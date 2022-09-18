from photonmover.Interfaces.Instrument import Instrument
import pyvisa as visa

GPIB_ADDRESS = "GPIB1::16::INSTR"


class HP70843B(Instrument):
    """
    Class for controlling the HP70843B pattern generator (as a voltage pulse generator)
    Clock reference for bit rate is set by HP70340A signal generator - independent code
        outputs a maximum frequency of 10 GHz -> 100 ps minimum pulse width
    """

    def __init__(self):
        super().__init__()
        self.gpib = None

    def initialize(self):
        print('Opening connnection to HP70843B pattern generator')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDRESS, timeout=5000)
        except BaseException:
            raise ValueError(
                'Cannot connect to the HP70843B pattern generator')

    def close(self):
        print('Disconnecting HP70843B')
        self.gpib.close()

    def reset(self):
        self.gpib.write("*RST")

    def turn_on(self):
        """
        Turns on data output
        """
        self.gpib.write("OUTP1 ON")

    def turn_off(self):
        """
        Turns off data output
        """
        self.gpib.write("OUTP1 OFF")

    def set_amplitude(self, amplitude):
        """
        :param amplitude: Amplitude [V] of voltage pulse
        """
        self.gpib.write("SOUR1:VOLT:LEV:IMM:AMPL %0.4f" % amplitude)

    def set_hi_level(self, hilevel):
        """
        :param hilevel: DC High output level [V]
        """
        self.gpib.write("SOUR1:VOLT:LEV:IMM:HIGH %0.4f" % hilevel)

    def set_polarity(self, polarity):
        """
        :param polarity: polarity of voltage pulse: 'positive' or 'negative'
        Note that "INV" gives a positive pulse, and "NORM" gives a negative pulse!
        """
        if polarity is 'positive':
            self.gpib.write("OUTP1:POL INV")
        elif polarity is 'negative':
            self.gpib.write("OUTP1:POL NORM")
        else:
            print('Invalid polarity! Specify positive or negative')

    def set_pattern_length(self, pattern_store, length):
        """
        Sets the Pattern Length (number of bits)
        The maximum channel length in 1-bit steps is 32 kbits (rep rate of 312.5 kHz for 100 ps pulses)
                                      2-bit steps is 32-64 kbits
                                      3_bit steps is 64-128 kbits
                                    ...etc (see manual for more)
        Maximum pattern stores of pattern number 1-4 is 8192 bits
        Maximum pattern stores of pattern number 0 is 4194304 bits

        """
        if length < 0 or length > 32000:
            print('The specified length is not supported for 1-bit steps. Doing nothing')

        # set user pattern to Straight (directly outputs input pattern)
        self.gpib.write("SOUR1:PATT:UPAT%d:USE STR" % pattern_store)

        # set pattern length
        self.gpib.write("SOUR1:PATT:UPAT%d:LENG %d" % (pattern_store, length))

    def set_pattern(self, pattern_store, pattern):
        """
        :param pattern: desired input bit pattern (string). Function converts to the format expected by the PPG
        Data is sent as bytes with a header specifying the number of bytes sent.
        Only the last bit in each byte is stored in the pattern
        """

        if pattern_store not in [0, 1, 2, 3, 4]:
            print('The specified pattern number is out of range. Doing nothing.')

        pattern_length = len(pattern)

        # Construct formatted data block for PPG
        data_header = '#' + str(len(str(pattern_length))) + str(pattern_length)
        data = data_header

        for bit in pattern:
            if bit is '0':
                formatted_bit = '\x00'
            elif bit is '1':
                formatted_bit = '\x01'
            else:
                print('Invalid bit! Must be 0 or 1')
            data = data + formatted_bit

        data = data + '\n'
        self.gpib.write("PATT:FORM PACK,1")  # set to 1 bit/byte
        self.gpib.write("PATT:UPAT%d %d" % (pattern_store, pattern_length))
        self.gpib.write("PATT:UPAT%d:DATA %s" % (pattern_store, data))
        # query pattern in store
        #self.gpib.write("PATT:UPAT%d:DATA?" % pattern_store)

    def load_pattern_store(self, pattern_store):
        """
        load a pattern stored in memory
        :param pattern_number = 0: current pattern, 1-4: non-volatile RAM
        """

        if pattern_store not in [0, 1, 2, 3, 4]:
            print('The specified pattern number is out of range. Doing nothing.')

        self.gpib.write("SOUR1:PATT:SEL UPAT%d," % pattern_store)

    def configure_pulse(
            self,
            repetition_rate,
            pulse_width,
            amplitude,
            hilevel,
            polarity):
        """
        Configure a pulse with the specified parameters, assuming 10 GHz clock rate (100 ps increments)
        :param repetition_rate: [Hz]
        :param pulse_width: [s]
        :param amplitude: [V]
        :param hilevel: [V]
        :param polarity: positive or negative
        """

        # write to current pattern
        pattern_store = 0
        self.load_pattern_store(pattern_store)

        # Pulse width step size
        pulse_step = 100e-12  # [s]

        # Convert repetition rate to pattern length
        pattern_length = round(
            1 / (repetition_rate * pulse_step))  # Number of bits

        on_bits = round(pulse_width / pulse_step)
        off_bits = pattern_length - on_bits

        on_bit_pattern = ''

        for i in range(on_bits):
            on_bit_pattern = on_bit_pattern + '1'

        bit_pattern = on_bit_pattern

        for i in range(off_bits):
            bit_pattern = bit_pattern + '0'

        self.set_pattern(pattern_store, bit_pattern)
        self.set_polarity(polarity)
        self.set_amplitude(amplitude)
        self.set_hi_level(hilevel)


if __name__ == '__main__':
    ppg = HP70843B()
    ppg.initialize()

    repetition_rate = 35e6  # 10e6 #0.110e9 #[Hz]
    pulse_width = 100e-12  # 0.5*(1/repetition_rate)#5e-9 #100e-12 #[s]
    amplitude = 0.9  # [V]
    hilevel = amplitude
    polarity = 'positive'

    ppg.configure_pulse(
        repetition_rate,
        pulse_width,
        amplitude,
        hilevel,
        polarity)
    ppg.turn_on()
    ppg.close()
