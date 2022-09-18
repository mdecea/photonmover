# NewPort Conex-CC class
# Adapted from Itay Shahak's code
# (https://gist.github.com/ishahak/bd025295dd8f6976dc962c6a02dec86b)

import CommandInterfaceConexCC
from photonmover.Interfaces.Instrument import Instrument

# dependant on 'clr' which is PythonNet package
import clr
from time import sleep

import ctypes
# We assume Newport.CONEXCC.CommandInterface.dll is copied to our folder
clr.AddReference('./Newport.CONEXCC.CommandInterface')

DEV = 1                # hardcoded here to the first device
MAX_VELOCITY = 0.4     # mm/s, by spec of NewPort TRA25CC DC Servo Motor

COM_ADDRESS = 'COM4'


class ConexCC(Instrument):

    def __init__(self, velocity=None, com_port=COM_ADDRESS):
        super().__init__()
        self.min_limit = -1
        self.max_limit = -1
        self.cur_pos = -1
        self.controller_state = ''
        self.positioner_error = ''
        self.com_port = com_port
        self.velocity = velocity

    def initialize(self):

        #self.dll = ctypes.cdll.LoadLibrary('./Newport.CONEXCC.CommandInterface.dll')
        #self.driver = self.dll.ConexCC()
        #self.dll.OpenInstrument.restype = ctypes.c_int
        # input()

        self.driver = CommandInterfaceConexCC.ConexCC()
        ret = self.driver.OpenInstrument(self.com_port)
        if ret != 0:
            print('Oops: error opening port %s' % self.com_port)
            self.positioner_error = 'init failed'
        else:
            print('ConexCC: Successfully connected to %s' % self.com_port)
            self.read_velocity()
            if self.velocity is not None:
                self.set_velocity(self.velocity)
                self.set_homing_velocity(self.velocity)
            self.read_limits()
            self.read_cur_pos()

    def wait_for_ready(self, timeout=60):
        print('waiting for ready state...', end='')
        count = 0
        sleep_interval = 0.2
        last_count = (1 / sleep_interval) * timeout
        while not self.is_ready():
            count += 1
            if count % 30 == 0:
                print('<%s>' % self.controller_state)
            else:
                print('<%s>' % self.controller_state, end='', flush=True)
            sleep(sleep_interval)
            if count >= last_count:
                print(
                    'failed to become ready. existing for timeout = %d seconds.' %
                    timeout)
                return False
        print('ok')
        return True

    def is_ready(self):
        self.read_controller_state(silent=True)

        if self.controller_state in ('3D', '3C'):  # in DISABLE state
            self.exit_disable_state()
            sleep(0.2)
            self.read_controller_state()
        elif self.controller_state.startswith('0'):  # not referenced state
            self.init_positioner()
            sleep(0.4)

        # ('32','33','34') means in READY state
        ready = self.positioner_error == '' and self.controller_state in (
            '32', '33', '34')
        return ready

    @classmethod
    def dump_possible_states(cls):
        # https://www.newport.com/mam/celum/celum_assets/resources/CONEX-CC_-_Controller_Documentation.pdf#page=54
        help_text = '''===== Conex-CC Controller States =====
            – 0A: NOT REFERENCED from RESET.
            – 0B: NOT REFERENCED from HOMING.
            – 0C: NOT REFERENCED from CONFIGURATION.
            – 0D: NOT REFERENCED from DISABLE.
            – 0E: NOT REFERENCED from READY.
            – 0F: NOT REFERENCED from MOVING.
            – 10: NOT REFERENCED - NO PARAMETERS IN MEMORY.
            – 14: CONFIGURATION.
            – 1E: HOMING.
            – 28: MOVING.
            – 32: READY from HOMING.
            – 33: READY from MOVING.
            – 34: READY from DISABLE.
            – 36: READY T from READY.
            – 37: READY T from TRACKING.
            – 38: READY T from DISABLE T.
            – 3C: DISABLE from READY.
            – 3D: DISABLE from MOVING.
            – 3E: DISABLE from TRACKING.
            – 3F: DISABLE from READY T.
            – 46: TRACKING from READY T.
            – 47: TRACKING from TRACKING.
            ===========================================
        '''
        for s in help_text.split('\n'):
            print(s.strip(' '))

    def read_limits(self):
        err_str = ''
        resp = 0
        res, resp, err_str = self.driver.SL_Get(DEV, resp, err_str)
        if res != 0 or err_str != '':
            print(
                'Oops: Negative SW Limit: result=%d,response=%.2f,errString=\'%s\'' %
                (res, resp, err_str))
        else:
            print('Negative SW Limit = %.1f' % resp)
            self.min_limit = resp

        res, resp, err_str = self.driver.SR_Get(DEV, resp, err_str)
        if res != 0 or err_str != '':
            print(
                'Oops: Positive SW Limit: result=%d,response=%.2f,errString=\'%s\'' %
                (res, resp, err_str))
        else:
            print('Positive SW Limit = %.1f' % resp)
            self.max_limit = resp

    def read_cur_pos(self):
        err_str = ''
        resp = 0
        res, resp, err_str = self.driver.TP(DEV, resp, err_str)
        if res != 0 or err_str != '':
            print(
                'Oops: Current Position: result=%d,response=%.2f,errString=\'%s\'' %
                (res, resp, err_str))
        else:
            print('Current Position = %.3f' % resp)
            self.cur_pos = resp

    def read_velocity(self):
        err_str = ''
        resp = 0
        res, resp, err_str = self.driver.VA_Get(DEV, resp, err_str)
        if res != 0 or err_str != '':
            print(
                'Oops: Current Velocity: result=%d,response=%.2f,errString=\'%s\'' %
                (res, resp, err_str))
        else:
            print('Current Velocity = %.3f' % resp)

    def read_controller_state(self, silent=False):
        err_str = ''
        resp = ''
        resp2 = ''
        res, resp, resp2, errString = self.driver.TS(DEV, resp, resp2, err_str)
        if res != 0 or err_str != '':
            print(
                'Oops: Read controller Err/State: result=%d,response=Err=\'%s\'/State=\'%s\',err_str=\'%s\'' %
                (res, resp, resp2, err_str))
        else:
            if not silent:
                print(
                    'Controller State = \'%s\', Error = \'%s\'' %
                    (resp2, resp))
            self.positioner_error = resp
            self.controller_state = resp2

    def exit_disable_state(self):
        err_str = ''
        state = 1  # enable
        res, err_str = self.driver.MM_Set(DEV, state, err_str)
        if res != 0 or err_str != '':
            print(
                'Oops: Leave Disable: result=%d,errString=\'%s\'' %
                (res, err_str))
        else:
            print('Exiting DISABLE state')

    def init_positioner(self):
        err_str = ''
        res, err_str = self.driver.OR(DEV, err_str)
        if res != 0 or err_str != '':
            print(
                'Oops: Find Home: result=%d,errString=\'%s\'' %
                (res, err_str))
        else:
            print('Finding Home')

    def set_homing_velocity(self, velocity):
        if velocity > MAX_VELOCITY:
            velocity = MAX_VELOCITY
        err_str = ''
        res, err_str = self.driver.OH_Set(DEV, velocity, err_str)
        if res != 0 or err_str != '':
            print(
                'Oops: Homing velocity: result=%d,errString=\'%s\'' %
                (res, err_str))
        else:
            print('Homing velocity set to %.1f mm/s' % velocity)

    def set_velocity(self, velocity):
        if velocity > MAX_VELOCITY:
            velocity = MAX_VELOCITY
        err_str = ''
        res, err_str = self.driver.VA_Set(DEV, velocity, err_str)
        if res != 0 or err_str != '':
            print(
                'Oops: Set velocity: result=%d,errString=\'%s\'' %
                (res, err_str))
        else:
            print('velocity Set to %.1f mm/s' % velocity)

    def move_relative(self, distance):
        if self.is_ready():
            err_str = ''
            res, err_str = self.driver.PR_Set(DEV, distance, err_str)
            if res != 0 or err_str != '':
                print(
                    'Oops: Move Relative: result=%d,errString=\'%s\'' %
                    (res, err_str))
            else:
                print('Moving Relative %.3f mm' % distance)

    def move_absolute(self, new_pos):
        if self.is_ready():
            err_str = ''
            res, err_str = self.driver.PA_Set(DEV, new_pos, err_str)
            if res != 0 or err_str != '':
                print(
                    'Oops: Move Absolute: result=%d,errString=\'%s\'' %
                    (res, err_str))
            else:
                print('Moving to position %.3f mm' % new_pos)

    def close(self):
        # note that closing the communication will NOT stop the motor!
        self.driver.CloseInstrument()


if __name__ == '__main__':
    ConexCC.dump_possible_states()
    conex_cc = ConexCC(velocity=0.5)
    conex_cc.initialize()
    ready = conex_cc.wait_for_ready(timeout=60)
    if ready:
        dist = input('Indicate absolute desired movement: ')
        conex_cc.move_absolute(dist)
        ready = conex_cc.wait_for_ready(timeout=60)
        if ready:
            dist = input('Indicate relative desired movement: ')
            conex_cc.move_relative(dist)
            ready = conex_cc.wait_for_ready(timeout=60)
            if ready:
                print('ok!')
            else:
                print('not ok 2!')
        else:
            print('not ok 1!')
        conex_cc.close()
    else:
        print('something went wrong')
