import pyvisa as visa
from photonmover.Interfaces.DigitalMultimeter import DigitalMultimeter
from photonmover.Interfaces.Instrument import Instrument


class Agilent34401A(Instrument, DigitalMultimeter):
    """
    Code for controlling Agilent 34401A-type digital multimeters.
    """

    def __init__(
        self,
        gpib_address="GPIB1::4::INSTR",
    ):
        super().__init__()

        self.gpib_address = gpib_address
        self.instr = None

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print("Opening connnection to Agilent DMM")

        rm = visa.ResourceManager()
        try:
            self.instr = rm.open_resource(
                self.gpib_address, timeout=6000
            )  # 2 min timeout
            print("Connected to Agilent DMM")
        except BaseException:
            raise ValueError("Cannot connect to the Agilent DMM")

    def close(self):
        print("Disconnecting Agilent DMM")
        self.instr.close()

    def identify(self):
        """
        Identify the instrument
        """
        return self.instr.query("*IDN?")

    def configure_measurement(self, range=5):
        # use maximum resolution
        self.instr.write("VOLTage:DC:NPLCycles 100")
        self.instr.write("CONFigure:VOLTage:DC {:f}, MAX".format(range))

    def get_voltage(self):
        """
        Queries the current voltage.

        """

        self.instr.write("READ?")
        volt = float(self.instr.read().strip("\n"))

        return volt


if __name__ == "__main__":
    dmm = Agilent34401A()
    dmm.initialize()
    dmm.identify()
    dmm.close()
