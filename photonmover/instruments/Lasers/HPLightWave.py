import sys
sys.path.insert(0,'../..')
import pyvisa as visa
import time
from Interfaces.Laser import TunableLaser
from Interfaces.Instrument import Instrument
from Interfaces.PowMeter import PowerMeter
import matplotlib.pyplot as plt
import math

# The HP Lightwave is particular because it is both a laser and a
# power meter.

HP_ADDR = "GPIB1::20::INSTR"
DEFAULT_INTEGRATION_TIME = 0.05
SWEEP_DWELL_TIME = 0.4 # Time to sleep at each wavelength when we do a
        # tx curve by setting each wavelength at a time (in s)


class HPLightWave(Instrument, TunableLaser, PowerMeter):

    def __init__(self, tap_channel, rec_channel, use_as_laser=True, integration_time=DEFAULT_INTEGRATION_TIME,
                 sweep_dwell_time=SWEEP_DWELL_TIME):
        super().__init__()

        self.lwmain = None
        self.tap_channel = tap_channel  # Power meter channel measuring the tap power
        self.rec_channel = rec_channel  # Power meter channel measuring the through power
        self.int_time = integration_time
        self.is_laser = use_as_laser
        self.sweep_dwell_time = sweep_dwell_time

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to HP laser and power meter')

        rm = visa.ResourceManager()
        self.lwmain = rm.open_resource(HP_ADDR, timeout=20000)

        self.initialize_sensors()

    def get_id(self):
        return(["Laser", "TunableLaser", "PowerMeter"])

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print('Closing connnection to HP laser')

        self.lwmain.write("INIT%d:CHAN1:CONT 1" % self.tap_channel)
        self.lwmain.write("INIT%d:CHAN1:CONT 1" % self.rec_channel)

        self.lwmain.close()

    def turn_off(self):
        """
        Turn light off
        :return:
        """
        if self.is_laser:
            print('Turning off HP laser')
            self.lwmain.write(":POW:STAT 0")

    def turn_on(self):
        """
        Turn light on
        :return:
        """
        if self.is_laser:
            print('Turning on HP laser')
            self.lwmain.write(":POW:STAT 1")

    def set_power(self, power):
        """
        Set the power to the specified value (in mW)
        :return:
        """

        if self.is_laser:
            print('Setting HP laser power to %.4f mW' % power)
            self.lwmain.write("POW %.7EMW" % power)
            time.sleep(0.01)

    def set_wavelength(self, wavelength):
        """
        Set the wavelength to the specified value (in nm)
        :return:
        """
        print('Setting HP laser wavelength to %.4f nm' % wavelength)

        self.lwmain.write("WAV %.7ENM" % wavelength)
        time.sleep(0.01)

        self.lwmain.write("SENS%d:CHAN1:POW:WAV %.7ENM" %
                          (self.tap_channel, wavelength))
        self.lwmain.write("SENS%d:CHAN1:POW:WAV %.7ENM" %
                          (self.rec_channel, wavelength))

    def get_powers(self):
        """
        Returns a list with the power measured in the tap port and in
        the through port. These ports will be specified in the init of
        the actual power_meter implementation.
        First element is the tap power, second the through power
        :return: A 2 element list with the power in W
        """

        self.lwmain.write("INIT%d:IMM" % self.tap_channel)
        self.lwmain.write("INIT%d:IMM" % self.rec_channel)

        power_tap_string = self.lwmain.query("FETC%d:POW?" % self.tap_channel)
        try:
            power_tap = max(0.0, float(power_tap_string))
        except ValueError:
            power_tap = 0.0

        received_power_string = self.lwmain.query("FETC%d:POW?" % self.rec_channel)

        try:
            received_power = max(0.0, float(received_power_string))
        except ValueError:
            received_power = 0.0

        self.lwmain.write("*CLS")

        return [power_tap, received_power]

    def initialize_sensors(self):
        """
        Initializes the power meters
        :return:
        """

        # Set integration time
        self.lwmain.write("SENS%d:CHAN1:POW:ATIME %.3fS" % (self.tap_channel, self.int_time))
        self.lwmain.write("SENS%d:CHAN1:POW:ATIME %.3fS" % (self.rec_channel, self.int_time))

        # Set units to mW
        self.lwmain.write("SENS%d:CHAN1:POW:UNIT 1" % self.tap_channel)
        self.lwmain.write("SENS%d:CHAN1:POW:UNIT 1" % self.rec_channel)

        # Automatic power range
        self.lwmain.write("SENS%d:CHAN1:POW:RANG:AUTO 1" % self.tap_channel)
        self.lwmain.write("SENS%d:CHAN1:POW:RANG:AUTO 1" % self.rec_channel)

        # Do not measure continuously
        self.lwmain.write("INIT%d:CHAN1:CONT 0" % self.tap_channel)
        self.lwmain.write("INIT%d:CHAN1:CONT 0" % self.rec_channel)

    def set_integration_time(self, channel, int_time):
        self.int_time = int_time
        self.lwmain.write("SENS%d:CHAN1:POW:ATIME %.3fS" % (channel, int_time))

    def set_range(self, channel=None, power_range='AUTO'):
        """
        Sets the power range of the power meter in the specified channel
        :param channel: Channel of the power meter
        :param power_range: The power range. If 'AUTO', it is set to AUTOMATIC. Else, it is the range in
        dBm (from -70 to 10 dBm in steps of 10 dBm)
        :return:
        """

        if channel is None:
            channel = self.rec_channel
        if power_range == 'AUTO':
            self.lwmain.write("SENS%d:POW:RANG:AUTO 1" % channel)

        else:
            if power_range <= -70:
                power_range = -70
            elif power_range <= -60:
                power_range = -60
            elif power_range <= -50:
                power_range = -50
            elif power_range <= -40:
                power_range = -40
            elif power_range <= -30:
                power_range = -30
            elif power_range <= -20:
                power_range = -20
            elif power_range <= -10:
                power_range = -10
            elif power_range <= 0:
                power_range = 0
            else:
                power_range = 10

            self.lwmain.write("SENS%d:POW:RANG:AUTO 0" % channel)
            self.lwmain.write("SENS%d:POW:RANG %dDBM" % (channel, int(power_range)))

    def start_sweep(self):
        self.lwmain.write("WAV:SWE START")

    def configure_sweep(self, init_wav, end_wav, num_wav):
        """
        Configures the laser to take a wavelength sweep
        :param init_wav:
        :param end_wav:
        :param num_wav:
        :return:
        """

        sweep_speed = self.__choose_sweep_speed__(end_wav, init_wav)
        
        step_width = round ( (end_wav - init_wav) / num_wav, 4 )  # in nm
        true_num_wavs = math.floor( (end_wav - init_wav)/step_width )

        sweep_time = (end_wav-init_wav)/sweep_speed

        # Configure laser sweep
        self.lwmain.write("WAV:SWE:CYCL 1")  # We only want one sweep
        self.lwmain.write("WAV:SWE:MODE CONT")  # Set to use continuous sweep (not stepped)
        self.lwmain.write("TRIG0:OUTP STF")  # One output trigger per step
        self.lwmain.write("WAV:SWE:SPE %.7ENM/S" % sweep_speed)  # sweep speed in nm/s
        self.lwmain.write("WAV:SWE:STEP %.7ENM" % step_width)
        self.lwmain.write("WAV:SWE:STAR %.7ENM" % init_wav)  # Start wavelength
        self.lwmain.write("WAV:SWE:STOP %.7ENM" % end_wav)  # Stop wavelength

        time.sleep(0.5)

        return sweep_time, true_num_wavs

    def __choose_sweep_speed__(self, end_wav, init_wav):

        # There are different sweep speeds: 0.5, 5, 20 and 40 nm/s
        # Choose depending on the range of the sweep

        if (end_wav - init_wav) > 30.0:
            sweep_speed = 5
        else:
            sweep_speed = 0.5  # in nm/s. This speed seems good. There is also 5 nm/s, 20 nm/s and 40 nm/s

        return sweep_speed


    def take_sweep(self, init_wav, end_wav, num_wav):
        """
        Takes a wavelength sweep from init_wav to end_wav with num_wav points,
        and measured the power.
        :return:
        """

        sweep_speed = self.__choose_sweep_speed__(end_wav, init_wav)
        
        total_sweep_time = (end_wav-init_wav)/sweep_speed  # in s
        #sweep_speed = (end_wav-init_wav)/total_sweep_time  # in nm/s
        #print(sweep_speed)
        step_width = round ( (end_wav - init_wav) / num_wav, 4 )  # in nm
        averaging_time = total_sweep_time*1e3/num_wav  # in ms

        # Configure power meter logging
        self.lwmain.write("SENS%d:CHAN1:FUNC:PAR:LOGG %d,%.7EMS" %
                          (self.tap_channel, num_wav, averaging_time))
        self.lwmain.write("SENS%d:CHAN1:FUNC:PAR:LOGG %d,%.7EMS" %
                          (self.rec_channel, num_wav, averaging_time))

        # Configure laser sweep
        self.lwmain.write("WAV:SWE:CYCL 1")  # We only want one sweep

        # self.lwmain.write("WAV:SWE:DWEL %.7EMS" % dwell_time)  # Dwell time (stepped sweep)

        self.lwmain.write("WAV:SWE:MODE CONT")  # Set to use continuous sweep (not stepped)
        self.lwmain.write("TRIG0:OUTP STF")  # Necessary for lambda logging. SWST
        self.lwmain.write("WAV:SWE:LLOG 1")  # Turn on lambda logging

        self.lwmain.write("WAV:SWE:SPE %.7ENM/S" % sweep_speed)  # sweep speed in nm/s
        self.lwmain.write("WAV:SWE:STEP %.7ENM" % step_width)

        self.lwmain.write("WAV:SWE:STAR %.7ENM" % init_wav)  # Start wavelength
        self.lwmain.write("WAV:SWE:STOP %.7ENM" % end_wav)  # Stop wavelength

        # = self.lwmain.query('WAV:SWE:CHEC?')
        #print(check_sweep)
        #if check_sweep != 'OK':
        #    print('Sweep not correct: ' + check_sweep)
        #    return

        # Trigger sweep and acquisition
        self.lwmain.write("TRIG%d:CHAN1:INP SME" %
                          self.rec_channel)
        self.lwmain.write("TRIG%d:CHAN1:INP SME" %
                          self.tap_channel)

        self.lwmain.write("SENS%d:CHAN1:FUNC:STAT LOGG,START" %
                          self.rec_channel)
        self.lwmain.write("SENS%d:CHAN1:FUNC:STAT LOGG,START" %
                          self.tap_channel)
        self.lwmain.write("WAV:SWE START")

        time.sleep(total_sweep_time+10)

        # Retrieve data
        wavs = self.lwmain.query_ascii_values(":READ:DATA?")
        print(wavs)

        self.lwmain.write("SENS%d:CHAN1:FUNC:RES?" %
                                                  self.rec_channel)
        rec_data = self.lwmain.read_raw().decode('ascii')
        print(rec_data)
        tap_data = self.lwmain.query_ascii_values("SENS%d:CHAN1:FUNC:RES?" %
                                                  self.tap_channel)
        wavs = self.lwmain.query_ascii_values(":READ:DATA?")

        return [wavs, rec_data, tap_data]

    def log_trial(self):
        """
        Copy the example given by the manual (no laser and power meter sync)
        """
        slot = 1
        num_points = 100
        av_time = 0.02

        # self.lwmain.write("*RST")
        # time.sleep(2)
        self.lwmain.write("*CLS")

        # self.lwmain.write("TRIG%d:OUTP DIS" % slot)
        self.lwmain.write("TRIG%d:INP CME" % slot)

        self.lwmain.write("SENS%d:CHAN1:FUNC:PAR:LOGG %d,%.7E" %
                          (slot, num_points, av_time))

        self.lwmain.write("SENS%d:CHAN1:FUNC:STAT LOGG,START" % slot)

        self.lwmain.write(":TRIG 2")

        time.sleep(num_points*av_time)

        # Check for acquisition finished
        acq_finished = self.lwmain.query("SENS%d:CHAN1:FUNC:STATE?" % slot)
        while not ('COMPLETE' in acq_finished):
            print(acq_finished)
            time.sleep(0.5)
            acq_finished = self.lwmain.query("SENS%d:CHAN1:FUNC:STATE?" % slot)
            sys.stdout.flush()
        print(acq_finished)

        # Acquisition finished, query the values
        self.lwmain.write("SENS%d:CHAN1:FUNC:RES?" % slot)

        # response = self.lwmain.read_raw()
        data = self.lwmain.read_binary_values()

        return data

        # The instrument returns the logging result in the following format:
        # #xyyyffff...; the first digit after the hash denotes the number of ascii
        # digits following (y) ; y specifies the number of binary data following;
        # "ffff" represent the 32Bit floats as log result.
        # response_ascii = response[0:2].decode('ascii')
        # print(response_ascii)
        # num_digits = response_ascii[1]
        # print(num_digits)
        #
        # num_points = response[2:2+int(num_digits)].decode('ascii')
        # print(num_points)
        # # Tentative things
        #
        # response = response[2+int(num_digits):]
        # print(float(response[0:4]))
        # #data = response.decode('ascii')
        # #print(data)
        # data = struct.unpack('<float', response[0:4])
        # print(data)

    def log_trial_2(self):
        """
        Play with triggering
        """
        slot = 1
        num_points = 40
        av_time = 0.02

        # self.lwmain.write("*RST")
        time.sleep(2)
        self.lwmain.write("*CLS")

        self.lwmain.write("SENS%d:CHAN1:FUNC:PAR:LOGG %d,%.7E" %
                          (slot, num_points, av_time))

        self.lwmain.write("WAVELENGTH:SWEEP:MODE CONTINUOUS")
        self.lwmain.write("WAVELENGTH:SWEEP:SPEED 5E-9")
        self.lwmain.write("WAVELENGTH:SWEEP:CYCLES 0")
        self.lwmain.write("WAVELENGTH:SWEEP:START 1520NM")
        self.lwmain.write("WAVELENGTH:SWEEP:STOP 1580NM")
        self.lwmain.write("WAVELENGTH:SWEEP:STEP 1NM")
        # print(self.lwmain.query("SOURCE0:WAVELENGTH:SWEEP:EXP?"))
        self.lwmain.write("INITIATE1:CONTINUOUS 0")

        self.lwmain.write("TRIG:CONF 3") # 1 for default
        print(self.lwmain.query(":TRIG:CONF?"))
        sys.stdout.flush()

        self.lwmain.write("TRIG0:OUTP STFINISHED")
        self.lwmain.write("TRIG0:INP SWSTARTED")
        self.lwmain.write("TRIG%d:OUTP DIS" % slot)
        self.lwmain.write("TRIG%d:INP SME" % slot)
        # self.lwmain.write("TRIG%d:INP IGN" % slot)
        print(self.lwmain.query("TRIG%d:INP?" % slot))
        # time.sleep(1)
        # print(self.lwmain.query("TRIG%d:OFFS?" % slot))
        sys.stdout.flush()

        # time.sleep(1)
        # time.sleep(num_points*av_time)

        self.lwmain.write("SENS%d:CHAN1:FUNC:STAT LOGG,START" % slot)
        time.sleep(3)

        self.lwmain.write("WAVELENGTH:SWEEP START")
        self.lwmain.write(":TRIG 2")

        # Check for acquisition finished
        acq_finished = self.lwmain.query("SENS%d:FUNC:STATE?" % slot)
        while not ('COMPLETE' in acq_finished):
            print(acq_finished)
            time.sleep(2)
            # self.lwmain.write(":TRIG 1")
            acq_finished = self.lwmain.query("SENS%d:CHAN1:FUNC:STATE?" % slot)
            sys.stdout.flush()
        print(acq_finished)

        # Acquisition finished, query the values
        self.lwmain.write("SENS%d:CHAN1:FUNC:RES?" % slot)

        # response = self.lwmain.read_raw()
        dt = self.lwmain.read_binary_values()

        return dt

    def get_state(self):
        """
        Returns a list wiht the following elements:
        1. The current wavelength
        2. The current power 
        3. If the laser is on or off.
        """

        power = self.lwmain.query_ascii_values(":SOUR:POW?") # Returns the power in W
        power = float(power[0])*1e3

        wav = self.lwmain.query_ascii_values("WAV?")  # Returns the wavelength in m
        wav = float(wav[0])*1e9

        state = self.lwmain.query_ascii_values(":POW:STAT?")
        state = int(state[0])

        return [wav, power, state]


if __name__ == '__main__':
    laser = HPLightWave(tap_channel=1, rec_channel=3)
    laser.initialize()
    print(laser.get_state())
    # laser.configure_sweep(1530, 1560, 300)
    laser.close()
    # laser.turn_on()
    # data = laser.log_trial_2()
    # plt.plot(data)
    # plt.show()
    # [wavs, rec_data, tap_data] = laser.take_sweep(1530.0, 1560.0, 201)

    # plt.plot(wavs, rec_data)
    # plt.plot(wavs, tap_data)
    # plt.show()
