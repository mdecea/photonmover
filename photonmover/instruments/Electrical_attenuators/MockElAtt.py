import sys
sys.path.insert(0,'../..')
from Interfaces.ElectricalAttenuator import ElectricalAttenuator
from Interfaces.Instrument import Instrument


class MockElAtt(Instrument, ElectricalAttenuator):

    def __init__(self):
        super().__init__()

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to electrical attenuator')

    def close(self):
        print('Disconnecting variable electrical attenuator')

    def set_attenuation(self, attenuation):

        if attenuation > 80:
            print("Attenuation can't be higher than 80 dB. Attenuation not changed.")
        if attenuation < 0:
            print("Attenuation can't be lower than 0 dB. Attenuation not changed.")

        print('Setting attenuation to %.2f dB' % attenuation)
