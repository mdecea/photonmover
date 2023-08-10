# This is an interface that any instrument that can
# be used as a laser driver has to implement.
# In some cases, optical amplifiers (SOAs, EDFA, etc)
# may implement similar commands and use this interface

from abc import ABC, abstractmethod


class LaserDriver(ABC):
    def __init__(self):
        super().__init__()

    @abstractmethod
    def set_current(self, current):
        """
        Sets the current to the specified value (in A)
        :return:
        """
        pass

    @abstractmethod
    def measure_current(self):
        """
        Measure the current through the device
        :return: The current in A
        """
        pass

    @abstractmethod
    def measure_voltage(self):
        """
        Measure the voltage through the device
        :return: The voltage in V
        """
        pass

    @abstractmethod
    def turn_on(self):
        """
        Turn on the soruce meter
        """
        pass

    @abstractmethod
    def turn_off(self):
        """
        Turn off the soruce meter
        """
        pass

    def get_id(self):
        return "LaserDriver"
