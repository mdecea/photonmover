from photonmover.Interfaces.Experiment import Experiment

from photonmover.Interfaces.Laser import TunableLaser
from photonmover.Interfaces.PowMeter import PowerMeter

# Imports necessary for the example
from photonmover.instruments.Lasers.Superlum import Superlum
from photonmover.instruments.Optical_switches.Dicon import DiConOpticalSwitch
from photonmover.instruments.Power_meters.Thorlabs import ThorlabsPowerMeter
from photonmover.instruments.DAQ.NI_DAQ import NiDAQ
from photonmover.instruments.Choppers.RedPitayaChopper import RedPitayaChopper

import time
import numpy as np

MAX_NUM_WAV_SET_TRIALS = 10  # Number of times we attempt to set the wavelength


class SweptSourceRaman(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT:
        WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.laser = None
        self.chopper = None
        self.power_meter = None
        self.daq = None
        self.optical_switch = None

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError(
                "The instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments to perform the experiment are present.
        :param instrument_list: list of the available instruments
        :return: True if the instruments are present, False otherwise.
        """

        for instr in instrument_list:
            if isinstance(instr, TunableLaser):
                self.laser = instr
            if isinstance(instr, NiDAQ):
                self.daq = instr
            if isinstance(instr, RedPitayaChopper):
                self.chopper = instr
            if isinstance(instr, DiConOpticalSwitch):
                self.optical_switch = instr
            if isinstance(instr, PowerMeter):
                self.power_meter = instr

        if (self.laser is not None) and (self.daq is not None) and (
                self.optical_switch is not None) and (
                    self.power_meter is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Swept source raman measurement """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Swept Source"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dict of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)

        wavs = params["wavs"]
        # Channels to measure (of the Optical switch)
        channels = params["channels"]
        int_time = params["int_time"]  # Integration time in s
        num_reps = params["num_reps"]  # Number of repetitions of each spectra
        _ = params["lock-in"]  # If the measurement is a lock-in or not
        # Sampling frequency of the DAQ
        sampling_freq = params["sampling_freq"]

        # initializing output data structures
        power_output_dic = {}  # time domain power monitoring
        ni_output_dic = {}
        spectra_dic = {}
        spectra_norm_dic = {}
        spectra_std_dic = {}

        self.laser.turn_on()

        # Configure daq acquisition
        num_samples = int(int_time * sampling_freq)
        self.daq.task.timing.cfg_samp_clk_timing(
            sampling_freq, samps_per_chan=num_samples)

        # Let's go for the wavelength sweep
        for wav in wavs:

            success = False
            num_trials = 0

            # ------------ 1. --------------------
            # Try to set the wavelength of interest

            while (not success) and num_trials < MAX_NUM_WAV_SET_TRIALS:

                success = self.laser.set_wavelength(
                    wav)  # returns 1 if successful
                time.sleep(1.0)
                measured_wavelength = self.laser.get_wavelength()

                if abs(measured_wavelength - wav) > 0.01:
                    # using just wavelength setting in laser but may need to
                    # implement wavemeter
                    success = 0

                num_trials = num_trials + 1

            if num_trials == MAX_NUM_WAV_SET_TRIALS:
                print(
                    'We could not set to a %.3f nm wav. Skipping it' %
                    wav)
                continue

            # ---------- 2. ---------------
            # Measure now that the wavelength is correct
            print('Measuring %.2f nm wavlength.' % wav)

            self.power_meter.set_wavelength(measured_wavelength)
            # power = self.power_meter.get_powers()[0]

            for channel in channels:

                # time domain power monitoring
                power_output_dic[channel] = list()
                ni_output_dic[channel] = list()
                spectra_dic[channel] = list()
                spectra_norm_dic[channel] = list()
                spectra_std_dic[channel] = list()

                self.optical_switch.set_channel(channel)
                time.sleep(0.5)
                print(
                    'Measuring on channel %d' %
                    self.optical_switch.get_channel())

                for n in range(1, num_reps + 1):
                    print('Acquisition {} of {}'.format(n, num_reps))

                    buff_power = []
                    buff_ni = []

                    if self.daq is not None:
                        # Execute DAQ acquisition
                        self.daq.start_task()
                        self.daq.wait_task(
                            timeout=num_samples / sampling_freq * 1.5)
                        temp_buff = self.daq.read_data(num_samples)
                        buff_ni = temp_buff[0]
                        buff_power = temp_buff[1]

                    timevec = np.arange(0, len(buff_ni), 1) / sampling_freq

                    # Saves wavelength and add data to dictionary
                    power_output_dic[channel].append(
                        [measured_wavelength] + list(buff_power))
                    ni_output_dic[channel].append(
                        [measured_wavelength] + list(buff_ni))
                    time_array_save = np.concatenate((np.array([0]), timevec))

                # save data each round so to not lose all of it if the process
                # fails
                print('Writing output csv files for channel %d' % channel)

                if filename is not None:
                    time_tuple = time.localtime()
                    power_file_name = "SSR-power-%s-channel=%d--%d#%d#%d_%d#%d#%d.csv" % (
                        filename,
                        channel,
                        time_tuple[0],
                        time_tuple[1],
                        time_tuple[2],
                        time_tuple[3],
                        time_tuple[4],
                        time_tuple[5])

                    np.savetxt(
                        power_file_name,
                        np.vstack(
                            (time_array_save,
                             np.array(
                                 power_output_dic[channel]))).T,
                        delimiter=",",
                        fmt='%s')

                    nidaq_file_name = "SSR-nidaq-%s-channel=%d--%d#%d#%d_%d#%d#%d.csv" % (
                        filename,
                        channel,
                        time_tuple[0],
                        time_tuple[1],
                        time_tuple[2],
                        time_tuple[3],
                        time_tuple[4],
                        time_tuple[5])
                    np.savetxt(
                        nidaq_file_name,
                        np.vstack(
                            (time_array_save,
                             np.array(
                                 ni_output_dic[channel]))).T,
                        delimiter=",",
                        fmt='%s')

                    # Compute averages,
                    # output_dic[channel][repetitions][0]=wavelength,
                    # output_dic[channel][repetitions][1:]=voltage
                    tap = np.array(power_output_dic[channel])[-num_reps:, 1:]
                    signal = np.array(ni_output_dic[channel])[-num_reps:, 1:]

                    # tap_avg = np.mean(tap, axis=0)
                    # signal_avg = np.mean(signal, axis=0)

                    spectra_dic[channel].append(np.mean(signal))
                    spectra_std_dic[channel].append(np.std(signal))
                    spectra_norm_dic[channel].append(
                        np.mean(signal) / np.mean(tap))

        # Turn laser off
        self.laser.turn_off()

        return None, None

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in
        the params dictionnary, in order for
        a measurement to be performed
        """
        return [
            "wavs",
            "channels",
            "int_time",
            "num_reps",
            "lock-in",
            "sampling_freq"]

    def default_params(self):
        """
        This function returns a dictionnary with default parameters
        for the experiment. Not all parameters need to have a default value.
        If a parameter is not given in the list of parameters, we will
        check if there are default parameters and use them if provided.
        If there are not default parameters at all, just return an
        empty dictionnary.
        """
        return {"channels": [2]}

    def plot_data(self, canvas_handle, data=None):
        pass


if __name__ == '__main__':

    # ---------------- CONNECT TO INSTRUMENTS --------------------
    # Connect and initialize necessary instruments
    laser = Superlum(com_address='COM4', verbose=False)
    optical_switch = DiConOpticalSwitch(com_address='COM3', verbose=False)
    power_meter = ThorlabsPowerMeter()
    daq = NiDAQ()
    # chopper = RedPitayaChopper(hostname='rp-f08473.local')

    # Open connections
    laser.initialize()
    power_meter.initialize()
    optical_switch.initialize()
    daq.initialize()
    # chopper.initialize()

    # --------------- CONFIGURE INSTRUMENTS ---------------------
    # Initialize instruments to correct settings
    laser.init_function()  # Warm up laser and stuff
    # Set correct power range and bandwidth for power meter
    power_meter.init_function()

    # Create DAQ task to record voltages
    daq.configure_channel_acq(
        ["cDAQ1Mod1/ai0", "cDAQ1Mod1/ai1"], min_vals=[0.0, 0.0],
        max_vals=[10.0, 2.5])

    # Set chopper and turn it on
    # chopper.configure_modulation(shape='SQUARE',
    #                              shape_params={'freq': 10 ,
    #                                            'Vpp': 1.0,
    #                                            'Voffset': 0.5})
    # chopper.turn_on()

    # ------------- RUN EXPERIMENT --------------------------

    # EXPERIMENT PARAMETERS
    channels = [2]
    int_time = 1
    num_reps = 2
    wavs = np.linspace(778.93, 779, 2)

    base_file_name = 'trial'

    # SET UP THE EXPERIMENT
    instr_list = [laser, optical_switch, power_meter, daq]
    exp = SweptSourceRaman(instr_list)
    params = {
        "wavs": wavs,
        "channels": channels,
        "int_time": int_time,
        "num_reps": num_reps,
        "lock-in": False,
        "sampling_freq": 1000}

    # RUN IT
    exp.perform_experiment(params, filename=base_file_name)

    # ------------ CLOSE INSTRUMENTS ------------------------

    # Close instruments
    laser.close()
    optical_switch.close()
    power_meter.close()
    daq.close()
    # chopper.close()
