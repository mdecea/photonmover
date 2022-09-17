from photonmover.Interfaces.Laser import TunableLaser
from photonmover.Interfaces.Instrument import Instrument


class MockLaser(Instrument, TunableLaser):

    def __init__(self):
        super().__init__()

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to laser')
        self.wav = 1550
        self.state = 0
        self.power = 1

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print('Closing connnection to laser')

    def turn_off(self):
        """
        Turn light off
        :return:
        """
        print('Turning off laser')
        self.state = 0

    def turn_on(self):
        """
        Turn light on
        :return:
        """
        print('Turning on laser')
        self.state = 1

    def set_power(self, power):
        """
        Set the power to the specified value (in mW)
        :return:
        """
        print('Setting power to %.4f mW' % power)
        self.power = power

    def set_wavelength(self, wavelength):
        """
        Set the wavelength to the specified value (in nm)
        :return:
        """
        print('Setting wavelength to %.4f nm' % wavelength)
        self.wav = wavelength

    def get_state(self):
        """
        Returns a list wiht the following elements:
        1. The current wavelength
        2. The current power 
        3. If the laser is on or off.
        """
        print("Getting laser state")
        return [self.wav, self.power, self.state]
