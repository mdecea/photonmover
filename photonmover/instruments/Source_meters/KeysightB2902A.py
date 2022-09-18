import numpy as np
import pyvisa as visa
import time
from photonmover.Interfaces.SourceMeter import SourceMeter
from photonmover.Interfaces.Instrument import Instrument

GPIB_ADDR = "GPIB1::23::INSTR"  # GPIB adress
DEFAULT_CURRENT_COMPLIANCE = 0.02  # Default current compliance in A


class KeysightB2902A(Instrument, SourceMeter):
    """
    Code for controlling a single channel of the Keysight B2902A through GPIB
    """

    def __init__(
            self,
            channel=1,
            current_compliance=DEFAULT_CURRENT_COMPLIANCE,
            gpib=None):
        """
        Note: the gpib is added as a parameter beacuse if we want to use two channels of the same
        SMU as two different source meters we would need to give the already initalized gpib (you cannot
        open two gpib connections to the same instrument)
        """

        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = gpib
        self.cur_compliance = current_compliance
        self.is_on = 0
        self.v_compliance = None
        self.channel = channel
        self.mode = 'VOLT'

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to keysight source meter')

        rm = visa.ResourceManager()
        try:
            if self.gpib is None:
                self.gpib = rm.open_resource(GPIB_ADDR, timeout=5000)
        except BaseException:
            raise ValueError('Cannot connect to the Keysight Source meter')

        self.init_function()  # Set to voltage source with compliance

    def close(self):
        self.gpib.close()

    def turn_on(self):
        """
        Turns the source on
        :return:
        """
        self.gpib.write(":OUTP%d ON" % self.channel)
        self.is_on = 1

    def turn_off(self):
        """
        Turns the source off
        :return:
        """
        self.gpib.write(":OUTP%d OFF" % self.channel)
        self.is_on = 0

    def set_func(self, mode):
        """

        :param mode: Either VOLT or CURR
        :return:
        """
        if not (mode == 'VOLT' or mode == 'CURR'):
            print('Source meter mode not correct. NO action taken')
            return

        self.gpib.write(":SOUR%d:FUNC:MODE %s" % (self.channel, mode))
        self.mode = mode

    def set_voltage_compliance(self, v_comp):
        self.gpib.write(":SENS%d:VOLT:PROT %.4E" % (self.channel, v_comp))
        self.gpib.write(":OUTP%d:PROT ON" % self.channel)
        self.v_compliance = v_comp

    def set_current_compliance(self, i_comp):
        self.gpib.write(":SENS%d:CURR:PROT %.4E" % (self.channel, i_comp))
        self.gpib.write(":OUTP%d:PROT ON" % self.channel)
        self.cur_compliance = i_comp

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

        self.gpib.write(":SOUR%d:VOLT %.4E" % (self.channel, voltage))

    def set_integration_time(self, int_time):
        # int time in seconds, or 'AUTO'
        if self.mode == 'VOLT':
            if int_time == 'AUTO':
                self.gpib.write(":sens%d:curr:aper:auto 1" % self.channel)
            else:
                self.gpib.write(":sens%d:curr:aper:auto 0" % self.channel)
                self.gpib.write(
                    ":sens%d:curr:aper %.3e" %
                    (self.channel, int_time))  # Set integration time in seconds
        elif self.mode == 'CURR':
            if int_time == 'AUTO':
                self.gpib.write(":sens%d:volt:aper:auto 1" % self.channel)
            else:
                self.gpib.write(":sens%d:volt:aper:auto 0" % self.channel)
                self.gpib.write(
                    ":sens%d:volt:aper %.3e" %
                    (self.channel, int_time))  # Set integration time in seconds

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

        self.gpib.write(":SOUR%d:CURR %.4E" % (self.channel, current))

    def init_function(self):
        """
        Initializes the source meter as a voltage source
        with the specified compliance
        """
        # self.gpib.write("*RST")
        self.set_func('VOLT')
        self.set_current_compliance(self.cur_compliance)
        self.gpib.write(
            ":SOUR%d:VOLT:RANG:AUTO ON" %
            self.channel)  # Auto voltage range
        self.gpib.write(
            ":SENS%d:CURR:RANG:AUTO:MODE NOR" %
            self.channel)  # Auto meaasurement params

    def measure_current(self):
        self.gpib.write(":FORM:ELEM:SENS CURR")
        return float(self.gpib.query(":MEAS? (@%d)" % self.channel))

    def measure_voltage(self):
        self.gpib.write(":FORM:ELEM:SENS VOLT")
        return float(self.gpib.query(":MEAS? (@%d)" % self.channel))

    def measure_resistance(self):
        self.gpib.write(":FORM:ELEM:SENS RES")
        return float(self.gpib.query(":MEAS? (@%d)" % self.channel))

    def take_IV(self, start_v, stop_v, num_v):
        """
        Takes an IV curve
        :return: A two column matrix, where the first column is voltage
        and the second is current
        """

        self.config_volt_sweep(start_v, stop_v, num_v)

        # Once measurement is set up, perform the sweep and get the data
        self.gpib.write(":outp on")
        self.gpib.write(":init (@%d)" % self.channel)
        self.gpib.write(":fetc:arr:curr? (@%d)" % self.channel)
        currents = self.gpib.read()
        currents = currents.split(',')
        currents_f = [float(cur) for cur in currents]

        meas = np.zeros((num_v, 2), float)

        for i, v in enumerate(np.linspace(start_v, stop_v, num_v)):
            meas[i, 0] = v
            meas[i, 1] = currents_f[i]

        return meas

    def config_volt_sweep(self, start_v, stop_v, num_v):
        """
        Sets the instrument to perform a voltage sweep with the
        specified parameters
        :param start_v:
        :param stop_v:
        :param num_v:
        :return:
        """

        self.set_func('VOLT')

        self.gpib.write(":sour%d:volt:mode swe" % self.channel)
        self.gpib.write(":sour%d:volt:star %.4E" % (self.channel, start_v))
        self.gpib.write(":sour%d:volt:stop %.4E" % (self.channel, stop_v))
        self.gpib.write(":sour%d:volt:poin %d" % (self.channel, num_v))

        # Set auto range current measurement
        self.gpib.write(":sens%d:func curr" % self.channel)
        # self.gpib.write(":sens:curr:nplc 0.1") # Set integration time in NPLC
        # units
        self.gpib.write(":sens%d:curr:aper 100e-3" %
                        self.channel)  # Set integration time in seconds

        # Generate num_V triggers by automatic internal algorithm
        self.gpib.write(":trig%d:sour aint" % self.channel)
        self.gpib.write(":trig%d:coun %d" % (self.channel, num_v))

    def source_from_val_list(self, source, val_list, measure, step_time):
        """
        Sources a specified series of voltages or currents.
        :param mode: 'VOLT' or 'CURR', for sourcing current or voltage
        :param val_list: the list of voltage (if mode is 'VOLT') or current (if mode is 'CURR') values to surce
        :param measure: 'VOLT' or 'CURR', wahetever we want to measure
        :param step_time: time per step (in s)
        """

        self.set_func(source)

        self.gpib.write(":sour%d:%s:mode list" % (self.channel, source))
        num_points = len(val_list)
        self.gpib.write(
            ":sour%d:%s:poin %d" %
            (self.channel, source, num_points))

        # Set the list of points
        value_list = str(val_list)
        value_list = value_list[1:-1]
        self.gpib.write(
            ":sour%d:list:%s %s" %
            (self.channel, source, value_list))

        # Generate num_points triggers by automatic internal algorithm
        self.gpib.write(":trig%d:sour aint" % self.channel)
        self.gpib.write(":trig%d:coun %d" % (self.channel, num_points))

        # Set auto range current measurement
        self.gpib.write(":sens%d:func %s" % (self.channel, measure))
        # self.gpib.write(":sens:curr:nplc 0.1") # Set integration time in NPLC
        # units
        self.gpib.write(
            ":sens%d:curr:aper %.4f" %
            (self.channel, step_time))  # Set integration time in seconds

        # Start the sourcing
        self.gpib.write(":outp on")
        self.gpib.write(":init (@%d)" % self.channel)

        # Get the data
        self.gpib.write(":fetc:arr:%s? (@%d)" % (measure, self.channel))
        meas_vals = self.gpib.read()
        meas_vals = meas_vals.split(',')
        meas_vals_f = [float(val) for val in meas_vals]

        self.turn_off()
        meas = np.zeros((num_points, 2), float)

        for i, meas_val in enumerate(meas_vals_f):
            meas[i, 0] = val_list[i]
            meas[i, 1] = meas_val

        return meas


