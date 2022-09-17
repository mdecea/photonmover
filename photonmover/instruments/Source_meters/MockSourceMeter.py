import sys
sys.path.insert(0,'../..')
import numpy as np
from Interfaces.SourceMeter import SourceMeter
from Interfaces.Instrument import Instrument


class MockSourceMeter(Instrument, SourceMeter):

    def __init__(self):
        super().__init__()

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to source meter')

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print('Closing connnection to source meter')

    def set_voltage(self, voltage):
        """
        Sets the voltage to the specified value (in V)
        :return:
        """
        print('Setting voltage to %.4f V' % voltage)

    def set_current(self, current):
        """
        Sets the current to the specified value (in A)
        :return:
        """
        print('Setting current to %.4E A' % current)

    def measure_current(self):
        """
        Measure the current through the device
        :return: The current in mA
        """
        return 0.0

    def measure_voltage(self):
        """
        Measure the voltage through the device
        :return: The voltage in V
        """
        return 0.0

    def turn_on(self):
        """
        Turn on the soruce meter
        """
        print("Turning on source meter")

    def turn_off(self):
        """
        Turn off the soruce meter
        """
        print("Turning off source meter")

    def take_IV(self, start_v, stop_v, num_v):
        """
        Takes an IV curve
        :return: A two column matrix, where the first column is voltage
        and the second is current
        """
        print('Performing IV measurement')
        iv = np.zeros((num_v, 2), float)

        return iv
