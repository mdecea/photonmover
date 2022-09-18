import pyvisa as visa
import time
from photonmover.Interfaces.Laser import TunableLaser
from photonmover.Interfaces.Instrument import Instrument
import matplotlib.pyplot as plt

SANTEC_TSL550_GPIB_ADDRESS = 28

# Tunable Laser Source


class SantecTSL550(Instrument, TunableLaser):

    def __init__(self, gpib_address=SANTEC_TSL550_GPIB_ADDRESS, wait=0.5):
        super().__init__()
        self.gpib_address = gpib_address
        self.wait = wait

    def initialize(self):

        print('Opening connnection to Santec TSL550 laser')
        rm = visa.ResourceManager()
        self.gpib = rm.open_resource("GPIB1::%d" % (self.gpib_address))

        # Stop any measurements that it may currently doing
        if int(self.gpib.query_ascii_values("SOUR:WAV:SWE:STAT?")[0]) != 1:
            self.stop_sweep()

        self.get_id()
        # self.reset()
        self.disable_input_trigger()

        # Turn on laser
        self.turn_on_LD()

    def close(self):
        print('Closing connnection to Santec laser')
        self.gpib.close()

    def disable_input_trigger(self):
        self.gpib.write(":SOUR:TRIG:INP:EXT 0")

    def get_id(self):
        self.gpib.write("*IDN?")
        return self.gpib.read_raw()

    def reset(self):
        self.gpib.write("*RST")

    def turn_on_LD(self):
        self.gpib.write(":SOUR:POW:STAT 1")
        # It takes 1 to 2 minutes to turn on the laser
        time.sleep(0.1)
        while (self.gpib.query_ascii_values(":SOUR:POW:STAT?")[0] != 1.0):
            time.sleep(10)

    def turn_off_LD(self):
        self.gpib.write(":SOUR:POW:STAT 0")

    def turn_on(self):
        self.gpib.write(":SOUR:POW:SHUT 0")

    def turn_off(self):
        self.gpib.write(":SOUR:POW:SHUT 1")

    # mode = 0 --> dBm
    # mode = 1 --> mW
    def set_power_units(self, mode):
        self.gpib.write(":SOUR:POW:UNIT " + str(mode))

    def set_power(self, value):
        self.gpib.write(":SOUR:POW:LEV " + str(value))

    # wavelength in nm
    def set_wavelength(self, wav):
        self.gpib.write(":SOUR:WAV " + str(wav))

    # Configures the number of sweeps to perform
    def cfg_num_sweeps(self, num_sweeps):
        self.gpib.write(":SOUR:WAV:SWE:CYCL " + str(num_sweeps))

    # Configures the delay between continuous sweeps (in s)
    def cfg_delay(self, time):
        self.gpib.write(":SOUR:WAV:SWE:DEL " + str(time))

    # Configures the time between steps (in s)
    def cfg_dwell(self, time):
        self.gpib.write(":SOUR:WAV:SWE:DWEL " + str(time))

    # Sets the mode
    # 0 : Step operation, one way
    # 1 : Continuous operation, one way
    # 2 : Step operation, two way
    # 3 : Continuous operation, two way
    def cfg_mode(self, mode):
        self.gpib.write("SOUR:WAV:SWE:MOD " + str(mode))

    # Sets the sweep speed in the continuous sweep (in nm/s, between 0.5 and
    # 100)
    def cfg_speed(self, speed):
        self.gpib.write("SOUR:WAV:SWE:SPE " + str(speed))

    # Sets the start and stop wavelength of the sweep
    def cfg_start_stop(self, init_wav, end_wav):
        self.gpib.write("SOUR:WAV:SWE:STAR " + str(init_wav))
        self.gpib.write("SOUR:WAV:SWE:STOP " + str(end_wav))

    # Sets the step in wavelength (between 0.0001 and 160 nm)
    def cfg_sweep_step(self, step):
        self.gpib.write("SOUR:WAV:SWE:STEP " + str(step))

    # Starts a single sweep
    def start_sweep(self):
        # Stop any measurements that it may currently doing
        if int(self.gpib.query_ascii_values("SOUR:WAV:SWE:STAT?")[0]) != 1:
            self.stop_sweep()

        self.gpib.write("SOUR:WAV:SWE:STAT 1")

    # Stop sweep
    def stop_sweep(self):
        self.gpib.write("SOUR:WAV:SWE:STAT 0")

    # Starts conrinuous sweep
    def start_cont_sweep(self):
        self.gpib.write("SOUR:WAV:SWE:REP")

    # Configures the trigger
    # mode = 0: No output trigger
    # mode = 1: Triggers when sweep ended
    # mode = 2: Triggers when sweep starts
    # mode = 3: triggers every "step" nm
    def cfg_out_trig(self, mode, step=None):
        if (step is not None) and (mode == 3):
            self.gpib.write("SOUR:TRIG:OUTP:STEP:WIDT " + str(step))
        self.gpib.write("SOUR:TRIG:OUTP " + str(mode))

    # Configures the TSL to do a sweep by changing the wavelength continuously
    # mode = 0: One-way sweep. Mode = 1: two way sweep
    # delay: time between sweeps (in s)
    # speed: speed of the sweep (in nm/s)
    def cfg_cont_sweep(
            self,
            init_wav,
            end_wav,
            speed,
            delay=1,
            mode=0,
            num_sweeps=1):

        self.cfg_num_sweeps(num_sweeps)
        self.cfg_delay(delay)
        self.cfg_speed(speed)
        self.cfg_start_stop(init_wav, end_wav)

        if mode == 0:
            self.cfg_mode(1)
        else:
            self.cfg_mode(3)

    # COnfigures the TSL to do a sweep by stepping the wavelength
    # mode = 0: One-way sweep. Mode = 1: two way sweep
    # dwell: time spent in each step (in s)
    def cfg_step_sweep(
            self,
            init_wav,
            end_wav,
            step,
            dwell,
            mode=0,
            num_sweeps=1):
        self.cfg_num_sweeps(num_sweeps)
        self.cfg_dwell(dwell)
        self.cfg_sweep_step(step)
        self.cfg_start_stop(init_wav, end_wav)
        self.cfg_sweep_step(step)

        if mode == 0:
            self.cfg_mode(0)
        else:
            self.cfg_mode(2)

    def get_state(self):
        """
        Returns a list wiht the following elements:
        1. The current wavelength
        2. The current power
        3. If the laser is on or off.
        """

        power = self.gpib.query_ascii_values(":SOUR:POW:LEV?")
        power = float(power[0])

        wav = self.gpib.query_ascii_values(":SOUR:WAV?")
        wav = float(wav[0])

        state = self.gpib.query_ascii_values(":SOUR:POW:SHUT?")
        state = int(state[0])

        return [wav, power, state]


if __name__ == '__main__':
    myLaser = SantecTSL550(SANTEC_TSL550_GPIB_ADDRESS)
    myLaser.initialize()
    myLaser.set_wavelength(1270)
    myLaser.set_power(0.2)
    myLaser.turn_on()

    input()
    # while True:
    #    wavelength = input("Enter desired wavelength: ")
    #   print("Setting wavelength " + wavelength)
    #    myLaser.set_wavelength(float(wavelength))

    # Test wav sweep
    myLaser.cfg_out_trig(2)  # Trigger signal when sweep starts
    myLaser.cfg_cont_sweep(1265.0, 1310.0, 2)
    input()
    myLaser.start_sweep()
    myLaser.close()
