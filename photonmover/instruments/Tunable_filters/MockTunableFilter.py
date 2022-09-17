from photonmover.Interfaces.TunableFilter import TunableFilter
from photonmover.Interfaces.Instrument import Instrument


class MockTunableFilter(TunableFilter, Instrument):

    def __init__(self):
        super().__init__()

    def set_wavelength(self, wavelength):
        """
        Sets the wavelength to the specified value (in nm)
        :return:
        """
        print("Setting filter wavelength to %.2f nm" % wavelength)

    def do_sweep(self, start_wav, stop_wav, num_wav, dwell_time):
        """
        Sets the sweep for the tunable filter
        :return:
        """
        print("Setting and performing filter sweep. Start: %.2f nm; stop: %.2f nm, num: %d, time = %.2f s"
              % (start_wav, stop_wav, num_wav, dwell_time))

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print("Initializing connection to Tunable Filter")

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print("Closing connection to Tunable Filter")
