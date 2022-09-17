import sys
sys.path.insert(0, '../..')
import numpy as np
import pyvisa as visa
import time
from Interfaces.SourceMeter import SourceMeter
from Interfaces.Instrument import Instrument

GPIB_ADDR = "GPIB1::26::INSTR"  # GPIB adress
DEFAULT_CURRENT_COMPLIANCE = 0.100  # Default current compliance in A  # was 0.005
DEFAULT_VOLTAGE_COMPLIANCE = 5  # Default current compliance in V


class Keithley2400(Instrument, SourceMeter):
    """
    Code for controlling Keithley 2400 through GPIB
    """

    def __init__(self, current_compliance=DEFAULT_CURRENT_COMPLIANCE, voltage_compliance=DEFAULT_VOLTAGE_COMPLIANCE, gpib=None):
        """
        Note: the gpib is added as a parameter beacuse if we want to use two channels of the same
        SMU as two different source meters we would need to give the already initalized gpib (you cannot
        open two gpib connections to the same instrument)
        """

        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = gpib
        self.cur_compliance = current_compliance
        self.volt_compliance = voltage_compliance
        self.is_on = 0
        self.mode = 'VOLT'  # 'VOLTS' or 'AMPS'

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Keithley source meter')

        rm = visa.ResourceManager()
        try:
            if self.gpib is None:
                self.gpib = rm.open_resource(GPIB_ADDR, timeout=5000)
        except:
            raise ValueError('Cannot connect to the Keysight Source meter')
        
        self.init_function()

    def close(self):
        print('Disconnecting Keithley source meter')
        self.turn_off()
        self.gpib.close()

    def set_voltage_range(self, v_range):
        # Current in V, or 'AUTO'
        if v_range == 'AUTO':
            self.gpib.write(':SENS:VOLT:RANG:AUTO ON')
        else:
            self.gpib.write(':SENS:VOLT:RANG:AUTO OFF')
            self.gpib.write(':SENS:VOLT:RANG %.4E' % v_range)

    def set_current_range(self, i_range):
        # Current in Amps, or 'AUTO'
        if i_range == 'AUTO':
            self.gpib.write(':SENS:CURR:RANG:AUTO ON')
        else:
            self.gpib.write(':SENS:CURR:RANG:AUTO OFF')
            self.gpib.write(':SENS:CURR:RANG %.4E' % i_range)

    def turn_on(self):
        """
        Turns the source on
        :return:
        """
        self.gpib.write(":OUTP ON")
        self.is_on = 1

    def turn_off(self):
        """
        Turns the source off
        :return:
        """
        self.gpib.write(":OUTP OFF")
        self.is_on = 0

    def set_voltage_compliance(self, v_comp):
        self.set_voltage_range(v_comp)
        self.gpib.write(':SENS:VOLT:PROT %.4E' % v_comp)
        self.volt_compliance = v_comp

    def set_current_compliance(self, i_comp):
        self.set_current_range(i_comp)
        self.gpib.write(':SENS:CURR:PROT %.4E' % i_comp)
        self.cur_compliance = i_comp

    def set_integration_time(self, time):
        # Sets the integration time (given in seconds)
        # We need to convert from seconds to number of power line cycles
        nplc = time*60
        self.gpib.write(':SENS:CURR:NPLC %.4E' % nplc)  # Even though we set if for current, it affects all measurements

    def measure_current(self):
        curr = self.gpib.query_ascii_values(':MEAS:CURR?')
        return float(curr[1])

    def measure_voltage(self):
        return float(self.gpib.query_ascii_values(':MEAS:VOLT?')[0])

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
            meas_current = self.measure_current()
            measurements[row, 0] = v
            measurements[row, 1] = meas_current
            print('Set Voltage: %.4f mV ; Measured Current: %.4E mA' % (v*1000, meas_current*1000))
            sys.stdout.flush()
            row = row + 1

        return measurements

    def set_func(self, mode):
        """
        :param mode: Either VOLT or CURR
        :return:
        """
        if not (mode == 'VOLT' or mode == 'CURR'):
            print('Source meter mode not correct. No action taken')
            return

        self.gpib.write(':SOUR:FUNC:MODE %s' % mode)  # set mode
        self.mode = mode

        if mode == 'VOLT':
            self.gpib.write(':SENS:FUNC "CURR"')
        else:
            self.gpib.write(':SENS:FUNC "VOLT"')

    def set_voltage(self, voltage, turn_on=True):
        """
        Sets the specified voltage
        :param voltage:
        :return:
        """

        if not (self.mode == 'VOLT'):
            self.turn_off()
            self.set_func('VOLT')
            time.sleep(0.1)

        if not self.is_on and turn_on:
            self.turn_on()

        self.gpib.write(":SOUR:VOLT %.4E" % voltage)

    def set_current(self, current, turn_on=True):
        """
        Sets the specified current
        :param current:
        :return:
        """

        if not (self.mode == 'CURR'):
            self.turn_off()
            self.set_func('CURR')
            time.sleep(0.1)

        if not self.is_on and turn_on:
            self.turn_on()

        self.gpib.write(":SOUR:CURR %.6E" % current)

    def init_function(self):
        """
        Initializes the source meter
        """
        # self.gpib.write("reset()")
        # self.gpib.write('waitcomplete()')
        # Clear buffers
        self.gpib.write(':FORM:DATA ASCII')

        self.set_func(self.mode)
        self.set_current_compliance(self.cur_compliance)
        self.set_voltage_compliance(self.volt_compliance)
        # self.set_measurement_interval(1)


if __name__ == '__main__':
    sm = Keithley2400(current_compliance=1, voltage_compliance=10)
    sm.initialize()
    sm.set_voltage(0.2)
    sm.turn_on()
    #while True:
    #    print(sm.measure_current())
    #    time.sleep(1)
    sm.close()
