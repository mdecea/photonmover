from photonmover.Interfaces.Experiment import Experiment

# Interfaces/instruments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.MSA import MSA
from photonmover.Interfaces.WaveformGenerator import WaveformGenerator

# This is only necessary for the example
from photonmover.instruments.Microwave_spectrum_analyzers.HP70900A \
    import HP70900A
from photonmover.instruments.Arbitrary_waveform_generators.Agilent81180A \
     import Agilent81180A

# General imports
import time


class SFDR(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT:
        WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments
        self.awg = None
        self.msa = None

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
        return """ Performs an SFDR measurement by increasing the amplitude of
            two closely spaced sinusoid signals and observing
            intermodulation products with the MSA. """

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "SFDR"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dict of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        """
        Keys: biases --> List of bias voltages for the applied sinusoids.
                 Both sinusoids have the same offset.
              amps --> List of amplitudes for the applied sinusoids.
              f1 --> Frequency of the 1st sinusoid
              f2 --> Frequency of the 2nd sinusoid
              amp_comp --> The amplitude of the 2nd sinusoid is amp[i]
                + amp_comp. This is  added to account for slight
                mismatches between the output power of the two sinusoids.
        """

        params = self.check_all_params(params)

        biases = params["voltages"]
        amps = params["amplitudes"]
        f1 = params["f1"]
        f2 = params["f2"]
        amp_comp = params["amp_comp"]

        # We do an SFDR experiment for each specified bias
        for bias in biases:

            # Set appropriate bias
            self.awg.select_channel(1)
            self.awg.set_waveform('SIN', f1, amps[0], bias)
            self.awg.select_channel(2)
            self.awg.set_waveform('SIN', f2, amps[0] + amp_comp, bias)
            self.awg.turn_on()

            # Now sweep sinousoid power
            for Vpp in amps:

                self.awg.select_channel(1)
                self.awg.set_voltage(Vpp, None)
                self.awg.select_channel(2)
                self.awg.set_voltage(Vpp + amp_comp, None)

                print('Measuring %.4f mVpp' % (Vpp * 1e3))
                print('Set driving signal')
                # Wait 1 second
                time.sleep(1)

                # Get trace
                if filename is not None:
                    time_tuple = time.localtime()
                    file_name = "SFDR-%s-freq1=%.4fMHz-freq2=%.4fMHz-Vgs_pp=%.3fV-Vgs_offs=%.3fV--%d#%d#%d_%d#%d#%d.csv" % (
                        filename,
                        self.f1 * 1e-6,
                        self.f2 * 1e-6,
                        Vpp,
                        bias,
                        time_tuple[0],
                        time_tuple[1],
                        time_tuple[2],
                        time_tuple[3],
                        time_tuple[4],
                        time_tuple[5])
                else:
                    file_name = None

                self.msa.read_data(file_name)

                print('Got trace')
                print('-----------------------------')

        return None

    def default_params(self):
        return {"amp_comp": 0.0}

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params
        dictionnary, in order for
        a measurement to be performed
        """
        return ["voltages", "amplitudes", "f1", "f2", "amp_comp"]

    def plot_data(self, canvas_handle, data=None):
        raise Exception('No data to plot for SFDR experiment')


if __name__ == '__main__':

    # INSTRUMENTS
    msa = HP70900A()
    awg = Agilent81180A()

    msa.initialize()
    awg.initialize()

    # EXPERIMENT PARAMETERS
    vgs_offset = [0]
    Vpp_list = [
        0.05,
        0.06,
        0.07,
        0.08,
        0.09,
        0.1,
        0.11,
        0.12,
        0.13,
        0.14,
        0.15,
        0.16,
        0.17,
        0.18,
        0.19,
        0.2,
        0.25,
        0.3,
        0.35,
        0.4,
        0.45,
        0.5]
    channel_2_Vpp_compensate = 0.02  # channel 2 needs a slightly larger power
    freq1 = 500e3
    freq2 = 510e3

    base_file_name = 'SFDR_no_DUT_awg_good'

    # SET UP THE EXPERIMENT
    instr_list = [msa, awg]
    exp = SFDR(instr_list)
    params = {
        "voltages": vgs_offset,
        "amplitudes": Vpp_list,
        "f1": freq1,
        "f2": freq2,
        "amp_comp": channel_2_Vpp_compensate}

    # RUN IT
    exp.perform_experiment(params, filename=base_file_name)

    # CLOSE INSTRUMENTS
    msa.close()
    awg.close()
