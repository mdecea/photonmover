from ctypes import *
from photonmover.Interfaces.WlMeter import WlMeter
from photonmover.Interfaces.Instrument import Instrument

DLL_PATH = "C:\\BristolWavelengthMeterV2_31b\\CLDevIFace.dll"


class BristolWlMeter(Instrument, WlMeter):

    def __init__(self, dll_path=DLL_PATH):
        super().__init__()

        # It is good practice to initialize variables in the init
        self.bristoldll = None
        self.bristol_handle = None
        self.bristol_get_wave = None
        self.dll_path = dll_path

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Bristol Wavelength meter')

        # Load the wavemeter DLL
        self.bristoldll = CDLL(self.dll_path)
        self.bristol_handle = self.bristoldll.CLOpenUSBSerialDevice(
            c_long(3))  # had been 4
        if self.bristol_handle == -1:
            print("ERROR OPENING WAVEMETER")
            self.bristol_get_wave = None
        else:
            # self.bristoldll.CLSetAutoSend(c_uint(1))
            # self.bristoldll.CLSetAcqFreq(c_uint(1))
            self.bristol_get_wave = self.bristoldll.CLGetLambdaReading
            self.bristol_get_wave.restype = c_double
            self.bristol_get_power = self.bristoldll.CLGetPowerReading
            self.bristol_get_power.restype = c_float

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print('Closing connnection to Bristol Wavelength meter')
        wmeter_close_success = self.bristoldll.CLCloseDevice(
            self.bristol_handle)

        if not wmeter_close_success == 0:
            print("ERROR CLOSING BRISTOL WAVELENGTH METER DEVICE")

    def get_wavelength(self):
        """
        Returns the wavelength in nm
        :return:
        """

        if self.bristol_get_wave:
            measured_wavelength = self.bristol_get_wave(self.bristol_handle)
        else:
            measured_wavelength = -1

        return measured_wavelength

    def get_power(self):
        """
        Returns the power in mW
        :return:
        """

        if self.bristol_get_power:
            measured_power = self.bristol_get_power(self.bristol_handle)
        else:
            measured_power = -1

        return measured_power
