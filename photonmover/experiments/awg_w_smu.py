# Uses one smu as a (slow) AWG and a second SMU to measure a relevant variable.
# The idea: set the driving voltage/current of the first smu, measure a relevant variable with the second smu.
# Keep repeating this.

from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.SourceMeter import SourceMeter

# For the example
from photonmover.instruments.Source_meters.Keithley2635A import Keithley2635A
from photonmover.instruments.Source_meters.KeysightB2902A import KeysightB2902A

# General imports
import time
import scipy.io as io
import winsound
import numpy as np


class AwgWSmu(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS
        HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments. We need 2 source meters, one that acts as the AWG (the drive smu) and one that
        # measures (the meas smu)
        self.drive_smu = None
        self.meas_smu = None

        # Save the last data obtained when the experiment was performed (for plotting purposes)
        self.data = None

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError("The necessary instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary to perform the experiment are present.
        The first SMU is the drive smu, the second on eis the measure SMU
        :param instrument_list: list of the available instruments 
        :return: True if the necessary instruments are present, False otherwise.
        """

        for instr in instrument_list:
            if isinstance(instr, SourceMeter):
                if self.drive_smu is None:
                    self.drive_smu = instr
                else:
                    self.meas_smu = instr

        if (self.drive_smu is not None) and (self.meas_smu is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return " SMU as AWG: Sets a driving voltage for the SMU, measures current with another SMU. Then repeats. "

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "SMU as AWG"

    def generate_points(self, shape, shape_params):
        """
        Generates the points corresponding to the specified shape and its parameters. The parameters depend on
        the specific shape.
        Currently supported shapes: 'square', 'triangle', 'sine'
        """

        low_value = shape_params['low_value']  # This is the lowest value of the shape
        high_value = shape_params['high_value']  # This is the highest value of the shape
        points_per_period = shape_params['points_per_period']  # Number of points per period of the shape
        num_periods = shape_params['num_periods']  # Number of periods to generate

        if shape == 'square':
           
            points_per_half_period = round(points_per_period/2)
            single_period = [low_value] * points_per_half_period + [high_value] * points_per_half_period
            waveform_points = single_period * num_periods

        elif shape == 'triangle':

            points_per_half_period = round(points_per_period/2) + 1
            up_ramp = np.linspace(low_value, high_value, points_per_half_period)
            down_ramp = np.flip(up_ramp)
            down_ramp = down_ramp[1:-1]

            single_period = np.concatenate((up_ramp, down_ramp))
            waveform_points = np.tile(single_period, num_periods)

        elif shape == 'sine':
            w = 2*np.pi/points_per_period
            single_period = np.sin(w*np.arange(points_per_period))
            waveform_points = np.tile(single_period, num_periods)

        else:

            raise ValueError('The specified shape is not supported')

        return waveform_points
           
    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        """ 
        params keys:
            "shape" --> Name of the waveform to generate (string) or list of points to generate
            "shape_params" --> Dict with the parameters for the specific shape, or None if 'shape' has a list of points
            "set" --> What are we setting? Either 'voltage' or 'current'. 
            "measure" --> What are we measuring? Either 'voltage' or 'current'. 
            "meas_bias" --> Bias point for the measure SMU. If meas is 'voltage', this should be a current. If meas is 'current', this should be a voltage.
        """

        params = self.check_all_params(params)

        shape = params["shape"]
        shape_params = params["shape_params"]
        set = params["set"]
        measure = params["measure"]
        meas_bias = params["meas_bias"]

        if isinstance(shape, str):
            waveform_points = self.generate_points(shape, shape_params)
        else:
            # We are directly given the points to set
            waveform_points = shape

        # Save current state so that we can get back to it after the measurement
        if set == 'voltage':
            prev_drive_point = self.drive_smu.measure_voltage()
            set_v = True
        else:
            prev_drive_point = self.drive_smu.measure_current()
            set_v = False

        if measure == 'voltage':
            prev_meas_point = self.meas_smu.measure_voltage()
            meas_v = True
        else:
            prev_meas_point = self.meas_smu.measure_current()
            meas_v = False

        num_points = len(waveform_points)
        measurement = np.zeros((num_points, 4), float)
        row = 0

        # Set the bias point of the measure smu
        if meas_v:
            self.meas_smu.set_current(meas_bias)
        else:
            self.meas_smu.set_voltage(meas_bias)

        # Force a set point and measure, repeat for all the points
        for setpoint in waveform_points:

            # Set the drive_smu
            if set_v:
                self.drive_smu.set_voltage(setpoint)
                setpoint_meas = self.drive_smu.measure_current()
            else:
                self.drive_smu.set_current(setpoint)
                setpoint_meas = self.drive_smu.measure_voltage()
            
            # Measure
            if meas_v:
                reading = self.meas_smu.measure_voltage()
            else:
                reading = self.meas_smu.measure_current()

            measurement[row, 0] = row
            measurement[row, 1] = setpoint
            measurement[row, 2] = setpoint_meas
            measurement[row, 3] = reading

            row = row + 1

            print('Point %d out of %d done' % (row, num_points))
            sys.stdout.flush()

        # Save the data
        if filename is not None:

            time_tuple = time.localtime()
            filename_comp = "%s--awg_w_smu--%d#%d#%d--%d#%d#%d.mat" % (filename,     
                                                                        time_tuple[0],
                                                                        time_tuple[1],
                                                                        time_tuple[2],
                                                                        time_tuple[3],
                                                                        time_tuple[4],
                                                                        time_tuple[5])

            print("Saving data to ", filename_comp)
            io.savemat(filename_comp, {'wf': measurement})

        # Beep when done
        winsound.Beep(2000, 1000)

        # Return to previous state
        if set == 'voltage':
            self.drive_smu.set_voltage(prev_drive_point)
        else:
            self.drive_smu.set_current(prev_drive_point)

        if measure == 'voltage':
            self.meas_smu.set_voltage(prev_meas_point)
        else:
            self.meas_smu.set_current(prev_meas_point)

        self.data = measurement

        return measurement

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionary, in order for
        a measurement to be performed
        """
        return ["shape", "shape_params", "set", "measure", "meas_bias"]

    def plot_data(self, canvas_handle, data=None):
        
        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')
        
        t = data[:, 0]
        rel_variable = data[:,2]

        plot_graph(x_data=t, y_data=rel_variable, canvas_handle=canvas_handle, xlabel='Point #', ylabel='Measured value', title='SMU as AWG', legend=None)


if __name__ == '__main__':

    meas_smu = KeysightB2902A(channel=1, current_compliance=0.02)
    drive_smu = KeysightB2902A(channel=2, current_compliance=0.02)

    drive_smu.initialize()
    meas_smu.initialize()

    meas_smu.set_integration_time(100e-3)
    drive_smu.set_integration_time(100e-3)

    instr_list = [drive_smu, meas_smu]
    exp = AwgWSmu(instr_list)

    shape = np.linspace(-1, 1, 201)

    shape_params = {'low_value': 0, 'high_value': -1.6, 'points_per_period': 6, 'num_periods': 10}
    params = {"shape": shape, "shape_params": shape_params, "set": 'voltage',
              "measure": 'voltage', "meas_bias": 0.75e-3}

    # RUN IT
    exp.perform_experiment(params, filename='eos_det_dopings--npn--Ib=750uA')

    # CLOSE INSTRUMENTS
    drive_smu.close()
    meas_smu.close()

    """
    ## LED measurements
    drive_smu = KeysightB2902A()
    meas_smu = Keithley2635A()

    drive_smu.initialize()
    meas_smu.initialize()

    # Configure measure smu to minimize noise
    meas_smu.set_measurement_integration(nplc=25)
    meas_smu.set_filter(enable=True, type='repeat_average', count=10)

    instr_list = [drive_smu, meas_smu]
    exp = AwgWSmu(instr_list)

    shape_params = {'low_value': 0, 'high_value': -1.6, 'points_per_period': 6, 'num_periods': 10}
    params = {"shape": 'square', "shape_params": shape_params, "set": 'voltage',
              "measure": 'current', "meas_bias": -1.5}

    # RUN IT
    exp.perform_experiment(params, filename='square_wave--led=2--det=1--det_bias=-1.5V')

    # CLOSE INSTRUMENTS
    drive_smu.close()
    meas_smu.close()
    """
