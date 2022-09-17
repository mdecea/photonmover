from photonmover.Interfaces.Instrument import Instrument

GPIB_ADDRESS = "GPIB1::18::INSTR"


class PPG3200(Instrument):
    """ 
    Class for controlling the Picosecond Pulse Labs 32 Gbps pattern generator
    """

    def __init__(self):
        super().__init__()
        self.gpib = None

    def initialize(self):

        print('Opening connnection to PPG pattern generator')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDRESS, timeout=5000)
        except:
            raise ValueError('Cannot connect to the PPG pattern generator')

    def close(self):
        print('Disconnecting HP OSA')
        self.gpib.close()

    def reset(self):
        self.gpib.write("*RST")

    def set_data_pattern_length(self, channel, length):
        """
        Programs the Pattern Length. This value is only relevant if the pattern type is DATA.
        In a two or four channel unit, the maximum pattern length per channel is 2,097,152.
        """

        if channel not in [1, 2]:
            print('The specifiec channel is not correct. Doing nothing.')
            return
        
        if length < 0 or length > 2097152:
            print('The specified kength is not supported. Doing nothing')

        self.gpib.write("DIG%d:PATT:LENG %d" % (channel, length))

    def set_pattern_type(self, channel, tp):
        """
        Programs the Pattern Type (PRBS or DATA)
        """
        
        if channel not in [1, 2]:
            print('The specified channel is not correct. Doing nothing.')
            return

        if tp not in ['PRBS', 'DATA']:
            print('The specified pattern type is not supported. Doing nothing.')
            return
        
        self.gpib.write("DIG%d:PATT:TYPE %s" % (channel, tp))

    def set_PRBS_pattern_length(self, channel, N):
        """
        Programs the Pattern PRBS Length. PRBS Length is specified as 2^N-1, where N is the
        specified value. This value is only relevant if the pattern type is PRBS.
        """

        if channel not in [1, 2]:
            print('The specified channel is not correct. Doing nothing.')
            return

        if N not in [7, 9, 11, 15, 23, 31]:
            print('The specified PRBS length is not supported. Doing nothing.')
            return

    def set_trigger_out(self, trigger_type, clk_divider=None):
        """
        Programs the trigger out event. trogger_type is either "PER" or "BITS"
        - PERiodic means the trigger will output a signal whose frequency is the clock rate divided
        by N, where N is the clk_divider setting.
        - BITStream means trigger pulses will be aligned with the pattern length.

        clk_divider is only relevant in the case of trigger_type = "PER". IN this case, 
        the trigger will output a signal whose frequency is the clock rate divided by clk_divider
        """

        if trigger_type not in ['PER', 'BITS']:
            print('The specified trigger out type is not supported. Doing nothing.')
            return
        
        self.gpib.write("OUTP0:SOUR %s" % trigger_type)

        if trigger_type == 'PER' and clk_divider is not None:
            self.gpib.write("OUTP0:DIV %d" % clk_divider)

    def turn_on(self, channel):
        """
        Turns on the specified channel
        """

        if channel not in [1, 2]:
            print('The specified channel is not correct. Doing nothing.')
            return

        self.gpib.write(":OUTP%d ON" % channel)

    def turn_off(self, channel):
        """
        Turns on the specified channel
        """

        if channel not in [1, 2]:
            print('The specified channel is not correct. Doing nothing.')
            return

        self.gpib.write(":OUTP%d OFF" % channel)

    def cnfg_output_clk_divider(self, divider):
        """
        Programs the clock output divider. The input to this divider is internal clock, and the output
        from the divider goes to the clock output.
        """

        if divider not in [1, 2, 4, 8, 16]:
            print('The specified output clock divider is not correct. Doing nothing.')
            return

        self.gpib.write(":OUTP:CLOC:DIV %d" % divider)

    def set_data_rate(self, data_rate):
        """
        Sets the data rate of the signal (in Hz)
        """

        if data_rate < 32e6 or data_rate > 32e9:
            print('The specified data rate is not supported. Doing nothing.')
            return
        
        self.gpib.write(":FREQ %.2E" % data_rate)

    def set_pattern(self, channel, pattern):
        """
        Programs a data pattern to output.
        Pattern is a string where each charcter is a bit. Ex: "0110010101110000"
        """

        if channel not in [1, 2]:
            print('The specified channel is not correct. Doing nothing.')
            return

        pattern_length = len(pattern)

        self.gpib.write(":DIG%d:PATT:DATA 1,%d,#%s" % (channel, pattern_length, pattern))


if __name__ == '__main__':

    channel = 1
    ppg = PPG3200()
    ppg.initialize()

    # Let's try to generate a pulse of a given duration, with a given repetition rate
    pulse_duration = 100e-9
    rep_rate = 1e6

    # Set patern generator to output user data
    ppg.set_pattern_type(channel, "DATA")
    # Synchronize trigger with pattern
    ppg.set_trigger_out("BITS")

    # Calculations
    rep_time = 1/rep_rate

    if pulse_duration < 1/32e9:
        print("We can't do this! The pulse length is too short.")
        ppg.close()
        return
    
    if pulse_duration > 1/1e9:

        # We need to use multiple '1' bits to make it work
        f = 1e9
        ppg.set_data_rate(f)

        # Get the length of the total bit stream to have the specified rep rate, and set it
        pat_length = round(rep_time/(1/f)))
        real_rep_rate = 1/(pat_length*(1/f)))
        print("The specified rep rate was %.2f MHz, the real rep rate is  %.2f MHz." % (rep_rate*1e-6, real_rep_rate*1e-6))
        ppg.set_data_pattern_length(channel, pat_length)

        # Get the number of '1' in the pattern to get the desired pulse duration
        num_ones = round(pulse_duration/1e-9)
        real_pulse_duration = num_ones*1e-9
        print("The specified pulse duration was %.2f ns, the real duration is %.2f ns." % (pulse_duration*1e9, real_pulse_duration*1e9))
        # Set the pattern
        pattern = "0"*5 + "1"*num_ones + "0"*5
        ppg.set_pattern(channel, pattern)

    else:

        # Get the data rate to specify, and program it
        f = 1/pulse_duration
        f = round(f, 2) # Round to 2 decimals
        real_pulse_duration = 1/f
        print("The specified pulse duration was %.2f ns, the real duration is %.2f ns." % (pulse_duration*1e9, real_pulse_duration*1e9))
        ppg.set_data_rate(f)

        # Get the length of the total bit stream to have the specified rep rate, and set it
        pat_length = round(rep_time/real_pulse_duration)
        real_rep_rate = 1/(pat_length*real_pulse_duration)
        print("The specified rep rate was %.2f MHz, the real rep rate is  %.2f MHz." % (rep_rate*1e-6, real_rep_rate*1e-6))
        ppg.set_data_pattern_length(channel, pat_length)

        # Finally, just set the bit pattern
        # We just need a bunch of 0 followed by a 1 and then a bunch of other 0
        pattern = "0"*5 + "1" + "0"*5
        ppg.set_pattern(channel, pattern)

    ppg.turn_on(channel)
    ppg.close()