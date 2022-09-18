# -*- coding: utf-8 -*-

import pyvisa as visa
import time
from photonmover.Interfaces.LightSource import LightSource
from photonmover.Interfaces.Instrument import Instrument
import matplotlib.pyplot as plt
import json
import socket

"""


Created on Thu Nov 19 20:57:24 2020
added lock wavelength WARNING: locking triggers tuning and setting of a new wavelength target by SOLSTIS
@author: User
Driver for M2 Solstis Tunable Laser
This driver talks to ICE BLOC the controller for the Solstis laser through TCP/IP sockets


Usage Example:
    from instrumental.drivers.lasers.solstis import M2_Solstis
    # laser = M2_Solstis()
    laser.set_wavelength(wavelength=850.0)
    wavelength =  laser.poll_wavelength()
    laser.close()


Contributors:
- Nili Persits
- Zheng Li
- Jaehwan Kim
- Gavin West

Copyright 2020-2021
"""


class SolsTiS(Instrument, LightSource):

    def __init__(
            self,
            host_address='localhost',
            port=9001,
            client_ip='192.168.1.100'):
        super().__init__()

        self.host_address = host_address
        self.port = port
        self.client_ip = client_ip
        self.s = None   # Preallocate a socket object

    def initialize(self):
        """
        Initializes the instrument's socket communications with IceBloc and sends `start_link` command.
        :return:
        """

        # Internal parameters
        self.timeout = 1.0
        self.wavelength_tolerance = 0.01  # nm
        self.poll_timeout = 30
        host_address = self.host_address
        port = self.port
        client_ip = self.client_ip
        self.latest_reply = None
        self.poll_status = -1

        try:
            self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.s.settimeout(self.timeout)  # sets timeout
            # self.s.connect((self._paramset['host_address'], self._paramset['port']))
            self.s.connect((host_address, port))
        except BaseException:
            # print('M2_Solstis: cannot open socket connection to {}:{}'.format(self._paramset['host_address'], self._paramset['port']))
            print(
                'M2_Solstis: cannot open socket connection to {}:{}'.format(
                    host_address, port))
            print("Unexpected error:", sys.exc_info()[0])
            self.s = None
        else:
            # send start link command and parse return
            json_startlink = {
                'message': {
                    'transmission_id': [1],
                    'op': 'start_link',
                    'parameters': {
                        'ip_address': client_ip
                    }
                }
            }

            command_startlink = json.dumps(json_startlink)
            self.s.sendall(bytes(command_startlink, 'utf-8'))

            json_reply = json.loads(self.s.recv(1024))
            if json_reply['message']['transmission_id'][0] == 1 and json_reply['message']['parameters']['status'] == 'ok':
                # print('M2_Solstis: successfully started link to {}:{} as {}'.format(self._paramset['host_address'], self._paramset['port'], self._paramset['client_id']))
                print(
                    'M2_Solstis: successfully started link to {}:{} as {}'.format(
                        host_address, port, client_ip))
            else:
                # print('M2_Solstis: failed to start link to {}:{} as {}'.format(self._paramset['host_address'], self._paramset['port'], self._paramset['client_id']))
                print(
                    'M2_Solstis: failed to start link to {}:{} as {}'.format(
                        host_address, port, client_ip))
                print('M2_Solstis: reply from controller {}'.format(json_reply))

                self.s.close()
                self.s = None

    def get_id(self):
        return ("LightSource")

    def close(self):
        """
        Closes the socket connection to the instrument
        :return:
        """

        if self.s is not None:
            self.s.close()
            print('Connection to SolsTiS is closed')

    def one_shot(self):
        """ Runs one-shot routine for beam alignment
        First moves the laser's center wavelength to 780 nm followed by one-shot command
        Returns
        -------
        status: str
            returns status of the one shot command
        """
        self.set_wavelength(wavelength=780)

        if self.s is not None:
            transID = 97
            json_oneshot = {
                'message': {
                    'transmission_id': [transID],
                    'op': 'beam_alignment',
                    'parameters': {
                        'mode': [4]
                    }
                }
            }
            self.s.sendall(bytes(json.dumps(json_oneshot), 'utf-8'))
            sleep(1.0)
            json_reply = json.loads(self.s.recv(1024))
            self.latest_reply = json_reply
            if json_reply['message']['parameters']['status'] == 0:
                print('M2_Solstis: one shot beam alignment successful')

                return 'Success'
            elif json_reply['message']['parameters']['status'] == 1:
                print('M2_Solstis: one shot beam alignment failed')

                return 'Failed'
            else:
                print('Gavin says things are fucked up, yo')

                return 'fubar'
        else:
            print('M2_Solstis: socket not connected')
            return 'Failed'

    def turn_off(self):
        """
        Turn light off
        :return:
        """
        print('The SolsTiS does not have a simple `off` command. Please turn off manually.')

    def turn_on(self):
        """
        Turn light on
        :return:
        """
        print('The SolsTiS does not have a simple `on` command. Please turn on manually.')

    def set_power(self, power):
        """
        Set the power to the specified value (in mW)
        :return:
        """
        print('The SolsTiS does not have a software-controllable output power. Please set manually.')

    def set_wavelength(self, wavelength, use_wavemeter=true):
        """
        Sets the laser to the specified wavelength in nanometers.


        Parameters
        ----------
        wavelength : float
            target wavelength in nanometers
        use_wavemeter : bool
            If True, tune using HighFinesse wavemeter. If False, use lookup table tuning.

        Returns
        -------
        error : int or str
            Zero is returned if wavelength was set correctly.

            Otherwise, error string returned by the laser is returned.

            open question about how the tuning is done

            0 : sussessfully sent
            1 : not sent
            9 : socket error
        """

        if use_wavemeter:
            cmd_string = 'set_wave_m'
        else:
            cmd_string = 'move_wave_t'
            raise ValueError(
                'Tuning with the lookup table requires disabling wavemeter control. This is not currently implemented')

        if self.s is None:
            # print('M2_Solstis: socket not connected')
            return 9
        else:
            transID = 91
            json_setwave = {
                'message': {
                    'transmission_id': [transID],
                    'op': cmd_string,
                    'parameters': {
                        'wavelength': [wavelength]
                    }
                }
            }

            self.s.sendall(bytes(json.dumps(json_setwave), 'utf-8'))
            sleep(1.0)
            json_reply = json.loads(self.s.recv(1024))
            self.latest_reply = json_reply
            if json_reply['message']['transmission_id'] == [
                    transID] and json_reply['message']['parameters']['status'] == [0]:
                return 0
            else:
                return 1

    def set_wavelength_tuning_tolerance(self) -> None:
        """
        """

    def get_wavelength(self, use_wavemeter=true) -> None:
        """
        Returns the current set wavelength. If the wavemeter is used, the value is the wavemeter readout.
        Otherwise the returned value is the table setpoint.


        Returns
        -------
        wavelength : Q_ class
            returns current measured wavelength if successful or Q 0.0 otherwise

        status id
        0: idle
        1: no wavemeter
        2: tuning
        3: maintaining
        9: no connection
        """

        wavelength = 0.0

        if self.s is not None:
            transID = 99
            json_getwave = {
                'message': {
                    'transmission_id': [transID],
                    'op': 'poll_wave_m'
                }
            }
            self.s.sendall(bytes(json.dumps(json_getwave), 'utf-8'))
            # sleep(5.0)
            json_reply = json.loads(self.s.recv(1024))
            if (json_reply['message']['transmission_id'] == [transID]) and (
                    json_reply['message']['parameters']['status'] in [[0], [2], [3]]):
                wavelength = json_reply['message']['parameters']['current_wavelength'][0]
                # print('M2_Solstis: Current wavelength from wavemeter is {}'.format(wavelength))

                if json_reply['message']['parameters']['status'] == [0]:
                    # print('M2_Solstis: idle: software inactive!')
                    self.poll_status = 0

                if json_reply['message']['parameters']['status'] == [2]:
                    # print('M2_Solstis: Tuning laser wavelength')
                    self.poll_status = 2

                elif json_reply['message']['parameters']['status'] == [3]:
                    # print('M2_Solstis: maintaining target wavelength at {}'.format(wavelength))
                    self.poll_status = 3

            else:
                # print('M2_Solstis: failed poll wavelength, no wavemeter')
                # print('M2_Solstis: reply from controller {}'.format(json_reply))
                self.poll_status = 1

                wavelength = 0.0
        else:
            # print('M2_Solstis: socket not connected')
            self.poll_status = 9
            wavelength = 0.0

        self.latest_reply = json_reply
        return wavelength

    def get_monitor_value(self):
        """
        Queries the specified monitor built into the SolsTiS/IceBloc.
        :return:
        """

    def stop_wavelength_tuning(self) -> None:
        """
        Stop an in-progress wavelength tuning operation.

        Parameters
        ----------

        Returns
        -------
        status : str
            Zero is returned if stop was successful
            1 if there is no link to the wavemeter
            9 : socket error
        wavelength the current and last wavelength

        """
        if self.s is None:
            # print('M2_Solstis: socket not connected')
            return 9
        else:
            transID = 77
            json_stopwave = {
                'message': {
                    'transmission_id': [transID],
                    'op': 'stop_wave_m',
                }
            }

            self.s.sendall(bytes(json.dumps(json_stopwave), 'utf-8'))
            # sleep(1.0)
            json_reply = json.loads(self.s.recv(1024))
            self.latest_reply = json_reply

            if (json_reply['message']['transmission_id'] == [
                    transID]) and json_reply['message']['parameters']['status'] == [0]:
                #wavelength = json_reply['message']['parameters']['current_wavelength'][0]
                return 0
            else:
                # print('M2_Solstis: failed connection to wavemeter')
                # print('M2_Solstis: reply from controller {}'.format(json_reply))

                return 1

    def lock_wavelength(self, operation):
        """
        Change state of wavelength lock.

        Inputs
        ------
        operation : str
            'on' or 'off'

        Returns
        -------
        status : str
            Zero is returned if operation was unsuccessful
            1 if there is no link to the wavemeter
            9 : socket error
        wavelength the current and last wavelength


        WHAT LOCK IS THIS? Etalon lock? Wavemeter lock? Is this meaning the wavemeter interface?
        """
        if self.s is None:
            # print('M2_Solstis: socket not connected')
            return 9
        else:
            transID = 8
            json_lockwave = {
                'message': {
                    'transmission_id': [transID],
                    'op': 'lock_wave_m',
                    'parameters': {
                        'operation': operation
                    }
                }
            }

            # print(json_lockwave)

            self.s.sendall(bytes(json.dumps(json_lockwave), 'utf-8'))
            # sleep(1.0)
            json_reply = json.loads(self.s.recv(1024))
            self.latest_reply = json_reply

            # print(json_reply)

            if json_reply['message']['transmission_id'] == [
                    transID] and json_reply['message']['parameters']['status'] == [0]:
                print('M2_Solstis: lock or unlock wavelength successfull')
                #wavelength = json_reply['message']['parameters']['current_wavelength'][0]
                # print('M2_Solstis: Tuning stopped. Current wavelength from wavemeter is {}'.format(wavelength))
                return 0
            else:
                # print('M2_Solstis: failed connection to wavemeter')
                # print('M2_Solstis: reply from controller {}'.format(json_reply))
                return 1

    def start_sweep(self):
        """
        """

    def configure_sweep(self, init_wav, end_wav, num_wav):
        """
        Configures the laser to take a wavelength sweep
        :param init_wav:
        :param end_wav:
        :param num_wav:
        :return:
        """
        pass

    def take_sweep(self, init_wav, end_wav, num_wav):
        """
        Takes a wavelength sweep from init_wav to end_wav with num_wav points,
        and measured the power.
        :return:
        """
        pass

    def get_state(self):
        """
        Returns a list wiht the following elements:
        1. The current wavelength
        2. The current output PD voltage
        3. The current tuning status
        4. The wavemeter link state (connected/disconnected)
        """

        pass


if __name__ == '__main__':
    laser = SolsTiS(
        host_address='localhost',
        port=9001,
        client_ip='192.168.1.100')
    laser.initialize()
    # laser.configure_sweep()
    laser.close()
