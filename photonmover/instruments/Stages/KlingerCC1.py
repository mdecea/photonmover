import sys
sys.path.insert(0, '../..')
from Interfaces.Instrument import Instrument
from Interfaces.Stage import SingleAxisStage
import pyvisa as visa
import time

# Taken from Jaehwan
GPIB_ADDR = "GPIB1::2::INSTR"  # GPIB adress


# For the stage connected: 16 mm travel
# 0 is set up at mid travel right now


class KlingerCC1(Instrument, SingleAxisStage):
    """ 
    Class for controlling Klinger Scientific CC1.1
    which is IEEE 488.1 compliant (488.2 is back-compliant but this instrument does not respond to *IDN? query)
    """
    
    def __init__(self, mode='high_speed', gpib_addr=GPIB_ADDR):
        super().__init__()
        self.gpib_address = gpib_addr
        self.gpib = None
        self.mode = mode

    def initialize(self):

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(self.gpib_address, timeout=None, write_termination='\r')
        except:
            raise ValueError('Cannot connect to the Klinger motor controller')

        self.set_mode_params(self.mode)

    def set_mode_params(self, mode):
        """
        Sets the step rate parameters corresponding to different modes
        Supported modes as of now: 'high_speed', 'low_speed'
        """

        if mode == 'high_speed':
            # Optimized for holomicrography load
            self.set_steprate(R=180, S=200, F=1)

        elif mode == 'low_speed':
            self.set_steprate(R=50, S=1, F=20)

        else:
            print('Klinger mode not recognized. Doing nothing.')
            

    def close(self):
        print('Disconnecting Klinger motor controller')
        self.gpib.close()

    def go_steps(self, N, blocking=True):
        N = round(N)

        if N>0 and N<65536:
            self.gpib.write("N {}".format(N))
            time.sleep(0.1)
            self.gpib.write("+")
            time.sleep(0.1)
            self.gpib.write("G")
            time.sleep(0.1)

        elif N<0 and N>-65536:
            self.gpib.write("N {}".format(-N))
            time.sleep(0.1)
            self.gpib.write("-")
            time.sleep(0.1)
            self.gpib.write("G")
            time.sleep(0.1)
        else:
            print('Invalid steps for given N')

        if blocking:
            # To wait until the movement is done, write something that is irrelevant.
            # You can only write after the movement is complete
            self.gpib.write("+")

    def move(self, dist):
        # Dist is in mm
        self.go_nm(dist*1e6)

    def go_nm(self, nm=0):
        # 1 step is 100 nm
        self.go_steps(N=nm/100)

    def set_steprate(self, R, S, F):
        # Step rate R (1~255) - larger is faster
        if R>0 and R<256:
            self.gpib.write("R {}".format(R))
            time.sleep(0.1)
        else:
            print('Invalid step rate R')

        # Step rate acceleration parameter S(1~255) - larger is faster
        if S>0 and S<256:
            self.gpib.write("S {}".format(S))
            time.sleep(0.1)
        else:
            print('Invalid step rate acceleration parameter S')

        # Step rate factor parameter F(1~255) - smaller is faster
        if F>0 and F<256:
            self.gpib.write("F {}".format(F))
            time.sleep(0.1)
        else:
            print('Invalid step rate factor parameter F')

if __name__ == '__main__':
    stage = KlingerCC1()
    stage.initialize()
    #stage.go_nm(1000)
    #print('a')
    #time.sleep(1)
    stage.go_steps(2000)
    stage.close()