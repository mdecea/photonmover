# This is an interface that any instrument that can
# be used as a digital multimeter can implement

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class DigitalMultimeter(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def initialize(self):
        """
        Initializes the instrument 
        """
        pass 


    @abstractmethod
    def get_voltage(self, voltage):
        """
        Sets the voltage to the specified value (in V)
        :return:
        """
        pass
    

    def get_id(self):
        return ("DigitalMultimeter")
