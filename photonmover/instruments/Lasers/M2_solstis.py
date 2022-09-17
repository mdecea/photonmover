from photonmover.Interfaces.Laser import TunableLaser
from photonmover.Interfaces.Instrument import Instrument

import socket
import json
from time import sleep
import numpy as np


class M2_Solstis(Instrument, TunableLaser):

    """
    Driver for M2 Solstis Tunable Laser
    This driver talks to ICE BLOC the controller for the Solstis laser through TCP/IP sockets

    :param host_address : Address to control computer
    :param port : Port
    :param client_ip : client ip setting in ICE BLOC

    settings for computer in 448:
    host_address ='192.168.1.222', port=39933, client_ip ='192.168.1.100'
    """

    def __init__(self, host_adress='localhost', port=9001, client_ip='192.168.1.100', timeout=1.0,
                 wav_tolerance=0.01, poll_timeout=30):
        
        self.timeout = timeout
        self.wavelength_tolerance = wav_tolerance  # in nm
        self.poll_timeout = poll_timeout  # in s

        self.host_address = host_adress
        self.port = port
        self.client_ip = client_ip
        self.latest_reply = None
        self.poll_status = -1

    def initialize(self):

        """
        Sets up connection to the instrument
        """

        try:

            self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.s.settimeout(self.timeout) # sets timeout
            self.s.connect((self.host_address, self.port))

        except:

            print('M2_Solstis: cannot open socket connection to %s:%d' % (self.host_address, self.port) )
            print("Unexpected error:", sys.exc_info()[0])
            self.s = None

        else:
            # send start link command and parse return
            json_startlink = {
                'message': {
                    'transmission_id': [1],
                    'op': 'start_link',
                    'parameters': {
                        'ip_address': self.client_ip
                    }
                }
            }

            command_startlink = json.dumps(json_startlink)
            self.s.sendall(bytes(command_startlink,'utf-8'))

            json_reply = json.loads(self.s.recv(1024))
            if json_reply['message']['transmission_id'][0] == 1 and json_reply['message']['parameters']['status'] == 'ok':
                print('M2_Solstis: successfully started link to %s:%d as %s' % (self.host_address, self.port, self.client_ip))
            else:
                print('M2_Solstis: failed to start link to to %s:%d as %s' % (self.host_address, self.port, self.client_ip))
                print('M2_Solstis: reply from controller {}'.format(json_reply))

                self.s.close()
                self.s = None

    def close(self):
        """
        Closes socket connection to the laser.
        """
        if self.s is not None:
            self.s.close()

    def turn_on(self):
        print('Turn on for M2 is manual, doing nothing')

    def turn_off(self):
        print('Turn off for M2 is manual, doing nothing')

    def set_power(self, power):
        print('Set power for M2 is manual, doing nothing')

    def get_state(self):
        """
        Returns a list wiht the following elements:
        1. The current wavelength
        2. The current power 
        3. If the laser is on or off.
        """

        wav = self.get_wavelength()
        
        return [wav, 0.0, 0]

    def set_wavelength_no_tuning(self, wavelength):

        """ Sends set wavelength command and checks reply
        :param wavelength: target wavelength (nm)
        :returns: error (int or str)    
            Zero is returned if wavelength was set correctly.
            Otherwise, error string returned by the laser is returned.
            0 : sussessfully sent
            1 : not sent
            9 : socket error
        """

        if self.s is None:
            print('M2_Solstis: socket not connected')
            return 9

        else:
            transID=91
            json_setwave = {
                'message': {
                    'transmission_id': [transID],
                    'op': 'set_wave_m',
                    'parameters': {
                        'wavelength': [wavelength]
                    }
                }
            }

            self.s.sendall(bytes(json.dumps(json_setwave),'utf-8'))
            sleep(1.0)
            json_reply=json.loads(self.s.recv(1024))
            self.latest_reply = json_reply
            if json_reply['message']['transmission_id'] == [transID] and json_reply['message']['parameters']['status'] == [0]:
                print('M2_Solstis: started tuning to {}'.format(wavelength))
                return 0
            else:
                print('M2_Solstis: command not sent')
                print('M2_Solstis: reply from controller {}'.format(json_reply))
                return 1

    def get_wavelength(self):
        """ 
        Returns wavelength from wavemeter in nanometers
        """

        wavelength =  0.0 

        if self.s is not None:

            transID=99
            json_getwave = {
                'message': {
                    'transmission_id': [transID],
                    'op': 'poll_wave_m'
                }
            }
            self.s.sendall(bytes(json.dumps(json_getwave),'utf-8'))

            sleep(2.0)

            json_reply=json.loads(self.s.recv(1024))
                        
            # status id: 0 - idle, 1 - no wavemeter, 2 - tuning, 3 - maintaining, 9 - no connection

            if (json_reply['message']['transmission_id'] == [transID]) and (json_reply['message']['parameters']['status'] in [[0], [2], [3]]):
                wavelength = json_reply['message']['parameters']['current_wavelength'][0]
                print('M2_Solstis: Current wavelength from wavemeter is {}'.format(wavelength))

                if json_reply['message']['parameters']['status'] ==[0]:
                    print('M2_Solstis: idle: software inactive!')
                    self.poll_status=0 
                    
                if json_reply['message']['parameters']['status'] ==[2]:
                    print('M2_Solstis: Tuning laser wavelength')
                    self.poll_status=2 

                elif json_reply['message']['parameters']['status'] ==[3]:
                    print('M2_Solstis: maintaining target wavelength at {}'.format(wavelength))
                    self.poll_status=3 

            else:
                print('M2_Solstis: failed poll wavelength, no wavemeter')
                print('M2_Solstis: reply from controller {}'.format(json_reply))
                self.poll_status=1 

                wavelength =  0.0
        else:
            print('M2_Solstis: socket not connected')
            self.poll_status=9 
            wavelength =  0.0
            
        self.latest_reply = json_reply
        return wavelength

    def stop(self):
        """ 
        stops the tuning operation in progress
        : returns status : 0 if stop was successful, 1 if there is no link to the wavemeter, 9 : socket error
        """

        if self.s is None:
            # print('M2_Solstis: socket not connected')
            return 9

        else:

            transID=77
            json_stopwave = {
                'message': {
                    'transmission_id': [transID],
                    'op': 'stop_wave_m',                    
                }
            }

            self.s.sendall(bytes(json.dumps(json_stopwave),'utf-8'))
            # sleep(1.0)
            json_reply=json.loads(self.s.recv(1024))
            self.latest_reply = json_reply
            
            if (json_reply['message']['transmission_id'] == [transID]) and json_reply['message']['parameters']['status'] == [0]:
                #wavelength = json_reply['message']['parameters']['current_wavelength'][0]
               return 0
            else:
                print('M2_Solstis: failed connection to wavemeter')
                print('M2_Solstis: reply from controller {}'.format(json_reply))
                return 1   

    def lock(self, operation):

        """ 
        locks or removes lock on wavelength
        :param operation: 'on' or 'off'
        :returns status: 
            Zero is returned if operation was unsuccessful
            1 if there is no link to the wavemeter
            9 : socket error                
        """

        if self.s is None:
            # print('M2_Solstis: socket not connected')
            return 9

        else:
            transID=8
            json_lockwave = {
                'message': {
                    'transmission_id': [transID],
                    'op': 'lock_wave_m', 
                    'parameters': {
                        'operation': operation
                    }
                }
            }
                       
            self.s.sendall(bytes(json.dumps(json_lockwave),'utf-8'))

            json_reply=json.loads(self.s.recv(1024))
            self.latest_reply = json_reply
            
            if json_reply['message']['transmission_id'] == [transID] and json_reply['message']['parameters']['status'] == [0]:
                
                print('M2_Solstis: lock or unlock wavelength successfull')       
                #wavelength = json_reply['message']['parameters']['current_wavelength'][0]
                # print('M2_Solstis: Tuning stopped. Current wavelength from wavemeter is {}'.format(wavelength))       
                return 0
            else:
                # print('M2_Solstis: failed connection to wavemeter')
                # print('M2_Solstis: reply from controller {}'.format(json_reply))

                return 1                 
          
    def one_shot(self):
        """ 
        Runs one-shot routine for beam alignment
        First moves the laser's center wavelength to 780 nm followed by one-shot command.
        : Returns status: status of the one shot command
        """

        if self.s is not None:
            transID=97
            json_oneshot = {
                'message': {
                    'transmission_id': [transID],
                    'op': 'beam_alignment',
                    'parameters': {
                        'mode': [4]
                    }
                }
            }
            self.s.sendall(bytes(json.dumps(json_oneshot),'utf-8'))
            sleep(1.0)
            json_reply=json.loads(self.s.recv(1024))
            self.latest_reply = json_reply
            if json_reply['message']['parameters']['status'] == 0:
                print('M2_Solstis: one shot beam alignment successful')

                return 'Success'
            elif json_reply['message']['parameters']['status'] == 1:
                print('M2_Solstis: one shot beam alignment failed')

                return 'Failed'
            else:
                print('software idle')

                return 'fubar'
        else:
            print('M2_Solstis: socket not connected')
            return 'Failed'

    def set_wavelength(self, wavelength):
        
        error_count = 0
        max_error_count = 0

        tuning_count = 0
        max_tuning_count = 3

        success = [] # initializing tuning success indicator

        status = -1 # initializing
        
        print('---------------------------------------------------')
        print('Initializing laser poll status = {} \n '.format(status))                                                          
        print('starting tuning to {} nm  '.format(wavelength))
        
        measured_wavelength = 0
        
        while status != 3:

            measured_wavelength = self.get_wavelength() # getting actual wavelength read
            print('wavelength from wavemeter is {} '.format(measured_wavelength))

            if error_count > max_error_count:
                print('Max Error count reached. Tuning failed ')
                success = 0
                self.stop()
                break

            if tuning_count > max_tuning_count:
                print('Max tuning count reached. Tuning failed ')
                success = 0
                self.stop()
                break  

            if status == -1:    # just started

                print('laser status is now {} \n'.format(status))
                
                self.set_wavelength_no_tuning(wavelength)

                print('M2_Solstis: setting wavelength to {} '.format(wavelength)) 

                sleep(self.poll_timeout)
            
                measured_wavelength = self.get_wavelength() #measuring the current wavelength
                print('current wavelength from wavemeter is now {} nm '.format(measured_wavelength))

                status = self.poll_status # getting current laser tuning status
                print('current laser status is now {} \n'.format(status))

            elif status == 0:

                #idle happened. If wavelength is close enough collect data, else reset wavelength. Stop tuning. 

                print('ERROR M2_Solstis: idle. software inactive!')
                                    
                measured_wavelength = self.get_wavelength()
                
                if np.abs((measured_wavelength - wavelength)) > self.wavelength_tolerance:
                                    
                    status = self.poll_status # check again
                    error_count=error_count+1
                        
                else:
                        
                    status = 3 
                    print('Despite idle wavelength is close and data will be acquired. Moving forward with data acquisition')
                
            elif status == 1:
                #no wavameter.  stop tuning.
                print('ERROR M2_Solstis: failed poll wavelength, no wavemeter')      
                self.stop()
                error_count = error_count+1
                status = -1  # going back to the while loop

            elif status == 2: 
                
                # tuning in process. do nothing. wait and poll status again 
                print('Status = 2, Tuning still in progress, waiting and trying to poll status again: # {} \n'.format(tuning_count))
                tuning_count = tuning_count+1
                print('M2_Solstis: Tuning laser wavelength. Try number {} \n'.format(tuning_count))
                #print('M2_Solstis: Current wavelength from wavemeter is {}'.format(measured_wavelength))

                sleep(self.poll_timeout)
                measured_wavelength = self.get_wavelength()
                status = self.poll_status
  
        else: 
            #status=3 laser is maintaining wavelength
            
            print('laser status is now {} (ready to acquire) \n'.format(status))
            measured_wavelength = self.get_wavelength() #measuring the current wavelength
            print('M2_Solstis: maintaining target wavelength at {} and ready for data Collection.'.format(measured_wavelength))                                                             
            success = 1            
            self.stop()
            #laser.lock('on')
            
        return success, measured_wavelength

if __name__ == '__main__':
    solstis = M2_Solstis()
    solstis.initialize()
    solstis.set_wavelength(800.0)
    sleep(2)
    print(solstis.get_wavelength())
    solstis.close()

            
          
     
    