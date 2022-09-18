from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

from photonmover.Interfaces.Laser import TunableLaser
from photonmover.Interfaces.PowMeter import PowerMeter
from photonmover.Interfaces.SourceMeter import SourceMeter
from photonmover.Interfaces.WlMeter import WlMeter
from photonmover.instruments.DAQ.NI_DAQ import NiDAQ
from photonmover.instruments.Power_meters.SantecMPM200 import SantecMPM200
from photonmover.instruments.Lasers.HPLightWave import HPLightWave
from photonmover.utils.calibrator import analyze_powers
import numpy as np
import time
import sys
import scipy.io as io
import winsound

# For the examples
from photonmover.instruments.Source_meters.Keithley2635A import Keithley2635A
from photonmover.instruments.Source_meters.KeysightB2902A import KeysightB2902A
from photonmover.instruments.Source_meters.Keithley2400 import Keithley2400

# NI DAQ INPUTS
AIN_RECEIVED = "Dev1/ai0"  # Analog signal corresponding to the received power
AIN_TAP = "Dev1/ai1"  # Analog signal corresponding to the tap power
PFI_CLK = "/Dev1/pfi0"  # Trigger coming from the laser


class TXSweep(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.laser = None
        self.pm = None
        self.daq = None
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
            if isinstance(instr, TunableLaser):
                # We need to account for the chance that the HPLightWave is not
                # the laser
                if isinstance(instr, HPLightWave):
                    if instr.is_laser:
                        self.laser = instr
                else:
                    self.laser = instr
            if isinstance(instr, PowerMeter):
                self.pm = instr
            if isinstance(instr, NiDAQ):
                self.daq = instr
            if isinstance(instr, WlMeter):
                self.wav_meter = instr
            if isinstance(instr, SourceMeter):
                self.smu = instr

        if ((self.pm is not None) or (self.daq is not None)) and (
                self.laser is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Sweeps wavelength, measures transmission. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Tx"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionnary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """
        """
        Dictionary keys:
                  wavs --> List of wavelengths
                  use_DAQ --> Boolean. If True, we use the DAQ.
                  power_range --> Power range for the received power channel of the pwoer meter (only for DAQ sweep)
                  calibrate --> If true, it will use the calibration data
                  meas_current --> If true (and there is a source meter connected), current is measured at each wavelength point
        """

        params = self.check_all_params(params)

        wavs = params["wavs"]
        use_DAQ = params["use_DAQ"]
        calibrate = params["calibrate"]
        # Current can only be measured with the mainframe
        meas_current = params["meas_current"]
        rec_splitter_ratio = params["rec_splitter_ratio"]

        if (self.daq is not None) and use_DAQ:
            power_range = params["power_range"]
            meas = self.perform_tx_measurement_daq(
                wavs, power_range, calibrate, rec_splitter_ratio, filename)
        elif self.pm is not None:
            # See if we use the HP lightwave or the MPM200
            if isinstance(self.laser, SantecMPM200):
                print('Tx measurent with MPM200')
                meas = self.perform_tx_measurement_MPM200(
                    wavs, calibrate, rec_splitter_ratio, filename)
            elif isinstance(self.laser, HPLightWave):
                print('Tx measurent with HPLightwave')
                meas = self.perform_tx_measurement_mainframe(
                    wavs, calibrate, meas_current, rec_splitter_ratio, filename)
            else:
                print('Tx measurent with HPLightwave')
                meas = self.perform_tx_measurement_mainframe(
                    wavs, calibrate, meas_current, rec_splitter_ratio, filename)

        self.data = meas

        return meas

    def default_params(self):
        return {
            "calibrate": True,
            "meas_current": False,
            "use_DAQ": False,
            "power_range": None,
            "rec_splitter_ratio": 1}

    def perform_tx_measurement_mainframe(
            self,
            wavs,
            calibrate,
            meas_current,
            rec_splitter_ratio,
            filename=None):
        """
        Performs a wavelength sweep using the mainframe to interrogate the received power
        """

        # Initialize the matrix to save the data
        measurements = np.zeros((len(wavs), 7), float)

        # Save current state so that we can get back to it after the
        # measurement
        [prev_wl, _, laser_active] = self.laser.get_state()

        # Turn laser on if necessary
        if not laser_active:
            self.laser.turn_on()

        row = 0

        for wav in wavs:

            self.laser.set_wavelength(wav)
            print('Wavelength set')
            self.pm.set_wavelength(wav)
            time.sleep(self.laser.sweep_dwell_time)

            tap_power, measured_received_power = self.pm.get_powers()
            through_loss, measured_input_power = analyze_powers(
                tap_power, measured_received_power, wav, calibrate, rec_splitter_ratio)

            if self.wav_meter is not None:
                meas_wavelength = self.wav_meter.get_wavelength()
            else:
                meas_wavelength = None

            if meas_current and (self.smu is not None):
                current = self.smu.measure_current()
            else:
                current = None

            measurements[row, 0] = meas_wavelength
            measurements[row, 1] = through_loss
            measurements[row, 2] = measured_input_power
            measurements[row, 3] = wav
            measurements[row, 4] = measured_received_power
            measurements[row, 5] = tap_power
            measurements[row, 6] = current

            print("Set Wavelength = %.3f nm" % wav)
            if meas_wavelength is not None:
                print("Meas Wavelength = %.5f nm" % meas_wavelength)
            print("Rec Power = %.3e mW" % measured_received_power)
            print("Transmission Loss = %.2f dB" % through_loss)
            sys.stdout.flush()

            row = row + 1

        if filename is not None:

            time_tuple = time.localtime()
            filename = "%s-tx_wav_sweep-%.2f-%d-%.2f--%d#%d#%d_%d#%d#%d.mat" % (filename,
                                                                                wavs[0],
                                                                                len(wavs),
                                                                                wavs[-1],
                                                                                time_tuple[0],
                                                                                time_tuple[1],
                                                                                time_tuple[2],
                                                                                time_tuple[3],
                                                                                time_tuple[4],
                                                                                time_tuple[5])

            print("Saving data to ", filename)
            io.savemat(filename, {'scattering': measurements})

        # Beep when done
        winsound.Beep(2000, 1000)

        # Return to previous state
        self.laser.set_wavelength(prev_wl)

        if not laser_active:
            self.laser.turn_off()

        return measurements

    def perform_tx_measurement_daq(
            self,
            wavs,
            power_range,
            calibrate,
            rec_splitter_ratio,
            filename=None):
        """
        Performs a wavelength sweep using the NI DAQ to interrogate the received power
        """

        [prev_wl, _, laser_active] = self.laser.get_state()

        # Turn laser on if necessary
        if not laser_active:
            self.laser.turn_on()

        sweep_time, true_num_wavs = self.laser.configure_sweep(
            wavs[0], wavs[-1], len(wavs))  # Configure the laser wavelength sweep

        # We need to account for the case that the power range is set to AUTO, in which case we need
        # to fix it
        pm_auto = False
        if power_range == 'AUTO' or power_range is None:
            pm_auto = True  # To put it back to auto afterwards
            # Get the current received power and decide the range based on that
            _, measured_received_power = self.pm.get_powers()
            meas_power_dBm = 10 * np.log10(measured_received_power * 1e3)
            power_range = np.ceil(meas_power_dBm / 10) * 10
            self.pm.set_range(self.pm.rec_channel, power_range)

        else:
            self.pm.set_range(self.pm.rec_channel, power_range)
        # 0 dBm power range will work for the tap channel
        self.pm.set_range(self.pm.tap_channel, 0)

        self.daq.configure_nsampl_acq(
            [AIN_RECEIVED, AIN_TAP], PFI_CLK, true_num_wavs)

        self.daq.start_task()
        self.laser.start_sweep()
        self.daq.wait_task(timeout=sweep_time + 10)
        daq_data = self.daq.read_data(true_num_wavs)
        # Matrix to save the data
        measurements = np.zeros((true_num_wavs, 7), float)

        wavs = np.linspace(wavs[0], wavs[-1], true_num_wavs)

        for i in range(len(wavs)):

            # Need to convert voltage to power, based on the range

            # power in W
            measured_received_power = daq_data[0][i] * \
                np.power(10, (power_range / 10)) * 1e-3
            tap_power = daq_data[1][i] * np.power(10, (0 / 10)) * 1e-3

            through_loss, measured_input_power = analyze_powers(
                tap_power, measured_received_power, wavs[i], calibrate, rec_splitter_ratio)

            measurements[i, 0] = 0.0   # We don't measure the wavelength
            measurements[i, 1] = through_loss
            measurements[i, 2] = measured_input_power
            measurements[i, 3] = wavs[i]
            measurements[i, 4] = measured_received_power
            measurements[i, 5] = tap_power

        if filename is not None:

            time_tuple = time.localtime()
            filename = "%s-tx_wav_sweep_DAQ-%.2f-%d-%.2f--%d#%d#%d_%d#%d#%d.mat" % (filename,
                                                                                    wavs[0],
                                                                                    len(wavs),
                                                                                    wavs[-1],
                                                                                    time_tuple[0],
                                                                                    time_tuple[1],
                                                                                    time_tuple[2],
                                                                                    time_tuple[3],
                                                                                    time_tuple[4],
                                                                                    time_tuple[5])

            print("Saving data to ", filename)
            io.savemat(filename, {'scattering': measurements})

        # Beep when done
        winsound.Beep(2000, 1000)  # frequency, duration

        # Return to previous state
        self.laser.set_wavelength(prev_wl)

        if pm_auto:
            self.pm.set_range(self.pm.rec_channel, 'AUTO')
            self.pm.set_range(self.pm.tap_channel, 'AUTO')

        if not laser_active:
            self.laser.turn_off()

        return measurements

    def perform_tx_measurement_MPM200(
            self,
            wavs,
            calibrate,
            rec_splitter_ratio,
            filename=None):
        """
        Performs a wavelength sweep using the MPM200 to interrogate the power
        """

        [prev_wl, _, laser_active] = self.laser.get_state()

        init_wav = wavs[0]
        end_wav = wavs[-1]
        num_wav = len(wavs) + 1

        if (end_wav - init_wav) > 20:
            wav_speed = 15
        # elif (end_wav-init_wav)/num_wav < 0.005:
        #    wav_speed = 0.5
        else:
            wav_speed = 1
        # wav_speed = np.min([15, np.max([num_wav*0.1e-3,
        # (end_wav-init_wav)/15])])  # speed in nm/s

        # Turn laser on if necessary
        if not laser_active:
            self.laser.turn_on()

        self.laser.set_wavelength(init_wav)

        # Configure laser for sweep (mode and trigger)
        self.laser.cfg_out_trig(2)  # Trigger signal when sweep starts
        self.laser.cfg_cont_sweep(init_wav, end_wav, wav_speed)

        # Configure power meter for sweep
        self.pm.cfg_cont_sweep(init_wav, end_wav, wav_speed, num_wav)

        # Start the measurement
        self.pm.start_meas()
        self.laser.start_sweep()

        # Wait until measurement is done
        self.pm.wait_meas(print_status=False)
        self.pm.stop_meas()

        # Obtain the logged data
        rec_powers = self.pm.get_logged_data(port=self.pm.rec_port)

        # In the continuous sweep it is necessary to calibrate the power data
        po = self.power_meter.get_power_offsets(
            port=self.pm.rec_port, wavelengths=np.linspace(
                init_wav, end_wav, num_wav), wave_ref=init_wav)
        rec_cal_powers = list(map(lambda x, y: x + y, rec_powers, po))

        if self.pm.tap_port is not None:
            ref_powers = self.power_meter.get_logged_data(
                port=self.pm.tap_port)
            po = self.power_meter.get_power_offsets(
                port=self.pm.tap_port, wavelengths=np.linspace(
                    init_wav, end_wav, num_wav), wave_ref=init_wav)
            ref_cal_powers = list(map(lambda x, y: x + y, ref_powers, po))
        else:
            ref_cal_powers = None

        # Now we have the data. Save it.

        # Matrix to save the data
        measurements = np.zeros((len(self.wavs) + 1, 6), float)

        wavs = np.linspace(init_wav, end_wav, num_wav)

        for i in range(len(wavs)):

            rec_power = np.power(10, rec_cal_powers[i] / 10) * 1e-3
            if self.pm.tap_port is not None:
                tap_power = np.power(10, ref_cal_powers[i] / 10) * 1e-3
            else:
                tap_power = None

            through_loss, measured_input_power = analyze_powers(
                tap_power, rec_power, wavs[i], calibrate, rec_splitter_ratio)

            measurements[i, 0] = 0.0  # We don't measure the wavelength
            measurements[i, 1] = through_loss
            measurements[i, 2] = measured_input_power
            measurements[i, 3] = wavs[i]
            measurements[i, 4] = rec_power
            measurements[i, 5] = tap_power

        if filename is not None:

            time_tuple = time.localtime()
            filename = "%s-tx_wav_sweep-%.2f-%d-%.2f--%d#%d#%d_%d#%d#%d.mat" % (filename,
                                                                                init_wav,
                                                                                num_wav,
                                                                                end_wav,
                                                                                time_tuple[0],
                                                                                time_tuple[1],
                                                                                time_tuple[2],
                                                                                time_tuple[3],
                                                                                time_tuple[4],
                                                                                time_tuple[5])

            print("Saving data to ", filename)
            io.savemat(filename, {'scattering': measurements})

        # Beep when done
        winsound.Beep(2000, 1000)

        # Return to previous state
        self.laser.set_wavelength(prev_wl)

        if not laser_active:
            self.laser.turn_off()

        return measurements

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionary, in order for
        a measurement to be performed
        """
        return [
            "wavs",
            "use_DAQ",
            "calibrate",
            "meas_current",
            "power_range",
            "rec_splitter_ratio"]

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError(
                    'plot_data was called before performing the experiment or providing data')

        wavs = data[:, 3]
        tx = data[:, 1]
        plot_graph(
            x_data=wavs,
            y_data=tx,
            canvas_handle=canvas_handle,
            xlabel='Wavelength (nm)',
            ylabel='Tx (dB)',
            title='Tx spectrum',
            legend=None)


class TXBiasVSweep(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT
        THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.laser = None
        self.pm = None
        self.smu = None
        self.daq = None
        self.wav_meter = None

        self.data = None
        self.legend = None  # To save the legend for plotting

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
            if isinstance(instr, TunableLaser):
                # We need to account for the chance that the HPLightWave is not
                # the laser
                if isinstance(instr, HPLightWave):
                    if instr.is_laser:
                        self.laser = instr
                else:
                    self.laser = instr
            if isinstance(instr, PowerMeter):
                self.pm = instr
            if isinstance(instr, SourceMeter):
                self.smu = instr
            if isinstance(instr, NiDAQ):
                self.daq = instr
            if isinstance(instr, WlMeter):
                self.wav_meter = instr

        if ((self.pm is not None) or (self.daq is not None)) and (
                self.laser is not None) and (self.smu is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Sweeps wavelength and bias voltage, measures transmission. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Tx vs V"

    def perform_experiment(self, params, filename=None):

        params = self.check_all_params(params)

        wavs = params["wavs"]
        volts = params["voltages"]
        use_DAQ = params["use_DAQ"]
        power_range = params["power_range"]
        meas_current = params["meas_current"]
        calibrate = params["calibrate"]
        rec_splitter_ratio = params["rec_splitter_ratio"]

        [prev_wl, _, laser_active] = self.laser.get_state()
        prev_bias = self.smu.measure_voltage()

        # Turn laser on if necessary
        if not laser_active:
            self.laser.turn_on()

        self.legend = []
        all_meas_data = []

        for v_set in volts:

            # We just have to set the voltage and do a Tx Measurement.
            self.smu.set_voltage(v_set)
            i_bias = self.smu.measure_current()

            self.legend.append('V = %d mV' % (v_set * 1e3))

            tx_sing_v = TXSweep(
                [self.laser, self.smu, self.pm, self.daq, self.wav_meter])
            measurement = tx_sing_v.perform_experiment(
                params={
                    "wavs": wavs,
                    "use_DAQ": use_DAQ,
                    "power_range": power_range,
                    "meas_current": meas_current,
                    "calibrate": calibrate,
                    "rec_splitter_ratio": rec_splitter_ratio},
                filename=None)

            all_meas_data.append(measurement[:, 1])

            if filename is not None:
                time_tuple = time.localtime()
                filename_comp = "%s-TxvsV-%d%s-I_meas=%.2eA-%.2fnm-%d-%.2fnm--%d#%d#%d--%d#%d#%d.mat" % (filename,
                                                                                                         1000 * v_set,
                                                                                                         "mV",
                                                                                                         i_bias,
                                                                                                         wavs[0],
                                                                                                         len(wavs),
                                                                                                         wavs[-1],
                                                                                                         time_tuple[0],
                                                                                                         time_tuple[1],
                                                                                                         time_tuple[2],
                                                                                                         time_tuple[3],
                                                                                                         time_tuple[4],
                                                                                                         time_tuple[5])

                print("Saving data to ", filename_comp)
                io.savemat(filename_comp, {'scattering': measurement})

        # Return to previous state
        self.laser.set_wavelength(prev_wl)
        self.pm.set_wavelength(prev_wl)
        self.smu.set_voltage(prev_bias)

        if not laser_active:
            self.laser.turn_off()

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_plt_data = [measurement[:, 3]]
        all_plt_data.extend(all_meas_data)

        self.data = all_plt_data

        return all_plt_data

    def default_params(self):
        return {
            "calibrate": True,
            "meas_current": False,
            "use_DAQ": False,
            "power_range": None,
            "rec_splitter_ratio": 1}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return [
            "wavs",
            "use_DAQ",
            "calibrate",
            "meas_current",
            "voltages",
            "power_range",
            "rec_splitter_ratio"]

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError(
                    'plot_data was called before performing the experiment or providing data')

        x_data = data[0]
        y_data = data[1:]
        plot_graph(
            x_data=x_data,
            y_data=y_data,
            canvas_handle=canvas_handle,
            xlabel='Wavelength (nm)',
            ylabel='Tx (dB)',
            title='Tx spectrum vs V',
            legend=self.legend)


class TXBiasISweep(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.laser = None
        self.pm = None
        self.smu = None
        self.daq = None
        self.wav_meter = None

        self.data = None
        self.legend = None  # To save the legend for plotting

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
            if isinstance(instr, TunableLaser):
                # We need to account for the chance that the HPLightWave is not
                # the laser
                if isinstance(instr, HPLightWave):
                    if instr.is_laser:
                        self.laser = instr
                else:
                    self.laser = instr
            if isinstance(instr, PowerMeter):
                self.pm = instr
            if isinstance(instr, SourceMeter):
                self.smu = instr
            if isinstance(instr, NiDAQ):
                self.daq = instr
            if isinstance(instr, WlMeter):
                self.wav_meter = instr

        if ((self.pm is not None) or (self.daq is not None)) and (
                self.laser is not None) and (self.smu is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Sweeps wavelength and bias voltage, measures transmission. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Tx vs I"

    def perform_experiment(self, params, filename=None):

        params = self.check_all_params(params)

        wavs = params["wavs"]
        curs = params["currents"]
        use_DAQ = params["use_DAQ"]
        power_range = params["power_range"]
        calibrate = params["calibrate"]
        rec_splitter_ratio = params["rec_splitter_ratio"]

        [prev_wl, _, laser_active] = self.laser.get_state()
        prev_bias = self.smu.measure_current()

        # Turn laser on if necessary
        if not laser_active:
            self.laser.turn_on()

        self.legend = []
        all_meas_data = []

        for i_set in curs:

            # We just have to set the voltage and do a Tx Measurement.
            self.smu.set_current(i_set)
            v_meas = self.smu.measure_voltage()

            self.legend.append('I = %.2e A' % (i_set))

            tx_sing_v = TXSweep(
                [self.laser, self.smu, self.pm, self.daq, self.wav_meter])
            measurement = tx_sing_v.perform_experiment(
                params={
                    "wavs": wavs,
                    "use_DAQ": use_DAQ,
                    "power_range": power_range,
                    "meas_current": False,
                    "calibrate": calibrate,
                    "rec_splitter_ratio": rec_splitter_ratio},
                filename=None)

            all_meas_data.append(measurement[:, 1])

            if filename is not None:
                time_tuple = time.localtime()
                filename_comp = "%s-TxvsI-%.2eA-Vmeas=%.2eV-%.2fnm-%d-%.2fnm--%d#%d#%d--%d#%d#%d.mat" % (filename,
                                                                                                         i_set,
                                                                                                         v_meas,
                                                                                                         wavs[0],
                                                                                                         len(wavs),
                                                                                                         wavs[-1],
                                                                                                         time_tuple[0],
                                                                                                         time_tuple[1],
                                                                                                         time_tuple[2],
                                                                                                         time_tuple[3],
                                                                                                         time_tuple[4],
                                                                                                         time_tuple[5])

                print("Saving data to ", filename_comp)
                io.savemat(filename_comp, {'scattering': measurement})

        # Return to previous state
        self.laser.set_wavelength(prev_wl)
        self.pm.set_wavelength(prev_wl)
        self.smu.set_current(prev_bias)

        if not laser_active:
            self.laser.turn_off()

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_plt_data = [measurement[:, 3]]
        all_plt_data.extend(all_meas_data)

        self.data = all_plt_data

        return all_plt_data

    def default_params(self):
        return {
            "calibrate": True,
            "use_DAQ": False,
            "power_range": None,
            "rec_splitter_ratio": 1}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return [
            "wavs",
            "use_DAQ",
            "calibrate",
            "currents",
            "power_range",
            "rec_splitter_ratio"]

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError(
                    'plot_data was called before performing the experiment or providing data')

        x_data = data[0]
        y_data = data[1:]
        plot_graph(
            x_data=x_data,
            y_data=y_data,
            canvas_handle=canvas_handle,
            xlabel='Wavelength (nm)',
            ylabel='Tx (dB)',
            title='Tx spectrum vs V',
            legend=self.legend)


class TXPowerSweep(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS
        HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.laser = None
        self.pm = None
        self.smu = None
        self.daq = None
        self.wav_meter = None

        self.data = None
        self.legend = None

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
            if isinstance(instr, TunableLaser):
                # We need to account for the chance that the HPLightWave is not
                # the laser
                if isinstance(instr, HPLightWave):
                    if instr.is_laser:
                        self.laser = instr
                else:
                    self.laser = instr
            if isinstance(instr, PowerMeter):
                self.pm = instr
            if isinstance(instr, SourceMeter):
                self.smu = instr
            if isinstance(instr, NiDAQ):
                self.daq = instr
            if isinstance(instr, WlMeter):
                self.wav_meter = instr

        if ((self.pm is not None) or (self.daq is not None)) and (
                self.laser is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Sweeps wavelength and input power, measures transmission. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Tx vs Power"

    def perform_experiment(self, params=None, filename=None):

        params = self.check_all_params(params)
        wavs = params["wavs"]
        powers = params["powers"]
        use_DAQ = params["use_DAQ"]
        power_range = params["power_range"]
        meas_current = params["meas_current"]
        calibrate = params["calibrate"]
        rec_splitter_ratio = params["rec_splitter_ratio"]

        [prev_wl, prev_power, laser_active] = self.laser.get_state()

        # Turn laser on if necessary
        if not laser_active:
            self.laser.turn_on()

        self.legend = []
        all_meas_data = []

        for p_set in powers:

            # We just have to set the voltage and do a Tx Measurement.
            self.laser.set_power(p_set)

            self.legend.append('P = %.2f mW' % p_set)

            tx_sing_p = TXSweep(
                [self.laser, self.smu, self.pm, self.daq, self.wav_meter])
            measurement = tx_sing_p.perform_experiment(
                params={
                    "wavs": wavs,
                    "use_DAQ": use_DAQ,
                    "power_range": power_range,
                    "meas_current": meas_current,
                    "calibrate": calibrate,
                    "rec_splitter_ratio": rec_splitter_ratio},
                filename=None)

            all_meas_data.append(measurement[:, 1])

            if filename is not None:
                time_tuple = time.localtime()
                filename_comp = "%s-TxvsV-%.2f%s-%.2fnm-%d-%.2fnm--%d#%d#%d--%d#%d#%d.mat" % (filename,
                                                                                              p_set,
                                                                                              "mW",
                                                                                              wavs[0],
                                                                                              len(wavs),
                                                                                              wavs[-1],
                                                                                              time_tuple[0],
                                                                                              time_tuple[1],
                                                                                              time_tuple[2],
                                                                                              time_tuple[3],
                                                                                              time_tuple[4],
                                                                                              time_tuple[5])

                print("Saving data to ", filename_comp)
                io.savemat(filename_comp, {'scattering': measurement})

        # Return to previous state
        self.laser.set_wavelength(prev_wl)
        self.pm.set_wavelength(prev_wl)
        self.laser.set_power(prev_power)

        if not laser_active:
            self.laser.turn_off()

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_plt_data = [measurement[:, 3]]
        all_plt_data.extend(all_meas_data)

        self.data = all_plt_data

        return all_plt_data

    def default_params(self):
        return {
            "calibrate": True,
            "meas_current": False,
            "use_DAQ": False,
            "power_range": None,
            "rec_splitter_ratio": 1}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return [
            "wavs",
            "use_DAQ",
            "calibrate",
            "meas_current",
            "powers",
            "power_range",
            "rec_splitter_ratio"]

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError(
                    'plot_data was called before performing the experiment or providing data')

        x_data = data[0]
        y_data = data[1:]
        plot_graph(
            x_data=x_data,
            y_data=y_data,
            canvas_handle=canvas_handle,
            xlabel='Wavelength (nm)',
            ylabel='Tx (dB)',
            title='Tx spectrum vs Power',
            legend=self.legend)


class TXDoubleBiasVSweep(Experiment):

    """
    Sweeps 2 different biases applied by two different source meters. As of now, this is made for characerization
    of the BJT modulator.

    """

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.laser = None
        self.pm = None
        self.smu1 = None
        self.smu2 = None
        self.daq = None
        self.wav_meter = None

        self.data = None
        self.legend = None

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
            if isinstance(instr, TunableLaser):
                # We need to account for the chance that the HPLightWave is not
                # the laser
                if isinstance(instr, HPLightWave):
                    if instr.is_laser:
                        self.laser = instr
                else:
                    self.laser = instr
            if isinstance(instr, PowerMeter):
                self.pm = instr
            if isinstance(instr, SourceMeter):
                if self.smu1 is None:
                    self.smu1 = instr
                else:
                    self.smu2 = instr
            if isinstance(instr, NiDAQ):
                self.daq = instr
            if isinstance(instr, WlMeter):
                self.wav_meter = instr

        if ((self.pm is not None) or (self.daq is not None)) and (
                self.laser is not None) and (self.smu1 is not None) and (self.smu2 is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Sweeps wavelength and 2 different bias voltages, measures transmission. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Tx vs V (2 SMUs)"

    def perform_experiment(self, params, filename=None):

        params = self.check_all_params(params)

        wavs = params["wavs"]
        volts1 = params["voltages"]
        volts2 = params["voltages2"]
        use_DAQ = params["use_DAQ"]
        rec_splitter_ratio = params["rec_splitter_ratio"]
        comb_mode = params["combine_mode"]
        # Type of combinatin of the two voltages
        # If 'all_to_all', we measure all the combinations of voltages and voltages2
        # If 'one_by_one', we measure (voltages[0], voltages2[0]), then
        # (voltages[1], voltages2[1])...
        if (comb_mode == 'one_by_one') and (len(volts1) != len(volts2)):
            raise ValueError(
                'The length of V1s and V2s is not the same (error in Tx vs V 2 SMUs)')

        power_range = params["power_range"]
        meas_current = params["meas_current"]
        calibrate = params["calibrate"]

        [prev_wl, _, laser_active] = self.laser.get_state()
        prev_bias1 = self.smu1.measure_voltage()
        prev_bias2 = self.smu2.measure_voltage()

        # Turn laser on if necessary
        if not laser_active:
            self.laser.turn_on()

        self.legend = []
        all_meas_data = []

        if comb_mode == 'all_to_all':

            for v_set1 in volts1:

                # We just have to set the voltage and do a Tx Measurement.
                self.smu1.set_voltage(v_set1)
                self.smu1.measure_current()

                for v_set2 in volts2:

                    # We just have to set the voltage and do a Tx Measurement.
                    self.smu2.set_voltage(v_set2)
                    i_meas2 = self.smu2.measure_current()
                    i_meas1 = self.smu1.measure_current()

                    self.legend.append(
                        'V1 = %d mV, V2 = %d mV' %
                        (v_set1 * 1e3, v_set2 * 1e3))

                    tx_sing_v = TXSweep(
                        [self.laser, self.smu1, self.pm, self.daq, self.wav_meter])
                    measurement = tx_sing_v.perform_experiment(
                        params={
                            "wavs": wavs,
                            "use_DAQ": use_DAQ,
                            "power_range": power_range,
                            "meas_current": meas_current,
                            "calibrate": calibrate,
                            "rec_splitter_ratio": rec_splitter_ratio},
                        filename=None)

                    all_meas_data.append(measurement[:, 1])

                    if filename is not None:
                        time_tuple = time.localtime()
                        filename_comp = "%s-TxvsV2-V1=%d%s-V2=%d%s-Imeas1=%.2eA-Imeas2=%.2eA-%.2fnm-%d-%.2fnm" \
                                        "--%d#%d#%d--%d#%d#%d.mat" % (filename,
                                                                      1000 * v_set1,
                                                                      "mV",
                                                                      1000 * v_set2,
                                                                      "mV",
                                                                      i_meas1,
                                                                      i_meas2,
                                                                      wavs[0],
                                                                      len(wavs),
                                                                      wavs[-1],
                                                                      time_tuple[0],
                                                                      time_tuple[1],
                                                                      time_tuple[2],
                                                                      time_tuple[3],
                                                                      time_tuple[4],
                                                                      time_tuple[5])

                        print("Saving data to ", filename_comp)
                        io.savemat(filename_comp, {'scattering': measurement})

        elif comb_mode == 'one_by_one':

            for v_set1, v_set2 in zip(volts1, volts2):

                # We just have to set the voltage and do a Tx Measurement.
                self.smu1.set_voltage(v_set1)
                i_meas1 = self.smu1.measure_current()
                self.smu2.set_voltage(v_set2)
                i_meas2 = self.smu2.measure_current()

                self.legend.append(
                    'V1 = %d mV, V2 = %d mV' %
                    (v_set1 * 1e3, v_set2 * 1e3))

                tx_sing_v = TXSweep(
                    [self.laser, self.smu1, self.pm, self.daq, self.wav_meter])
                measurement = tx_sing_v.perform_experiment(
                    params={
                        "wavs": wavs,
                        "use_DAQ": use_DAQ,
                        "power_range": power_range,
                        "meas_current": meas_current,
                        "calibrate": calibrate,
                        "rec_splitter_ratio": rec_splitter_ratio},
                    filename=None)

                all_meas_data.append(measurement[:, 1])

                if filename is not None:
                    time_tuple = time.localtime()
                    filename_comp = "%s-TxvsV2-V1=%d%s-V2=%d%s-Imeas1=%.2eA-Imeas2=%.2eA-%.2fnm-%d-%.2fnm" \
                                    "--%d#%d#%d--%d#%d#%d.mat" % (filename,
                                                                  1000 * v_set1,
                                                                  "mV",
                                                                  1000 * v_set2,
                                                                  "mV",
                                                                  i_meas1,
                                                                  i_meas2,
                                                                  wavs[0],
                                                                  len(wavs),
                                                                  wavs[-1],
                                                                  time_tuple[0],
                                                                  time_tuple[1],
                                                                  time_tuple[2],
                                                                  time_tuple[3],
                                                                  time_tuple[4],
                                                                  time_tuple[5])

                    print("Saving data to ", filename_comp)
                    io.savemat(filename_comp, {'scattering': measurement})

        # Return to previous state
        self.laser.set_wavelength(prev_wl)
        self.pm.set_wavelength(prev_wl)
        self.smu1.set_voltage(prev_bias1)
        self.smu2.set_voltage(prev_bias2)

        if not laser_active:
            self.laser.turn_off()

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_plt_data = [measurement[:, 3]]
        all_plt_data.extend(all_meas_data)

        self.data = all_plt_data

        return all_plt_data

    def default_params(self):
        return {
            "calibrate": True,
            "meas_current": False,
            "use_DAQ": False,
            "power_range": None,
            "combine_mode": "all_to_all",
            "rec_splitter_ratio": 1}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return [
            "wavs",
            "use_DAQ",
            "calibrate",
            "meas_current",
            "voltages",
            "voltages2",
            "power_range",
            "combine_mode",
            "rec_splitter_ratio"]

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError(
                    'plot_data was called before performing the experiment or providing data')

        x_data = data[0]
        y_data = data[1:]
        plot_graph(
            x_data=x_data,
            y_data=y_data,
            canvas_handle=canvas_handle,
            xlabel='Wavelength (nm)',
            ylabel='Tx (dB)',
            title='Tx spectrum vs 2V',
            legend=self.legend)


if __name__ == '__main__':

    # ------
    # Standard wav sweep

    # laser = HPLightWave(tap_channel=1, rec_channel=3)
    # laser.initialize()

    # instr_list = [laser]
    # exp = TXSweep(instr_list)
    # wavs = np.linspace(1550, 1560, 5)
    # params = {"wavs": wavs, "use_DAQ": False, "calibrate": False, "meas_current": False}

    # # RUN IT
    # exp.perform_experiment(params, filename='trial')

    # # CLOSE INSTRUMENTS
    # laser.close()

    # -------------

    laser = HPLightWave(tap_channel=1, rec_channel=3)
    smu1 = KeysightB2902A(channel=1, current_compliance=0.02)
    smu2 = KeysightB2902A(channel=2, current_compliance=0.02)
    daq = NiDAQ()

    laser.initialize()
    smu1.initialize()
    smu2.initialize()
    daq.initialize()

    instr_list = [laser, smu1, smu2, daq]
    exp = TXDoubleBiasVSweep(instr_list)

    wavs = np.linspace(1569.0, 1573.0, 401)

    # Regular op
    #voltages = [-4, -3.5, -3, -2.5, -2, -1.5, -1, -0.5, -0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
    #voltages2 = [-4, -3.5, -3, -2.5, -2, -1.5, -1, -0.5, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
    # params = {"wavs": wavs, "use_DAQ": True, "calibrate": True, "meas_current": False, "voltages": voltages, "voltages2": voltages2,
    #    "combine_mode": "one_by_one", "power_range": -20}

    # BJT op
    voltages = [4, 3, 2, 1, 0, -0.25, -0.5, -0.6, -0.7, -0.8, -0.9, -1]
    voltages2 = [4, 3, 2, 1, 0, -0.25, -0.5, -0.6, -0.7, -0.8, -0.9, -1]
    params = {
        "wavs": wavs,
        "use_DAQ": True,
        "calibrate": True,
        "meas_current": False,
        "voltages": voltages,
        "voltages2": voltages2,
        "combine_mode": "all_to_all",
        "power_range": None,
        "rec_splitter_ratio": 0.1}

    # RUN IT
    exp.perform_experiment(
        params, filename='BJT_mod--1550--npn--eos_det_dopings--BJT_operation')

    # CLOSE INSTRUMENTS
    laser.close()
    smu1.close()
    smu2.close()
    daq.close()
