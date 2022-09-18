from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

from photonmover.Interfaces.Laser import TunableLaser
from photonmover.Interfaces.PowMeter import PowerMeter
from photonmover.instruments.DAQ.NI_DAQ import NiDAQ

from photonmover.utils.calibrator import CALIBRATION_FILENAME

import numpy as np
import pickle

# NI DAQ INPUTS
AIN_RECEIVED = "Dev1/ai0"  # Analog signal corresponding to the received power
AIN_TAP = "Dev1/ai1"  # Analog signal corresponding to the tap power
PFI_CLK = "/Dev1/pfi0"  # Trigger coming from the laser

LASER_POWER = 1.00  # mW (switchable). Power for the cailbration
MEAS_COUNT = 10  # Number of times the same wavelength is measured


class Calibration(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments.
        IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED
        ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.laser = None
        self.pm = None
        self.daq = None

        self.data = None

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
            if isinstance(instr, PowerMeter):
                self.pm = instr
            if isinstance(instr, NiDAQ):
                self.daq = instr

        if ((self.pm is not None) or (self.daq is not None)) and (
                self.laser is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return " Sweeps wavelength, measures transmission. Meant for " \
               " calibration of the ratio between the measured tap power " \
               " and the launched power."

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Calibration (tap to launched power)"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dict of the parameters necessary for the experiment.
        :param filename: unused. We calibration filename is always the same.
        :return:
        """

        params = self.check_all_params(params)

        wavs = params["wavs"]
        use_DAQ = params["use_DAQ"]

        if (self.daq is not None) and use_DAQ:
            meas = self.calibration_daq(wavs)
        elif self.pm is not None:
            meas = self.calibration_pm(wavs)
        else:
            print("Calibration cannot be performed. Doing nothing.")
            return

        # Save the calibration data in the pickle file
        pickle_file_object = open(CALIBRATION_FILENAME, 'w+b')
        pickle.dump((wavs, meas), pickle_file_object)
        pickle_file_object.close()

        self.data = [wavs, meas]

        return [wavs, meas]

    def calibration_pm(self, wavs):
        """
        Sweep wavelength, measure the ratio between tap and received power
        """

        # Save current state so that we can get back to it after the
        # calibration
        [prev_wl, prev_power, laser_active] = self.laser.get_state()

        new_calibration = []

        # Turn laser on if necessary
        if not laser_active:
            self.laser.turn_on()

        self.laser.set_power(LASER_POWER)

        for w in wavs:

            self.laser.set_wavelength(w)
            self.pm.set_wavelength(w)

            meas_list = list()

            for i in range(MEAS_COUNT):

                [tap_power, received_power] = self.laser.get_powers()
                ratio = tap_power / received_power
                meas_list.append(ratio)

            meas_array = np.array(meas_list)
            ave_ratio = meas_array.mean()
            new_calibration.append(ave_ratio)

            print("Mean ratio for %.2fnm = %.2f" % (w, ave_ratio))

        # Go back to previous state
        self.laser.set_wavelength(prev_wl)
        if not laser_active:
            self.laser.turn_off()
        else:
            self.laser.set_power(prev_power)

        return new_calibration

    def calibration_daq(self, wavs):

        [prev_wl, prev_power, laser_active] = self.laser.get_state()

        # Turn laser on if necessary
        if not laser_active:
            self.laser.turn_on()

        self.pm.set_range(self.pm.rec_channel, 0)
        # 0 dBm power range will work for the tap channel
        self.pm.set_range(self.pm.tap_channel, 0)

        self.laser.set_power(LASER_POWER)

        new_calibration = []

        for w in wavs:

            self.laser.set_wavelength(w)
            self.pm.set_wavelength(w)

            self.daq.configure_nsampl_acq(
                [AIN_RECEIVED, AIN_TAP],
                clk_channel=None,
                num_points=MEAS_COUNT)

            self.daq.start_task()
            self.daq.wait_task()
            daq_data = self.daq.read_data(MEAS_COUNT)

            ratios = []
            for i in range(len(daq_data[0])):
                # tap_power / received_power
                ratios.append(daq_data[1][i] / daq_data[0][i])

            meas_array = np.array(ratios)
            ave_ratio = meas_array.mean()
            new_calibration.append(ave_ratio)

            print("Mean ratio for %.2fnm = %.2f" % (w, ave_ratio))

        # Go back to previous state
        self.laser.set_wavelength(prev_wl)
        if not laser_active:
            self.laser.turn_off()
        else:
            self.laser.set_power(prev_power)

        self.pm.set_range(self.pm.rec_channel, -10)
        self.pm.set_range(self.pm.tap_channel, -10)
        self.pm.set_range(self.pm.rec_channel, 'AUTO')
        self.pm.set_range(self.pm.tap_channel, 'AUTO')

        return new_calibration

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in
        the params dictionary, in order for a measurement to be
        performed
        """
        return ["wavs", "use_DAQ"]

    def default_params(self):
        return {"use_DAQ": False}

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError(
                    'plot_data was called before performing the experiment'
                    'or providing data')

        wavs = data[0]
        meas = data[1]

        plot_graph(
            x_data=wavs,
            y_data=meas,
            canvas_handle=canvas_handle,
            xlabel='Wavelength (nm)',
            ylabel='Tap to received power ratio',
            title='Calibration',
            legend=None)
