# This is an interface that any instrument that can
# be used as a power meter has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class PowerMeter(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def set_wavelength(self, wavelength):
        """
        Set the wavelength to the specified value (in nm)
        :return:
        """
        pass

    @abstractmethod
    def get_powers(self):
        """
        Returns a list with the power measured in the tap port and in
        the through port. These ports will be specified in the init of
        the actual power_meter implementation.
        :return: A 2 element list with the power in mW
        """
        pass

    @abstractmethod
    def set_range(self, channel, range):
        """
        Set the power range of the specified channel to the specified number
        :return:
        """
        pass

    def get_id(self):
        return ("PowerMeter")
