import sys
import pyvisa as visa
import numpy as np
import time
import csv
from photonmover.Interfaces.Instrument import Instrument
from enum import Enum
sys.path.insert(0, '../..')

import IPython
import matplotlib.pyplot as plt
from tqdm import tqdm
import struct

MANUFACTURER_ID = 0x1AB1


class ScopeTypes(Enum):
    """ Container class for scope model definitions """
    DS1054Z = 0x04CE

# TODO - implement probe function ":CHANnel<n>:PROBe"
# for now manually set all oscillscope channels to 1x probe

# TODO - update docstring for set_memory_depth to explain expected args

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
        """
        num_chans_enabled = np.sum(self.get_channel_states())

        mdepth = int(mdepth) if (
            mdepth != 'AUTO' and mdepth != 'MAX') else mdepth

        if mdepth != "AUTO":
            if num_chans_enabled == 1:
                if mdepth == 'MAX':
                    pts = 24000000
                else:
                    assert pts in ('AUTO', 12000, 120000,
                                   1200000, 12000000, 24000000)
            elif num_chans_enabled == 2:
                if mdepth == 'MAX':
                    pts = 12000000
                else:
                    assert pts in ('AUTO', 6000, 60000,
                                   600000, 6000000, 12000000)
            elif num_chans_enabled in (3, 4):
                if mdepth == 'MAX':
                    pts = 6000000
                else:
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


    
    def read_memory_buffer(self, channels):
        """
        Reads the entire memory buffer for all specified channels, up to the
        memory depth or number of points in the sample (samp rate*time range)
        Always reads all specified channels, even when channels are deactivated
        on the instrument front panel. Signals for deactivated channels are
        ~0 (usually 1e-8).
        :param channels: list with the channels whose waveform we want to obtain.
        :param file_name: if specified, it will save the data with the specified file name. Do not include the ".csv".
        :return: Length N list of 2-tuples, where n is the number of channels, each containing (time, voltage) for the respective channel.
                [(channel1_time_data, channel1_signal_data), (channel2_time_data, channel2_signal_data), ...]
        """

        # all_preambles = []
        all_waveforms = []

        # Set waveform reading mode to normal
        self.gpib.write(":WAV:MODE RAW")

        # Set to send ascii
        # read data as comma-separated list of voltages in scientific notation
        self.gpib.write(":WAV:FORM BYTE")

        memory_depth = self.get_memory_depth()
        samps = self.get_sampling_rate()*self.get_horizontal_scale()*12
        n_collect = int(np.min([memory_depth, samps]))
        print('n_collect = ' + str(n_collect))
        if memory_depth == "AUTO":
            raise Warning("The 'AUTO' memory depth option is not supported when"
                          + " reading the memory buffer, please set a manual value or"
                          + " 'MAX'.")

        xinc = self.gpib.query_ascii_values(":WAVeform:XINCrement?")[0]
        x0 = self.gpib.query_ascii_values(":WAVeform:XORigin?")[0]
        xref = self.gpib.query_ascii_values(":WAVeform:XREFerence?")[0]

        self.stop()  # stop acquisition in order to retrieve memory buffer
        for c in channels:

            y0 = self.gpib.query_ascii_values(":WAVeform:YORigin?")[0]
            yinc = self.gpib.query_ascii_values(":WAVeform:YINCrement?")[0]
            yref = self.gpib.query_ascii_values(":WAVeform:YREFerence?")[0]

            if c not in [1, 2, 3, 4]:
                print("Specified channel not correct. Skipping it")
                continue

            # Choose source
            self.gpib.write(":WAV:SOUR CHAN{:d}".format(c))

            # Collect data. Can't transfer entire memory buffer at once
            # so it is broken up into 4 separate reads
            data = []
            if n_collect < 2e6+1:
                N = 4
            elif n_collect < 6e6+1:
                N = 8
            elif n_collect < 12e6+1:
                N = 16
            elif n_collect < 22e6:
                N = 32

            print("N_chunks = " + str(N))
            for idx in range(N):
                n1 = 1 + idx*n_collect//N
                n2 = (idx+1)*n_collect//N
                if n2 > n_collect:
                    n2 = n_collect
                self.gpib.write(":WAVeform:STARt {:d}".format(n1))
                self.gpib.write(":WAVeform:STOP {:d}".format(n2))
                print(self.gpib.write(":WAVeform:STARt?"))
                print(self.gpib.write(":WAVeform:STOP?"))

                data += self.gpib.query_binary_values(
                    ":WAVeform:DATA?", datatype='B')
                print(data)

            wav_data = [(v - y0 - yref)*yinc for v in data]
            wave_time = np.arange(0, xinc * len(wav_data), xinc) - x0 - xref

            all_waveforms.append((wave_time, wav_data))

        # Return to run state so commands update
        self.run() # TODO - this might be a problem i.e not done reading before you start running again
        return all_waveforms

    # TODO - investigate this
    def read_memory_buffer_sagar(self, channel):
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

        MAX_BYTE_SAMPLES = 250000 # TODO - make this a class parameter
        N_points = wp_dict['points']
        N_chunks = N_points // MAX_BYTE_SAMPLES

        self.gpib.write(":WAV:SOUR %d" % channel)
        self.gpib.write(":WAV:MODE RAW")
        self.gpib.write(":WAVE:FORM BYTE")

        assert(N_points % MAX_BYTE_SAMPLES == 0)

        data = np.array([])
        for i in tqdm(range(N_chunks)):
            
            self.gpib.write(":WAV:STAR %d" % (1+i*MAX_BYTE_SAMPLES))
            self.gpib.write(":WAV:STOP %d" % ((i+1)*MAX_BYTE_SAMPLES))
            chunk = np.array(self.gpib.query_binary_values(":WAV:DATA?", datatype='B', header_fmt='ieee'))
            print("chunk length: " + str(len(chunk)))
            # self.gpib.write("WAV:DATA?")
            # chunk = self.gpib.read_raw()[11:]
            # Convert to voltage using method suggested by the manual
            chunk = (chunk - y0 - yref) * yinc
            data = np.append(data, chunk)
            print("data length: %d" % +len(data))

        t_array = np.arange(0, xinc * len(data), xinc) + x0 - xref # check sign, this should be -T to T

        return data, t_array, wp_dict

    def read_internal_memory_ascii(self, channel):
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

        MAX_BYTE_SAMPLES = 15625
        N_points = wp_dict['points']
        N_chunks = N_points // MAX_BYTE_SAMPLES
        assert(N_points % MAX_BYTE_SAMPLES == 0)

        self.gpib.write(":WAV:SOUR %d" % channel)
        self.gpib.write(":WAV:MODE RAW")
        self.gpib.write(":WAVE:FORM ASCii")

        data = np.array([])
        for i in tqdm(range(N_chunks)):
            
            self.gpib.write(":WAV:STAR %d" % (1+i*MAX_BYTE_SAMPLES))
            self.gpib.write(":WAV:STOP %d" % ((i+1)*MAX_BYTE_SAMPLES))
            chunk = np.array(self.gpib.query_ascii_values(":WAV:DATA?"))
            # Convert to voltage using method suggested by the manual
            # chunk = (chunk - wp_dict['yorigin'] - wp_dict['yreference']) * wp_dict['yincrement']
            print("chunk length: " + str(len(chunk)))
            data = np.append(data, chunk)
            print("data length: " + str(len(data)))

        t_array = np.arange(0, wp_dict['xincrement'] * len(data), wp_dict['xincrement']) + wp_dict['xorigin'] - wp_dict['xreference'] # check sign, this should be -T to T

        return data, t_array, wp_dict

    # NOTE - adapted this function (and subfunctions) from: https://github.com/pklaus/ds1054z/blob/master/ds1054z/__init__.py
    def get_internal_memory_samples(self, channel):
        """
        This function returns the waveform samples from the scope
        Does a byte query from memory, strips the header, and converts to voltage
        """
        self.stop()
        self.gpib.write(":WAVeform:SOURce %d" % channel)
        self.gpib.write(":WAVeform:FORMat BYTE")
        self.gpib.write(":WAVeform:MODE RAW")

        wp = self.gpib.query_ascii_values(":WAVeform:PREamble?")
        wp_dict = {
            'format'     : wp[0],      # 0 (BYTE), 1 (WORD) or 2 (ASC)
            'type'       : wp[1],      # 0 (NORMal), 1 (MAXimum) or 2 (RAW)
            'points'     : int(wp[2]), # integer between 1 and 12000000. We expect 6000000
            'count'      : wp[3], 
            'xincrement' : wp[4],
            'xorigin'    : wp[5],
            'xreference' : wp[6],
            'yincrement' : wp[7],
            'yorigin'    : wp[8],
            'yreference' : wp[9],
        }

        pnts = wp_dict['points']
        buff = b""
        MAX_BYTE_LEN = 250000
        pos = 1
        while len(buff) < pnts:
            self.gpib.write(":WAVeform:STARt {0}".format(pos))
            end_pos = min(pnts, pos+MAX_BYTE_LEN-1)
            self.gpib.write(":WAVeform:STOP {0}".format(end_pos))
            # tmp_buff = self.gpib.query_raw(":WAVeform:DATA?")
            # tmp_buff = bytes(self.gpib.query(":WAVeform:DATA?"))
            tmp_buff = bytes(self.gpib.query_binary_values(":WAVeform:DATA?", datatype="B", header_fmt="ieee"))
            buff += tmp_buff # self._decode_ieee_block(tmp_buff)
            pos += MAX_BYTE_LEN

        xinc = wp_dict['xincrement']
        xorigin = wp_dict['xorigin']

        t_array = []
        for i in range(pnts):
            t_array.append(xinc* i + xorigin)

        samples = self._get_waveform_samples(buff, wp_dict)

        return samples, t_array, wp_dict

    def _decode_ieee_block(self, ieee_bytes):
        """
        Strips headers (and trailing bytes) from a IEEE binary data block off.
        This is the block format commands like ``:WAVeform:DATA?``, ``:DISPlay:DATA?``,
        ``:SYSTem:SETup?``, and ``:ETABle<n>:DATA?`` return their data in.
        Named after ``decode_ieee_block()`` in python-ivi
        """
        n_header_bytes = int(chr(ieee_bytes[1]))+2
        n_data_bytes = int(ieee_bytes[2:n_header_bytes].decode('ascii'))
        return ieee_bytes[n_header_bytes:n_header_bytes + n_data_bytes]

    def _get_waveform_samples(self, buff, wp_dict):
        """
        Converts raw binary data from _get_waveform_bytes_internal() into usable voltage data
        """

        yorig = wp_dict['yorigin']
        yref = wp_dict['yreference']
        yinc = wp_dict['yincrement']

        samples = list(struct.unpack(str(len(buff))+'B', buff))
        samples = [(val - yorig - yref)*yinc for val in samples]

        return samples

if __name__ == '__main__':

    scope = RigolDS1000()
    addresses = scope.find_address()
    scope.initialize()

    # data, t_array, wp_dict = scope.read_memory_buffer_sagar(4)
    # print(wp_dict)
    # print(len(data))
    # print(len(t_array))

    # plt.plot(t_array, data)
    # plt.title('Memory Read Test')
    # plt.xlabel('t []')
    # plt.ylabel('CH4 [V]')
    # plt.show()

    samples, t_array, wp_dict = scope.get_internal_memory_samples(4)
    print(wp_dict)
    print(len(samples))
    print(len(t_array))

    plt.plot(t_array, samples)
    plt.title('Memory Read Test')
    plt.xlabel('t [s]')
    plt.ylabel('CH4 [V]')
    plt.show()

    IPython.embed()






    

