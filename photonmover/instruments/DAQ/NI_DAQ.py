import sys
sys.path.insert(0,'../..')

import nidaqmx
import time
from Interfaces.Instrument import Instrument


class NiDAQ(Instrument):
    """
    This class interfaces with the National Instruments DAQ card.
    """

    def __init__(self):
        super().__init__()
        # You program the NI_DAQ through tasks. For now, we will only have a single task
        self.task = None

    def initialize(self):
        """
        We don't really need to do anything, but we have it for compliance with the Instrument interface
        :return:
        """
        pass

    def get_id(self):
        return "DAQ"

    def close(self):
        if self.task is not None:
            self.task.close()

    def start_task(self):
        self.task.start()

    def wait_task(self, timeout=200):
        self.task.wait_until_done(timeout=timeout)  # timeout is in seconds

    def read_data(self, num_points):
        data = self.task.read(number_of_samples_per_channel=num_points)
        self.task.stop()
        return data

    def configure_nsampl_acq(self, input_channels, clk_channel=None, num_points=2, max_sampling_freq=1000, min_vals=None, max_vals=None):
        """
        Creates a DAQ task to acquire voltage at the specified analog input channels. Specify the number of points to
        be acquired and teh clock reference. If None, the internal clock of the board is used.
        :param input_channels: Analog input channels to record
        :param clk_channel: Clock source. If None, the internal clock is used
        :param num_points: Number of points to acquire per each channel
        :param max_sampling_freq: Maximum sampling frequency (in samples per second)
        :param min_vals: Min voltage value to measure. If None, we will assume it is 0. Either a list for each channel or a single number (all channels the same)
        :param max_vals: Max voltage value to measure. If None, we will assume it is 2.0. Either a list for each channel or a single number (all channels the same)
        :return:
        """
        if self.task is not None:
            self.task.close()
            self.task = None

        if min_vals is None:
            min_vals = 0.0
        
        if max_vals is None:
            max_vals = 2.0

        if not isinstance(min_vals, list):
            min_vals = [min_vals]*len(input_channels)

        if not isinstance(max_vals, list):
            max_vals = [max_vals]*len(input_channels)

        self.task = nidaqmx.Task()
        for i, in_channel in enumerate(input_channels):
            self.task.ai_channels.add_ai_voltage_chan(in_channel, min_val=min_vals[i], max_val=max_vals[i])

        self.task.timing.cfg_samp_clk_timing(max_sampling_freq, source=clk_channel, active_edge=nidaqmx.constants.Edge.FALLING,
                                             samps_per_chan=num_points)

    def configure_channel_acq(self, input_channels, min_vals, max_vals):
        """
        Creates a DAQ task to acquire voltage at the specified analog input channels.
        :param input_channels: Analog input channels to record (list)
        :param min_vals: Minimum voltages to expect for each analog input channel (list, same length as input_channels, or single number if all channels are the same)
        :param max_vals: Maximum voltages to expect for each analog input channel (list, same length as input_channels, or single number if all channels are the same)
        :return:
        """
        if self.task is not None:
            self.task.close()
            self.task = None

        self.task = nidaqmx.Task()

        if not isinstance(min_vals, list):
            min_vals = [min_vals]*len(input_channels)

        if not isinstance(max_vals, list):
            max_vals = [max_vals]*len(input_channels)

        for i, in_channel in enumerate(input_channels):
            self.task.ai_channels.add_ai_voltage_chan(in_channel, min_val=min_vals[i], max_val=max_vals[i])



if __name__ == '__main__':

    with nidaqmx.Task() as task:
        task.ci_channels.add_ci_count_edges_chan("Dev1/ctr1")
        task.start()

        while (True):
            #print('1 Channel 1 Sample Read: ')
            data = task.read(number_of_samples_per_channel=1)
            time.sleep(1)
            print(data)

        print('1 Channel N Samples Read: ')
        data = task.read(number_of_samples_per_channel=1000)
        print(data)