
import sys
from photonmover.utils.plot_utils import filter_nans
from photonmover.Interfaces.Experiment import Experiment
from photonmover.utils.plot_utils import plot_graph

# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.MSA import MSA
from photonmover.Interfaces.WaveformGenerator import WaveformGenerator

# This is only necessary for the example
from photonmover.instruments.Microwave_spectrum_analyzers.HP70900A import HP70900A
from photonmover.instruments.Arbitrary_waveform_generators.Agilent81180A import Agilent81180A

# General imports
import time
import numpy as np
import csv


class BW_AWG_and_MSA(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.awg = None
        self.msa = None

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
            if isinstance(instr, WaveformGenerator):
                self.awg = instr
            if isinstance(instr, MSA):
                self.msa = instr

        if (self.msa is not None) and (self.awg is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return """ Performs a bandwidth measurement by sweeping the frequency of a sinusoid generated 
        by an AWG and measures the response using an MSA. It can also sweep amplitude and offset. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Bandwidth AWG+MSA"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionnary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        params = self.check_all_params(params)

        biases = params["voltages"]
        amps = params["amplitudes"]
        freqs = params["freqs"]

        self.awg.set_waveform('SIN', self.freq[0], self.amp[0], self.bias[0])
        self.awg.turn_on()

        for offset in biases:
            for amp in amps:

                print('Starting freq sweep for offset %.4f mV, amplitude %.4f mV...' % (offset * 1e3, amp * 1e3))

                # Configure AWG and turn on
                self.awg.set_waveform('SIN', self.freq[0], amp, offset)
                self.awg.turn_on()

                peak_freqs = []
                peak_amps = []

                # Sweep frequency and get spectrum for each one
                for freq in freqs:

                    print('Measuring %.4f MHz...' % (freq*1e-6))

                    # Change the frequency of the applied signal
                    self.awg.set_frequency(freq)
                    print('Set AWG Freq.')
                    # Wait 1 second
                    time.sleep(1)

                    # Set the MSA to get the signal of interest
                    freq_string = "%.4f MHZ" % (freq*1e-6)
                    span_string = "%.4f MHZ" % np.minimum(np.maximum((2*freq*1e-6), 0.5), 1)
                    self.msa.set_freq_axis(freq_string, span_string, None, None)
                    time.sleep(2)

                    # Get peak information
                    f_peak, amp_val = self.msa.get_peak_info()
                    peak_freqs.append(f_peak)
                    peak_amps.append(amp_val)
                    print('Peak at %.4f MHz with strength %.4f dB' % (f_peak*1e-6, amp_val))
                    print('Got peak data')

                    # Get the spectrum and save it
                    time_tuple = time.localtime()

                    if filename is not None:
                        file_name = "%s-freq=%.4fMHz-Vgs_amp=%.3fV-Vgs_offs=%.3fV--%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                                                        freq*1e-6,
                                                                                                        amp,
                                                                                                        offset,
                                                                                                        time_tuple[0],
                                                                                                        time_tuple[1],
                                                                                                        time_tuple[2],
                                                                                                        time_tuple[3],
                                                                                                        time_tuple[4],
                                                                                                        time_tuple[5])
                    else:
                        file_name = None

                    self.msa.read_data(file_name)

                    print('Got trace for offset %.4f mV...' % (offset * 1e3))
                    print('-----------------------------')

                if filename is not None:
                    summary_filename = "%s-peaks_vs_freq_summary-Vgs_amp=%.3fV-Vgs_offs=%.3fV--%d#%d#%d_%d#%d#%d.csv" % (filename,
                                                                                                                    amp,
                                                                                                                    offset,
                                                                                                                    time_tuple[0],
                                                                                                                    time_tuple[1],
                                                                                                                    time_tuple[2],
                                                                                                                    time_tuple[3],
                                                                                                                    time_tuple[4],
                                                                                                                    time_tuple[5])
                    # Save the peak vs frequency data
                    with open(summary_filename, 'w+') as csvfile:
                        writer = csv.writer(csvfile)
                        writer.writerow(freq_list)
                        writer.writerow(peak_freqs)
                        writer.writerow(peak_amps)

        self.data = [peak_freqs, peak_amps]

        return [peak_freqs, peak_amps]

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionnary, in order for
        a measurement to be performed
        """
        return ["voltages", "amplitudes", "freqs"]

    def plot_data(self, canvas_handle, data=None):
        
        if data is None:
            if self.data is not None:
                data = self.data
            else:
                raise ValueError('plot_data was called before performing the experiment or providing data')
              
        peak_freqs = data[0]
        peak_amps = data[1]

        plot_graph(x_data=peak_freqs, y_data=peak_amps, canvas_handle=canvas_handle, xlabel='Peak Frequency (Hz)', ylabel='Peak amplitude (dBm)', title='AWG+MSA', legend=None)


if __name__ == '__main__':

    # INSTRUMENTS
    msa = HP70900A()
    awg = Agilent81180A()

    msa.initialize()
    awg.initialize()

    # EXPERIMENT PARAMETERS
    vgs_amp = [0.15]

    vgs_offset = [-0.07, -0.02]

    start_freq = 100e3
    end_freq = 100e6
    num_freq = 3
    log_sweep = True  # If True, it does a logarithmic sweep
    if log_sweep:
        freq_list = np.logspace(np.log10(start_freq), np.log10(end_freq), num_freq)
    else:
        freq_list = np.linspace(start_freq, end_freq, num_freq)

    base_file_name = './data/trial'

    # SET UP THE EXPERIMENT
    instr_list = [msa, awg]
    exp = BW_AWG_and_MSA(instr_list)
    params = {"voltages": vgs_offset, "amplitudes": vgs_amp, "freqs": freq_list}

    # RUN IT
    exp.perform_experiment(params, filename=base_file_name)

    # CLOSE INSTRUMENTS
    msa.close()
    awg.close()