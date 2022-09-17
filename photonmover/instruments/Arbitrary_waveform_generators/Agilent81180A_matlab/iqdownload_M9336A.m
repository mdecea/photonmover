%
% Download a real or complex waveform into the M9336A
% This routine is NOT intended to be called directly from a user script.
% It should only be called via iqdownload()
%
function driverHandle = iqdownload_M9336A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 
%
% T.Dippon, Keysight Technologies 2017
%

% keep driverHandle as a global variable so that the value is kept across
% multiple calls to this function 
global driverHandle;

if (~isempty(sequence))
    errordlg('Sequence mode is not yet implemented for the M9336A');
    return;
end

% Access to M9336A is through IVI.NET and a special "Wrapper DLL".
% Determine where to search for the Wrapper DLL
arch = computer('arch');
if (strfind(arch, '64'))
    dllFolderPath = fullfile('C:', 'Program Files', 'Keysight', 'MAwg', 'bin');
else
    dllFolderPath = fullfile('C:', 'Program Files (x86)', 'Keysight', 'MAwg', 'bin');
end
% apparently, a 'cd' to the DLL directory is required
oldDir = cd();
try
    cd(dllFolderPath);
catch
    errordlg(sprintf('Expecting M9336A driver in directory: %s', dllFolderPath));
    return;
end
try
    asmInfo = NET.addAssembly(fullfile(dllFolderPath, 'KtMAwgDriverWrapper.dll'));
catch ex
    errordlg(sprintf('Can''t load M9336A driver (KtMAwgDriverWrapper.dll).\n%s', ex.message));
    cd(oldDir);
    return;
end
cd(oldDir);

% check, if driver has been called before (to speed up debugging)
if (fs >= 0 && (~exist('driverHandle', 'var') || ~isa(driverHandle, 'KtMAwgWrapper.KtMAwgWrapper') || ~driverHandle.IsInitialized))
    % call driver constructor
    hMsgBox = msgbox('Initializing driver. Please wait...', 'Please wait...', 'replace');
    try
        driverHandle = KtMAwgWrapper.KtMAwgWrapper();
    catch ex
        errordlg(['Error instantiating a KtMAwgWrapper object. Make sure that the M9336A Software is properly installed. ' ex.message]);
        driverHandle = [];
    end
    if (~isempty(driverHandle))
        try
            initOptions = 'QueryInstrStatus=true, simulate=false';
            driverHandle.Initialize(arbConfig.visaAddr, initOptions);
        catch ex
            if (strfind(ex.message, 'RSRC_LOCKED'))
                errordlg('Driver is locked. Do you have the SFP or another application still connected to this unit??');
            else
                errordlg(['Error initializing KtMAwgWrapper: ' ex.message]);
            end
            delete(driverHandle);
            driverHandle = [];
        end
    end
    try close(hMsgBox); catch; end
end
if (isempty(driverHandle))
    return;
end

% ignore channel 4 in case it was enabled
if (size(channelMapping, 1) > 3)
    channelMapping(4:end,:) = [];
end

% workaround for checking if the connection can be established (thereby
% opening the driver)  --> specify sampleRate = 0
if (fs == 0)
    return;
end

% workaround for closing the driver --> specify a negative sample rate
if (fs < 0)
    try
        driverHandle.Close();
        driverHandle.Dispose();
        delete(driverHandle);
    catch
    end
    driverHandle = [];
    return;
end

% stop waveform generation
driverHandle.AbortGeneration1();
% delete all waveforms
driverHandle.Arbitrary.ClearMemory();

% set up external 1/2 outputs as markers
try
    % I don't know how to query if a marker already exists without throwing and
    % error if it doesn't...   so, I'll use a try/catch block even though
    % it looks strange
    m1 = driverHandle.Markers.Item('M1');
catch
    driverHandle.Markers.Add('M1');
    m1 = driverHandle.Markers.Item('M1');
end
try
    m2 = driverHandle.Markers.Item('M2');
catch
    driverHandle.Markers.Add('M2');
    m2 = driverHandle.Markers.Item('M2');
end
m1.Configure('Channel1', 16, 'External1');
m2.Configure('Channel1', 17, 'External2');


% load the waveformss channel by channel
for ch = find(channelMapping(:,1))'
    gen_arb_M9336A(arbConfig, driverHandle, ch, real(data), marker1, fs, segmNum);
end
for ch = find(channelMapping(:,2))'
    gen_arb_M9336A(arbConfig, driverHandle, ch, imag(data), marker2, fs, segmNum);
end

% start waveform generation simultaneously on all channels
try
    driverHandle.InitiateGeneration('');
catch e
    if(isa(e, 'NET.NetException'))      
        if(isa(e.ExceptionObject, 'Keysight.KtMAwg.KtMAwgAggregateException'))
            msg = char(e.ExceptionObject.Message);        
            innerExceptions = e.ExceptionObject.InnerExceptions;
            for i=0:innerExceptions.Count-1    
                msg = sprintf('%s %s', msg, char(innerExceptions.Item(i).Message));
            end
            errordlg(msg);
           % throw(MException('initgen:error',msg));        
        end
    else
        errordlg(e.Message);
    %    throw(e);
    end
end



function gen_arb_M9336A(arbConfig, driverHandle, ch, data, marker, fs, segmNum)
% download a waveform to a single channel
channelName = sprintf('Channel%d', ch);
% set sample rate
driverHandle.Arbitrary.SetSampleRate(channelName, fs);
% convert waveform to 16 bit signed integers
dataInt16 = int16(32767 * data);
% convert marker to byte (= uint8)
markerUint8 = uint8(marker);
wfmName = sprintf('iqtools_ch%d_seg%d', ch, segmNum);
waveformHandle = driverHandle.Arbitrary.Waveform.CreateChannelWaveform1(channelName, wfmName, dataInt16, markerUint8);
driverHandle.Arbitrary.SetHandle(channelName, waveformHandle);
% set operating mode
driverHandle.SetOperationMode(channelName, KtMAwgWrapper.KtMAwgOperationModeEnum.Continuous);
% set output type
if (isfield(arbConfig, 'outputType') && strcmpi(arbConfig.outputType, 'Differential'))
    driverHandle.Output.SetTerminalConfiguration( channelName, KtMAwgWrapper.KtMAwgTerminalConfigurationEnum.Differential );
else
    driverHandle.Output.SetTerminalConfiguration( channelName, KtMAwgWrapper.KtMAwgTerminalConfigurationEnum.SingleEnded );
end
% set amplitude & offset
if (isfield(arbConfig,'amplitude'))
    aList = fixlength(arbConfig.amplitude, 3);
    gain = aList(ch);
    driverHandle.Arbitrary.SetGain(channelName, gain);
end
if (isfield(arbConfig,'offset'))
    oList = fixlength(arbConfig.offset, 3);
    offset = oList(ch);
    driverHandle.Arbitrary.SetOffset(channelName, offset);
end
% turn on output
driverHandle.Output.SetEnabled(channelName, true);


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, numel(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
