from photonmover.Interfaces.MSA import MSA
from photonmover.Interfaces.Instrument import Instrument

import pyvisa as visa
import time
import numpy as np
import matplotlib.pyplot as plt
import csv


GPIB_ADDRESS = "GPIB1::18::INSTR"


class HP70900A(MSA, Instrument):
    """
    Code for getting data out of the microwave spectrum analyzer
    """

    def __init__(self):
        super().__init__()
        self.gpib = None

    def initialize(self):
        print('Opening connnection to HP MSA')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDRESS, timeout=5000)
        except:
            raise ValueError('Cannot connect to the HP MSA')

        self.init_func()

    def init_func(self):
        self.gpib.write('TDF P')  # Set ASCII mode for communication

    def close(self):
        print('Disconnecting HP MSA')
        self.gpib.close()


    def set_freq_axis(self, center, span, start_freq, end_freq):
        """
        Sets the center and span frequencies, if specified, or
        the start and end frequencies.
        :param center: string with units. Example: '700 MHZ'
        :param span: string with units. Example:  '100 MHZ'
        :param start_freq: initial frequency (string with units)
        :param end_freq: end frequency (string with units)
        :return:
        """

        if center is not None:
            self.gpib.write('CF %s;' % center )

        if span is not None:
            self.gpib.write('SP %s;' % span)

        if start_freq is not None:
            self.gpib.write('FA %s;' % start_freq)

        if end_freq is not None:
            self.gpib.write('FB %s;' % end_freq)

    def set_continuous_acq(self):
        """
        Sets the analyzer to acquire continuous sweeps.
        :return:
        """
        self.gpib.write('CONTS;')

    def set_acq_bandwidth(self, res_bw, video_bw):
        """
        Sets the bandwidth of the acquisition filters.
        :param res_bw: resolution bandwidth filter  (string with units)
        :param video_bw: video vandiwdth filter (string with units)
        :return:
        """

        if res_bw is not None:
            self.gpib.write('RB %s;' % res_bw)

        if video_bw is not None:
            self.gpib.write('VB %s;' % video_bw)

    def instrument_preset(self):
        """
        Sets the instrument to its preset state
        :return:
        """
        self.gpib.write('IP;')

    def set_sweep_time(self, sweep_time):
        """
        Sets the sweep time
        :param sweep_time: string with units (ex: '1S') or 'AUTO'
        :return:
        """
        self.gpib.write('ST %s;' % sweep_time)

    def set_reference_level(self, ref_value, ref_pos):
        """
        Sets the reference power level and its position in the screen
        :param ref_value: reference level with units. Ex:'-20dBM'
        :param ref_pos: graticule line at which the reference level is (10--> Top, 0 --> Bottom)
        :return:
        """

        if ref_value is not None:
            self.gpib.write('RL %s;' % ref_value)

        if ref_pos is not None:
            self.gpib.write('RLPOS %d;' % ref_pos)

    def set_peak_detection_type(self, type):
        """
        Sets the peak detection to use.
        :param type: 'NRM' for normal, 'POS' for positive peaks, 'NEG' for negative peaks
        :return:
        """

        if type not in ['NRM', 'POS', 'NEG']:
            print('Specified detection type not valid. Doing nothing.')
            return

        self.gpib.write('DET %s;' % type)

    def identify_signal(self, move_to_center=False, get_freq=True):
        """
        Tries to identify a signal in the spectrum
        :param move_to_center: If True, it moves the identified signal to the center of the screen
        :param get_freq: if True, it returns the frequency of the identified signal
        :return:
        """
        self.gpib.write('SIGID AUTO;')

        if move_to_center:
            self.gpib.write('IDCF;')

        if get_freq:
            return self.gpib.query_ascii_values('IDFREQ?;')

    def get_peak_info(self, peak_id='HIP'):
        """
        Find the peak of the spectra and returns the frequency and the amplitude in a list
        :param peak_id: Type of peak to look for.
                'CP': closest peak
                'CPIT': closest pit
                'HI': highest point on the trace
                'HIP': highest peak
                'MI': minimum peak (NOT the same as the minimum point!)
                'MIPIT': lowest pit
                'NH': next highest signal level detected
                'NHPIT': next highest pit
                'NL': next signal peak to the left
                'NLPIT': next signal pit to the left.
                'NM': next minimum peak
                'NMPIT: next lowest pit.
                'NR': next peak to the right
                'NRPIT': next pit to the right
        :return:
        """
        self.gpib.write('TS;DONE?;')
        self.gpib.write('MK;')  # position a marker
        self.gpib.write('MKPK %s;' % peak_id)  # move the marker to the peak

        amp = self.gpib.query_ascii_values('MKA?;')
        freq = self.gpib.query_ascii_values('MKF?;')

        return [freq[0], amp[0]]

    def take_sweep(self, num_avg=1):
        """
        Take sweep
        :param num_avg: Number of averages
        :return:
        """
        if num_avg == 1:
            self.gpib.write('VAVG OFF;SNGLS;TS;')
        else:
            self.gpib.write('VAVG %d;VAVG ON;TS' % num_avg )

    def read_data(self, filename=None):

        # Get trace conditions
        self.gpib.write("TRCOND TRA?;")
        conds = self.gpib.read_raw().decode('ascii')
        # separate by comma
        conds = conds.split(',')
        init_freq = float(conds[0])
        end_freq = float(conds[1])

        # Get trace
        self.gpib.write('TS;DONE?;')
        self.gpib.write('VIEW TRA;')

        #print(self.gpib.query_ascii_values('DONE?;'))
        #while int(self.gpib.query_ascii_values('DONE?;')[0]) != 1:
        #    time.sleep(0.2)


        amps = self.gpib.query_ascii_values("TRA?;")

        #while int(self.gpib.query_ascii_values('DONE?;')[0]) != 1:
        #    time.sleep(0.2)

        freqs = np.linspace(init_freq, end_freq, len(amps))

        # Save the data if necessary. Each channel will be stored in a different file
        if filename is not None:
            with open(filename, 'w+') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(freqs)
                writer.writerow(amps)

        self.gpib.write('CLRW TRA;')

        return [freqs, amps]


if __name__ == '__main__':

    hp = HP70900A()
    hp.initialize()
    #freq = 500e3
    #freq_string = "%.4f MHZ" % (freq*1e-6)
    #span_string = "%.4f MHZ" % np.maximum((2*freq*1e-6), 0.5)
    #print(freq_string)
    #print(span_string)
    #input()
    #hp.set_freq_axis(freq_string, span_string, None, None)
    #input()
    #print(hp.get_peak_info())
    #input()
    hp.read_data('gain_pv_mod-Pin=4mW-no_EDFA-Vpp=0.0005V-f=0.5MHz.csv')
    #print(hp.read_data())
    hp.close()


