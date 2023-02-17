import sys
import pyvisa as visa
import numpy as np
import time
import csv
from photonmover.Interfaces.Instrument import Instrument
from enum import Enum
sys.path.insert(0, '../..')


MANUFACTURER_ID = 0x1AB1

class SignalGenTypes(Enum):
    """ Container class for signal generator model definitions """
    DG4202 = 0x0641


class RigolDG4202(Instrument):
    """
    Code for controlling Rigol DG4202 Signal Generato via USB connection.
    INPUTS:
        * **instr_address** (str): USB address. If `None`, the instrument will
                            not connect, but methods exist to find available
                            DG4000 signal generators.
    """

    def __init__(self, instr_address=None):
        super().__init__()

        # It is good practice to initialize variables in init
        self.instr = None
        self.instr_address = instr_address

        self.rm = visa.ResourceManager()
        self.is_initialized = False

    def initialize(self, override_address=None):
        """
        Initializes the instrument. Optionally override the address provided
        during class instantiation.
        :return:
        """
        if override_address is not None:  # Assign new instrument address
            self._set_address(instr_address=override_address)

        if self.instr_address is None:
            print("No instrument address was provided, cannot initialize")
            return
        else:
            print('Opening connnection to Rigol Signal Generator')

            try:
                self.instr = self.rm.open_resource(
                    self.instr_address, timeout=10000)
                self.is_initialized = True
            except ConnectionError:
                raise ConnectionError('Cannot connect to Rigol Signal Generator')

    def close(self):
        print('Disconnecting Rigol Signal Generator')
        self.instr.close()

    def find_address(self):
        """
        Finds addresses of connected Rigol signal generators.
        If only one address exists, it automatically applies that address to
        the the invoking class instance. This overrides provided addresses.
        """
        model_string = ' '
        for spec in SignalGenTypes:
            model_string += '(VI_ATTR_MODEL_CODE==0x{:04X}) || '.format(
                spec.value)
            model_string = model_string.rstrip(' || ')
            search_string = "USB?*?{{VI_ATTR_MANF_ID==0x{:04X} && ({})}}".format(
                MANUFACTURER_ID, model_string)

        try:
            instr_list = self.rm.list_resources(search_string)
        except Warning:
            instr_list = []
            raise Warning("No connected signal generators were found")

        if len(instr_list) == 1:  # Only one relevant signal generator found, set as address
            print("Only found one applicable instrument, using this address.")
            print("Instrument address: {}".format(instr_list[0]))
            self._set_address(instr_address=instr_list[0])

    def _set_address(self, instr_address) -> None:
        """
        Set the USB interfacing address. Only works on un-initialized instantiations of the class.
        """
        if not self.is_initialized:
            self.instr_address = instr_address
        else:
            print("Cannot assign a new address to an initialized instrument.")

    def set_channel_output_state(self, state='off', channel=[1,2]):
        """
        Set the state of the channel output 
        """
        if not hasattr(channel, '__iter__'):
            channel=[channel]
        
        for chan in channel:
            state = state.upper()
            self.instr.write(":OUTPut{:d}:STATe {:s}".format(chan, state))

    def get_channel_output_state(self):
        """
        Returns the output state for BOTH channels 
        
        """
        states={}
        for chan in ["1","2"]:
            states[chan] = self.instr.query(":OUTPut{:s}:STATe?".format(chan)).rstrip('\n')
        
        return states
    
    def set_voltage_amplitude(self, voltage, channel):
        """
        Sets the signal amplitude of the specified 
        channel. 
        Only works on a single channel at a time. 
        """
        self.instr.write(":SOURce{:d}:VOLTage:AMPLitude {:f}".format(channel, voltage))  
    
    def get_voltage_amplitude(self, channel): 
        """
        Queries the set voltage of the specified
        channel. 
        """
        return self.instr.query(":SOURce{:d}:VOLTage:AMPLitude?".format(channel)).rstrip('\n')

    def set_frequency(self, freq, channel):
        """
        Set the frequency of the output signal
        
        * **freq** (float): Frequency in Hz. 
        """
        if not hasattr(channel, '__iter__'):
            channel=[channel]
        
        for chan in channel:
            self.instr.write(":SOURce{:d}:FREQuency {:f}".format(chan, freq))

    def get_frequency(self):
        """
        Get the frequency of the output signal on
        both channels. 

        Returns dict of set frequencies. 
        """
        
        freqs = {}
        for chan in ["1","2"]:
            freqs[chan] = self.instr.query(":SOURce{:s}:FREQuency?".format(chan)).rstrip('\n')
        return freqs 

    def set_output_impedance(self, impedance, channel):
        """
        Sets the output impedance for the specified channel. 

        * **channel** (int or list of ints): Channel number. 
                        Can be an int or a list of ints, e.g. 
                        channel=1 or channel=[1,2].
                        All channels are given the same impedance. 
        * **impedance** (multiple): Desired impedance value. Can
                        be 50 or "infinity" for high Z output. 
        """

        if not hasattr(channel, '__iter__'):
            channel=[channel]
        
        for chan in channel:
            if str(impedance) == "50":
                imp = "50"
            elif impedance.lower() == "infinity":
                imp = "INFinity" 

            self.instr.write(":OUTPut{:d}:IMPedance {:s}".format(chan, imp))


if __name__ == '__main__':

    siggen = RigolDG4202()
    addresses = siggen.find_address()
    siggen.initialize(override_address=addresses[0])

    siggen.close()
