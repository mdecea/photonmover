import pyvisa as visa
from photonmover.Interfaces.SignalGenerator import SignalGenerator
from photonmover.Interfaces.Instrument import Instrument
import numpy as np


class AnritsuMG3692B(Instrument, SignalGenerator):
    """
    Code for controlling Keysight B2902A through GPIB
    """

    def __init__(self, gpib_address="GPIB1::1::INSTR"):
        super().__init__()

        self.gpib = None
        self.gpib_address=gpib_address

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Anritsu Signal Generator')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(self.gpib_address, timeout=5000)
        except:
            raise ValueError('Cannot connect to Anritsu Signal Generator')

    def turn_on(self):
        """
        Turns on the output waveform
        :return:
        """
        self.gpib.write('RF1')

    def turn_off(self):
        """
        Turns off the output waveform
        :return:
        """
        self.gpib.write('RF0')

    def set_power(self, power):
        """
        Sets the output power in logarithmic units. Allowed values are between
        -20 and 30 dBm.
        Overrides any call of set_voltage.

        Calling this method turns the RF output off.

        :param power: RF power [dBm]
        :return:
        """
        if not -20 <= power <= 30:
            raise ValueError( 'The input power setpoint is outside the instrument range (-20 to 30 dBm).' )
        else:
            self.gpib.write( 'RF0' )
            self.gpib.write( 'LOG' )
            self.gpib.write( 'L1' )
            self.gpib.write( '{:f} DM'.format(power) )

    def set_voltage(self, amplitude):
        """
        Sets the output voltage in millivolts, up to a maximum of .
        Overrides any call of set_power.

        Calling this method turns the RF output off.

        :amplitude: peak to peak amplitude [mV]
        :return:
        """
        maxvolt = 10
        if not -20 <= amplitude <= maxvolt:
            raise ValueError( 'The supplied voltage amplitude outside the instrument range' )
        else:
            self.gpib.write('RF0')
            self.gpib.write('LIN')
            self.gpib.write('{:f} VT'.format(amplitude))

    def set_frequency(self, freq):
        """
        Sets the waveform frequency (Hz)
        :param freq:
        :return:
        """
        if freq > 20e9:
            print('Specified frequency is too high. No change')
            return

        self.gpib.write('F1') # Select F1 frequency parameter
        self.gpib.write('{:d} HZ'.format(int(freq ))) # set parameter in Hz
        self.gpib.write('CLO') # Close parameter F1

    def close(self):
        print('Disconnecting Anritsu Signal Generator')
        self.gpib.close()

    def get_setpoint(self, param) -> None:
        """
        """




if __name__ == '__main__':

    sig_gen = AnritsuMG3692B()
    sig_gen.initialize()
    sig_gen.turn_on()
    sig_gen.set_frequency( 10e9 )
    sig_gen.turn_off()
    sig_gen.close()
