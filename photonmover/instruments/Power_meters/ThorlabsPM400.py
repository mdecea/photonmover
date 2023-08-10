import sys
import pyvisa as visa
import time
from photonmover.Interfaces.Instrument import Instrument
from photonmover.Interfaces.PowMeter import PowerMeter
from enum import Enum

sys.path.insert(0, "../..")


MANUFACTURER_ID = 0x1313


class PowerMeterTypes(Enum):
    """Container class for power meter model definitions"""

    PM400 = 0x8075


class ThorlabsPM400(Instrument, PowerMeter):
    """
    Code for controlling a Thorlabs PM400 power meter through VISA.
    INPUTS:
        * **instr_address** (str): USB address. If `None`, the instrument will
                            not connect, but methods exist to find available
                            DG4000 signal generators.
    """

    def __init__(self, instr_address=None):
        super().__init__()

        # It is good practice to initialize variables in init
        self.instr = None
        self.instr_address = instr_address

        self.rm = visa.ResourceManager()
        self.is_initialized = False

    def initialize(self, override_address=None):
        """
        Initializes the instrument. Optionally override the address provided
        during class instantiation.
        :return:
        """
        if override_address is not None:  # Assign new instrument address
            self._set_address(instr_address=override_address)

        if self.instr_address is None:
            print("No instrument address was provided, cannot initialize")
            return
        else:
            print("Opening connnection to Thorlabs Power Meter PM400")

            try:
                self.instr = self.rm.open_resource(self.instr_address, timeout=10000)
                self.is_initialized = True
            except ConnectionError:
                raise ConnectionError("Cannot connect to Thorlabs Power Meter PM400")

        self.instr.read_termination = "\n"
        self._initialize_params()

    def close(self):
        print("Disconnecting Thorlabs Power Meter PM400")
        self.instr.close()

    def find_address(self):
        """
        Finds addresses of connected Thorlabs Power Meter PM400s.
        If only one address exists, it automatically applies that address to
        the the invoking class instance. This overrides provided addresses.
        """
        model_string = " "
        for spec in PowerMeterTypes:
            model_string += "(VI_ATTR_MODEL_CODE==0x{:04X}) || ".format(spec.value)
            model_string = model_string.rstrip(" || ")
            search_string = "USB?*?{{VI_ATTR_MANF_ID==0x{:04X} && ({})}}".format(
                MANUFACTURER_ID, model_string
            )

        try:
            instr_list = self.rm.list_resources(search_string)
        except Warning:
            instr_list = []
            raise Warning("No connected signal generators were found")

        if (
            len(instr_list) == 1
        ):  # Only one relevant signal generator found, set as address
            print("Only found one applicable instrument, using this address.")
            print("Instrument address: {}".format(instr_list[0]))
            self._set_address(instr_address=instr_list[0])

    def _set_address(self, instr_address) -> None:
        """
        Set the USB interfacing address. Only works on un-initialized instantiations of the class.
        """
        if not self.is_initialized:
            self.instr_address = instr_address
        else:
            print("Cannot assign a new address to an initialized instrument.")

    def _initialize_params(self):
        """
        Set default parameters and options.
        """
        init_commands = [
            "*RST",  # Reset to defaults
            "SENSE:POWER:UNIT DBM",  # Set dBm as default return unit
            "SENSe:CORRection:WAVelength 1348",  # Choose a default wavelength
            "SENSE:CORRECTION:COLLECT:ZERO:STATE 0",  # Do not use background zeroing
            "CONFIGURE:POWER",  # Return scaled power
        ]

        for cmd in init_commands:
            self.instr.write(cmd)
            time.sleep(0.2)

    def set_wavelength(self, wavelength):
        """
        Set the correction wavelength to the specified value (in nm)
        :return:
        """
        self.instr.write("SENSe:CORRection:WAVelength {:d}".format(wavelength))

    def set_power_unit(self, unit="W"):
        """
        Choose which unit to measure power in. Can be 'W' for watts or
        'DBM' for dBm.
        """
        if unit.lower() in ["w", "dbm"]:
            self.instr.write(
                "SENSE:POWER:UNIT {:s}".format(unit)
            )  # Set dBm as default return unit
        else:
            return ValueError(
                "Invalid input given for power meter unit. Must be 'W' or 'DBM' "
            )

    def get_powers(self):
        """
        Returns the measured power, in system units (modified with `set_power_unit`)
        :return:
        """
        pwr = float(self.instr.query("READ?"))
        return pwr

    def set_range(self, channel, range):
        """
        Set the power range of the specified channel to the specified number
        :return:
        """
        pass

    def get_id(self):
        return self.instr.query("*IDN?")


if __name__ == "__main__":
    pm = ThorlabsPM400()
    addresses = pm.find_address()
    pm.initialize(override_address=addresses[0])

    pm.close()
