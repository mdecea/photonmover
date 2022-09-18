import pyvisa as visa
from photonmover.Interfaces.Instrument import Instrument
from photonmover.Interfaces.PowMeter import PowerMeter

GPIB_ADDR = "GPIB1::19::INSTR"  # VISA adress

# Power meter with GPIB interface


class HP8153A(Instrument, PowerMeter):

    def __init__(
            self,
            rec_channel=1,
            tap_channel=None,
            gpib_address=GPIB_ADDR):

        super().__init__()
        self.gpib_address = gpib_address
        self.rec_channel = rec_channel
        self.tap_channel = tap_channel

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """

        print('Opening connnection to HP8153A power meter')
        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDR, timeout=10000)
        except BaseException:
            raise ValueError('Cannot connect to HP8153A power meter')

        self.init_func()

    def init_func(self):

        # Set units to mW
        if self.tap_channel is not None:
            self.gpib.write("SENS%d:CHAN1:POW:UNIT 1" % self.tap_channel)
        if self.rec_channel is not None:
            self.gpib.write("SENS%d:CHAN1:POW:UNIT 1" % self.rec_channel)

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print('Closing connnection to HP8153A power meter')

        self.gpib.close()

    def init_id(self):
        self.gpib.write("*IDN?")
        self.id_str = self.gpib.read_raw().strip()

    def set_wavelength(self, wavelength):
        if self.tap_channel is not None:
            self.gpib.write("SENS%d::POW:WAV %.7ENM" %
                            (self.tap_channel, wavelength))
        if self.rec_channel is not None:
            self.gpib.write("SENS%d::POW:WAV %.7ENM" %
                            (self.rec_channel, wavelength))

    def get_powers(self):
        """
        Returns a list with the power measured in the tap port and in
        the through port. These ports will be specified in the init of
        the actual power_meter implementation.
        First element is the tap power, second the through power
        :return: A 2 element list with the power in W
        """

        if self.tap_channel is not None:
            self.gpib.write("INIT%d:IMM" % self.tap_channel)
            power_tap_string = self.gpib.query(
                "FETC%d:POW?" % self.tap_channel)
            try:
                power_tap = max(0.0, float(power_tap_string))
            except ValueError:
                power_tap = 0.0
        else:
            power_tap = 0.0

        if self.rec_channel is not None:
            self.gpib.write("INIT%d:IMM" % self.rec_channel)
            received_power_string = self.gpib.query(
                "FETC%d:POW?" % self.rec_channel)

            try:
                received_power = max(0.0, float(received_power_string))
            except ValueError:
                received_power = 0.0
        else:
            received_power = 0.0

        self.gpib.write("*CLS")

        return [power_tap, received_power]

    def set_integration_time(self, channel, int_time):
        self.gpib.write("SENS%d:POW:ATIME %.3fS" % (channel, int_time))

    def set_range(self, channel=None, power_range='AUTO'):
        """
        Sets the power range of the power meter in the specified channel
        :param channel: Channel of the power meter
        :param power_range: The power range. If 'AUTO', it is set to AUTOMATIC. Else, it is the range in
        dBm (from -70 to 10 dBm in steps of 10 dBm)
        :return:
        """

        if channel is None:
            channel = self.rec_channel
        if power_range == 'AUTO':
            self.gpib.write("SENS%d:POW:RANG:AUTO 1" % channel)

        else:
            if power_range <= -70:
                power_range = -70
            elif power_range <= -60:
                power_range = -60
            elif power_range <= -50:
                power_range = -50
            elif power_range <= -40:
                power_range = -40
            elif power_range <= -30:
                power_range = -30
            elif power_range <= -20:
                power_range = -20
            elif power_range <= -10:
                power_range = -10
            elif power_range <= 0:
                power_range = 0
            else:
                power_range = 10

            self.gpib.write("SENS%d:POW:RANG:AUTO 0" % channel)
            self.gpib.write(
                "SENS%d:POW:RANG %dDBM" %
                (channel, int(power_range)))


if __name__ == '__main__':
    pm = HP8153A(rec_channel=2)
    pm.initialize()
    print(pm.get_powers())
    pm.close()
