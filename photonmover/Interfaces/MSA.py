from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface


class MSA(ABC):

    def __init__(self):
        super().__init__()

    @abstractmethod
    def read_data(self, file=None, plot_data=True):
        """
        Reads MSA data and returns a two element list with
        frequencies and amplitudes
        :param file: If specified, a csv file will be generated with that name
        :param plot_data: If True, the trace data will be plotted
        :return: [frequencies, amplitudes]
        """
        pass

    def get_id(self):
        return ("MicrowaveSpectrumAnalyzer")
