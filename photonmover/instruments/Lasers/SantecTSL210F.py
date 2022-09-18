import pyvisa as visa
import time
from photonmover.Interfaces.Laser import TunableLaser
from photonmover.Interfaces.Instrument import Instrument

SANTEC_1_ADDR = "GPIB1::7::INSTR"
SANTEC_2_ADDR = "GPIB1::8::INSTR"
SANTEC_3_ADDR = "GPIB1::9::INSTR"
SANTEC_4_ADDR = "GPIB1::10::INSTR"

SWEEP_DWELL_TIME = 1  # Time to sleep at each wavelength when we do a
# tx curve by setting each wavelength at a time (in s)


class SantecTSL210F(Instrument, TunableLaser):
    """
    Handler to the Santec Tunable Laser. It is a little special because
    it has 4 lasers, and each laser has a different GPIB address
    """

    def __init__(self, sweep_dwell_time=SWEEP_DWELL_TIME):
        super().__init__()

        self.santec1 = None
        self.santec2 = None
        self.santec3 = None
        self.santec4 = None
        self.active_module = -1
        self.wav = 1280.0
        self.power = 1
        self.sweep_dwell_time = sweep_dwell_time

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Santec laser')

        rm = visa.ResourceManager()
        self.santec1 = rm.open_resource(SANTEC_1_ADDR, timeout=1000)
        self.santec2 = rm.open_resource(SANTEC_2_ADDR, timeout=1000)
        self.santec3 = rm.open_resource(SANTEC_3_ADDR, timeout=1000)
        self.santec4 = rm.open_resource(SANTEC_4_ADDR, timeout=1000)

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print('Closing connnection to Santec laser')
        self.santec1.close()
        self.santec2.close()
        self.santec3.close()
        self.santec4.close()

    def turn_off(self):
        """
        Turn light off
        :return:
        """
        print('Turning off Santec laser')

        self.active_module = -1
        self.santec1.write("LF")
        self.santec2.write("LF")
        self.santec3.write("LF")
        self.santec4.write("LF")

    def turn_on(self):
        """
        Turn light on
        :return:
        """
        print('Turning on Santec laser')
        self.active_module = 0
        self.santec1.write("LO")
        self.santec2.write("LO")
        self.santec3.write("LO")
        self.santec4.write("LO")

    def set_power(self, power):
        """
        Set the power to the specified value (in mW)
        :return:
        """
        print('Setting santec power to %.4f mW' % power)
        self.santec1.write("LP %.2f" % power)
        self.santec2.write("LP %.2f" % power)
        self.santec3.write("LP %.2f" % power)
        self.santec4.write("LP %.2f" % power)
        self.power = power

    def set_wavelength(self, wavelength):
        """
        Set the wavelength to the specified value (in nm)
        :return:
        """
        print('Setting Santec wavelength to %.4f nm' % wavelength)

        # We need to select which of the 4 lasers to select depending on
        # the desired wavelength

        if 1530.0 < wavelength < 1630.000001:
            self.santec1.write("SW 4")
            self.santec4.write("WA %.4f" % wavelength)
            if self.active_module != 4:
                self.active_module = 4
                time.sleep(5.00)
            else:
                time.sleep(0.01)

        elif 1440.0 < wavelength < 1530.1:
            self.santec1.write("SW 3")
            self.santec3.write("WA %.4f" % wavelength)
            if self.active_module != 3:
                self.active_module = 3
                time.sleep(5.00)
            else:
                time.sleep(0.01)

        elif 1355 < wavelength < 1440.1:
            self.santec1.write("SW 2")
            self.santec2.write("WA %.4f" % wavelength)
            if self.active_module != 2:
                self.active_module = 2
                time.sleep(5.00)
            else:
                time.sleep(0.01)

        elif 1259.999999 < wavelength < 1355.1:
            self.santec1.write("SW 1")
            self.santec1.write("WA %.4f" % wavelength)
            if self.active_module != 1:
                self.active_module = 1
                time.sleep(5.00)
            else:
                time.sleep(0.01)

        else:
            print("Wavelength out of range. No change will be made")
            return

        self.wav = wavelength

    def get_state(self):
        """
        Returns a list wiht the following elements:
        1. The current wavelength
        2. The current power
        3. If the laser is on or off.
        """
        if self.active_module >= 0:
            state = 1
        else:
            state = 0

        return [self.wav, self.power, state]
