import sys
import time
import pyvisa as visa
from photonmover.Interfaces.LaserDriver import LaserDriver
from photonmover.Interfaces.Instrument import Instrument

COM_PORT = 6  # COM port number

class ThorlabsBOA(Instrument):
    """
    Code for controlling thorlabs tabletop SOA/BOAs through VISA/pyserial. 
    These are typically model numbers S7FC or S9FC.
    """

    def __init__(
            self,
            com_port = COM_PORT,
        ):
        super().__init__()

        self.com_port = com_port
        self.is_enabled = False
        self.instr = None


    def initialize(self):
        """
        Initializes the instrumen t
        :return:
        """
        print('Opening connnection to Thorlabs SOA/BOA')

        rm = visa.ResourceManager()
        try:
            self.instr = rm.open_resource('ASRL{:d}::INSTR'.format(self.com_port) )
        except BaseException:
            raise ValueError('Cannot connect to the Thorlabs SOA/BOA')

        self._set_init_params()

    def _set_init_params(self):
        """
        Initializes the amplifier with default parameters 
        """
        self.instr.baud_rate=115200 
        self.instr.read_termination = "\r"
        self.instr.write_termination = "\r"

        self.get_state() # check whether the amplifier is on already

    def close(self):
        print('Disconnecting Thorlabs SOA/BOA')
        self.turn_off()
        self.instr.close()
    
    def _clear_buffer(self): 
        """" 
        Clear remaining messages in the instrument serial buffer
        """
        buffersize = self.instr.bytes_in_buffer 
        if buffersize > 0: 
            self.instr.read_bytes(count=buffersize)

    def _query_instr(self, query): 
        """ 
        Formats an instrument query to strip the query return. 
        Basically just returns the SECOND read, since the first is 
        always the original query. 
        """
        self.instr.write(query) 
        time.sleep(0.1) 
        self.instr.read()
        return self.instr.read() 

    def identify(self):
        """
        Identify the instrument
        """
        return self._query_instr("id?")
           
    def turn_on(self):
        """
        Turns the amplifier on
        :return:
        """
        self._clear_buffer()
        self.instr.write("enable=1")
        self.is_enabled = True

    def turn_off(self):
        """
        Turns the amplifier off
        :return:
        """
        self._clear_buffer()
        self.instr.write("enable=0")
        self.is_enabled = False

    def get_state(self) -> None: 
        """ 
        Gets the current state (on/off) of the amplifier. 
        Updates the class attribute
        """
        self._clear_buffer() 
        self.is_enabled = bool(int(self._query_instr(query="enable?")))

    def get_current(self):
        """
        Returns the drive current, in mA
        """
        return float(self._query_instr("current?"))

    def set_current(self, current):
        """
        Sets the amplifier current. 
        :param current: in mA
        :return:
        """
        if current > 200:
            print("The set current cannot be above 200 mA" )
            return
        elif current < 0:
            print(" The set current cannot be negative")
            return 

        self._clear_buffer()
        self.instr.write("current={:f}".format(current))
    
    def get_temperature(self): 
        """
        Gets the actual amplifier temperature, in degC.
        """
        return float(self._query_instr("temp?"))

    def set_temperature(self, temperature): 
        """ 
        Sets the amplifier temperature, in degC.
        """
        self._clear_buffer()
        self.instr.write("target={:f}".format(temperature))

    def get_full_specs(self):
        """
        Returns the full "specifications" of the unit
        """
        self.instr.write( "specs?" )
        time.sleep(0.1)
        data = self.instr.read_bytes(count=self.instr.bytes_in_buffer).decode("utf8")
        return data.split('\r')



if __name__ == '__main__':
    soa = ThorlabsBOA()
    soa.initialize()
    soa.set_current(100)
    soa.turn_on()
    time.sleep(2)
    soa.turn_off()
    soa.close()

####
# # Available commands: 
# 'id?    ::    Identification Query',
# 'target    ::    Set Target Temperature (C)',
# 'target?    ::    Get Target Temperature (C)',
# 'temp?    ::    Get Actual Temperature (C)',
# 'current    ::    Set Current (mA)',
# 'current?    ::    Get Current (mA)',
# 'power?    ::    Get Power (mW)',
# 'enable    ::    Set Channel Enable (1: Enable, 0:Disabled)',
# 'enable?    ::    Get Channel Enable (1: Enable, 0:Disabled)',
# 'specs?    ::    Show Laser Diode Specifications',
# 'step    ::    Set Arrow Key Step Size (.01->10)',
# 'step?    ::    Get Arrow Key Step Size',
# 'save    ::    Save Parameters',
# 'statword?    ::    Status',
# #