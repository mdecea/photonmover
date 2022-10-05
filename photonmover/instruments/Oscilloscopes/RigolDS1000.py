import sys
import pyvisa as visa
import numpy as np
import time
import csv
from photonmover.Interfaces.Instrument import Instrument
from enum import Enum
sys.path.insert(0, '../..')

from tqdm.notebook import tqdm as tqdm_notebook


MANUFACTURER_ID = 0x1AB1


class ScopeTypes(Enum):
    """ Container class for scope model definitions """
    DS1054Z = 0x04CE

# TODO - implement probe function ":CHANnel<n>:PROBe"
# for now manually set all oscillscope channels to 1x probe

class RigolDS1000(Instrument):
    """
    Code for controlling Rigol DS1000 Oscilloscope via USB connection.
    INPUTS:
        * **instr_address** (str): USB address. If `None`, the instrument will
                            not connect, but methods exist to find available
                            DS1000Z scopes.
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

        if num_avg > 1024:
            print("Specified averages are too high. Setting to maximum.")
            num_avg = 1024

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

    def set_bw(self, channel, bw):
        """
        Sets the bandwidth limit for the specified channel
        :param channel: 1, 2, 3 or 4
        :param bw: 0 if OFF, 1 if 20MHz bw limit
        :return:
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        if bw not in [0, 1]:
            print("Bandwidth option not correct. Doing nothing")
            return

        if bw == 0:
            self.gpib.write(":CHAN%d:BWL OFF" % channel)

        if bw == 1:
            self.gpib.write(":CHAN%d:BWL 20M" % channel)

    def set_coupling_type(self, channel, coupling):
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

    def channel_display(self, channel, on):
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

    def set_vertical_range(self, channel, rnge, offset):
        """
        Set the vertical range parameters for the specified channel. If they are
        None, nothing happens.
        :param channel: 1, 2, 3 or 4
        :param rnge:
        :param offset:
        :return:
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        if rnge is not None:
            self.gpib.write(":CHAN%d:RANG %.3f" % (channel, rnge))

        if offset is not None:
            self.gpib.write(":CHAN%d:OFFS %.3f" % (channel, offset))

    def get_channel_offset(self, channel):
        """
        Returns the channel offset voltage in scientific notation
        """
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
        return self.gpib.query_ascii_values(":TIMebase:SCALe?")[0]

    def set_horizontal_range(self, rnge):
        """
        Sets the horizontal scale in seconds. For DS1000Z scopes, there are
        12 horizontal divisions per range.
        Individual divisions must follow a 1-2-5 step size. Values that are not
        multiple of 12, 24, 60 are scaled to fit.
        :param rnge:
        :return:
        """
        self.set_horizonal_scale(scale=rnge/12)

    def measure_item(self, channel, item):
        """
        Measures the specified item in the specified channel
        :param channel: 1, 2, 3 or 4
        :param item: "VMAX", "VMIN", "VPP", "VAVG", "PER", "FREQ"
        :return: the specified item value
        """

        if channel not in [1, 2, 3, 4]:
            print("Channel not correct. Doing nothing.")
            return

        if item not in ["VMAX", "VMIN", "VPP", "VAVG", "PER", "FREQ"]:
            print("Specified item to measure not correct. Doing nothing")
            return

        self.gpib.write(":MEAS:ITEM %s,CHAN%d" % (item, channel))
        time.sleep(1)
        return float(self.gpib.query_ascii_values(":MEAS:ITEM? %s,CHAN%d" % (item, channel))[0])

    def set_trigger(self, mode, coupling, trig_number, channel, level):
        """
        Sets the trigger with the specified parameters.
        :param mode: Trigger mode. One of "EDGE", "PULSE", "RUNT", "WIND", "SLOPE", "NEDG", "PATT", "DEL"
        :param coupling: Coupling type. One of "AC", "DC", "LFR", "HFR"
        :param trig_number: Sets when the trigger fires. One of "AUTO", "NORM", "SING"
        :param channel: source of the trigger
        :param level: level for the trigger to fire
        :return:
        """

        if mode in ["EDGE", "PULSE", "RUNT", "WIND", "SLOPE", "NEDG", "PATT", "DEL"]:
            self.gpib.write(":TRIG:MODE %s" % mode)

        if coupling in ["AC", "DC", "LFR", "HFR"]:
            self.gpib.write(":TRIG:COUP %s" % coupling)

        if trig_number in ["AUTO", "NORM", "SING"]:
            self.gpib.write(":TRIG:SWE %s" % trig_number)

        if channel in [1, 2, 3, 4]:
            self.gpib.write(":TRIG:%s:SOUR CHAN%d" % (mode, channel))

        if level is not None:
            self.gpib.write(":TRIG:%s:LEV %.4f" % (mode, level))

    def get_channel_states(self):
        """
        Checks which channels are activated.
        Returns list of booleans.
        """
        return [bool(self.gpib.query_ascii_values(":CHANnel{:d}:DISPlay?".format(x))[0]) for x in [1, 2, 3, 4]]

    def set_memory_depth(self, mdepth):
        """
        Sets the memory depth, based on the number of enabled channels.
        Can either manually set mdepth to one of the supported values, "AUTO", or "MAX" (suggested)
        """
        num_chans_enabled = np.sum(self.get_channel_states())

        mdepth = int(mdepth) if (
            mdepth != 'AUTO' and mdepth != 'MAX') else mdepth

        if mdepth != "AUTO":
            if num_chans_enabled == 1:
                if mdepth == 'MAX':
                    pts = 24000000
                else:
                    pts = mdepth
                    assert pts in ('AUTO', 12000, 120000,
                                   1200000, 12000000, 24000000)
            elif num_chans_enabled == 2:
                if mdepth == 'MAX':
                    pts = 12000000
                else:
                    pts = mdepth
                    assert pts in ('AUTO', 6000, 60000,
                                   600000, 6000000, 12000000)
            elif num_chans_enabled in (3, 4):
                if mdepth == 'MAX':
                    pts = 6000000
                else:
                    pts = mdepth
                    assert pts in ('AUTO', 3000, 30000,
                                   300000, 3000000, 6000000)
            else:
                print("No channels enabled, memory depth settings unchanged")

            if isinstance(pts, int):
                mdepth = str(pts)

        self.run()
        self.gpib.write(':ACQ:MDEP {:s}'.format(mdepth))

    def get_memory_depth(self):
        """
        Queries the current memory depth setting.
        """
        self.gpib.write(":ACQ:MDEP?")
        mdepth = int(self.gpib.read().rstrip('\n'))

        return mdepth

    def get_sampling_rate(self):
        """
        Returns the sampling rate
        """
        return self.gpib.query_ascii_values("ACQuire:SRATe?")[0]

    def read_waveform(self, channels, file_name=None):
        """
        Reads the display waveform data in the specified channels. This is limited
        to 1200 points of data, independent of the number of samples taken internally.
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
        Uses tqdm.notebook.tqdm for loading bar in Jupyter notebook
        MAX_BYTE_SAMPLES is specified in the manual
        """

        if channel not in [1, 2, 3, 4]:
            raise Warning("Channel not correct. Doing nothing.")
        
        if self.get_memory_depth() == "AUTO":
            raise Warning("The 'AUTO' memory depth option is not supported when"
                + " reading the memory buffer, please set a manual value or"
                + " 'MAX'.")
            
        self.stop()

        wp = self.gpib.query_ascii_values(":WAVeform:PREamble?")
        wp_dict = {
            'format'     : wp[0], # 0 (BYTE), 1 (WORD) or 2 (ASC)
            'type'       : wp[1], # 0 (NORMal), 1 (MAXimum) or 2 (RAW)
            'points'     : int(wp[2]), # integer between 1 and 12000000.
            'count'      : wp[3], 
            'xincrement' : wp[4],
            'xorigin'    : wp[5],
            'xreference' : wp[6],
            'yincrement' : wp[7],
            'yorigin'    : wp[8],
            'yreference' : wp[9],
        }

        x0 =  wp_dict['xorigin']
        xref = wp_dict['xreference']
        xinc = wp_dict['xincrement']

        y0 =   wp_dict['yorigin']
        yref = wp_dict['yreference']
        yinc = wp_dict['yincrement']

        self.gpib.write(":WAVeform:SOURce CHANnel%d" % channel)
        self.gpib.write(":WAV:MODE RAW")
        self.gpib.write(":WAVE:FORM BYTE")

        MAX_BYTE_SAMPLES = 250000
        N_points = wp_dict['points']

        N_chunks = N_points // MAX_BYTE_SAMPLES


        data = np.array([])
        # Doesn't run when N_chunks is 0 <-> range(0) == [], and doesn't include remainder points outside of chunk        
        for i in tqdm_notebook(range(N_chunks)):
            start_pos = (1+i*MAX_BYTE_SAMPLES)
            end_pos = ((i+1)*MAX_BYTE_SAMPLES)
            self.gpib.write(":WAV:STAR %d" % start_pos)
            self.gpib.write(":WAV:STOP %d" % end_pos)
            chunk = np.array(self.gpib.query_binary_values(":WAV:DATA?", datatype='B', header_fmt='ieee'))
            # Convert to voltage using method suggested by the manual
            chunk = (chunk - y0 - yref) * yinc
            data = np.append(data, chunk)

        # Handles cases where N_points < MAX_BYTE_SAMPLES or N_points % MAX_BYTE_SAMPLES != 0)
        if (N_points % MAX_BYTE_SAMPLES != 0):
            start_pos = N_chunks*MAX_BYTE_SAMPLES + 1
            end_pos = (N_points % MAX_BYTE_SAMPLES) + (start_pos - 1)
            self.gpib.write(":WAV:STAR %d" % start_pos)
            self.gpib.write(":WAV:STOP %d" % end_pos)
            chunk = np.array(self.gpib.query_binary_values(":WAV:DATA?", datatype='B', header_fmt='ieee'))
            chunk = (chunk - y0 - yref) * yinc
            data = np.append(data, chunk)

        # Adding x0 + xref rather than subtracting appears to give correct timing array
        t_array = np.arange(0, xinc * len(data), xinc) + x0 + xref 

        return data, t_array, wp_dict


if __name__ == '__main__':

    scope = RigolDS1000()
    addresses = scope.find_address()
    scope.initialize()







    

