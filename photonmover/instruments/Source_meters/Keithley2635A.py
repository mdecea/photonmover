import sys
sys.path.insert(0, '../..')
import numpy as np
import pyvisa as visa
import time
from Interfaces.SourceMeter import SourceMeter
from Interfaces.Instrument import Instrument

GPIB_ADDR = "GPIB1::29::INSTR"  # GPIB adress
DEFAULT_CURRENT_COMPLIANCE = 0.1   # Default current compliance in A
DEFAULT_VOLTAGE_COMPLIANCE = 5  # Default current compliance in V


class Keithley2635A(Instrument, SourceMeter):
    """
    Code for controlling Keysight B2902A through GPIB
    """

    def __init__(self, current_compliance=DEFAULT_CURRENT_COMPLIANCE, voltage_compliance=DEFAULT_VOLTAGE_COMPLIANCE):
        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = None
        self.cur_compliance = current_compliance
        self.volt_compliance = voltage_compliance
        self.is_on = 0
        self.mode = 'VOLTS'  # 'VOLTS' or 'AMPS'

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Keithley source meter')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDR, timeout=30000)
        except:
            raise ValueError('Cannot connect to the Keysight Source meter')

        self.init_function()

    def close(self):
        print('Disconnecting Keithley source meter')
        self.turn_off()
        self.gpib.close()

    def turn_on(self):
        """
        Turns the source on
        :return:
        """
        self.gpib.write("smua.source.output = smua.OUTPUT_ON")
        self.is_on = 1

    def turn_off(self):
        """
        Turns the source off
        :return:
        """
        self.gpib.write("smua.source.output = smua.OUTPUT_OFF")
        self.is_on = 0

    def set_func(self, mode):
        """
        :param mode: Either VOLT or CURR
        :return:
        """
        if not (mode == 'VOLTS' or mode == 'AMPS'):
            print('Source meter mode not correct. NO action taken')
            return

        self.gpib.write('smua.source.func = smua.OUTPUT_DC%s' % mode)  # set voltage
        self.mode = mode

    def set_voltage_compliance(self, v_comp):
        self.gpib.write('smua.source.limitv = %.4E' % v_comp)
        self.gpib.write('smua.measure.rangev = %.4E' % v_comp)
        self.volt_compliance = v_comp

    def set_current_compliance(self, i_comp):

        self.gpib.write('smua.source.limiti = %.4E' % i_comp)
        # self.gpib.write('smua.measure.rangei = %.4E' % i_comp)
        self.cur_compliance = i_comp

    def set_voltage(self, voltage):
        """
        Sets the specified voltage
        :param voltage:
        :return:
        """

        if not (self.mode == 'VOLTS'):
            self.turn_off()
            self.set_func('VOLTS')
            time.sleep(0.1)

        if not self.is_on:
            self.turn_on()

        self.gpib.write("smua.source.levelv = %.4E" % voltage)

    def set_current(self, current):
        """
        Sets the specified current
        :param current:
        :return:
        """

        if not (self.mode == 'AMPS'):
            self.turn_off()
            self.set_func('AMPS')
            time.sleep(0.1)

        if not self.is_on:
            self.turn_on()

        self.gpib.write("smua.source.leveli = %.4E" % current)

    def init_function(self):
        """
        Initializes the source meter
        """
        # self.gpib.write("reset()")
        # self.gpib.write('waitcomplete()')
        # Clear buffers
        self.gpib.write('format.data = format.ASCII')
        self.gpib.write('errorqueue.clear()')
        self.gpib.write('smua.nvbuffer1.clear()')
        self.gpib.write('waitcomplete()')

        self.set_func(self.mode)
        self.set_current_compliance(self.cur_compliance)
        self.set_voltage_compliance(self.volt_compliance)
        # Set longest integration time
        # self.gpib.write('smua.measure.nplc = 25')
        # self.set_measurement_interval(1)

    def measure_current(self):
        self.gpib.write('current1=smua.measure.i()')
        self.gpib.write('waitcomplete()')
        return float(self.gpib.query_ascii_values('print(current1)')[0])

    def measure_voltage(self):
        self.gpib.write('voltage1=smua.measure.v()')
        return float(self.gpib.query_ascii_values('print(voltage1)')[0])

    def take_IV(self, start_v, stop_v, num_v):
        """
        Takes an IV curve
        :return: A two column matrix, where the first column is voltage
        and the second is current
        """

        print('Starting IV measurement')
        sys.stdout.flush()

        measurements = np.zeros((num_v, 2), float)
        row = 0

        for v in np.linspace(start_v, stop_v, num_v):
            self.set_voltage(v)
            self.gpib.write('waitcomplete()')
            meas_current = self.measure_current()
            measurements[row, 0] = v
            measurements[row, 1] = meas_current
            print('Set Voltage: %.4f mV ; Measured Current: %.4E mA' % (v*1000, meas_current*1000))
            sys.stdout.flush()
            row = row + 1

        return measurements

    def set_voltage_range(self, v_range):
        # Current in V
        self.gpib.write('smua.source.rangev= %.4E' % v_range)

    def set_current_range(self, i_range):
        # Current in Amps
        self.gpib.write('smua.source.rangei= %.4E' % i_range)

    def set_measurement_delay(self, time):
        self.gpib.write("smua.measure.delay = %.4E" % time)

    def set_measurement_interval(self, time):
        # Sets the measurement interval (in seconds)
        self.gpib.write('smua.measure.interval=%.4E' % time)

    def set_measurement_integration(self, nplc):
        # Sets the integration time in nplc units. 1 nplc is one period of the frequency of the AC power
        # So for 60 Hz, 1 NPLC = 17 ms. Has to be between 1 and 25
        if nplc > 25:
            print('Specified integration NPLC is more than the max. Setting to max.')
            nplc = 25
        if nplc < 1:
            print('Specified integration NPLC is smaller than the min. Setting to min.')
            nplc = 1
        self.gpib.write('smua.measure.nplc = %d' % nplc)
    
    def set_filter(self, enable=True, type='repeat_average', count=10):
        # Configures the digital filter that can be used to reduce readout noise.

        # If enable = True, it turns on the digital filtering.
        # There are 3 different types:
        # - repeat_average: makes 'count' measurements and takes the average
        # - moving_average: takes the moving average of 'count' measurements
        # - median: takes the median of 'count measurements
        # Count: the number of measurements neede for one reading. Has to be between 1 and 100

        if type == 'repeat_average':
            type_str = 'FILTER_REPEAT_AVG'
        elif type == 'moving_average':
            type_str = 'FILTER_MOVING_AVG'
        elif type == 'median':
            type_str = 'FILTER_MEDIAN'

        self.gpib.write('smua.measure.filter.type = smua.%s' % type_str)

        if count > 100:
            print('Specified filter count is more than the max. Setting to max.')
            count = 100
        if count < 1:
            print('Specified filter count is smaller than the min. Setting to min.')
            count = 1

        self.gpib.write('smua.measure.filter.count = %d' % count)

        if enable:
            self.gpib.write('smua.measure.filter.enable = smua.FILTER_ON')
        else:
            self.gpib.write('smua.measure.filter.enable = smua.FILTER_OFF')


if __name__ == '__main__':
    sm = Keithley2635A()
    sm.initialize()
    while True:
        print(sm.measure_current())
        time.sleep(1)
    sm.close()


