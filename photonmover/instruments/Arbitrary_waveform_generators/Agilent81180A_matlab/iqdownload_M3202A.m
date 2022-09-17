function driverHandle = iqdownload_M3202A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)
% download an IQ waveform to the M320xA
% This routine is NOT intended to be called directly from a user script
% It should only be called via iqdownload()
%
% Guy McBride, Thomas Dippon, Keysight Technologies 2017
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

% keep driverHandle as a global variable so that the value is kept across
% multiple calls to this function 
global driverHandle;

if (~isempty(sequence))
    errordlg('Sequence mode is not yet implemented for the M320xA');
    return;
end
if (isfield(arbConfig, 'SD1ModuleIndex'))
    pxiSlotNum = arbConfig.SD1ModuleIndex;
else
    pxiSlotNum = 0;
end

% check, if driver has been called before (to speed up debugging)
if (fs >= 0 && (~exist('driverHandle', 'var') || ~isa(driverHandle, 'KeysightSD1.SD_AOU') || ~driverHandle.isOpen()))
    try
        NET.addAssembly(fullfile(getenv('KEYSIGHT_SD1_LIBRARY_PATH'), 'VisualStudio.NET\KeysightSD1.dll'));
        moduleHandle = KeysightSD1.SD_Module();
        if (moduleHandle.moduleCount() == 0)
            errordlg('The SD1 device driver did not find any M320xA devices');
            return
        end
        
        %Use moduleIdx as Slot and obtain the actual index for the given
        %slot. In this way in the GUI the user can select the slot
        moduleIdx = -1;
        for indk = 0:(moduleHandle.moduleCount()-1)
            slot = moduleHandle.getSlot(indk);
            if (slot == pxiSlotNum)
                moduleIdx = indk;
                break;
            end
        end
        
        if (moduleIdx < 0)
            errordlg(sprintf('No SD1 AWG found in slot %d. Please set a valid Slot Number in the Instrument Configuration', pxiSlotNum));
            return;
        end
        
        moduleType = moduleHandle.getProductName(moduleIdx);
        chassis = moduleHandle.getChassis(moduleIdx);
        
        driverHandle = KeysightSD1.SD_AOU();
        driverHandle.open(moduleType, chassis, slot);
        if (driverHandle.getType() ~= KeysightSD1.SD_Object_Type.AOU && ...
            driverHandle.getType() ~= KeysightSD1.SD_Object_Type.AIO)
            driverHandle.close();
            driverHandle = [];
            errordlg(sprintf('unexpected module type found at index %d. Please check instrument configuration', moduleIdx));
            return;
        end
    catch e
        errordlg(sprintf('An error occurred during the initialization of the N320xA device driver (SD1.SD_AOU) for module index %d', moduleIdx));
        driverHandle = [];
        return;
    end
    if (~driverHandle.isOpen())
        errordlg(sprintf('Can''t open N320xA device driver (SD1.SD_AOU) for module index %d', moduleIdx));
        return;
    end
end

% for checking if the connection can be established (thereby
% opening the driver)  --> specify sampleRate = 0
if (fs == 0)
    return;
end

% workaround for closing the driver --> specify a negative sample rate
if (fs < 0)
    try
        driverHandle.close();
        delete(driverHandle);
    catch
    end
    driverHandle = [];
    return;
end


% finally, download the waveforms
for col = 1:size(channelMapping, 2) / 2
    for ch = find(channelMapping(:, 2*col-1))'
        gen_arb_M320xA(arbConfig, driverHandle, ch, real(data(:,col)), marker1, fs, segmNum);
    end
    for ch = find(channelMapping(:, 2*col))'
        gen_arb_M320xA(arbConfig, driverHandle, ch, imag(data(:,col)), marker2, fs, segmNum);
    end
end
% make sure all channels are in sync my stopping and restarting all 4
driverHandle.AWGstopMultiple(15);
driverHandle.AWGstartMultiple(15);

if (~exist('keepOpen', 'var') || keepOpen == 0)
    driverHandle.close();
end
end


function gen_arb_M320xA(arbConfig, driverHandle, chan, data, marker, fs, segm_num)
% download a waveform <data> to a single channel <chan>
%
chan = chan - 1; % channel numbers start at zero
firstCh = 1;

if(driverHandle.getHardwareVersion()<4.0)
    firstCh = 0;
end;

prescaler = 0;

if(strcmp(arbConfig.model,'M3201A_CLV'))
    minFclk = 100e6;
    if( (minFclk>0) && (fs<=minFclk) )
        prescaler = floor(max(arbConfig.maximumSampleRate)/fs/5);
        fs = fs*prescaler*5;
    end    
elseif(strcmp(arbConfig.model,'M3202A_CLV'))
    minFclk = 400e6;
    % Precaler 0 => 400M - 1G => Fs = Fclk
    % Precaler 1 =>  80M - 200M => Fs = Fclk/(1*5)
    % Precaler 2 =>  40M - 100M => Fs = Fclk/(2*5)
    % Precaler 3 =>  13.3333M - 33.3333M => Fs = Fclk/(n*10)
    % Precaler 4 =>  10M - 25M => Fs = Fclk/(n*10)
    
    if( (minFclk>0) && (fs<(1e9/30)) ) %<=33.333333M
        errordlg(sprintf('Range not implemented'));
        return;
        
    elseif( (minFclk>0) && (fs<(400e6/10)) ) %33.33333M< f <40M
        errordlg(sprintf('Invalid Frequency'));
        return;
        
    elseif( (minFclk>0) && (fs<(1e9/10)) ) %40M<= f <=100M
        errordlg(sprintf('Range not implemented'));
        return;
        
    elseif( (minFclk>0) && (fs<(1e9/5)) ) %100M< f <=200M
        errordlg(sprintf('Range not implemented'));
        return;
        
    elseif( (minFclk>0) && (fs<(400e6)) ) %200M< f <400M
        errordlg(sprintf('Invalid Frequency'));
        return;
        
    else %400M< f <1G
        prescaler = 0;
    end  
end



% set the sample rate, but only if the "variable sample rate" model has been selected
if (~isempty(strfind(arbConfig.model, 'CLV')))
    driverHandle.clockSetFrequency(fs, 1);
    pause(0.01); % You may need to at a Sleep of 1ms here (comment from Nestor)
end
% set the amplitude, if it has been configured, otherwise leave it alone
if (isfield(arbConfig,'amplitude'))
    ampl = fixlength(arbConfig.amplitude, 4);
    driverHandle.channelAmplitude(chan+firstCh, ampl(chan+1));
% else
%     driverHandle.channelAmplitude(chan, 0.5);
end
% and finally, load the waveform...
driverHandle.channelWaveShape(chan+firstCh, KeysightSD1.SD_Waveshapes.AOU_AWG);
driverHandle.AWG(chan+firstCh, 0, 0, 0, prescaler, KeysightSD1.SD_WaveformTypes.WAVE_ANALOG, data);
end


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, numel(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
end


