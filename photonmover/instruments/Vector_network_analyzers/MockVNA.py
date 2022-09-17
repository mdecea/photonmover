from photonmover.Interfaces.VNA import VNA
from photonmover.Interfaces.Instrument import Instrument
import numpy as np


class MockVNA(VNA, Instrument):

    def __init__(self):
        super().__init__()
        self.gpib = None

    def initialize(self):
        print('Opening connnection to VNA')

    def close(self):
        print('Disconnecting VNA')

    def read_data_lin_sweep(self, file=None, plot_data=True):
        print("Reading VNA trace")
        f = np.linspace(50e6, 40e9, 201)
        data = f
        return [f, data]

    def take_data(self, num_averages):
        print("Taking VNA trace with %d averages" % num_averages)

    def read_data(self, file=None, plot_data=True):
        print("Reading VNA trace")
        f = np.linspace(50e6, 40e9, 201)
        data = f
        return [f, data]

