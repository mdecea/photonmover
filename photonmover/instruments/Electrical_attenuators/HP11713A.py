import numpy as np
import pyvisa as visa
import time
from photonmover.Interfaces.ElectricalAttenuator import ElectricalAttenuator
from photonmover.Interfaces.Instrument import Instrument

GPIB_ADDR = "GPIB1::14::INSTR"  # GPIB adress


fine_attenuation_channel = 'X'  # This channel has 1 dB attenuation steps
fine_channel_strings = {0: "B1234", 1: "A1B234", 2: "A2B134", 3: "A12B34",
                        4: "A4B123", 5: "A14B23", 6: "A24B13", 7: "A124B3",
                        8: "A34B12", 9: "A134B2", 10: "A234B1", 11: "A1234"}

coarse_attenuation_channel = 'Y'  # This channel has 10 dB attenuation steps
coarse_channel_strings = {0: "B567", 10: "A5B67", 20: "A6B57", 30: "A56B7",
                          40: "A7B56", 50: "A67B5", 60: "A67B5", 70: "A567"}


class HP11713A(Instrument, ElectricalAttenuator):
    """
    Code for controlling HP11713A variable electrical attenuator through GPIB
    """

    def __init__(self):
        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = None
        self.current_fine_att = 0
        self.current_coarse_att = 0

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to HP electrical attenuator')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDR, timeout=5000)
        except BaseException:
            raise ValueError(
                'Cannot connect to the HP variable electrical attenuator')

    def close(self):
        print('Disconnecting HP variable electrical attenuator')
        self.gpib.close()

    def set_attenuation(self, attenuation):

        if attenuation > 80:
            print("Attenuation can't be higher than 80 dB. Attenuation not changed.")
        if attenuation < 0:
            print("Attenuation can't be lower than 0 dB. Attenuation not changed.")

        # Calculate the attenuation that each channel has to apply
        fine_att = int(attenuation % 10)
        coarse_att = int(attenuation - fine_att)

        # Get the data string to send for each attenuation
        fine_data_str = self.construct_data_string(fine_att, 'fine')
        coarse_data_str = self.construct_data_string(coarse_att, 'coarse')

        # Find out which change has to be made first to avoid the amplitude being higher than what it was set to or
        # what it will be set to
        if fine_att > self.current_fine_att:
            #  First fine attenuation and then coarse
            if fine_data_str is not None:
                self.gpib.write(fine_data_str)
                self.current_fine_att = fine_att
            time.sleep(0.5)
            if coarse_data_str is not None:
                self.gpib.write(coarse_data_str)
                self.current_coarse_att = coarse_att
        else:
            #  First coarse attenuation and then fine
            if coarse_data_str is not None:
                self.gpib.write(coarse_data_str)
                self.current_coarse_att = coarse_att
            time.sleep(0.5)
            if fine_data_str is not None:
                self.gpib.write(fine_data_str)
                self.current_fine_att = fine_att

        print('Setting attenuation to %.2f dB' % attenuation)

    def construct_data_string(self, attenuation, channel):
        """
        Returns the data string to send to the attenuator based on the channel and
        the attenuation (strings taken from the manual)
        :param attenuation: Attenuation in dB
        :param channel: Controller channel to which the attenuator is connected (X or Y)
        :return: The string to send
        """

        if channel == 'coarse':
            return coarse_channel_strings[attenuation]
        elif channel == 'fine':
            return fine_channel_strings[attenuation]
        else:
            print('Specified channel is not correct')
            return None


if __name__ == '__main__':
    hp = HP11713A()
    hp.initialize()
    att = ''
    while att != 'q':
        att = input('Desired attenuation (dB): ')
        hp.set_attenuation(float(att))
    hp.close()
