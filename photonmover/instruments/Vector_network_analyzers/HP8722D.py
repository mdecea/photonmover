from photonmover.Interfaces.VNA import VNA
from photonmover.Interfaces.Instrument import Instrument

import pyvisa as visa
import time
import numpy as np
import matplotlib.pyplot as plt
import csv


class HP8722D(VNA, Instrument):
    """
    Code for getting data out of the HP 8722D VNA.

    This class can both extract data from sweeps, as well as perform basic functions
    like turning the signal source on/off, and set the frequency axis range and
    number of points.
    
    """

    def __init__(self, gpib_address="GPIB1::25::INSTR"):
        super().__init__()
        self.gpib = None
        self.gpib_address = gpib_address

    def initialize(self):
        print('Opening connnection to HP VNA')
        print( 'GPIB address is {}'.format(self.gpib_address))
        rm = visa.ResourceManager()
        try:
            self.gpib = rm.open_resource(self.gpib_address, timeout=120000)  # 2 min timeout
            print( 'Connected to HP VNA' )
        except:
            raise ValueError('Cannot connect to the HP VNA')

    def close(self):
        print('Disconnecting HP VNA')
        self.gpib.close()

    # ----------- SETTINGS ---------------
    
    def source_on(self, power=None):
        """
        Turns on source power.
        If power is specified, it also sets the output power (in dBm) 
        """
        self.gpib.write( 'SOUPON;')
        if power is not None:
            if -85 < power < -5:
                self.gpib.write( 'POWE %.2f DB; ' )
            else:
                print('The specified VNA power is not supported. Doing nothing.')

    def source_off(self):
        """
        Turns off source power
        """
        self.gpib.write( 'SOUPOFF;')

    def set_averaging(self, num_averages):
        """
        Sets the VNA to acquire with averaging. If num_averages = 1, it turn off averaging
        """

        num_averages = int(num_averages)

        if num_averages > 1:
            self.gpib.write('AVEROON; AVERFACT%d; AVERREST;' % num_averages)

        elif num_averages == 1:
            self.gpib.write('AVEROOFF;')

        else:
            print('THe specified number of averages is not supported.')

    def set_measurement_type(self, sweeptype='S11', meastype='LOGM'):
        """
        Sets the s parameter to be measured (S11, S21, S12, S22) and what is being measued (magnitude, phase...)
        meastype can be 'LOGM' for log of magnitude or 'PHAS' for phase
        """

        # Set the sweep type
        if sweeptype is not None:
            self.gpib.write('%s;' % sweeptype)

        if meastype is not None:
            self.gpib.write('%s;' % meastype)

    def set_freq_axis(self, center=None, span=None, start_freq=None, end_freq=None, num_points=None):
        """
        Sets the center/span or min/max frequencies for a LINEAR sweep, and the
        number of points.
        Frequencies are in GHz with up to three decimal places.

        If all parameters are given, start and end frequencies take preference.

        If None is passed for a parameter, its current value is used.
        """
        giga=1e9

        if center is not None:
            self.gpib.write('CENT {};'.format(center*giga))

        if span is not None:
            self.gpib.write('SPAN {};'.format(span*giga) )

        if start_freq is not None:
            self.gpib.write('STAR {};'.format(start_freq*giga))

        if end_freq is not None:
            self.gpib.write('STOP {};'.format(end_freq*giga))

        num_points_options = set([201, 401, 801, 1601])
        if num_points is not None:
            if not set([num_points]).issubset(num_points_options):
                raise ValueError( 'num_points input must be one of: 201, 401, 801, 1601' )
            self.gpib.write( 'POIN {};'.format(num_points) )
    
    def set_trigger(self, mode='continuous', num_count=None):
        """
        Sets the trigger. It can be 'continuous', 'single', or 'fixed_num'. In the case of 'fixed_num',
        specify the number of triggered acquisitions in num_count variable
        """

        if mode == 'continuous':
            self.gpib.write('CONT;')
        elif mode == 'single':
            self.gpib.write('SING;')
        elif mode == 'fixed_num' and num_count is not None:
            self.gpib.write('NUMG%d;' % num_count)
        else:   
            print('The specified trigger settings for the VNA are not recognized. Doing nothing.')

    # ---------- TAKING AND READING DATA --------------
    
    def take_data(self, num_sweeps):
        """
        Triggers the acquisition of data over num_sweeps acquisitions
        """

        if num_sweeps == 1:
            self.gpib.query_ascii_values('OPC?; SING;')

        else:
            # Turn on averaging and trigger num_sweeps sweeps
            self.gpib.write('AVEROON; AVERFACT%d; AVERREST;' % num_sweeps)
            self.gpib.write('NUMG%d;' % num_sweeps)

        time.sleep(num_sweeps*4)

    def read_data_lin_sweep(self, file=None, plot_data=False):
        """
        Reads the data from a linear sweep, by asking for initial frequency, end frequency and
        number of points to construct the frequencies.

        If file is specified, it creates a csv with the specified path and filename
        """

        # Set correct data transfer mode
        self.gpib.write('FORM4;')
        self.gpib.write('OUTPFORM;')

        data = self._get_data()
        fr = self._get_freqs(rangetype='linear')

        if plot_data:
            plt.plot(fr, data)
            plt.show()

        if file is not None:
            with open(file, 'w+') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(fr)
                writer.writerow(data)

        return [fr, data]

    def read_data(self, file=None, plot_data=False):
        """
        Reads the data from any sweep. The data transfer is more complicated here.
        """

        # Assume that the data has been taken, just retrieving from the VNA
        # res = self.gpib.query_ascii_values('OPC?;')
        # print(res)
        # sys.stdout.flush()
        # while int(res) != 1:
        #     time.sleep(1)
        #     res = self.gpib.query_ascii_values('OPC?;')
        #     print(res)
        #     sys.stdout.flush()

        # Set correct data transfer mode
        self.gpib.write('FORM4;')
        self.gpib.write('OUTPFORM;')

        # Get data
        data = self._get_data()

        # Get frequency
        self.gpib.write('OUTPLIML;')
        fr = self.gpib.read_raw().decode('ascii')
        fr = fr.replace('\n', ',').replace(' ', '').split(",")
        fr = fr[0:-4]
        fr = [float(i) for i in fr[0::4]]

        if plot_data:
            plt.plot(fr, data)
            plt.show()

        if file is not None:
            with open(file, 'w+') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(fr)
                writer.writerow(data)

        return [fr, data]

    def read_data_allform(self, sweeptype='S11' ):
        """
        An expanded form of read_data() which provides both the S value and
        equivalent Y and Z values (magnitude and phase for each).
        """

        self.set_measurement_type(sweeptype=sweeptype)
        
        if sweeptype != 'S11':
            raise ValueError( "This class does not yet support anything but S11 (the conversions aren't worked out!)")

        results = dict.fromkeys(['S','Y','Z'], {
                        'freq':[],
                        'magnitude':[],
                        'phase':[],
                        })

        # Define functions to convert between S and Y/Z
        def S11toZ(magnitude, phase, freq=0, Z0=50):
            """ Convert S11 to Z. freq is a dummy input to allow dict parsing """
            S11 = 10**(magnitude/20) *np.exp(1j*phase*np.pi/180)
            Zrefl = Z0*(1+S11)/(1-S11)
            return {'magnitude':np.abs(Zrefl), 'phase':np.angle(Zrefl)*180/np.pi}
        def S11toY(magnitude, phase, freq=0, Z0=50):
            """ Convert S11 to Y. freq is a dummy input to allow dict parsing """
            Zcomponents = S11toZ(magnitude, phase, Z0=Z0)
            Z = Zcomponents['magnitude']*np.exp(1j*Zcomponents['phase']*np.pi/180)
            Y = 1/Z
            return {'magnitude':np.abs(Y), 'phase':np.angle(Y)*180/np.pi}

        # Set correct data transfer mode
        self.gpib.write('FORM4;')
        self.gpib.write('OUTPFORM;')
        results['S']['freq']= np.asarray(self._get_freqs(rangetype='linear'))

        M = [('LOGM', 'magnitude'), ('PHAS', 'phase')]
        for item in M:
            self.gpib.write('{};'.format(item[0]) )
            self.gpib.write('OUTPFORM;')
            results['S'][item[1]] = np.asarray(self._get_data())

        self.gpib.write('LOGM;')

        results['Y'] = S11toY( **results['S'] )
        results['Z'] = S11toZ( **results['S'] )
        results['Y']['freq'] = results['S']['freq']
        results['Z']['freq'] = results['S']['freq']
        return results

    def _get_freqs(self, rangetype='linear'):
        """
        Gets the frequency points used for the current sweep, either by linear
        interpolation or by querying the internal OUTPLIML method.

        :param rangetype: Either 'linear' or 'all'.
        """
        if rangetype.lower() == 'linear':
            num_f = int(self.gpib.query_ascii_values('POIN?;')[0])
            init_f = float(self.gpib.query_ascii_values('STAR?;')[0])
            span_f = float(self.gpib.query_ascii_values('SPAN?;')[0])
            fr = np.linspace(init_f, init_f+span_f, num_f)
        elif rangetype.lower() == 'all':
            raise ValueError(" 'all' method currently causes VNA to freeze. Don't use it." )
            #  10 May 2021: Despite having hard copied this from old code of Marc's, it's not working as-is.
            # I get a message "waiting for clean sweep" on the VNA screen, but it never happens.
            self.gpib.write('OUTPLIML;')
            fr = self.gpib.read_raw().decode('ascii')
            fr = fr.replace('\n', ',').replace(' ', '').split(",")
            fr = fr[0:-4]
            fr = [float(i) for i in fr[0::4]]

        return fr

    def _get_data(self):
        """
        Read and process ASCII data from device buffer, returning as a list of floats.
        """
        self.gpib.write( 'OUTPFORM;')
        data = self.gpib.read_raw().decode('ascii')
        data = data.replace('\n', ',').replace(' ', '').split(",")[0:-2]
        data = [float(i) for i in data[0::2]]

        return data


if __name__ == '__main__':
    hp = HP8722D()
    hp.initialize()
    #.read_data_lin_sweep('D:\\photonmover_MARC\\new_photonmover\\instruments\\Vector_network_analyzers\\'
     #                      'bw_0_8Vdc_1547_18nm_-20dBm.csv')
    hp.read_data('C:\\Users\\Prismo\\Desktop\\Marc\\trial_log.csv')
    hp.close()
