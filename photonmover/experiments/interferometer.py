# Michelson Interferometer measurement
# Moves the stage to different positions, measures power

from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.PowMeter import PowerMeter
from photonmover.Interfaces.Stage import SingleAxisStage

# This is only necessary for the example
from photonmover.instruments.Stages.KlingerCC1 import KlingerCC1
from photonmover.instruments.Power_meters.HP8153A import HP8153A

# General imports
import time
import numpy as np
import scipy.io as io
import winsound
import csv


class Interferometer(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT:
        WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.stage = None

        self.pm = None

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError(
                "The instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments to perform the experiment are present.
        :param instrument_list: list of the available instruments
        :return: True if the instruments are present, False otherwise.
        """

        for instr in instrument_list:
            if isinstance(instr, PowerMeter):
                self.pm = instr
            elif isinstance(instr, SingleAxisStage):
                self.stage = instr

        if self.pm is not None and self.stage is not None:
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return " Moves the stage and records power. "

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Interferometer"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dict of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)

        positions = params["positions"]  # Positions to measure (in mm). First element is current position.

        powers = []

        # Measure at current position
        [_, power] = self.pm.get_powers()
        powers.append(power)

        for i in range(1, len(positions)):

            self.stage.move(positions[i]-positions[i-1])
            time.sleep(0.2)
            [_, power] = self.pm.get_powers()
            powers.append(power)            

        if filename is not None:
            # Save the data in a csv file
            time_tuple = time.localtime()
            complete_filename = "%s--interferometer--%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                               time_tuple[0],
                                                                               time_tuple[1],
                                                                               time_tuple[2],
                                                                               time_tuple[3],
                                                                               time_tuple[4],
                                                                               time_tuple[5])

            with open(complete_filename, 'w+') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(positions)
                writer.writerow(powers)

        self.data = [positions, powers]

        return [positions, powers]

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in
        the params dictionary, in order for
        a measurement to be performed
        """
        return ["positions"]

    def plot_data(self, canvas_handle, data=None):

        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError(
                    'plot_data was called before performing the experiment'
                    ' or providing data')

        positions = data[0]
        powers = data[1]

        plot_graph(
            x_data=np.array(positions)*1e7,
            y_data=powers,
            canvas_handle=canvas_handle,
            xlabel='Position (nm)',
            ylabel='Power (mW)',
            title='Interferometer',
            legend=None)


if __name__ == '__main__':

    # INSTRUMENTS
    pm = HP8153A(rec_channel=1, tap_channel=None)
    stage = KlingerCC1(mode='low_speed')

    pm.initialize()
    stage.initialize()

    # EXPERIMENT PARAMETERS
    pos = np.arange(0, 1.55*2, 0.1)*1e-4  # Positions in mm

    file_name = 'HP_laser_test'  # Filename where to save csv data

    # SET UP THE EXPERIMENT
    instr_list = [pm, stage]
    exp = Interferometer(instr_list)
    params = {"postions": pos}

    # RUN IT
    exp.perform_experiment(params, filename=file_name)

    # CLOSE INSTRUMENTS
    pm.close()
    stage.close()