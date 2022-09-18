# This is an interface for instruments which output CW microwave/RF tones

from abc import ABC, abstractmethod


class SignalGenerator(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def turn_on(self):
        """
        Turns the signal generator output on.
        """
        pass

    @abstractmethod
    def turn_off(self):
        """
        Turns the signal generator output off.
        """
        pass

    @abstractmethod
    def set_frequency(self, freq):
        """
        Sets the desired signal output frequency.
        :param freq: frequency of the waveform (Hz)
        """
        pass

    @abstractmethod
    def get_frequency(self):
        """
        Gets the current output frequency setpoint.
        """
        pass

    @abstractmethod
    def set_power(self, power):
        """
        Sets the signal generator's output power.
        :param power: Desired power output (into 50 ohm) [dBm]
        """
        pass

    @abstractmethod
    def get_power(self):
        """
        Gets the signal generator's output power setpoint.
        """
        pass

    @abstractmethod
    def set_voltage(self, amplitude=None, offset=None, Vmin=None, Vmax=None):
        """
        Sets the voltage settings. If any of them is None, they are
        not modified
        :param amplitude: peak to peak amplitude (V)
        :param offset: offset voltage (V)
        :return:
        """
        pass

    @abstractmethod
    def get_voltage(self):
        """
        Gets the signal generator's voltage setpoint.
        """
        pass
