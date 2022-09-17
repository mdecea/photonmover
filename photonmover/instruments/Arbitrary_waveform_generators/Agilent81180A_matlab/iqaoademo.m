
function iqaoademo()
%
% AoA (angle of arrival) simulation demo
%
arbConfig = loadArbConfig();
if (strcmp(arbConfig.model, 'M8195A_2ch') || strcmp(arbConfig.model, 'M8195A_2ch_mrk') || strcmp(arbConfig.model, 'M8195A_4ch'))
    mpulse_demo2();
elseif (~strncmp(arbConfig.model, 'M8195A', 6))
    errordlg('This demo is only supported on M8195A');
else
    res = questdlg('This demo requires the M8195A to be in 4-channel mode with extended memory. Do you want to switch to this mode?');
    if (strcmp(res, 'Yes'))
        acs = load(iqarbConfigFilename());
        acs.arbConfig.model = 'M8195A_4ch';
        save(iqarbConfigFilename(), '-struct', 'acs');
        mpulse_demo2();
    end
end


function mpulse_demo2()
arbConfig = loadArbConfig();
fs = arbConfig.defaultSampleRate;
loopDuration = 10;
pri = 2e-6;
pw = 200e-9;
maxDelay = 100e-9;
nsteps = 200;
numSegmentLoops = round(loopDuration / nsteps / pri);
wfms = cell(4);
clear seq;
for k = 1:nsteps
    if (mod(k,10) == 0)
        hMsgBox = msgbox(sprintf('Downloading Waveform %d of %d', k, nsteps), 'Please wait...', 'replace');
    end
    delay = maxDelay * sin(2*pi*(k/nsteps)) * [0 1 2 3]/3;
    delay = delay + abs(min(delay));
    for i = 1:4
        % calculate waveform with variable delay
        wfms{i} = imag(iqpulse('pri', pri, 'pw', pw, 'offset', 200e6, 'span', 390e6, 'sampleRate', fs, 'delay', delay(i)));
        % add some amplitude variation
        wfms{i} = wfms{i} .* ((sin(2*pi*(k/nsteps)) * (i-1)/3) / 2.5 + 0.6);
    end
    if (arbConfig.numChannels == 4)
        xiqdownload(complex(wfms{1}, wfms{2}), fs, 'segmentNumber', k, 'channelMapping', [1 0; 0 1; 0 0; 0 0], 'run', 0, 'keepopen', 1);
        xiqdownload(complex(wfms{3}, wfms{4}), fs, 'segmentNumber', k, 'channelMapping', [0 0; 0 0; 1 0; 0 1], 'run', 0, 'keepopen', 1);
    else
        xiqdownload(complex(wfms{1}, wfms{4}), fs, 'segmentNumber', k, 'channelMapping', [1 0; 0 0; 0 0; 0 1], 'run', 0, 'keepopen', 1);
    end
end
try 
    close(hMsgBox);
catch
end
i = 1;
for k = 1:nsteps
    seq(i).sequenceInit = 1;
    seq(i).sequenceEnd = 1;
    seq(i).markerEnable = 1;
    if (k == nsteps)
        seq(i).scenarioEnd = 1;
    end
    seq(i).segmentNumber = k;
    seq(i).segmentLoops = numSegmentLoops;
    seq(i).sequenceAdvance = 'Auto';
    i = i + 1;
end
iqseq('define', seq, 'keepOpen', 1, 'run', 0);
iqseq('mode', 'STSC');
%
% set up real-time scope if available
%
arbConfig = loadArbConfig();
if ((isfield(arbConfig, 'isScopeConnected') && arbConfig.isScopeConnected == 0) || ~isfield(arbConfig, 'visaAddrScope'))
    errordlg('Connection to realtime scope address is not configured. Please set up the scope manually');
    return;
end
hMsgBox = msgbox('Setting up the Oscilloscope, please wait...', 'Please wait...', 'replace');
f = iqopen(arbConfig.visaAddrScope);
if (isempty(f))
    try 
        close(hMsgBox);
    catch
    end
    return;
