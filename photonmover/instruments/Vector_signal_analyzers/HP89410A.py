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

        self.gpib_address = gpib_address
        self.gpib = None

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """

        if self.gpib_address is not None:
            print("Opening connnection to HP89410A vector signal analyzer")

            rm = visa.ResourceManager()
            try:
                self.gpib = rm.open_resource(self.gpib_address, timeout=5000)
            except BaseException:
                raise ValueError("Cannot connect to HP89410A vector signal analyzer")
        else:
            print("No GPIB address provided, please re-instantiate with an address")

    def close(self):
        print("Disconnecting HP89410A vector signal analyzer")
        # self.turn_off()
        self.gpib.close()

    def reset(self):
        self.gpib.write("*RST")

    def set_instrument_mode(self, mode="vector"):
        """
        Chooses operating mode of the instrument.

        `mode` (string): "vector", "scalar", or "demodulation"
        """
        if mode.lower() in ["vector", "scalar", "demodulation"]:
            self.gpib.write("INSTrument:SELect {:s}".format(mode.upper()))
        else:
            raise Warning("The provided mode is not an option for this instrument")

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

        self.gpib.write("INP%d:IMP %d;" % (channel, impedance))

    def turn_on(self, channel):
        """
        Activates the specified channel.
        :param channel: VSA channel (1 or 2)
        """

        if not (channel in [1, 2]):
            print("Channel number not correct. Doing nothing.")
            return

        self.gpib.write("INP%d:STAT ON;" % channel)

    def turn_off(self, channel):
        """
        Deactivates the specified channel.
        :param channel: VSA channel (1 or 2)
        """

        if not (channel in [1, 2]):
            print("Channel number not correct. Doing nothing.")
            return

        self.gpib.write("INP%d:STAT OFF;" % channel)

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
            self.gpib.write("SENS:FREQ:CENT {:s};".format(str(center)))

        if span is not None:
            self.gpib.write("SENS:FREQ:SPAN {:s};".format(str(span)))

        if start_freq is not None:
            self.gpib.write("SENS:FREQ:STAR {:s};".format(str(start_freq)))

        if end_freq is not None:
            self.gpib.write("SENS:FREQ:STOP {:s};".format(str(end_freq)))

    def set_y_unit(self, unit):
        """
        Specifes the y axis unit
        :param unit: Desired unit (string)
        """

        if not (
            unit
            in [
                "dB",
                "dBVrms",
                "V2/Hz",
                "Vrms2",
                "dBm",
                "dBVrms/rtHz",
                "Vpk",
                "Vrms2/Hz",
                "dBm/Hz",
                "pct",
                "Vpk/rtHz",
                "W",
                "dBV",
                "unitless",
                "Vpk2",
                "W/Hz",
                "dBV/rtHz",
                "V",
                "Vpk2/Hz",
                "Wrms",
                "dBVpk",
                "V/rtHz",
                "Vrms",
                "Wrms/Hz",
                "dBVpk/rtHz",
                "V2",
                "Vrms/rtHz",
            ]
        ):
            print("Specified unit not correct. Doing nothing.")
            return

        self.gpib.write("CALC:UNIT:POW %s;" % unit)

    def autoscale_y(self):
        self.gpib.write("DISP:WIND:TRAC:Y:AUTO ONCE;")

    def get_rbw(self):
        """
        Returns the resolution bandwidth setting, in Hz.
        """
        rbw = self.gpib.query_ascii_values("SENS:BAND:RES?")[0]
        return rbw

    def set_rbw(self, rbw):
        """
        Sets the resolution bandwidth.
        :param rbw: string with units or in Hz. Minimum is 300 mHz.
        """
        self.gpib.write("SENS:BAND:RES %s;" % rbw)

    def set_averaging(self, turn_on, av_type, num_averages):
        """
        Turn on or off the averaging with the specified number of averages.
        :param turn_on: if 1, it turns on averaging. If 0, it turns it off.
        :param av_type: averaging type. Either 'MAX' (hols the maximum at each point), 'RMS' (power average) or 'COMP'.
            'RMS' should be used in most cases.
        :param num_averages: number of averages to take.
        """

        if turn_on:
            self.gpib.write("SENS:AVER:STAT ON;")
            if not (type in ["MAX", "RMS", "COMP"]):
                self.gpib.write("SENS:AVER:TYPE RMS;")
            else:
                self.gpib.write("SENS:AVER:TYPE %s;" % av_type)

            self.gpib.write("SENS:AVER:COUN %d;" % num_averages)
        else:
            self.gpib.write("SENS:AVER:STAT OFF;")

    def set_num_points(self, num_points=401):
        """
        Sets the number of points to record per sweep.

        :param num_points: Desired number of points. Allowed
                values are 51, 101, 201, 401, 801, 1601

        """
        if num_points not in {51, 101, 201, 401, 801, 1601}:
            print("The specified number of points is not valid.")
            return
        self.gpib.write("SENSe:SWEep:POINts {:d}".format(num_points))

    def averages_taken(self):
        """
        Checks the number of averages taken
        """

        return self.gpib.query_ascii_values("SENS:AVER:COUN:INT?")[0]

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
        self.gpib.write("SYST:KEY 24;")  # KEY: Save/recall
        self.gpib.write("SYST:KEY 111;")  # KEY: F1
        self.gpib.write("SYST:KEY %d;" % (111 + data_reg_num))  # KEY: Shifted
        time.sleep(0.5)  # Give the system some time to finish saving

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

        xdata = np.array(xdata.split(","), dtype=float)
        ydata = np.array(ydata.split(","), dtype=float)

        # convert to V/sqrt(Hz)
        ydata = np.sqrt(ydata) / np.sqrt(2)

        if filename is not None:
            with open(filename + ".csv", "w+") as csvfile:
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

        self.set_averaging(0, "RMS", None)
        time.sleep(1)

        if isinstance(num_averages, list):
            change_aver = 1
        else:
            change_aver = 0
            self.set_averaging(1, "RMS", num_averages)

        if isinstance(rbws, list):
            change_rbw = True
        else:
            change_rbw = False
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
                self.set_averaging(1, "RMS", num_averages[idx])
                self.gpib.write("SYST:KEY 21;")  # KEY: Meas Restart

                time.sleep(20)
                # Wait for measurement
                while self.averages_taken() < num_averages[idx]:
                    print("Waiting")
                    time.sleep(10)

            else:
                # Start measuring
                self.gpib.write("SYST:KEY 21;")  # KEY: Meas Restart

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
            data_register = idx + 1
            xd, yd = self.retrieve_data(data_register)

            # returned data is sometimes outside the specified frequency bounds
            # Find closest frequencies and slice
            min_indx = np.abs(xd - freqs[idx]).argmin()
            max_indx = np.abs(xd - freqs[idx + 1]).argmin() + 1
            xd, yd = xd[min_indx:max_indx], yd[min_indx:max_indx]

            freq_regs.append(xd)
            sig_regs.append(yd)

        freq = np.concatenate(freq_regs, axis=-1)
        sig = np.concatenate(sig_regs, axis=-1)

        if filename is not None:
            with open(filename + ".csv", "w+") as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(freq)
                writer.writerow(sig)

        return freq, sig

    def set_trigger_holdoff_state(self, state="off"):
        """
        Sets the state (on/off) of the trigger holdoff option
        (a "dark time" following a trigger event, during which
        further trigger events are ignored).
        """

        if state.upper() in ["ON", "OFF"]:
            self.gpib.write("TRIGger:HOLDoff:STATe {:s}".format(state.upper()))
        else:
            raise Warning("State must be 'on' or 'off'.")

    def set_trigger_delay(self, delay, channel=1):
        """
        Sets the time delay between trigger and the beginning of data collection.
        Delay can be negative (pre-trigger delay) or positive (post-trigger delay).
        Both delay values are limited by the memory depth. The associated time bound
        is related to the time span set.

        `delay` is specified in milliseconds.
        `channel` (int): Specifies which channel's parameter to adjust. Can be 1 or 2.
        """

        self.gpib.write("SENSe:SWEep{:d}:TIME:DELay {:.1f}ms".format(channel, delay))

    def set_trigger_holdoff(self, holdoff):
        """
        Sets the "dark time", the duration after a trigger event during which other
        trigger events are ignored. Effectively sets upper bound on trigger frequency.

        `holdoff` must be between 0 and 41[sec].
        """
        if (holdoff >= 0) and (holdoff <= 41):
            self.gpib.write("TRIGger:HOLDoff:DELay {:.3f}s".format(holdoff))
        else:
            raise Warning("Specified holdoff time is invalid or out-of-bounds.")

    def set_trigger_level(self, level):
        """
        Sets the signal level at which a measurement is triggered.
        If the trigger type is external trigger (TRIG:SOUR EXT),
        the trigger signal is connected to the front panel connector
        labeled EXT TRIGGER and trigger level is entered in units of
        volts or %. The level is an analog voltage between -11V and
        +11V.

        :param level: Trigger level in volts.
        """
        if (level <= 11) and (level >= -11):
            self.gpib.write("TRIGger:LEVel {:0.2f}V".format(level))
        else:
            raise Warning("Specified level is not valid. Must be inside +/- 11 V.")

    def set_trigger_slope(self, slope="positive"):
        """
        Selects whether the trigger happens on rising ('positive') or falling ('negative')
        signal edges.
        """
        if slope.upper() in ["POSITIVE", "NEGATIVE"]:
            self.gpib.write("TRIGger:SLOPe {:s}".format(slope.upper()))
        else:
            raise Warning("State must be 'positive' or 'negative'.")

    def set_trigger_source(self, source="IMM"):
        """
        Sets the type of source off which measurements are triggered.
        Can be "IMM","INT1", "INT2", IF1/2, OUTP,
        BUS, or EXT.
        """
        if source.upper() in [
            "IMM",
            "INT1",
            "INT2",
            "IF1",
            "IF2",
            "OUTP",
            "BUS",
            "EXT",
        ]:
            self.gpib.write("TRIGger:SOURce {:s}".format(source.upper()))
        else:
            raise Warning("Invalid trigger source specified.")

    def set_gate_delay(self, delay=0.0, channel=1):
        """
        Specifies the time when the gate begins relative to the beginning
        of the main time record.

        `delay` (float): Delay time in milliseconds
        `channel` (int): Channel to adjust
        """

        msg = "SENSe:SWEep{:d}:TIME:GATE:DELay {:.1f}ms".format(channel, delay)
        self.gpib.write(msg)

    def set_gate_state(self, state="off", channel=1):
        """
        Enables or disables time gating

        `state` (string): 'on' or 'off'
        `channel` (int): Channel to adjust
        """
        if state.lower() in ["on", "off"]:
            msg = "SENSe:SWEep{:d}:TIME:GATE:STATe {:s}ms".format(
                channel, state.upper()
            )
            self.gpib.write(msg)
        else:
            raise Warning('Provided "state" must be "on" or "off".')

    def set_gate_span(self, span=5, channel=1):
        """
        Enables or disables time gating

        `span` (float): Gate duration in milliseconds
        `channel` (int): Channel to adjust
        """
        if span > 3.828:  # default value for 401 frequency points. Don't go lower
            msg = "SENSe:SWEep{:d}:TIME:GATE:SPAN {:.3f}ms".format(channel, span)
            self.gpib.write(msg)
        else:
            raise Warning('Provided "state" must be "on" or "off".')


if __name__ == "__main__":
    vsa = HP89410A()
    vsa.initialize()
    vsa.collect_signal_spectrum(
        freqs=["1", "100", "1000", "10000", "100e3", "1e6", "10e6"],
        num_averages=[600, 600, 200, 500, 500, 500],
        rbws=["1", "10", "50", "500", "5000", "50000"],
        filename="HP_1550_vib_isol",
    )
    vsa.close()
