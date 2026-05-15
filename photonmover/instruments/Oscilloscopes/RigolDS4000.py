import sys
import pyvisa as visa
import numpy as np
import time
import csv
from photonmover.Interfaces.Instrument import Instrument
from tqdm.notebook import tqdm as tqdm_notebook
from enum import Enum
sys.path.insert(0, '../..')

MANUFACTURER_ID = 0x1AB1

class ScopeTypes(Enum):
    """ Container class for scope model definitions """
    # DS1054Z = 0x04CE
    DS4024 = 0x04B1

class RigolDS4000(Instrument):
    """
    Code for controlling Rigol DS4000 Oscilloscope via USB connection.
    INPUTS:
        * **instr_address** (str): USB address. If `None`, the instrument will
                            not connect, but methods exist to find available
                            DS4000 scopes.
    """

    def __init__(self, instr_address=None):
        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = None
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
            print('Opening connnection to Rigol Oscilloscope')

            try:
                self.gpib = self.rm.open_resource(
                    self.instr_address, timeout=10000)
                self.is_initialized = True
            except ConnectionError:
                raise ConnectionError('Cannot connect to Rigol Oscilloscope')

    def close(self):
        print('Disconnecting Rigol Oscilloscope')
        self.gpib.close()

    def find_address(self):
        """
        Finds addresses of connected Rigol oscilloscopes.
        If only one address exists, it automatically applies that address to
        the the invoking class instance. This overrides provided addresses.
        """
        model_string = ' '
        for spec in ScopeTypes:
            model_string += '(VI_ATTR_MODEL_CODE==0x{:04X}) || '.format(
                spec.value)
            model_string = model_string.rstrip(' || ')
            search_string = "USB?*?{{VI_ATTR_MANF_ID==0x{:04X} && ({})}}".format(
                MANUFACTURER_ID, model_string)

        try:
            scope_list = self.rm.list_resources(search_string)
        except Warning:
            scope_list = []
            raise Warning("No connected oscilloscopes were found")

        if len(scope_list) == 1:  # Only one relevant scope found, set as address
            print("Only found one connected oscilloscope, applying this address.")
            print("Scope address: {}".format(scope_list[0]))
            self._set_address(instr_address=scope_list[0])

    def _set_address(self, instr_address) -> None:
        """
        Set the USB interfacing address. Only works on un-initialized instantiations of the class.
        """
        if not self.is_initialized:
            self.instr_address = instr_address
        else:
            print("Cannot assign a new address to an initialized instrument.")

    def autoscale(self):
        self.gpib.write(":AUT")

    def clear(self):
        """
        Clears all the waveforms in the display
        :return:
        """
        self.gpib.write(":CLE")

    def run(self):
        """
        Start the oscilloscope
        :return:
        """
        self.gpib.write(":RUN")

    def stop(self):
        """
        Stop the oscilloscope
        :return:
        """
        self.gpib.write(":STOP")

    def single(self):
        """
        Single acquisition
        :return:
        """
        self.gpib.write(":SING")

    def force_trigger(self):
        """
        Force a trigger
        :return:
        """
        self.gpib.write(":TFOR")

    def set_acq_averages(self, num_avg):
        """
        Sets averaging to the specified number
        :param num_avg:
        :return:
        """

        if num_avg > 8192:
            print("Specified averages are too high. Setting to maximum.")
            num_avg = 8192

        if num_avg % 2 != 0:
            print(
                "The number of averages has to be a power of 2. Setting to the closest.")
            num_avg = round(np.log2(num_avg))

        self.gpib.write("ACQ:AVER %d" % num_avg)

    def set_acq_type(self, mode):
        """
        Sets the acquisition type for the oscilloscope
        :param mode: "NORM", "AVER", "PEAK", "HRES"
        :return:
        """

        if mode not in ["NORM", "AVER", "PEAK", "HRES"]:
            print("Acquisition mode not supported. Doing nothing.")
            return

        self.gpib.write(":ACQ:TYPE %s" % mode)

    def set_channel_bw(self, channel, bw):
        """
        Sets the bandwidth limit for the specified channel
        :param channel: 1, 2, 3 or 4
        :param bw: OFF, 20M, 100M, or 200M
        :return:
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        if bw not in ['OFF', '20M', '100M', '200M']:
            print("Bandwidth option not correct. Doing nothing")
            return

        self.gpib.write(f":CHAN{channel:d}:BWL {bw}")

    def set_channel_coupling_type(self, channel, coupling):
        """
        Set the coupling type (AC, DC or GND)
        :param channel: 1, 2, 3 or 4
        :param coupling: "AC", "DC", "GND"
        :return:
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        if coupling not in ["AC", "DC", "GND"]:
            print("Coupling option not correct. Doing nothing")
            return

        self.gpib.write(":CHAN%d:COUP %s" % (channel, coupling))

    def set_channel_probe(self, channel, atten):
        """
        Sets the probe ration for specified channel
        :param channel (int): 1, 2, 3 or 4
        :param atten   (float): 0.01, 0.02, 0.05, ... 100, 200, 500, 1000
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        if atten not in [0.01, 0.02, 0.05, 0.1, 0.2, 0.5,
                         1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]:
            print("Probe attenuation not correct. Doing nothing.")
            return

        self.gpib.write(":CHANnel%d:PROBe %.7f" % (channel, atten))

    def get_probe(self, channel):
        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        return self.gpib.query_ascii_values(":CHANnel%d:PROBe?" % channel)[0]

    def set_channel_display(self, channel, on):
        """
        Turns on or off the display of the specified channel
        :param channel: 1, 2, 3 or 4
        :param on: 0 for off, 1 for on
        :return:
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        if on not in [0, 1]:
            print("Display option not correct. Doing nothing")
            return

        self.gpib.write(":CHAN%d:DISP %d" % (channel, on))

    def get_channel_displays(self):
        """
        Checks which channels are activated.
        Returns list of booleans.
        """
        return [bool(self.gpib.query_ascii_values(":CHANnel{:d}:DISPlay?".format(x))[0]) for x in [1, 2, 3, 4]]

    def set_channel_invert(self, channel, invert):
        """
        Inverts the signal of the specified channel
        :param channel: 1, 2, 3 or 4
        :param invert: 0 for not inverted, 1 for inverted
        :return:
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        if invert not in [0, 1]:
            print("Invert option not correct. Doing nothing")
            return

        self.gpib.write(":CHAN%d:INV %d" % (channel, invert))

    def set_channel_impedance(self, channel, imp):
        """
        Sets the input impedance for the specified channel
        :param channel: 1, 2, 3 or 4
        :param imp: "OMEG" for 1Mohm and "FIFTy" for 50Ohm
        :return:
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        if imp not in ["FIFTy", "OMEG"]:
            print("Impedance option not correct. Doing nothing")
            return

        self.gpib.write(":CHAN%d:IMP %s" % (channel, imp))

    def set_channel_vernier(self, channel, on):
        """
        Turns on or off the vernier of the specified channel
        :param channel: 1, 2, 3 or 4
        :param on: 0 for off, 1 for on
        :return:
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        if on not in [0, 1]:
            print("Vernier option not correct. Doing nothing")
            return

        self.gpib.write(":CHAN%d:VERN %d" % (channel, on))

    def get_channel_vernier(self, channel):
        """
        Queries whether the vernier of the specified channel is on or off
        :param channel: 1, 2, 3 or 4
        :return: 0 for off, 1 for on
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        return self.gpib.query_ascii_values(":CHAN%d:VERN?" % channel)[0]

    def set_channel_vertical_scale(self, channel, scale):
        """
        Sets the vertical scale of the specified analog channel. 
        The unit is related to the current amplitude unit of the specified analog channel. 
        The default unit is V/div.

        When the input impedance is 50Ohm and the probe ratio is 1X,
        the value of <scale> is from 1 mV/div to 1 V/div.

        When the input impedance is 1 MOhm and the probe ratio is 1X,
        the value of <scale> is from 1 mV/div to 5 V/div.

        :param channel: 1, 2, 3 or 4
        :param scale: (float) vertical scale of the specified analog channel (V/div)
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        self.gpib.write(":CHAN%d:SCAL %.7f" % (channel, scale))

    def get_channel_vertical_scale(self, channel):
        """
        Queries the vertical scale of the specified analog channel.
        The unit is related to the current amplitude unit of the specified analog channel.
        The default unit is V/div.

        When the input impedance is 50Ohm and the probe ratio is 1X,
        the value of <scale> is from 1 mV/div to 1 V/div.

        When the input impedance is 1 MOhm and the probe ratio is 1X,
        the value of <scale> is from 1 mV/div to 5 V/div.

        :param channel: 1, 2, 3 or 4
        :return: (float) vertical scale of the specified analog channel (V/div)
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        return self.gpib.query_ascii_values(":CHAN%d:SCAL?" % channel)[0]

    def set_channel_offset(self, channel, offset):
        """
        Sets the vertical position of the specified analog channel. 
        The unit is related to the current amplitude unit of the specified analog channel. 
        The default unit is V.

        Returned offset is related to current input impedance, probe ratio, and vertical scale.
        When the input impedance is 50Ohm and the probe ratio is 1X:
            1 mV/div to 124 mV/div: -1.2 V to +1.2 V
            125 mV/div to 1 V/div: -12 V to +12 V
        
        When the input impedance is 1 MOhm and the probe ratio is 1X:
            1 mV/div to 229 mV/div: -2 V to +2 V
            230 mV/div to 5 V/div: -40 V to +40 V

        :param channel: 1, 2, 3 or 4
        :param offset: (float) vertical position of the specified analog channel

        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return None
        
        self.gpib.write(":CHAN%d:OFFS %.7f" % (channel, offset))

    def get_channel_offset(self, channel):
        """
        Queries the vertical position of the specified analog channel. 
        The unit is related to the current amplitude unit of the specified analog channel. 
        The default unit is V.

        Returned offset is related to current input impedance, probe ratio, and vertical scale.
        When the input impedance is 50Ohm and the probe ratio is 1X:
            1 mV/div to 124 mV/div: -1.2 V to +1.2 V
            125 mV/div to 1 V/div: -12 V to +12 V
        
        When the input impedance is 1 MOhm and the probe ratio is 1X:
            1 mV/div to 229 mV/div: -2 V to +2 V
            230 mV/div to 5 V/div: -40 V to +40 V

        :param channel: 1, 2, 3 or 4

        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return None
        
        return self.gpib.query_ascii_values(":CHAN%d:OFFS?" % channel)[0]

    def set_horizontal_scale(self, scale):
        """
        Sets the horizontal scale in s/div
        :param scale:
        :return:
        """
        self.gpib.write(":TIM:SCAL %.7f" % scale)

    def get_horizontal_scale(self):
        """
        Returns the horizontal scale in sec/div
        """
        return self.gpib.query_ascii_values(":TIM:SCAL?")[0]

    def set_trigger(self, coupling, trig_number, level, mode='EDGE', source='EXT', slope='POS', holdoff=None, nreject=None):
        """
        Sets the trigger with the specified parameters.
        :param coupling: Coupling type. One of "AC", "DC", "LFR", "HFR"
            DC: allows DC and AC components to pass the trigger path.
            AC: blocks all the DC components and attenuates signals below 8 Hz.
            LFReject: blocks the DC components and rejects the low frequency components below 5 kHz.
            HFReject: rejects the high frequency components above 50 kHz.
        
        :param trig_number: Sets when the trigger fires. One of "AUTO", "NORM", "SING"
            AUTO: indicates the auto trigger. In this trigger mode, if the specified trigger condition
             is not found, the oscilloscope will force a trigger and data acquisition to display the waveform.
            NORMal: indicates the normal trigger. In this trigger mode, only when the specified trigger condition is
             found, will the oscilloscope perform a trigger and data acquisition.
            SINGle: indicates the single trigger. In this trigger mode, only when the specified trigger condition is
             found, will the oscilloscope perform a trigger and data acquisition, and then stop.
        
        :param level: level for the trigger to fire
        :param mode: Trigger mode. "EDGE", "PULSE", "RUNT", "NEDG", "SLOP", "VID", "PATT", "RS232", "IIC", "SPI", "CAN", "FLEX", "USB"
        :param source: Trigger source. "CHAN1", "CHAN2", "CHAN3", "CHAN4", "EXT", "EXT5", "ACLine"
        :param slope: Trigger slope. "POS" for positive, "NEG" for negative, "RFALI" for triggering at crossing point 
          where either rising or falling edge of input signal meets preset trigger level.

        :param holdoff: holdoff time for the trigger
        :param nreject: Turn noise reject on or off. 0 for off, 1 for on
        """

        if coupling in ["AC", "DC", "LFR", "HFR"]:
            self.gpib.write(":TRIG:COUP %s" % coupling)

        if trig_number in ["AUTO", "NORM", "SING"]:
            self.gpib.write(":TRIG:SWE %s" % trig_number)

        if mode in ["EDGE", "PULSE", "RUNT", "NEDG", "SLOP", "VID", "PATT", "RS232", "IIC", "SPI", "CAN", "FLEX", "USB"]:
            self.gpib.write(":TRIG:MODE %s" % mode)

        if holdoff is not None:
            self.gpib.write(":TRIG:HOLD %.7f" % holdoff)

        if nreject is not None:
            self.gpib.write(":TRIG:NREJ %d" % nreject)

        if mode == "EDGE" and source in ["CHAN1", "CHAN2", "CHAN3", "CHAN4", "EXT", "EXT5", "ACLine"]:
            self.gpib.write(":TRIG:EDG:SOUR %s" % source)
        if mode == "EDGE" and slope in ["POS", "NEG", "RFALI"]:
            self.gpib.write(":TRIG:EDG:SLOP %s" % slope)
        if mode == "EDGE" and level is not None:
            self.gpib.write(":TRIG:EDG:LEV %.4f" % level)

    def get_trigger_status(self):
        """
        Queries the trigger status. Returns one of "TD", "WAIT", "STOP", "RUN"
        """
        return self.gpib.query(":TRIG:STAT?").strip()

    def set_memory_depth(self, mdepth):
        """
        Sets the memory depth, based on the number of enabled channels.
        :param mdepth: (int) or (str) memory depth. 
        For "AUTO" oscilloscope chooses this based on sampling rate and number of enabled channels.
        """
        num_chans_enabled = np.sum(self.get_channel_displays())

        self.run()

        if mdepth == "AUTO":
            self.gpib.write(':ACQ:MDEP AUTO')
        else:
            if num_chans_enabled == 1:
                if mdepth not in [int(14e3), int(14e4), int(14e5), int(14e6), int(14e7)]: # 14k, 140k, 1.4M, 14M, 140M
                    print("Specified memory depth not supported for 1 enabled channel. Doing nothing.")
                    return
                self.gpib.write(':ACQ:MDEP %d' % mdepth)
            else:
                if mdepth not in [int(7e3), int(7e4), int(7e5), int(7e6), int(7e7)]: # 7k, 70k, 700k, 7M, 70M
                    print("Specified memory depth not supported for more than 1 enabled channel. Doing nothing.")
                    return
                self.gpib.write(':ACQ:MDEP %d' % mdepth)

    def get_memory_depth(self):
        """
        Queries the current memory depth setting.
        """
        self.gpib.write(":ACQ:MDEP?")
        mdepth = int(self.gpib.read().rstrip('\n'))

        return mdepth

    def get_sampling_rate(self):
        """
        Returns the sampling rate (Sa/s)
        """
        return self.gpib.query_ascii_values("ACQuire:SRATe?")[0]

    # TODO - have not debugged this function!
    def read_waveform(self, channels, file_name=None):
        """
        Reads the display waveform data in the specified channels. This is limited
        to a constant number of points (1400), independent of the number of samples taken internally.
        Use `read_memory_buffer()` to collect all data.

        Always reads all specified channels, even when channels are deactivated
        on the instrument front panel. Signals for deactivated channels are
        ~0 (usually 1e-8).

        :param channels: list with the channels whose waveform we want to obtain.
        :param file_name: if specified, it will save the data with the specified file name. Do not include the ".csv".
        :return: 2 lists, each with n elemnts, where n is the number of channels.
                List 1: [preamble_channel1, preamble_channel2, ...]
                List 2: [(channel1_time_data, channel1_signal_data), (channel2_time_data, channel2_signal_data), ...]
        """

        all_preambles = []
        all_waveforms = []

        # Set waveform reading mode to normal
        self.gpib.write(":WAV:MODE NORM")

        # Set to send ascii
        # read data as comma-separated list of voltages in scientific notation
        self.gpib.write(":WAV:FORM ASCII")

        for c in channels:
            if c not in [1, 2, 3, 4]:
                print("Specified channel not correct. Skipping it")
                continue

            # Choose source
            self.gpib.write(":WAV:SOUR CHAN%d" % c)
            self.gpib.write("WAV:DATA?")
            data = self.gpib.read_raw()
            raw_data = data[11:]
            '''
            The strings of the waveform data consists of TMC data block header 
            and the waveform data. The format of the TMC data block header is #9XXXXXXXXX, 
            and the 9-digit data (XXXXXXXXX) following it denotes the length of the data stream 
            (in bytes). The TMC data block header is followed by the waveform data. 
            
            "ASCii" format: The query directly returns the actual voltage value of each waveform 
            point in scientific notation; and the voltage values are separated by commas.
            '''

            # Convert ASCII text data values to floats
            wav_data_str = (str(raw_data)[2:-3]).split(',')
            wav_data = [float(i) for i in wav_data_str]

            preamble = self.gpib.query_ascii_values("WAV:PRE?")

            # Generate time vectors
            wave_time = list(
                np.arange(0, int(preamble[2]))*preamble[4] + preamble[5])

            # Save the data if necessary. Each channel will be stored in a different file
            if file_name is not None:
                file_name_chan = file_name + "_channel_" + str(c) + ".csv"
                with open(file_name_chan, 'w+') as csvfile:
                    writer = csv.writer(csvfile)
                    writer.writerow(preamble)
                    writer.writerow(wav_data)

            all_preambles.append(preamble)
            all_waveforms.append((wave_time, wav_data))

        return all_preambles, all_waveforms

    def read_memory_buffer(self, channel):
        """
        Read data from internal memory for specified channel.
        Reading the memory of this oscilloscope looks to be a little different than the DS1000 series.
        Following the exact procedure from the programming guide. 
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return None, None, None 
        #     raise Warning("Channel not correct. Doing nothing.")
        #     return None, None, None

        # if self.get_memory_depth() == "AUTO":
        #     raise Warning("The 'AUTO' memory depth option may not be supported when"
        #                   + " reading the memory buffer, please set a manual value?")

        self.stop()

        self.gpib.write(":WAVeform:SOURce CHANnel%d" % channel)
        self.gpib.write(":WAV:MODE RAW")
        self.gpib.write(":WAV:STAR")

        wp = self.gpib.query_ascii_values(":WAVeform:PREamble?")
        wp_dict = {
            'format': wp[0],  # 0 (BYTE), 1 (WORD) or 2 (ASC)
            'type': wp[1],  # 0 (NORMal), 1 (MAXimum) or 2 (RAW)
            'points': int(wp[2]),  # integer between 1 and 12000000.
            'count': wp[3],
            'xincrement': wp[4],
            'xorigin': wp[5],
            'xreference': wp[6],
            'yincrement': wp[7],
            'yorigin': wp[8],
            'yreference': wp[9],
        }

        x0 = wp_dict['xorigin']
        xref = wp_dict['xreference']
        xinc = wp_dict['xincrement']

        N_points_to_read = self.get_memory_depth()
        data = np.zeros(N_points_to_read)
        curr_idx = 0

        self.gpib.write(":WAVeform:STARt 1")
        self.gpib.write(":WAVeform:STOP %d" % N_points_to_read)

        self.gpib.write("WAV:POIN %d" % N_points_to_read)

        self.gpib.write(":WAV:RES")
        self.gpib.write(":WAV:BEG")
        while self.gpib.query(":WAV:STAT?").split(",")[0] != 'IDLE':
            chunk = np.array(self.gpib.query_binary_values(":WAV:DATA?", datatype='B', header_fmt='ieee'))
            data[curr_idx:curr_idx + len(chunk)] = chunk
            curr_idx += len(chunk)
            time.sleep(0.1)

        # Now, IDLE was returned
        if curr_idx == N_points_to_read:
            print("Successfully read all points from memory buffer.")
        else:
            chunk = np.array(self.gpib.query_binary_values(":WAV:DATA?", datatype='B', header_fmt='ieee'))
            data[curr_idx:curr_idx + len(chunk)] = chunk
            curr_idx += len(chunk)
            assert curr_idx == N_points_to_read, "Did not read the expected number of points from memory buffer."   

            self.gpib.write(":WAV:END")
            time.sleep(0.1)

    
        # Adding x0 + xref rather than subtracting appears to give correct timing array
        t_array = np.arange(0, xinc * len(data), xinc) + x0 + xref

        return data, t_array, wp_dict


if __name__ == '__main__':

    scope = RigolDS4000()
    addresses = scope.find_address()
    scope.initialize()

    scope.close()
