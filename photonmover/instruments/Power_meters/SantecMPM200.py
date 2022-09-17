import pyvisa as visa
import photonmover.instruments.Power_meters.real_plotter as real_plotter
import struct
import matplotlib.pyplot as pyplot
import time
import math
import numpy as np
from photonmover.Interfaces.Instrument import Instrument
from photonmover.Interfaces.PowMeter import PowerMeter

SANTEC_MPM200_GPIB_ADDRESS = 16

# Power meter with GPIB interface
class SantecMPM200(Instrument, PowerMeter):

    def __init__(self, rec_port=1, tap_port=None, module=0, gpib_address=SANTEC_MPM200_GPIB_ADDRESS):

        super().__init__()
        self.gpib_address = gpib_address
        self.rec_port = rec_port
        self.tap_port = tap_port
        self.module = module

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Santec MPM200 power meter')

        rm = visa.ResourceManager()
        self.gpib = rm.open_resource("GPIB1::%d" % (self.gpib_address))

        # Stop any measurements that it may currently doing
        if int(self.gpib.query_ascii_values("STAT?")[0]) != 1:
            self.stop_meas()

        # Flush out all its errors
        self.read_all_errors(print_errors=False)
        # self.set_range(None, -20)

        # Create variable for wavelength offset power table
        self.wop = dict()

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print('Closing connnection to Santec MPM200')

        self.gpib.close()

    def init_id(self):
        self.gpib.write("*IDN?")
        self.id_str = self.gpib.read_raw().strip()

    def read_all_errors(self, print_errors=True):
        self.gpib.write('ERR?')
        err = self.gpib.read_raw()
        while "0," not in str(err):
            if print_errors:
                print("Error: %s" % err)
            self.gpib.write('ERR?')
            err = self.gpib.read_raw()

    def cfg_mode(self, mode):
        if mode in ["CONST1", "CONST2", "SWEEP1", "SWEEP2", "FREERUN"]:
            self.gpib.write("WMOD %s" % mode)
        else:
            print("Specified mode not correct")

    # units = 0 --> dBm
    # units = 1 --> mW
    def cfg_units(self, units):
        if units in [0, 1]:
            self.gpib.write("UNIT %s" % units)
        else:
            print("Specified unit not correct")

    def cfg_trigger(self, internal):
        self.gpib.write("TRIG 0" if internal else "TRIG 1")

    def cfg_freerun_samples(self, samples):
        if (samples < 1 or samples > 1000000):
            print("Specified number of samples not correct")
            return
        self.gpib.write("LOGN %d" % samples)

    def cfg_sweep_wavelength(self, start, stop, step):
        if (start < 1260 or start > 1630):
            print("Start wavelength out of range")
            return
        if (stop < 1260 or stop > 1630):
            print("Stop wavelength out of range")
            return
        if (step < 0.002 or step > 10):
            print("Wavelength stop out of range")
            return
        self.gpib.write("WSET %.3f %.3f %.3f" % (start, stop, step))

    def cfg_sweep_speed(self, speed):
        if (speed < 0.001 or speed > 100):
            print("Sweep speed out of range")
            return
        self.gpib.write("SPE %.3f" % speed)

    # FGS stands for fast gain switching
    def cfg_fgs_average_time(self, time):
        if (time < 0.05 or time > 10000):
            print("fast gain switching averaging time out of range")
            return
        self.gpib.write("FGSAVG %.2f" % time)

    def set_wavelength(self, wave):
        if (wave < 1260 or wave > 1630):
            print("Wavelength out of range")
            return
        self.gpib.write("WAV %.3f" % wave)

    def cfg_average_time(self, time):
        if (time < 0.05 or time > 10000):
            print("Measurement averaging time out of range")
            return
        self.gpib.write("AVG %.2f" % time)

    # Configures the TIA gain level
    # Lev = 1 goes up to +5dBm
    # Lev = 2 goes up to +0dBm
    # Lev = 3 goes up to -15dBm
    # Lev = 4 goes up to -25dBm
    # Lev = 5 goes up to -40dBm
    def set_range(self, channel, rng):

        # Ignore the channel, just have it here to comply with the interface
        if rng == 'AUTO':
            self.cfg_mode("CONST2")

        else:
            if rng < -40:
                lev = 5
            elif rng < -25:
                lev = 4
            elif rng < -15:
                lev = 3
            elif rng < 0:
                lev = 2
            else:
                lev = 1

            print(lev)
            self.cfg_mode("CONST1")
            #self.gpib.write("LEV %d, %d, %d" % (lev, self.module, channel))
            self.gpib.write("LEV %d" % lev)

    def start_meas(self):
        self.gpib.write("MEAS")

    def stop_meas(self):
        self.gpib.write("STOP")

    def create_power_offset_table(self, port):
        wop = [-1e9]
        # Get all the calibrated power offset data
        for i in range(1, 20):
            wop.append(float(self.gpib.query_ascii_values("CWAVPO? %d,%d,%d" % (self.module, port, i))[0]))
        self.wop[(self.module, port)] = wop

    def get_power_offset_raw(self, port, wavelength):
        if (self.module, port) not in self.wop:
            self.create_power_offset_table(port)

        wop = self.wop[(self.module, port)]
        x0_num = int(min(max(math.floor((wavelength - 1270) / 20) + 1, 1), 19))
        x1_num = int(min(max(math.ceil((wavelength - 1270) / 20) + 1, 1), 19))
        if x0_num == x1_num:
            return wop[x0_num]
        else:
            x0 = (20 * (x0_num - 1)) + 1270
            x1 = (20 * (x1_num - 1)) + 1270
            y0 = wop[x0_num]
            y1 = wop[x1_num]
            return (y1 - y0) / (x1 - x0) * (wavelength - x0) + y0

    def get_power_offsets(self, port, wavelengths, wave_ref):
        if self.module < 0 or self.module > 4:
            print("Module number out of range")
            return
        if port < 1 or port > 4:
            print("Port number out of range")
            return

        # Perform offset calculation for the fixed wavelength
        fwop = self.get_power_offset_raw(port, wave_ref)
        # Perform offset calculation for all wavelengths
        po = []
        for wavelength in wavelengths:
            po.append(self.get_power_offset_raw(port, wavelength) - fwop)
        return po

    def get_logged_data(self, port):
        if self.module < 0 or self.module > 4:
            print("Module number out of range")
            return
        if port < 1 or port > 4:
            print("Port number out of range")
            return

        # Read the status indicator and the number of digits of the length sequence
        self.gpib.write("LOGG? %d,%d" % (self.module, port))
        status = self.gpib.read_raw()  # buf_size = 2 read_raw
        #print(status)
        # Detect if the logged data is invalid
        if status[0:1] != b'#':
            raise Exception("Logged data is invalid!")

        # Read the number of bytes to read to read the length of the data sequence
        #print(int(status[1:2]))
        num_bytes = int(status[2:2 + int(status[1:2])])
        #print(num_bytes)

        # Need a while loop to read everything
        raw_data = status[2 + int(status[1:2]) : 2 + int(status[1:2]) + num_bytes]

        data = []
        for i in range(0, num_bytes, 4):
            data += struct.unpack('f', raw_data[i:i + 4])
        return data

    def get_powers(self):
        all_powers = self.get_all_powers()
        # They are given in dBm, so we need to translate to W
        if self.tap_port is not None:
            return [np.power(10, all_powers[self.tap_port-1]/10)*1e-3, np.power(10, all_powers[self.rec_port-1]/10)*1e-3]
        else:
            return [1, np.power(10, all_powers[self.rec_port-1]/10)*1e-3]

    def get_all_powers(self):
        return list(map(float, self.gpib.query_ascii_values("READ? %d" % self.module)))

    def get_power_now_gen(self):
        while True:
            yield (self.get_all_powers())

    # Configure the MPM to take nsamples measurements at the wavelength wav with external trigger
    def cfg_nsamples_meas(self, nsamples, wav, auto_gain=False, ref_level=None, avg_time=1):

        self.cfg_trigger(internal=False)
        self.cfg_wavelength(wav)
        self.cfg_average_time(avg_time)
        self.cfg_freerun_samples(nsamples)

        if auto_gain:
            self.cfg_mode("CONST2")
        else:
            if ref_level is not None:
                self.set_range(None, ref_level)
            self.cfg_mode("CONST1")

        self.read_all_errors()

    # Takes step sweep data from TSL550
    def cfg_step_sweep(self, wave_start, wave_end, wave_step, sweep_speed, auto_gain=False, ref_level=None):

        self.cfg_trigger(internal=False)

        if auto_gain:
            self.cfg_mode("SWEEP2")
        else:
            if ref_level is not None:
                self.set_range(None, ref_level)
            self.cfg_mode("SWEEP1")

        self.cfg_sweep_wavelength(wave_start, wave_end, wave_step)
        self.cfg_sweep_speed(sweep_speed)  # max(5, sweep_speed)

        self.read_all_errors()

    # Takes continuous sweep data from TSL550
    def cfg_cont_sweep(self, wave_start, wave_end, sweep_speed, num_samples, ref_level=None):

        self.cfg_trigger(internal=False)
        self.cfg_freerun_samples(num_samples)
        # Calculate the average time necessary to do the measurement
        avg_time = float(((float(wave_end - wave_start) / float(sweep_speed) / num_samples))) * 1e3
        self.cfg_average_time(avg_time)
        self.cfg_mode("FREERUN")
        self.set_wavelength(wave_start)

        self.read_all_errors()

    # Waits for the measurement to be finished
    def wait_meas(self, print_status=True):
        result = list(map(int, self.gpib.query_ascii_values("STAT?")))
        while result[0] != 1:
            time.sleep(0.1)
            result = list(map(int, self.gpib.query_ascii_values("STAT?")))
            if print_status:
                print("Measuring... %d\r" % int(result[1]))

        if print_status:
            print("Measuring... %d DONE" % int(result[1]))


