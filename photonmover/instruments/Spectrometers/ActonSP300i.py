from photonmover.Interfaces.Instrument import Instrument
import serial
import time
import numpy as np

COM_ADDRESS = 'COM2'


class ActonSP300i(Instrument):

    def __init__(self):
        super().__init__()

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print("Initializing connection to Tunable Filter")
        self.ser = serial.Serial(COM_ADDRESS, timeout=3)

    def close(self):
        """
        Closes the instrument
        :return:
        """
        print("Closing connection to Tunable Filter")
        self.ser.close()

    def set_wavelength(self, wavelength):
        """
        Rotates the grating to a specific wavelength
        :return:
        """

        message = '%.3f GOTO' % wavelength

        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        print(self.ser.read())
        print("Setting grating wavelength to %d nm" % wavelength)

    def do_wl_sweep(self, start_wav, stop_wav, sweep_rate):
        """
        Rotates the grating at a constant speed to do a sweep
        sweep_rate is in nm/min
        :return:
        """

        print("Setting sweep to start: %.2f nm; stop: %.2f nm, rate = %.2f nm/min"
              % (start_wav, stop_wav, num_wav, sweep_rate))

        # Go to start wavelenth
        self.set_wavelength(start_wav)

        # Set sweep rate
        message = '%.2f NM/MIN' % sweep_rate

        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        print(self.ser.read())

        # Start the sweep and specify the end wavelength (at the same time)
        message = '%.3f NM' % stop_wav
        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        print(self.ser.read())

        # Wait for the sweep to be done
        sweep_time = (np.abs((stop_wav-start_wav))/sweep_rate)*60
        time.sleep(sweep_time*1.1)

    def set_diverter_mirror(self, pos):
        """
        Sets the mirror at the output of the spectrometer. Pos is either:
        - FRONT: positions the beam to the front port
        - SIDE: positions the beam to the side port
        """

        if pos not in ['FRONT', 'SIDE']:
            print('Specified mirror position is not supported. DOing nothing.')
            return
        
        message = '%s' % pos
        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        print(self.ser.read())
        print("Setting spectrometer mirror to %s" % pos)


if __name__ == '__main__':
    sp = ActonSP300i
    sp.initialize()
    while True:
        wav = input('Enter desired wavelength (nm): ')
        sp.set_wavelength(float(wav))
        print('Wavelength set')
    sp.close()

