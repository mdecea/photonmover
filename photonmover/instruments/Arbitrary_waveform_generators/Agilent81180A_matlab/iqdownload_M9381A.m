function driver = iqdownload_M9381A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)
% download an IQ waveform to the M9381A, based on IVI-COM driver in
% Simulation Mode
% Ver 1.1, Robin Wang, Feb 2013

driver = [];
if (~isempty(sequence))
    errordlg('Sequence mode is not available for the Keysight M9381A');
    f = [];
    return;
end

try
    driver = evalin('base', 'M9381_driver');
catch e
end

if (isempty(driver))
    try
        driver =  instrument.driver.AgM938x();
    catch e
        errordlg({'Can''t open M9381A device driver (AgM938x):' e.message});
        return;
    end
end

% initOptions = 'QueryInstrStatus=true, simulate=false, DriverSetup=Trace=false';
initOptions = 'Simulate=false, DriverSetup= Trace=false'; 
idquery = true;
if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
    reset = true;
else
    reset = false;
end

if (~driver.Initialized)
    driver.Initialize(arbConfig.visaAddr, idquery, reset, initOptions);
end
% prompt the user for center frequency and power defaults are the current settings
fCenter      = driver.DeviceSpecific.RF.Frequency();
amplitude    = driver.DeviceSpecific.RF.Level();
prompt       = {'Amplitude of Signal (dBm):', 'Carrier Frequency (Hz): '};
defaultVal   = {sprintf('%g', amplitude), sprintf('%g', fCenter)};
dlg_title    = 'Inputs for VSG';
user_vals    = inputdlg(prompt, dlg_title, 1, defaultVal);
drawnow;

if (isempty(user_vals{1})) && (isempty(user_vals{2}))
    amplitude = 0;
    fCenter   = 1e9;
    warndlg('The amplitude is set to 0 dBm, and carrier frequency to 1 GHz')
else
    amplitude = user_vals{1};
    fCenter   = user_vals{2};
end

if (isempty(user_vals{1})) && ~(isempty(user_vals{2}))
    amplitude = 0;
    warndlg('The amplitude is set to 0 dBm')
else     
    amplitude = user_vals{1};
end

if ~(isempty(user_vals{1})) && (isempty(user_vals{2}))
    fCenter = 1e9;    
    warndlg('Carrier frequency is set to 1 GHz')
else
    fCenter = user_vals{2};
end

ArbFileName = sprintf('IQTools%04d', segmNum);       % filename for the data in the ARB

downloadSignal(driver, data.', ArbFileName, fs, fCenter, amplitude);


function downloadSignal(driver, IQData, ArbFileName, sampleRate, centerFrequency, outputPower);
% This function downloads IQ Data to the signal generator's non-volatile memory

if ~isvector(IQData)
    error('downloadWaveform: invalidInput');
else
    IQsize = size(IQData);
    % User gave input as column vector. Reshape it to row vector.
    if ~isequal(IQsize(1),1)
        IQData = reshape(IQData,1,IQsize(1));
    end
end
% Seperate out the real and imaginary data in the IQ Waveform
wave = [real(IQData);imag(IQData)];
wave = wave(:)';    % transpose the waveform

% stop the modulator before removing the ARB file
driver.DeviceSpecific.Modulation.Stop();
% remove arb file (from previous run)
driver.DeviceSpecific.Modulation.IQ.RemoveArb(ArbFileName);
%upload the waveform, start playback, and enable modulation
driver.DeviceSpecific.Modulation.IQ.UploadArbDoubles(ArbFileName, wave, sampleRate, 0, 0.75);
driver.DeviceSpecific.Modulation.Enabled = true;
% play the waveform, sending all changes to hardware
% AgM938xStartEventEnum.AgM938xStartEventImmediate = 0
driver.DeviceSpecific.Modulation.PlayArb(ArbFileName, 0);

% Set center frequency (Hz);  set output power (dBm)
driver.DeviceSpecific.RF.Configure(str2num(centerFrequency), str2num(outputPower));
driver.DeviceSpecific.RF.OutputEnabled = true;
% The properties don't take effect until the driver is notified.
driver.DeviceSpecific.Apply();
assignin('base', 'M9381_driver', driver);



        
        
