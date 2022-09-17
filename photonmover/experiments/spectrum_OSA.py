from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.Camera import Camera
from photonmover.Interfaces.PowMeter import PowerMeter

# This is only necessary for the example
from photonmover.instruments.Optical_spectrum_analyzers.HP70951B import HP70951B
from photonmover.instruments.Cameras.Xenics import Xenics
from photonmover.instruments.DAQ.NI_DAQ import NiDAQ
from photonmover.instruments.Power_meters.HP8153A import HP8153A

# General imports
import time
import numpy as np
import scipy.io as io
import winsound
import matplotlib.pyplot as plt


class spectrum_OSA_camera(Experiment):
    """
    Obtains the spectrum of a source using the HP OSA monochrometer and a camera as a
    detector
    """

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.camera = None
        self.osa = None

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError("The necessary instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary to perform the experiment are present.
        :param instrument_list: list of the available instruments 
        :return: True if the necessary instruments are present, False otherwise.
        """

        for instr in instrument_list:
            if isinstance(instr, Camera):
                self.camera = instr
            if isinstance(instr, HP70951B):
                self.osa = instr

        if (self.osa is not None) and (self.camera is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Performs a spectrum measurement using the monochrometer in the HP OSA and the camera as a detector. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Spectrum monochrometer+camera"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionnary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)
        
        res_bws = params["res_bws"]  # Resolution bandwidths (in nm)
        center_wls = params["center_wls"]  # Center wavelengths (in nm)

        # Set the OSA to the correct mode. We assume the camera is all set up.
        self.osa.set_wl_axis(start_wl= "%.2fNM" % center_wls[0], end_wl= "%.2fNM" % center_wls[-1])
        self.osa.set_mode('PRESEL')

        time.sleep(5)
        print('Finished configuring OSA')

        # Iterate over resolution bandwidths and center wavelengths
        for res_bw in res_bws:

            self.osa.set_acq_bandwidth( res_bw= ('%.2fNM' % res_bw) )
            print('Setting res bw of monochrometer to %.2f nm...' % res_bw)

            for wl in center_wls:

                print('Setting center wavelength of monochrometer to %.4f nm...' % wl)
                self.osa.set_presel_wl(wl)
                time.sleep(0.3)

                # Take a picture with the camera
                if filename is not None:
                    fname = "%s--res_bw=%.2fnm--wl=%.4fnm.png" % (filename, res_bw, wl)
                    self.camera.get_frame(fname)

        return None

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["res_bws", "center_wls"]

    def plot_data(self, canvas_handle, data=None):
        raise Exception('No data to plot for soectrum OSA and camera experiment')


class spectrum_OSA_DAQ(Experiment):
    """
    Obtains the spectrum of a source using the HP OSA monochrometer and a DAQ reading the voltage geenrated by a photodetector
    """

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.daq = None
        self.osa = None

        self.data = None
        self.legend = None

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError("The necessary instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary to perform the experiment are present.
        :param instrument_list: list of the available instruments 
        :return: True if the necessary instruments are present, False otherwise.
        """

        for instr in instrument_list:
            if isinstance(instr, NiDAQ):
                self.daq = instr
            if isinstance(instr, HP70951B):
                self.osa = instr

        if (self.osa is not None) and (self.daq is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Performs a spectrum measurement using the monochrometer in the HP OSA and the DAQ to read a voltage coming out of a detector. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Spectrum monochrometer+DAQ"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionnary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)

        res_bws = params["res_bws"]  # Resolution bandwidths (in nm)
        center_wls = params["center_wls"]  # Center wavelengths (in nm)
        daq_channel = params["daq_channel"]  # DAQ channel to which the PD output is connected
        num_meas_per_wav = params["num_meas_per_wav"]  # Number of measurements to take per each wavelength setting
        sampling_rate = params["sampling_rate"]  # Samples per second for the DAQ

        # Configure DAQ acquisition
        self.daq.configure_nsampl_acq(input_channels=[daq_channel], clk_channel=None, num_points=num_meas_per_wav, max_sampling_freq=sampling_rate, min_vals=0.0, max_vals=10.0)

        # Set the OSA to the correct mode.
        self.osa.set_wl_axis(start_wl= "%.2fNM" % center_wls[0], end_wl= "%.2fNM" % center_wls[-1])
        self.osa.set_mode('PRESEL')

        time.sleep(5)
        print('Finished configuring OSA')

        self.legend = []
        all_meas_data = []

        # Iterate over resolution bandwidths and center wavelengths
        for res_bw in res_bws:

            # Matrix to save the data
            measurements = np.zeros((len(center_wls), 2), float)

            self.osa.set_acq_bandwidth( res_bw= ('%.2fNM' % res_bw) )
            print('Setting res bw of monochrometer to %.2f nm...' % res_bw)

            for i, wl in enumerate(center_wls):

                print('Setting center wavelength of monochrometer to %.4f nm...' % wl)
                self.osa.set_presel_wl(wl)
                time.sleep(0.3)

                # Measure the voltage from the PD with the DAQ
                self.daq.start_task()
                self.daq.wait_task(timeout=1.5*num_meas_per_wav/sampling_rate)
                daq_data = self.daq.read_data(num_meas_per_wav)

                measurements[i, 0] = wl
                measurements[i, 1] = np.average(daq_data)

            self.legend.append('RBW = %.2f nm' % res_bw)
            all_meas_data.append(measurements[:, 1])

            if filename is not None:

                time_tuple = time.localtime()
                filename = "%s-DAQ_spectrum--res_bw=%.2fnm--%.2fnm--%d-%.2fnm--%d#%d#%d_%d#%d#%d.mat" % (filename,
                                                                            res_bw,
                                                                            center_wls[0],
                                                                            len(center_wls),
                                                                            center_wls[-1],
                                                                            time_tuple[0],
                                                                            time_tuple[1],
                                                                            time_tuple[2],
                                                                            time_tuple[3],
                                                                            time_tuple[4],
                                                                            time_tuple[5])

                print("Saving data to ", filename)
                io.savemat(filename, {'data': measurements})

        # Beep when done
        winsound.Beep(2000, 1000) # frequency, duration

        all_plt_data = [measurements[:, 0]]
        all_plt_data.extend(all_meas_data)
        self.data = all_plt_data

        return None

    def default_params(self):
        return {"num_meas_per_wav":100, "sampling_rate": 100, "res_bws": [10]}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["res_bws", "center_wls", "daq_channel", "num_meas_per_wav", "sampling_rate"]

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')

        x_data = data[0]
        y_data = data[1:]
        plot_graph(x_data=x_data, y_data=y_data, canvas_handle=canvas_handle, xlabel='Wavelength (nm)', ylabel='Measured V', title='V vs wavelength', legend=self.legend)


class spectrum_OSA_powermeter(Experiment):
    """
    Obtains the spectrum of a source using the HP OSA monochrometer and a power meter
    """

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.power_meter = None
        self.osa = None

        self.data = None
        self.legend = None

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError("The necessary instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary to perform the experiment are present.
        :param instrument_list: list of the available instruments 
        :return: True if the necessary instruments are present, False otherwise.
        """

        for instr in instrument_list:
            if isinstance(instr, PowerMeter):
                self.power_meter = instr
            if isinstance(instr, HP70951B):
                self.osa = instr

        if (self.osa is not None) and (self.power_meter is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Performs a spectrum measurement using the monochrometer in the HP OSA and a power meter. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Spectrum monochrometer+Power Meter"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionnary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)

        res_bws = params["res_bws"]  # Resolution bandwidths (in nm)
        center_wls = params["center_wls"]  # Center wavelengths (in nm)
        pm_channel = params["pm_channel"]  # Relevant power meter channel
        int_time = params["int_time"] # Integration time

        # Configure power meter integration time
        self.power_meter.set_integration_time(pm_channel, int_time)

        # Set the OSA to the correct mode.
        self.osa.set_wl_axis(start_wl= "%.2fNM" % center_wls[0], end_wl= "%.2fNM" % center_wls[-1])
        self.osa.set_mode('PRESEL')

        time.sleep(5)
        print('Finished configuring OSA')

        self.legend = []
        all_meas_data = []

        # Iterate over resolution bandwidths and center wavelengths
        for res_bw in res_bws:

            # Matrix to save the data
            measurements = np.zeros((len(center_wls), 2), float)

            self.osa.set_acq_bandwidth( res_bw= ('%.2fNM' % res_bw) )
            print('Setting res bw of monochrometer to %.2f nm...' % res_bw)

            for i, wl in enumerate(center_wls):

                print('Setting center wavelength of monochrometer to %.4f nm...' % wl)
                self.osa.set_presel_wl(wl)
                self.power_meter.set_wavelength(wl)
                time.sleep(0.3)

                # Measure the power
                powers = self.power_meter.get_powers()
                power = powers[pm_channel]
                measurements[i, 0] = wl
                measurements[i, 1] = power

            self.legend.append('RBW = %.2f nm' % res_bw)
            all_meas_data.append(measurements[:, 1])

            if filename is not None:

                time_tuple = time.localtime()
                filename = "%s-DAQ_spectrum--res_bw=%.2fnm--%.2fnm--%d-%.2fnm--%d#%d#%d_%d#%d#%d.mat" % (filename,
                                                                            res_bw,
                                                                            center_wls[0],
                                                                            len(center_wls),
                                                                            center_wls[-1],
                                                                            time_tuple[0],
                                                                            time_tuple[1],
                                                                            time_tuple[2],
                                                                            time_tuple[3],
                                                                            time_tuple[4],
                                                                            time_tuple[5])

                print("Saving data to ", filename)
                io.savemat(filename, {'data': measurements})

        # Beep when done
        winsound.Beep(2000, 1000) # frequency, duration

        all_plt_data = [measurements[:, 0]]
        all_plt_data.extend(all_meas_data)
        self.data = all_plt_data

        return None

    def default_params(self):
        return {"res_bws": [10], "pm_channel": 1, "int_time": 1}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["res_bws", "center_wls", "pm_channel", "int_time"]

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')

        x_data = data[0]
        y_data = data[1:]
        plot_graph(x_data=x_data, y_data=y_data, canvas_handle=canvas_handle, xlabel='Wavelength (nm)', ylabel='Measured power (mW)', title='Power vs wavelength', legend=self.legend)


if __name__ == '__main__':

    # --------------------------------------
    # OSA and power meter

    # INSTRUMENTS
    osa = HP70951B()
    pm = HP8153A(rec_channel=1, tap_channel=None)

    osa.initialize()
    pm.initialize()
    
    # EXPERIMENT PARAMETERS
    res_bws = [1] # in nm

    start_wl = 1000
    end_wl = 1300
    wl_spacing = 0.5
    center_wls = np.arange(start_wl, end_wl, wl_spacing) # in nm

    int_time = 1
    pm_channel = 1

    base_file_name = './data/CNT_absorption/tx_283mgperL_CNTs'

    # SET UP THE EXPERIMENT
    instr_list = [osa, pm]
    exp = spectrum_OSA_powermeter(instr_list)
    params = {"res_bws": res_bws, "center_wls": center_wls, "pm_channel": pm_channel, "int_time": int_time}

    # RUN IT
    exp.perform_experiment(params, filename=base_file_name)

    # PLOT IT
    plt.figure()
    canvas_handle = plt.subplot(111)
    exp.plot_data(canvas_handle)

    # CLOSE INSTRUMENTS
    osa.close()
    pm.close()

    # # -------------------------------------
    # # OSA and DAQ

    # # INSTRUMENTS
    # osa = HP70951B()
    # daq = NiDAQ()

    # osa.initialize()
    # daq.initialize()
    
    # # EXPERIMENT PARAMETERS
    # res_bws = [10] # in nm

    # start_wl = 1000
    # end_wl = 1300
    # wl_spacing = 1
    # center_wls = np.arange(start_wl, end_wl, wl_spacing) # in nm
    # sampling_rate = 10

    # daq_channel = "Dev1/ai0"
    # num_meas_per_wav = 100  # Number of measurements per wavelength

    # base_file_name = './data/LED_spectrum/LED_spectrum_w_camera_Ibias=70mA'

    # # SET UP THE EXPERIMENT
    # instr_list = [osa, daq]
    # exp = spectrum_OSA_DAQ(instr_list)
    # params = {"res_bws":res_bws, "center_wls":center_wls, "daq_channel": daq_channel,
    # "num_meas_per_wav": num_meas_per_wav, "sampling_rate": sampling_rate}

    # # RUN IT
    # exp.perform_experiment(params, filename=base_file_name)

    # # PLOT IT
    # plt.figure()
    # canvas_handle = plt.subplot(111)
    # exp.plot_data(canvas_handle)

    # # CLOSE INSTRUMENTS
    # osa.close()
    # daq.close()

    # # -------------------------------------
    # # OSA and camera

    # # INSTRUMENTS
    # osa = HP70951B()
    # camera = Xenics()

    # osa.initialize()
    # camera.initialize()
    
    # # EXPERIMENT PARAMETERS
    # res_bws = [10] # in nm

    # start_wl = 1000
    # end_wl = 1300
    # wl_spacing = 1
    # center_wls = np.arange(start_wl, end_wl, wl_spacing) # in nm
    # print(center_wls)
    # input()

    # base_file_name = './data/LED_spectrum/LED_spectrum_w_camera_Ibias=70mA'

    # print('Waiting for camera to cool down and load everyhting (20 sec)')
    # time.sleep(20)

    # # SET UP THE EXPERIMENT
    # instr_list = [osa, camera]
    # exp = spectrum_OSA_camera(instr_list)
    # params = {"res_bws":res_bws, "center_wls":center_wls}

    # # RUN IT
    # exp.perform_experiment(params, filename=base_file_name)

    # # CLOSE INSTRUMENTS
    # osa.close()
    # camera.close()
    # # -------------------------------------