if __name__ == '__main__':
    pm = SantecMPM200()
    pm.initialize()
    # Close any existing plots
    pyplot.close('all')

    # pm.cfg_nsamples_meas(300, 1280)
    # pm.start_meas()
    # pm.wait_meas(modulcd in   e = 0, port = 4, print_status = True)

    # Get all the power values
    # power_data = pm.get_logged_data(module = 0, port = 4)
    # print power_data

    # sys.exit(0)

    #print(pm.gpib.query_ascii_values("LEV?"))
    #input()
    pm.set_range(2, -17)
    print(pm.gpib.query_ascii_values("LEV?"))
    #input()
    pm.cfg_average_time(5)
    pm.set_wavelength(1280)
    pm.cfg_fgs_average_time(5)

    #pm.set_range(2, -15)


    # print(list(pm.get_powers()))

    # print pm.get_logged_data(0,4)

    fig1 = pyplot.figure(figsize=(12, 6))
    blah = real_plotter.RealPlotter(fig1, pm.get_power_now_gen(), 10)
    blah.start_animation()

    # # -----------------------------------------------------------------
    # # Testing sweep
    # # Configure power meter for sweep
    # init_wav = 1265.0
    # end_wav = 1310.0
    # num_wav = 100
    # wav_speed = 2
    #
    # pm.cfg_cont_sweep(init_wav, end_wav, wav_speed, num_wav)
    #
    # input()
    # # Start the measurement
    # pm.start_meas()
    # time.sleep(5)
    # # Wait until measurement is done
    # pm.wait_meas(print_status=True)
    # pm.stop_meas()
    #
    # input()
    # # Obtain the logged data
    # rec_powers = pm.get_logged_data(port=1)
    # print(rec_powers)
    #
    # po = pm.get_power_offsets(port=1,
    #                           wavelengths=np.linspace(init_wav, end_wav, num_wav), wave_ref=init_wav)
    # rec_cal_powers = map(lambda x, y: x + y, rec_powers, po)
    #
    # print(rec_cal_powers)
    # # -------------------------------------------------