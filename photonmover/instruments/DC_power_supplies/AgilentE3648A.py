import numpy as np
import pyvisa as visa
import time
from photonmover.Interfaces.DCPowerSource import DCPowerSource
from photonmover.Interfaces.Instrument import Instrument

GPIB_ADDR = "GPIB1::5::INSTR"  # GPIB adress
DEFAULT_VOLTAGE_COMPLIANCE = 8  # Default current compliance in V


class AgilentE3648A(Instrument, DCPowerSource):
    """
    Code for controlling Agilent E3648A DC power supply through GPIB.
    """

    def __init__(
            self,
            channel=1,
            voltage_compliance=DEFAULT_VOLTAGE_COMPLIANCE,
            gpib=None):
        """
        Note: the gpib is added as a parameter beacuse if we want to use two channels of the same
        SMU as two different source meters we would need to give the already initalized gpib (you cannot
        open two gpib connections to the same instrument)
        """

        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = gpib
        self.volt_compliance = voltage_compliance
        self.is_on = 0
        self.channel = channel

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Agilent E3648A DC power source')

        rm = visa.ResourceManager()
        try:
            if self.gpib is None:
                self.gpib = rm.open_resource(GPIB_ADDR, timeout=5000)
        except BaseException:
            raise ValueError(
                'Cannot connect to the Agilent E3648A DC power source')

        self.init_function()

    def close(self):
        print('Disconnecting Agilent E3648A DC power source')
        # self.turn_off()
        self.gpib.close()

    def select_channel(self, channel):
        if channel not in [1, 2]:
            print('The specified channel is not correct. Doing nothing')
            return

        self.gpib.write('INST:SEL OUT%d' % channel)
        self.channel = channel

    def init_function(self):
        """
        Initializes the source meter
        """

        self.select_channel(self.channel)
        self.set_voltage_compliance(self.volt_compliance)
        self.activate_overvoltage_prot(1)
        # self.set_measurement_interval(1)

    def measure_current(self):
        curr = self.gpib.query_ascii_values(':MEAS:CURR?')
        return float(curr[1])

    def measure_voltage(self):
        return float(self.gpib.query_ascii_values(':MEAS:VOLT?')[0])

    def set_voltage(self, voltage):
        """
        Sets the specified voltage
        :param voltage:
        :return:
        """

        self.gpib.write("VOLT %.4E" % voltage)

    def set_current(self, current):
        """
        Sets the specified current
        :param current:
        :return:
        """

        self.gpib.write("CURR %.6E" % current)

    def set_voltage_compliance(self, v_comp):
        self.gpib.write('VOLT:PROT %.4E' % v_comp)
        self.volt_compliance = v_comp

    def activate_overvoltage_prot(self, state):
        # Turns on overvoltage protection if state=1, turns it off if state=0

        if state not in [0, 1]:
            print('The specified channel is not correct. Doing nothing')
            return

        self.gpib.write('VOLT:PROT:STAT %d' % state)

    def set_voltage_range(self, v_range):

        if v_range < 8:
            rge = 8
        elif v_range > 8:
            rge = 20

        self.gpib.write('VOLT:RANG P%dV' % rge)

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


if __name__ == '__main__':
    ps = AgilentE3648A()
    ps.initialize()
    ps.set_voltage(3.0)
    ps.turn_on()
    ps.close()
