# This is an interface that any instrument that can
# be used as a wavelength meter has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class WlMeter(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def get_wavelength(self):
        """
        Returns the wavelength in nm
        :return:
        """
        pass

    def get_id(self):
        return ("WavelengthMeter")
