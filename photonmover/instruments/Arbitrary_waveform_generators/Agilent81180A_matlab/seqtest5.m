function seqtest5()
% Demonstration of M8190A/M8195A sequencing and memory ping-pong capabilities
% This demo can also be used to show dynamic sequencing (see line 66)
%
% Instrument Configuration has to be set up using IQtools config dialog
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 


% make sure that we can connect to the M8190A/95A and have the right licenses
if (~iqoptcheck([], {'bit', 'M8195A'}, 'SEQ'))
    return;
end
f = iqopen();
xfprintf(f, ':abort');

% use the default sample rate for this AWG
arbConfig = loadArbConfig();
fs = arbConfig.defaultSampleRate;
% define the segment length (make sure it divides evenly into 64 as well as
% 48, so that it can run in 12 bit as well as 14 bit mode (M8190A)
% Also divides by 128 for the M8195A
segLen = 7680;
% set up a couple of waveform segments
% single pulse
s1 = iqpulsegen('pw', segLen/2, 'off', segLen/2, 'rise', 0, 'fall', 0);
s1(segLen) = 0;
% noise
s2 = rand(segLen, 1) - 0.5;
s2(segLen) = 0;
% a triangle waveform
s3 = iqpulsegen('pw', 0, 'off', 0, 'rise', segLen/4, 'fall', segLen/4, 'high', [0.5 -0.5], 'low', 0);
% a sinusoidal waveform
s4 = 0.75*sin(2*pi*(1:segLen)/segLen);

loadSegments = 1;
if (loadSegments)
    % start from scratch and delete all segments
    iqseq('delete', [], 'keepOpen', 1);
    % download the waveform segments - identical data on channel 1 and 2
    iqdownload(complex(real(s1), real(s1)), fs, 'segmentNumber', 1, 'keepOpen', 1, 'run', 0);
    iqdownload(complex(real(s2), real(s2)), fs, 'segmentNumber', 2, 'keepOpen', 1, 'run', 0);
    iqdownload(complex(real(s3), real(s3)), fs, 'segmentNumber', 3, 'keepOpen', 1, 'run', 0);
    iqdownload(complex(real(s4), real(s4)), fs, 'segmentNumber', 4, 'keepOpen', 1, 'run', 0);
end

setupSequence = 1;
if (setupSequence)
    % and set up the sequence
    clear seq;
    for i = 1:4
        seq(i).segmentNumber = i;
        seq(i).segmentLoops = 1;
        seq(i).segmentAdvance = 'Auto';
        seq(i).sequenceInit = 1;
        seq(i).sequenceEnd = 1;
    end
    iqseq('define', seq, 'keepOpen', 1, 'run', 0);
end

%%
% demo for dynamic sequencing
%
dyn = 1;    % set dyn=1 to enable dynamic switching between segments
if (dyn)
    xfprintf(f, ':abort');
    xfprintf(f, ':func1:mode sts');
    if (~isempty(strfind(arbConfig.model, 'M8190A')))
        xfprintf(f, ':func2:mode sts');
    end
    xfprintf(f, ':stab1:dyn on');
    if (~isempty(strfind(arbConfig.model, 'M8190A')))
        xfprintf(f, ':stab2:dyn on');
    end
    xfprintf(f, ':init:imm');
    % select a couple of segments - alternatively, use dynamic sequence
    % control connector
    hMsgBox = xmsgbox('Dynamic sequencing demo running...', 'Dynamic sequence demo');
    while true
        seg = randi([0,3]);
        xfprintf(f, sprintf(':stab:dyn:sel %d', seg));
        if (updateDialog(hMsgBox, sprintf('Selecting segment #%d', seg)))
            break;
        end
        pause(1);
    end
end

%%
% demo for memory ping pong
%
pingpong = 1;   % set pingpong to 1 to re-load segments at runtime - note: segment length can not be changed
if (pingpong)
    hMsgBox = xmsgbox('Memory ping-pong demo running. Please wait..', 'Memory ping pong demo');
    xfprintf(f, ':abort');
    xfprintf(f, ':func:mode sts');
    xfprintf(f, ':stab:dyn on');
    while true
        % create a signal
        ampl = 0.2 + 0.8*rand(1);
        cyc = randi([1,5]);
        sig = ampl * sin(cyc*2*pi*(1:segLen)/segLen);
        % determin segment number to overwrite
        segment = mod(pingpong,2) + 1;
        if (updateDialog(hMsgBox, sprintf('Downloading segment #%d...', segment))); break; end
        % download to a segment that is currently not in use
        % setting 'run' to -1 means that we are using memory ping pong
        % i.e. no :ABORT before updating the segment
        iqdownload(complex(real(sig), real(sig)), fs, 'segmentNumber', segment, 'keepOpen', 1, 'run', -1);
%         xiqdownload(arbConfig, f, 1, sig, fs, segment);
%         xiqdownload(arbConfig, f, 2, sig, fs, segment);
        pause(1);
        if (updateDialog(hMsgBox, sprintf('Generate segm #%d (ampl=%d%%, freq=%s) ...', segment, round(ampl*100), iqengprintf(cyc*fs/segLen, 2)))); break; end
        % ...and select the associated sequence table entry
        xfprintf(f, sprintf(':stab:dyn:sel %d', segment-1));
        pause(1);
        pingpong = pingpong + 1;
    end
end

fclose(f);
end



function xiqdownload(arbConfig, f, chan, sig, fs, segment) 
    dataSize = 'int8';
    data = int8(round(127 * real(sig)));
    % in case of 1 or 2 channel with marker mode, need to load 16 bit values
    if (strcmp(arbConfig.model, 'M8195A_1ch') || ...
        (strcmp(arbConfig.model, 'M8195A_2ch_mrk') && chan == 1))
        dataSize = 'int16';
        data = int16(data);
        data = bitand(data,255);
        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end
    end
    cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segment, 0);
    xbinblockwrite(f, data, dataSize, cmd);
