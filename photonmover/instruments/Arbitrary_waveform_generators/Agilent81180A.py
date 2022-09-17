import pyvisa as visa
from photonmover.Interfaces.WaveformGenerator import WaveformGenerator
from photonmover.Interfaces.Instrument import Instrument
import numpy as np
import matplotlib.pyplot as plt 

GPIB_ADDR = "GPIB1::2::INSTR"  # GPIB adress


class Agilent81180A(Instrument, WaveformGenerator):
    """
    Code for controlling Keysight B2902A through GPIB
    """

    def __init__(self, channel=1):
        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = None
        self.shape = 'SIN'
        self.channel = channel

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Agilent Waveform Generator')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDR, timeout=5000)
            self.select_channel(self.channel)
        except:
            raise ValueError('Cannot connect to Agilent Waveform Generator')

    def select_channel(self, channel):
        """
        Specifies the channel to program/control
        :param channel:
        :return:
        """
        if self.channel not in [1, 2]:
            print("The specified channel is not correct. Doing nothing.")
            return

        self.gpib.write(':INST %d;' % channel)

    def couple_channels(self, turn_on, offset=None):
        """
        Turns on or off the coupling of the two channels
        :param turn_on: if 1, it turns on the coupling. If 0, it turns off the coupling
        :param offset: if specified, phase offset between the two channels (in samples)
        :return:
        """

        self.gpib.write(':INST:COUP:STAT %d;' % turn_on)

        if offset is not None:
            self.gpib.write(':INST:COUP:OFFS %d;' % offset)

    def turn_on(self):
        """
        Turns on the output waveform
        :return:
        """
        self.gpib.write(':OUTP ON;')

    def turn_off(self):
        """
        Turns off the output waveform
        :return:
        """
        self.gpib.write(':OUTP OFF;')

    def set_coupling(self, coupling):
        """
        Sets the coupling type for the output signal
        :param coupling: 'AC', 'DC' or 'DAC'. Latter is for a DC coupled DAC (?)
        :return:
        """

        if self.channel not in ['AC', 'DC', 'DAC']:
            print("The specified coupling mode is not correct. Doing nothing.")
            return

        self.gpib.write(':OUTP:COUP %s;' % coupling)

    def set_voltage(self, amplitude, offset):
        """
        Sets the voltage settings. If any of them is None, they are not modified
        :param amplitude: peak to peak amplitude (V)
        :param offset: offset voltage (V)
        :return:
        """

        if amplitude is not None:
            if 0.05 <= amplitude <= 4:
                self.gpib.write(":VOLT %.2f;" % amplitude)
            else:
                print("Specified amplitude is too high. No change.")

        if offset is not None:
            self.gpib.write(":VOLT:OFFS %.2f;" % offset)

    def set_shape(self, shape):
        """
        Sets the waveform shape
        :param shape: "SIN", "SQU", "TRI", "RAMP", "NOIS", "DC"
        :return:
        """

        if shape not in ["SIN", "SQU", "TRI", "RAMP", "NOIS", "DC"]:
            print("Specified shape not correct.")
            return

        self.shape = shape

        self.gpib.write(":FUNC:SHAP %s;" % shape)

    def set_duty_cycle(self, duty_cycle):
        """
        Sets the waveform duty_cycle (%). Only for square waves.
        :param duty_cycle:
        :return:
        """

        if self.shape != 'SQU':
            print('Duty cycle only for square functions')
            return

        self.gpib.write("SQU:DCYC %.2f;" % duty_cycle)

    def set_frequency(self, freq):
        """
        Sets the waveform frequency (Hz)
        :param freq:
        :return:
        """
        if freq > 250e6:
            print('Specified frequency is too high. No change')
            return

        self.gpib.write(":FREQ %.2E;" % freq)

    def close(self):
        print('Disconnecting Agilent Waveform Generator')
        self.gpib.close()

    def set_waveform(self, shape, freq, vpp, offset):
        """
        Generates the waveform with the specified parameters
        :param shape: shape of the waveform (sinusoidal, square...). "SIN", "SQU", "TRI", "RAMP", "NOIS", "DC"
        :param freq: frequency of the waveform (Hz)
        :param vpp: peak to peak voltage (V)
        :param offset: offset voltage (V)
        """

        self.set_shape(shape)
        self.set_frequency(freq)
        self.set_voltage(vpp, offset)

    def set_load(self, load):
        pass

    def load_PRBS(self, N, freq, Vpp, offset, samples_per_bit = 32):
        """
        Loads a PRBS signal into the arbitrary waveform memory, and sets the sample clock so that
        the output PRBS has the frequency freq.
        :param N: PRBS length
        :param freq: desired frequency (bps)
        :param Vpp: peak to peak voltage (V)
        :param offset: offset of teh PRBS (V)
        :param samples_per_bit: number of samples per bit
        :return:
        """

       	print('To load arbitrary waveforms, use the matlab code in <iqtools> folder. ')


if __name__ == '__main__':

    awg = Agilent81180A()
    awg.initialize()
    awg.turn_on()
    awg.set_waveform('SIN', 2e6, 2, 0.5)
    awg.turn_on()
    awg.close()
