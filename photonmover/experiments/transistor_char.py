# Experiments for transistor characterization

from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.SourceMeter import SourceMeter

# For the example
from photonmover.instruments.Source_meters.Keithley2635A import Keithley2635A
from photonmover.instruments.Source_meters.KeysightB2902A import KeysightB2902A
from photonmover.instruments.Source_meters.Keithley2400 import Keithley2400

from photonmover.experiments.iv_curve import IVCurve

# General imports
import time
import scipy.io as io
import winsound
import numpy as np


class BJTTransOutputCurve(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS
        HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock=None)

        # It is always good practice to initialize variables in the init

        # Instruments. We need 2 source meters, one connected at the BE junction,
        # the other to the CE junction.
        self.be_smu = None
        self.ce_smu = None

        self.data = None
        self.legend = None

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
                if self.be_smu is None:
                    self.be_smu = instr
                else:
                    self.ce_smu = instr

        if (self.ce_smu is not None) and (self.be_smu is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return " BJT output curve: Forces an Ib, measures Ic vs Vce. "

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "BJT output curve"

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
            "voltages" --> CE voltages to be applied
            "currents" --> Base current to be applied
        """

        params = self.check_all_params(params)
        base_currents = params["currents"]  # Base currents to apply
        ce_voltages = params["voltages"]  # Collector-emitter current to applyt

        # Save current state so that we can get back to it after the
        # measurement
        prev_base_current = self.be_smu.measure_current()
        prev_ce_voltage = self.ce_smu.measure_voltage()

        self.legend = []
        all_meas_data = []

        # Force a base current, sweep ce voltage and measure C current.
        for base_i in base_currents:

            self.be_smu.set_current(base_i)

            collector_emitter_sweep = IVCurve([self.ce_smu])
            iv_data = collector_emitter_sweep.perform_experiment(
                params={"voltages": ce_voltages}, filename=None)

            self.legend.append('Ib = %.2f mA' % (base_i * 1e3))
            all_meas_data.append(np.log10(np.abs(iv_data[:, 1])))

            if filename is not None:

                time_tuple = time.localtime()
                filename_comp = "%s--bjt_output--Ib=%.4emA--%d#%d#%d--%d#%d#%d.mat" % (filename,
                                                                                       base_i * 1e3,
                                                                                       time_tuple[0],
                                                                                       time_tuple[1],
                                                                                       time_tuple[2],
                                                                                       time_tuple[3],
                                                                                       time_tuple[4],
                                                                                       time_tuple[5])

                print("Saving data to ", filename_comp)
                io.savemat(filename_comp, {'iv': iv_data})

        # Beep when done
        winsound.Beep(2000, 1000)

        # Return to previous state
        self.be_smu.set_current(prev_base_current)
        self.ce_smu.set_voltage(prev_ce_voltage)

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_plt_data = [iv_data[:, 0]]
        all_plt_data.extend(all_meas_data)

        self.data = all_plt_data

        return iv_data

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionary, in order for
        a measurement to be performed
        """
        return ["voltages", "currents"]

    def plot_data(self, canvas_handle, data=None):

        if data is not None:
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
            xlabel='Vce (V)',
            ylabel='log10(Ic) (A)',
            title='BJT curve',
            legend=self.legend)


class FETTransOutputCurve(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS
        HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments. We need 2 source meters, one connected at the gate of the transistor,
        # and one at the drain-source.
        self.gate_smu = None
        self.drain_smu = None

        self.legend = None
        self.data = None

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
        return " MOS output curve: Forces a Vgs, measures Ids vs Vds. "

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "MOS output curve"

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
            "voltages2" --> Drain-source voltages to be applied.
        """

        params = self.check_all_params(params)
        gate_voltages = params["voltages"]
        drain_voltages = params["voltages2"]

        # Save current state so that we can get back to it after the
        # measurement
        prev_gate_voltage = self.gate_smu.measure_voltage()
        prev_drain_voltage = self.drain_smu.measure_voltage()

        self.legend = []
        all_meas_data = []

        # Force a Vgs, take IV curve of the DS.
        for gate_v in gate_voltages:

            self.gate_smu.set_voltage(gate_v)

            drain_source_sweep = IVCurve([self.drain_smu])
            iv_data = drain_source_sweep.perform_experiment(
                params={"voltages": drain_voltages}, filename=None)

            self.legend.append('Vgs = %d mV' % (gate_v * 1e3))
            all_meas_data.append(np.log10(np.abs(iv_data[:, 1])))

            if filename is not None:

                time_tuple = time.localtime()
                filename_comp = "%s--transistor_output--Vgs=%.4eV--%d#%d#%d--%d#%d#%d.mat" % (filename,
                                                                                              gate_v,
                                                                                              time_tuple[0],
                                                                                              time_tuple[1],
                                                                                              time_tuple[2],
                                                                                              time_tuple[3],
                                                                                              time_tuple[4],
                                                                                              time_tuple[5])

                print("Saving data to ", filename_comp)
                io.savemat(filename_comp, {'iv': iv_data})

        # Beep when done
        winsound.Beep(2000, 1000)

        # Return to previous state
        self.gate_smu.set_voltage(prev_gate_voltage)
        self.drain_smu.set_voltage(prev_drain_voltage)

        # The plot data is given as [x vals, y vals1, y vals2,...]
        all_plt_data = [iv_data[:, 0]]
        all_plt_data.extend(all_meas_data)

        self.data = all_plt_data

        return all_plt_data

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionary, in order for
        a measurement to be performed
        """
        return ["voltages", "voltages2"]

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
            xlabel='Vds (V)',
            ylabel='log10(Ids) (A)',
            title='MOS curve',
            legend=self.legend)


if __name__ == '__main__':

    # # -----------------------------------------
    # # FET output curve
    # gate_smu = KeysightB2902A()
    # drain_smu = Keithley2635A()

    # gate_smu.initialize()
    # drain_smu.initialize()

    # instr_list = [gate_smu, drain_smu]
    # exp = FETTransOutputCurve(instr_list)

    # # Parameters
    # voltages = np.linspace(0, -1.6, 17)  # Gate voltages to be applied
    # voltages2 = np.linspace(-3, 1, 401)  # Drain voltages to be applied

    # params = {"voltages": voltages, "voltages2": voltages2}

    # # RUN IT
    # exp.perform_experiment(params, filename='led=3_det=1')

    # # CLOSE INSTRUMENTS
    # gate_smu.close()
    # drain_smu.close()

    # -----------------------------------------
    # BJT output curve
    be_smu = Keithley2400()
    ce_smu = KeysightB2902A()

    be_smu.initialize()
    ce_smu.initialize()

    instr_list = [be_smu, ce_smu]
    exp = BJTTransOutputCurve(instr_list)

    # Parameters
    currents = [500e-9, 1e-6, 5e-6, 10e-6, 50e-6, 100e-6, 250e-6, 500e-6]
    voltages = np.linspace(-1.5, 1.5, 61)  # CE voltages to be applied

    params = {"voltages": voltages, "currents": currents}

    # RUN IT
    exp.perform_experiment(params, filename='BJTmod--1550--pnp--eos_dopings')

    # CLOSE INSTRUMENTS
    be_smu.close()
    ce_smu.close()
