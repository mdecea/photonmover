import pyvisa as visa
from photonmover.Interfaces.SignalGenerator import SignalGenerator
from photonmover.Interfaces.Instrument import Instrument


class HP70340A(Instrument, SignalGenerator):
    """
    Code for controlling the HP703040A signal generator through GPIB
    """

    def __init__(self, gpib_address="GPIB1::1::INSTR"):
        super().__init__()

        self.gpib = None
        self.gpib_address = gpib_address

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Anritsu Signal Generator')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(self.gpib_address, timeout=5000)
        except BaseException:
            raise ValueError('Cannot connect to Anritsu Signal Generator')

    def set_frequency(self, freq):
        """
        Sets the waveform frequency (Hz)
        :param freq:
        :return:
        """
        if freq > 20e9:
            print('Specified frequency is too high. No change')
            return

        self.gpib.write('FREQ %.9fHZ' % freq)  # Select F1 frequency parameter

    def turn_on(self):
        """
        Turns on the output waveform
        :return:
        """
        self.gpib.write('OUTP:STAT ON')

    def turn_off(self):
        """
        Turns off the output waveform
        :return:
        """
        self.gpib.write('OUTP:STAT OFF')

    def set_power(self, power):
        """
        Sets the output power in logarithmic units. Allowed values are between
        -20 and 30 dBm.
        Overrides any call of set_voltage.

        Calling this method turns the RF output off.

        :param power: RF power [dBm]
        :return:
        """
        if not -15 <= power <= 30:
            raise ValueError(
                'The input power setpoint is outside the instrument range (-20 to 30 dBm).')
        else:
            self.gpib.write('POW:LEV %.3fDBM' % power)

    def close(self):
        print('Disconnecting HP70340A Signal Generator')
        self.gpib.close()


if __name__ == '__main__':

    sig_gen = HP70340A()
    sig_gen.initialize()
    sig_gen.turn_on()
    sig_gen.set_frequency(10e9)
    sig_gen.turn_off()
    sig_gen.close()
