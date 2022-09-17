function [result, fs] = iqreadM8131A(arbConfig, chan, trigChan, duration, avg, maxAmpl, ~, trigDelay, trigLevel)
% read a waveform from M8131A
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
f = iqopen(arbConfig.visaAddrScope);
if (isempty(f))
    return;
end
xfprintf(f, sprintf('*CLS'));
% xfprintf(f, sprintf(':TIMEbase:SCale %g', duration / 10));
% xfprintf(f, sprintf(':TIMEbase:REFerence LEFT'));
% xfprintf(f, sprintf(':TIMEbase:DELay %g', trigDelay));
if (avg > 1)
    errordlg('Averaging is not supported in M8131A');
    return;
end
% turn off the default channel in case it is not used - it will be turned
% back on below if it is part of the configuration
xfprintf(f, ':CHAN1:DISP OFF');
for i = 1:numChan
    if (strncmpi(chan{i}, 'DIFF', 4))
        errordlg('Differential channels are not supported in M8131A');
        return;
    elseif (strncmpi(chan{i}, 'REdge', 5))  % real edge, single ended
        errordlg('Real edge channels are not supported in M8131A');
        return;
    else                                    % normal channel, single ended
        chan{i} = chan{i}(1);
        ampl = maxAmpl(min(i,length(maxAmpl)));
    end
    xfprintf(f, sprintf(':CHAN%s:DISP ON', chan{i}));
end
if (~isempty(trigChan))
    trigAuto = 0;
    if (strcmpi(trigChan, 'unused'))    % use the first measured channel as a trigger
        trigAuto = 1;
    elseif (strcmp(trigChan, 'AUX'))    % use AUX Trigger
        errordlg('AUX Trigger is not supported in M8131A');
        return;
    else                                % regular trigger channel
        errordlg('Trigger is not yet supported in M8131A');
        return;
    end
end

% Determine the sample rate set in the digitizer.
% For the time being, we'll just use whatever is configured in the SFP
smode = xquery(f, ':ACQ:SRATE?');
% limit the number of samples 
maxpts = 100e6;
if (~isempty(strfind(smode, '32')))
    fs = 32e9;
    gr = 40;
%    maxpts = 2621440;
else
    fs = 16e9;
    gr = 40;
%    maxpts = 1310720;
end
dmode = xquery(f, ':DPR:MODE?');
if (~isempty(strfind(dmode, 'DDC')))
    ddc = 1;
    gr = 16;
%    maxpts = 524288;
    decs = xquery(f, ':DPR:DDC:DEC?');
    fs = fs / 2^str2double(decs(4:end));
else
    ddc = 0;
    decs = xquery(f, ':DPR:DIR:DEC?');
    if (~isempty(strfind(decs, '2')))
        gr = 32;
%        maxpts = 1048576;
        fs = fs / 2;
    end
end
if (duration == 0)
    numPts = maxpts;
else
    numPts = min(maxpts, ceil(duration * fs));
end
% round the number of points up to the next multiple of granularity
numPts = ceil(numPts / gr) * gr;
xfprintf(f, sprintf(':ACQuire:POINts %d', numPts));

% Start acquisition and wait until digitizer has triggered and stored
% waveform in memory
xfprintf(f, ':DIG:NDIS');
retry1 = 10;
while (retry1 > 0 && str2double(xquery(f, ':STAT:OPER:TRIG:EVEN?')) == 0)
    pause(0.1);
    retry1 = retry1 - 1;
end
if (retry1 <= 0)
    errordlg('M8131A did not trigger');
    return;
end
retry2 = 10;
while (str2double(xquery(f, ':STAT:OPER:MEMC:COND?')) ~= 0)
    pause(0.1);
    retry2 = retry2 - 1;
end
if (retry2 <= 0)
    errordlg('M8131A did not capture a waveform');
    return;
end

if (strcmp(f.type, 'tcpip'))
    xfprintf(f, ':WAVeform:BYTeorder MSBFIRST');
else
    xfprintf(f, ':WAVeform:BYTeorder LSBFIRST');
end

% prepare waveform upload
if (ddc)
    result = complex(zeros(numPts, numChan), zeros(numPts, numChan));
else
    result = zeros(numPts, numChan);
end
for i = 1:numChan
    y_origin = str2double(xquery(f, sprintf(':WAVeform:YORigin? CHAN%s', chan{i})));
    y_increment = str2double(xquery(f, sprintf(':WAVeform:YINCrement? CHAN%s', chan{i})));
    x_origin = 0;
    x_increment = 1/fs;
    offset = 0;
    chunkSize = 16000;
    while (offset < numPts)
        len = min(chunkSize, numPts - offset);
        cmd = sprintf(':WAVeform:DATa:BLOCK? CHAN%s,%d,%d', chan{i}, offset, len);
        fprintf(f, cmd);
        r = fread(f, 1);
        if (~strcmp(char(r), '#'))
            error('unexpected binary format');
        end
        r = fread(f, 1);
        nnch = str2double(char(r));
        r = fread(f, nnch);
        nch = floor(str2double(char(r))/2);
%        fprintf('%s - %s  --> %d words\n', f.Name, cmd, nch);
        if (~ddc && nch ~= len || ddc && nch ~= 2*len)
            fprintf('binary block contains %d samples - expected %d\n', nch, len);
        end
        if (nch > 0)
            a = fread(f, nch, 'int16');
        else
            a = [];
        end
        fread(f, 1); % read EOL
        yval = a .* y_increment + y_origin;
        if (ddc)
%            fprintf('min %d, max %d, %.0f%% full scale\n', min(a), max(a), max(abs(a))/32768*100);
            yval = complex(yval(1:2:end-1), yval(2:2:end));
        else
%            fprintf('min %d, max %d, %.0f%% full scale\n', min(a), max(a), max(abs(a))/512*100);
        end
        result(offset+1:offset+len, i) = yval;
        offset = offset + len;
    end
end
fclose(f);
if (nargout == 0)
    figure(1);
    xval = linspace(x_origin, x_origin + (numPts-1)*x_increment, numPts);
    plot(xval, result, '.-');
    grid on;
end


function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, -1 for errors
retVal = 0;
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    fprintf('%s - %s\n', f.Name, s);
end
fprintf(f, s);
rptErr = 0;
while rptErr < 50
    result = query(f, ':syst:err?');
    if (isempty(result))
        fclose(f);
        errordlg(sprintf(['The instrument at %s did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'], f.Name), 'Error');
        retVal = -1;
        return;
    end
    if (strncmp(result, '0', 1) || strncmp(result, '+0', 2))
        break;
    elseif (~exist('ignoreError', 'var') || ignoreError == 0)
        fprintf('%s ERROR: %s -> %s\n', f.Name, s, strtrim(result));
        errordlg({'Instrument returns an error on command:' s 'Error Message:' strtrim(result)}, 'Error', 'replace');
        retVal = -1;
    end
    rptErr = rptErr + 1;
end


function retVal = xquery(f, s)
% send a query to the instrument object f
retVal = query(f, s);
% set debugScpi=1 in MATLAB workspace to log SCPI commands
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    if (length(retVal) > 60)
        rstr = sprintf('%s... (total %d chars)', retVal(1:60), length(retVal));
    else
        rstr = retVal;
    end
    fprintf('%s - %s -> %s\n', f.Name, s, strtrim(rstr));
end



