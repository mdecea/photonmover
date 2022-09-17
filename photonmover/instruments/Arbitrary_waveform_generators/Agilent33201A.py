import sys
sys.path.insert(0, '../..')
import pyvisa as visa
from Interfaces.WaveformGenerator import WaveformGenerator
from Interfaces.Instrument import Instrument

GPIB_ADDR = "GPIB1::10::INSTR"  # GPIB adress


class Agilent33201A(Instrument, WaveformGenerator):
    """
    Code for controlling Keysight B2902A through GPIB
    """

    def __init__(self):
        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = None
        self.shape = 'SIN'


    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Agilent Waveform Generator')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDR, timeout=5000)
        except:
            raise ValueError('Cannot connect to the Keysight Source meter')

        self.init_func()

    def init_func(self):
        self.set_load(1e9)

    def close(self):
        print('Disconnecting Agilent Waveform Generator')
        self.gpib.close()

    def set_waveform(self, shape, freq, vpp, offset):
        """
        Generates the waveform with the specified parameters
        :param shape: shape of the waveform (sinusoidal, square...). "SIN", "SQU", "TRI", "RAMP", "NOIS", "DC"
        :param freq: frequency of the waveform (Hz)
        :param vpp: peak to peak voltage (V)
        :param offset: offset voltage (V)
        """

        if shape not in ["SIN", "SQU", "TRI", "RAMP", "NOIS", "DC"]:
            print("Specified shape not correct.")
            return

        if shape in ["SIN", "SQU"]:
            if freq > 15e6:
                print('Specified frequency is too high. Setting to maximum.')
                freq = 15e6
        else:
            if freq > 100e3:
                print('Specified frequency is too high. Setting to maximum.')
                freq = 100e3

        if vpp > 20:
            print('Vpp too high. Setting to maximum.')
            vpp = 20

        if vpp < 0.1:
            print('Vpp too low. Setting to minimum.')
            vpp = 0.1


        self.shape = shape
        self.gpib.write("APPL:%s %.2E, %.2f, %.3f" % (shape, freq, vpp, offset))

    def set_shape(self, shape):
        """
        Sets the waveform shape
        :param shape: "SIN", "SQU", "TRI", "RAMP", "NOIS", "DC"
        :return:
        """

        if shape not in ["SIN", "SQU", "TRI", "RAMP", "NOIS", "DC"]:
            print("Specified shape not correct.")
            return

        self.shape = shape

        self.gpib.write("FUNC:SHAP %s" % shape)

    def set_frequency(self, freq):
        """
        Sets the waveform frequency (Hz)
        :param freq:
        :return:
        """

        if self.shape in ["SIN", "SQU"]:
            if freq > 15e6:
                print('Specified frequency is too high. No change')
                return
        else:
            if freq > 100e3:
                print('Specified frequency is too high. No change')
                return

        self.gpib.write("FREQ %.2E" % freq)

    def set_duty_cycle(self, duty_cycle):
        """
        Sets the waveform duty_cycle (%). Only for square waves.
        :param duty_cycle:
        :return:
        """

        if self.shape != 'SQU':
            print('Duty cycle only for square functions')
            return

        self.gpib.write("PULS:DCYC %d" % duty_cycle)

    def set_load(self, load):
        """
        Sets the output load
        :param load: if 50, output load is set to 50 Ohms. Anything else sets it to high impedance.
        :return:
        """

        if load == 50:
            self.gpib.write("OUTP:LOAD 50")
        else:
            self.gpib.write("OUTP:LOAD INF")

    def set_voltage(self, amplitude, offset):
        """
        Sets the voltage settings. If any of them is None, they are not modified
        :param amplitude: peak to peak amplitude (V)
        :param offset: offset voltage (V)
        :return:
        """

        if amplitude is not None:
            if 0.1 < amplitude < 20:
                self.gpib.write("VOLT %.2f" % amplitude)
            else:
                print("Specified amplitude is too high. No change.")

        if offset is not None:
            self.gpib.write("VOLT:OFFS %.2f" % offset)


if __name__ == '__main__':
    awg = Agilent33201A()
    awg.initialize()

    awg.set_waveform('SQU', 1e3, 2, 0.5)

    awg.close()
