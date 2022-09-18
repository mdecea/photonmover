import numpy as np
import pyvisa as visa
import time
from photonmover.Interfaces.TempController import TempController
from photonmover.Interfaces.Instrument import Instrument

GPIB_ADDR = "GPIB1::12::INSTR"  # GPIB adress


class Lakeshore331S(Instrument):

    """
    Code for controlling the Lakeshore 331S cryostat temp controller
    """

    def __init__(self):
        super().__init__()
        # It is good practice to initialize variables in init
        self.gpib = None

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Lakeshore Temp controller')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDR, timeout=5000)
        except BaseException:
            raise ValueError('Cannot connect to Newport Temp controller')

        self.init_function()

    def close(self):
        print('Disconnecting Newport Temp controller')
        # self.turn_off()
        self.gpib.close()

    def init_function(self):
        # Clear status
        self.gpib.write("*CLS")

    def get_temperature(self):
        # Queries the temperature of both channel A and B
        chan_a_temp = float(self.gpib.query_ascii_values('KRDG? A')[0])
        chan_b_temp = float(self.gpib.query_ascii_values('KRDG? B')[0])

        return [chan_a_temp, chan_b_temp]

    def turn_on(self, range=1):
        """
        Turns the heater on with the specified range.
        :param range: 1 --> Low (0.5W), 2 --> Med (5W), 3 --> High (50W)
        :return:
        """

        if range not in [1, 2, 3]:
            print('Specified heater range not recognized. Either 1, 2 or 3.')

        self.gpib.write('RANGE %d' % range)

    def turn_off(self):
        """
        Turns the heater off.
        :return:
        """
        self.gpib.write('RANGE 0')

    def set_temperature(self, temperature):
        # Sets the temperature (in K)
        self.gpib.write('SETP 1,%.2f' % temperature)


if __name__ == '__main__':
    tec = Lakeshore331S()
    tec.initialize()
    print(tec.get_temperature())
    tec.set_temperature(200)
    # tec.turn_on()
    tec.close()
