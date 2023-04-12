# -*- coding: utf-8 -*-
# Copyright 2020 Gavin West
import numpy as np
import pyvisa as visa
from pyvisa.constants import StopBits, Parity, SerialTermination
import photonmover.Interfaces.TempController as TempController
import photonmover.Interfaces.Instrument as Instrument


class LFI3751(TempController, Instrument):
    """
    A class for Wavelength Electronics LFI3751-type TEC controllers, subclass
    of TempController.

    INPUTS:
        * **com_port** (int): The COM port the instrument is connected through.
        * **rs232_address** (int): The address the controller is set to communicate on, see instrument panel.

    """

    def __init__(self, com_port, rs232_address=1):
        super().__init__()
        # It is good practice to initialize variables in init
        self.com_port = com_port
        self.rs232_address = rs232_address

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Wavelength Electronics 3751 temperature controller')

        rm = visa.ResourceManager()
        try:
            self.tec = rm.open_resource('COM' + str(self.com_port))
        except BaseException:
            raise ValueError(
                'Cannot connect to Wavelength Electronics temp controller')

        self.init_function()

    def close(self):
        try:
            self.tec.close()
            print('Disconnecting Wavelength Electronics 3751 temperature controller')
        except BaseException:
            print('Cannot disconnect instrument')

    def init_function(self):
        """
        Initializes device, sets communication parameters.
        """
        self.tec.baud_rate = 19200
        self.tec.data_bits = 8
        self.tec.parity = Parity.none
        self.tec.stop_bits = StopBits.one
        self.tec.end_input = SerialTermination.termination_char

        # Write an arbitrary message to initialize RS232 communication with instrumnet.
        # Choosing the "alarm status" message
        self.tec.query(self._format_msg(cmd='read', code=35, value=0))

    def turn_on(self):
        """
        Turns the temperature controller on at the current set temperature
        :return:
        """
        self.tec.query(self._format_msg(cmd='write', code=51, value=0.001))

    def turn_off(self):
        """
        Turns the control current off.
        :return:
        """
        self.tec.query(self._format_msg(cmd='write', code=51, value=0))

    def set_temperature(self, temperature):
        """
        Sets the target temperature (in C).
        Given temperature value must be between -199.999 C and +199.99 C.
        """
        if np.abs(temperature) > 199.999:
            raise ValueError(
                "Temperature setpoint must be within +/- 199.999 C")

        self.tec.query(
            self._format_msg(
                cmd='write',
                code=3,
                value=temperature))

    def get_temperature(self):
        """
        Queries the current temperature, as read by the sensor.
        Returns temperature as a float in degree C.
        """
        reply = self.tec.query(self._format_msg(cmd='read', code=1, value=0))
        return float(reply[-12:-4])

    def get_temperature_setpoint(self):
        """
        Queries the current temperature setpoint.
        Returns temperature as float in degree C.
        """
        reply = self.tec.query(self._format_msg(cmd='read', code=3, value=0))
        return float(reply[-12:-4])

    def set_sensor_properties(
            self,
            sensor_type="thermistor",
            sensor_parameters=None):
        """
        Communicates sensor type and parameters (e.g., thermal resistivity constants) for internal calibration of the temperature measurement.

        sensor_type (str): (NTC) "thermistor" is the only supported sensor type at this time.
        sensor_parameters (dict): A1,2, B1,2, and C1,2 parameters for the thermistor calibration as a dict, e.g. sensor_params['A1']=5.00
        """

        if sensor_type == "thermistor":
            # set NTC-type thermistor with 100 uA bias current
            self.tec.query(
                self._format_msg(
                    cmd='write',
                    code=41,
                    value=-0.010))

            # Set A/B/C parameters
            if not set(sensor_parameters.keys()) == set(
                    ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']):
                raise ValueError(
                    'The sensor_parameters dict must contain ONLY A1, A2, B1, B2, C1, and C2 keyword/value pairs.')

            code_dict = {
                'A1': 21,
                'A2': 22,
                'B1': 23,
                'B2': 24,
                'C1': 25,
                'C2': 26,
            }
            for k, v in sensor_parameters.items():
                self.tec.query(
                    self._format_msg(
                        cmd='write',
                        code=code_dict[k],
                        value=v))

    # def autotune_pid( self, temperature ):
    #     """
    #     Run the PID autotune procedure at a given temperature setpoint, and assign the resulting PID values.
    #     """
    #     self.tec.query( self._format_msg(cmd='write', code=51, value=1.011))

    def set_temperature_limits(self, upper=None, lower=None):
        """
        Set upper and lower temperature limits, in degree celcius.

        """
        if np.abs(upper) > 199.999 or np.abs(lower) > 199.999:
            raise ValueError('Temperature bounds cannot exceed +/- 199.999 C')

        if upper < lower:
            raise ValueError('Upper bound must be greater than lower bound')

        if upper is None:
            self.tec.query(
                self._format_msg(
                    cmd='write',
                    code=31,
                    value=199.999))
        elif upper is not None:
            self.tec.query(self._format_msg(cmd='write', code=31, value=upper))

        if lower is None:
            self.tec.query(
                self._format_msg(
                    cmd='write',
                    code=32,
                    value=-199.999))
        elif lower is not None:
            self.tec.query(self._format_msg(cmd='write', code=32, value=lower))

    def _framechecksum(self, msg):
        """
        Calculate the "Frame Check Sum" value appended to the tail of setpoint messages.
        Returns FCS as a string.
        """

        fcslen = len(msg)
        if fcslen != 15:
            raise ValueError("Message length incorrect")

        fcs = 0
        for idx in range(fcslen):
            x = ord(msg[idx])
            fcs = fcs ^ x
        return hex(fcs)[-2:]

    def _format_msg(self, cmd, code, value):
        """
        Automatically generates the command string based on the command code, type of oepration (read/write), and value.

        cmd (str): 'read' or 'write' based on desired reply
        code (int): Code number for desired command
        val (float): Value to be sent, e.g. temperature, current, etc.

        Appends the Frame Check Sum automatically.

        """
        if cmd == 'read':
            cmd = 1
        elif cmd == 'write':
            cmd = 2
        else:
            raise ValueError("'cmd' input must be either 'read' or 'write'")

        msg = '!1{:02d}{:1d}{:02d}{:+08.3f}'.format(
            self.rs232_address, cmd, code, value)

        return msg + self._framechecksum(msg)

    def _read_buffer(self):
        """
        Returns the output of the buffer (e.g., errors) for debugging purposes.
        """

        print(self.tec.read())


if __name__ == '__main__':
    t_cont = LFI3751(com_port=12)
    t_cont.initialize()
    print(t_cont.get_temperature())
    t_cont.close()
