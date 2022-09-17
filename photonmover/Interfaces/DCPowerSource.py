# This is an interface that any instrument that can
# be used as a source meter has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class DCPowerSource(ABC):

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
        Sets the voltage to the specified value (in A)
        :return:
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
    def measure_current(self):
        """
        Measure the output current
        """
        pass

    @abstractmethod
    def measure_voltage(self):
        """
        Measure the output voltage
        """
        pass

    def get_id(self):
        return("DCPowerSource")