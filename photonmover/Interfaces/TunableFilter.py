# This is an interface that any instrument that can
# be used as a source meter has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class TunableFilter(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def set_wavelength(self, wavelength):
        """
        Sets the wavelength to the specified value (in nm)
        :return:
        """
        pass

    @abstractmethod
    def do_sweep(self, start_wav, stop_wav, num_wav, dwell_time):
        """
        Sets and performs the sweep for the tunable filter. Dwell time in s.
        :return:
        """
        pass

    def get_id(self):
        return("TunableFilter")