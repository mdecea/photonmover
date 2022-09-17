import numpy as np
import pyvisa as visa
import time
from photonmover.Interfaces.SourceMeter import SourceMeter
from photonmover.Interfaces.Instrument import Instrument


PARAM_ANALYZER_ADDR = "GPIB0::17::INSTR"  # GPIB adress
DEFAULT_CURRENT_COMPLIANCE = 0.05  # Default current compliance in A

class ParameterAnalyzer(Instrument, SourceMeter):
    """
    Use the HP parameter analyzer as a source meter to take IV curves
    """

    def __init__(self, channel, current_compliance = DEFAULT_CURRENT_COMPLIANCE):
        super().__init__()

        # It is good practice to initialize variables in init
        self.sparam = None
        self.channel = channel  # Active channel of teh parameter analyzer
        self.cur_compliance = current_compliance

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to HP parameter analyzer')
        rm = visa.ResourceManager()
        try:
            self.sparam = rm.open_resource(PARAM_ANALYZER_ADDR, timeout=10000)
        except:
            raise ValueError('Cannot connect to the Parameter Analyzer')

        self.initialize_channel(self.channel)
        self.set_integration_time('short')

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print('Closing connnection to Parameter Analyzer')
        self.sparam.write("CL")
        self.sparam.write(":PAGE")
        self.sparam.close()

    def set_voltage(self, voltage):
        """
        Sets the voltage to the specified value (in V)
        :return:
        """
        print('Setting param Analyzer voltage to %.4f V' % voltage)
        self.sparam.write("DV %d,12,%.5E,%.4f" % (self.channel, voltage,
                                                  self.cur_compliance))

    def set_channel(self, channel):
        self.channel = channel

    def set_current_compliance(self, compliance):
        """
        :param compliance: In Amps
        :return:
        """
        self.cur_compliance = compliance

    def measure_current(self):
        """
        Measure the current through the device
        :return: The current in mA
        """
        try:
            photocurrent = float(self.sparam.query("TI? %d,0" % self.channel))
        except ValueError:
            photocurrent = 0.0

        return photocurrent

    def take_IV(self, start_v, stop_v, num_v):
        """
        Takes an IV curve
        :return: A two column matrix, where the first column is voltage
        and the second is current
        """
        print('Performing IV measurement with parameter analyzer')

        iv = np.zeros((num_v, 2), float)
        self.set_integration_time('long')

        row = 0

        for volt in np.linspace(start_v, stop_v, num_v):

            iv[row, 0] = volt

            self.set_voltage(volt)
            dummy = self.measure_current()
            time.sleep(0.0001)
            current_meas = self.measure_current()

            iv[row, 1] = current_meas

            print("Measured current for %.2fV = %.2e" % (volt, current_meas))

            row = row + 1

        self.set_integration_time('short')

        return iv

    def initialize_channel(self, channel):
        """
        Initializes the current channel
        :return: None
        """

        self.channel = channel

        self.sparam.write("US")
        time.sleep(1.0)
        self.sparam.write("FMT 2")
        self.sparam.write("AV 1")
        self.sparam.write("CM 0")
        self.sparam.write("SLI 1")
        # self.sparam.write("FL 0")
        self.sparam.write("CN %d" % channel)
        self.sparam.write("DV 2,11,0," + str(self.cur_compliance))  # Last number: current compliance (0.05)

        self.set_voltage(0.0)

    def set_integration_time(self, time):
        """
        Sets the integration time
        :param time: String, eiher 'short', 'med'. or 'long'
        :return:
        """
        if time == 'short':
            mode = 1
        elif time == 'med':
            mode = 2
        elif time == 'long':
            mode = 3
        else:
            print('Specified integration time is not correct.')
            return

        self.sparam.write("SLI " + str(mode))
