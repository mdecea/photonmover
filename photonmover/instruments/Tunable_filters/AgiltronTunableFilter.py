from photonmover.Interfaces.TunableFilter import TunableFilter
from photonmover.Interfaces.Instrument import Instrument
import serial
import time

COM_ADDRESS = 'COM4'


class AgiltronTunableFilter(TunableFilter, Instrument):

    def __init__(self, com_address=COM_ADDRESS):
        super().__init__()
        self.com_address = com_address

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print("Initializing connection to Tunable Filter")
        self.ser = serial.Serial(self.com_address, timeout=3)

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print("Closing connection to Tunable Filter")
        self.ser.close()

    def set_wavelength(self, wavelength):
        """
        Sets the wavelength to the specified value (in nm)
        :return:
        """
        if wavelength < 1520 or wavelength > 1598:
            print(
                'Tunable filter cannot cover this wavelength. Tunable filter wavelength not changed.')
            return

        message = 'C%d,' % wavelength

        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        print(self.ser.read())
        print("Setting filter wavelength to %d nm" % wavelength)

    def do_sweep(self, start_wav, stop_wav, num_wav, dwell_time):
        """
        Sets the sweep for the tunable filter
        :return:
        """

        print(
            "Setting filter sweep to start: %.2f nm; stop: %.2f nm, num: %d, time = %.2f ms" %
            (start_wav, stop_wav, num_wav, dwell_time))

        span = stop_wav - start_wav

        if span > 30:
            print(
                ' The span for the tunable filter seep is too high. Limiting it ot the maximum of 30 nm.')
            stop_wav = start_wav + 30
            span = 30

        # Start wavelenth
        message = 'L%d,' % start_wav
        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        print(self.ser.read(5).encode('ascii'))

        # End wavelength
        message = 'H%d,' % stop_wav
        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        print(self.ser.read(5).encode('ascii'))

        # Scan pause at each wavelength
        if dwell_time < 1 or dwell_time > 30:
            print(
                'Dwell time has to be between 1 and 30 seconds. Setting it to 1 second.')
            dwell_time = 1
        message = 'T%d,' % dwell_time
        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        print(self.ser.read(5).encode('ascii'))

        # Start sweep
        message = 'S%d,' % span
        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        time.sleep(span * dwell_time)
        print(self.ser.read(5).encode('ascii'))


if __name__ == '__main__':
    tf = AgiltronTunableFilter()
    tf.initialize()
    while True:
        wav = input('Enter desired wavelength (nm): ')
        tf.set_wavelength(float(wav))
        print('Wavelength set')
    tf.close()
