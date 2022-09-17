# -*- coding: utf-8 -*-
# Copyright 2020 Nate Bogdanowicz, Dodd Gray
"""
Driver module for Ibsen spectrometers.
"""
import numpy as np
from time import sleep


_INST_PARAMS_ = ['visa_address']
# _INST_VISA_INFO_ = {
#     'Eagle': ('JETI_PIC_VERSA',['']),
# }

def _check_visa_support(visa_rsrc):
    rt0 = visa_rsrc.read_termination
    wt0 = visa_rsrc.write_termination
    br0 = visa_rsrc.baud_rate
    visa_rsrc.read_termination = visa_rsrc.CR
    visa_rsrc.write_termination = visa_rsrc.CR
    visa_rsrc.baud_rate = 921600
    try:
        idn = visa_rsrc.query('*IDN?')
        if idn=="JETI_PIC_VERSA":
            return "Eagle"
        else:
            visa_rsrc.read_termination = rt0
            visa_rsrc.write_termination = wt0
            visa_rsrc.baud_rate = br0
            return None
    except:
        visa_rsrc.read_termination = rt0
        visa_rsrc.write_termination = wt0
        visa_rsrc.baud_rate = br0
        return None


class Eagle(Instrument):
    _INST_PARAMS_ = ['visa_address']

    def _initialize(self):
        self._rsrc.read_termination = self._rsrc.CR
        self._rsrc.write_termination = self._rsrc.CR
        self._rsrc.baud_rate = 921600
        self.spec_number = int(self.query('*PARA:SPNUM?').split()[-1])
        self.n_pixels = int(self.query('*PARA:PIX?').split()[-1])
        self.fit_params = [float(self.query(f'*PARA:FIT{j}?').split()[-1]) for j in range(5)] # quintic polynomial fit for wavelength vs pixel number
        self.wl = np.polyval(self.fit_params[::-1],np.arange(self.n_pixels)) # calculate wavelength array for this spectrometer
        self.serial_number = int(self.query('*PARA:SERN?').split()[-1])
        self.sensor = int(self.query('*PARA:SENS?').split()[-1])
        self.adc_res = int(self.query('*PARA:ADCR?').split()[-1])

    t_int = SCPI_Facet('*CONF:TINT', convert=int, units='ms')
    n_ave = SCPI_Facet('*CONF:AVE', convert=int, units='ms')

    def spectrum(self,t_int=10*u.ms):
        self._rsrc.write(f'*MEAsure {int(t_int.to(u.ms).m)} 1 2')
        sleep(t_int.to(u.second).m + 0.05)
        counts = np.array([int(val) for val in self._rsrc.read().split()[1:]])
        return counts

    def spectrum_raw(self,t_int=10*u.ms):
        self._rsrc.write(f'*MEAsure {int(t_int.to(u.ms).m)} 1 2')
        sleep(t_int.to(u.second).m + 0.05)
        counts_raw = self._rsrc.read_raw()
        return counts_raw
