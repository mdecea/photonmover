# This is an interface that any instrument that can
# be used as a motorized stage has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface

class SingleAxisStage(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def move(self, dist):
        """
        moves the stage the specified distance.
        :param dist: distance to move in mm
        """