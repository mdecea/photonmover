# This is an interface that any instrument that can
# be used as a camera has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class Camera(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def get_frame(self, filename):
        """
        Grabs a frame and saves it to the specified filename
        :return: None
        """
        pass

    @abstractmethod
    def configure(self, params):
        """
        Configures the camera settings indicated in params.
        :param params: dictionnary with each setting as a key.
        """

    def get_id(self):
        return ("Camera")
