# This is an interface that any instrument that can
# be used as a source meter has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class TempController(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def set_temperature(self, temp):
        """
        Sets the  temperature to the specified value (in C)
        :return:
        """
        pass

    @abstractmethod
    def get_temperature(self):
        """
        Returns the current temperature (in C)
        :return:
        """
        pass

    @abstractmethod
    def get_temperature_setpoint(self):
        """
        Returns the current temperature setpoint (in degrees celcius)
        :return:
        """
        pass

    def turn_on(self):
        """
        Turns on the TEC
        :return:
        """
        pass

    def turn_off(self):
        """
        Turns off the TEC
        :return:
        """
        pass

    def get_id(self):
        return("TemperatureController")
