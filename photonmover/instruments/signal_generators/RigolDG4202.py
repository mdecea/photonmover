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

    def set_channel_output_state(self, state='off', channels=[1,2]):
        """
        Set the state of the channel output 
        """



    def get_channel_output_state(self):
        """
        Checks what the output state of each channel is. 
        Returns list of booleans.
        """


if __name__ == '__main__':

    siggen = RigolDG4202()
    addresses = siggen.find_address()
    siggen.initialize(override_address=addresses[0])

    siggen.close()
