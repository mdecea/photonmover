# Takes the output characteristics of a pv modulator. Forces an Ids, forces a Vgs and
# measures Vds.

from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

# Interfaces/instruments necessary for the experiment
# - You use an INterface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.SourceMeter import SourceMeter

# General imports
import time
import numpy as np
import scipy.io as io
import winsound


class PVModOutputCurve(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments. We need 2 source meters, one connected at the gate of the transistor,
        # and one at the drain-source.
        self.gate_smu = None
        self.drain_smu = None

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
            if isinstance(instr, SourceMeter):
                if self.gate_smu is None:
                    self.gate_smu = instr
                else:
                    self.drain_smu = instr

        if (self.gate_smu is not None) and (self.drain_smu is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return " PV mod output curve: Forces an Ids and a Vgs, measures Vds. "

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "PV mod output curve"

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
            "voltages" --> Gate voltages to be applied.
            "currents" --> Drain-source currents to be applied.
        """

        params = self.check_all_params(params)

        gate_voltages = params["voltages"]
        drain_currents = params["currents"]

        prev_gate_bias = self.gate_smu.measure_voltage()

        self.legend = []
        all_meas_data = []

        # Iterate over currents
        for ids in drain_currents:

            # First, force current
            self.drain_smu.set_current(ids)
            self.legend.append('Ids = %.2E uA' % (ids * 1e6))

            measurements = np.zeros((len(gate_voltages), 2), float)

            # Force a Vgs, measure Vds.
            for i, gate_v in enumerate(gate_voltages):
                self.gate_smu.set_voltage(gate_v)
                vds = self.gate_smu.measure_voltage()

                measurements[i, 0] = gate_v
                measurements[i, 1] = vds

            all_meas_data.append(measurements[:, 1])

            if filename is not None:

                time_tuple = time.localtime()
                filename_comp = "%s--pv_mod_output--Ids=%.4e-Vgs=%.4eV-%.4eV%dnum--%d#%d#%d--%d#%d#%d.mat" % (filename,
                                                                                                              ids,
                                                                                                              gate_voltages[0],
                                                                                                              gate_voltages[-1],
                                                                                                              len(gate_voltages),
                                                                                                              time_tuple[0],
                                                                                                              time_tuple[1],
                                                                                                              time_tuple[2],
                                                                                                              time_tuple[3],
                                                                                                              time_tuple[4],
                                                                                                              time_tuple[5])
                print("Saving data to ", filename_comp)
                io.savemat(filename_comp, {'vgs_vds': measurements})

        # Beep when done
        winsound.Beep(2000, 1000)

        # Return to previous state
        self.drain_smu.set_current(0)
        self.gate_smu.set_voltage(prev_gate_bias)

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_data = [measurements[:, 0]]
        all_data.extend(all_meas_data)

        self.data = all_data

        return all_data

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["voltages", "currents"]

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
            x_data,
            y_data,
            canvas_handle=canvas_handle,
            xlabel='Vgs (V)',
            ylabel='Vds(V)',
            title='PV mod output curve',
            legend=self.legend)
