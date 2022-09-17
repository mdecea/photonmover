from photonmover.Interfaces.Instrument import Instrument
from photonmover.instruments.DAQ.RedPitaya import RedPitaya as scpi
import socket
import sys

RED_PITAYA_BUFFER_SIZE = 16384 # buffer size in RedPitaya

class RedPitayaChopper(Instrument):

    def __init__(self, hostname='rp-f08473.local', outp_channel=1):
        super().__init__()
        self.hostname = hostname
        self.ipc_s = None
        self.rpc_s = None
        self.outp_channel = outp_channel

    def initialize(self):
        # Get IP and connect to scpi server
        self.ipc_s={}
        self.rpc_s={}

        try:
            self.ipc_s.update({self.hostname : socket.gethostbyname(self.hostname)})        
            self.rpc_s.update({self.hostname : scpi.scpi(self.ipc_s[self.hostname])})
        except:
            print('{} is unavailable: {}'.format(self.hostname, sys.exc_info()))
        else:
            print('Chopper RedPitaya at {} has IP {} is connected'.format(self.hostname, self.ipc_s[self.hostname]))

    
    def close(self):
        try:
            # Turn off MEMS chopper
            self.rpc_s[self.hostname].tx_txt('OUTPUT1:STATE OFF')
            print('{} with IP {} successfully disconnected'.format(self.hostname, self.ipc_s[self.hostname]))
        except:
            print('Could not close redpitayas : {}'.format( sys.exc_info())) # hostname, sys.exc_info()))

    def configure_modulation(self, shape, shape_params):
        """
        Configures the modulation of the chopper.
        :param shape: shape of the modulation. Supported: 'SQUARE', 'ARBITRARY'
        :param shape_params: Necessary parameters for the specified shape, as a dictionnary
            For square: freq, Vpp, Voffset
            For arbitrary: burst_mode (continuous or burst), code, cyc_in_burst, reps, code_freq, Vpp, Voffset [check below for definition]
        """

        if shape == 'SQUARE':
            print('Configuring square signal for chopper') 

            freq = shape_params["freq"] 
            Vpp = shape_params["Vpp"] 
            Voffset = shape_params["Voffset"] 

            self.rpc_s[self.hostname].tx_txt('GEN:RST')
            self.rpc_s[self.hostname].tx_txt( 'SOUR%d:FUNC %s' % (self.outp_channel, shape.upper()) )
            self.rpc_s[self.hostname].tx_txt( 'SOUR%d:FREQ:FIX %.2f' % (self.outp_channel, freq) )
            self.rpc_s[self.hostname].tx_txt( 'SOUR%d:VOLT %.2f' % (self.outp_channel, Vpp) )
            self.rpc_s[self.hostname].tx_txt( 'SOUR%d:VOLT:OFFS %.2f' % (self.outp_channel, Voffset) )
        
        if shape == 'ARBITRARY':

            print('Configuring arbitrary modulation for chopper')

            # ---- GATHER DATA ------
            burst_mode = shape_params['burst_mode']
            code = shape_params["code"]  # The value of each bit as a fraction of Vpp (i.e, 0.5 means that the bit is Voffset + 0.5*Vpp)
            code_freq = shape_params["code_freq"] # 1/code_freq is the time for each code
            Vpp = shape_params["Vpp"] 
            Voffset = shape_params["Voffset"] 

            # Only relevant in BURST mode
            cyc_in_burst = shape_params["cyc_in_burst"]  # Number of periods in a burst
            reps = shape_params["cyc_in_burst"]  # Number of burst repetitions 
            
            # ----- Calculations
            sec_per_bit = 1/code_freq
            # adjust carrier frequency according to length of code
            freq = code_freq/len(code)
            mult = RED_PITAYA_BUFFER_SIZE // len(code)

            # generate data to load RedPitaya by expanding each code to mult length
            code_buff = []
            for v in code:
                code_buff = code_buff + [v]*mult

            # ---- COMMUNICATE TO RED PITAYA ---
            self.rpc_s[self.hostname].tx_txt('GEN:RST')
            self.rpc_s[self.hostname].tx_txt('SOUR%d:FUNC %s' % ( self.outp_channel, shape.upper()) )
            self.rpc_s[self.hostname].tx_txt('SOUR%d:BURS:STAT %s' % (self.outp_channel,  burst_mode.upper()) )
            self.rpc_s[self.hostname].tx_txt('SOUR%d:TRIG:IMM' % self.outp_channel)
                
            if burst_mode == 'CONTINUOUS':
                self.rpc_s[self.hostname].tx_txt('SOUR%d:FREQ:FIX ' % (self.outp_channel, freq) )
            elif burst_mode == 'BURST':
                self.rpc_s[self.hostname].tx_txt('SOUR%d:BURS:NCYC %d' % (self.outp_channel, cyc_in_burst) )
                self.rpc_s[self.hostname].tx_txt('SOUR%d:BURS:NOR %d' % (self.outp_channel, reps) )
                
                usec_per_bit = int(sec_per_bit*1.0e6)
                self.rpc_s[self.hostname].tx_txt('SOUR%d:BURS:INT:PER %d' % (self.outp_channel, usec_per_bit))        
                
                
            self.rpc_s[self.hostname].tx_txt('SOUR%d:VOLT %.2f' % (self.outp_channel, Vpp))
            self.rpc_s[self.hostname].tx_txt('SOUR%d:VOLT:OFFS %.2f' % (self.outp_channel, Voffset))

            code_str = ','.join([str(d) for d in code_buff])
            self.rpc_s[self.hostname].tx_txt('SOUR%d:TRAC:DATA:DATA %s' % (self.outp_channel, code_str))

        else:

            raise ValueError('The indicated shape for the chopper is not suppoerted/recognized')


    def turn_on(self):
        self.rpc_s[self.hostname].tx_txt('OUTPUT{}:STATE ON'.format(self.outp_channel))

    def turn_off(self):
        self.rpc_s[self.hostname].tx_txt('OUTPUT{}:STATE OFF'.format(self.outp_channel))
    
