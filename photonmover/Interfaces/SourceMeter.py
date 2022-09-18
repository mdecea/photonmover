# This is an interface that any instrument that can
# be used as a source meter has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class SourceMeter(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def set_voltage(self, voltage):
        """
        Sets the voltage to the specified value (in V)
        :return:
        """
        pass

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

    @abstractmethod
    def take_IV(self, start_v, stop_v, num_v):
        """
        Takes an IV curve
        :return: A two column matrix, where the first column is voltage
        and the second is current
        """
        pass

    def get_id(self):
        return ("SourceMeter")
