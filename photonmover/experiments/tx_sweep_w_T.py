# This script performs a wavelength sweep by sweeping the temperature of the laser diode.
# It can also measure generated photocurrent if desired, by talking to a
# source meter.

from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

from photonmover.Interfaces.PowMeter import PowerMeter
from photonmover.Interfaces.SourceMeter import SourceMeter
from photonmover.Interfaces.WlMeter import WlMeter
from photonmover.Interfaces.TempController import TempController

from photonmover.utils.calibrator import CALIBRATION_FILENAME, get_calibration_factor

# These are necessay for executing the experiment from this file (if this
# file is the main file)
from photonmover.instruments.Lasers.HPLightWave import HPLightWave
from photonmover.instruments.Source_meters.Keithley2400 import Keithley2400
from photonmover.instruments.Wavelength_meters.BrsitolWlMeter import BristolWlMeter
from photonmover.instruments.Temperature_controllers.Newport3040 import Newport3040

import time
import numpy as np
import sys
import scipy.io as io
import winsound

# Calibration on 10/01/2020:
# WM TAP: 131.3 uW - 240 uW
# REC: 2.16 mW - 4.024 mW
# The power launched into the chip (before the input GC) is the measured
# wave meter power * CAL_FACTOR_WM.
CAL_FACTOR_WM = 16.608
# Note we are assuming that the calibration factor is independent of wavelength. This should be
# a good approximation given the small wavelength range we can actually sweep.

# Note: Another calibration factor for the power meter tap is needed, but
# we will get that number from the calibration file


class TXSweepT(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.pm = None
        self.T_controller = None
        self.wav_meter = None
        self.smu = None

        self.data = None

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError(
                "The necessary instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary to perform the experiment are present.
        :param instrument_list: list of the available instruments
        :return: True if the necessary instruments are present, False otherwise.
        """

        for instr in instrument_list:
            if isinstance(instr, PowerMeter):
                self.pm = instr
            if isinstance(instr, TempController):
                self.T_controller = instr
            if isinstance(instr, WlMeter):
                self.wav_meter = instr
            if isinstance(instr, SourceMeter):
                self.smu = instr

        if ((self.pm is not None)) and (self.T_controller is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Sweeps wavelength through a change in temperature, measures transmission and current if a SMU is connected. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Wav sweep w/ T controller"

    def set_temp(self, temp):
        # Sets the temperature and returns the new wavelength
        self.T_controller.set_temperature(temp)
        # Wait for the temp to stabilize
        time.sleep(1)
        return self.wav_meter.get_wavelength()

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionnary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)

        Ts = params["temperatures"]

        if self.smu is not None:
            self.smu.turn_on()

        prev_T = self.T_controller.get_temperature()

        # Initialize the matrix to save the data
        measurements = np.zeros((len(Ts), 8), float)
        row = 0

        for temp in Ts:

            wav = self.set_temp(temp)
            print(wav)
            time.sleep(1.5)

            tap_power_pm, measured_received_power = self.pm.get_powers()
            tap_power_wm = self.wav_meter.get_power()
            cur = self.source_meter.measure_current()

            cal_factor_pm = get_calibration_factor(wav)

            # Matrix data is the following:
            # Column 1: Measured wavelength from the wavemeter
            # Column 2: Set temperature of the laser diode
            # Column 3: raw tap power from the power meter
            # Column 4: raw tap power from the wave meter
            # Column 5: input power extracted from the power meter tap
            # Column 6: input power extracted from the wave meter
            # Column 7: received power (measured by the power meter)
            # Column 8: Generated photocurrent (if meas_current is True)
            measurements[row, 0] = wav
            measurements[row, 1] = temp
            measurements[row, 2] = tap_power_pm
            measurements[row, 3] = tap_power_wm
            measurements[row, 4] = tap_power_pm * cal_factor_pm
            measurements[row, 5] = tap_power_wm * CAL_FACTOR_WM
            measurements[row, 6] = measured_received_power
            measurements[row, 7] = cur

            print("Set Temp = %.3f C" % temp)
            print("Meas Wavelength = %.5f nm" % wav)
            print("Rec Power = %.3e W" % measured_received_power)
            sys.stdout.flush()

            row = row + 1

        if filename is not None:
            time_tuple = time.localtime()
            filename = "%s-Tsweep-%d-%d-%d--%d#%d#%d_%d#%d#%d.mat" % (filename,
                                                                      init_temp,
                                                                      end_temp,
                                                                      step_temp,
                                                                      time_tuple[0],
                                                                      time_tuple[1],
                                                                      time_tuple[2],
                                                                      time_tuple[3],
                                                                      time_tuple[4],
                                                                      time_tuple[5])

            out_file_path = filename
            print("Saving data to ", out_file_path)
            io.savemat(out_file_path, {'scattering': measurements})

        # Beep when done
        winsound.Beep(2000, 1000)

        # Go back to original temperature
        self.T_controller.set_temperature(prev_T)

        self.data = measurements

        return measurements

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["temperatures"]

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError(
                    'plot_data was called before performing the experiment or providing data')

        wavs = data[:, 0]
        powers = data[:, 6]

        plot_graph(
            x_data=wavs,
            y_data=powers,
            canvas_handle=canvas_handle,
            xlabel='Wavelength (nm)',
            ylabel='Power (mW)',
            title='T sweep',
            legend=None)


if __name__ == '__main__':

    # Connect to necessary instruments
    TAP_CHANNEL = 1  # Power meter channel measuring the launched power
    REC_CHANNEL = 3  # Power meter channel measuring the received power

    power_meter = HPLightWave(tap_channel=TAP_CHANNEL, rec_channel=REC_CHANNEL)
    power_meter.initialize()
    power_meter.set_wavelength(1180)

    temp_controller = Newport3040(channel=2)
    temp_controller.initialize()
    temp_controller.turn_on()

    wavemeter = BristolWlMeter()
    wavemeter.initialize()

    source_meter = Keithley2400()
    source_meter.initialize()

    # Create the experiment
    instr_list = [power_meter, temp_controller, wavemeter, source_meter]
    exp = TXSweepT(instr_list)

    # Ask for operation:
    close = False

    while close is False:

        next_op = input(
            "Enter operation (set [temp] - sweep [T0 T1 Tstep filename]) - end:")
        next_op = next_op.split()
        op = next_op[0]

        if op == 'set':
            try:
                temp = float(next_op[1])
                new_wav = exp.set_temp(temp)
                print('The measured wavelength is %.4f nm' % new_wav)
            except BaseException:
                print('Temeperature not recognized.')

        elif op == 'sweep':
            # try:
            init_temp = float(next_op[1])
            end_temp = float(next_op[2])
            step_temp = float(next_op[3])
            if len(next_op) == 5:
                file_name = next_op[4]
            else:
                file_name = None

            ts = np.arange(init_temp, end_temp + 0.001, step_temp)
            exp.perform_experiment({"temperatures": ts}, filename=file_name)

        elif op == 'end':
            close = True

        else:
            print('Operation not recognized. Enter a valid command. ')

    # Close connections
    wavemeter.close()
    temp_controller.close()
    power_meter.close()
    source_meter.close()
