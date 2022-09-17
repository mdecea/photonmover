import pyvisa as visa
import numpy as np
import time
import csv
import struct
import binascii
import matplotlib.pyplot as plt
from photonmover.Interfaces.Instrument import Instrument

GPIB_ADDR = "GPIB1::2::INSTR"  # VISA adress


class HP54750A(Instrument):
    """
    Code for controlling HP 54750A oscilloscope
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
        print('Opening connnection to HP 54750A oscilloscope')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDR, timeout=10000)
        except:
            raise ValueError('Cannot connect to HP 54750A oscilloscope')

        self.gpib.write(":TIM:REF LEFT")

    def close(self):
        print('Disconnecting HP 54750A oscilloscope')
        self.gpib.close()

    def autoscale(self):
        self.gpib.write(":AUT")

    def clear(self):
        """
        Clears all the waveforms in the display
        :return:
        """
        self.gpib.write(":CDIS")

    def run(self):
        """
        Start the oscilloscope
        :return:
        """
        self.gpib.write(":RUN")

    def single(self):
        """
        Single acquisition
        :return:
        """
        self.gpib.write(":SING")

    def stop(self):
        """
        Stop the oscilloscope
        :return:
        """
        self.gpib.write(":STOP")

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

        if on:
            self.gpib.write(":VIEW CHAN%d" % channel)
        else:
            self.gpib.write(":BLANK CHAN%d" % channel)

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

        if num_avg == 1:
            # No averaging
            self.gpib.write(":ACQ:AVER OFF")
        else:
            self.gpib.write(":ACQ:COUN %d" % num_avg)
            self.gpib.write(":ACQ:AVER ON")

    def set_bw(self, channel, bw):
        """
        Sets the bandwidth limit for the specified channel
        :param channel: 1, 2, 3 or 4
        :param bw: 'HIGH' or 'LOW'
        :return:
        """

        if channel not in [1, 2, 3 ,4]:
            print("Channel not correct. Doing nothing.")
            return

        if bw not in ['HIGH', 'LOW']:
            print("Bandwidth option not correct. Doing nothing")
            return

        self.gpib.write(":CHAN%d:BAND %s" % (channel, bw))

    def set_vertical_range(self, channel, rnge, offset):
        """
        Set the vertical range parameters for the specified channel. If they are
        None, nothing happens.
        :param channel: 1, 2, 3 or 4
        :param rnge: the full scale range that the screen covers
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

    def set_color_graded_display(self, on):
        """
        Turns on or off the color-graded display (necessary for eye diagrams)
        """
        if on not in [0, 1]:
            print('Color graded diplsay option not recognized. Doing nothing.')
            return

        self.gpib.write(":DISP:CGR %d" % on)

    def set_wf_draw_mode(self, mode):
        """
        Specifies the waveform display mode.
        Mode is either 'FAST', 'CDOT' (connected dots display) or 'HRES' (high resolution)
        """

        if mode not in ['FAST', 'CDOT', 'HRES']:
            print('Waveform draw mode option not recognized. Doing nothing.')
            return

        self.gpib.write(":DISP:DWAV %s" % mode)

    def set_horizonal_scale(self, scale):
        """
        Sets the horizontal scale in s/div
        :param scale:
        :return:
        """
        self.gpib.write(":TIM:SCAL %.7f" % scale)

    def set_time_origin(self, time_delay):
        """
        Sets the time delay between the trigger and the first point shown on the screen (in s)
        """
        self.gpib.write(":TIM:POS %.10f" % time_delay)

    def read_waveform(self, channels, file_name=None):
        """
        Reads the waveform currently shown on the screen in the specified channels
        :param channels: list with the channels whose waveform we w ant to obtain.
        :param file_name: if specified, it will save the data with the specified file name. Do not include the ".csv".
        :return: 2 lists, each with n elemnts, where n is the number of channels.
                List 1: [preamble_channel1, preamble_channel2, ...]
                List 2: [channel1_data, channel2_data, ...]
        """

        all_ts = []
        all_waveforms = []

        # Set to send ascii
        self.gpib.write(":WAV:FORM ASCII")

        for c in channels:
            if c not in [1, 2, 3, 4]:
                print("Specified channel not correct. Skipping it")
                continue

            # Choose source
            self.gpib.write(":WAV:SOUR CHAN%d" % c)

            data = self.gpib.query_ascii_values("WAV:DATA?")

            x_increment = self.gpib.query_ascii_values("WAV:XINC?")
            x_origin = self.gpib.query_ascii_values("WAV:XOR?")

            t = np.arange(len(data))*x_increment + x_origin

            #plt.plot((t-x_origin)*1e12, data)
            #plt.show()

            # Save the data if necessary. Each channel will be stored in a different file
            if file_name is not None:

                # Create the csv file
                file_name_chan = file_name + "_channel_" + str(c) + ".csv"

                with open(file_name_chan, 'w+') as csvfile:
                    writer = csv.writer(csvfile)
                    writer.writerow(t)
                    writer.writerow(data)

            all_ts.append(t)
            all_waveforms.append(data)

        return all_ts, all_waveforms

    def get_pattern_data(self, channel, pattern_length, data_rate, num_patterns=1, file_name=None):
        """
        Records a total of 'num_patterns' patterns. 
        This function concatenates calls to read_waveform with different time origins so we can record data for longer
        than what is shown on the screen.
        :param channels: the channel to record
        :param pattern_length: the length (in bits) of the pattern we are applying
        :param data_rate: the data rate of the pattern (1/bit_duration)
        :param num_patterns: the number of patterns we want to record. 
        :param file_name: name of the csv file that will be created with the data
        The total time recorded is num_patterns*pattern_length/data_rate
        """

        time_origin = 0
        total_time_recorded = 0
        done = False

        t_vec = []
        wf_vec = []

        total_time = num_patterns*pattern_length/data_rate

        while not done:
            #print(time_origin)
            self.set_time_origin(time_origin)
            ts, wf = self.read_waveform([channel], file_name = None)
            #plt.plot(ts[0], wf[0])
            #plt.show()
            t_vec.extend(ts[0])
            wf_vec.extend(wf[0])

            t = ts[0]
            time_origin = t[-1] + (t[1]-t[0])

            #if time_origin > pattern_length/data_rate:
            #    time_origin = time_origin - pattern_length/data_rate

            total_time_recorded = total_time_recorded + (t[-1] - t[0])

            if total_time_recorded > total_time:
                done = True

         # Save the data if necessary. Each channel will be stored in a different file
        if file_name is not None:

            # Create the csv file
            file_name_chan = file_name + ".csv"

            with open(file_name_chan, 'w+') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(t_vec)
                writer.writerow(wf_vec)

        return t_vec, wf_vec
        

if __name__ == '__main__':

    osc = HP54750A()
    osc.initialize()

    #t, wf = osc.get_pattern_data(1, pattern_length=127, data_rate=1.5e9, num_patterns=10,
    #    file_name ='straight_spoke--Vbias=0.7V--Idc=0.77uA--Vpp=0.5V--att=44dB--f=1.5Gbps--avgs=256')
    #plt.plot(t, wf)
    #plt.show()
    #osc.autoscale()
    #time.sleep(1)
    osc.read_waveform([1], 'trial')

    osc.close()

