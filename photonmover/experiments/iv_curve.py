from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.SourceMeter import SourceMeter

# This is only necessary for the example
from photonmover.instruments.Source_meters.Keithley2400 import Keithley2400

# General imports
import time
import numpy as np
import scipy.io as io
import winsound


class IVCurve(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.sm = None

        self.data = None

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError("The necessary instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary to perform the experiment are present.
        :param instrument_list: list of the available instruments 
        :return: True if the necessary instruments are present, False otherwise.
        """

        for instr in instrument_list:
            if isinstance(instr, SourceMeter):
                self.sm = instr

        if self.sm is not None:
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return " Performs an IV measuremet: sweeps applied voltage and measures current. "

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "IV curve"
           
    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)
        
        voltages = params["voltages"]

        # Save current state so that we can get back to it after the measurement
        prev_bias = self.sm.measure_voltage()

        iv_data = self.sm.take_IV(voltages[0], voltages[-1], len(voltages))

        if filename is not None:

            time_tuple = time.localtime()
            filename = "%s--iv--%d-%d-%d--%d#%d#%d--%d#%d#%d.mat" % (filename,
                                                                     voltages[0],
                                                                     len(voltages),
                                                                     voltages[-1],
                                                                     time_tuple[0],
                                                                     time_tuple[1],
                                                                     time_tuple[2],
                                                                     time_tuple[3],
                                                                     time_tuple[4],
                                                                     time_tuple[5])

            print("Saving data to ", filename)
            io.savemat(filename, {'iv': iv_data})

        # Beep when done
        winsound.Beep(2000, 1000)

        # Return to previous state
        self.sm.set_voltage(prev_bias)

        self.data = iv_data

        return iv_data

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["voltages"]

    def plot_data(self, canvas_handle, data=None):
        
        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')

        volts = data[:,0]
        curs = data[:,1]

        plot_graph(x_data=volts, y_data=np.log10(np.abs(curs)), canvas_handle=canvas_handle, xlabel='Voltage (V)', ylabel='log10(Current) (A)', title='IV curve', legend=None)
        

if __name__ == '__main__':

    cur_compliance = 0.1  # Current compliance for source meter (in A)
    v_compliance = 3 # Voltage compliance for source meter (in V)

    # INSTRUMENTS
    sm = Keithley2400(current_compliance=cur_compliance, voltage_compliance=v_compliance)

    sm.initialize()

    # EXPERIMENT PARAMETERS
    init_voltage = 0  # in V
    end_voltage = 2 # in V
    num_volts = 50 # Number of points between init and end current
    volt_list = np.linspace(init_voltage, end_voltage, num_volts)

    file_name = 'IV_curve_trial'  # Filename where to save csv data

    # SET UP THE EXPERIMENT
    instr_list = [sm]
    exp = IVCurve(instr_list)
    params = {"voltages": volt_list}

    # RUN IT
    exp.perform_experiment(params, filename=file_name)

    # CLOSE INSTRUMENTS
    sm.close()
