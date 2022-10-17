import numpy as np
import csv
from photonmover.Interfaces.Instrument import Instrument
import time
import pyvisa as visa


class HP89410A(Instrument):
    """
    Code for controlling the HP89410A vector signal analyzer
    """
    def __init__(self, gpib_address=None):
        super().__init__()
        # It is good practice to initialize variables in init
        self.gpib_address = gpib_address
        self.gpib = None

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """

        if self.gpib_address is not None:
            print('Opening connnection to HP89410A vector signal analyzer')

            rm = visa.ResourceManager()
            try:
                self.gpib = rm.open_resource(self.gpib_address, timeout=5000)
            except BaseException:
                raise ValueError(
                    'Cannot connect to HP89410A vector signal analyzer')
        else:
            print("No GPIB address provided, please re-instantiate with an address")

    def close(self):
        print('Disconnecting HP89410A vector signal analyzer')
        # self.turn_off()
        self.gpib.close()

    def reset(self):
        self.gpib.write('*RST')

    def set_input_impedance(self, channel, impedance):
        """
        Set the input impedance for the specified channel
        :param channel: VSA channel (1 or 2)
        :param impedance: impedance (50, 75 or 1e6)
        """
        if not (channel in [1, 2]):
            print("Channel number not correct. Doing nothing.")
            return

        if not (impedance in [50, 75, 1e6]):
            print("Impedance not supported not correct. Doing nothing.")
            return

        self.gpib.write('INP%d:IMP %d;' % (channel, impedance))

    def turn_on(self, channel):
        """
        Activates the specified channel.
        :param channel: VSA channel (1 or 2)
        """

        if not (channel in [1, 2]):
            print("Channel number not correct. Doing nothing.")
            return

        self.gpib.write('INP%d:STAT ON;' % channel)

    def turn_off(self, channel):
        """
        Deactivates the specified channel.
        :param channel: VSA channel (1 or 2)
        """

        if not (channel in [1, 2]):
            print("Channel number not correct. Doing nothing.")
            return

        self.gpib.write('INP%d:STAT OFF;' % channel)

    def set_freq_axis(self, center, span, start_freq, end_freq):
        """
        Sets the center and span frequencies, if specified, or
        the start and end frequencies.
        :param center: string with units or in Hz. Example: '700 MHZ' or '700e6'
        :param span: string with units. Example:  '100 MHZ' or '100e6'
        :param start_freq: initial frequency (string with units)
        :param end_freq: end frequency (string with units)
        :return:
        """

        if center is not None:
            self.gpib.write('SENS:FREQ:CENT %s;' % center)

        if span is not None:
            self.gpib.write('SENS:FREQ:SPAN %s;' % span)

        if start_freq is not None:
            self.gpib.write('SENS:FREQ:STAR %s;' % start_freq)

        if end_freq is not None:
            self.gpib.write('SENS:FREQ:STOP %s;' % end_freq)

    def set_y_unit(self, unit):
        """
        Specifes the y axis unit
        :param unit: Desired unit (string)
        """

        if not (
            unit in [
                'dB',
                'dBVrms',
                'V2/Hz',
                'Vrms2',
                'dBm',
                'dBVrms/rtHz',
                'Vpk',
                'Vrms2/Hz',
                'dBm/Hz',
                'pct',
                'Vpk/rtHz',
                'W',
                'dBV',
                'unitless',
                'Vpk2',
                'W/Hz',
                'dBV/rtHz',
                'V',
                'Vpk2/Hz',
                'Wrms',
                'dBVpk',
                'V/rtHz',
                'Vrms',
                'Wrms/Hz',
                'dBVpk/rtHz',
                'V2',
                'Vrms/rtHz']):
            print("Specified unit not correct. Doing nothing.")
            return

        self.gpib.write('CALC:UNIT:POW %s;' % unit)

    def autoscale_y(self):
        self.gpib.write('DISP:WIND:TRAC:Y:AUTO ONCE;')

    def get_rbw(self):
        """
        Returns the resolution bandwidth setting, in Hz.
        """
        rbw = self.gpib.query_ascii_values('SENS:BAND:RES?')[0]
        return rbw

    def set_rbw(self, rbw):
        """
        Sets the resolution bandwidth.
        :param rbw: string with units or in Hz. Minimum is 300 mHz.
        """
        self.gpib.write('SENS:BAND:RES %s;' % rbw)

    def set_averaging(self, turn_on, av_type, num_averages):
        """
        Turn on or off the averaging with the specified number of averages.
        :param turn_on: if 1, it turns on averaging. If 0, it turns it off.
        :param av_type: averaging type. Either 'MAX' (hols the maximum at each point), 'RMS' (power average) or 'COMP'.
            'RMS' should be used in most cases.
        :param num_averages: number of averages to take.
        """

        if turn_on:
            self.gpib.write('SENS:AVER:STAT ON;')
            if not (type in ['MAX', 'RMS', 'COMP']):
                self.gpib.write('SENS:AVER:TYPE RMS;')
            else:
                self.gpib.write('SENS:AVER:TYPE %s;' % av_type)

            self.gpib.write('SENS:AVER:COUN %d;' % num_averages)
        else:
            self.gpib.write('SENS:AVER:STAT OFF;')

    def averages_taken(self):
        """
        Checks the number of averages taken
        """

        return self.gpib.query_ascii_values('SENS:AVER:COUN:INT?')[0]

    def save_trace_to_memory(self, trace_num, data_reg_num):
        """
        Saves the specified trace to the specified data register.
        :param trace_num: Trace to save (usually 1). 1 - 4.
        :param data_reg_num: Data register number. 1 - 6.
        """

        if not (trace_num in [1, 2, 3, 4]):
            print("Trace number not correct. Doing nothing.")
            return

        if not (data_reg_num in [1, 2, 3, 4, 5, 6]):
            print("Data register number not correct. Doing nothing.")
            return

        # print(data_reg_num)
        # self.gpib.write('TRACE:COPY D%d, TRAC%d' % (data_reg_num, trace_num))
        self.gpib.write('SYST:KEY 24;')  # KEY: Save/recall
        self.gpib.write('SYST:KEY 111;')  # KEY: F1
        self.gpib.write('SYST:KEY %d;' % (111 + data_reg_num))  # KEY: Shifted

    def retrieve_data(self, trace_id, filename=None):
        """
        Retrieves the data saved in the instrument memory
        :param trace_id: id of the trace. 1 - 6.
        :param filename: Optional; filename in which to store data [csv format].
        :return:
        """

        if not (trace_id in [1, 2, 3, 4, 5, 6]):
            print("Trace ID not correct. Doing nothing.")
            return

        xdata = self.gpib.query("TRACE:X:DATA? D{:d}".format(trace_id))
        ydata = self.gpib.query("TRACE:DATA? D{:d}".format(trace_id))

        xdata = np.array(xdata.split(','), dtype=float)
        ydata = np.array(ydata.split(','), dtype=float)

        # convert to V/sqrt(Hz)
        ydata = np.sqrt(ydata) / np.sqrt(2)

        if filename is not None:
            with open(filename + '.csv', 'w+') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(xdata)
                writer.writerow(ydata)

        return (xdata, ydata)

    def convert_to_noise_spectra(self, freqs, Sv, Vpp_interferometer, dL):
        """
        Converts the vsa data into frequency noise spectra, assuming the noise 
        was measured using an imbalanced MZI approach. 

        :param freqs: vector of frequencies (in Hz)
        :param Sv: voltage noise masured by the VSA (in V/sqrt(Hz))
        :param Vpp_interferometer: peak to peak voltage of the interferometer (Vmax - Vmin).
        :param dL: path length between the two arms of the interferometer
        """

        c = 2.99e8
        neff = 1.48

        dV = Vpp_interferometer / 2
        tau = dL / (c / neff)

        denom = dV / np.sqrt(2) * 2 * np.pi * tau * np.sinc(freqs * tau)

        Sf = (Sv / denom) ** 2

        return [freqs, Sf]

    def collect_signal_spectrum(self, freqs, num_averages, rbws, filename=None):
        """
        Collects a large spectrum signal.
        The VSA is limited to taking data on a linearly-spaced frequency grid.
        Over broad bandwidths this leads to unnecessarily coarse or fine spacings
        on the extreme ends.
        In order to get a balanced, quasi-frequency-scaled resolution, we take
        several spectra over the whole frequency range we want to cover.

        :param freqs: list with the edge frequencies of the different slices. We will take one
            spectrum between freqs[0] and freqs[1]; another between freqs[1] and freqs[2], ...
        :param num_averages: number of averages to take. It can be a single number (and then all
            frequency slices will have the same nuber of averages) or a vector with the length len(freqs-1).
            In this latter case, each slice will average with the specified number.
        :param rbws: resolution bandwidth to use. It can be a single number (and then all
            frequency slices will have the same rbw) or a vector with the length len(freqs-1).
            In this latter case, each slice will use the specified rbw.
        :param filename: Optional; Stores output data in `<filename>.csv`.
        """

        self.set_averaging(0, 'RMS', None)
        time.sleep(1)

        if isinstance(num_averages, list):
            change_aver = 1
        else:
            change_aver = 0
            self.set_averaging(1, 'RMS', num_averages)

        if isinstance(rbws, list):
            change_rbw = 1
        else:
            change_rbw = 0
            self.set_rbw(rbws)

        for idx in range(len(freqs) - 1):
            # Set axis
            self.set_freq_axis(None, None, freqs[idx], freqs[idx + 1])
            self.autoscale_y()

            # Set rbw if necessary
            if change_rbw:
                self.set_rbw(rbws[idx])

            # Set averaging if necessary
            if change_aver:
                self.set_averaging(1, 'RMS', num_averages[idx])
                self.gpib.write('SYST:KEY 21;')  # KEY: Meas Restart

                time.sleep(20)
                # Wait for measurement
                while self.averages_taken() < num_averages[idx]:
                    print('Waiting')
                    time.sleep(10)

            else:
                # Start measuring
                self.gpib.write('SYST:KEY 21;')  # KEY: Meas Restart

                # Wait until done
                time.sleep(10)
                while self.averages_taken() < num_averages:
                    time.sleep(5)

            # Save data into data register
            self.save_trace_to_memory(1, idx + 1)
            time.sleep(1)

        # After all is done, save the register data into files
        freq_regs = []  # initialize lists for frequency, signal data
        sig_regs = []
        for idx in range(len(freqs) - 1):
            data_register = idx+1
            xd, yd = self.retrieve_data(data_register)

            # returned data is sometimes outside the specified frequency bounds
            # Find closest frequencies and slice
            min_indx = np.abs(xd-freqs[idx]).argmin()
            max_indx = np.abs(xd-freqs[idx+1]).argmin()+1
            xd, yd = xd[min_indx:max_indx], yd[min_indx:max_indx]

            freq_regs.append(xd)
            sig_regs.append(yd)

        freq = np.concatenate(freq_regs, axis=-1)
        sig = np.concatenate(sig_regs, axis=-1)

        if filename is not None:
            with open(filename + '.csv', 'w+') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(freq)
                writer.writerow(sig)

        return freq, sig


if __name__ == '__main__':
    vsa = HP89410A()
    vsa.initialize()
    vsa.collect_signal_spectrum(freqs=['1', '100', '1000', '10000', '100e3', '1e6', '10e6'],
                                num_averages=[600, 600, 200, 500, 500, 500],
                                rbws=['1', '10', '50', '500', '5000', '50000'],
                                filename='HP_1550_vib_isol')
    vsa.close()
