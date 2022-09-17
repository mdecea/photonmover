from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.PowMeter import PowerMeter
from photonmover.Interfaces.SourceMeter import SourceMeter

# This is only necessary for the example
from photonmover.instruments.Lasers.HPLightWave import HPLightWave
from photonmover.instruments.Source_meters.Keithley2400 import Keithley2400
from photonmover.instruments.Power_meters.HP8153A import HP8153A

# General imports
import time
import numpy as np
import csv


class LI_curve(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.pm = None
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
            if isinstance(instr, PowerMeter):
                self.pm = instr
            if isinstance(instr, SourceMeter):
                self.sm = instr

        if (self.pm is not None) and (self.sm is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return " Performs an LI measurement: sweeps applied current and measures power. "

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "LI curve"
        
    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)
        
        currents = params["currents"]
        meas_volt = params["meas_volt"]

        power_list = []
        volt_list = []

        # Sweep current and get power
        for cur in currents:

            print('Measuring %.4f mA...' % (cur*1e3))
            # Set the current
            self.sm.set_current(cur)
            print('Set Source meter current')

            # Wait 200 ms
            time.sleep(0.2)

            if meas_volt:
                v = self.sm.measure_voltage()
                volt_list.append(v)

            # Get power
            [_, power] = self.pm.get_powers()

            print('Measured power is %.3e W' % (power))

            power_list.append(power)

        print('Finished LI curve')
        print('-----------------------------')

        if filename is not None:
            # Save the data in a csv file
            time_tuple = time.localtime()
            complete_filename = "%s--%d#%d#%d_%d#%d#%d.csv" % (filename,                                            
                                                            time_tuple[0],
                                                            time_tuple[1],
                                                            time_tuple[2],
                                                            time_tuple[3],
                                                            time_tuple[4],
                                                            time_tuple[5])

            with open(complete_filename, 'w+') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(currents)
                writer.writerow(power_list)
                if meas_volt:
                    writer.writerow(volt_list)

        self.data = [currents, power_list]

        return [currents, power_list]
    
    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionary, in order for
        a measurement to be performed
        """
        return ["currents", "meas_volt"]

    def default_params(self):
        return {"meas_volt": False}

    def plot_data(self, canvas_handle, data=None):
        
        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')
        
        curs = data[0]
        powers = data[1]

        plot_graph(x_data=curs, y_data=powers, canvas_handle=canvas_handle, xlabel='Current (A)', ylabel='Power (mW)', title='LI curve', legend=None)


if __name__ == '__main__':

    pm_channel = 1  # Channel of the power meter to which the fiber is connected
    cur_compliance = 0.05  # Current compliance for source meter (in A)
    v_compliance = 10  # Voltage compliance for source meter (in V)

    # INSTRUMENTS
    pm = HPLightWave(tap_channel=1, rec_channel=3)
    sm = Keithley2400(current_compliance=cur_compliance, voltage_compliance=v_compliance)

    pm.initialize()
    sm.initialize()

    # EXPERIMENT PARAMETERS
    init_current = 8e-3  # in A
    end_current = 20e-3 # in A
    num_current = 120 # Number of points between init and end current
    # cur_list = np.linspace(init_current, end_current, num_current)
    cur_list = np.logspace(np.log10(init_current), np.log10(end_current), num_current)

    file_name = 'AIM_MZM_SMF_2'  # Filename where to save csv data

    # SET UP THE EXPERIMENT
    instr_list = [pm, sm]
    exp = LI_curve(instr_list)
    params = {"currents": cur_list, "meas_volt": True}

    # RUN IT
    exp.perform_experiment(params, filename=file_name)

    # CLOSE INSTRUMENTS
    pm.close()
    sm.close()
