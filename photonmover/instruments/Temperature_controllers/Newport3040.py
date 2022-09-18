import numpy as np
import pyvisa as visa
import time
from photonmover.Interfaces.TempController import TempController
from photonmover.Interfaces.Instrument import Instrument

GPIB_ADDR = "GPIB1::12::INSTR"  # GPIB adress


class Newport3040(Instrument, TempController):
    """
    Code for controlling Keysight B2902A through GPIB
    """

    def __init__(self, high_T_limit=80, low_T_limit=10, cur_limit=1, mode='T'):
        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = None
        self.high_T_lim = high_T_limit
        self.low_T_lim = low_T_limit
        self.cur_lim = cur_limit
        self.mode = mode

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Newport Temp controller')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDR, timeout=5000)
        except BaseException:
            raise ValueError('Cannot connect to Newport Temp controller')

        self.init_function()

    def init_function(self):
        self.set_high_temp_limit(self.high_T_lim)
        self.set_low_temp_limit(self.low_T_lim)
        self.set_current_limit(self.cur_lim)
        self.set_mode(self.mode)

    def close(self):
        print('Disconnecting Newport Temp controller')
        # self.turn_off()
        self.gpib.close()

    def set_channel(self, channel):
        self.gpib.write('TEC:CHAN %d,' % channel)

    def set_current(self, current):
        # Sets the TEC current (A)
        self.gpib.write('TEC:ITE %.9f,' % current)

    def set_current_limit(self, current_limit):
        # Sets the TEC current limit (A)
        self.gpib.write('TEC:LIM:ITE %.9f,' % current_limit)
        self.cur_lim = current_limit

    def set_high_temp_limit(self, high_temp_limit):
        # Sets the TEC maximum temperature
        self.gpib.write('TEC:LIM:THI %.2f,' % high_temp_limit)
        self.high_T_lim = high_temp_limit

    def set_low_temp_limit(self, low_temp_limit):
        # Sets the TEC maximum temperature
        self.gpib.write('TEC:LIM:TLO %.2f,' % low_temp_limit)
        self.low_T_lim = low_temp_limit

    def set_mode(self, mode):
        # Sets the TEC mode. 'ITE' for constant current, 'R' for constant R,
        # 'T' for constant T
        if mode not in ['ITE', 'R', 'T']:
            print('Selected TEC mode not recognized. Doing nothing.')
            return

        self.gpib.write('TEC:MODE:%s,' % mode)
        self.mode = mode

    def turn_on(self):
        self.gpib.write('TEC:OUT 1,')

    def turn_off(self):
        self.gpib.write('TEC:OUT 0,')

    def set_sensor(self, sensor):
        # Selects the temperature sensor type.
        # 0: None, 1: Thermistor at 100 uA drive, 2: Thermistor at 10 uA drive,
        # 3: LM335, 4: AD590, 5: RTD
        if sensor not in [0, 1, 2, 3, 4, 5]:
            print('Selected TEC sensor not recognized. DOing nothing.')
            return

        self.gpib.write('TEC:SEN %d,' % sensor)

    def set_temperature(self, temperature):
        # Sets the temperature (in deg C)
        self.gpib.write('TEC:T %.2f,' % temperature)

    def get_temperature(self):
        return float(self.gpib.query_ascii_values('TEC:T?,')[0])


if __name__ == '__main__':
    tec = Newport3040()
    tec.initialize()
    time.sleep(1)
    tec.turn_on()
    input()
    while (True):
        t = input("Enter T:")
        tec.set_temperature(float(t))
    tec.close()
