function f = iqdownload_M9383A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, amplitude, fCenter, segmName)
% Download IQ to N5194A
% Ver 0.1, Robin Wang, Feb 2013
% Ver 0.2, Thomas Wychock, Aug 2017
% Ver 1.0, Thomas Wychock, April 4, 2018

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
f.UserData = arbConfig.model;

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
    defaultVal   = {iqengprintf(eval(amplitude)), iqengprintf(eval(fCenter)), sprintf(segmName)};
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

downloadSignal(f, data.', segmName, fs, fCenter, amplitude, marker1, marker2, arbConfig.DACRange, arbConfig.LOIPAddr);

if (~keepOpen)
    fclose(f);delete(f); 
end

end


function downloadSignal(deviceObject, IQData, ArbFileName, sampleRate, centerFrequency, outputPower, marker1, marker2, scalingFactor, varargin)
% This function downloads IQ Data to the signal generator's non-volatile memory
% This function takes 2 inputs,
% * instrument object
% * The waveform which is a row vector.
% Syntax: downloadWaveform(instrObject, Test_IQData)

% Copyright 2012 The MathWorks, Inc.
% varargin{1} is vector UXG LO IP address

deviceObject.Timeout = 60;
xfprintf(deviceObject,'*CLS');

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
% For now we will just create a .MAT file and load and play this
fileLoadName = [pwd '\' ArbFileName '.mat'];
arbLoadName = ArbFileName;

%For some reason, the iqdata seems to be flipped...so I am reversing it
%here
IQData = imag(IQData) + real(IQData)*j;

iqsavewaveform(IQData, sampleRate, 'filename', strcat(ArbFileName,'.mat'));

% Once we do file transfer like instruments, we will modify
% % Seperate out the real and imaginary data in the IQ Waveform
% wave = [real(IQData);imag(IQData)];
% wave = wave(:)';    % transpose the waveform
% 
% % Scale the waveform if necessary
% tmp = max(abs([max(wave) min(wave)]));
% if (tmp == 0)
%     tmp = 1;
% end
% 
% % ARB binary range is 2's Compliment -32768 to + 32767
% % So scale the waveform to +/- 32767 not 32768
% scale  = 2^15-1;
% scale  = scale/tmp;
% wave   = round(wave * scale);
% modval = 2^16;
% % Get data from double to unsigned int
% wave = uint16(mod(modval + wave, modval));

% Some settings commands to make sure we don't damage the instrument
xfprintf(deviceObject,':OUTPut:STATe OFF');
xfprintf(deviceObject,':SOURce:RADio:ARB:STATe OFF');
xfprintf(deviceObject,':OUTPut:MODulation:STATe OFF');

% Write the data to the instrument 
% Right now just select file and link to VSG
xfprintf(deviceObject,[':MEMory:COPY:NAME "' fileLoadName '","' arbLoadName '"']);

% %IQ Data
% binblockwrite(deviceObject,wave,'uint16',[':MEMory:DATA "WFM1:' ArbFileName '", ']);
% fprintf(deviceObject,'\n');
% 
% %Create marker file
% if (~isempty(marker1) || ~isempty(marker2))
% 
%     %Marker 1, track the signal
%     if (~isempty(marker1))
%         %Normalize
%         marker1 = marker1/(max(marker1));
%     else
%         marker1 = zeros(length(wave));
%     end
% 
%     %Marker 2, invert to the signal
%     if (~isempty(marker2))
%         %Normalize
%         marker2 = uint16(2*(~(marker2/(max(marker2)))));
%     else
%         marker2 = zeros(length(wave));
%     end
% 
%     marker = uint8(marker1+marker2);
%     
%     %Marker Data
%     binblockwrite(deviceObject,marker,'uint8',[':MEMory:DATA "MKR1:' ArbFileName '", ']);
%     fprintf(deviceObject,'\n');
%     
% end

% Set the scaling to Scaling range
xfprintf(deviceObject, [':RADio:ARB:HEADer:SCALe:OVERride "' arbLoadName '",' num2str(scalingFactor)]);

% Set the sample rate (Hz) for the signal.
% You can get this info for the standard signals by looking at the data in the 'waveforms' variable
xfprintf(deviceObject,[':RADio:ARB:HEADer:SRATe:OVERride "' arbLoadName '",' num2str(sampleRate)]); %WBS: no sample clock feature for N5194A W-ARB
% set center frequency (Hz)
xfprintf(deviceObject, [':SOURce:FREQuency ' num2str(centerFrequency)]); %WBS: turns LO RF off 
% set output power (dBm)
xfprintf(deviceObject, ['POWer ' num2str(outputPower)]);

% make sure output protection is turned on
%fprintf(deviceObject,':OUTPut:PROTection ON');
% turn off internal AWGN noise generation
% fprintf(deviceObject,':SOURce:RADio:ARB:NOISe:STATe OFF');

% Play back the selected waveform 

xfprintf(deviceObject, ['RADio:ARB:WAVeform "' arbLoadName '"']);%wbs: command still valid for 250 MHz arb
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

end

function setAndWait(deviceObject, queryCommand, desiredState, setupCommand)
% Controls the VUXG to set its external LO accordingly
    modeCurrent = query(deviceObject, queryCommand);
    if (~strcmp(modeCurrent(1:numel(desiredState)), desiredState))    
        xfprintf(deviceObject, setupCommand);
        opcComp = query(deviceObject, '*OPC?');
        while str2double(opcComp)~= 1
            pause(0.5);
            opcComp = query(deviceObject, '*OPC?');
        end
    end

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

        if (~strncmpi(result, '0,No error', 10) && ~strncmpi(result, '0,"No error"', 12))
            errordlg(sprintf('Instrument returns error on cmd "%s". Result = %s\n', s, result));
        else
            break;
        end
        count = count + 1;
    end
end
