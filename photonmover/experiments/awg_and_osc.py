from photonmover.Interfaces.Experiment import Experiment

# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.WaveformGenerator import WaveformGenerator
from photonmover.instruments.Oscilloscopes.RigolDS1000 import RigolDS1000

# This is only necessary for the example
from photonmover.instruments.Arbitrary_waveform_generators.Agilent33201A import Agilent33201A

# General imports
import time
import numpy as np


class AWG_and_OSC(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.awg = None
        self.osc = None

        self.check_necessary_instruments(instrument_list)

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError("The necessary instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary to perform the experiment are present.
        :param instrument_list: list of the available instruments 
        :return: True if the necessary instruments are present, False otherwise.
        """
        for instr in instrument_list:
            if isinstance(instr, WaveformGenerator):
                self.awg = instr
            if isinstance(instr, RigolDS1000):
                self.osc = instr

        if (self.osc is not None) and (self.awg is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return "Sweeps amplitude, bias and frequency of a square wave and records the resulting " \
               "signal with an oscilloscope."

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "AWG + OSC"
           
    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)

        biases = params["voltages"]
        amps = params["amplitudes"]
        freqs = params["freqs"]

        for freq in freqs:
            for amp in amps:
                for bias in biases:

                    # Set the awg
                    self.awg.set_waveform('SQU', freq, amp, bias)
                    time.sleep(1)

                    # Autoscale the oscilloscope
                    self.osc.autoscale()
                    time.sleep(8)

                    # Acquire and save data

                    if filename is not None:
                        fname = "%s-Vgs_bias=%.3fV--Vgs_amp=%.3fV--Vgs_freq=%.3fkHz" % (filename, vgs_bias,
                                                                                        vgs_amp,
                                                                                        vgs_freq*1e-3)
                    else:
                        fname = None

                    osc.read_waveform([1, 2], fname)

        return None
    
    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["voltages", "amplitudes", "freqs"]

    def plot_data(self, canvas_handle, data=None):
        raise Exception('No data to plot for AWG and osc experiment')


if __name__ == '__main__':

    # INSTRUMENTS
    osc = RigolDS1000()
    awg = Agilent33201A()
    osc.initialize()
    awg.initialize()

    # EXPERIMENT PARAMETERS
    start_vgs_bias = 0.1
    stop_vgs_bias = 0.46
    num_vgs_bias = 37
    vgs_bias = np.linspace(start_vgs_bias, stop_vgs_bias, num_vgs_bias)

    vgs_amp = [0.1]  # Was 0.1
    vgs_freq = [100]

    # SET UP THE EXPERIMENT
    instr_list = [osc, awg]
    exp = AWG_and_OSC(instr_list)
    params = {"voltages": vgs_bias, "amplitudes": vgs_amp, "freqs": vgs_freq}

    # RUN IT
    exp.perform_experiment(params, filename="N=4_long_gate_Isc=10uA")

    # CLOSE INSTRUMENTS
    osc.close()
    awg.close()