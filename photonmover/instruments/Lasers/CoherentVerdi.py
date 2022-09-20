# -*- coding: utf-8 -*-
import pyvisa as visa
from pyvisa.constants import StopBits, Parity, SerialTermination
from photonmover.Interfaces.Laser import Laser
from photonmover.Interfaces.Instrument import Instrument


class CoherentVerdi(Instrument, Laser):

    """
    A class for Coherent Verdi lasers.
    INPUTS:
        * **com_port** (int): The COM port the instrument is connected through.
    """

    def __init__(self, com_port):
        super().__init__()

        self.com_port = com_port
        self.controller = None
        self.is_initialized = False
        self.shutter_state = None
        self.standby_state = None

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Coherent Verdi controller')

        if self.is_initialized:
            print("Verdi is already an initialized instrument")
        else:
            rm = visa.ResourceManager()
            try:
                self.controller = rm.open_resource('COM'+str(self.com_port))
                self.is_initialized = True
            except ConnectionError:
                raise ConnectionError('Cannot connect to Coherent Verdi controller')

            self.init_function()

    def close(self):
        if self.is_initialized:
            try:
                self.controller.close()
                print('Disconnecting Coherent Verdi controller')
            except Warning:
                raise Warning("Cannot disconnect instrument for unknown reasons")
        else:
            print("Verdi is not initialized, cannot close.")

    def init_function(self):
        """
        Initializes device, sets communication parameters.
        """
        self.controller.baud_rate = 19200
        self.controller.data_bits = 8
        self.controller.parity = Parity.none
        self.controller.stop_bits = StopBits.one
        self.controller.end_input = SerialTermination.termination_char

        # Get rid of the "Verdi" prompt preceeding all responses
        self.controller.query("PROMPT=0")
        self.controller.query("ECHO=0")
        self.get_shutter_state()
        self.get_standby_state()

    def turn_on(self) -> None:
        """
        Wrapper function for `set_shutter_state()` to comply with `Laser` parent
        class.
        Checks that the Verdi status is not on standby, and opens the shutter.
        Prints the power setpoint.
        """

        self.get_standby_state()
        keyswitch_state = self.query_instrument("?K")
        if keyswitch_state.lower() == '0':
            print("Key switch is in 'off' position. Cannot change setting remotely.")
        else:
            self.set_standby_state(state='on')
            self.set_shutter_state(state='open')
            print("Power setpoint: {}W".format(
                self.get_power(get_setpoint=True)))

    def turn_off(self, override_interlock_key=False) -> None:
        """
        Wrapper function for `set_shutter_state()` to comply with `Laser` parent
        class.
        Optionally can put the laser fully into `Standby` state. This OVERRIDES
        the front panel key (the key may still indicate it is "on" and not "standby").
        INPUTS:
        * **override_interlock_key** (bool): Optionally override the physical
                            key setting on the Verdi controller's front panel.
                            This override only works to set standby ON, it cannot
                            override an "off" key position.
        """

        if self.shutter_state.lower() != 'closed':
            self.set_shutter_state(state='closed')

        if override_interlock_key:
            self.set_standby_state('off')

    def set_shutter_state(self, state='closed') -> None:
        """
        Opens or closes the shutter.
        * **state** (str): Informs whether to open or close the shutter. Takes
                            either "open" or "closed". Default is "closed".
        """

        if state.lower() == 'closed':
            cmd = 0
            self.shutter_state = 'closed'
        elif state.lower() == 'open':
            cmd = 1
            self.shutter_state = 'open'
        else:
            raise ValueError(" 'state' input must be 'open' or 'closed' ")
        self.query_instrument("S={}".format(cmd))

    def get_shutter_state(self, print_out=False):
        """
        Returns the current shutter state (open or closed)
        INPUTS:
        * **print_out** (bool): Flag, print state to command line.
        """
        ans = self.query_instrument("?S")
        if ans == '0':
            self.shutter_state = 'closed'
        elif ans == '1':
            self.shutter_state = 'open'

        if print_out:
            print('Shutter is {}'.format(self.shutter_state))

    def get_standby_state(self, print_out=False):
        """
        Checks if the verdi controller is in standby.
        INPUTS:
        * **print_out** (bool): Flag, print state to command line.
        """

        self.standby_state = self.query_instrument("?L")
        if print_out:
            if self.standby_state == '1':
                print("Laser is not on standby")
            else:
                print("Laser is on standby")

    def set_standby_state(self, state):
        """
        Sets the standby state. If the keyswitch is off, the standby state
        cannot be changed remotely.
        INPUTS:
        * **state** (str): Desired standby state: 'on', the laser is active, and
                            'off', the laser is off (in standby).
        """

        keyswitch_state = self.query_instrument("?K")
        if keyswitch_state.lower() == '0':
            print("Key switch is in 'off' position. Cannot change setting remotely.")
            self.standby_state = 0
        else:
            if state.lower() == 'on':
                self.query_instrument("LASER=1")
                self.standby_state = 1
            elif state.lower() == 'off':
                self.query_instrument("LASER=0")
                self.standby_state = 0

    def get_state(self):
        """
        Returns state of general instrument as list of [Power setpoint, output on/off]
        """

        self.get_shutter_state()
        return [self.get_power(), self.shutter_state]

    def set_power(self, power) -> None:
        """
        Sets the output power level.
        * **power** (float): Desired output power, in watts. Must be between 0.01
                            and 10. No default.
        """
        if not ((power <= 10) and (power >= 0.01)):
            print("Power must be between 0.01 and 10 watts")
            return
        else:
            self.query_instrument('POWER={}'.format(power))

    def get_power(self, get_setpoint=False):
        """
        Gets the output power, or setpoint, in watts.
        """
        if get_setpoint:
            return self.query_instrument("?SP")
        else:
            return self.query_instrument("?P")

    def get_maintenance_parameters(self):
        """
        Queries the Verdi controller for laser head hours, diode hours, diode
        currents/voltages/PD voltages, LBO temperature settings, and so on.
        """
        data = {'head': {},
                'lbo': {},
                'vanadate': {},
                'diode1': {},
                'diode2': {},
                'power_supply': {},
                }

        data['head']['hours'] = self.query_instrument("?HH")
        data['head']['current'] = self.query_instrument("?C")
        data['head']['temp_baseplate'] = self.query_instrument("?BT")
        data['head']['power_out'] = self.query_instrument("?P")

        data['lbo']['temp'] = self.query_instrument("?LBOT")
        data['lbo']['temp_setting'] = self.query_instrument("?LBOST")

        data['power_supply']['hours'] = self.query_instrument("?PSH")

        data['vanadate']['temp'] = self.query_instrument("?VT")
        data['vanadate']['temp_setting'] = self.query_instrument("?VST")

        for idx, diode in [(1, 'diode1'), (2, 'diode2')]:
            data[diode]['current'] = self.query_instrument("?D{}C".format(idx))
            data[diode]['temp'] = self.query_instrument("?D{}HST".format(idx))
            data[diode]['hours'] = self.query_instrument("?D{}H".format(idx))
            data[diode]['photocell'] = self.query_instrument(
                "?D{}PC".format(idx))
            data[diode]['temp_servo_status'] = self.query_instrument(
                "?D{}SS".format(idx))

        return data

    def query_instrument(self, message):
        """
        Formats queries and responses. All responses are formatted as strings
        """
        return str(self.controller.query(message))[:-2]


if __name__ == '__main__':
    laser = CoherentVerdi(com_port=1)
    laser.initialize()
    print(laser.get_state())
    laser.close()
