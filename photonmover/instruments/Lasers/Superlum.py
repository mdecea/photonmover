import sys
sys.path.insert(0,'../..')
from Interfaces.Laser import TunableLaser
from Interfaces.Instrument import Instrument

import re
import serial
import io
import time

class Superlum(Instrument, TunableLaser):

    """
    Wrapper class for controlling Superlum BS-840-1-OEM tunable laser
    based on https://github.com/rwalle/py_blms_ctrl
    """

    def __init__(self, com_address='COM1', timeout=1.0, verbose=True, shutdown=True):
        super().__init__()
        # Serial settings
        self.baud = 57600
        self.startbit = 1
        self.stopbit = 1
        self.parity = None
        self.flowcontrol = None

        self.timeout = timeout
        self.port = com_address

        self.verbose = verbose

        self.shutdown = shutdown

        # laser status variables
        self.laser = None
        self.laser_io = None

        self.laser_on = False
        self.aotf_tec = False
        self.aotf_tec_stable = False
        self.sld_tec = False
        self.sld_tec_stable = False
        self.sld = False
        self.laser_rdy = False

        # laser parameters
        self.bwl_wavelength = 740.0
        self.min_wavelength = 770.0
        self.max_wavelength = 825.0

    def initialize(self):

        print('Connecting to Superlum laser')
        self.laser = serial.Serial(self.port, self.baud, timeout=self.timeout)
        self.laser_io = io.TextIOWrapper(io.BufferedRWPair(self.laser, self.laser))

    def init_function(self):

        self.set_mode(mode='T') # single tone mode
        self.set_mode(mode='W') # On mode
        
        timeout = 120 # sec
        flags = [True]*4

        for i in range(timeout):
            self.get_status()
            if self.aotf_tec and flags[0]:
                print('AOTF TEC ON...')
                flags[0] = False            
            if self.aotf_tec_stable and flags[1]:
                print('AOTF TEC STABLE!')
                flags[1] = False         
            if self.sld_tec and flags[2]:            
                print('SLD TEC ON...')
                flags[2] = False            
            if self.sld_tec_stable and flags[3]:
                print('SLD TEC STABLE!')            
                flags[3] = False
            
            
            if self.laser_rdy:
                print('Superlum ready to use')
                break 
                
            time.sleep(1.0)
                
        self.verbose = True
        self.get_status()
        self.verbose = False

    def read_response(self):
        if self.laser_io == None:
            raise NameError('Superlum: Use connect() to connect to the device before the query.')

        response = self.laser_io.readline()
        return response

    def analyze_response(self, cmd, resp):

        # return a tuple (status_code, status_bool, status_text)
        # depending on sent command and received response
        if self.verbose:
            print('Superlum sent message: '+cmd)
            print('Superlum response: '+resp)

        if resp is None:
            print('No response from Superlum laser')
        elif resp[:2]=='!E':
            print('Superlum: common error message')
        elif resp[:2]=='!M':
            print('Superlum: wrong mode set message')
        else:
            # Set/get status command
            if cmd[0] == 'M':
                if self.verbose:
                    print('Superlum: 1.2 Set device operation mode. Read device status.')

                f = re.match('^M\S{5}\n$', resp)
                if f is None:
                    print('Could not parse response {}'.format(resp))
                else:
                    self.parse_state(status_string=resp[1:6])

            elif cmd[:3] == 'P21': # set wavelength command
                if self.verbose:
                    print('superlum: 1.3 Read / Set device parameter set wavelength')

                if len(cmd)>4: # write operation
                    if cmd == resp:
                        if self.verbose:
                            print('set wavelength successful')
                        return 1
                    else:
                        return 0
                else: # read operation
                    wl = self.bwl_wavelength + float(int(resp[3:-1], 16))/100.0
                    print('current wavelength: {}'.format(wl))
                    return wl

            elif cmd[:3] == 'P04': # Read base wavelength command
                if self.verbose:
                    print('superlum: 1.3 Read / Set device parameter get base wavelength')

                wl = float(int(resp[3:-1], 16))
                if self.verbose:
                    print('base wavelength is: {}'.format(wl))
                self.bwl_wavelength = wl

                return wl

            elif cmd[0] == 'X':
                if self.verbose:
                    print('superlum: 1.4 Switch Output ON/OFF. Start / Stop Sweep.')

                f = re.match('^X\S{5}\n$', resp)
                if f is None:
                    print('Could not parse response {}'.format(resp))
                else:
                    self.parse_state(status_string=resp[1:6])
                    return 1
            else:
                print('{} parsing not yet implemented'.format(cmd))

        return 0

    def parse_state(self, status_string):
        """
        Parses the status string and updates the relevant internal variables
        """
        if self.verbose:
            print('Status string {}={}'.format(status_string, bin(int(status_string, 16))))

        DSB = int(status_string[:2], 16)
        mode = int(DSB & 0b00000111)
        ctrl = int((DSB & 0b00011000) >>3)
        func = int((DSB & 0b01100000) >>5)

        if mode < 2:
            status = 'shutdown'
            self.laser_rdy = False
        if mode ==3:
            status = 'warm up'
            self.laser_rdy = False
        elif mode == 4 or mode==5:
            status = 'function'
            self.laser_rdy = True
        elif mode>5:
            status = 'error'
            self.laser_rdy = False
        if self.verbose:
            print('superlum status: '+ status)

        status = 'local'
        if ctrl <2:
            status = 'remote'
        elif ctrl<4:
            status = 'USB'
        if self.verbose:
            print('superlum control mode: '+ status)

        if func==0:
            status = 'single tone'
        elif func <3:
            status = 'single sweep'
        elif ctrl<4:
            status = 'continuous sweep'
        if self.verbose:
            print('superlum sweep mode: '+ status)

        SS = int(status_string[2], 16)

        if SS==0:
            status='stopped'
        else:
            status = 'started'
        if self.verbose:
            print('superlum sweep '+status)

        MSB = int(status_string[3:5], 16)
        if MSB & 0b00000001:
            if self.verbose:
                print('AOTF TEC ON')
            self.aotf_tec = True
        else:
            if self.verbose:
                print('AOTF TEC OFF')
            self.aotf_tec = False

        if MSB & 0b00000010:
            if self.verbose:
                print('AOTF TEC STABLE')
            self.aotf_tec_stable=True
        else:
            if self.verbose:
                print('AOTF TEC NOT STABLE')
            self.aotf_tec_stable=False
        if MSB & 0b00000100:
            if self.verbose:
                print('AOTF TEC thermistor error')

        if MSB & 0b00010000:
            if self.verbose:
                print('SLD TEC ON')
            self.sld_tec = True
        else:
            if self.verbose:
                print('SLD TEC OFF')
            self.sld_tec = False

        if MSB & 0b00010000:
            if self.verbose:
                print('SLD TEC STABLE')
            self.sld_tec_stable=True
        else:
            if self.verbose:
                print('SLD TEC NOT STABLE')
            self.sld_tec_stable=False

        if MSB & 0b00100000:
            if self.verbose:
                print('SLD TEC thermistor error')

        if MSB & 0b01000000:
            # if self.verbose:
            print('SLD laser output ON')
            self.laser_on=True
        else:
            # if self.verbose:
            print('SLD laser output OFF')
            self.laser_on=False

        if MSB & 0b10000000:
            if self.verbose:
                print('SLD current limit')

    def get_status(self):
        if self.laser_io == None:
            raise NameError('Use connect() to connect to the device before the query.')

        sendmsg = 'M\n'
        self.laser_io.write(sendmsg)
        self.laser_io.flush()

        return self.analyze_response(cmd = sendmsg, resp=self.read_response())

    def set_mode(self, mode):
        if self.laser_io is None:
            raise NameError('Superlum: Use connect() to connect to the device before the query.')

        if re.match('[BECTZYOW]', mode) is None or len(mode)>1:
            print('Superlum -- invalid modes, valid modes:')
            print('B: Set BUTTON CTRL mode (LOCAL)')
            print('E: Set EXTERNAL CTRL mode (REMOTE PORT)')
            print('C: Set USB CTRL mode (USB PORT)')
            print('T: Set SINGLE TONE mode')
            print('Z: Set CONTINUOUS SWEEP MODE')
            print('Y: Set SINGLE SWEEP MODE')
            print('O: Set OFF mode (SHUTDOWN)')
            print('W: Set ON mode (WAKE UP)')
            return 0

        sendmsg = 'M'+mode+'\n'
        self.laser_io.write(sendmsg)
        self.laser_io.flush()
        return self.analyze_response(cmd = sendmsg, resp=self.read_response())

    def get_wavelength(self):
        if self.laser_io == None:
            raise NameError('Superlum: Use connect() to connect to the device before the query.')
        sendmsg = 'P21\n'
        self.laser_io.write(sendmsg)
        self.laser_io.flush()
        return self.analyze_response(cmd = sendmsg, resp=self.read_response())

    def set_wavelength(self, wavelength):
        if self.laser_io is None:
            raise NameError('Superlum: Use connect() to connect to the device before the query.')

        if wavelength < self.min_wavelength:
            print('Superlum: wavelength cannot be smaller than base wavelength {}nm'.format(self.min_wavelength))
            return 0
        elif wavelength > self.max_wavelength:
            print('Superlum: wavelength cannot be larger than {}nm'.format(self.max_wavelength))
            return 0

        wlhex = '%04X' % int(round((wavelength - self.bwl_wavelength)*100.0))
        sendmsg = 'P21'+wlhex+'\n'
        self.laser_io.write(sendmsg)
        self.laser_io.flush()
        return self.analyze_response(cmd = sendmsg, resp=self.read_response())

    def get_bwl(self):
        if self.laser_io is None:
            raise NameError('Superlum: Use connect() to connect to the device before the query.')
        sendmsg = 'P04\n'
        self.laser_io.write(sendmsg)
        self.laser_io.flush()
        return self.analyze_response(cmd = sendmsg, resp=self.read_response())

    def turn_off(self):

        if self.laser_io is None:
            raise NameError('Superlum: Use connect() to connect to the device before the query.')

        # check laser status
        self.get_status()

        if not self.laser_on:
            print('Superlum already off. Doing nothing.')
            return
        
        sendmsg = 'X\n'
        self.laser_io.write(sendmsg)
        self.laser_io.flush()
        print('Turning off Superlum laser.')
        return self.analyze_response(cmd = sendmsg, resp=self.read_response())

    def turn_on(self):

        if self.laser_io is None:
            raise NameError('Superlum: Use connect() to connect to the device before the query.')
        
        # check laser status
        self.get_status()
        
        if self.laser_on:
            print('Superlum already on. Doing nothing.')
            return

        sendmsg = 'X\n'
        self.laser_io.write(sendmsg)
        self.laser_io.flush()
        print('Turning on Superlum laser.')
        return self.analyze_response(cmd = sendmsg, resp=self.read_response())

    def set_shutdown(self, shutdown):
        """
        Sets the shutdown mode when closing the connection.
        If True, it does shutdown. Else, it does not.
        """
        self.shutdown = shutdown

    def set_power(self, power):
        print('The power cannot be set on the superlum!')

    def get_state(self):
        """
        Returns a list wiht the following elements:
        1. The current wavelength
        2. The current power 
        3. If the laser is on or off.
        """

        self.get_status()
        wl = self.get_wavelength()
        power = None

        return [wl, power, self.laser_on]

    def close(self):
        if self.laser_io is None:
            raise NameError('The device is not open yet.')

        if self.shutdown:
            # put laser into shutdown mode
            self.set_mode(mode='O')

        # close serial connection
        self.laser.close()

        print('Closing connection to Superlum')