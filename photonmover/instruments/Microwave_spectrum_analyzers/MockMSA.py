import sys
sys.path.insert(0,'../..')
from Interfaces.MSA import MSA
from Interfaces.Instrument import Instrument
import numpy as np


class MockMSA(MSA, Instrument):

    def __init__(self):
        super().__init__()
        self.gpib = None

    def initialize(self):
        print('Opening connnection to MSA')

    def close(self):
        print('Disconnecting MSA')

    def read_data_lin_sweep(self, file=None, plot_data=True):
        print("Reading MSA trace")
        f = np.linspace(50, 30e9, 201)
        data = f
        return [f, data]

    def take_data(self, num_averages):
        print("Taking MSA trace with %d averages" % num_averages)

    def read_data(self, file=None, plot_data=True):
        print("Reading MSA trace")
        f = np.linspace(50, 30e9, 201)
        data = f
        return [f, data]

