from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

from photonmover.Interfaces.VNA import VNA
from photonmover.Interfaces.SourceMeter import SourceMeter
from photonmover.Interfaces.Laser import TunableLaser
from photonmover.Interfaces.TunableFilter import TunableFilter

from photonmover.instruments.Vector_network_analyzers.HP8722D import HP8722D
from photonmover.instruments.Source_meters.Keithley2400 import Keithley2400
from photonmover.instruments.Source_meters.Keithley2635A import Keithley2635A

# General imports
import time
import csv


# Plotting
PLOT_S_PARAM = "S21"  # Which s parameter to plot
PLOT_FORMAT = "LOGM"  # Which measurement format to plot


class RetrieveVNATrace(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        super().__init__(visa_lock)

        # Instruments
        self.vna = None

        self.data = {}

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError("The necessary instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary to perform the experiment are present.
        :param instrument_list: list of the available instruments 
        :return: True if the necessary instruments are present, False otherwise.
        """
        for instr in instrument_list:
            if isinstance(instr, VNA):
                self.vna = instr

        if self.vna is not None:
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return "Retrieves a trace from the VNA"

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Retrieve VNA trace"
        
    def perform_experiment(self, params=None, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionnary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)
        s_params = params["s_params"]  # List of the relevant s parameters we want to obtain (S11, S12, ...)
        meas_formats = params["meas_formats"]  # List of the measurements formats for each s parameter (logm, phas)

        # We will take the data in all the formats specified by meas_formats, for all the s parameters
        # specified by s_params
        
        for s_param in s_params:

            self.data[s_param] = {}

            for meas_format in meas_formats:

                self.vna.set_measurement_type(sweeptype=s_param, meastype=meas_format)

                if filename is not None:

                    time_tuple = time.localtime()
                    filename_complete = "%s-VNA--s_param=%s--format=%s--%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                                         s_param,
                                                                                         meas_format,
                                                                                         time_tuple[0],
                                                                                         time_tuple[1],
                                                                                         time_tuple[2],
                                                                                         time_tuple[3],
                                                                                         time_tuple[4],
                                                                                         time_tuple[5])

                meas = self.vna.read_data(file=filename_complete, plot_data=False)

                self.data[s_param][meas_format] = meas

        print('VNA acquisition finished')

        return self.data

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["s_params", "meas_formats"]

    def default_params(self):
        return {"s_params": ['S21'], "meas_formats": ['LOGM']}

    def plot_data(self, canvas_handle, data=None):
        
        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')
        
        x_data = data[0]
        y_data = data[1]

        plot_graph(x_data, y_data, canvas_handle=canvas_handle, xlabel='Freq (Hz)', ylabel='s_21 (dB)', title='VNA meas', legend=None)


class AcquireVNATrace(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        super().__init__(visa_lock)

        # Instruments
        self.vna = None

        self.data = {}

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError("The necessary instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary to perform the experiment are present.
        :param instrument_list: list of the available instruments 
        :return: True if the necessary instruments are present, False otherwise.
        """
        for instr in instrument_list:
            if isinstance(instr, VNA):
                self.vna = instr

        if self.vna is not None:
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return "Starts a VNA aquisition and stores the data once donce"

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Trigger VNA"          
    
    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionnary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """
        params = self.check_all_params(params)
        num_averages = params["num_averages"]

        s_params = params["s_params"]  # List of the relevant s parameters we want to obtain (S11, S12, ...)
        meas_formats = params["meas_formats"]  # List of the measurements formats for each s parameter (logm, phas)

        # We will take the data in all the formats specified by meas_formats, for all the s
        # parameters specified by s_params
        
        for s_param in s_params:

            self.data[s_param] = {}

            # We need to take a new sweep for every s parameter
            self.vna.set_measurement_type(sweeptype=s_param, meastype=None)
            self.vna.take_data(num_averages)

            for meas_format in meas_formats:

                self.vna.set_measurement_type(sweeptype=s_param, meastype=meas_format)

                if filename is not None:

                    time_tuple = time.localtime()
                    filename_complete = "%s-VNA--s_param=%s--format=%s--%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                                         s_param,
                                                                                         meas_format,
                                                                                         time_tuple[0],
                                                                                         time_tuple[1],
                                                                                         time_tuple[2],
                                                                                         time_tuple[3],
                                                                                         time_tuple[4],
                                                                                         time_tuple[5])

                else:
                    filename_complete = None

                meas = self.vna.read_data(file=filename_complete, plot_data=False)
                self.data[s_param][meas_format] = meas

        print('VNA acquisition finished')

        # Return to continuos triggering and averaging off
        self.vna.set_trigger(mode='continuous')
        self.vna.set_averaging(num_averages=1)

        return self.data

    def default_params(self):
        return {"num_averages": 4, "s_params": ['S21'], "meas_formats": ['LOGM']}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionary, in order for
        a measurement to be performed
        """
        return ["num_averages", "s_params", "meas_formats"]

    def plot_data(self, canvas_handle, data=None):
        
        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')
        
        x_data = data[0]
        y_data = data[1]

        plot_graph(x_data, y_data, canvas_handle=canvas_handle, xlabel='Freq (Hz)', ylabel='s_21 (dB)', title='VNA meas', legend=None)


class VNABiasVSweep(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE
        BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.vna = None
        self.smu = None
        self.laser = None
        self.tunable_filter = None

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
            if isinstance(instr, VNA):
                self.vna = instr
            if isinstance(instr, SourceMeter):
                self.smu = instr
            if isinstance(instr, TunableLaser):
                self.laser = instr
            if isinstance(instr, TunableFilter):
                self.tunable_filter = instr

        if (self.vna is not None) and (self.smu is not None) and (self.laser is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Sweeps bias voltage and wavelength, measures s21. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "BW vs V, wav"
    
    def perform_experiment(self, params, filename=None):
        
        params = self.check_all_params(params)
        volts = params["voltages"]
        wavs = params["wavs"]
        num_averages = params["num_averages"]

        s_params = params["s_params"]  # List of the relevant s parameters we want to obtain (S11, S12, ...)
        meas_formats = params["meas_formats"]  # List of the measurements formats for each s parameter (logm, phas)
        # We will take the data in all the formats specified by meas_formats, for all the s
        # parameters specified by s_params
        
        [prev_wl, _, laser_active] = self.laser.get_state()
        prev_bias = self.smu.measure_voltage()

        self.legend = []
        all_meas_data = []

        for v_set in volts:

            # We just have to set the voltage and do a Tx Measurement.
            self.smu.set_voltage(v_set)
            i_meas = self.smu.measure_current()

            for wav in wavs:

                # Set the wavelength
                self.laser.set_wavelength(wav)

                if self.tunable_filter:
                    self.tunable_filter.set_wavelength(wav)

                time.sleep(0.4)

                # Get the VNA trace
                VNA_spec_v_wav = AcquireVNATrace([self.vna])
                measurement = VNA_spec_v_wav.perform_experiment(params={"num_averages": num_averages,
                                                                        "s_params": s_params,
                                                                        "meas_formats": meas_formats},
                                                                filename=None)
                self.legend.append("V = %d mV; wav = %.2f nm" % (v_set*1e3, wav))
                all_meas_data.append(measurement[PLOT_S_PARAM][PLOT_FORMAT][1])

                if filename is not None:

                    # Create a different file for each s parameter and format
                    for s_param, meas_dict in measurement.items():
                        for format, meas in meas_dict.items():

                            # Create the csv file
                            time_tuple = time.localtime()
                            filename_complete = "%s-VNAvsV--s_param=%s--format=%s--V=%dmV--Imeas=%.2eA--wav=%.2fnm--" \
                                                "%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                           s_param,
                                                                           format,
                                                                           v_set*1000,
                                                                           i_meas,
                                                                           wav,
                                                                           time_tuple[0],
                                                                           time_tuple[1],
                                                                           time_tuple[2],
                                                                           time_tuple[3],
                                                                           time_tuple[4],
                                                                           time_tuple[5])

                            with open(filename_complete, 'w+') as csvfile:
                                writer = csv.writer(csvfile)
                                writer.writerow(meas[0])
                                writer.writerow(meas[1])

        # Return to previous state
        self.laser.set_wavelength(prev_wl)
        self.smu.set_voltage(prev_bias)
        if self.tunable_filter:
            self.tunable_filter.set_wavelength(prev_wl)

        if not laser_active:
            self.laser.turn_off()

        print('BW vs V acquisition finished')

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_plt_data = [measurement[PLOT_S_PARAM][PLOT_FORMAT][0]]
        all_plt_data.extend(all_meas_data)
        self.data = all_plt_data

        return all_plt_data

    def default_params(self):
        return {"num_averages": 4, "s_params": ['S21'], "meas_formats": ['LOGM']}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["voltages", "wavs", "num_averages", "s_params", "meas_formats"]

    def plot_data(self, canvas_handle, data=None):
        
        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')
        
        x_data = data[0]
        y_data = data[1:]

        plot_graph(x_data, y_data, canvas_handle=canvas_handle, xlabel='Freq (Hz)', ylabel='s_21 (dB)', title='VNA vs V meas', legend=self.legend)


class VNABiasISweep(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.vna = None
        self.smu = None
        self.laser = None
        self.tunable_filter = None

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
            if isinstance(instr, VNA):
                self.vna = instr
            if isinstance(instr, SourceMeter):
                self.smu = instr
            if isinstance(instr, TunableLaser):
                self.laser = instr
            if isinstance(instr, TunableFilter):
                self.tunable_filter = instr

        if (self.vna is not None) and (self.smu is not None) and (self.laser is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Sweeps bias voltage and wavelength, measures s21. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "BW vs I, wav"
    
    def perform_experiment(self, params, filename=None):
        
        params = self.check_all_params(params)
        curs = params["currents"]
        wavs = params["wavs"]
        num_averages = params["num_averages"]

        s_params = params["s_params"]  # List of the relevant s parameters we want to obtain (S11, S12, ...)
        meas_formats = params["meas_formats"]  # List of the measurements formats for each s parameter (logm, phas)
        # We will take the data in all the formats specified by meas_formats, for all the
        # s parameters specified by s_params
        
        [prev_wl, _, laser_active] = self.laser.get_state()
        prev_bias = self.smu.measure_current()

        self.legend = []
        all_meas_data = []

        for i_set in curs:

            # We just have to set the voltage and do a Tx Measurement.
            self.smu.set_current(i_set)
            v_meas = self.smu.measure_voltage()

            for wav in wavs:

                # Set the wavelength
                self.laser.set_wavelength(wav)

                if self.tunable_filter:
                    self.tunable_filter.set_wavelength(wav)

                time.sleep(0.4)

                # Get the VNA trace
                VNA_spec_v_wav = AcquireVNATrace([self.vna])
                measurement = VNA_spec_v_wav.perform_experiment(params={"num_averages":num_averages, "s_params": s_params, "meas_formats": meas_formats}, filename=None)
                self.legend.append("I = %.2e A; wav = %.2f nm" % (i_set, wav))
                all_meas_data.append(measurement[PLOT_S_PARAM][PLOT_FORMAT][1])

                if filename is not None:
                    # Create a different file for each s parameter and format
                    for s_param, meas_dict in measurement.items():
                        for format, meas in meas_dict.items():

                            # Create the csv file
                            time_tuple = time.localtime()
                            filename_complete = "%s-VNAvsI--s_param=%s--format=%s--I=%.2eA--Vmeas=%.2eV--wav=%.2fnm--" \
                                                "%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                           s_param,
                                                                           format,
                                                                           i_set,
                                                                           v_meas,
                                                                           wav,
                                                                           time_tuple[0],
                                                                           time_tuple[1],
                                                                           time_tuple[2],
                                                                           time_tuple[3],
                                                                           time_tuple[4],
                                                                           time_tuple[5])

                            with open(filename_complete, 'w+') as csvfile:
                                writer = csv.writer(csvfile)
                                writer.writerow(meas[0])
                                writer.writerow(meas[1])

        # Return to previous state
        self.laser.set_wavelength(prev_wl)
        self.smu.set_current(prev_bias)
        if self.tunable_filter:
            self.tunable_filter.set_wavelength(prev_wl)

        if not laser_active:
            self.laser.turn_off()

        print('BW vs I acquisition finished')

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_plt_data = [measurement[PLOT_S_PARAM][PLOT_FORMAT][0]]
        all_plt_data.extend(all_meas_data)
        self.data = all_plt_data

        return all_plt_data

    def default_params(self):
        return {"num_averages": 4, "s_params": ['S21'], "meas_formats": ['LOGM']}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["currents", "wavs", "num_averages", "s_params", "meas_formats"]

    def plot_data(self, canvas_handle, data=None):
        
        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')
        
        x_data = data[0]
        y_data = data[1:]

        plot_graph(x_data, y_data, canvas_handle=canvas_handle, xlabel='Freq (Hz)', ylabel='s_21 (dB)',
                   title='VNA vs V meas', legend=self.legend)


class VNADoubleBiasVSweep(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS
        HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.vna = None
        self.smu1 = None
        self.smu2 = None
        self.laser = None
        self.tunable_filter = None

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
            if isinstance(instr, VNA):
                self.vna = instr
            if isinstance(instr, SourceMeter):
                if self.smu1 is None:
                    self.smu1 = instr
                else:
                    self.smu2 = instr
            if isinstance(instr, TunableLaser):
                self.laser = instr
            if isinstance(instr, TunableFilter):
                self.tunable_filter = instr

        if (self.vna is not None) and (self.smu1 is not None) and (self.smu2 is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Sweeps two different bias voltages and wavelength, measures s21. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "BW vs V1, V2, wav"
    
    def perform_experiment(self, params, filename=None):
        
        params = self.check_all_params(params)

        volts1 = params["voltages"]
        volts2 = params["voltages2"]
        wavs = params["wavs"]
        num_averages = params["num_averages"]

        if self.laser is None:
            # If there is no laser, set the wavelength to a foo
            wavs = [0.00]

        s_params = params["s_params"]  # List of the relevant s parameters we want to obtain (S11, S12, ...)
        meas_formats = params["meas_formats"]  # List of the measurements formats for each s parameter (logm, phas)
        # We will take the data in all the formats specified by meas_formats, for all the s
        # parameters specified by s_params

        if self.laser is not None:
            [prev_wl, _, laser_active] = self.laser.get_state()
        prev_bias1 = self.smu1.measure_voltage()
        prev_bias2 = self.smu2.measure_voltage()

        self.legend = []
        all_meas_data = []

        # Type of combinatin of the two voltages
        # If 'all_to_all', we measure all the combinations of voltages and voltages2
        # If 'one_by_one', we measure (voltages[0], voltages2[0]), then (voltages[1], voltages2[1])...
        comb_mode = params["combine_mode"]

        if (comb_mode == 'one_by_one') and (len(volts1) != len(volts2)):
            raise ValueError('The length of V1s and V2s is not the same (error in Tx vs V 2 SMUs)')

        if comb_mode == 'all_to_all':

            for v1 in volts1:

                self.smu1.set_voltage(v1)
                self.smu1.measure_current()

                for v2 in volts2:

                    self.smu2.set_voltage(v2)
                    i_meas2 = self.smu2.measure_current()
                    i_meas1 = self.smu1.measure_current()

                    for wav in wavs:

                        if self.laser is not None:
                            # Set the wavelength
                            self.laser.set_wavelength(wav)

                        if self.tunable_filter:
                            self.tunable_filter.set_wavelength(wav)

                        time.sleep(0.4)

                        # Get the VNA trace
                        VNA_spec_v_wav = AcquireVNATrace([self.vna])
                        measurement = VNA_spec_v_wav.perform_experiment(params={"num_averages": num_averages,
                                                                                "s_params": s_params,
                                                                                "meas_formats": meas_formats},
                                                                        filename=None)
                        self.legend.append("V1 = %d mV; V2 = %d mV, wav = %.2f nm" % (v1*1e3, v2*1e3, wav))
                        all_meas_data.append(measurement[PLOT_S_PARAM][PLOT_FORMAT][1])

                        if filename is not None:
                            # Create a different file for each s parameter and format
                            for s_param, meas_dict in measurement.items():
                                for format, meas in meas_dict.items():

                                    # Create the csv file
                                    time_tuple = time.localtime()
                                    filename_complete = "%s-VNAvs2V--s_param=%s--format=%s--V1=%dmV--V2=%dmV--" \
                                                        "Imeas1=%.2eA--Imeas2=%.2eA--wav=%.2fnm--" \
                                                        "%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                                   s_param,
                                                                                   format,
                                                                                   v1*1000,
                                                                                   v2*1000,
                                                                                   i_meas1,
                                                                                   i_meas2,
                                                                                   wav,
                                                                                   time_tuple[0],
                                                                                   time_tuple[1],
                                                                                   time_tuple[2],
                                                                                   time_tuple[3],
                                                                                   time_tuple[4],
                                                                                   time_tuple[5])

                                    with open(filename_complete, 'w+') as csvfile:
                                        writer = csv.writer(csvfile)
                                        writer.writerow(meas[0])
                                        writer.writerow(meas[1])

        elif comb_mode == 'one_by_one':

            for v1, v2 in zip(volts1, volts2):

                # We just have to set the voltage and do a Tx Measurement.
                self.smu1.set_voltage(v1)
                i_meas1 = self.smu1.measure_current()
                self.smu2.set_voltage(v2)
                i_meas2 = self.smu2.measure_current()

                for wav in wavs:

                    if self.laser is not None:
                        # Set the wavelength
                        self.laser.set_wavelength(wav)

                    if self.tunable_filter:
                        self.tunable_filter.set_wavelength(wav)

                    time.sleep(0.4)

                    # Get the VNA trace
                    VNA_spec_v_wav = AcquireVNATrace([self.vna])
                    measurement = VNA_spec_v_wav.perform_experiment(params={"num_averages":num_averages,
                                                                            "s_params": s_params,
                                                                            "meas_formats": meas_formats},
                                                                    filename=None)
                    self.legend.append("V1 = %d mV; V2 = %d mV, wav = %.2f nm" % (v1*1e3, v2*1e3, wav))
                    all_meas_data.append(measurement[PLOT_S_PARAM][PLOT_FORMAT][1])

                    if filename is not None:
                        # Create a different file for each s parameter and format
                        for s_param, meas_dict in measurement.items():
                            for format, meas in meas_dict.items():

                                if filename is not None:

                                    # Create the csv file
                                    time_tuple = time.localtime()
                                    filename_complete = "%s-VNAvs2V--s_param=%s--format=%s--V1=%dmV--V2=%dmV--Imeas1=%.2eA--Imeas2=%.2eA--wav=%.2fnm--" \
                                                        "%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                                   s_param,
                                                                                   format,
                                                                                   v1*1000,
                                                                                   v2*1000,
                                                                                   i_meas1,
                                                                                   i_meas2,
                                                                                   wav,
                                                                                   time_tuple[0],
                                                                                   time_tuple[1],
                                                                                   time_tuple[2],
                                                                                   time_tuple[3],
                                                                                   time_tuple[4],
                                                                                   time_tuple[5])

                                    with open(filename_complete, 'w+') as csvfile:
                                        writer = csv.writer(csvfile)
                                        writer.writerow(measurement[0])
                                        writer.writerow(measurement[1])

        # Return to previous state
        if self.laser is not None:
            self.laser.set_wavelength(prev_wl)
            if not laser_active:
                self.laser.turn_off()
        self.smu1.set_voltage(prev_bias1)
        self.smu2.set_voltage(prev_bias2)
        if self.tunable_filter:
            self.tunable_filter.set_wavelength(prev_wl)

        print('BW vs V1, V2 acquisition finished')

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_plt_data = [measurement[PLOT_S_PARAM][PLOT_FORMAT][0]]
        all_plt_data.extend(all_meas_data)

        self.data = all_plt_data
        return all_plt_data

    def default_params(self):
        return {"num_averages": 4, "s_params": ['S21'], "meas_formats": ['LOGM'], "combine_mode": 'all_to_all'}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["voltages", "voltages2", "wavs", "num_averages", "combine_mode", "s_params", "meas_formats"]

    def plot_data(self, canvas_handle, data=None):
        
        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')
        
        x_data = data[0]
        y_data = data[1:]

        plot_graph(x_data, y_data, canvas_handle=canvas_handle, xlabel='Freq (Hz)', ylabel='s_21 (dB)',
                   title='VNA vs 2 V meas', legend=self.legend)


class VNABiasVandBiasISweep(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS
        HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.vna = None
        self.v_smu = None
        self.i_smu = None
        self.laser = None
        self.tunable_filter = None

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
            if isinstance(instr, VNA):
                self.vna = instr
            if isinstance(instr, SourceMeter):
                if self.v_smu is None:
                    self.v_smu = instr
                else:
                    self.i_smu = instr
            if isinstance(instr, TunableLaser):
                self.laser = instr
            if isinstance(instr, TunableFilter):
                self.tunable_filter = instr

        if (self.vna is not None) and (self.v_smu is not None) and (self.i_smu is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Sweeps bias voltage, bias current and wavelength, measures s parameters. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "BW vs Vbias, Ibias, wav"

    def perform_experiment(self, params, filename=None):

        params = self.check_all_params(params)

        volts = params["voltages"]
        currents = params["currents"]
        wavs = params["wavs"]
        num_averages = params["num_averages"]

        if self.laser is None:
            # If there is no laser, set the wavelength to a foo
            wavs = [0.00]

        s_params = params["s_params"]  # List of the relevant s parameters we want to obtain (S11, S12, ...)
        meas_formats = params["meas_formats"]  # List of the measurements formats for each s parameter (logm, phas)
        # We will take the data in all the formats specified by meas_formats, for all the s
        # parameters specified by s_params

        if self.laser is not None:
            [prev_wl, _, laser_active] = self.laser.get_state()

        prev_bias1 = self.v_smu.measure_voltage()
        prev_bias2 = self.i_smu.measure_current()

        self.legend = []
        all_meas_data = []

        # Type of combinatin of the two voltages
        # If 'all_to_all', we measure all the combinations of voltages and voltages2
        # If 'one_by_one', we measure (voltages[0], voltages2[0]), then (voltages[1], voltages2[1])...
        comb_mode = params["combine_mode"]

        if (comb_mode == 'one_by_one') and (len(volts) != len(currents)):
            raise ValueError('The length of Vs and Is is not the same (error in Tx vs V, I 2 SMUs)')

        if comb_mode == 'all_to_all':

            for volt in volts:

                self.v_smu.set_voltage(volt)
                self.v_smu.measure_current()

                for cur in currents:

                    self.i_smu.set_current(cur)
                    v_meas = self.i_smu.measure_voltage()
                    i_meas = self.v_smu.measure_current()

                    for wav in wavs:

                        if self.laser is not None:
                            # Set the wavelength
                            self.laser.set_wavelength(wav)

                        if self.tunable_filter:
                            self.tunable_filter.set_wavelength(wav)

                        time.sleep(0.4)

                        # Get the VNA trace
                        VNA_spec_v_wav = AcquireVNATrace([self.vna])
                        measurement = VNA_spec_v_wav.perform_experiment(params={"num_averages": num_averages,
                                                                                "s_params": s_params,
                                                                                "meas_formats": meas_formats},
                                                                        filename=None)
                        self.legend.append("V = %d mV; I = %.2e A, wav = %.2f nm" % (volt * 1e3, cur, wav))
                        all_meas_data.append(measurement[PLOT_S_PARAM][PLOT_FORMAT][1])

                        if filename is not None:
                            # Create a different file for each s parameter and format
                            for s_param, meas_dict in measurement.items():
                                for format, meas in meas_dict.items():
                                    # Create the csv file
                                    time_tuple = time.localtime()
                                    filename_complete = "%s-VNAvsIandV--s_param=%s--format=%s--V=%dmV--I=%.2eA--" \
                                                        "Imeas=%.2eA--Vmeas=%.2eV--wav=%.2fnm--" \
                                                        "%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                                   s_param,
                                                                                   format,
                                                                                   volt * 1000,
                                                                                   cur,
                                                                                   i_meas,
                                                                                   v_meas,
                                                                                   wav,
                                                                                   time_tuple[0],
                                                                                   time_tuple[1],
                                                                                   time_tuple[2],
                                                                                   time_tuple[3],
                                                                                   time_tuple[4],
                                                                                   time_tuple[5])

                                    with open(filename_complete, 'w+') as csvfile:
                                        writer = csv.writer(csvfile)
                                        writer.writerow(meas[0])
                                        writer.writerow(meas[1])

        elif comb_mode == 'one_by_one':

            for volt, cur in zip(volts, currents):

                # We just have to set the voltage and do a Tx Measurement.
                self.v_smu.set_voltage(volt)
                self.smu2.set_current(cur)
                i_meas = self.v_smu.measure_current()
                v_meas = self.i_smu.measure_voltage()

                for wav in wavs:

                    if self.laser is not None:
                        # Set the wavelength
                        self.laser.set_wavelength(wav)

                    if self.tunable_filter:
                        self.tunable_filter.set_wavelength(wav)

                    time.sleep(0.4)

                    # Get the VNA trace
                    VNA_spec_v_wav = AcquireVNATrace([self.vna])
                    measurement = VNA_spec_v_wav.perform_experiment(params={"num_averages": num_averages,
                                                                            "s_params": s_params,
                                                                            "meas_formats": meas_formats},
                                                                    filename=None)
                    self.legend.append("V = %d mV; I = %.2e A, wav = %.2f nm" % (volt * 1e3, cur, wav))
                    all_meas_data.append(measurement[PLOT_S_PARAM][PLOT_FORMAT][1])

                    if filename is not None:
                        # Create a different file for each s parameter and format
                        for s_param, meas_dict in measurement.items():
                            for format, meas in meas_dict.items():

                                if filename is not None:
                                    # Create the csv file
                                    time_tuple = time.localtime()
                                    filename_complete = "%s-VNAvsIandV--s_param=%s--format=%s--V=%dmV--I=%.2eA--" \
                                                        "Imeas=%.2eA--Vmeas=%.2eV--wav=%.2fnm--" \
                                                        "%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                                   s_param,
                                                                                   format,
                                                                                   volt * 1000,
                                                                                   cur,
                                                                                   i_meas,
                                                                                   v_meas,
                                                                                   wav,
                                                                                   time_tuple[0],
                                                                                   time_tuple[1],
                                                                                   time_tuple[2],
                                                                                   time_tuple[3],
                                                                                   time_tuple[4],
                                                                                   time_tuple[5])

                                    with open(filename_complete, 'w+') as csvfile:
                                        writer = csv.writer(csvfile)
                                        writer.writerow(measurement[0])
                                        writer.writerow(measurement[1])

        # Return to previous state
        if self.laser is not None:
            self.laser.set_wavelength(prev_wl)
            if not laser_active:
                self.laser.turn_off()
        self.v_smu.set_voltage(prev_bias1)
        self.i_smu.set_voltage(prev_bias2)
        if self.tunable_filter:
            self.tunable_filter.set_wavelength(prev_wl)

        print('BW vs V, I acquisition finished')

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_plt_data = [measurement[PLOT_S_PARAM][PLOT_FORMAT][0]]
        all_plt_data.extend(all_meas_data)

        self.data = all_plt_data
        return all_plt_data

    def default_params(self):
        return {"num_averages": 4, "s_params": ['S21'], "meas_formats": ['LOGM'], "combine_mode": 'all_to_all'}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["voltages", "currents", "wavs", "num_averages", "combine_mode", "s_params", "meas_formats"]

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')

        x_data = data[0]
        y_data = data[1:]

        plot_graph(x_data, y_data, canvas_handle=canvas_handle, xlabel='Freq (Hz)', ylabel='s_21 (dB)',
                   title='VNA vs V, I meas', legend=self.legend)


if __name__ == '__main__':

    vna = HP8722D()
    vna.initialize()

    # ---- TEST ---
    instr_list = [vna]
    exp = AcquireVNATrace(instr_list)

    # params = {"num_averages": 2, "s_params": ["S11", "S22", "S21", "S12"], "meas_formats": ["LOGM", "PHAS"]}
    params = {"num_averages": 4, "s_params": ["S21"], "meas_formats": ["LOGM"]}

    exp.perform_experiment(params, filename='bjt_mod--npn--1550--eos_det_mix--Vbe=0.88V--Ibe=100uA--Vbc=0.5V--Ibc=-72.3uA')

    # --- sub-threshold region transistor char --

    # gate_smu = Keithley2635A()
    # drain_smu = Keithley2400()
    #
    # gate_smu.initialize()
    # drain_smu.initialize()
    #
    # instr_list = [vna, gate_smu, drain_smu]
    #
    # exp = VNADoubleBiasVSweep(instr_list)
    #
    # gate_vs = [0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5]
    # drain_vs = [0.2, 1]
    # params = {"voltages": gate_vs, "voltages2": drain_vs, "wavs": None,
    #           "num_averages": 2, "combine_mode": 'all_to_all', "s_params": ["S11", "S22", "S21", "S12"],
    #           "meas_formats": ["LOGM", "PHAS"]}
    #
    # # RUN IT
    # exp.perform_experiment(params, filename='dut2--RT--subthreshold_char')
    #
    # gate_smu.close()
    # drain_smu.close()

    # -------------------------------

    # --- amp characterization

    # --- sub-threshold region transistor char --

    # vdd_smu = Keithley2635A()
    # ibias_smu = Keithley2400()
    #
    # vdd_smu.initialize()
    # ibias_smu.initialize()
    #
    # instr_list = [vna, vdd_smu, ibias_smu]
    #
    # exp = VNABiasVandBiasISweep(instr_list)
    #
    # vdds = [0.8, 0.85, 0.9, 0.95, 1]
    # ibias = [1e-6, 1.5e-6, 1.75e-6, 2e-6, 2.25e-6, 2.5e-6, 3e-6]
    # params = {"voltages": vdds, "currents": ibias, "wavs": None,
    #           "num_averages": 2, "combine_mode": 'all_to_all', "s_params": ["S11", "S22", "S21", "S12"],
    #           "meas_formats": ["LOGM", "PHAS"]}
    #
    # # RUN IT
    # exp.perform_experiment(params, filename='amp--RT')
    #
    # vdd_smu.close()
    # ibias_smu.close()

    # -------------------------------

    # CLOSE INSTRUMENTS
    vna.close()