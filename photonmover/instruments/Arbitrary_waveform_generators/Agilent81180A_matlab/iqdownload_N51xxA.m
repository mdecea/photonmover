function f = iqdownload_N51xxA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, amplitude, fCenter, segmName)
% Download IQ to MXG/MXG-X/EXG/ESG/PSG
% Ver 1.1, Robin Wang, Feb 2013
if (~isempty(sequence))
    errordlg('Sequence mode is not available for the Keysight VSG');
    f = [];
    return;
end

f = iqopen(arbConfig);
if (isempty(f))
    return;
end
% Walt Schulte added 10/11 to set visa object user data to the N5194A arb
% used for download
if ((strcmp(arbConfig.model, 'N5194A_250MHz')) || (strcmp(arbConfig.model, 'N5194A_2GHz')))
   f.UserData = arbConfig.model; 
end
%%%%%%%%%%%%%%%%
if ((strcmp(arbConfig.connectionType, 'visa')) || (strcmp(arbConfig.connectionType, 'tcpip')))
    f.ByteOrder = 'bigEndian';
else
    f.ByteOrder = 'littleEndian';
end
    
if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
    xfprintf(f, '*RST');
end

% prompt the user for center frequency and power
% defaults are the current settings
% added a conditional for scripting
if (isempty(amplitude) || isempty(fCenter) || isempty(segmName))
    fCenter      = query(f, ':freq? ');
    amplitude    = query(f, ':power?');
    segmName     = sprintf('IQTools%04d', segmNum); %WBS: needs to have .wfm extension?      % filename for the data in the ARB
    prompt       = {'Amplitude of Signal (dBm):', 'Carrier Frequency (Hz): ', 'Segment Name: '};
    defaultVal   = {sprintf('%g', eval(amplitude)), sprintf('%g', eval(fCenter)), sprintf(segmName)};
    dlg_title    = 'Inputs for VSG';
    user_vals    = inputdlg(prompt, dlg_title, 1, defaultVal);
    drawnow;

    if (isempty(user_vals))
        return;
    end
    
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
    
    if (isempty(user_vals{3}))
        segmName  = sprintf('IQTools%04d', segmNum);
    else     
        segmName  = user_vals{3};
    end
    
end