end
xfprintf(f, '*RST');
xfprintf(f, sprintf(':TIMEbase:SCale %g', 50e-9));
xfprintf(f, sprintf(':TIMEbase:DELay %g', 100e-9));
trigChan = 2;
xfprintf(f, sprintf(':TRIGger:EDGE:SOURce CHAN%d', trigChan));
xfprintf(f, sprintf(':TRIGger:LEVel CHAN%d,%g', trigChan, 50e-3));
xfprintf(f, sprintf(':TRIGger:HOLD %g', pri * 0.9));
xfprintf(f, sprintf(':DISPlay:GRAT:NUMB %d', 4));
if (arbConfig.numChannels == 4)
    xfprintf(f, sprintf(':DISPlay:GRAT:NUMB %d', 4));
    for i = 1:4
        xfprintf(f, sprintf(':CHAN%d:DISP ON', i));
        xfprintf(f, sprintf(':CHAN%d:RANGe %g', i, 560e-3));
        xfprintf(f, sprintf(':CHAN%d:OFFS %g', i, 0));
        xfprintf(f, sprintf(':DISPlay:GRAT:SETGrat CHN%d,%d', i, i));
    end
else
    xfprintf(f, sprintf(':DISPlay:GRAT:NUMB %d', 2));
    for i = [1 4]
        xfprintf(f, sprintf(':CHAN%d:DISP ON', i));
        xfprintf(f, sprintf(':CHAN%d:RANGe %g', i, 560e-3));
        xfprintf(f, sprintf(':CHAN%d:OFFS %g', i, 0));
        xfprintf(f, sprintf(':DISPlay:GRAT:SETGrat CHN%d,%d', i, (i+2)/3));
    end
    for i = [2 3]
        xfprintf(f, sprintf(':CHAN%d:DISP OFF', i));
    end
end
fclose(f);
try 
    close(hMsgBox);
catch
end


% speed up the download process by skipping the :SYST:ERR? queries
function xiqdownload(wfm, fs, ~, segmNum, ~, chMap, ~, ~, ~, ~)
if (segmNum == 1)
    iqdownload(wfm, fs, 'segmentNumber', segmNum, 'channelMapping', chMap, 'run', 0, 'keepopen', 1);
else
    f = iqopen();
    for ch = find(chMap(:,1))'
        gen_arb_M8195A(f, ch, real(wfm), segmNum);
    end
    for ch = find(chMap(:,2))'
        gen_arb_M8195A(f, ch, imag(wfm), segmNum);
    end
    fprintf(f, '*CLS');  % clear the error caused by deleting segments that don't exist
end


function gen_arb_M8195A(f, chan, wfm, segmNum)
segmentLength = length(wfm);
fprintf(f, sprintf(':TRACe%d:DELete %d', chan, segmNum));
fprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segmNum, segmentLength));
data = int8(round(127 * wfm));
% swap MSB and LSB bytes in case of TCP/IP connection
if (strcmp(f.type, 'tcpip'))
    data = swapbytes(data);
end
cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segmNum, 0);
binblockwrite(f, data, 'int8', cmd);
fprintf(f, '');



function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, -1 for errors
retVal = 0;
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    fprintf('cmd = %s\n', s);
end
fprintf(f, s);
% result = query(f, ':syst:err?');
% if (isempty(result))
%     fclose(f);
%     errordlg({'The instrument did not respond to a :SYST:ERRor query.' ...
%         'Please check that the firmware is running and responding to commands.'}, 'Error');
%     retVal = -1;
%     return;
% end
% if (~exist('ignoreError', 'var') || ignoreError == 0)
%     if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12) && ~strncmp(result, '0', 1))
%         errordlg({'Instrument returns an error on command:' s 'Error Message:' result}, 'Error', 'replace');
%         retVal = -1;
%     end
% end
