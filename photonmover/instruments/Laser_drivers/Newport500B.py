import sys
from instruments.Source_meters.KeysightB2902A import DEFAULT_CURRENT_COMPLIANCE
sys.path.insert(0, '../..')
import time
import pyvisa as visa
from Interfaces.LaserDriver import LaserDriver
from Interfaces.Instrument import Instrument

"USB0::0x1AB1::0x04CE::DS1ZA201205030::INSTR"

USB[board]::manufacturer ID::model code::serial number[::USB interface number][::INSTR]
GPIB_ADDR = "GPIB1::29::INSTR"  # GPIB adress
DEFAULT_CURRENT_RANGE = 'high'   # Default current range in A
DEFAULT_CURRENT_COMPLIANCE = 1  # Default current compliance in A


class Newport500B(Instrument, LaserDriver):
    """
    Code for controlling Newport 500B laser driver through GPIB
    """

    def __init__(self, mode='constant_cur', cur_comp=DEFAULT_CURRENT_COMPLIANCE, current_range=DEFAULT_CURRENT_RANGE):
        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = None
        self.cur_range = current_range
        self.is_on = 0
        self.mode = mode
        self.cur_comp = cur_comp

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Keithley source meter')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDR, timeout=30000)
        except:
            raise ValueError('Cannot connect to the Keysight Source meter')

        self.init_function()

    def set_current_range(self, range):
        """
        Sets the current range. Range is either 'high' or 'low'
        """

        if range not in ['high', 'low']:
            print('Range for Newport 500B not recognized. Doing nothing.')
            return
        
        rng = 0 if range == 'high' else 1

        self.gpib.write('LAS:RANGE %d' % rng)
    
    def init_function(self):
        """
        Initializes the source meter
        """

        self.set_current_range(self.cur_range)
        self.set_mode(self.mode)
        self.set_current_compliance(self.cur_comp)

    def set_mode(self, mode):
        """
        Sets the mode, which can be 'constant_cur' or 'constant_pow'.
        In 'constant_pow', the controller tries to keep a constant photocurrent.
        """

        if mode not in ['constant_cur', 'constant_pow']:
            print('Mode for Newport laser driver not recognized. Doing nothing.')
            return
        
        md = 'I' if mode == 'constant_cur' else 'MDI'

        self.gpib.write('LAS:MODE:%s' % md)
        self.mode = mode

    def close(self):
        print('Disconnecting Newport laser driver')
        self.turn_off()
        self.gpib.close()

    def turn_on(self):
        """
        Turns the source on
        :return:
        """
        self.gpib.write("LAS:OUT 1")
        self.is_on = 1

    def turn_off(self):
        """
        Turns the source off
        :return:
        """
        self.gpib.write("LAS:OUT 0")
        self.is_on = 0

    def set_current_compliance(self, limit_i):
        """
        Sets the current compliance. limit_i is in A.
        """

        self.gpib.write('LAS:LIM:LDI %.4f' % limit_i*1e3)  # In the command the current limit is in mA
        self.cur_comp = limit_i

    def set_current(self, current):
        """
        Sets the specified current. If mode is constant current, then this is the drive current.
        If mode is constant photodiode current, then this is the desired constant photodiode current.
        :param current: in A
        :return:
        """

        if self.mode == 'constant_cur':
            self.gpib.write('LAS:LDI %.4f' % current*1e3)  # Command takes mA
        elif self.mode == 'constant_pow':
            self.gpib.write('LAS:MDI %.4f' % current*1e3)  # Command takes mA

    def measure_current(self):
        # Returns the current in A
        return float(self.gpib.query_ascii_values('LAS:LDI?')[0]*1e-3)

    def measure_voltage(self):
        # Returns the voltage in V
        return float(self.gpib.query_ascii_values('LAS:LDV?')[0])


if __name__ == '__main__':
    sm = Newport500B()
    sm.initialize()
    sm.set_current(0.7)
    sm.turn_on()
    time.sleep(5)
    sm.turn_off()
    sm.close()