if ((strcmp(arbConfig.model, 'N5194A_250MHz')) || (strcmp(arbConfig.model, 'N5194A_2GHz')))
   downloadSignal(f, data.', segmName, fs, fCenter, amplitude, arbConfig.DACRange, arbConfig.LOIPAddr);
else
    downloadSignal(f, data.', segmName, fs, fCenter, amplitude, arbConfig.DACRange);
end

if (~keepOpen)
    fclose(f);delete(f); 
end
end


function downloadSignal(deviceObject, IQData, ArbFileName, sampleRate, centerFrequency, outputPower, scalingFactor, varargin)
% This function downloads IQ Data to the signal generator's non-volatile memory
% This function takes 2 inputs,
% * instrument object
% * The waveform which is a row vector.
% Syntax: downloadWaveform(instrObject, Test_IQData)

% Copyright 2012 The MathWorks, Inc.
% varargin{1} is vector UXG LO IP address
if ~isvector(IQData)
    error('downloadWaveform: invalidInput');
else
    IQsize = size(IQData); %WBS: if Wideband vector UXG, needs to be > 800 samples
    % User gave input as column vector. Reshape it to row vector.
    if ~isequal(IQsize(1),1)
        IQData = reshape(IQData,1,IQsize(1));
    end
end


%% Download signal
% Seperate out the real and imaginary data in the IQ Waveform
wave = [real(IQData);imag(IQData)];
wave = wave(:)';    % transpose the waveform

% Scale the waveform if necessary
tmp = max(abs([max(wave) min(wave)]));
if (tmp == 0)
    tmp = 1;
end

% ARB binary range is 2's Compliment -32768 to + 32767
% So scale the waveform to +/- 32767 not 32768
scale  = 2^15-1;
scale  = scale/tmp;
wave   = round(wave * scale);
modval = 2^16;
% Get data from double to unsigned int
wave = uint16(mod(modval + wave, modval));

% Some settings commands to make sure we don't damage the instrument
xfprintf(deviceObject,':OUTPut:STATe OFF');
xfprintf(deviceObject,':SOURce:RADio:ARB:STATe OFF');
xfprintf(deviceObject,':OUTPut:MODulation:STATe OFF');

% Write the data to the instrument 

% “[:SOURce]:FREQuency:LO:SOURce INTernal|EXTernal”
% initialize SCPI control of LO
% SCPI: “[:SOURce]:FREQuency:LO:CONTrol:SCPI:INITialize ON|OFF|1|0”
%
if strcmp(deviceObject.UserData, 'N5194A_250MHz')  
    %WBS: change to mode ARB
    xfprintf(deviceObject, ':INST:SEL VECT');
    xfprintf(deviceObject, ':FREQuency:LO:SOURce EXTernal');
    xfprintf(deviceObject, [':SYSTem:LO:COMMunicate:LAN:IP "' varargin{1} '"']); %WBS: not sure if the SPCI parser is reading IP addresses.   
    xfprintf(deviceObject, ':FREQuency:LO:CONTrol:SCPI:INITialize ON');
    binblockwrite(deviceObject,wave,'uint16',[':MEMory:DATA "WFM1:' ArbFileName '", ']);
    
elseif (strcmp(deviceObject.UserData, 'N5194A_2GHz'))
    %WBS: change to mode WARB
    xfprintf(deviceObject, ':INST:SEL WVEC');
    xfprintf(deviceObject, [':SYSTem:LO:COMMunicate:LAN:IP "' varargin{1} '"']);  %WBS: not sure if the SCPI parser is reading IP addresses. Cell2Str?
    xfprintf(deviceObject, ':FREQuency:LO:CONTrol:SCPI:INITialize ON');
    binblockwrite(deviceObject,wave,'uint16',[':MEMory:DATA "WFM1:' ArbFileName '", ']);    
else
    binblockwrite(deviceObject,wave,'uint16',[':MEMory:DATA "WFM1:' ArbFileName '", ']);
end
fprintf(deviceObject,'\n');

% Set the scaling to Scaling range
xfprintf(deviceObject, [':SOURce:RADio:ARB:RSCaling ' num2str(scalingFactor*100)]);

% Set the sample rate (Hz) for the signal.
% You can get this info for the standard signals by looking at the data in the 'waveforms' variable
xfprintf(deviceObject,[':SOURce:RADio:ARB:SCLock:RATE ' num2str(sampleRate)]); %WBS: no sample clock feature for N5194A W-ARB
% set center frequency (Hz)
xfprintf(deviceObject, [':SOURce:FREQuency ' num2str(centerFrequency)]); %WBS: turns LO RF off 
% set output power (dBm)
xfprintf(deviceObject, ['POWer ' num2str(outputPower)]);

% make sure output protection is turned on
%fprintf(deviceObject,':OUTPut:PROTection ON');
% turn off internal AWGN noise generation
% fprintf(deviceObject,':SOURce:RADio:ARB:NOISe:STATe OFF');

% Play back the selected waveform 

%WBS: turn on LVDS control of N5193A. "[:SOURce]:FREQuency:LO:CONTrol:FCPort[:STATe] ON|OFF|1|0"
xfprintf(deviceObject, [':SOURce:RAD:ARB:WAV "WFM1:' ArbFileName '"']);%wbs: command still valid for 250 MHz arb
%WBS: could be fprintf(deviceObject, [':SOURce:RAD:WARB:WAV "WFM1:'
%ArbFileName '"']); for wideband arb
opcComp = query(deviceObject, '*OPC?');
while str2double(opcComp)~= 1
    pause(0.5);
    opcComp = query(deviceObject, '*OPC?');
end

% ARB Radio on
xfprintf(deviceObject, ':SOURce:RADio:ARB:STATe ON');
% modulator on
xfprintf(deviceObject, ':OUTPut:MODulation:STATe ON');
% RF output on
xfprintf(deviceObject, ':OUTPut:STATe ON');

%Local Mode
xfprintf(deviceObject, 'SYST:COMM:GTL');
end


function xfprintf(f, s)
% Send the string s to the instrument object f
% and check the error status

% un-comment the following line to see a trace of commands
%    fprintf('cmd = %s\n', s);
    fprintf(f, s);
    count = 0;
    while (count<30)
        result = query(f, ':syst:err?');

        if (isempty(result))
            fclose(f);
            errordlg('Instrument did not respond to :SYST:ERR query. Check the instrument.', 'Error');
            error('Instrument did not respond to :SYST:ERR query. Check the instrument.');
            break;
        end

        if (~strncmpi(result, '+0,no error', 10) && ~strncmpi(result, '+0,"no error"', 12))
            errordlg(sprintf('Instrument returns error on cmd "%s". Result = %s\n', s, result));
        else
            break;
        end
        count = count + 1;
    end
end
