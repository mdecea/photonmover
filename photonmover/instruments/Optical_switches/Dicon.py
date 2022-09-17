from photonmover.Interfaces.Instrument import Instrument
import serial
import time
import re


class DiConOpticalSwitch(Instrument):

    """
    Driver for DiCon FiberOptics MEMS 1xN Optical Switch Module on RS232 communication
    """

    def __init__(self, com_address='COM1', timeout=1.0, verbose=True):

        super().__init__()
        self.port = com_address
        self.timeout = timeout
        self.verbose = verbose
        self.channel = 0

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """

        print("Initializing connection to Dicon Optical Switch")

        self.ser = serial.Serial(self.port, baudrate=115200, timeout=self.timeout)

        # Read number of channels from module
        self.ser.reset_input_buffer()
        self.ser.write(b'CF?\r')
        self.ser.read() # dummy read the newline
        reply = self.ser.readline().decode("utf-8")

        try:
            self.channel_max = int(re.split(',', reply)[1])
        except Exception as ex:
            self.channel_max = 16
            print('Could not get number of channels from the optical switch')
            print(ex)
            print(reply)

        # Park switch
        self.park_switch()

    def identify(self):
        self.ser.reset_input_buffer()
        self.ser.write(b'ID?\r')
        self.ser.read() # dummy read the newline
        print('Dicon switch id: %s' % self.ser.readline())

    def set_channel(self, new_channel):
        if new_channel >=0 and new_channel <= self.channel_max:
            self.channel = new_channel
            self.ser.reset_input_buffer()
            self.ser.write(bytes('I1 {}\r'.format(new_channel), 'utf-8'))
        else:
            print('DiConOpticalSwitch: Invalid channel. Doing nothing.')

    def get_channel(self):
        """ Returns current channel setting of the switch"""
        self.ser.reset_input_buffer()
        self.ser.write(b'I1?\r')
        self.ser.read() # dummy read the newline
        resp = self.ser.readline()
        if self.verbose:
            print(resp)

        # Parse response
        ch = re.match(r"\d+", resp.decode('utf-8'))
        if ch is not None:
            return int(ch[0])
        else:
            return -1

    def park_switch(self):
        # Park switch
        self.ser.write(b'PK\r')

    def close(self):
        self.park_switch()

        # Close serial port
        self.ser.close()