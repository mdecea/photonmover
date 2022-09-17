function [result, fs] = iqreadM3xxxA(arbConfig, chan, trigChan, duration, avg, maxAmpl, ~, trigDelay, trigLevel)
% read a waveform from scope
%
% arguments:
% arbConfig - if empty, use realtime scope address configured in IQTools config
% chan - cell array of scope channels to be captured ('1'-'4', 'DIFF1', 'DIFF2', 'REdge1', 'REdge3', 'DIFFREdge')
% trigChan - string with trigger channel ('1'-'4', 'AUX' or 'unused')
% duration - length of capture (in seconds)
% avg - number of averages (1 = no averaging)
% maxAmpl - amplitude of the signal (will be used to set Y scale)
%           if set to 0, will not set amplitude
%           if set to -1, will autoscale
% trigDelay - trigger delay (zero if not specified)
% trigLevel - trigger level (zero if not specified)
%
if (~exist('arbConfig', 'var'))
    arbConfig = [];
end
arbConfig = loadArbConfig(arbConfig);
if ((isfield(arbConfig, 'isScopeConnected') && arbConfig.isScopeConnected == 0) || ~isfield(arbConfig, 'visaAddrScope'))
    error('Scope address is not configured, please use "Instrument Configuration" to set it up');
end
if (~exist('chan', 'var'))
    chan = {'1' '2'};
end
if (~exist('trigChan', 'var'))
    trigChan = 'unused';
end
if (~exist('duration', 'var') || isempty(duration))
    duration = 1e-6;
end
if (~exist('avg', 'var') || isempty(avg) || avg < 1)
    avg = 1;
end
if (~exist('maxAmpl', 'var') || isempty(maxAmpl))
    maxAmpl = 800e-3;
end
if (~exist('trigDelay', 'var') || isempty(trigDelay))
    trigDelay = 0;
end
if (~exist('trigLevel', 'var') || isempty(trigLevel))
    trigLevel = 0;
end
numChan = length(chan);
result = [];
fs = 0;
pxiSlotNum = 6; %Digitizer Slot

% check, if driver has been called before (to speed up debugging)
if (fs >= 0)% && (~exist('driverHandle', 'var') || ~isa(driverHandle, 'KeysightSD1.SD_AOU') || ~driverHandle.isOpen))
    try
        NET.addAssembly(fullfile(getenv('KEYSIGHT_SD1_LIBRARY_PATH'), 'VisualStudio.NET\KeysightSD1.dll'));
        moduleHandle = KeysightSD1.SD_Module();
        moduleCount = moduleHandle.moduleCount();
        if (moduleCount == 0)
            errordlg('The SD1 device driver did not find any M320xA devices');
            return
        end
        f = KeysightSD1.SD_AIN();
        
        moduleIdx = -1;
        for indk = 0:(moduleHandle.moduleCount()-1)
            slot = moduleHandle.getSlot(indk);
            if (slot == pxiSlotNum)
                moduleIdx = indk;
                break;
            end
        end
        
        if (moduleIdx < 0)
            errordlg(sprintf('No SD1 Digitizer found in slot %d. Please set a valid Slot Number in the Instrument Configuration', pxiSlotNum));
            return;
        end
               
        chassis = moduleHandle.getChassis(moduleIdx);
        slot = moduleHandle.getSlot(moduleIdx);
		moduleType = char(moduleHandle.getProductName(moduleIdx));
		
        f.open('', chassis, slot);
        if(f.isOpen())
            if(KeysightSD1.SD_Object_Type.AIO ~= f.getType() && KeysightSD1.SD_Object_Type.AIN ~= f.getType())
                f.close();
            end;            
        end;

        if(~(f.isOpen()))
            errordlg(sprintf('No M33xxA or M31xxA Module found'));
            return;
        end
  
    catch e
        errordlg(sprintf('An error occurred during the initialization of the M31xxA device driver (SD1.SD_AIN) for module index %d', moduleIdx));
        return;
    end
    if (~f.isOpen)
        errordlg(sprintf('Can''t open M31xxA device driver (SD1.SD_AIN) for module index %d', moduleIdx));
        return;
    end
end

if (f == 0)
    return;
end

%model = xquery(f, '*IDN?');
%if (~isempty(strfind(model, 'MSO-X 4')))
    model4k = 1;
% else
%     model4k = 0;
% end

% if (avg > 1)
%     if (model4k)
%         xfprintf(f, sprintf(':ACQuire:COUNT %d', avg));
%     else
%         xfprintf(f, sprintf(':ACQuire:AVERage:COUNT %d', avg));
%     end
%     xfprintf(f, sprintf(':ACQuire:AVERage ON'));
% else
%     xfprintf(f, sprintf(':ACQuire:AVERage OFF'));
% end
% xfprintf(f, sprintf(':ACQuire:MODE RTIME'));
% if (~model4k)
%     xfprintf(f, sprintf(':ACQuire:RESPonse FLATmag'));
% end

