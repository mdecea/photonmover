function [yval, fs] = iqreaddca(arbConfig, chan, ~, duration, avg, maxAmpl, trigFreq, dataRate, spb, bandwidth, sirc)
% read a waveform from DCA
%
% arguments:
% arbConfig - if empty, use DCA address configured in IQTools config
% chan - list of scope channels to be captured
% trigChan - not used (will always be front panel)
% duration - length of capture (in seconds)
% avg - number of averages (1 = no averaging)
% maxAmpl - amplitude of the signal (will be used to set Y scale)
%           0 means do not set ampltiude
%           -1 means: use maximum amplitude supported by this instrument
%           -2 means: perform autoscale
% trigFreq - trigger frequency in Hz. Zero for once per waveform. Assumes
%            that the trigger signal is connected to the FP trigger input
%            Non-zero: trigger frequency for PTB. Assumes that Trigger signal 
%            is connected to FP+PTB inputs. Will use PatternLock.
% dataRate - (optional) specifies the data rate that will be used in
%            pattern lock mode. If not given, will use trigFreq as the data rate
% spb -      (optional) samples per bit. If trigFreq and dataRate are
%            specified, spb can be used define how many samples per bit the
%            DCA will use when capturing the waveform. If spb is not
%            specified, the routine will use 128 kSa for the entire
%            waveform (spb will depend on dataRate and duration in that case)
% bandwidth - if empty, will leave scope bandwidth as-is. If non-empty,
%            will set scope bandwidth to the given value. Note that
%            bandwidth must be a string.  This string is directly passed to the
%            :CHAN:BANDWIDTH command. I.e. ENUMs, such as "BAND1" or "HIGH" are
%            possible.  A value of "MAX" will try to set the bandwidth to
%            the maximum available value
% sirc -     if empty, will leave SIRC setting as-is.  If non-empty, will 
%            turn SIRC on (1) or off (0).
%
yval = [];
fs = 1;
if (~exist('arbConfig', 'var'))
    arbConfig = [];
end
arbConfig = loadArbConfig(arbConfig);
if ((isfield(arbConfig, 'isDCAConnected') && arbConfig.isDCAConnected == 0) || ~isfield(arbConfig, 'visaAddrDCA'))
    error('DCA address is not configured, please use "Instrument Configuration" to set it up');
end
f = iqopen(arbConfig.visaAddrDCA);
if (isempty(f))
    return;
end
if (~exist('chan', 'var') || isempty(chan))
    chan = {'1A' '2A'};
end
if (~exist('duration', 'var') || isempty(duration))
    duration = 10e-9;
end
if (~exist('avg', 'var') || isempty(avg) || avg < 1)
    avg = 1;
end
if (~exist('maxAmpl', 'var') || isempty(maxAmpl))
    maxAmpl = -2;        % ampl = -2 means autoscale
end
if (~exist('trigFreq', 'var') || isempty(trigFreq))
    trigFreq = 0;
end
if (~exist('dataRate', 'var') || isempty(dataRate))
    dataRate = trigFreq;
end
if (dataRate ~= 0)
    if (abs(mod(dataRate, trigFreq)) > eps)
        errordlg('dataRate must be an integer multiple of trigFreq');
        error('dataRate must be an integer multiple of trigFreq');
    end
end
if (~exist('spb', 'var') || isempty(spb))
    spb = 0;
end
if (~exist('bandwidth', 'var') || isempty(bandwidth) || strcmp(strtrim(bandwidth), ''))
    bandwidth = [];
end
if (~exist('sirc', 'var'))
    sirc = [];
end
numChan = length(chan);
xfprintf(f, '*CLS');
% find out which SCPI language to use: flex or old DCA style
flex = 1;
raw_idn = xquery(f, '*IDN?');
idn = regexp(raw_idn, ',\s*', 'split');
if (strcmp(idn{1}, 'TEKTRONIX'))
    [yval, fs] = iqreaddcatek(arbConfig, chan, 0, duration, avg, maxAmpl, trigFreq);
    return;
end
if (strncmp(idn{2}, '86100C', 6))
    flex = 0;
