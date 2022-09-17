function result = dphy(varargin)
% Generate a C-PHY signal on two M8190A modules or one or two M8195A modules.
% It is typically called from dphy_gui.m (a graphical user interface to
% set up C-PHY parameters, but can also be called standalone.
% Parameters are passed as name/value pairs. The following parameter names
% are supported:
% 'sampleRate' - the samplerate that will be used by both M8190A modules
% 'cmd' - can be 'init', 'run', 'display'
%
% T.Dippon, Keysight Technologies 2011-2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

result = [];
if (nargin == 0)
    dphy_gui;
    return;
end
% set default values - will be overwritten by arguments
cmd = '';
sampleRate = 12e9;
fixedSkew = [0 0 0 0];
slaveClk = 'extclk';
clear dParam;
dParam.lpDataRate = 10e6;
dParam.hsDataRate = 2.5e9;
dParam.lpLow = 0;
dParam.lpHigh = 0.6;
dParam.hsLow = 0.1;
dParam.hsHigh = 0.4;
dParam.lpPattern = '0 1 0 2 0 1 0 2 0 1 3 3 3 2 0';
dParam.hsPattern = '0 1 2 3 4 5 0 1 2 3 4 5 0 1 2 3 4 5';
dParam.hsSkewAB = 0;
dParam.hsSkewAC = 0;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';     sampleRate = varargin{i+1};
            case 'cmd';            cmd = varargin{i+1};
            case 'dparam';         dParam = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

arbConfig = loadArbConfig();
% check valid configuration
[awg1, awg2, syncCfg, scopeCfg, numCh, useM8195A] = makeCfg(arbConfig);
if (isempty(awg1))
    return;
end

dParam.lpAmp = dParam.lpHigh - dParam.lpLow;
dParam.lpOffs = (dParam.lpHigh + dParam.lpLow)/2;
dParam.hsAmp = dParam.hsHigh - dParam.hsLow;
dParam.hsOffs = (dParam.hsHigh + dParam.hsLow)/2;
dParam.max = max([dParam.lpHigh dParam.lpLow dParam.hsHigh dParam.hsLow]);
dParam.min = min([dParam.lpHigh dParam.lpLow dParam.hsHigh dParam.hsLow]);
if (strcmp(dParam.mode, 'DPHY'))
    dParam.max = max([dParam.max dParam.ClockHigh dParam.ClockLow]);
    dParam.min = min([dParam.min dParam.ClockHigh dParam.ClockLow]);
    fixedSkew = [0 0 0 dParam.ClockDelay / dParam.hsDataRate];
else
    if (isfield(dParam, 'DelayA'))
        fixedSkew = [dParam.DelayA dParam.DelayB dParam.DelayC 0];
    end
end
dParam.maxAmp = dParam.max - dParam.min;
dParam.maxOffs = (dParam.max + dParam.min) / 2;

% common sample rate for both AWGs
fs = sampleRate;

% determine what to do
switch (cmd)
    case 'init'
        % turn off correction during initialize to avoid voltage overflow
%        dParam.Correction = 0;
        result = setupTestPattern(arbConfig, fs, 1, slaveClk, cmd, fixedSkew, dParam);
        if (isempty(result))
            result = autoDeskew(arbConfig, fs, slaveClk, fixedSkew, dParam);
        end
    case {'run'}
        result = setupTestPattern(arbConfig, fs, 0, slaveClk, cmd, fixedSkew, dParam);
        if ((~isfield(arbConfig, 'isScopeConnected') || (isfield(arbConfig, 'isScopeConnected') && arbConfig.isScopeConnected ~= 0)) && isfield(arbConfig, 'visaAddrScope'))
            setupScope(arbConfig, dParam);
        end
    case {'display'}
        [awg1, awg2, syncCfg, scopeCfg, numCh, useM8195A] = makeCfg(arbConfig);
        wfms = calcWfm(sampleRate, awg1, dParam, cmd);
        sig = cell2mat(wfms);
        sig = [real(sig(:,1)) imag(sig(:,1)) real(sig(:,2))];
        % scale from normlized to voltage
        sig = (sig + 1)/2 * dParam.maxAmp + dParam.min;
        figure(1);
        clf;
        set(gcf(),'Name','C-PHY generator demo');
        xaxis = linspace(0, (size(sig,1)-1)/fs, size(sig,1));
        plot(xaxis, sig, '.-', 'LineWidth', 2);
        ylim([dParam.min - 0.1*dParam.maxAmp dParam.max + 0.1*dParam.maxAmp]);
        xlabel('time (s)');
        ylabel('Voltage into 50 Ohm (V)');
        legend({'A', 'B', 'C'});
    case {'scope'}
        if ((~isfield(arbConfig, 'isScopeConnected') || (isfield(arbConfig, 'isScopeConnected') && arbConfig.isScopeConnected ~= 0)) && isfield(arbConfig, 'visaAddrScope'))
            setupScope(arbConfig, dParam);
        end
    case 'stop'
        result = doStop(arbConfig);
    otherwise
        error('unknown cmd');
end


function result = doStop(arbConfig)
[awg1, awg2, syncCfg, ~, numCh, useM8195A] = makeCfg(arbConfig);
if (~isempty(syncCfg))
    fsync = iqopen(syncCfg);
    if (isempty(fsync))
        return;
    end
    xfprintf(fsync, ':abor');
    xfprintf(fsync, ':inst:mmod:conf 1');
    fclose(fsync);
else
    % open the connection to the AWGs
    f1 = iqopen(awg1);
    if (isempty(f1))
        return;
    end
    fprintf(f1, ':abort');
    fclose(f1);
    if (~isempty(awg2))
        f2 = iqopen(awg2);
        if (~isempty(f2))
            fprintf(f2, ':abort');
            fclose(f2);
        end
    end
end
result = [];


function startStopScope(arbConfig, start)
% connect to scope
[~, ~, ~, scopeCfg, ~, ~] = makeCfg(arbConfig);
fscope = iqopen(scopeCfg);
if (isempty(fscope))
    return;
end
if (start)
    xfprintf(fscope, ':run');
else
    xfprintf(fscope, '*cls');   % ignore earlier errors
    xfprintf(fscope, ':stop');
end
fclose(fscope);


function setupScope(arbConfig, dParam)
% connect to scope
[awg1, awg2, ~, scopeCfg, numCh, useM8195A] = makeCfg(arbConfig);
fscope = iqopen(scopeCfg);
if (isempty(fscope))
    return;
end
doSetup = 1;
% in case of CPHY, clk is treated the same as A, B, C
% in case of DPHY, clk has separate levels
if (strcmp(dParam.mode, 'CPHY'))
    ampClk = dParam.maxAmp;
    offsClk = dParam.maxOffs;
else
    ampClk = dParam.ClockHigh - dParam.ClockLow;
    offsClk = (dParam.ClockHigh + dParam.ClockLow)/2;
end
% if HS only is displayed, use HS amplitude, else use max amplitude
if (isempty(dParam.lpPattern))
    amp1 = dParam.hsAmp;
    offs1 = dParam.hsOffs;
    timescale = 2 / dParam.hsDataRate;
else
    amp1 = dParam.maxAmp;
    offs1 = dParam.maxOffs;
    timescale = 5 / dParam.lpDataRate;
    % don't attempt to do eye diagram with LP & HS data together
    if (dParam.scopeMode == 3 || dParam.scopeMode == 4)
        return;
    end
end
avg = 'off';
funcOn = 1;
chanOn = 1;
switch (dParam.scopeMode)
    case 1 % overlaid
        k = 2.5;
        b = -2;
        xfprintf(fscope, sprintf(':timebase:scal %g', timescale));
        xfprintf(fscope, 'disp:cgrade off');
        offs = [b*amp1/k+offs1 b*amp1/k+offs1 b*amp1/k+offs1 -1*b*ampClk/k+offsClk];
        scale = [amp1/k amp1/k amp1/k ampClk/k];
        funcScale = 2*amp1/k;
        funcOffs = 2*funcScale;
%	trigChan = 'aux';
%	trigLev = 100e-3;
        trigChan = 'chan4';
        trigLev = offsClk;
        trigHoldoff = length(dParam.hsPattern) / dParam.hsDataRate + 100e-9;
    case 2 % individual
        k = 1.2;
        xfprintf(fscope, sprintf(':timebase:scal %g', timescale));
        xfprintf(fscope, 'disp:cgrade off');
        offs = [-3*amp1/k+offs1 -1*amp1/k+offs1 1*amp1/k+offs1 3*ampClk/k+offsClk];
        scale = [amp1/k amp1/k amp1/k ampClk/k];
        funcScale = 2*amp1/k;
        funcOffs = 3*funcScale;
        trigChan = 'chan4';
        trigLev = offsClk;
        trigHoldoff = length(dParam.hsPattern) / dParam.hsDataRate + 100e-9;
    case {3 4} % eye diagram
        xfprintf(fscope, sprintf(':timebase:scal %g', 0.3 / dParam.hsDataRate));
        xfprintf(fscope, sprintf(':timebase:delay %g', 1 / dParam.hsDataRate));
        if (dParam.scopeMode == 3)
            %xfprintf(fscope, 'disp:cgrade on');
            funcOn = 0;
        else
            xfprintf(fscope, 'disp:cgrade off');
            if (strcmp(dParam.mode, 'CPHY'))
                chanOn = 0;
            end
        end
        sc = 5; % waveform will span <sc> vertical divisions on scope
        offs = [offs1 offs1 offs1 offsClk];
        scale = [amp1/sc amp1/sc amp1/sc ampClk/sc];
        funcScale = 2*amp1/sc;
        funcOffs = 0; % 2*funcScale;
        trigChan = 'chan4';
        trigLev = offsClk;
        trigHoldoff = 100e-9;
        avg = 'off';
    otherwise
        doSetup = 0;
        % don't touch the scope setup
end
if (doSetup)
    % remove all measurements to avoid a cluttered screen
    xfprintf(fscope, ':meas:clear');
    % setup functions for C-PHY only
    if (strcmp(dParam.mode, 'CPHY'))
        xfprintf(fscope, ':func1:SUBtract chan1,chan2');
        xfprintf(fscope, ':func2:SUBtract chan2,chan3');
        xfprintf(fscope, ':func3:SUBtract chan3,chan1');
        xfprintf(fscope, ':func4:MATLab:OPER "CclockCPHY"', 1);
        xfprintf(fscope, ':func4:MATLab func1,func2', 1);
        xfprintf(fscope, ':func4:VERTical:RANGe 8', 1);
        xfprintf(fscope, ':func5:MATLab:OPER "CclockCPHY"', 1);
        xfprintf(fscope, ':func5:MATLab func4,func3', 1);
        xfprintf(fscope, ':func5:VERTical:RANGe 8', 1);
        xfprintf(fscope, ':MEAS:CLOCK:METHod EXPlicit, FUNC5, RISing', 1);
        xfprintf(fscope, ':MEAS:CLOCK:METHod:ALIGn EDGE', 1);
    end
    if (strcmp(dParam.mode, 'CPHY'))
        chanList = [3 2 1];
    else
        chanList = [4 2 1];
    end
    for i = [4 3 2 1]
        xfprintf(fscope, sprintf(':chan%d:disp off', i));
    end
    for i = chanList
        xfprintf(fscope, sprintf(':chan%d:scale %g; offs %g', i, scale(i), offs(i)));
        if (chanOn)
            xfprintf(fscope, sprintf(':chan%d:disp on', i));
        else
            xfprintf(fscope, sprintf(':chan%d:disp off', i));
        end
    end
    % turn on function
    if (strcmp(dParam.mode, 'CPHY'))
        for i = [3 2 1]
            xfprintf(fscope, sprintf(':func%d:scale %g; offset %g', i, funcScale, funcOffs));
            if (funcOn)
                xfprintf(fscope, sprintf(':func%d:display on', i));
            else
                xfprintf(fscope, sprintf(':func%d:display off', i));
            end
        end
    end
    % setup timebase
    % setup trigger
    xfprintf(fscope, sprintf(':trig:lev %s,%g', trigChan, trigLev));
    xfprintf(fscope, sprintf(':trig:edge:source %s', trigChan));
    xfprintf(fscope, sprintf(':trig:holdoff %g', trigHoldoff));
    % turn on averaging
    xfprintf(fscope, sprintf(':acquire:average:count 8'));
    xfprintf(fscope, sprintf(':acquire:average %s', avg));
    % turn down the bandwidth to reduce the sampling ripple at lower rates
    if (dParam.hsDataRate <= 2e9)
        xfprintf(fscope, sprintf(':acquire:bandwidth 8 GHz'));
    elseif (dParam.hsDataRate <= 3e9)
        xfprintf(fscope, sprintf(':acquire:bandwidth 10 GHz'));
    else
        xfprintf(fscope, sprintf(':acquire:bandwidth auto'));
    end
end
xfprintf(fscope, sprintf(':cdisplay'));
fclose(fscope);


function result = setupTestPattern(arbConfig, fs, doDeskew, slaveClk, cmd, fixedSkew, dParam)
global cal_amp;
global cal_offs;
global g_skew;
result = -1;
[awg1, awg2, syncCfg, ~, numCh, useM8195A] = makeCfg(arbConfig);
if (~isempty(awg2))
    switch lower(slaveClk)
        case {'extclk' 'external sample clock' }
            refSource = 'AXI';
            awg2.extClk = 1;   % ARB #2 is the slave and will run on external clock
        case {'axiref' 'axi reference clock' }
            refSource = 'AXI';
            awg2.extClk = 0;
        case {'extref' 'external reference clock' }
            refSource = 'EXTernal';
            awg2.extClk = 0;
        otherwise
            error(['unexpected slaveClk parameter: ' slaveClk]);
    end
end
if (mod(length(dParam.lpPattern), 2) ~= 0)
    msgbox('length of LP pattern must be even');
    result = -1;
    return;
end
dummySegNum = 1;
% open the connection to the AWGs
f1 = iqopen(awg1);
if (isempty(f1))
    return;
end
if (~isempty(awg2))
    f2 = iqopen(awg2);
    if (isempty(f2))
        return;
    end
else
    f2 = [];
end
% set the amplitude & offset values
amp = dParam.maxAmp;
offs = dParam.maxOffs;
awg1.ampType = 'DC';
awg1.amplitude = [amp amp];
awg1.offset = [offs offs];
if (~isempty(awg2))
    awg2.ampType = 'DC';
    awg2.amplitude = [amp amp];
    awg2.offset = [offs offs];
end
% if level calibration has been performed, use cal values
if (exist('cal_amp', 'var') && ~isempty(cal_amp) && ~doDeskew)
    if (useM8195A)
        awg1.amplitude = cal_amp;
        awg1.offset = cal_offs;
    else
        awg1.amplitude = [cal_amp(1) cal_amp(2)];
        awg1.offset = [cal_offs(1) cal_offs(2)];
        if (~isempty(awg2))
            awg2.amplitude = [cal_amp(3) cal_amp(4)];
            awg2.offset = [cal_offs(3) cal_offs(4)];
        end
    end
end
% stop scope capture
startStopScope(arbConfig, 0);
if (~isempty(syncCfg))
    fsync = iqopen(syncCfg);
    if (isempty(fsync))
        return;
    end
    xfprintf(fsync, ':abor');
    xfprintf(fsync, ':inst:mmod:conf 1');
    configMode = query(fsync, ':INSTrument:MMODule:CONF?');
    if (str2double(configMode) ~= 0)
        xfprintf(fsync, ':inst:slave:del:all');
        xfprintf(fsync, sprintf(':inst:mast ""'));
    end
elseif (~isempty(strfind(awg1.model, 'M8190A')))
    % stop both of them and
    % turn channel coupling on (in case it is not already on)
    fprintf(f1, ':abort');
    fprintf(f1, ':inst:coup:stat1 on');
    if (~isempty(f2))
        fprintf(f2, ':abort');
        fprintf(f2, ':inst:coup:stat1 on');
        % set 100 MHz RefClk for the slave, source as specified
        fprintf(f2, sprintf(':ROSCillator:FREQuency %g', 100e6));
        fprintf(f2, sprintf(':ROSCillator:SOURce %s', refSource));
    end
end

% switch AWG2 to internal clock temporarily to avoid clock loss
% but only if we actually perform deskew - not for simple start/stop
if (doDeskew && isempty(syncCfg) && ~isempty(awg2))
    switch (awg2.model)
        case 'M8190A_12bit'
            dwid = 'WSPeed';
        case 'M8190A_14bit'
            dwid = 'WPRecision';
        case { 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }
            interpolationFactor = eval(awg2.model(13:end));
            dwid = sprintf('INTX%d', interpolationFactor);
        otherwise
            dwid = [];
            % older instrument - do not send any command
    end
    cmds = sprintf(':FREQuency:RASTer:SOURce INTernal; :FREQuency:RASTer %.15g', fs);
    if (~isempty(dwid))
        cmds = sprintf('%s; :TRACe1:DWIDth %s; :TRACe2:DWIDth %s', cmds, dwid, dwid);
    end
    xfprintf(f2, cmds);
end

%% set up AWG #1 -------------------------------------------------------
% delete all waveform segments
if (~isempty(strfind(awg1.model, 'M8190A')))
    iqseq('delete', [], 'arbConfig', awg1, 'keepOpen', 1);
end
% create a "dummy" segment, that compensates the trigger delay.
% Fine delay can be adjusted using the Soft Front Panel
% (Ultimately, the deskew process should be automated)
% Trigger delay will be approx. 160 sequence clock cycles plus 
% some fixed delay due to the trigger cable
% One sequence clock cycle is 48 resp. 64 sample clocks.
% We also have have to take care of the linear playtime restriction
% of >256 sequence clock cycles.
fixDelay = 18e-9;
n1 = 257 * awg1.segmentGranularity;
n2 = n1 + (160 + round(fixDelay * fs / awg1.segmentGranularity)) * awg1.segmentGranularity;
dummySegment = zeros(1, n2);
nextSeg1 = [];
nextSeg2 = [];
% now create the real waveform segment, resp. the "test" segment which
% can be used to measure the skew
wfms = calcWfm(fs, awg1, dParam, cmd);
% download the waveforms into AWG1, but don't start the AWG yet (run=0)
% also, keep the connection open to speed up the download process
if (~isempty(strfind(awg1.model, 'M8195A')))
    sumA = [];
    w1 = [];
    w2 = [];
    for i=1:size(wfms,1)
        sumA = [sumA; [real(wfms{i,1}) imag(wfms{i,1})]];
    end
    if (~doDeskew && length(g_skew) == 4 && length(fixedSkew) == 4)
        sumA(:,1) = iqdelay(sumA(:,1), fs, g_skew(1)+fixedSkew(1));
        sumA(:,2) = iqdelay(sumA(:,2), fs, g_skew(2)+fixedSkew(2));
        sumA(find(sumA > 1)) = 1;
        sumA(find(sumA < -1)) = -1;
    end
%     iqdownload(sumA(:,1), fs, 'arbConfig', awg1, 'channelMapping', [1 0; 0 0; 0 0; 0 0], 'run', 0);
%     iqdownload(sumA(:,2), fs, 'arbConfig', awg1, 'channelMapping', [0 0; 1 0; 0 0; 0 0], 'run', 0);
else
    for i=1:size(wfms,1)
        iqdownload(wfms{i,1}, fs, 'arbConfig', awg1, 'channelMapping', [1 0; 0 1], 'keepOpen', 1, 'run', 0, 'segmentNumber', i+1);
    end
    iqdownload(dummySegment, fs, 'arbConfig', awg1, 'channelMapping', [1 0; 0 1], 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);
end

%% set up ARB #2 -------------------------------------------------------
% delete all segments
if (~isempty(awg2))
    iqseq('delete', [], 'arbConfig', awg2, 'keepOpen', 1, 'run', 0);
end
% shorter dummy segment in the second AWG because by the time it receives
% the trigger, the first AWG was already running for some time
dummySegment = zeros(1, n1);
if (~isempty(strfind(awg1.model, 'M8195A')))
    sumB = [];
    for i=1:size(wfms,1)
        sumB = [sumB; [real(wfms{i,2}) imag(wfms{i,2})]];
    end
    if (~doDeskew && length(g_skew) == 4 && length(fixedSkew) == 4)
        sumB(:,1) = iqdelay(sumB(:,1), fs, g_skew(3)+fixedSkew(3));
        sumB(:,2) = iqdelay(sumB(:,2), fs, g_skew(4)+fixedSkew(4));
        sumB(find(sumB > 1)) = 1;
        sumB(find(sumB < -1)) = -1;
    end
%     iqdownload(sumB(:,1), fs, 'arbConfig', awg1, 'channelMapping', [0 0; 0 0; 1 0; 0 0], 'run', 0);
%     iqdownload(sumB(:,2), fs, 'arbConfig', awg1, 'channelMapping', [0 0; 0 0; 0 0; 1 0], 'run', 1);
    iqdownload([sumA sumB], fs, 'arbConfig', awg1, 'channelMapping', dParam.chMap);
elseif (~isempty(awg2))
    for i=1:size(wfms,1)
        iqdownload(wfms{i,2}, fs, 'arbConfig', awg2, 'channelMapping', [1 0; 0 1], 'keepOpen', 1, 'run', 0, 'segmentNumber', i+1);
    end
    iqdownload(dummySegment, fs, 'arbConfig', awg2, 'channelMapping', [1 0; 0 1], 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);
end

%% now set up the sequence table (the same table will be used for both
% modules).  Data is entered into a struct and then passed to iqseq()
if (~isempty(strfind(awg1.model, 'M8190A')))
    clear seq;
    % dummy segment once
    i = 1;
    % Without SYNC module, play a dummy segment once to compensate delay
    if (isempty(syncCfg))
        seq(i).segmentNumber = dummySegNum;
        seq(i).segmentLoops = 1;
        seq(i).sequenceInit = 1;
        seq(i).sequenceEnd = 1;
        seq(i).markerEnable = 1;    % marker to start the slave module
        i = i + 1;
    end
    % the test segment(s)
    for k=1:size(wfms,1)
        seq(i).segmentNumber = k+1;
        seq(i).segmentLoops = 1;
        if (k == 1)
            seq(i).sequenceInit = 1;
            seq(i).markerEnable = 1;
            seq(i).sequenceAdvance = 'Conditional';
        end
        if (k == size(wfms,1))
            seq(i).sequenceEnd = 1;
        end
        i = i + 1;
    end
    % the dummy segment
    seq(i).segmentNumber = dummySegNum;
    seq(i).segmentLoops = 1;
    seq(i).segmentAdvance = 'Auto';
    seq(i).sequenceInit = 1;
    seq(i).sequenceEnd = 1;
    seq(i).scenarioEnd = 1;
    iqseq('define', seq, 'arbConfig', awg1, 'keepOpen', 1, 'run', 0);
    if (~isempty(awg2))
        iqseq('define', seq, 'arbConfig', awg2, 'keepOpen', 1, 'run', 0);
    end

    % set AWG #1 to triggered or continuous - depending on sync module
    iqseq('triggerMode',  ~isempty(syncCfg), 'arbConfig', awg1, 'keepopen', 1);
    % turn on triggered mode in AWG #2 in any case
    if (~isempty(awg2))
        iqseq('triggerMode', 'triggered', 'arbConfig', awg2, 'keepopen', 1);
    end
    % set SYNC Marker level of AWG #1 and trigger threshold of AWG #2
    lev = 250e-3;
    xfprintf(f1, sprintf(':mark1:sync:volt:ampl %g; offs %g', 500e-3, lev));
    if (isempty(syncCfg) && ~isempty(f2))
        xfprintf(f2, sprintf(':arm:trigger:level %g; imp low; slope pos', lev));
    end
    % and run (i.e. wait for trigger)
    if (~isempty(awg2))
        xfprintf(f2, ':TRIG:SOUR:ADV EVENT');
        iqseq('mode', 'STSC', 'arbConfig', awg2, 'keepopen', 1);
        % wait until AWG #2 has started (make sure it is ready to respond to the trigger)
        query(f2, '*opc?');
    end
    % now start AWG #1 which will generate a SYNC marker and trigger AWG #2
    iqseq('mode', 'STSC', 'arbConfig', awg1, 'keepopen', 1);

    if (~doDeskew && length(g_skew) == 4 && length(fixedSkew) == 4)
        setAWGDelay(f1, f2, g_skew + fixedSkew, g_skew + fixedSkew);
    end
    fclose(f1);
    if (~isempty(f2))
        fclose(f2);
    end
end
% start scope capture
startStopScope(arbConfig, 1);
result = [];


function wfms = calcWfm(fs, awg1, dParam, cmd)
% Calculate the waveforms that will be downloaded to the AWGs
% The returned wfms are two-dimensional cell arrays that contain vectors
% of complex values. 1st dimension is the waveform number (for building a
% sequence), the second dimension points to the AWG number (1 and 2).
% The real and imaginary part correspond to channel 1 and 2 of each AWG.
% (This just happens to be the format the iqdownload expects)
clear wfms;
% For deskew, simply generate a single "step function".
% Otherwise, calculate the waveforms based on dParam.lpPattern and
% dParam.hsPattern
if (strcmp(cmd, 'init'))
    if (fs > 12e9)  % assume M8195A
        n = 2048;
        t = (1:n)/n;
        t0 = sum(sin((1:2:n/2)' * (2*pi*t)) .* repmat(1./(1:2:n/2)', 1, length(t)));
    else  % assume M8190A
        t0 = real(iqpulsegen('arbConfig', awg1, 'sampleRate', fs, 'pw', 9600, 'rise', 0, 'fall', 0, 'off', 9600, 'high', 1, 'low', -1));
    end
    if (isfield(dParam, 'Correction') && dParam.Correction ~= 0)
        % apply correction, but DO NOT scale
        t1 = real(iqcorrection(t0, fs, 'chMap', dParam.chMap(:,1:2), 'normalize', 0));
        t2 = real(iqcorrection(t0, fs, 'chMap', dParam.chMap(:,3:4), 'normalize', 0));
        t3 = real(iqcorrection(t0, fs, 'chMap', dParam.chMap(:,5:6), 'normalize', 0));
        t4 = real(iqcorrection(t0, fs, 'chMap', dParam.chMap(:,7:8), 'normalize', 0));
    else
        t1 = t0;
        t2 = t0;
        t3 = t0;
        t4 = t0;
    end
    t1 = reshape(t1, length(t1), 1);
    t2 = reshape(t2, length(t2), 1);
    t3 = reshape(t3, length(t3), 1);
    t4 = reshape(t4, length(t4), 1);
    wfms{1,1} = complex(t1, t2);
    wfms{1,2} = complex(t3, t4);
else
    % don't show any warnings about short waveforms in display only mode
    nowarning = (strcmp(cmd, 'display'));
    if (strcmp(dParam.mode, 'CPHY'))
        [p1 p2 p3 p4] = trPatCPHY(dParam);
    else
        [p1 p2 p3 p4] = trPatDPHY(dParam);
    end
    idx = 1;
    if (~isempty(p1))
        t1 = real(iserial('sampleRate', fs, 'data', p1, 'transitiontime', dParam.hsTT, 'dataRate', dParam.hsDataRate, 'isi', dParam.hsIsi, 'SJpp', dParam.hsJitter, 'SJFreq', dParam.hsJitterFreq, 'nowarning', nowarning));
        t2 = real(iserial('sampleRate', fs, 'data', p2, 'transitiontime', dParam.hsTT, 'dataRate', dParam.hsDataRate, 'isi', dParam.hsIsi, 'SJpp', dParam.hsJitter, 'SJFreq', dParam.hsJitterFreq, 'nowarning', nowarning));
        t3 = real(iserial('sampleRate', fs, 'data', p3, 'transitiontime', dParam.hsTT, 'dataRate', dParam.hsDataRate, 'isi', dParam.hsIsi, 'SJpp', dParam.hsJitter, 'SJFreq', dParam.hsJitterFreq, 'nowarning', nowarning));
        t4 = real(iserial('sampleRate', fs, 'data', p4, 'transitiontime', dParam.hsTT, 'dataRate', dParam.hsDataRate, 'nowarning', nowarning));
        % add common mode distortion is required
        if (isfield(dParam, 'CMAmpl') && dParam.CMAmpl ~= 0)
            n = length(t1);
            per = round(dParam.CMFreq * n / fs);
            if (per == 0)
                warndlg(sprintf('Common mode frequency is too low. Minimum is %g', fs / n));
            end
            cm = sin(2*pi*per*(1:n)/n) * dParam.CMAmpl;
            t1 = t1 + cm;
            t2 = t2 + cm;
            t3 = t3 + cm;
        end
        sig = [reshape(t1, length(t1), 1), ...
               reshape(t2, length(t2), 1), ...
               reshape(t3, length(t3), 1), ...
               reshape(t4, length(t4), 1)];
        if (isfield(dParam, 'Correction') && dParam.Correction ~= 0)
            % apply correction, but DO NOT scale
            [sig, chMap] = iqcorrection(sig, fs, 'chMap', dParam.chMap, 'normalize', 0);
            dParam.chMap = chMap;
        end
        wfms{idx,1} = complex(sig(:,1), sig(:,2));
        wfms{idx,2} = complex(sig(:,3), sig(:,4));
        idx = idx + 1;
    end
    if (~isempty(dParam.lpPattern))
        t1 = real(iserial('sampleRate', fs, 'data', bitand(dParam.lpPattern, 1)/1, 'transitiontime', dParam.lpTT, 'dataRate', dParam.lpDataRate, 'SJpp', dParam.lpJitter, 'SJFreq', dParam.lpJitterFreq));
        t2 = real(iserial('sampleRate', fs, 'data', bitand(dParam.lpPattern, 2)/2, 'transitiontime', dParam.lpTT, 'dataRate', dParam.lpDataRate, 'SJpp', dParam.lpJitter, 'SJFreq', dParam.lpJitterFreq));
        t3 = real(iserial('sampleRate', fs, 'data', bitand(dParam.lpPattern, 4)/4, 'transitiontime', dParam.lpTT, 'dataRate', dParam.lpDataRate, 'SJpp', dParam.lpJitter, 'SJFreq', dParam.lpJitterFreq));
        t4 = real(iserial('sampleRate', fs, 'data', repmat([0 0], 1, length(dParam.lpPattern)/2), 'transitiontime', 0, 'dataRate', dParam.lpDataRate));
        t1 = reshape(t1, length(t1), 1);
        t2 = reshape(t2, length(t2), 1);
        t3 = reshape(t3, length(t3), 1);
        t4 = reshape(t4, length(t4), 1);
        wfms{idx,1} = complex(t1, t2);
        wfms{idx,2} = complex(t3, t4);
    end
end


function [p1 p2 p3 p4] = trPatDPHY(dParam)
% calculate 4 waveforms based on dParam.hsPattern
pat = dParam.hsPattern;
len = numel(pat);
relL = (dParam.hsLow - dParam.min) / dParam.maxAmp;
relH = (dParam.hsHigh - dParam.min) / dParam.maxAmp;
clkL = (dParam.ClockLow - dParam.min) / dParam.maxAmp;
clkH = (dParam.ClockHigh - dParam.min) / dParam.maxAmp;
p1 = mod(pat, 2) * (relH - relL) + relL;
p2 = (1 - mod(pat, 2)) * (relH - relL) + relL;
p3 = (1 - mod(pat, 2)) * (relH - relL) + relL;
% if no LP pattern, make clock repetitive
if (isempty(dParam.lpPattern))
    p4 = [repmat([1;0], floor(len/2), 1); zeros(mod(len,2),1)];
else
    p4 = [0; 0; repmat([1;0], floor(len/2)-2, 1); 0; 0; zeros(mod(len,2),1)];
end
p4 = p4 * (clkH - clkL) + clkL;


function [p1 p2 p3 p4] = trPatCPHY(dParam)
% calculate 4 waveforms based on dParam.hsPattern
pat = dParam.hsPattern;
len = numel(pat);
levA = [0 2 0 1 1 0 2; ...  % A
        0 0 2 2 0 1 1; ...  % B
        0 1 1 0 2 2 0] / 2; % C
% defines the next symbol based on input and current symbol
% where: +x=1, -x=2, +y=3, -y=4, +z=5, -z=6
nextSym = [5 6 1 2 3 4; ... % input 000
           6 5 2 1 4 3; ... % input 001
           3 4 5 6 1 2; ... % input 010
           4 3 6 5 2 1; ... % input 011
           2 1 4 3 6 5; ... % input 100
           1 2 3 4 5 6];    % input 101 --> stay the same (not a valid)
currSym = 1;
for i=1:length(pat)
    x = pat(i);
    if (x >= 0 && x <= 5)
        currSym = nextSym(x+1, currSym);
        pat(i) = -currSym;
    elseif (x <= -1 && x >= -6)
        currSym = -pat(i);
    else
        pat(i) = 0;
    end
end
relL = (dParam.hsLow - dParam.min) / dParam.maxAmp;
relH = (dParam.hsHigh - dParam.min) / dParam.maxAmp;
p1 = levA(1,-pat+1) * (relH - relL) + relL;
p2 = levA(2,-pat+1) * (relH - relL) + relL;
p3 = levA(3,-pat+1) * (relH - relL) + relL;
% if no LP pattern, make clock repetitive
if (isempty(dParam.lpPattern))
    p4 = [repmat([1;0], floor(len/2), 1); zeros(mod(len,2),1)];
else
    p4 = [0; 0; repmat([1;0], floor(len/2)-2, 1); 0; 0; zeros(mod(len,2),1)];
end


function result = autoDeskew(arbConfig, fs, slaveClk, fixedSkew, dParam)
% perform deskew and level calibration of the 4 AWG channels
global cal_amp;
global cal_offs;
global g_skew;
result = [];
[awg1, awg2, ~, scopeCfg, numCh, useM8195A] = makeCfg(arbConfig);

% connect to scope
fscope = iqopen(scopeCfg);
if (isempty(fscope))
    result = 'Can''t connect to scope';
    return;
end

% connect to AWGs
f1 = iqopen(awg1);
% define on which channels the scope should compare signals
ch = [1 3];
% scope timebase scales for the three successive measurements
timebase = [10e-9 500e-12 50e-12];
% delay (in sec) to allow scope to take sufficient number of measurements
measDelay = [0.2 1 1];
if (isempty(initScopeMeasurement(fscope, ch, dParam)))
    return;
end
if (useM8195A)
    del12 = doScopeMeasurement(fscope, [1 2], numCh, timebase(1), measDelay(1));
    del13 = doScopeMeasurement(fscope, [1 3], numCh, timebase(1), measDelay(1));
    del14 = doScopeMeasurement(fscope, [1 4], numCh, timebase(1), measDelay(1));
    newTimebase = max(abs([del12 del13 del14 200e-12])) / 4;
    del12 = doScopeMeasurement(fscope, [1 2], numCh, newTimebase, measDelay(1));
    del13 = doScopeMeasurement(fscope, [1 3], numCh, newTimebase, measDelay(1));
    del14 = doScopeMeasurement(fscope, [1 4], numCh, newTimebase, measDelay(1));
    g_skew = [0 -del12 -del13 -del14];
    % round to integer number of samples
%    g_skew = round((g_skew + fixedSkew) * fs) / fs - fixedSkew;
else
    if (~isempty(awg2))
        f2 = iqopen(awg2);
        % initialize AWG delay
        setAWGDelay(f1, f2, [0 0 0 0], fixedSkew);
        % perform first measurement to determine coarse delay
        cdel = doScopeMeasurement(fscope, ch, numCh, timebase(1), measDelay(1));
        %fprintf('---\nskew1 = %g\n', cdel * 1e12);
        % if measurement is invalid, give up
        if (isempty(cdel))
            return;
        end
        %fprintf(sprintf('cdel = %g\n', round(cdel*1e12)));
        cdel = cdel + fixedSkew(ch(1)) - fixedSkew(ch(2));
        if (abs(cdel) > 10e-9)
            errordlg({sprintf('Skew is too large for the built-in delay line (%g ns).', cdel * 1e9) ...
                    'Please make sure that you have connected the AWG outputs' ...
                    'to the scope according to the connection diagram.'});
            return;
        end
        % set the coarse delay in the AWG
        setAWGDelay(f1, f2, [0 0 0 0], [cdel cdel 0 0] + fixedSkew);

        for mloop = 1:2
            % now measure again with higher resolution
            fdel = doScopeMeasurement(fscope, ch, numCh, timebase(1+mloop), measDelay(1+mloop));
            fdel = fdel + fixedSkew(ch(1)) - fixedSkew(ch(2));
            %fprintf('skew%d = %g\n', mloop + 1, fdel * 1e12);
            if (isempty(fdel))
                return;
            end
            %fprintf(sprintf('fdel = %g\n', round(fdel*1e12)));
            if (abs(cdel + fdel) > 10e-9)
                errordlg(sprintf('Delay after first correction too large: %g ns', (cdel + fdel) * 1e9));
                return;
            end
            pdel = cdel;
            cdel = pdel + fdel;
            setAWGDelay(f1, f2, [pdel pdel 0 0] + fixedSkew, [cdel cdel 0 0] + fixedSkew);
        end
    else
        cdel = 0;
        f2 = [];
    end

    % measure again (sanity check)
    % result = doScopeMeasurement(fscope, ch, numCh, timebase(3), measDelay(3));
    %fprintf('skewFinal = %g\n', result * 1e12);
    % xfprintf(fscope, sprintf(':acquire:average off'));

    % try to adjust the second channel of each AWG as well - if it is connected
    % if measurement is invalid, simply return
    if (isempty(strfind(awg1.model, 'M8195A')))
        del12 = doScopeMeasurement(fscope, [1 2], numCh, timebase(2), measDelay(2), 0);
        if (isempty(del12))
            errordlg({'Can''t measure skew of M8190A#1, channel 2.' ...
                    'Please make sure that you have connected the AWG outputs' ...
                    'to the scope according to the connection diagram.'});
            return;
        end
        %fprintf(sprintf('del12 = %g\n', round(del12*1e12)));
        del12 = del12 + fixedSkew(1) - fixedSkew(2);
    else
        del12 = 0;
    end

    if (~isempty(f2))
        del34 = doScopeMeasurement(fscope, [3 4], numCh, timebase(2), measDelay(2), 0);
        if (isempty(del34))
            errordlg({'Can''t measure skew of M8190A#2, channel 2.' ...
                    'Please make sure that you have connected the AWG outputs' ...
                    'to the scope according to the connection diagram.'});
            return;
        end
        %fprintf(sprintf('del34 = %g\n', round(del24*1e12)));
        del34 = del34 + fixedSkew(3) - fixedSkew(4);
        setAWGDelay(f1, f2, [cdel cdel 0 0] + fixedSkew, [cdel cdel-del12 0 -del34] + fixedSkew);
    else
        del34 = 0;
    end
    g_skew = [cdel cdel-del12 0 -del34];
end
% if we managed to get to here, all 4 scope channels have a valid signal,
% so lets turn them all on
for i = 1:4
    xfprintf(fscope, sprintf(':chan%d:disp on', i));
end
if (numCh <= 2)
    xfprintf(fscope, sprintf(':chan%d:disp off', 3));
    xfprintf(fscope, sprintf(':chan%d:disp off', 4));
end

% calibrate voltages, too
timebase = 10e-9;
xfprintf(fscope, sprintf(':timebase:scal %g', timebase));
xfprintf(fscope, sprintf(':meas:clear'));
meas_high = ones(1,4);
meas_low = -1*ones(1,4);
for i = 1:numCh
    meas_high(i) = str2double(query(fscope, sprintf(':meas:vtop? chan%d', i)));
    meas_low(i) = str2double(query(fscope, sprintf(':meas:vbase? chan%d', i)));
end
want_high = dParam.max;
want_low = dParam.min;
cal_high = 2*want_high - meas_high;
cal_low = 2*want_low - meas_low;
cal_amp = cal_high - cal_low;
cal_offs = (cal_high + cal_low)/2;

% make sure we are not exceeding the max amplitude of the AWG
maxAmpl = str2double(query(f1, ':VOLT:AMPL? MAX'));
if (max(cal_amp) > maxAmpl)
    msgbox(sprintf(['The amplitude calibration requires the AWG amplifier gain to be set to %.3gV. ' ...
        'This exceeds the AWGs maximum amplitude of %.3gV. ' ...
        'The amplifier gain will be set to %.3gV. Expect deviations from the configured amplitude.'], max(cal_amp), maxAmpl, maxAmpl));
    cal_amp(cal_amp > maxAmpl) = maxAmpl;
end

% apply new amplitude settings
setupTestPattern(arbConfig, fs, 0, slaveClk, 'init', fixedSkew, dParam);
% now show how nicely they are aligned
fscope = iqopen(scopeCfg);
xfprintf(fscope, sprintf(':meas:clear'));
if (numCh > 2)
    xfprintf(fscope, sprintf(':meas:deltatime chan%d,chan%d', 1, 4));
    xfprintf(fscope, sprintf(':meas:deltatime chan%d,chan%d', 1, 3));
end
xfprintf(fscope, sprintf(':meas:deltatime chan%d,chan%d', 1, 2));
xfprintf(fscope, sprintf(':meas:stat on'));
% channel 4 only used for DPHY
if (strcmp(dParam.mode, 'CPHY'))
    xfprintf(fscope, sprintf(':chan%d:disp off', 4));
end
fclose(fscope);


function cSkewChange = setAWGDelay(f1, f2, prevSkew, skew)
% set the skew for all four AWG channels to <skew>.
% <skew> must be a vector with 4 elements representing channels 1 2 3 & 4
% values can be negative (!)
% <prevSkew> is the "previous skew". This is used to keep the coarse delay
% unchanged if possible (<prevSkew> must also be a vector of four elements)
% returns 1 if any of the coarse skews were changed

%fprintf('skew in:  ');
%fprintf(sprintf('%g ', round(skew*1e12)));
%fprintf('\n');
% make them all zero-based
cSkewChange = 0;
skew = skew - min(skew);
prevSkew = prevSkew - min(prevSkew);
cskew = zeros(1,4);
fskew = zeros(1,4);
fvec = {f1 f1 f2 f2};
chvec = [1 2 1 2];
for i = 1:4
    if (skew(i) < 15e-12)
        cskew(i) = 0;
        fskew(i) = skew(i);
    else
        cskew(i) = floor((skew(i) - 15e-12) * 1e11) / 1e11;
        fskew(i) = skew(i) - cskew(i);
        if (prevSkew(i) ~= 0)
            cpskew = floor((prevSkew(i) - 15e-12) * 1e11) / 1e11;
            nfskew = skew(i) - cpskew;
            if (nfskew <= 30e-12 && nfskew >= 0)
                cskew(i) = cpskew;
                fskew(i) = nfskew;
            else
                cSkewChange = 1;
            end
        end
    end
    if (~isempty(fvec{i}))
        xfprintf(fvec{i}, sprintf(':arm:cdel%d %g', chvec(i), cskew(i)));
        xfprintf(fvec{i}, sprintf(':arm:del%d %g', chvec(i), fskew(i)));
    end
end
%fprintf('skew set: ');
%fprintf(sprintf('%g ', round((cskew+fskew)*1e12)));
%fprintf('coarse: ');
%fprintf(sprintf('%g ', round(cskew*1e12)));
%fprintf('fine: ');
%fprintf(sprintf('%g ', round(fskew*1e12)));
%fprintf('\n');


function result = initScopeMeasurement(fscope, ch, dParam)
result = [];
xfprintf(fscope, '*rst');
xfprintf(fscope, ':syst:head off');
for i = 1:4
    xfprintf(fscope, sprintf(':chan%d:disp on', i));
end
timebase = 10e-9;
xfprintf(fscope, sprintf(':timebase:scal %g', timebase));
offs = dParam.maxOffs;
scale = dParam.maxAmp / 6;
for i = 1:4
    xfprintf(fscope, sprintf(':chan%d:scale %g; offs %g', i, scale, offs));
end
trigLev = offs;
xfprintf(fscope, sprintf(':trig:mode edge'));
xfprintf(fscope, sprintf(':trig:edge:slope positive'));
xfprintf(fscope, sprintf(':trig:edge:source chan1'));
xfprintf(fscope, sprintf(':trig:lev chan1,%g', trigLev));
xfprintf(fscope, ':run');
res = query(fscope, 'ader?');
if (eval(res) ~= 1)
    % try one more time
    res = query(fscope, 'ader?');
    if (eval(res) ~= 1)
        res = questdlg('Please verify that the scope captures the waveform correctly and press OK','Scope','OK','Cancel','OK');
        if (~strcmp(res, 'OK'))
            fclose(fscope);
            return;
        end
    end
end
xfprintf(fscope, ':meas:deltatime:def rising,1,middle,rising,1,middle');
for i = 1:4
    xfprintf(fscope, sprintf(':meas:thresholds:absolute chan%d,%g,%g,%g', i, offs+dParam.maxAmp/4, offs, offs-dParam.maxAmp/4));
    xfprintf(fscope, sprintf(':meas:thresholds:method chan%d,absolute', i));
end
%xfprintf(fscope, sprintf(':acquire:average:count 8'));
%xfprintf(fscope, sprintf(':acquire:average on'));
result = 1;



function result = doScopeMeasurement(fscope, ch, numCh, timebase, measDelay, showError)
result = [];
if (~exist('showError', 'var'))
    showError = 1;
end
if (max(ch) > numCh)
    result = 0;
    return;
end
for i = 1:4
    xfprintf(fscope, sprintf(':chan%d:disp on', i));
end
xfprintf(fscope, sprintf(':timebase:scal %g', timebase));
doMeasAgain = 1;
while (doMeasAgain)
    xfprintf(fscope, sprintf(':meas:clear'));
    xfprintf(fscope, sprintf(':meas:deltatime chan%d,chan%d', ch(1), ch(2)));
    xfprintf(fscope, sprintf(':meas:stat on'));
    pause(measDelay);
    query(fscope, 'ader?');
    measStr = query(fscope, ':meas:results?');
    measList = eval(['[' measStr(11:end-1) ']']);
%    fprintf(sprintf('Result: %s\n', measStr));
    meas = measList(4);   % mean
    if (abs(meas) > 1e37)
        if (showError)
            errordlg({'Invalid scope measurement: ' sprintf('%g', meas) ' ' ...
                'Please make sure that you have connected the AWG outputs' ...
                'to the scope according to the connection diagram.'});
        end
        return;
    end
    if (abs(measList(3) - measList(2)) > 100e-12)   % max - min
        res = questdlg({'The scope returns delta time measurements with large variations.' ...
                       'Please verify that the slave clock source is set correctly and the' ...
                       'scope shows a steady waveform. Then press OK' },'Scope','OK','Cancel','OK');
        if (~strcmp(res, 'OK'))
            fclose(fscope);
            return;
        end
    else
        doMeasAgain = 0;
    end
    result = meas;
end


function [awg1, awg2, syncCfg, scopeCfg, numCh, useM8195A] = makeCfg(arbConfig)
% create separate config structures for AWG#1, AWG#2, SYNC module and scope
% The following configurations are supported:
% - two M8190A modules with SYNC module
% - two M8190A modules without SYNC module (sync via scope)
% - one M8190A module (only A & B signals will be generated)
% - one M8195A module
awg1 = [];
awg2 = [];
syncCfg = [];
scopeCfg = [];
numCh = 4;
useM8195A = 0;
if (~isempty(strfind(arbConfig.model, 'M8195A')))
    awg1 = arbConfig;
    numCh = arbConfig.numChannels;
    useM8195A = 1;
elseif (~isempty(strfind(arbConfig.model, 'M8190A')))
    if (~strcmp(arbConfig.connectionType, 'visa'))
        errormsg('Only VISA connection type is supported');
        return;
    end
    if (~iqoptcheck(arbConfig, 'bit', 'SEQ'))
        return;
    end
    awg1 = arbConfig;
    if (~isfield(arbConfig, 'visaAddr2'))
%        warndlg('Second M8190A is not configured - only A & B signals will be generated');
        numCh = 2;
    else
        awg2 = arbConfig;
        awg2.visaAddr = arbConfig.visaAddr2;
        if (~iqoptcheck(awg2, 'bit', 'SEQ'))
            result = -1
            return;
        end
        if (isfield(arbConfig, 'useM8192A') && arbConfig.useM8192A ~= 0)
            syncCfg.model = 'M8192A';
            syncCfg.connectionType = 'visa';
            syncCfg.visaAddr = arbConfig.visaAddrM8192A;
        end
    end
else
    errordlg('Only M8190A or M8195A AWGs are supported');
    return;
end
if ((~isfield(arbConfig, 'isScopeConnected') || (isfield(arbConfig, 'isScopeConnected') && arbConfig.isScopeConnected ~= 0)) && isfield(arbConfig, 'visaAddrScope'))
    scopeCfg.model = 'scope';
    scopeCfg.connectionType = 'visa';
    scopeCfg.visaAddr = arbConfig.visaAddrScope;
end



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
    result = query(f, ':syst:err?');
    if (isempty(result))
        fclose(f);
        errordlg({'The instrument did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'}, 'Error');
        retVal = -1;
        return;
    end
    if (~exist('ignoreError', 'var') || ignoreError == 0)
        if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12) && ~strncmp(result, '0', 1))
            errordlg({'Instrument returns an error on command:' s 'Error Message:' result});
            retVal = -1;
        end
    end

