# This is an interface that any instrument that can
# be used as a laser has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class Laser(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def turn_off(self):
        """
        Turn light off
        :return:
        """
        pass

    @abstractmethod
    def turn_on(self):
        """
        Turn light on
        :return:
        """
        pass

    @abstractmethod
    def set_power(self, power):
        """
        Set the power to the specified value (in mW)
        :return:
        """
        pass

    @abstractmethod
    def get_state(self):
        """
        Returns a list with the following elements:
        1. The current power
        2. If the laser is on or off.
        """
        pass

    def get_id(self):
        return ("Laser")


class TunableLaser(Laser):
    def __init__(self):
        super().__init__()
        self.sweep_dwell_time = 0.5  # Default wait time

    @abstractmethod
    def set_wavelength(self, wavelength):
        """
        Set the wavelength to the specified value (in nm)
        :return:
        """
        pass

    @abstractmethod
    def get_state(self):
        """
        Returns a list wiht the following elements:
        1. The current wavelength
        2. The current power
        3. If the laser is on or off.
        """
        pass

    def get_id(self):
        return ["TunableLaser", "Laser"]