channelCorrection = 0;
firstChannel = 0;
versionHW = f.getHardwareVersion();
if versionHW < 4
    channelCorrection = 1;
else
    firstChannel = 1;
end;

if (model4k)
    impedance = KeysightSD1.AIN_Impedance.AIN_IMPEDANCE_50;
else
    impedance = KeysightSD1.AIN_Impedance.AIN_IMPEDANCE_HZ;
end;

impedance = int32(impedance);
coupling = int32(KeysightSD1.AIN_Coupling.AIN_COUPLING_AC);
ampl = f.channelMaxFullScale(impedance, coupling);

if isempty(trigChan)
    triggerMode = KeysightSD1.SD_TriggerModes.AUTOTRIG;
else
    if (strncmpi(trigChan, 'REdge', 5))
        trigChan = trigChan(6:end);
    end

    if (strcmp(trigChan, 'AUX'))    % use AUX Trigger
        triggerMode = KeysightSD1.SD_TriggerModes.EXTTRIG;
        f.triggerIOconfig(KeysightSD1.SD_TriggerDirections.AOU_TRG_IN);
        trigChan = 0;
        if(strncmpi(moduleType, 'M33', 3))
            trigChan = 1;
        end;
    else
        if (strcmpi(trigChan, 'unused'))    % use the first measured channel as a trigger
            triggerMode = KeysightSD1.SD_TriggerModes.ANALOGAUTOTRIG;
            trigChan = chan{1};
        else                        % regular trigger channel
            triggerMode = KeysightSD1.SD_TriggerModes.ANALOGTRIG;
        end;
        trigChan = trigChan - '0' - channelCorrection;
        f.channelInputConfig(trigChan, ampl, impedance, coupling);
        f.channelTriggerConfig(trigChan, KeysightSD1.SD_AIN_TriggerMode.RISING_EDGE, trigLevel);
        trigChan = bitshift(1, trigChan - firstChannel);
    end
end;

fs = 100e6;
if(strncmpi(moduleType, 'M3102A', 6) || strncmpi(moduleType, 'M3302A', 6))
    fs = 500e6;
end;

numPts = round(duration * fs);

mask = 0;
for i = 1:numChan
    channel = chan{i} - '0' - channelCorrection;
    
    f.channelInputConfig(channel, ampl, impedance, coupling);

    f.DAQconfig(channel, numPts, 1, trigDelay, triggerMode);
    if(triggerMode == KeysightSD1.SD_TriggerModes.ANALOGTRIG || triggerMode == KeysightSD1.SD_TriggerModes.ANALOGAUTOTRIG)
        f.DAQanalogTriggerConfig(channel, trigChan);
    elseif(triggerMode == KeysightSD1.SD_TriggerModes.EXTTRIG)
        f.DAQdigitalTriggerConfig(channel, KeysightSD1.SD_TriggerExternalSources.TRIGGER_EXTERN + trigChan, KeysightSD1.SD_TriggerBehaviors.TRIGGER_RISE);
    end;
    mask = bitor(mask, bitshift(1, channel - firstChannel));
end

retry = 0;
%res = str2double(xquery(f, chkCmd));
%done = bitand(mask, uint32(res));
% wait max. 5 sec for a trigger event - otherwise fail (Z592 is particularly slow...)
% while (~done && retry < 50)
%     pause(0.1);
    f.DAQstopMultiple(15);
    f.DAQflushMultiple(15);
    f.DAQstartMultiple(mask);
%     done = bitand(mask, uint32(str2double(xquery(f, chkCmd))));
%     retry = retry + 1;
% end
% if (~done)
%     errordlg('Scope did not trigger. Please verify that the connections between AWG and scope match the configuration');
%     fclose(f);
%     return;
% end

result = zeros(numPts, numChan);
wfmpts = 0;
x_origin = 0;
x_increment = 1/fs;
y_origin = 0;
for i = 1:numChan
    channel = chan{i} - '0' - channelCorrection;
    data = NET.createArray('System.Int16', numPts);
    readPoints = f.DAQread(channel, data, 1000);
    data = double(data);
    a = data(1:readPoints);
    y_increment = f.channelFullScale(channel)/(bitshift(1, 15) - 1);
    yval = a .* y_increment + y_origin;
    result(:,i) = yval;
end
xval = linspace(x_origin, x_origin + (wfmpts - 1)*x_increment, wfmpts);
f.close();
if (nargout == 0)
    figure(1);
    plot(xval, result, '.-');
    grid on;
end



