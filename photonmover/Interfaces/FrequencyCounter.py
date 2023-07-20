# This is an interface for instruments which count cycles of a tone or return "instantaneous" frequency.

from abc import ABC, abstractmethod

class FrequencyCounter(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod 
    def initialize(self):
        """
        Initializes the instrument 
        """
        pass 
    
    @abstractmethod
    def get_frequency(self, freq):
        """
        Sets the desired signal output frequency.
        :param freq: frequency of the waveform (Hz)
        """
        pass

    @abstractmethod 
    def close(self):
        """ 
        Closes the instrument connection
        """
        pass 