if __name__ == '__main__':

    smu = KeysightB2902A(channel=1, current_compliance=1)
    smu.initialize()

    print(
        smu.source_from_val_list(
            source='CURR',
            val_list=[
                0,
                0.1,
                0.2,
                0.3,
                0.4,
                0.5,
                0.5,
                0.5,
                0.5,
                0.5,
                0.4,
                0.3,
                0.2,
                0.1,
                0],
            measure='CURR',
            step_time=500e-3))
    print('1st ramp done')

    time.sleep(2)

    print(smu.source_from_val_list(source='CURR', val_list=[0, -
                                                            0.1, -
                                                            0.2, -
                                                            0.3, -
                                                            0.4, -
                                                            0.5, -
                                                            0.5, -
                                                            0.5, -
                                                            0.5, -
                                                            0.5, -
                                                            0.5, -
                                                            0.5, -
                                                            0.4, -
                                                            0.3, -
                                                            0.2, -
                                                            0.1, 0], measure='CURR', step_time=500e-3))
    print('2nd ramp done')

    # print(smu.source_from_val_list(source = 'VOLT', val_list = [0, -0.2, -0.4, -0.6, -0.8, -1, -1.2, -1.2, -1.2, -1.2, -1, -0.8, -0.6, -0.4, -0.2, 0],
    # measure = 'CURR', step_time = 500e-3))
    #print('1st ramp done')

    # time.sleep(2)

    # print(smu.source_from_val_list(source = 'VOLT', val_list = [0, 0.2, 0.4, 0.6, 0.8, 1, 1.2, 1.2, 1.2, 1.2, 1, 0.8, 0.6, 0.4, 0.2, 0],
    # measure = 'CURR', step_time = 500e-3))
    #print('2nd ramp done')

    smu.close()