end


function hMsgBox = xmsgbox(s, title)
% show a message box but replace the "OK" button with a "Stop" button
hMsgBox = msgbox(s, title);
ch = get(hMsgBox, 'Children');
for i=1:length(ch)
    if (strcmp(ch(i).Type, 'uicontrol'))
        set(ch(i), 'String', 'Stop');
    end
end
end


function xbinblockwrite(f, data, format, cmd)
% set debugScpi=1 in MATLAB workspace to log SCPI commands
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    fprintf('cmd = %s %s, %d elements\n', cmd, format, length(data));
end
binblockwrite(f, data, format, cmd);
fprintf(f, '');
end




function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, -1 for errors

retVal = 0;
% set debugScpi=1 in MATLAB workspace to log SCPI commands
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    fprintf('cmd = %s\n', s);
end
fprintf(f, s);
result = query(f, ':syst:err?');
if (isempty(result))
    fclose(f);
    errordlg({'The M8195A firmware did not respond to a :SYST:ERRor query.' ...
        'Please check that the firmware is running and responding to commands.'}, 'Error');
    retVal = -1;
    return;
end
if (~exist('ignoreError', 'var') || ignoreError == 0)
    while (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
        errordlg({'M8195A firmware returns an error on command:' s 'Error Message:' result});
        result = query(f, ':syst:err?');
        retVal = -1;
    end
end
end



function result = updateDialog(hMsgBox, s)
% Change the text of a message box
% Returns 1 if message box has been closed by the user
result = 0;
if (~isempty(hMsgBox))
    try
        ch = get(hMsgBox, 'Children');
        for i=1:length(ch)
            if (strcmp(ch(i).Type, 'axes'))
                set(get(ch(i), 'Children'), 'String', s);
            end
        end
        pause(0.001);
    catch ex
        result = 1;
    end
end
end
