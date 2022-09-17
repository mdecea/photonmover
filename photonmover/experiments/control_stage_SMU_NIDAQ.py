
# Uses an SMU to drive the aerotech stage, and uses an NiDAQ to implement the feedback and know when to stop.

from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.SourceMeter import SourceMeter
from photonmover.instruments.DAQ.NI_DAQ import NiDAQ

# For the example
from photonmover.instruments.Source_meters.KeysightB2902A import KeysightB2902A
from photonmover.instruments.Source_meters.Keithley2400 import Keithley2400

# General imports
import time
import nidaqmx
import winsound
import numpy as np


class AerotechControl(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS
        HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments. 
        self.smu = None
        self.daq = None

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
                self.smu = instr
            if isinstance(instr, NiDAQ):
                self.daq = instr

        if (self.smu is not None) and (self.daq is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return " Controls the aerotech stage with a source meter and a DAQ for feedback "

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Aerotech control"
           
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
            "distance" --> Distance to move in mm
            "distance_to_counts" --> Conversion between distance and counts on the encoder (in counts/mm)
            "drive_current" --> Current at which to drive the motor in Amps. We assume it has the sign that will move the motor in the positive direction.
                It can either be a single number, in which case we will apply +drive_current and -drive_current, or
                a two element list, in which case we will apply drive_current[0] and drive_current[1] for each direction respecitvely.
            "daq_channel" --> daq channel to which the stage feedback is connected. None if we want to use the default.
                                Example: "/Dev1/PFI0"
        """

        params = self.check_all_params(params)

        dist = params["distance"]
        dist_to_counts = params["distance_to_counts"]
        bias_cur = params["drive_current"]
        daq_channel = params["daq_channel"]

        if isinstance(bias_cur, list):
            if dist > 0:
                bias_cur = bias_cur[0]
            else:
                bias_cur = bias_cur[1]
        else:
            if dist < 0:
                bias_cur = -1*bias_cur
            else:
                bias_cur = bias_cur

        # Set the current drive for the smu
        self.smu.set_current(bias_cur, turn_on=False)

        # Configure DAQ task
        daq_task = nidaqmx.Task()
        daq_task.ci_channels.add_ci_count_edges_chan("Dev1/ctr1")
        if daq_channel is not None:
            daq_task.ci_channels[0].ci_count_edges_term = daq_channel

        # Start the task and turn on the SMU
        daq_task.start()
        self.smu.turn_on()

        # Monitor the task and stop when we have reached the required number of counts
        desired_counts = abs(dist)*dist_to_counts
        cts = 0

        while (cts < desired_counts):
            cts = daq_task.read()
            #print(cts)
        
        self.smu.turn_off()
        final_counts = daq_task.read()
        daq_task.close()

        print('We wanted %d counts and we got %d.' % (desired_counts, final_counts))

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionary, in order for
        a measurement to be performed
        """
        return ["distance", "distance_to_counts", "drive_current", "daq_channel"]
    
    def default_params(self):
        return {"distance_to_counts": 500, "drive_current": 0.5, "daq_channel": None}

    def plot_data(self, canvas_handle, data=None):
        # Nothing to plot
        return


if __name__ == '__main__':

    # smu = KeysightB2902A(channel=1, current_compliance=1)
    smu = Keithley2400(current_compliance=1)
    daq = NiDAQ()

    smu.initialize()
    daq.initialize()

    smu.set_voltage_compliance(10)

    instr_list = [smu, daq]
    exp = AerotechControl(instr_list)

    while (True):
        dist = float(input('Enter distance to move in mm: '))

        params = {"distance": dist, "distance_to_counts": 500, "drive_current": 0.55, "daq_channel": None}

        # RUN IT
        exp.perform_experiment(params)

    #time.sleep(5)


    #params = {"distance": 10.0, "distance_to_counts": 500, "drive_current": 0.55, "daq_channel": None}

    # RUN IT
    #exp.perform_experiment(params)

    # CLOSE INSTRUMENTS
    smu.close()
    daq.close()