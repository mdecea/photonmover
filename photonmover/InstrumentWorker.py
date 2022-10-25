"""
Class to perform basic operations from the GUI. These are all instances
of QObject so they can be esasily executed in other threads. This way,
we avoid the GUI from freezing.
"""

import time
from PyQt5.QtCore import QObject, pyqtSignal

from photonmover.Interfaces.Laser import Laser
from photonmover.Interfaces.Laser import TunableLaser
from photonmover.Interfaces.TunableFilter import TunableFilter
from photonmover.Interfaces.SourceMeter import SourceMeter
from photonmover.Interfaces.PowMeter import PowerMeter
from photonmover.Interfaces.ElectricalAttenuator import ElectricalAttenuator
from photonmover.Interfaces.WlMeter import WlMeter
from photonmover.Interfaces.TempController import TempController
from photonmover.instruments.DAQ.NI_DAQ import NiDAQ


class InstrumentWorker(QObject):
    """
    Controls any operation related to instruments coming directly form the GUI
    """

    # Signals need to be created this way and not in the __init__ method for
    # some reason
    done = pyqtSignal()  # Indicates that a specific operation is completed
    # This is the signal that will contain all the info for the stats
    # refreshing
    stats_vals = pyqtSignal(list)

    def __init__(self, instr_list, visa_lock, status_bar):
        super().__init__()
        self.instr_list = instr_list
        self.status_bar = status_bar
        self.visa_lock = visa_lock

    def laser_on(self, op):

        self.visa_lock.lock()
        lasers = self._find_instr_type_(Laser)

        for las in lasers:
            if op == "turn_off":
                # self.status_bar.showMessage('Turning off laser', 5000)
                las.turn_off()
            else:
                # self.status_bar.showMessage('Turning on laser', 5000)
                las.turn_on()

        self.done.emit()
        self.visa_lock.unlock()

    def set_laser_wav(self, set_wav, tunable_filter_follows_laser):

        self.visa_lock.lock()
        # You can only set the wavelength in a Tunable light source
        lasers = self._find_instr_type_(TunableLaser)
        power_meters = self._find_instr_type_(PowerMeter)
        tunable_filters = self._find_instr_type_(TunableFilter)

        for las in lasers:
            las.set_wavelength(set_wav)

        for p in power_meters:
            p.set_wavelength(set_wav)

        if tunable_filter_follows_laser:
            for tf in tunable_filters:
                tf.set_wavelength(set_wav)

        self.done.emit()
        self.visa_lock.unlock()

    def set_laser_power(self, set_power):

        self.visa_lock.lock()
        lasers = self._find_instr_type_(Laser)

        for las in lasers:
            las.set_power(set_power)

        self.done.emit()
        self.visa_lock.unlock()

    def set_pm_range(self, set_range):

        self.visa_lock.lock()

        pms = self._find_instr_type_(PowerMeter)

        if set_range == 'AUTO':
            power_range = set_range
        else:
            power_range = float(set_range)

        for pm in pms:
            pm.set_range(channel=None, power_range=power_range)

        self.done.emit()
        self.visa_lock.unlock()

    def set_tec_T(self, set_T):

        self.visa_lock.lock()
        tecs = self._find_instr_type_(TempController)

        for tec in tecs:
            tec.set_temperature(set_T)

        self.done.emit()
        self.visa_lock.unlock()

    def set_smu_volt(self, set_volt, smu_num=1):

        self.visa_lock.lock()

        # smu_num is the smu number to which we want to apply the setting.
        # the order is given by the oder in which the instruments are passed in
        # the instrument lust

        source_meters = self._find_instr_type_(SourceMeter)
        source_meters[smu_num - 1].set_voltage(set_volt)
        time.sleep(0.5)

        self.done.emit()
        self.visa_lock.unlock()

    def set_smu_cur(self, set_cur, smu_num=1):

        self.visa_lock.lock()
        source_meters = self._find_instr_type_(SourceMeter)

        source_meters[smu_num - 1].set_current(set_cur)
        time.sleep(0.5)

        self.done.emit()
        self.visa_lock.unlock()

    def set_smu_channel(self, set_chan, smu_num=1):

        self.visa_lock.lock()

        source_meters = self._find_instr_type_(SourceMeter)
        source_meters[smu_num - 1].set_channel(set_chan)
        time.sleep(0.5)

        self.done.emit()

        self.visa_lock.unlock()

    def set_el_att(self, set_att):

        self.visa_lock.lock()

        el_atts = self._find_instr_type_(ElectricalAttenuator)
        for el_att in el_atts:
            el_att.set_attenuation(set_att)

        time.sleep(0.5)

        self.done.emit()
        self.visa_lock.unlock()

    def set_tunable_filter_wav(self, set_wav):

        self.visa_lock.lock()

        tunable_filters = self._find_instr_type_(TunableFilter)

        for tf in tunable_filters:
            tf.set_wavelength(set_wav)

        self.done.emit()
        self.visa_lock.unlock()

    def get_stats(self, smu_mode, measure_smu):
        """
        Gets all the statistics describing the state of the setup.
        """

        self.visa_lock.lock()

        # Measured wavelength
        wav_meter = self._find_instr_type_(WlMeter)
        if wav_meter:
            meas_wav = wav_meter[0].get_wavelength()
        else:
            meas_wav = "NA"

        # Ask the SMU if it is time
        if measure_smu:
            smu = self._find_instr_type_(SourceMeter)
            if smu:
                if smu_mode == 'meas_volt':
                    smu_val = smu[0].measure_voltage()
                elif smu_mode == 'meas_cur':
                    smu_val = smu[0].measure_current()
            else:
                smu_val = "NA"
        else:
            smu_val = None

        # Power
        pm = self._find_instr_type_(PowerMeter)
        if pm:
            tap_power, rec_power = pm[0].get_powers()

        else:
            tap_power, rec_power = [0, 0]

        self.stats_vals.emit([meas_wav, smu_val, tap_power, rec_power])
        self.done.emit()

        self.visa_lock.unlock()

    def get_raman_stats(self, daq_channel):
        """
        Gets all the statistics describing the state of the Raman setup.
        """

        self.visa_lock.lock()

        # Measured wavelength
        wav_meter = self._find_instr_type_(WlMeter)
        if wav_meter:
            meas_wav = wav_meter[0].get_wavelength()
        else:
            meas_wav = "NA"

        # Power measured with power meter
        pm = self._find_instr_type_(PowerMeter)
        if pm:
            power, _ = pm[0].get_powers()

        else:
            power, _ = [0, 0]

        # Voltage measured with the DAQ
        daq = self._find_instr_type_(NiDAQ)
        daq.configure_channel_acq([daq_channel], 0.0, 10.0)
        v_daq = daq.read_data(num_points=1)

        self.stats_vals.emit([meas_wav, power, v_daq])
        self.done.emit()

        self.visa_lock.unlock()

    def _find_instr_type_(self, category):
        """
        Returns a list of the instruments with the specified category
        category is one of the instrument interfaces. Ex: Laser
        """
        lst = []

        for instr in self.instr_list:
            if isinstance(instr, category):
                lst.append(instr)

        return lst