end
%--- find out if this a DCA-M  (in this case, some of the PTB commands can not be used
if (flex)
    moduleType = findModuleType(f, chan);
else
    % legacy scope software
    moduleType = xquery(f, ':MODEL? LMODULE');
end
% if (strncmp(moduleType, 'N109', 4) || strncmp(moduleType, 'N106', 4))
if (strncmp(moduleType, 'N109', 4))
    dcam = 1;
else
    dcam = 0;
end
%--- handle automatic scope amplitude
if (maxAmpl == -2)
    autoScale = 1;
    maxAmpl = 0;
else
    autoScale = 0;
end

if (maxAmpl == -1)
    maxAmpl = 0.8;      % max value supported by 86108B
    dp = strfind(chan, 'DIFF');
    if (~isempty([dp{:}]))
        maxAmpl = 2 * maxAmpl;    % for differential ports, double amplitude
    end
end
%--- some basic setup
xfprintf(f, sprintf(':SYSTem:MODE OSC'));
xfprintf(f, sprintf(':STOP'));
xfprintf(f, sprintf(':TRIG:SOURce:AUTodetect OFF'));
xfprintf(f, sprintf(':TRIG:SOURce FPANEL'));
xfprintf(f, sprintf(':TRIG:PLOC OFF'));

% turn off the default channel, in case it is not needed
if (flex)
    xfprintf(f, ':CHAN1A:DISP OFF');
else
    xfprintf(f, ':CHAN1:DISP OFF');
end
%--- configure the desired channels
for i = 1:numChan
    if (~isempty(strfind(chan{i}, 'DIFF')))
        xfprintf(f, sprintf(':%s:DMODe ON', chan{i}));
    else
        if ((chan{i}(end) == 'A' || chan{i}(end) == 'C') && flex)
            xfprintf(f, sprintf(':DIFF%s:DMODe OFF', chan{i}));
        end
        if (length(chan{i}) <= 2)
            chan{i} = strcat('CHAN', chan{i});
        end
    end
    ampl = maxAmpl(min(i,length(maxAmpl)));
    if (flex)
        if (ampl ~= 0)
            % don't try to set the amplitude higher than the max. supported
            qmax = str2double(xquery(f, sprintf(':%s:YSCALE? MAX', chan{i})));
            xfprintf(f, sprintf(':%s:YSCALE %g', chan{i}, min(ampl/8, qmax)));
        end
        % Do not set offset to zero. User might want to set it differently
        %    xfprintf(f, sprintf(':%s:YOFFSET %g', chan{i}, 0));
        if (~strncmpi(chan{i}, 'FUNC', 4))
            if (isempty(bandwidth) || strncmpi(bandwidth, 'max', 3))
                xfprintf(f, sprintf(':CHAN%s:BANDwidth:FREQ MAX', chan{i}(end-1:end)), 0);
            elseif (isstrprop(bandwidth(1), 'alpha'))
                xfprintf(f, sprintf(':CHAN%s:BANDwidth %s', chan{i}(end-1:end), bandwidth), 0);
            else
                xfprintf(f, sprintf(':CHAN%s:BANDwidth:FREQ %s', chan{i}(end-1:end), bandwidth), 0);
            end
        end
        if (xfprintf(f, sprintf(':%s:DISP ON', chan{i})))
            errordlg(sprintf('An error occurred when trying to turn on channel "%s". Please check your channel mapping.', chan{i}));
            return;
        end
    else
        if (ampl ~= 0)
            xfprintf(f, sprintf(':%s:SCALE %g', chan{i}(1:5), ampl / 8));
        end
    % Do not set offset to zero. User might want to set it differently
    %    xfprintf(f, sprintf(':%s:OFFSET %g', chan{i}(1:5), 0));
        if (~isempty(bandwidth))
            if (strncmpi(bandwidth, 'max', 3))
                % Different modules use different ENUMs for setting bandwidth
                % So, let's try out all of them and ignore any errors
                xfprintf(f, sprintf(':CHAN%s:BANDwidth HIGH', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND1', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND2', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND3', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND4', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND5', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND6', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND7', chan{i}(end-1:end-1)), 1);
            else
                xfprintf(f, sprintf(':CHAN%s:BANDwidth %s', chan{i}(end-1:end-1), bandwidth), 0);
            end
        end
        xfprintf(f, sprintf(':%s:DISP ON', chan{i}(1:5)));
    end
end

%--- set up timebase and triggering
if (trigFreq ~= 0)
    pattLength = round(dataRate * duration);
    if (flex)
        % built-in PTB
        if (~dcam)  % don't send PTB commands to DCA-M
            if (strncmp(moduleType, '86108B', 6) || strncmp(moduleType, 'N1060', 5))
                % use module-specific PTB in 86108B and N1060
                xfprintf(f, sprintf(':PTimebase1:RSOurce EXTernal'));
                xfprintf(f, sprintf(':PTIMebase1:RFRequency %.15g', trigFreq));
                if (xfprintf(f, sprintf(':PTIMEbase1:STATe ON')))
                    return;
                end
            else
                % otherwise, use chassis timebase
                xfprintf(f, sprintf(':TIMebase:PTIMebase:RFRequency %.15g', trigFreq));
                if (xfprintf(f, sprintf(':TIMebase:PTIMEbase:STATe ON')))
                    return;
                end
                % reset PTB
%                 if (xfprintf(f, sprintf(':TIMebase:PTIMebase:RTReference')))
%                     return;
%                 end
                xquery(f, '*OPC?');
            end
            xquery(f, '*OPC?');
        end
        if (xfprintf(f, sprintf(':TIMEbase:UNITs SECond')))
            return;
        end
        xfprintf(f, sprintf(':TRIG:SOURce FPANEL'));
        if (~dcam)
            xfprintf(f, sprintf(':TRIGger:MODe CLOCk'));
        end
        xfprintf(f, sprintf(':TRIGger:BRATe:AUTodetect OFF'));
        xfprintf(f, sprintf(':TRIGger:PLENgth:AUTodetect OFF'));
        xfprintf(f, sprintf(':TRIGger:DCDRatio:AUTodetect OFF'));
        xfprintf(f, sprintf(':TIMebase:BRATe %.15g', dataRate));
        xfprintf(f, sprintf(':TRIGger:PLENgth %d', pattLength));
        trigRatio = round(dataRate / trigFreq);
        trigRatioStr = 'UNITy';
        if (trigRatio > 1)
            trigRatioStr = sprintf('SUB%d', trigRatio);
        end
        % If samples per bit is specified, use it to calculate the total number of samples
        if (spb ~= 0)
            numPts = spb * pattLength;
        else
            % otherwise, use a fixed maximum number of samples (128 K)
            numPts = 128*1024;
            % number of samples per bit
            spb = round(numPts / pattLength);
        end
        xfprintf(f, sprintf(':ACQuire:EPATtern OFF'));
        xfprintf(f, sprintf(':ACQuire:SPBit:MODe MANual'));
        xfprintf(f, sprintf(':ACQuire:SPBit %d', spb));
        xfprintf(f, sprintf(':TRIGger:DCDRatio %s', trigRatioStr));
        xfprintf(f, sprintf(':MEASure:JITTer:DEFine:SIGNal:AUTodetect OFF'));
        xfprintf(f, sprintf(':MEASure:JITTer:DEFine:SIGNal DATA'));
        xfprintf(f, sprintf(':TRIGger:PLOCk ON'));
        xfprintf(f, '*OPC');
        count = 30;
%        hMsgBox = msgbox('Waiting to acquire pattern lock...');
        while count > 0
            esr = str2double(xquery(f, '*ESR?'));
            if (bitand(esr, 1) ~= 0)
                break;
            end
            pause(1);
            count = count - 1;
        end
%         try
%             close(hMsgBox);
%         catch
%         end
        if (count <= 0)
            errordlg('DCA did not acquire pattern lock. Please make sure that the signals are connected correctly');
            return;
        end
        % if sirc is non-empty, set it accordingly - ignore errors if SIRC is not available
        % Changes BK
        chanSuffixFunctions = {'1A', '1B', '2A', '2B'};
        sircResponse = {'FLAT','BESSel','SINC'} ; 
        for i = 1:numChan
            if (strncmpi(chan{i}, 'FUNC', 4))
                % with FUNCtions, we don't know which channel they are
                % connected to. For the time being, let's assume it the
                % function order corresponds to an increasing channel
                % number
                chanSuffix = chanSuffixFunctions{i};
            else
                chanSuffix = chan{i}(end-1:end);
            end
            if (sirc)
                xfprintf(f, sprintf(':CHAN%s:SIRC ON', chanSuffix), 1);
            else
                xfprintf(f, sprintf(':CHAN%s:SIRC OFF', chanSuffix), 1);
            end
            % must set the bandwidth for SIRC mode separately - 
            if (isempty(bandwidth))
                bw = '100e9';
            else
                bw = sscanf(bandwidth, '%g');
                if (isempty(bw))
                    bw = '100e9';
                end
            end
            % Changes BK
            xfprintf(f, sprintf(':CHAN%s:SIRC:FBANDWIDTH %s', chanSuffix, bw), 1);
            % Set SIRC response to "Flat" for minimum attenuation
            xfprintf(f, sprintf(':CHAN%s:SIRC:RESPonse %s', chanSuffix, sircResponse{1}), 1);
        end
    else
        errordlg('PatternLock not yet implemented in legacy DCA mode');
        return;
    end
else
    if (flex)
        xfprintf(f, sprintf(':TIMebase:PTIMEbase:STATe OFF'));
        xfprintf(f, sprintf(':PTIMEbase:STATe OFF'));
        xfprintf(f, sprintf(':TIMEbase:UNITs SECond'));
        xfprintf(f, sprintf(':TRIG:BWLimit EDGE'));
    else
        xfprintf(f, sprintf(':TRIG:BWLimit LOW'));
    end
end
xfprintf(f, sprintf(':TRIG:LEVEL %g', 0));
xfprintf(f, sprintf(':TRIG:SLOPe POS'));
xfprintf(f, sprintf(':TIMEbase:REFerence LEFT'));
xfprintf(f, sprintf(':TIMEbase:SCALe %g', duration / 10));

if (trigFreq ~= 0)
    if (flex)
%        xfprintf(f, sprintf(':ACQuire:EPATtern ON'));
        numPts = round(round(numPts / pattLength) * pattLength);
    else
        errordlg('PatternLock not yet implemented in legacy DCA mode');
        error('PatternLock not yet implemented in legacy DCA mode');
    end
else
    if (flex)
        if (xfprintf(f, sprintf(':ACQuire:RSPec RLENgth')))
            return;
        end
        xfprintf(f, sprintf(':ACQuire:RLENgth:MODE MANUAL'));
        xfprintf(f, sprintf(':ACQuire:RLENgth MAX'));
        numPts = str2double(xquery(f, ':ACQuire:RLENgth?'));
        xfprintf(f, sprintf(':ACQuire:WRAP OFF'));
        xfprintf(f, sprintf(':ACQuire:CDISplay'));
    else
        if (xfprintf(f, sprintf(':CDISplay')))
            return;
        end
        numPts = 16384; % MAX value does not work on old DCA
        %xfprintf(f, sprintf(':ACQuire:POINts MAX'));
        %numPts = str2double(xquery(f, ':ACQuire:POINts?'));
        xfprintf(f, sprintf(':ACQuire:POINts %d', numPts));
    end
end

if (autoScale)
    xfprintf(f, ':AUTOscale');
    xquery(f, '*OPC?');
    % set timebase again
    xfprintf(f, sprintf(':TIMEbase:SCALe %g', duration / 10));
end

% perform autoscale with entire pattern still turned off
if (trigFreq ~= 0)
    if (flex)
        xfprintf(f, sprintf(':ACQuire:EPATtern ON'));
    end
end

%--- set up acquisition limits and run

% in pattern lock, acquire a certain number of patterns to avoid "holes" in
% the waveform. Need 12 patterns to guarantee no holes, but experience
% shows that with only 6 patterns, very few holes remain which will be
% interpolated
numPatt = 6;

% there are several cases to be distinguished:
% PatternLock / averaging / flex or legacy
if (avg > 1)
    if (flex)
        if (trigFreq ~= 0)
            xfprintf(f, ':LTESt:ACQuire:CTYPe PATT');
            xfprintf(f, sprintf(':LTESt:ACQuire:CTYPe:PATT %d', numPatt));
        end
        xfprintf(f, sprintf(':ACQuire:SMOOTHING AVER'));
        xfprintf(f, sprintf(':ACQuire:ECOunt %d', avg));
        xfprintf(f, sprintf(':LTESt:ACQuire:CTYPe:WAVeforms %d', avg));
        xfprintf(f, sprintf(':LTESt:ACQuire:STATe ON'));
        xfprintf(f, sprintf(':ACQuire:RUN'));
    else
        xfprintf(f, sprintf(':ACQuire:AVERAGE ON'));
        xfprintf(f, sprintf(':ACQuire:COUNT %d', avg));
        xfprintf(f, sprintf(':ACQuire:RUNTil WAVEforms,%d', avg));
        xfprintf(f, sprintf(':AEEN 1'));
        xfprintf(f, sprintf(':RUN'));
    end
else
    if (flex)
        xfprintf(f, sprintf(':ACQuire:SMOOTHING NONE'));
        if (trigFreq ~= 0)
            xfprintf(f, ':LTESt:ACQuire:CTYPe PATT');
            xfprintf(f, sprintf(':LTESt:ACQuire:CTYPe:PATT %d', numPatt));
            xfprintf(f, sprintf(':LTESt:ACQuire:STATe ON'));
            xfprintf(f, sprintf(':ACQuire:RUN'));
        else
            xfprintf(f, sprintf(':LTESt:ACQuire:STATe OFF'));
            xfprintf(f, sprintf(':ACQuire:SINGLE'));
        end
    else
        xfprintf(f, sprintf(':ACQuire:AVERAGE OFF'));
        xfprintf(f, sprintf(':AEEN 0'));
%        xfprintf(f, sprintf(':SINGLE'));   % with :SINGLE, ESR? does not work
        xfprintf(f, sprintf(':RUN'));
    end
end

%--- wait until capture has completed. Don't use a blocking wait!!
xfprintf(f, '*OPC');
hMsgBox = iqwaitbar('Please wait, DCA capture in progress...');
pause(1);
if (trigFreq ~= 0)
    count = round(max(avg, numPatt) * (numPts / 35000));
else
    count = round(avg * 2);
end
% some spare time beyond the nominal timeout
spare = -20 - count;
startCount = count;
userBreak = 0;
while count > spare
    esr = str2double(xquery(f, '*ESR?'));
    if (bitand(esr, 1) ~= 0)
        break;
    end
    hMsgBox.update(mod(startCount - count, startCount)/startCount);
    if (hMsgBox.canceling())
        userBreak = 1;
        break;
    end
    pause(1);
    count = count - 1;
end
delete(hMsgBox);
if (userBreak)
    return;
end
if (count <= spare)
    if (trigFreq ~= 0)
        errordlg('Scope timeout during waveform capture. Please make sure that the trigger signal is connected to the front panel trigger input *and* the Precision Timebase input');
    else
        errordlg('Scope timeout during waveform capture. Please make sure that the trigger signal is connected to the front panel trigger input');
    end
    return;
end
%fprintf('%d samples, %d avg, %d sec, %d sec max., %g (samples * avg) per second\n', numPts, avg, startCount - count, startCount, numPts * avg / (startCount - count));
if (strcmp(f.type, 'tcpip'))
    xfprintf(f, ':WAVeform:BYTeorder MSBFIRST');
else
    xfprintf(f, ':WAVeform:BYTeorder LSBFIRST');
end
yval = zeros(numPts, numChan);

%--- get the waveform from the scope
for i=1:numChan
    if (flex)
        xfprintf(f, sprintf(':WAVeform:SOURce %s', chan{i}));
        xOrig = str2double(xquery(f, ':WAVeform:YFORmat:XORigin?'));
        xInc  = str2double(xquery(f, ':WAVeform:YFORmat:XINC?'));
        yOrig = str2double(xquery(f, ':WAVeform:YFORmat:WORD:ENC:YORigin?'));
        yInc  = str2double(xquery(f, ':WAVeform:YFORmat:WORD:ENC:YINC?'));
        tmp = xbinread(f, ':WAVeform:YFORmat:WORD:YDATA?', 'int16');
    else
        xfprintf(f, sprintf(':WAVeform:SOURce %s', chan{i}(1:5)));
        xfprintf(f, sprintf(':WAVeform:FORMAT WORD'));
        tmp = xbinread(f, ':WAVeform:DATA?', 'int16');
        xOrig = str2double(xquery(f, ':WAVeform:XORigin?'));
        xInc  = str2double(xquery(f, ':WAVeform:XINC?'));
        yOrig = str2double(xquery(f, ':WAVeform:YORigin?'));
        yInc  = str2double(xquery(f, ':WAVeform:YINC?'));
    end
    % check for overflow
    if (~isempty(find(tmp == 32256, 1)) || ~isempty(find(tmp == 32256, 1)))
        warndlg('Signal exceeds scope range. Consider reducing the scope amplitude scale or insert an attenuator in the signal path', 'Scope Amplitude exceeded', 'replace');
    end
    % replace negative overflow by a negative value
    tmp(tmp == 31744) = -32767;
    % find invalid values ("holes" in PTB) 
    tmp(tmp == 31232) = NaN;
    invidx = find(isnan(tmp));
    if (~isempty(invidx))
        %fprintf('%d invalid samples - interpolating\n', length(invidx));
        % fill them by interpolation
        xtmp = tmp; xtmp(invidx) = [];
        xaxs = 1:numPts; xaxs(invidx) = [];
        tmp(invidx) = interp1(xaxs, xtmp, invidx);
    end
    % convert to voltage values
    fs = 1 / xInc;
    xval = (1:numPts) * xInc + xOrig;
    try
        yval(:,i) = tmp * yInc + yOrig;
    catch
    end;
end
if (flex)
    xfprintf(f, sprintf(':ACQuire:SMOOTHING NONE'));
    xfprintf(f, sprintf(':LTESt:ACQuire:STATe OFF'));
    xfprintf(f, sprintf(':ACQuire:RUN'));
    if (trigFreq ~= 0)
        xfprintf(f, sprintf(':TIMEbase:SCALe %g', 1/trigFreq));
    end
else
    xfprintf(f, sprintf(':ACQuire:AVERAGE OFF'));
    xfprintf(f, sprintf(':AEEN 0'));
end
fclose(f);
% if called without output arguments, plot the result
if (nargout == 0)
    figure(151);
    plot(xval, yval, '.-');
    yval = [];
end


function moduleType = findModuleType(f, chan)
% default behavior: start at slot 1 and search for a module
slot = 1;
searchDir = 1;
% locate a channel that points to a slot number
for i = 1:length(chan)
    if (~strncmpi(chan{i}, 'FUNC', 4))
        slot = str2double(chan{1}(end-1));
        % set search direction backwards because sometimes, the channel
        % number is slot number + 1
        searchDir = -1;
        break;
    end
end
foundModule = false;
while (~foundModule && slot >= 1 && slot <= 4)
    moduleType = xquery(f, sprintf(':MODEL? SLOT%d', slot));
    if (~strncmpi(moduleType, 'Not Present', 11))
        foundModule = true;
        break;
    end
    slot = slot + searchDir;
end
if (~foundModule)
    moduleType = '';
    warndlg('Can''t determine which type of DCA module you are using. Uploading data from scope might not work correctly in this case.');
end


function a = binread(f, cmd, fmt)
a = [];
fprintf(f, cmd);
r = fread(f, 1);
if (~strcmp(char(r), '#'))
    error('unexpected binary format');
end
r = fread(f, 1);
nch = str2double(char(r));
r = fread(f, nch);
nch = floor(str2double(char(r))/2);
if (nch > 0)
    a = fread(f, nch, fmt);
else
    a = [];
end
fread(f, 1); % read EOL


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
    if (strncmp(result, '0', 1))
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
        if (~isempty(find(isstrprop(retVal(1:60), 'cntrl'), 1)))
            rstr = sprintf('(%d chars, some non-printable)', length(retVal));
        else
            rstr = sprintf('%s... (total %d chars)', retVal(1:60), length(retVal));
        end
    else
        rstr = retVal;
    end
    fprintf('%s - %s -> %s\n', f.Name, s, strtrim(rstr));
end


function retVal = xbinread(f, cmd, fmt)
retVal = binread(f, cmd, fmt);
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    rstr = sprintf('(%d elements)', length(retVal));
    fprintf('%s - %s -> %s\n', f.Name, cmd, strtrim(rstr));
end
