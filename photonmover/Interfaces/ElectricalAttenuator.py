# This is an interface that any instrument that can
# be used as an electrical attenuator has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface

class ElectricalAttenuator(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def set_attenuation(self, attenuation):
        """
        Sets the attenuation to the value specified (in dB)
        :param attenuation: desired attenuation in dB
        :return: None
        """
        pass

    def get_id(self):
        return("ElectricalAttenuator")