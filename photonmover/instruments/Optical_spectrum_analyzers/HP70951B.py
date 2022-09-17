from photonmover.Interfaces.MSA import MSA
from photonmover.Interfaces.Instrument import Instrument

import pyvisa as visa
import time
import numpy as np
import matplotlib.pyplot as plt
import csv


GPIB_ADDRESS = "GPIB1::23::INSTR"


class HP70951B(MSA, Instrument):

    """
    Code for getting data out of the HP 70951B Optical Spectrum Analyzer.
    """

    def __init__(self):
        super().__init__()
        self.gpib = None

    def initialize(self):
        print('Opening connnection to HP OSA')

        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(GPIB_ADDRESS, timeout=5000)
        except:
            raise ValueError('Cannot connect to the HP OSA')

        self.init_func()

    def init_func(self):
        self.gpib.write('TDF P')  # Set ASCII mode for communication

    def close(self):
        print('Disconnecting HP OSA')
        self.gpib.close()

    def set_amplitude_units(self, unit):
        if unit not in ['W', 'V', 'DBM']:
            print('Specified units not valid. Doing nothing.')
            return
        
        self.write('AUNITS %s;' % unit)

    def automeasure(self):
        """
        Automatically zoom in on largest signal at input
        """
        self.write('AUTOMEAS;')

    def set_wl_axis(self, center=None, span=None, start_wl=None, end_wl=None):
        """
        Sets the center and span wavelengths, if specified, or
        the start and end wavelength.
        :param center: string with units. Example: '700 NM'
        :param span: string with units. Example:  '100 NM'
        :param start_wl: initial wavelength (string with units)
        :param end_wl: end wavelength (string with units)
        :return:
        """

        if center is not None:
            self.gpib.write('CENTERWL %s;' % center )

        if span is not None:
            self.gpib.write('SP %s;' % span)

        if start_wl is not None:
            self.gpib.write('STARTWL %s;' % start_wl)

        if end_wl is not None:
            self.gpib.write('STOPWL %s;' % end_wl)

    def clear_display(self):
        self.write('CLRDSP;')

    def set_continuous_acq(self):
        """
        Sets the analyzer to acquire continuous sweeps.
        :return:
        """
        self.gpib.write('CONTS;')

    def set_mode(self, mode):
        """
        Sets the instrument mode. Check the manual for more detailed info.
        Mode is a string, with options:
        - OSA: Regular mode.
        - PWRMTR: The instrument functions only as a power meter.
        - OSAPULSE: Operation mode that is optimized for making accurate fast pulse measurements.
        - PRESEL: acts as a fixed-tuned, variable wavelength, variable bandwidth, bandpass filter.
        - SR: Stimulus-response.
        - PD: Photodiode test. Used to get PD responsivity. 
        """

        if mode not in ['OSA', 'PWRMTR', 'OSAPULSE', 'PRESEL', 'SR', 'PD']:
            print('Specified operatio mode not valid. Doing nothing.')
            return

        self.gpib.write('INSTMODE %s;' % mode)

    def instrument_preset(self):
        """
        Sets the instrument to its preset state
        :return:
        """
        self.gpib.write('IP;')

    def set_presel_wl(self, wl):
        """
        Sets the center wavelength of the filter in PRESEL mode. 
        wl is the wavelength in nm.
        """
        self.gpib.write('MKTUNE %.2fNM;' % wl)

    def acquire_pd_measurement(self, print_info=True):
        """
        Performs the PD mode measurement.
        IMPORTANT: This assumes that the reference spectrum has already been taken!
        """

        if print_info:
            print('When you press enter, the PD measurement will be taken. Before that, you should have:')
            print('1. Connected the front-panel MONOCHROMATOR OUTPUT to the PHOTODETECTOR INPUT with a fiber-optic cable.')
            print('2. Pressed STORE THRU --> B')
            input('3. Connected the PD output to the TRANS-Z IN of the rear panel of the OSA')

        self.gpib.write('PDMEAS ON;')

    def set_acq_bandwidth(self, res_bw=None, video_bw=None):
        """
        Sets the bandwidth of the acquisition filters.
        :param res_bw: resolution bandwidth  (string with wavelength units)
        :param video_bw: video vandiwdth filter (string with frequency units)
        :return:
        """

        if res_bw is not None:
            self.gpib.write('RB %s;' % res_bw)

        if video_bw is not None:
            self.gpib.write('VB %s;' % video_bw)

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

    def set_sensitivity(self, sens):
        # Sensitivity is in the amplitude units (either W (if linear mode) or dBm (if log mode))
        self.write('SENS %.4f;' % sens)

    def set_sweep_time(self, sweep_time):
        """
        Sets the sweep time
        :param sweep_time: string with units (ex: '1S') or 'AUTO'
        :return:
        """
        self.gpib.write('ST %s;' % sweep_time)

    def read_data(self, trace='A', filename=None):

        # Get trace conditions
        self.gpib.write("TRCOND TR%s?;" % trace)
        conds = self.gpib.read_raw().decode('ascii')
        # separate by comma
        conds = conds.split(',')
        init_wl = float(conds[0])
        end_wl = float(conds[1])

        # Get trace
        self.gpib.write('TS;DONE?;')
        self.gpib.write('VIEW TR%s;' % trace)

        #print(self.gpib.query_ascii_values('DONE?;'))
        #while int(self.gpib.query_ascii_values('DONE?;')[0]) != 1:
        #    time.sleep(0.2)


        amps = self.gpib.query_ascii_values("TR%s?;" % trace)

        #while int(self.gpib.query_ascii_values('DONE?;')[0]) != 1:
        #    time.sleep(0.2)

        wavs = np.linspace(init_wl, end_wl, len(amps))

        # Save the data if necessary. Each channel will be stored in a different file
        if filename is not None:
            with open(filename, 'w+') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(wavs)
                writer.writerow(amps)

        self.gpib.write('CLRW TR%s;' % trace)

        return [wavs, amps]

    def take_sweep(self, num_avg=1):
        """
        Take sweep
        :param num_avg: Number of averages
        :return:
        """
        if num_avg == 1:
            self.gpib.write('VAVG OFF;SNGLS;TS;')
        else:
            self.gpib.write('VAVG %d;VAVG ON;TS;' % num_avg )

    def activate_TIA_input(self, turn_on=True):
        """
        Allows input via the rear-panel TRANS-Z INPUT connector. Normally, the output of the optical spectrum analyzer's internal photodetector connects to a transimpedance 
        amplifier. Using the ON argument switches the amplifier's input from the photodetector to the rear-panel TRANS-Z INPUTconnector.
        """
        if turn_on:
            self.gpib.write('XAMPSW ON;')
        else:
            self.gpib.write('XAMPSW OFF;')

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
        wl = self.gpib.query_ascii_values('MKF?;')

        return [wl[0], amp[0]]

    def perform_PD_measurement(self, init_wl, end_wl, sensitivity, video_bw = 'AUTO', res_bw = '10NM', filename=None):
        """
        Sets up a PD responsivity measurement and performs it. If filename is specified, it saves a csv file with the measured data.
        If we don't want to affect any of the parameters, simply set it to None,
        """

        # First, set up measurement
        self.set_wl_axis(center=None, span=None, start_wl=init_wl, end_wl=end_wl)
        if sensitivity is not None:
            self.set_sensitivity(sensitivity)
        self.set_acq_bandwidth(res_bw=res_bw, video_bw=video_bw)

        # Now direct the user
        input('1. Connect the front-panel MONOCHROMATOR OUTPUT to the PHOTODETECTOR INPUT with a fiber-optic cable.')
        input('2. Wait for a full trace to be acquired')
        input('3. Press STORE THRU --> B')
        input('4. Connected the PD output to the TRANS-Z IN of the rear panel of the OSA.')
        input('5. Press enter and the measurement will be performed')

        self.acquire_pd_measurement(print_info=False)       
        self.gpib.write('DONE?;')

        # Now gather the data

        # Trace B has the reference input light to the PD
        [in_wl, in_power] = self.read_data(trace='B', filename=None)
        # Trace A has the responsivity data
        [out_wl, R_pd] = self.read_data(trace='A', filename=None)

        if filename is not None:
            with open(filename, 'w+') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(['Input light wavelength (row 1) and power (row 2):'])                
                writer.writerow(in_wl)
                writer.writerow(in_power)
                writer.writerow(['PD wavelength (row 3) and responsivity (row 4):'])                
                writer.writerow(out_wl)
                writer.writerow(R_pd)
        
        return [out_wl, R_pd, in_wl, in_power]


if __name__ == '__main__':

    hp = HP70951B()
    hp.initialize()
    hp.read_data(filename='thorlabs_810nmLED_spectrum--Ibias=1A.csv')
    #print(hp.read_data())
    hp.close()


