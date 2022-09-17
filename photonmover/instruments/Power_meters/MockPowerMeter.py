import sys
sys.path.insert(0,'../..')

from Interfaces.PowMeter import PowerMeter
from Interfaces.Instrument import Instrument
import numpy as np


class MockPowerMeter(Instrument, PowerMeter):

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

    def set_wavelength(self, wavelength):
        """
        Set the wavelength to the specified value (in nm)
        :return:
        """
        print('Setting wavelength to %.4f nm' % wavelength)

    def get_powers(self):
        """
        Returns a list with the power measured in the tap port and in
        the through port. These ports will be specified in the init of
        the actual power_meter implementation.
        :return: A 2 element list with the power in mW
        """
        return np.ndarray.tolist(np.random.rand(1,2)[0,:])

    def set_range(self, channel, range):
        print("Range set")
