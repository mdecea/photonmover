# This is an interface that any instrument that can
# be used as a source meter has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class WaveformGenerator(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def set_waveform(self, shape, freq, vpp, offset):
        """
        Generates the waveform with the specified parameters
        :param shape: shape of the waveform (sinusoidal, square...)
        :param freq: frequency of the waveform (Hz)
        :param vpp: peak to peak voltage (V)
        :param offset: offset voltage (V)
        """
        pass

    @abstractmethod
    def set_shape(self, shape):
        """
        Sets the waveform shape
        :param shape:
        :return:
        """


    @abstractmethod
    def set_frequency(self, freq):
        """
        Sets the waveform frequency (Hz)
        :param freq:
        :return:
        """


    @abstractmethod
    def set_duty_cycle(self, duty_cycle):
        """
        Sets the waveform duty_cycle (%)
        :param duty_cycle:
        :return:
        """

    @abstractmethod
    def set_load(self, load):
        """
        Sets the output load
        :param load:
        :return:
        """

    @abstractmethod
    def set_voltage(self, amplitude, offset):
        """
        Sets the voltage settings. If any of them is None, they are not modified
        :param amplitude: peak to peak amplitude (V)
        :param offset: offset voltage (V)
        :return:
        """

    def get_id(self):
        return("WaveformGenerator")
