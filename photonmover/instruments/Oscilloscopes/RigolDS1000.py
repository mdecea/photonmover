import sys
sys.path.insert(0, '../..')
import pyvisa as visa
import numpy as np
import time
import csv
import struct
import binascii
from Interfaces.Instrument import Instrument

GPIB_ADDR = "USB0::0x1AB1::0x04CE::DS1ZA201205030::INSTR"  # VISA adress


class RigolDS1000(Instrument):
    """
    Code for controlling Rigol DS1000 Oscilloscope
    """

    def __init__(self):
        super().__init__()

        # It is good practice to initialize variables in init
        self.gpib = None


    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Rigol Oscilloscope')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDR, timeout=10000)
        except:
            raise ValueError('Cannot connect to Rigol Oscilloscope')


    def close(self):
        print('Disconnecting Rigol Oscilloscope')
        self.gpib.close()

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
            print("The number of averages has to be a power of 2. Setting to the closest.")
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

        if channel not in [1, 2, 3 ,4]:
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

        if channel not in [1, 2, 3 ,4]:
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

        if channel not in [1, 2, 3 ,4]:
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

        if channel not in [1, 2, 3 ,4]:
            print("Channel not correct. Doing nothing.")
            return

        if rnge is not None:
            self.gpib.write(":CHAN%d:RANG %.3f" % (channel, rnge))

        if offset is not None:
            self.gpib.write(":CHAN%d:OFFS %.3f" % (channel, offset))

    def set_horizonal_scale(self, scale):
        """
        Sets the horizontal scale in s/div
        :param scale:
        :return:
        """
        self.gpib.write(":TIM:SCAL %.7f" % scale)

    def measure_item(self, channel, item):
        """
        Measures the specified item in the specified channel
        :param channel: 1, 2, 3 or 4
        :param item: "VMAX", "VMIN", "VPP", "VAVG", "PER", "FREQ"
        :return: the specified item value
        """

        if channel not in [1, 2, 3 ,4]:
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

    def read_waveform(self, channels, file_name=None):
        """
        Reads the waveform in the specified channels
        :param channels: list with the channels whose waveform we w ant to obtain.
        :param file_name: if specified, it will save the data with the specified file name. Do not include the ".csv".
        :return: 2 lists, each with n elemnts, where n is the number of channels.
                List 1: [preamble_channel1, preamble_channel2, ...]
                List 2: [channel1_data, channel2_data, ...]
        """

        all_preambles = []
        all_waveforms = []

        # Set waveform reading mode to normal
        self.gpib.write(":WAV:MODE NORM")

        # Set to send ascii
        self.gpib.write(":WAV:FORM ASCII")

        for c in channels:
            if c not in [1, 2, 3, 4]:
                print("Specified channel not correct. Skipping it")
                continue

            # Choose source
            self.gpib.write(":WAV:SOUR CHAN%d" % c)

            self.gpib.write("WAV:DATA?")
            data = self.gpib.read_raw()
            #print(data)
            num_bytes = int(data[7:11])
            #print(num_bytes)
            raw_data = data[11:]
            #print(raw_data)
            #input()

            wav_data_str = (str(raw_data)[2:-3]).split(',')

            wav_data = [float(i) for i in wav_data_str]
            #print(wav_data)

            preamble = self.gpib.query_ascii_values("WAV:PRE?")

            # Save the data if necessary. Each channel will be stored in a different file
            if file_name is not None:

                # Create the csv file
                file_name_chan = file_name + "_channel_" + str(c) + ".csv"

                with open(file_name_chan, 'w+') as csvfile:
                    writer = csv.writer(csvfile)
                    writer.writerow(preamble)
                    writer.writerow(wav_data)

            all_preambles.append(preamble)
            all_waveforms.append(wav_data)

        return all_preambles, all_waveforms


if __name__ == '__main__':

    osc = RigolDS1000()
    osc.initialize()

    print(osc.measure_item(1, "VPP"))
    #osc.autoscale()
    #time.sleep(1)
    #osc.read_waveform([1], 'trial')

    osc.close()














