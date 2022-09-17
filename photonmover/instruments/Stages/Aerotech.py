# Controls de Aerotech stage. This is a special Instrument because it is made of
# other instruments (a daq and an SMU).
from photonmover.Interfaces.Instrument import Instrument
from photonmover.Interfaces.Stage import SingleAxisStage


# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.SourceMeter import SourceMeter
from photonmover.instruments.DAQ.NI_DAQ import NiDAQ

# For the example
from photonmover.instruments.Source_meters.KeysightB2902A import KeysightB2902A

# General imports
import time
import nidaqmx
import winsound
import numpy as np


class AerotechStage(Instrument, SingleAxisStage):

    def __init__(self, smu, daq, dist_to_counts=500, drive_current=0.55, daq_channel=None):
        """
        :param smu: an already initialized SourceMeter that applies current to the stage
        :param daq: a DAQ that reads the feedback from the encoder
        :param dist_to_counts: Conversion between distance and counts on the encoder (in counts/mm)
        :param drive_current: Current at which to drive the motor in Amps. We assume it has the sign that will move the motor in the positive direction.
                It can either be a single number, in which case we will apply +drive_current and -drive_current, or
                a two element list, in which case we will apply drive_current[0] and drive_current[1] for each direction respecitvely.
        :param daq_channel: daq channel to which the stage feedback is connected. None if we want to use the default.
                                Example: "/Dev1/PFI0"
        """
        super().__init__()

        # It is always good practice to initialize variables in the init

        # Instruments. 
        self.smu = smu
        self.daq = daq

        self.dist_to_counts = dist_to_counts
        self.bias_cur = drive_current
        self.daq_channel = daq_channel

    def initialize(self):
        # We don't really need to do anything
        pass

    def set_drive_current(self, drive_current):
        self.bias_cur = drive_current

    def set_dist_to_counts(self, dist_to_counts):
        self.dist_to_counts = dist_to_counts

    def move(self, dist):
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
            
        """

        if isinstance(self.bias_cur, list):
            if dist > 0:
                bias_set = self.bias_cur[0]
            else:
                bias_set = self.bias_cur[1]
        else:
            if dist < 0:
                bias_set = -1*self.bias_cur
            else:
                bias_set = self.bias_cur

        # Set the current drive for the smu
        self.smu.set_current(bias_set, turn_on=False)

        # Configure DAQ task
        daq_task = nidaqmx.Task()
        daq_task.ci_channels.add_ci_count_edges_chan("Dev1/ctr1")
        if self.daq_channel is not None:
            daq_task.ci_channels[0].ci_count_edges_term = self.daq_channel

        # Start the task and turn on the SMU
        daq_task.start()
        self.smu.turn_on()

        # Monitor the task and stop when we have reached the required number of counts
        desired_counts = abs(dist)*self.dist_to_counts
        cts = 0

        while (cts < desired_counts):
            cts = daq_task.read()
            # print(cts)
        
        self.smu.turn_off()
        final_counts = daq_task.read()
        daq_task.close()

        print('We wanted %d counts and we got %d.' % (desired_counts, final_counts))

    def close(self):
        # We don't really need to do anything
        pass


if __name__ == '__main__':

    smu = KeysightB2902A(channel=1, current_compliance=1)
    daq = NiDAQ()

    smu.initialize()
    daq.initialize()

    smu.set_voltage_compliance(10)

    instr_list = [smu, daq]
    stage = AerotechStage(smu, daq, dist_to_counts=500, drive_current=0.55, daq_channel=None)

    # RUN IT
    stage.move(70)

    # CLOSE INSTRUMENTS
    smu.close()
    daq.close()