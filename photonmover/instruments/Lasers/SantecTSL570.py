import pyvisa as visa
import time
from photonmover.Interfaces.Laser import TunableLaser
from photonmover.Interfaces.Instrument import Instrument
import matplotlib.pyplot as plt

SANTEC_TSL570_GPIB_ADDRESS = 1
SANTEC_TSL570_STEP_SWEEP_MIN_DWELL_TIME = 0.1 # [s], consistent with both instrument units and sleep()

SANTEC_TSL570_MAX_WAV = 1380 # [nm]
SANTEC_TSL570_MIN_WAV = 1240 # [nm]
SANTEC_TSL_FULL_WAVRANGE_MAX_POWER = 7 # [dBm] ~ 5mW, 10mW from 1260-1360nm

# Class implemented using SPCI standard in the manual
class SantecTSL570(Instrument, TunableLaser):

    def __init__(self, gpib_address=SANTEC_TSL570_GPIB_ADDRESS, wait=0.5):
        super().__init__()
        self.gpib_address = gpib_address
        self.wait = wait
        self.step_sweep_dwell_time = SANTEC_TSL570_STEP_SWEEP_MIN_DWELL_TIME
        self.sweep_dwell_time = self.step_sweep_dwell_time

        self.valid_sweep_speeds = {1, 2, 5, 10, 20, 50, 100, 200}

    #### Basic functions ####
    def initialize(self):

        print('Opening connnection to Santec TSL570 laser')
        rm = visa.ResourceManager()
        self.gpib = rm.open_resource("GPIB0::%d" % (self.gpib_address))

        return self.get_id()

    def close(self):
        print('Closing connnection to Santec TSL570 laser')
        self.gpib.close()

    def get_id(self):
        self.gpib.write("*IDN?")
        return self.gpib.read_raw()

    def reset(self):
        self.gpib.write("*RST")

        # mode = 0 --> dBm
    
    def turn_on(self):
        self.gpib.write(":POW:STAT 1")

    def turn_off(self):
        self.gpib.write(":POW:STAT 0")

    def is_on(self):
        return int(self.gpib.query(":POW:STAT?"))

    def set_wavelength(self, wav):
        "Set the wavelength [nm]"
        self.gpib.write(":WAV %.4fnm" % wav)

    def get_wavelength(self):
        "Get the wavelength [nm]"
        return float(self.gpib.query("WAV?")) * 1e9

    def set_wavelength_units(self, mode):
        "mode (int) : 0 [nm], 1 [THz]"
        self.gpib.write(":WAV:UNIT %d" % mode)

    def get_wavelength_units(self):
        "0 [nm], 1 [THz]"
        return int(self.gpib.query(":WAV:UNIT?"))

    def set_power(self, pow):
        "pow (float) [mW]"
        self.gpib.write(":POW %.2fmW" % pow)
        
    def get_power(self):
        "Returns power in units sepcified by get_power_units()"
        return float(self.gpib.query(":POW?"))
    
    def get_monitored_power(self):
        "Returns power measured by built-in power monitor in units sepcified by get_power_units()"
        return float(self.gpib.query(":POW:ACT?"))
    
    def set_shutter(self, mode):
        "mode (int) : 0 [open], 1 [closed]"
        self.gpib.write(":POW:SHUT %d" % mode)

    def get_shutter_status(self):
        return int(self.gpib.query(":POW:SHUT?"))
        
    def set_power_units(self, mode):
        "mode (int) : 0 [dBm], 1 [mW]"
        self.gpib.write(":POW:UNIT %d" % mode)

    def get_power_units(self):
        "0 [dBm], 1 [mW]"
        return int(self.gpib.query(":POW:UNIT?"))

    def get_state(self):
        """
        Returns a list with the following elements:
        1. The current wavelength
        2. The current power
        3. If the laser is on or off.
        """
        wav = self.get_wavelength()
        pow = self.get_power()
        is_on = self.is_on()

        return [wav, pow, is_on]
    
    #### Sweep functions ####

    # Set sweep parameters
    def set_sweep_mode(self, mode):
        """
        mode (int) 
        0: Step sweep mode and One way 
        1: Continuous sweep mode and One way 
        2: Step sweep mode and Two way 
        3: Continuous sweep mode and Two way
        """
        self.gpib.write(":WAV:SWE:MOD %d" % mode)

    def set_sweep_wavelength_start(self, wav):
        "wav (float) [nm], up to 4 decimal places are relevant"
        self.gpib.write(":WAV:SWE:STARt %.4fnm" % wav)

    def set_sweep_wavelength_stop(self, wav):
        "wav (float) [nm], up to 4 decimal places are relevant"
        self.gpib.write(":WAV:SWE:STOP %.4fnm" % wav)

    def set_sweep_wavelength_step(self, step):
        "step (float) [nm], 0.0001 nm is the minimum step size"
        self.gpib.write(":WAV:SWE:STEP %.4fnm" % step)

    def set_sweep_step_dwell(self, dwell):
        "dwell (float) [s], 0.0 to 99.9s, only 1 decimal place relevant"
        self.gpib.write(":WAV:SWE:DWEL %.1f" % dwell)

    def set_sweep_cont_speed(self, speed):
        """
        speed (int) [nm/s]
        Range: 1 to 200 nm/s 
        Selection: 1,2,5,10,20,50,100,200 (nm/s)
        """
        self.gpib.write(":WAV:SWE:SPE %d" % speed)

    def set_sweep_cycles(self, cycles):
        "cycles (int) - number of sweep repetitions"
        self.gpib.write(":WAV:SWE:CYCL %d" % cycles)

    def set_cycle_delay(self, delay):
        """
        delay (float) [s] - delay between consequent scans
        Range: 0 to 999.9 sec 
        Step: 0.1 sec
        """
        self.gpib.write(":WAV:SWE:DEL %.1f" % delay)

    # Get sweep parameters
    def get_sweep_mode(self):
        """
        0: Step sweep mode and One way 
        1: Continuous sweep mode and One way 
        2: Step sweep mode and Two way 
        3: Continuous sweep mode and Two way
        """
        return int(self.gpib.query(":WAV:SWE:MOD?"))

    def get_wavelength_range_min(self):
        """Reads out the minimum wavelength in the configurable sweep range"""
        return float(self.gpib.query(":WAV:SWE:RANG:MIN?")) * 10**9

    def get_wavelength_range_max(self):
        "Reads out the maximum wavelength in the configurable sweep range"
        return float(self.gpib.query(":WAV:SWE:RANG:MAX?")) * 10**9

    def get_sweep_wavelength_start(self):
        "Returns wavelength sweep start [nm]"
        return float(self.gpib.query(":WAV:SWE:STARt?")) * 10**9

    def get_sweep_wavelength_stop(self):
        "Returns wavelength sweep stop [nm]"
        return float(self.gpib.query(":WAV:SWE:STOP?")) * 10**9

    def get_sweep_wavelength_step(self):
        "Returns wavelength sweep step [nm]"
        return float(self.gpib.query(":WAV:SWE:STEP?")) * 10**9
    
    def get_sweep_step_dwell(self):
        "Returns step sweep dwell time [s]"
        return float(self.gpib.query(":WAV:SWE:DWEL?"))
    
    def get_sweep_cont_speed(self):
        """
        Range: 1 to 200 nm/s 
        Selection: 1,2,5,10,20,50,100,200 (nm/s)
        """
        return int(float(self.gpib.query(":WAV:SWE:SPE?")))
    
    def get_sweep_cycles(self):
        "Returns number of sweep cycles (repetitions)"
        return int(self.gpib.query(":WAV:SWE:CYCL?"))
    
    def get_cycle_delay(self):
        """
        Return delay between consequent scans [s]
        Range: 0 to 999.9 sec 
        Step: 0.1 sec
        """
        return float(self.gpib.query(":WAV:SWE:DEL?"))
    
    # Sweep control functions
    def set_sweep_status(self, state):
        "state (int), 0: stop, 1: start - different from softtrigger command"
        self.gpib.write(":WAV:SWE %d" % state)

    def get_sweep_status(self):
        """
        0: Stopped 
        1: Running 
        3: Standing by trigger 
        4: Preparation for sweep start
        """
        return int(self.gpib.query(":WAV:SWE?"))
    
    def repeat_sweep(self):
        "Starts a repeat scan"
        self.gpib.write(":WAV:SWE:REP")
    
    def get_sweep_count(self):
        "(int) Read out the current number of completed sweeps"
        return int(self.gpib.query(":WAV:SWE:COUN?"))

    #### I/O (trigger-related) functions ####
    def get_min_trigger_step(self, speed):
        """
        speed (int) : sweep speed [nm/s]
        Returns the minimum trigger step [nm] when operating in wavelength constant mode
        """
        assert speed in self.valid_sweep_speeds

        d = {
            1 : 0.2e-3,
            2 : 0.2e-3,
            5 : 0.5e-3,
            10 : 1.0e-3,
            20 : 1.0e-3,
            50 : 2.5e-3,
            100 : 5.0e-3,
            200 : 10.0e-3
        }

        return d[speed]
    
    def soft_trigger(self):
        """
        TODO - last function to test
        Issues a soft trigger. 
        Executes sweep from trigger standby mode.
        """
        self.gpib.write(":TRIG:INP:SOFT")

    def set_ext_trig_setting(self, mode):
        """
        Enables / Disables external trigger input.
        mode (int)
        0 : Enable
        1 : Disable
        """
        self.gpib.write(":TRIG:INP:EXT %d" % mode)

    def set_input_trig_polarity(self, mode):
        """
        Sets input trigger polarity
        mode (int)
        0: High Active / Triggers at rising edge 
        1: Low Active / Triggers at falling edge
        """
        self.gpib.write(":TRIG:INP:ACT %d" % mode)

    def set_standby(self, mode):
        """
        Sets the device in trigger signal input standby mode.
        mode (int)
        0: Normal operation mode 
        1: Trigger standby mode
        """
        self.gpib.write(":TRIG:INP:STAN %d" % mode)

    def set_trig_out_timing(self, mode):
        """
        Sets the timing of the trigger signal output.
        mode (int)
        0: None 
        1: Stop 
        2: Start 
        3: Step
        """
        self.gpib.write(":TRIG:OUTP %d" % mode)

    def set_trig_out_polarity(self, mode):
        """
        Sets output trigger polarity.
        mode (int)
        0: High Active / Triggers at rising edge 
        1: Low Active / Triggers at falling edge
        """
        self.gpib.write(":TRIG:OUTP:ACT %d" % mode)

    def set_trig_out_step(self, wav_step):
        """
        Sets the interval of the trigger signal output.
        wav_step (float) [nm]
        """
        self.gpib.write(":TRIG:OUTP:STEP %.4fnm" % wav_step)

    def set_trig_out_setting(self, mode):
        """
        Sets the output trigger period mode.
        0: Sets the output trigger to be periodic in wavelength. 
        1: Sets the output trigger to be periodic in time.
        """
        self.gpib.write(":TRIG:OUTP:SETT %d" % mode)

    def set_trig_through(self, mode):
        """
        Sets the trigger through mode. 
        When On is selected, input trigger signal is put through to the output trigger port. 
        Trigger signal is re-shaped according to polarity setting.
        mode (int) 
        0 : OFF
        1 : ON
        """
        self.gpib.write(":TRIG:THR %d" % mode)

    def get_ext_trig_setting(self):
        """
        Reads out the setting of external trigger input.
        0: Disable 
        1: Enable
        """
        return int(self.gpib.query(":TRIG:INP:EXT?"))
    
    def get_input_trig_polarity(self):
        """
        Reads out input trigger polarity.
        0: High Active / Triggers at rising edge 
        1: Low Active / Triggers at falling edge
        """
        return int(self.gpib.query(":TRIG:INP:ACT?"))
    
    def get_standby(self):
        """
        Reads out the trigger signal input standby mode.
        0: Normal operation mode 
        1: Trigger standby mode
        """
        return int(self.gpib.query(":TRIG:INP:STAN?"))
    
    def get_trig_out_timing(self):
        """
        Reads out the timing setting of the trigger signal output.
        0: None 
        1: Stop 
        2: Start
        3: Step
        """
        return int(self.gpib.query(":TRIG:OUTP?"))
    
    def get_trig_out_polarity(self):
        """
        Reads out output trigger polarity.
        0: High Active / Triggers at rising edge 
        1: Low Active / Triggers at falling edge
        """
        return int(self.gpib.query(":TRIG:OUTP:ACT?"))
    
    def get_trig_out_step(self):
        """
        Reads out the interval of the trigger signal output [nm]
        """
        return float(self.gpib.query(":TRIG:OUTP:STEP?")) * 10**9
    
    def get_trig_out_setting(self):
        """
        Reads out the output trigger period mode.
        0: Sets the output trigger to be periodic in wavelength. 
        1: Sets the output trigger to be periodic in time.
        """
        return int(self.gpib.query(":TRIG:OUTP:SETT?"))

    def get_trig_through(self):
        """
        Reads out the trigger through mode.
        0: OFF 
        sa1: ON
        """
        return int(self.gpib.query(":TRIG:THR?"))

if __name__ == '__main__':
    myLaser = SantecTSL570(SANTEC_TSL570_GPIB_ADDRESS)
    print(myLaser.initialize())
    myLaser.close()