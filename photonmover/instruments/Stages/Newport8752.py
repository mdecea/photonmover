from photonmover.Interfaces.Instrument import Instrument
import serial
import time

COM_ADDRESS = 'COM11'


class Newport8752(Instrument):

    def __init__(
        self, axis_map={
            'x': 'a1', 'y': 'a2'}, units={
            'x': 1 / 30e-9, 'y': 1 / 30e-9}):
        super().__init__()

        # Axis map indicating which driver (a1 - a8) corresponds to each axis
        self.axis_map = axis_map

        self.wait = 0.1

        # Converts between encoder positions and a given distance unit.
        self.units = units
        # For example, if 1 um = 10000 encoder steps, then we could do units={'x':1000, 'y':1000}
        # And then, if we call move(units=1), we will move 1 um (which is equal
        # to 1000 encoder steps)

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print("Initializing connection to Tunable Filter")
        self.serial = serial.Serial(
            COM_ADDRESS,
            baudrate=19200,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=3,
            xonxoff=True,
            rtscts=False,
            dsrdtr=False)
        self.joystick_enable(enable=False)
        self.sendrecv('DEF')  # Default settings

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print("Closing connection to Newport picomotor driver")
        self.serial.close()

    def send(self, cmd):
        """Send a command to the picomotor driver."""
        line = cmd + '\r\n'
        retval = self.serial.write(bytes(line, encoding='ascii'))
        print('sent %s' % line)
        self.serial.flush()
        return retval

    def readlines(self):
        """Read response from picomotor driver."""
        return ''.join([l.decode('ASCII') for l in self.serial.readlines()])

    def sendrecv(self, cmd):
        """Send a command and (optionally) printing the picomotor driver's response."""
        res = self.send(cmd)
        time.sleep(self.wait)
        ret_str = self.readlines()
        return res, ret_str

    def set_axis(self, axis, vel=None, acc=None, motor=0):
        """Set current axis ('x' or 'y') and (optionally) its velocity.

        :param motor: some picomotor controllers have 3 channels, so we could select the specific channel
            with this parameter. Nevertheless, what we have in lab only has one channel (so motor = 0)

        """

        assert axis in self.axis_map

        fmt = dict(driver=self.axis_map[axis], motor=motor)
        basecmd = '{cmd} {driver} {motor}={value}'

        cmd = 'chl {driver}={motor}'.format(**fmt)

        resp = self.sendrecv(cmd)

        cmd = 'typ {driver} 0'.format(**fmt)
        resp = self.sendrecv(cmd)

        if acc is not None:
            assert 0 < acc <= 32000, 'Acceleration out of range (1..32000).'
            cmd = basecmd.format(cmd='ACC', value=acc, **fmt)
            self.sendrecv(cmd)

        if vel is not None:
            assert 0 < vel <= 2000, 'Velocity out of range (1..2000).'
            cmd = basecmd.format(cmd='VEL', value=vel, **fmt)
            self.sendrecv(cmd)

        cmd = 'mon'  # Turn drivers on

        return self.sendrecv(cmd)

    def move_to_limit(
            self,
            axis,
            direction='forward',
            vel=None,
            acc=None,
            motor=0):
        """
        Moves the specified axis to its limit
        :param direction: 'forward' or 'reverse', if we want to find the forward or reverse limit.
        """
        self.set_axis(axis, vel=vel, acc=acc, motor=motor)

        if direction == 'forward':
            cmd = 'fli {driver}'.format(driver=self.axis_map[axis])
        elif direction == 'reverse':
            cmd = 'rli {driver}'.format(driver=self.axis_map[axis])
        return self.sendrecv(cmd)

    def move_steps(self, steps, axis, vel=None, acc=None, motor=0, go=True):
        """
        Send command to move `axis` of the given `steps`.

        :param steps: how many steps to move with respect to the current position
        :param motor: some picomotor controllers have 3 channels, so we could select the specific channel
            with this parameter. Nevertheless, what we have in lab only has one channel (so motor = 0)
        :param go: if True, the command is executed right away
        """

        print('Current pos: %s', self.sendrecv('pos'))

        self.set_axis(axis, vel=vel, acc=acc, motor=motor)
        cmd = 'rel {driver}={steps}'.format(
            driver=self.axis_map[axis], steps=steps)
        if go:
            cmd = cmd + ' g'
        return self.sendrecv(cmd)

    def move(self, units, axis, vel=None, acc=None, motor=0, go=True):
        """Send command to move `axis` of the given `units`.
        :param units: how many units to move with respect to the current position. the ocnversino form units to step is
            done through the self.units dictionnary specified in the __init__
        :param motor: some picomotor controllers have 3 channels, so we could select the specific channel
            with this parameter. Nevertheless, what we have in lab only has one channel (so motor = 0)
        :param go: if True, the command is executed right away
        """
        steps = round(units * self.units[axis])
        return self.move_steps(
            steps,
            axis,
            vel=None,
            acc=None,
            motor=0,
            go=True)

    def go(self):
        """Send 'go' command to execute all previously sent move commands."""
        return self.sendrecv('go')

    def halt(self):
        """Send 'HAL' command to stop motion with deceleration."""
        return self.sendrecv('hal')

    def joystick_enable(self, enable=True):
        """Enable or disable the joystick."""
        cmd = 'JON' if enable else 'JOF'
        return self.sendrecv(cmd)

    def status_msg(self):
        """Return the driver status byte as an integer (see manual pag. 185)."""
        self.send('STA')
        time.sleep(self.wait)
        ret_str = self.readlines()
        return ret_str

    def status(self):
        ret_str = self.status_msg()
        i = ret_str.find('A1=')
        if i >= 0:
            status = int(ret_str[i + 5:i + 7], 16)
        else:
            raise IOError("Received: '%s'" % ret_str)
        return status

    def is_moving(self):
        """Return True if motor is moving, else False."""
        status = self.status()
        return status & 0x01


if __name__ == '__main__':
    stage = Newport8752()
    stage.initialize()
    # print(stage.set_axis('x'))
    # input()
    # print(stage.move_to_limit('x'))
    # input()
    print(stage.move_steps(-10000, 'y', vel=500, acc=None, motor=0, go=True))
    print('Current pos: %s', stage.sendrecv('pos'))
    stage.close()
