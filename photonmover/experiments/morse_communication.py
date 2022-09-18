# This is a funny experiment, were we try to get a CMOS LED to
# talk to a camera in Morse code (very slowly!)
#
# Essentially, we only need a source meter. We will turn the source
# meter on and off according to the word or sentence provided.

import winsound
import time
from photonmover.instruments.Source_meters.KeysightB2902A import KeysightB2902A
from photonmover.Interfaces.SourceMeter import SourceMeter
from photonmover.Interfaces.Experiment import Experiment
CODE = {  # Letters
    'A': '.-', 'B': '-...', 'C': '-.-.',
    'D': '-..', 'E': '.', 'F': '..-.',
    'G': '--.', 'H': '....', 'I': '..',
    'J': '.---', 'K': '-.-', 'L': '.-..',
    'M': '--', 'N': '-.', 'O': '---',
    'P': '.--.', 'Q': '--.-', 'R': '.-.',
    'S': '...', 'T': '-', 'U': '..-',
    'V': '...-', 'W': '.--', 'X': '-..-',
    'Y': '-.--', 'Z': '--..',

    # Numbers
    '0': '-----', '1': '.----', '2': '..---',
    '3': '...--', '4': '....-', '5': '.....',
    '6': '-....', '7': '--...', '8': '---..',
    '9': '----.',

    # Spacings
    ',': '...',  # The comma will be used as a separator between letters
    ' ': '.......',  # Space is separator between words
    '.': '..........',
}


# Interfaces/instruments necessary for the experiment
# - You use an INterface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model

# General imports


class MorseComm(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT:
        WE ASSUME THAT THE INSTRUMENTS HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # Instruments. We need a source meter, which we will turn on and off
        # accordingly.
        self.smu = None

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
            if isinstance(instr, SourceMeter):
                if self.smu is None:
                    self.smu = instr

        if (self.smu is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return " Communication through Morse code "

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Morse code comm"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dict of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        """
        params keys:
            "v_bias" --> Bias voltage for turning the LED on
            "sentence" --> Word/sentence we want to communicate
            "dot_T" --> Duration (in seconds) of a dot
        """

        params = self.check_all_params(params)

        v_bias = params["v_bias"]
        sentence = params["sentence"]
        dot_T = params["dot_T"]

        prev_bias = self.smu.measure_voltage()

        # Turn off the smu and set it to the desired bias voltage
        self.smu.turn_off()
        self.smu.set_voltage(v_bias)

        treated_sentence = self.process_sentence(sentence)

        # Iterate over every character of the (treated) sentence
        for ch in treated_sentence:
            # Transmit the character
            self.transmit_char(ch, dot_T)

        # Beep when done
        winsound.Beep(2000, 1000)

        # Return to previous state
        self.smu.set_voltage(prev_bias)
        self.smu.turn_off()

        return None

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params
        dictionary, in order for
        a measurement to be performed
        """
        return ["v_bias", "sentence", "dot_T"]

    def process_sentence(self, sentence):
        """
        Converts from human readable to morse code
        """

        # Capitalize
        sentence = sentence.upper()

        # Essentially, we need to add commas between successive letters to have
        # a separator
        treated_sentence = ""

        for i, ch in enumerate(sentence):

            treated_sentence = treated_sentence + ch

            if (i + 1) < len(sentence):
                # Add a separator between letters (a ',') if the next character
                # is a letter or a number
                if sentence[i + 1].isalpha() or sentence[i + 1].isdigit():
                    treated_sentence = treated_sentence + ","

        print('We will send: %s' % treated_sentence)
        return treated_sentence

    def transmit_char(self, ch, dot_T):

        morse_seq = CODE[ch]

        for s in morse_seq:
            if s == '.':
                self.smu.turn_on()
                time.sleep(dot_T)
                self.smu.turn_off()
            if s == '-':
                self.smu.turn_on()
                time.sleep(3 * dot_T)
                self.smu.turn_off()

            # Need to wait one time unit between elements of the same character
            time.sleep(dot_T)

    def plot_data(self, canvas_handle, data=None):
        raise Exception('No data to plot for the Morse comm experiment')


if __name__ == '__main__':

    # INSTRUMENTS
    smu = KeysightB2902A()
    smu.initialize()

    # EXPERIMENT PARAMETERS
    v_bias = 14
    sentence = "POE"
    dot_T = 1

    # SET UP THE EXPERIMENT
    instr_list = [smu]
    exp = MorseComm(instr_list)
    params = {"v_bias": v_bias, "sentence": sentence, "dot_T": dot_T}

    # RUN IT
    exp.perform_experiment(params)

    # CLOSE INSTRUMENTS
    smu.close()
