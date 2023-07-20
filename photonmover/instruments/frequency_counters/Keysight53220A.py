import sys
import time
import pyvisa as visa
from photonmover.Interfaces.FrequencyCounter import FrequencyCounter
from photonmover.Interfaces.Instrument import Instrument



class Keysight53220A(Instrument, FrequencyCounter):
    """
    Code for controlling thorlabs tabletop SOA/BOAs through VISA/pyserial. 
    These are typically model numbers S7FC or S9FC.
    """

    def __init__(
            self,
            gpib_address = "GPIB1::4::INSTR",
        ):
        super().__init__()

        self.gpib_address = gpib_address
        self.instr = None


    def initialize(self):
        """
        Initializes the instrumen t
        :return:
        """
        print('Opening connnection to Keysight Frequency Counter')

        rm = visa.ResourceManager()
        try:
            self.instr = rm.open_resource(
                self.gpib_address, timeout=6000)  # 2 min timeout
            print('Connected to Keysight frequency counter')
        except BaseException:
            raise ValueError('Cannot connect to the Keysight frequency counter')
        
    def close(self):
        print('Disconnecting Keysight frequency counter')
        self.instr.close()
    
    def identify(self):
        """
        Identify the instrument
        """
        return self.query("*IDN?")

    def get_frequency(self, channel=[1,2], res=1e-1, f0=10e6):
        """ 
        Set measurement parameters and immediately trigger a frequency measurement 
        on the specified channel(s). 
        Data is read from the instrument.

        Measurements on the two channels are NOT concurrent. 

        * **channel** (int):    Channel to make measurement on. Can be 1, 2, or [1,2].
        * **res** (float):      Frequency resolution, in Hz.
        * **f0** (numeric):     Approximate expected frequency
        """

        freq = []
        if not hasattr(channel, '__iter__'):
            channel=[channel]
        
        for chan in channel:
            self.instr.write("MEAS:FREQ? {:s}, {:s}, (@{:d})".format(str(f0), str(res), chan))
            meas = self.instr.read()
            freq.append( float(meas.strip("\n")) )
        
        return freq
        


if __name__ == '__main__':
    counter = Keysight53220A()
    counter.initialize()
    counter.identify()
    counter.close()
