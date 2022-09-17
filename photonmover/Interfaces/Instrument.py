# This is an interface that any instrument has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface

class Instrument(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        pass

    @abstractmethod
    def close(self):
        """
        Closes the instrument
        :return:
        """
        pass