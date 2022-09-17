from photonmover.Interfaces.WlMeter import WlMeter
from photonmover.Interfaces.Instrument import Instrument


class MockWlMeter(Instrument, WlMeter):

    def __init__(self):
        super().__init__()

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to power meter')

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print('Closing connnection to power meter')

    def get_wavelength(self):
        """
        Returns the wavelength in nm
        :return:
        """
        return 1550.0
