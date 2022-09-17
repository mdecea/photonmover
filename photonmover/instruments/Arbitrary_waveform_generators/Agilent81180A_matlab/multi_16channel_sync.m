function result = multi_16channel_sync(varargin)
% Set up two M8190A modules to run in sync. This function is typically
% called from the multi_channel_sync_gui, but it can also be called from
% other MATLAB functions.
% Parameters are passed as name/value pairs. The following parameter names
% are supported:
% 'sampleRate' - the samplerate that will be used by both M8190A modules
% 'cmd' - can be 'manualDeskew', 'autoDeskew', 'start', 'stop'
% 'arbConfig' - arbConfig struct - optional (see loadArbConfig)
% 'useMarkers' - set to 1 if the channel 1 sample markers are used for
%               deskewing instead of the ch1 outputs of each module
% 'triggered' - if set to 1, will generate a single waveform on every
%              trigger event, otherwise will generate continuous signal
% 'fixedSkew' - manually entered skew for each channel (vector of 4 values)
%              if empty or all zeros, instrument skew will not be affected
%              M1=(1:2), M2=(3:4), S1a=(5:6), S1b=(7:8), S1c=(9:10),
%              S2a=(11:12), S2b=(13:14), S2c=(15:16)
% Harald Beck, Keysight Technologies 2014-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

result = [];
if (nargin == 0)
    multi_16channel_sync_gui;
    return;
end
% set default values - will be overwritten by arguments
cmd = '';
sampleRate = 12e9;
arbConfig = loadArbConfig();
useMarkers = 0;
triggered = 0;
waveformID = 3;  % pulse & sine wave
fixedSkew = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';     sampleRate = varargin{i+1};
            case 'cmd';            cmd = varargin{i+1};
            case 'arbconfig';      arbConfig = varargin{i+1};
            case 'usemarkers';     useMarkers = varargin{i+1};
            case 'triggered';      triggered = varargin{i+1};
            case 'fixedskew';      fixedSkew = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end


% common sample rate for both AWGs
fs = sampleRate;

switch (cmd)
    case 'manualDeskew'
        result = setupTestPattern(arbConfig, fs, 1, useMarkers, fixedSkew, 0, 2);
    case 'autoDeskew'
        result = setupTestPattern(arbConfig, fs, 1, useMarkers, fixedSkew, 0, 2);
        if (isempty(result))
            autoDeskew(arbConfig, fixedSkew);
        end
    case 'start'
        result = setupTestPattern(arbConfig, fs, 0, useMarkers, fixedSkew, triggered, waveformID);
        if (isfield(arbConfig, 'visaAddrScope'))
            setupScope(arbConfig, waveformID, triggered);
        end
    case 'stop'
        result = doStop(arbConfig);
    case 'trigger'
        result = doTrigger(arbConfig);
    otherwise
        error('unknown cmd');
end


function result = doStop(arbConfig)
[awg1 awg2 syncCfg sync2ndCfg scopeCfg] = makeCfg(arbConfig);
if (~isempty(syncCfg))
    fsync = iqopen(syncCfg);
    if (isempty(fsync))
        return;
    end
    xfprintf(fsync, ':abor');
    xfprintf(fsync, ':inst:mmod:conf 1');
    fclose(fsync);
    if (~isempty(sync2ndCfg))
        % 16 channels anticipated
        fsync2nd = iqopen(sync2ndCfg);
        if (isempty(fsync2nd))
            return;
        end
        xfprintf(fsync2nd, ':abor');
        xfprintf(fsync2nd, ':inst:mmod:conf 1');
        fclose(fsync2nd);
        
    end
else
    % open the connection to the AWGs
    f1 = iqopen(awg1);
    if (isempty(f1))
        return;
    end
    f2 = iqopen(awg2);
    if (isempty(f2))
        return;
    end
    % stop both of them
    fprintf(f1, ':abort');
    fprintf(f2, ':abort');
    fclose(f1);
    fclose(f2);
end
result = [];



function result = doTrigger(arbConfig)
[awg1 , ~, syncCfg, ~, ~] = makeCfg(arbConfig);
if (~isempty(syncCfg))
    fsync = iqopen(syncCfg);
    if (isempty(fsync))
        return;
    end
    xfprintf(fsync, ':trig:beg');
    fclose(fsync);
else
    % open the connection to AWG1
    f1 = iqopen(awg1);
    xfprintf(f1, ':TRIGger:BEGin');
    fclose(f1);
end
result = [];



function setupScope(arbConfig, waveformID, triggered)
% connect to scope
[~, ~, ~, ~, scopeCfg] = makeCfg(arbConfig);
fscope = iqopen(scopeCfg);
if (isempty(fscope))
    return;
end
% remove all measurements to avoid a cluttered screen
xfprintf(fscope, ':meas:clear');
switch (waveformID)
    case 2  % test pattern
        setupScope2(fscope);
        xfprintf(fscope, sprintf(':timebase:scal %g', 50e-9));
        xfprintf(fscope, sprintf(':trig:edge:source chan1'));
    case 3   % pulse & sine wave
        setupScope2(fscope);
        if (triggered)
            xfprintf(fscope, sprintf(':timebase:scal %g', 5e-6));
        else
            xfprintf(fscope, sprintf(':timebase:scal %g', 50e-9));
        end
        xfprintf(fscope, sprintf(':trig:edge:source chan1'));
        xfprintf(fscope, sprintf(':trig:lev chan1,%g', 100e-3));
end
fclose(fscope);


function setupScope2(fscope, scale)
offs = 0;
if (~exist('scale', 'var'))
    scale = 200e-3;
end
for i = [1 2 3 4]
    xfprintf(fscope, sprintf(':chan%d:disp on', i));
    xfprintf(fscope, sprintf(':chan%d:offs %g', i, offs));
    xfprintf(fscope, sprintf(':chan%d:scale %g', i, scale));
end


function result = setupTestPattern(arbConfig, fs, doDeskew, useMarkers, fixedSkew, triggered, waveformID)
result = [];
[awg1, awg2, syncCfg, sync2ndCfg, ~, awg1a, awg1b, awg1c, awg2a, awg2b, awg2c] = makeCfg(arbConfig);
awg2.extClk = 1;   % ARB #2 is the slave and will run on external clock
dummySegNum = 10;
testSegNum = 1;
% open the connection to the AWGs
f1 = iqopen(awg1);
if (isempty(f1))
    return;
end
f2 = iqopen(awg2);
if (isempty(f2))
    return;
end
if (~isempty(awg1a))
  f1a = iqopen(awg1a);
end
if (~isempty(awg1b))
  f1b = iqopen(awg1b);
end
if (~isempty(awg1c))
  f1c = iqopen(awg1c);
end
if (~isempty(awg2a))
  f2a = iqopen(awg2a);
end
if (~isempty(awg2b))
  f2b = iqopen(awg2b);
end
if (~isempty(awg2c))
  f2c = iqopen(awg2c);
end
fsync = iqopen(syncCfg);
if (isempty(fsync))
    return;
end
xfprintf(fsync, ':abor');
% always go to configuration mode and remote all modules
% so that we can set the sample rate and mode
fsync2nd = iqopen(sync2ndCfg);
if (isempty(fsync2nd))
    return;
end
xfprintf(fsync2nd, ':abor');
xfprintf(f1, sprintf(':MARKer1:SYNC:VOLTage:OFFSet %g; AMPLitude %g', 0.25, 0.5));
xfprintf(fsync2nd, sprintf(':ARM:TRIG:LEVel %g', 0.25));


% set marker levels if we are using markers
xfprintf(f1, sprintf(':MARKer1:SAMPle:VOLTage:OFFSet %g; AMPLitude %g', 0, 0.5));
xfprintf(f2, sprintf(':MARKer1:SAMPle:VOLTage:OFFSet %g; AMPLitude %g', 0, 0.5));

% switch AWG2 to internal clock temporarily to avoid clock loss
% but only if we actually perform deskew - not for simple start/stop
if (doDeskew && isempty(syncCfg))
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
    cmd = sprintf(':FREQuency:RASTer:SOURce INTernal; :FREQuency:RASTer %.15g', fs);
    if (~isempty(dwid))
        cmd = sprintf('%s; :TRACe1:DWIDth %s; :TRACe2:DWIDth %s', cmd, dwid, dwid);
    end
    xfprintf(f2, cmd);
end

%% set up AWG #1 -------------------------------------------------------
% delete all waveform segments
iqseq_multi('delete', [], 'arbConfig', awg1, 'keepOpen', 1);

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
n2 = n1 + (160 + 1 + round(fixDelay * fs / awg1.segmentGranularity)) * awg1.segmentGranularity;
dummySegment = zeros(1, n2);
% now create the real waveform segment, resp. the "test" segment which
% can be used to measure the skew
clear wfms;
switch (waveformID)
    case 2  % test segment
        t1 = real(iqpulsegen('arbConfig', awg1, 'sampleRate', fs, 'pw', 96000, 'rise', 0, 'fall', 0, 'off', 48000, 'high', 1, 'low', -1));
        wfms{1,1} = t1;
        wfms{1,2} = t1;
        wfms{1,3} = t1;
        wfms{1,4} = t1;
    case 3  % pulse followed by sinewave
        n = 192;
        for i = 1:4
            wfms{1,i} = [-1*ones(1,n) ones(1,n) zeros(1,i*n) sin(2*pi*(1:n)/n) zeros(1,(6-i)*n)];
        end
    otherwise
        error(['unexpected waveformID: ' num2str(waveformID)]);
end
% download the waveforms into AWG1, but don't start the AWG yet (run=0)
% also, keep the connection open to speed up the download process
for k = 1:size(wfms,1)
    iqdownload_multi(complex(wfms{k,1},wfms{k,2}), fs, 'arbConfig', awg1, 'keepOpen', 1, 'run', 0, 'segmentNumber', testSegNum+k-1);
end
iqdownload_multi(dummySegment, fs, 'arbConfig', awg1, 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);

%% set up ARB Slave #1a -------------------------------------------------------
% download the waveforms into AWG slave
% also, keep the connection open to speed up the download process
if (~isempty(awg1a))
    % delete all waveform segments
    iqseq_multi('delete', [], 'arbConfig', awg1a, 'keepOpen', 1, 'run', 0);
    for k = 1:size(wfms,1)
        iqdownload_multi(complex(wfms{k,2},wfms{k,2}), fs, 'arbConfig', awg1a, 'keepOpen', 1, 'run', 0, 'segmentNumber', testSegNum+k-1);
    end
    iqdownload_multi(dummySegment, fs, 'arbConfig', awg1a, 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);
end

%% set up ARB Slave #1b -------------------------------------------------------
% download the waveforms into AWG slave
% also, keep the connection open to speed up the download process
if (~isempty(awg1b))
    % delete all waveform segments
    iqseq_multi('delete', [], 'arbConfig', awg1b, 'keepOpen', 1, 'run', 0);
    for k = 1:size(wfms,1)
        iqdownload_multi(complex(wfms{k,2},wfms{k,2}), fs, 'arbConfig', awg1b, 'keepOpen', 1, 'run', 0, 'segmentNumber', testSegNum+k-1);
    end
    iqdownload_multi(dummySegment, fs, 'arbConfig', awg1b, 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);
end

%% set up ARB Slave #1c -------------------------------------------------------
% download the waveforms into AWG slave
% also, keep the connection open to speed up the download process
if (~isempty(awg1c))
    % delete all waveform segments
    iqseq_multi('delete', [], 'arbConfig', awg1c, 'keepOpen', 1, 'run', 0);
    for k = 1:size(wfms,1)
        iqdownload_multi(complex(wfms{k,2},wfms{k,2}), fs, 'arbConfig', awg1c, 'keepOpen', 1, 'run', 0, 'segmentNumber', testSegNum+k-1);
    end
    iqdownload_multi(dummySegment, fs, 'arbConfig', awg1c, 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);
end

%% set up ARB #2 -------------------------------------------------------
% delete all segments
iqseq_multi('delete', [], 'arbConfig', awg2, 'keepOpen', 1, 'run', 0);
% shorter dummy segment in the second AWG because by the time it receives
% the trigger, the first AWG was already running for some time
dummySegment = zeros(1, n1);
for k = 1:size(wfms,1)
    iqdownload_multi(complex(wfms{k,3},wfms{k,4}), fs, 'arbConfig', awg2, 'keepOpen', 1, 'run', 0, 'segmentNumber', testSegNum+k-1);
end
iqdownload_multi(dummySegment, fs, 'arbConfig', awg2, 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);

%% set up ARB Slave #2a -------------------------------------------------------
% download the waveforms into AWG slave
% also, keep the connection open to speed up the download process
if (~isempty(awg2a))
    % delete all segments
    iqseq_multi('delete', [], 'arbConfig', awg2a, 'keepOpen', 1, 'run', 0);
    for k = 1:size(wfms,1)
        iqdownload_multi(complex(wfms{k,4},wfms{k,4}), fs, 'arbConfig', awg2a, 'keepOpen', 1, 'run', 0, 'segmentNumber', testSegNum+k-1);
    end
    iqdownload_multi(dummySegment, fs, 'arbConfig', awg2a, 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);
end

%% set up ARB Slave #2b -------------------------------------------------------
% download the waveforms into AWG slave
% also, keep the connection open to speed up the download process
if (~isempty(awg2b))
    % delete all segments
    iqseq_multi('delete', [], 'arbConfig', awg2b, 'keepOpen', 1, 'run', 0);
    for k = 1:size(wfms,1)
        iqdownload_multi(complex(wfms{k,4},wfms{k,4}), fs, 'arbConfig', awg2b, 'keepOpen', 1, 'run', 0, 'segmentNumber', testSegNum+k-1);
    end
    iqdownload_multi(dummySegment, fs, 'arbConfig', awg2b, 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);
end

%% set up ARB Slave #2c -------------------------------------------------------
% download the waveforms into AWG slave
% also, keep the connection open to speed up the download process
if (~isempty(awg2c))
    % delete all segments
    iqseq_multi('delete', [], 'arbConfig', awg2c, 'keepOpen', 1, 'run', 0);
    for k = 1:size(wfms,1)
        iqdownload_multi(complex(wfms{k,4},wfms{k,4}), fs, 'arbConfig', awg2c, 'keepOpen', 1, 'run', 0, 'segmentNumber', testSegNum+k-1);
    end
    iqdownload_multi(dummySegment, fs, 'arbConfig', awg2c, 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);
end

%% now set up the sequence table (the same table will be used for both
% master modules).  Data is entered into a struct and then passed to iqseq()
clear seq;
i = 1;
% Without SYNC module, play a dummy segment once to compensate delay
if ((isempty(syncCfg) || ~isempty(sync2ndCfg)))
    seq(i).segmentNumber = dummySegNum;
    seq(i).segmentLoops = 1;
    seq(i).markerEnable = 1;    % marker to start the slave module
    seq(i).sequenceInit = 1;
    seq(i).sequenceEnd = 1;
    i = i + 1;
end
xfprintf(f2, ':TRIG:SOUR:ADV EVENT');
% the test segment(s)
for k = 1:size(wfms,1)
    seq(i).sequenceInit = 1;
    if (k > 1)
        seq(i).sequenceInit = 0;
    end
    if (k == size(wfms,1))
        seq(i).sequenceEnd = 1;
    end
    seq(i).segmentNumber = testSegNum+k-1;
    seq(i).segmentLoops = 1;
    seq(i).markerEnable = 1;
    if (triggered)
        seq(i).segmentAdvance = 'Auto';
    else
        seq(i).segmentAdvance = 'Conditional';
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
iqseq_multi('define', seq, 'arbConfig', awg1, 'keepOpen', 1, 'run', 0);
iqseq_multi('define', seq, 'arbConfig', awg2, 'keepOpen', 1, 'run', 0);

%% now set up the sequence table (the same table will be used for 
% slave modules).  Data is entered into a struct and then passed to iqseq()
clear seq;
% the dummy segment
i = 1;
seq(i).segmentNumber = dummySegNum;
seq(i).segmentLoops = 1;
seq(i).segmentAdvance = 'Auto';
seq(i).sequenceInit = 1;
seq(i).sequenceEnd = 0;
seq(i).markerEnable = 1;
i = i+1;
% the test segment(s)
for k = 1:size(wfms,1)
    seq(i).sequenceInit = 0;
    if (k > 1)
        seq(i).sequenceInit = 0;
    end
    if (k == size(wfms,1))
        seq(i).sequenceEnd = 1;
    end
    seq(i).segmentNumber = testSegNum+k-1;
    seq(i).segmentLoops = 1;
    seq(i).markerEnable = 1;
    if (triggered)
        seq(i).segmentAdvance = 'Auto';
    else
        seq(i).segmentAdvance = 'Conditional';
    end
    i = i + 1;
end
if (~isempty(awg1a))
    iqseq_multi('define', seq, 'arbConfig', awg1a, 'keepOpen', 1, 'run', 0);
    query(f1a, '*opc?');
    % turn on triggered mode in AWG slave in any case
    iqseq_multi('triggerMode', 'triggered', 'arbConfig', awg1a, 'keepopen', 1, 'run', 0);
    % and run (i.e. wait for trigger)
    query(f1a, '*opc?');
    iqseq_multi('mode', 'STS', 'arbConfig', awg1a, 'keepopen', 1, 'run', 0);
    % wait until AWG slave has started (make sure it is ready to respond to the trigger)
    query(f1a, '*opc?');
end
if (~isempty(awg1b))
    iqseq_multi('define', seq, 'arbConfig', awg1b, 'keepOpen', 1, 'run', 0);
    % turn on triggered mode in AWG slave in any case
    iqseq_multi('triggerMode', 'triggered', 'arbConfig', awg1b, 'keepopen', 1, 'run', 0);
    % and run (i.e. wait for trigger)
    iqseq_multi('mode', 'STS', 'arbConfig', awg1b, 'keepopen', 1, 'run', 0);
    % wait until AWG slave has started (make sure it is ready to respond to the trigger)
    query(f1b, '*opc?');
end
if (~isempty(awg1c))
    iqseq_multi('define', seq, 'arbConfig', awg1c, 'keepOpen', 1, 'run', 0);
    % turn on triggered mode in AWG slave in any case
    iqseq_multi('triggerMode', 'triggered', 'arbConfig', awg1c, 'keepopen', 1, 'run', 0);
    % and run (i.e. wait for trigger)
    iqseq_multi('mode', 'STS', 'arbConfig', awg1c, 'keepopen', 1, 'run', 0);
    % wait until AWG slave has started (make sure it is ready to respond to the trigger)
    query(f1c, '*opc?');
end
if (~isempty(awg2a))
    iqseq_multi('define', seq, 'arbConfig', awg2a, 'keepOpen', 1, 'run', 0);
    % turn on triggered mode in AWG slave in any case
    iqseq_multi('triggerMode', 'triggered', 'arbConfig', awg2a, 'keepopen', 1, 'run', 0);
    % and run (i.e. wait for trigger)
    iqseq_multi('mode', 'STS', 'arbConfig', awg2a, 'keepopen', 1, 'run', 0);
    % wait until AWG slave has started (make sure it is ready to respond to the trigger)
    query(f2a, '*opc?');
end
if (~isempty(awg2b))
    iqseq_multi('define', seq, 'arbConfig', awg2b, 'keepOpen', 1, 'run', 0);
    % turn on triggered mode in AWG slave in any case
    iqseq_multi('triggerMode', 'triggered', 'arbConfig', awg2b, 'keepopen', 1, 'run', 0);
    % and run (i.e. wait for trigger)
    iqseq_multi('mode', 'STS', 'arbConfig', awg2b, 'keepopen', 1, 'run', 0);
    % wait until AWG slave has started (make sure it is ready to respond to the trigger)
    query(f2b, '*opc?');
end
if (~isempty(awg2c))
    iqseq_multi('define', seq, 'arbConfig', awg2c, 'keepOpen', 1, 'run', 0);
    % turn on triggered mode in AWG slave in any case
    iqseq_multi('triggerMode', 'triggered', 'arbConfig', awg2c, 'keepopen', 1, 'run', 0);
    % and run (i.e. wait for trigger)
    iqseq_multi('mode', 'STS', 'arbConfig', awg2c, 'keepopen', 1, 'run', 0);
    % wait until AWG slave has started (make sure it is ready to respond to the trigger)
    query(f2c, '*opc?');
end

% set AWG #1 to triggered or continuous - depending on user selection
condTrig = ~isempty(syncCfg);
iqseq_multi('triggerMode', condTrig, 'arbConfig', awg1, 'keepopen', 1);
% turn on triggered mode in AWG #2 in any case
iqseq_multi('triggerMode', 'triggered', 'arbConfig', awg2, 'keepopen', 1);
% and run (i.e. wait for trigger)
iqseq_multi('mode', 'STSC', 'arbConfig', awg2, 'keepopen', 1);
% wait until AWG #2 has started (make sure it is ready to respond to the trigger)
query(f2, '*opc?');
% now start AWG #1 which will generate a SYNC marker and trigger AWG #2 and slaves
iqseq_multi('mode', 'STSC', 'arbConfig', awg1, 'keepopen', 1);
if (triggered && isempty(syncCfg))
    xfprintf(f1, sprintf(':STAB%d:SCEN:ADV AUTO', 1));
    xfprintf(f1, sprintf(':STAB%d:SCEN:ADV AUTO', 2));
    xfprintf(f2, sprintf(':STAB%d:SCEN:ADV AUTO', 1));
    xfprintf(f2, sprintf(':STAB%d:SCEN:ADV AUTO', 2));
end

fclose(f1);
fclose(f2);
if (~isempty(awg1a))
    fclose(f1a);
end
if (~isempty(awg1b))
    fclose(f1b);
end
if (~isempty(awg1c))
    fclose(f1c);
end
if (~isempty(awg2a))
    fclose(f2a);
end
if (~isempty(awg2b))
    fclose(f2b);
end
if (~isempty(awg2c))
    fclose(f2c);
end


function result = autoDeskew(arbConfig, fixedSkew)
result = [];
[awg1, awg2, syncCfg, sync2ndCfg, scopeCfg, awg1a, awg1b, awg1c, awg2a, awg2b, awg2c] = makeCfg(arbConfig);
% if skew is configured in arbConfig, it will overwrite the skew that is
% determined by autoDeskew function --> warn the user
if (isfield(awg1, 'skew'))
    errordlg('Please turn off "skew" setting in IQTools configuration window. It interferes with automatic deskew');
    return;
end
% connect to AWGs
f1 = iqopen(awg1);
if (isempty(f1))
    return;
end
f2 = iqopen(awg2);
if (isempty(f2))
    return;
end
if (~isempty(awg1a))
  f1a = iqopen(awg1a);
end
if (~isempty(awg1b))
  f1b = iqopen(awg1b);
end
if (~isempty(awg1c))
  f1c = iqopen(awg1c);
end
if (~isempty(awg2a))
  f2a = iqopen(awg2a);
end
if (~isempty(awg2b))
  f2b = iqopen(awg2b);
end
if (~isempty(awg2c))
  f2c = iqopen(awg2c);
end
% connect to scope
fscope = iqopen(scopeCfg);
if (isempty(fscope))
    return;
end

% connect to Sync Modules
fsync = iqopen(syncCfg);
if (isempty(fsync))
    return;
end
fsync2nd = iqopen(sync2ndCfg);
if (isempty(fsync2nd))
    return;
end

% define on which channels the scope should compare signals
ch = [1 3];
% scope timebase scales for the three successive measurements
timebase = [10e-9 500e-12 50e-12];
% delay (in sec) to allow scope to take sufficient number of measurements
measDelay = [0.2 1 1];
if (isempty(initScopeMeasurement(arbConfig, f1, fscope, ch)))
    return;
end
% initialize AWG delay
setAWGDelay(f1, f2, [0 0 0 0], fixedSkew);

% Find center of sequencer clock edge to guarantee trigger accuracy.
% Current implementation only reflects two master groups, i.e. 2x M8192A
% perform first measurement of sequencer clock edge
seqclkphase = doScopeMeasurement(fscope, ch, timebase(1), measDelay(1));
% if measurement is invalid, give up
if (isempty(seqclkphase))
    return;
end
seqclkruns = 20; % better repeat measurement until 80 to 90% of the sequencer clock period has been sampled
seqclkrange = zeros(1, seqclkruns);
fs_seqclkrun = arbConfig.defaultSampleRate * 0.9;
if fs_seqclkrun < min(arbConfig.minimumSampleRate)
    fs_seqclkrun = arbConfig.defaultSampleRate * 1.1;
end
for i = 1:seqclkruns
    seqclkrange(i) = seqclkphase;
    % stop both group masters
    xfprintf(fsync, ':ABOR');
    xfprintf(fsync2nd, ':ABOR');
    xfprintf(fsync2nd, ':INST:MMOD:CONF ON');
    % switch clock at group 2 master to let the sequencer divider find a
    % new starting phase
    xfprintf(f2, ':FREQ:RAST:SOUR1 INT');
    % change to another sample clock
    xfprintf(f2, ':FREQ:RAST:', fs_seqclkrun);
    query(f2, '*OPC?');
    xfprintf(f2, ':FREQ:RAST:SOUR1 EXT');
    query(f2, '*OPC?');
    % start group masters again
    xfprintf(fsync2nd, ':INST:MMOD:CONF OFF');
    xfprintf(fsync2nd, ':INIT:IMM');
    xfprintf(fsync, ':INIT:IMM');
    xfprintf(fsync, ':TRIG:BEG');
    query(fsync, '*OPC?');
    % measure next possible sequencer clock edge position
    seqclkphase = doScopeMeasurement(fscope, ch, timebase(1), measDelay(1));
end
seqclkrange(i) = seqclkphase;
% calculate min and max values for sequencer clock edge position
seqclkmin = min(seqclkrange) + 0.45*(max(seqclkrange) - min(seqclkrange));
seqclkmax = max(seqclkrange) - 0.45*(max(seqclkrange) - min(seqclkrange));
% Repeat restart of sequencer clock as long as the edge is out of the valid
% range.
while (seqclkphase < seqclkmin) || (seqclkphase > seqclkmax)
    seqclkrange(i) = seqclkphase;
    % stop both group masters
    xfprintf(fsync, ':ABOR');
    xfprintf(fsync2nd, ':ABOR');
    xfprintf(fsync2nd, ':INST:MMOD:CONF ON');
    % switch clock at group 2 master to let the sequencer divider find a
    % new starting phase
    xfprintf(f2, ':FREQ:RAST:SOUR1 INT');
    % change to another sample clock
    xfprintf(f2, ':FREQ:RAST:', fs_seqclkrun);
    query(f2, '*OPC?');
    xfprintf(f2, ':FREQ:RAST:SOUR1 EXT');
    query(f2, '*OPC?');
    % start group masters again
    xfprintf(fsync2nd, ':INST:MMOD:CONF OFF');
    xfprintf(fsync2nd, ':INIT:IMM');
    xfprintf(fsync, ':INIT:IMM');
    xfprintf(fsync, ':TRIG:BEG');
    query(fsync, '*OPC?');
    % measure next possible sequencer clock edge position
    seqclkphase = doScopeMeasurement(fscope, ch, timebase(1), measDelay(1));
end

% perform first measurement to determine coarse delay
cdel = doScopeMeasurement(fscope, ch, timebase(1), measDelay(1));
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
setAWGDelay(f1, f2, [0 0 0 0], [cdel cdel 0 0] + fixedSkew(1:4));

for mloop = 1:2
    % now measure again with higher resolution
    fdel = doScopeMeasurement(fscope, ch, timebase(1+mloop), measDelay(1+mloop));
    if (isempty(fdel))
        errordlg('Please double check that AWG channels are connected to the scope according to the connection diagram');
        return;
    end
    fdel = fdel + fixedSkew(ch(1)) - fixedSkew(ch(2));
    %fprintf(sprintf('fdel = %g\n', round(fdel*1e12)));
    if (abs(cdel + fdel) > 10e-9)
        errordlg(sprintf('Delay after first correction too large: %g ns', (cdel + fdel) * 1e9));
        return;
    end
    pdel = cdel;
    cdel = pdel + fdel;
    setAWGDelay(f1, f2, [pdel pdel 0 0] + fixedSkew(1:4), [cdel cdel 0 0] + fixedSkew(1:4));
end

%  fixedSkew arry structure for master 1 to slave 2c
%    M1=(1:2), M2=(3:4), S1a=(5:6), S1b=(7:8), S1c=(9:10), S2a=(11:12), S2b=(13:14), S2c=(15:16)

% channel 1 of master 1 and 2 have been used for
if (~isempty(awg1a))
    setAWGDelay(f1a, f1a, [0 0 0 0], [0 0 cdel cdel] + [0 0 fixedSkew(5:6)] - [0 0 fixedSkew(1:2)]);
end
if (~isempty(awg1b))
    setAWGDelay(f1b, f1b, [0 0 0 0], [0 0 cdel cdel] + [0 0 fixedSkew(7:8)] - [0 0 fixedSkew(1:2)]);
end
if (~isempty(awg1c))
    setAWGDelay(f1c, f1c, [0 0 0 0], [0 0 cdel cdel] + [0 0 fixedSkew(9:10)] - [0 0 fixedSkew(1:2)]);
end
% set delay of all group 2 channels to the master 2 channel 1 settings
if (~isempty(awg2a))
    setAWGDelay(f2a, f2a, [0 0 0 0], [0 0 0 0] + [0 0 fixedSkew(11:12)] - [0 0 fixedSkew(3:4)]);
end
if (~isempty(awg2b))
    setAWGDelay(f2b, f2b, [0 0 0 0], [0 0 0 0] + [0 0 fixedSkew(13:14)] - [0 0 fixedSkew(3:4)]);
end
if (~isempty(awg2c))
    setAWGDelay(f2c, f2c, [0 0 0 0], [0 0 0 0] + [0 0 fixedSkew(15:16)] - [0 0 fixedSkew(3:4)]);
end

% measure again (sanity check)
% result = doScopeMeasurement(fscope, ch, timebase(3), measDelay(3));
%fprintf('skewFinal = %g\n', result * 1e12);
% xfprintf(fscope, sprintf(':acquire:average off'));

% try to adjust the second channel of each AWG as well - if it is connected
% if measurement is invalid, simply return
del12 = doScopeMeasurement(fscope, [1 2], timebase(2), measDelay(2), 0);
if (isempty(del12))
    warndlg({'Can not measure delay between channel 1 and 2. Please check'
        'that all channels are connected according to the connection diagram.'
        '(Deskew operation will continue assuming a zero delay)'});
    del12 = 0;
end
%fprintf(sprintf('del12 = %g\n', round(del12*1e12)));
del12 = del12 + fixedSkew(1) - fixedSkew(2);
del34 = doScopeMeasurement(fscope, [3 4], timebase(2), measDelay(2), 0);
if (isempty(del34))
    warndlg({'Can not measure delay between channel 3 and 4. Please check'
        'that all channels are connected according to the connection diagram.'
        '(Deskew operation will continue assuming a zero delay)'});
    del34 = 0;
end
%fprintf(sprintf('del34 = %g\n', round(del34*1e12)));
del34 = del34 + fixedSkew(3) - fixedSkew(4);
setAWGDelay(f1, f2, [cdel cdel 0 0] + fixedSkew(1:4), [cdel cdel-del12 0 -del34] + fixedSkew(1:4));
% if we managed to get to here, all 4 scope channels have a valid signal,
% so lets turn them all on
for i = 1:4
    xfprintf(fscope, sprintf(':chan%d:disp on', i));
end
xfprintf(fscope, sprintf(':meas:clear'));
xfprintf(fscope, sprintf(':meas:deltatime chan%d,chan%d', 1, 2));
xfprintf(fscope, sprintf(':meas:deltatime chan%d,chan%d', 1, 3));
xfprintf(fscope, sprintf(':meas:deltatime chan%d,chan%d', 1, 4));
xfprintf(fscope, sprintf(':meas:stat on'));
fclose(f1);
fclose(f2);
fclose(fscope);
fclose(fsync);
fclose(fsync);
if (~isempty(awg1a))
    fclose(f1a);
end
if (~isempty(awg1b))
    fclose(f1b);
end
if (~isempty(awg1c))
    fclose(f1c);
end
if (~isempty(awg2a))
    fclose(f2a);
end
if (~isempty(awg2b))
    fclose(f2b);
end
if (~isempty(awg2c))
    fclose(f2c);
end


function cSkewChange = setAWGDelay(f1, f2, prevSkew, skew)
% set the skew for all four AWG channels to <skew>.
% <skew> must be a vector with 4 elements representing channels 1 2 3 & 4
% values can be negative (!)
% <prevSkew> is the "previous skew". This is used to keep the coarse delay
% unchanged if possible (<prevSkew> must also be a vector of four elements)
% returns 1 if any of the coarse skews were changed

% make them all zero-based
cSkewChange = 0;
skew = skew - min(skew);
prevSkew = prevSkew - min(prevSkew);
cskew = zeros(1,4);
fskew = zeros(1,4);
fvec = [f1 f1 f2 f2];
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
%    if (chvec(i) == 1) for 1 channel M8190A
    xfprintf(fvec(i), sprintf(':arm:cdel%d %g', chvec(i), cskew(i)));
    xfprintf(fvec(i), sprintf(':arm:del%d %g', chvec(i), fskew(i)));
%    end
end
%fprintf('skew set: ');
%fprintf(sprintf('%g ', round((cskew+fskew)*1e12)));
%fprintf('coarse: ');
%fprintf(sprintf('%g ', round(cskew*1e12)));
%fprintf('fine: ');
%fprintf(sprintf('%g ', round(fskew*1e12)));
%fprintf('\n');


function result = initScopeMeasurement(arbConfig, f1, fscope, ch)
result = [];
xfprintf(fscope, '*rst');
xfprintf(fscope, ':syst:head off');
for i = 1:4
    xfprintf(fscope, sprintf(':chan%d:disp on', i));
end
trigLev = str2double(query(f1, ':volt:offs?'));
ampl = str2double(query(f1, ':volt:ampl?'));

timebase = 10e-9;
xfprintf(fscope, sprintf(':timebase:scal %g', timebase));
scale = ampl / 6;
for i = 1:4
    xfprintf(fscope, sprintf(':chan%d:offs %g', i, trigLev));
    xfprintf(fscope, sprintf(':chan%d:scale %g', i, scale));
end
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
    xfprintf(fscope, sprintf(':meas:thresholds:absolute chan%d,%g,%g,%g', i, trigLev+ampl/4, trigLev, trigLev-ampl/4));
    xfprintf(fscope, sprintf(':meas:thresholds:method chan%d,absolute', i));
end
xfprintf(fscope, sprintf(':acquire:average:count 4'));
xfprintf(fscope, sprintf(':acquire:average on'));
result = 1;



function result = doScopeMeasurement(fscope, ch, timebase, measDelay, showError)
result = [];
if (~exist('showError', 'var'))
    showError = 1;
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
    meas = measList(4);   % mean
    if (abs(meas) > 1e37)
        if (showError)
            errordlg({'Signal edges were not found on the scope.' ...
                'Please make sure that you have connected the AWG outputs' ...
                'to the scope according to the connection diagram.' ...
                '(Measurement result returned was: ' sprintf('%g', meas) ')'});
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


function [awg1, awg2, syncCfg, sync2ndCfg, scopeCfg, awg1a, awg1b, awg1c, awg2a, awg2b, awg2c] = makeCfg(arbConfig)
% create separate config structures for AWG#1, AWG#2, SYNC, SYNC#2 module and scope
if (~strcmp(arbConfig.connectionType, 'visa'))
    errordlg('Only VISA connection type is supported by this utility');
end
if (~isfield(arbConfig, 'visaAddrM2'))
    errordlg('Please configure second M8190A module in configuration window');
end
awg1 = arbConfig;
awg1.visaAddr = arbConfig.visaAddrM1;
awg2 = arbConfig;
awg2.visaAddr = arbConfig.visaAddrM2;
scopeCfg = [];
if (isfield(arbConfig, 'visaAddrScope'))
    scopeCfg.model = 'scope';
    scopeCfg.connectionType = 'visa';
    scopeCfg.visaAddr = arbConfig.visaAddrScope;
end
syncCfg = [];
syncCfg.model = 'M8192A';
syncCfg.connectionType = 'visa';
syncCfg.visaAddr = arbConfig.visaAddrSync1;
sync2ndCfg = [];
sync2ndCfg.model = 'M8192A';
sync2ndCfg.connectionType = 'visa';
sync2ndCfg.visaAddr = arbConfig.visaAddrSync2;
% additional slaves
awg1a = [];
if (isfield(arbConfig, 'visaAddrS1a'))
  awg1a = arbConfig;
  awg1a.visaAddr = arbConfig.visaAddrS1a;
end
awg1b = [];
if (isfield(arbConfig, 'visaAddrS1b'))
    awg1b = arbConfig;
    awg1b.visaAddr = arbConfig.visaAddrS1b;
end
awg1c = [];
if (isfield(arbConfig, 'visaAddrS1c'))
    awg1c = arbConfig;
    awg1c.visaAddr = arbConfig.visaAddrS1c;
end
awg2a = [];
if (isfield(arbConfig, 'visaAddrS2a'))
    awg2a = arbConfig;
    awg2a.visaAddr = arbConfig.visaAddrS2a;
end
awg2b = [];
if (isfield(arbConfig, 'visaAddrS2b'))
    awg2b = arbConfig;
    awg2b.visaAddr = arbConfig.visaAddrS2b;
end
awg2c = [];
if (isfield(arbConfig, 'visaAddrS2c'))
    awg2c = arbConfig;
    awg2c.visaAddr = arbConfig.visaAddrS2c;
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



% The iqdownload functionality is copied into this file, because of changes in the
% run stop behavior.
%
function result = iqdownload_multi(iqdata, fs, varargin)
% Download a vector of I/Q samples to the configured AWG
% - iqdata - contains a row-vector of complex I/Q samples
%            additional columns may contain marker info
% - fs - sampling rate in Hz
% optional arguments are specified as attribute/value pairs:
% - 'segmentNumber' - specify the segment number to use (default = 1)
% - 'normalize' - auto-scale the data to max. DAC range (default = 1)
% - 'downloadToChannel - string that describes to which AWG channel
%              the data is downloaded. (deprecated, please use
%              'channelMapping' instead)
% - 'channelMapping' - new format for AWG channel mapping:
%              vector with 2 columns and 1..n rows. Columns represent 
%              I and Q, rows represent AWG channels. Each element is either
%              1 or 0, indicating whether the signal is downloaded to
%              to the respective channel
% - 'sequence' - description of the sequence table 
% - 'marker' - vector of integers that must have the same length as iqdata
%              low order bits correspond to marker outputs
% - 'arbConfig' - struct as described in loadArbConfig (default: [])
% - 'keepOpen' - if set to 1, will keep the connection to the AWG open
%              after downloading the waveform
% - 'run' - determines if the AWG will be started immediately after
%              downloading the waveform/sequence. (default: 1)
%
% If arbConfig is not specified, the file "arbConfig.mat" is expected in
% the current directory.
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

%% parse optional arguments
segmNum = 1;
result = [];
keepOpen = 0;
normalize = 1;
downloadToChannel = [];
channelMapping = [1 0; 0 1];
sequence = [];
arbConfig = [];
clear marker;
run = 1;
for i = 1:nargin-2
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'segmentnumber';  segmNum = varargin{i+1};
            case 'keepopen'; keepOpen = varargin{i+1};
            case 'normalize'; normalize = varargin{i+1};
            case 'downloadtochannel'; downloadToChannel = varargin(i+1);
            case 'channelmapping'; channelMapping = varargin{i+1};
            case 'marker'; marker = varargin{i+1};
            case 'sequence'; sequence = varargin{i+1};
            case 'arbconfig'; arbConfig = varargin{i+1};
            case 'run'; run = varargin{i+1};
        end
    end
end


% convert old format for "downloadToChannel" to channelMapping
% new format is array with row=channel, column=I/Q
if (~isempty(downloadToChannel))
    disp('downloadToChannel is deprecated, please use channelMapping instead');
    if (iscell(downloadToChannel))
        downloadToChannel = downloadToChannel{1};
    end
    if (ischar(downloadToChannel))
        switch (downloadToChannel)
            case 'I+Q to channel 1+2'
                channelMapping = [1 0; 0 1];
            case 'I+Q to channel 2+1'
                channelMapping = [0 1; 1 0];
            case 'I to channel 1'
                channelMapping = [1 0; 0 0];
            case 'I to channel 2'
                channelMapping = [0 0; 1 0];
            case 'Q to channel 1'
                channelMapping = [0 1; 0 0];
            case 'Q to channel 2'
                channelMapping = [0 0; 0 1];
            case 'RF to channel 1'
                channelMapping = [1 1; 0 0];
            case 'RF to channel 2'
                channelMapping = [0 0; 1 1];
            case 'RF to channel 1+2'
                channelMapping = [1 1; 1 1];
            otherwise
                error(['unexpected value for downloadToChannel argument: ' downloadToChannel]);
        end
    end
end

if (ischar(channelMapping))
    error('unexpected format for parameter channelMapping: string');
end

% if markers are not specified, generate square wave marker signal
if (~exist('marker', 'var'))
    marker = [15*ones(floor(length(iqdata)/2),1); zeros(length(iqdata)-floor(length(iqdata)/2),1)];
end
% try to load the configuration from the file arbConfig.mat
arbConfig = loadArbConfig(arbConfig);

% make sure the data is in the correct format
if (isvector(iqdata) && size(iqdata,2) > 1)
    iqdata = iqdata.';
end

% normalize if required
if (normalize && ~isempty(iqdata))
    scale = max(max(abs(real(iqdata(:,1)))), max(abs(imag(iqdata(:,1)))));
    if (scale > 1)
        if (normalize)
            iqdata(:,1) = iqdata(:,1) / scale;
        else
            errordlg('Data must be in the range -1...+1', 'Error');
        end
    end
end

%% extract data
    numColumns = size(iqdata, 2);
    if (~isvector(iqdata) && numColumns >= 2)
        data = iqdata(:,1);
    else
        data = reshape(iqdata, numel(iqdata), 1);
    end
    if (isfield(arbConfig, 'DACRange') && arbConfig.DACRange ~= 1)
        data = data .* arbConfig.DACRange;
    end
    
%% apply I/Q gainCorrection if necessary
    if (isfield(arbConfig, 'gainCorrection') && arbConfig.gainCorrection ~= 0)
        data = complex(real(data) * 10^(arbConfig.gainCorrection/20), imag(data));
        scale = max(max(real(data)), max(imag(data)));
        if (scale > 1)
            data = data ./ scale;
        end
    end

%% extract markers - assume there are two markers per channel
    marker = reshape(marker, numel(marker), 1);
    marker1 = bitand(uint16(marker),3);
    marker2 = bitand(bitshift(uint16(marker),-2),3);
    
    len = length(data);
    if (mod(len, arbConfig.segmentGranularity) ~= 0)
        errordlg(['Segment size is ' num2str(len) ', must be a multiple of ' num2str(arbConfig.segmentGranularity)], 'Error');
        return;
    elseif (len < arbConfig.minimumSegmentSize && len ~= 0)
        errordlg(['Segment size is ' num2str(len) ', must be >= ' num2str(arbConfig.minimumSegmentSize)], 'Error');
        return;
    elseif (len > arbConfig.maximumSegmentSize)
        errordlg(['Segment size is ' num2str(len) ', must be <= ' num2str(arbConfig.maximumSegmentSize)], 'Error');
        return;
    end
    if (isfield(arbConfig, 'interleaving') && arbConfig.interleaving)
        fs = fs / 2;
        data = real(data);                              % take the I signal
        data = complex(data(1:2:end), data(2:2:end));   % and split it into two channels
        if (~isempty(marker1))
            marker1 = marker1(1:2:end);
            marker2 = marker2(1:2:end);
        end
        if (size(channelMapping, 1) == 4)
            if (max(max(channelMapping(1:2,:))) > 0)
                channelMapping(1:2,:) = [1 0; 0 1];
            end
            if (max(max(channelMapping(3:4,:))) > 0)
                channelMapping(3:4,:) = [1 0; 0 1];
            end
        else
            channelMapping = [1 0; 0 1];
        end
    end
    
%% establish a connection and download the data
    result = iqdownload_multi_M8190A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);


function result = iqdownload_multi_M8190A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run)
% Download a waveform to the M8190A
% It is NOT intended that this function be called directly, only via iqdownload
%
% Harald Beck, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    result = [];
    
    % find out if sync module is used
    useM8192A = 0;
    if (isfield(arbConfig, 'useM8192A') && (arbConfig.useM8192A ~= 0))
        useM8192A = 1;
        if (arbConfig.useM8192A > 1)
            useM8192A = 2;
        end
    end
    
    % if called with more than two channels, send data to second M8190A
    if (size(channelMapping, 1) > 2 && isfield(arbConfig, 'visaAddr2')) % && max(max(channelMapping(3:4,:))) > 0)
        arb2 = arbConfig;
        arb2.visaAddr = arb2.visaAddr2;
        result = iqdownload_multi_M8190A(arb2, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping(3:4,:), sequence, run);
        % if nothing on channels 1 & 2, return the result
        if (max(max(channelMapping(1:2,:))) == 0)
            return;
        end
    end
    channelMapping(3:end,:) = [];
    
    % interpolation factor for digital upconversion modes
    interpolationFactor = 1;
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    result = f;
    
    % find out if we have a one-channel or two channel instrument.
    try
        opts = query(f, '*opt?');
    catch ex
        errordlg({'Can not communicate with M8190A Firmware. Please try again.'
            'If this does not solve the problem, exit and restart MATLAB'
            ['(Error message: ' ex.message]});
        return;
    end
    if (~isempty(strfind(opts, '001')))
        numChannels = 1;
        % be graceful with one-channel instruments and ignore anything
        % that deals with the second channel
        channelMapping(2,:) = [0 0];
    else
        numChannels = 2;
    end
    % treat sequence setup completely separate from waveform download
    if (~isempty(sequence))
        result = setupSequence(f, arbConfig, sequence, channelMapping, run, useM8192A, keepOpen);
    else
        % perform instrument reset if it is selected in the configuration
        if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
            if (isempty(find(channelMapping(:,1), 1)) || isempty(find(channelMapping(:,2), 1)))
                warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                         'waveform to only one channel. This will delete the waveform on the' ...
                         'other channel. If you want to keep the previous waveform, please' ...
                         'un-check the "send *RST" checkbox in the Configuration window.'});
            elseif (segmNum ~= 1)
                warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                         'waveform to segment number greater than 1. This will delete all other' ...
                         'waveform segments. If you want to keep the previous waveform, please' ...
                         'un-check the "send *RST" checkbox in the Configuration window.'});
            end
            xfprintf(f, '*RST');
        end
        % stop waveform output
        if (useM8192A)
            try
                arbSync = loadArbConfig();
                arbSync.visaAddr = arbConfig.visaAddrM8192A;
                fsync = iqopen(arbSync);
                xfprintf(fsync, ':ABOR');
                xfprintf(fsync, ':inst:mmod:conf 1');
                xfprintf(fsync, ':inst:slave:del:all');
                xfprintf(fsync, ':inst:mast ""');
                query(fsync, '*opc?');
                fclose(fsync);
                if (useM8192A > 1)
                    arbSync.visaAddr = arbConfig.visaAddrSync2;
                    fsync2nd = iqopen(arbSync);
                    xfprintf(fsync2nd, ':ABOR');
                    xfprintf(fsync2nd, ':inst:mmod:conf 1');
                    xfprintf(fsync2nd, ':inst:slave:del:all');
                    xfprintf(fsync2nd, ':inst:mast ""');
                    query(fsync2nd, '*opc?');
                    fclose(fsync2nd);
                end
            catch ex
                msgbox(ex.message);
            end
        else
            if (run >= 0)
                for i = find(channelMapping(:,1) + channelMapping(:,2))'
                    xfprintf(f, sprintf(':ABORt%d', i));
                end
            end
        end
        % determine which version of the instrument we have and set parameters
        % accordingly
        switch (arbConfig.model)
            case 'M8190A_12bit'
                dwid = 'WSPeed';
            case 'M8190A_14bit'
                dwid = 'WPRecision';
            case { 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }
                interpolationFactor = eval(arbConfig.model(13:end));
                fs = fs * interpolationFactor;
                dwid = sprintf('INTX%d', interpolationFactor);
            otherwise
                dwid = [];
                % older instrument - do not send any command
        end
        % set frequency, int/ext and precision in a single command to avoid out-of-range
        % errors
        if (fs ~= 0)
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                if (isfield(arbConfig, 'extClk') && arbConfig.extClk)
                    cmd = sprintf(':FREQuency:RASTer:SOURce%d EXTernal; :FREQuency:RASTer:EXTernal %.15g;', i, fs);
                else
                    cmd = sprintf(':FREQuency:RASTer:SOURce%d INTernal; :FREQuency:RASTer %.15g;', i, fs);
                end
                if (~isempty(dwid))
                    % set format on both channels in all cases
                    % otherwise, an error might occur if the channels
                    % are uncoupled
                    cmd = sprintf('%s :TRACe1:DWIDth %s; :TRACe2:DWIDth %s;', cmd, dwid, dwid);
                end
                % if we get an error when setting the mode, don't attempt to
                % do anything else - it will not work
                % However, if the SYNC module is in use, ignore errors
                % (can't set sample rate in slave module)
%                if (xfprintf(f, cmd, useM8192A) ~= 0)
                if (xfprintf(f, cmd, 1) ~= 0)
                    return;
                end
                % workaround: read error queue one more time, because
                % the slave M8190A will throw two errors.
                % Ideally, this should be taken care of in xfprintf
                if (useM8192A)
                    query(f, ':syst:err?');
                    query(f, ':syst:err?');
                end
            end
        end
        contMode = 1;
        gateMode = 0;
        if (isfield(arbConfig, 'triggerMode'))
            switch(arbConfig.triggerMode)
                case 'Continuous'
                    contMode = 1;
                    gateMode = 0;
                case 'Triggered'
                    contMode = 0;
                    gateMode = 0;
                case 'Gated'
                    contMode = 0;
                    gateMode = 1;
                otherwise
                    contMode = -1;
                    gateMode = -1;
            end
        end
        if (~useM8192A && contMode >= 0)
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':INIT:CONTinuous%d %d; :INIT:GATE%d %d', i, contMode, i, gateMode));
            end
        end
        if (interpolationFactor ~= 1)
            % DUC mode waveform download
            if (sum(channelMapping(1,:)) ~= 0)
                gen_arb_IQ_M8190A(arbConfig, f, 1, data, marker1, segmNum);
            end
            if (sum(channelMapping(2,:)) ~= 0)
                gen_arb_IQ_M8190A(arbConfig, f, 2, data, marker2, segmNum);
            end
        else
            % direct mode waveform download
            for ch = find(channelMapping(:,1))'
                gen_arb_M8190A(arbConfig, f, ch, real(data), marker1, segmNum, run);
            end
            for ch = find(channelMapping(:,2))'
                gen_arb_M8190A(arbConfig, f, ch, imag(data), marker2, segmNum, run);
            end
        end
        if (isfield(arbConfig,'skew') && isfloat(arbConfig.skew))
            % in arbConfig, there is no separate skew value for ch1 and
            % ch2. Positive values mean Ch1 is delayed, negative values
            % mean that Ch2 is delayed
            skew = arbConfig.skew;
            ch = 1;
            if (skew < 0)
                skew = -1 * skew;
                ch = 2;
            end
            if (numChannels >= 2)
                if (arbConfig.skew > 30e-12)
                    xfprintf(f, sprintf(':ARM:CDELay%d %.12g', ch, skew));
                    xfprintf(f, sprintf(':ARM:DELay%d 0', ch));
                    if (numChannels > 1)
                        xfprintf(f, sprintf(':ARM:CDELay%d %.12g', 3-ch, 0));
                        xfprintf(f, sprintf(':ARM:DELay%d 0', 3-ch));
                    end
                else
                    xfprintf(f, sprintf(':ARM:CDELay%d 0', ch));
                    xfprintf(f, sprintf(':ARM:DELay%d %.12g', ch, arbConfig.skew));
                    if (numChannels > 1)
                        xfprintf(f, sprintf(':ARM:CDELay%d 0', 3-ch));
                        xfprintf(f, sprintf(':ARM:DELay%d %.12g', 3-ch, 0));
                    end
                end
            end
        end
        doRun(f, arbConfig, useM8192A, channelMapping, run, keepOpen);
    end
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end;


function doRun(f, arbConfig, useM8192A, channelMapping, run, keepOpen)
    if (useM8192A)
        % don't do anything for the recursive call
        if (run == 1 && ~strcmp(arbConfig.visaAddr, arbConfig.visaAddr2))
            if (isfield(arbConfig, 'useM8192A') && (arbConfig.useM8192A == 1))
                % one sync module
                try
                    arbSync = loadArbConfig();
                    arbSync.visaAddr = arbSync.visaAddrM8192A;
                    fsync = iqopen(arbSync);
                    xfprintf(fsync, ':ABOR');
                    xfprintf(fsync, ':inst:mmod:conf 1');
                    xfprintf(fsync, ':inst:mast ""');
                    xfprintf(fsync, ':inst:slave:del:all');
                    xfprintf(fsync, sprintf(':inst:mast "%s"', arbConfig.visaAddr));
	                xfprintf(fsync, sprintf(':inst:slave:add "%s"', arbConfig.visaAddr2));
                    xfprintf(fsync, ':inst:mmod:conf 0');
                    % for triggered mode, switch the Trace Advance back to AUTO
                    if (isfield(arbConfig, 'triggerMode') && strcmp(arbConfig.triggerMode, 'Triggered'))
                        for i = find(channelMapping(:,1) + channelMapping(:,2))'
                            xfprintf(f, sprintf(':trace%d:adv auto', i));
                        end
                        arb2 = loadArbConfig();
                        arb2.visaAddr = arb2.visaAddr2;
                        f2 = iqopen(arb2);
                        for i = find(channelMapping(:,1) + channelMapping(:,2))'
                            xfprintf(f2, sprintf(':trace%d:adv auto', i));
                        end
                        fclose(f2);
                    end
                    xfprintf(fsync, ':init:imm');
                    xfprintf(fsync, ':trig:beg');
                    query(fsync, '*opc?');
                    fclose(fsync);
                catch ex
                    msgbox(ex.message);
                end
            else
                % two sync modules
                try
                    % Group 2
                    arbSync = loadArbConfig();
                    arbSync.visaAddr = arbSync.visaAddrSync2;
                    fsync2nd = iqopen(arbSync);
                    xfprintf(fsync2nd, ':ABOR');
                    xfprintf(fsync2nd, ':inst:mmod:conf 1');
                    xfprintf(fsync2nd, ':inst:mast ""');
                    xfprintf(fsync2nd, ':inst:slave:del:all');
                    xfprintf(fsync2nd, sprintf(':inst:mast "%s"', arbConfig.visaAddr2));
                    if (isfield(arbConfig, 'visaAddrS2a'))
                        xfprintf(fsync2nd, sprintf(':inst:slave:add "%s"', arbConfig.visaAddrS2a));
                    end
                    if (isfield(arbConfig, 'visaAddrS2b'))
                        xfprintf(fsync2nd, sprintf(':inst:slave:add "%s"', arbConfig.visaAddrS2b));
                    end
                    if (isfield(arbConfig, 'visaAddrS2c'))
                        xfprintf(fsync2nd, sprintf(':inst:slave:add "%s"', arbConfig.visaAddrS2c));
                    end
                    xfprintf(fsync2nd, ':inst:mmod:conf 0');
                    % for triggered mode, switch the Trace Advance back to AUTO
                    if (isfield(arbConfig, 'triggerMode') && strcmp(arbConfig.triggerMode, 'Triggered'))
                        for i = find(channelMapping(:,1) + channelMapping(:,2))'
                            xfprintf(f, sprintf(':trace%d:adv auto', i));
                        end
                        arb2 = loadArbConfig();
                        arb2.visaAddr = arb2.visaAddr2;
                        f2 = iqopen(arb2);
                        for i = find(channelMapping(:,1) + channelMapping(:,2))'
                            xfprintf(f2, sprintf(':trace%d:adv auto', i));
                        end
                        fclose(f2);
                    end
                    xfprintf(fsync2nd, ':init:imm');
                    query(fsync2nd, '*opc?');
                    fclose(fsync2nd);

                    % Group 1
                    arbSync.visaAddr = arbSync.visaAddrM8192A;
                    fsync = iqopen(arbSync);
                    xfprintf(fsync, ':ABOR');
                    xfprintf(fsync, ':inst:mmod:conf 1');
                    xfprintf(fsync, ':inst:mast ""');
                    xfprintf(fsync, ':inst:slave:del:all');
                    xfprintf(fsync, sprintf(':inst:mast "%s"', arbConfig.visaAddr));
                    if (isfield(arbConfig, 'visaAddrS1a'))
                        xfprintf(fsync, sprintf(':inst:slave:add "%s"', arbConfig.visaAddrS1a));
                    end
                    if (isfield(arbConfig, 'visaAddrS1b'))
                        xfprintf(fsync, sprintf(':inst:slave:add "%s"', arbConfig.visaAddrS1b));
                    end
                    if (isfield(arbConfig, 'visaAddrS1c'))
                        xfprintf(fsync, sprintf(':inst:slave:add "%s"', arbConfig.visaAddrS1c));
                    end
                    xfprintf(fsync, ':inst:mmod:conf 0');
                    % for triggered mode, switch the Trace Advance back to AUTO
                    if (isfield(arbConfig, 'triggerMode') && strcmp(arbConfig.triggerMode, 'Triggered'))
                        for i = find(channelMapping(:,1) + channelMapping(:,2))'
                            xfprintf(f, sprintf(':trace%d:adv auto', i));
                        end
                        arb2 = loadArbConfig();
                        arb2.visaAddr = arb2.visaAddr2;
                        f2 = iqopen(arb2);
                        for i = find(channelMapping(:,1) + channelMapping(:,2))'
                            xfprintf(f2, sprintf(':trace%d:adv auto', i));
                        end
                        fclose(f2);
                    end
                    xfprintf(fsync, ':init:imm');
                    xfprintf(fsync, ':trig:beg');
                    query(fsync, '*opc?');
                    fclose(fsync);
                    
                catch ex
                    msgbox(ex.message);
                end
            end
        end
    else
        % turn on channel coupling only if download to both channels
        % otherwise keep the previous setting. If the user wants de-coupled
        % channels, he has to do that in the SFP or outside this script
        if (length(find(channelMapping(:,1) + channelMapping(:,2))) > 1)
            xfprintf(f, ':INSTrument:COUPle:STATe ON');
        end
        if (run == 1)
            % setting ARB mode is now done in gen_arb function
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':INIT:IMMediate%d', i));
            end
        end
    end
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end;

    
function gen_arb_M8190A(arbConfig, f, chan, data, marker, segm_num, run)
% download an arbitrary waveform signal to a given channel and segment
    if (isempty(chan) || ~chan)
        return;
    end
    segm_len = length(data);
    if (segm_len > 0)
        % Try to delete the segment, but ignore errors if it does not exist
        % Another approach would be to first find out if it exists and only
        % then delete it, but that takes much longer
        if (run >= 0)
            xfprintf(f, sprintf(':TRACe%d:DELete %d', chan, segm_num), 1);
            xfprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segm_num, segm_len));
        end
        % scale to DAC values - data is assumed to be -1 ... +1
        data = int16(round(8191 * data) * 4);
        if (~isempty(marker))
            if (length(marker) ~= length(data))
                errordlg('length of marker vector and data vector must be the same');
            else
                data = data + int16(bitand(uint16(marker), 3));
            end
        end
        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end
        % Download the arbitrary waveform. 
        % Split large waveform segments in reasonable chunks
        use_binblockwrite = 1;
        offset = 0;
        while (offset < segm_len)
            if (use_binblockwrite)
                len = min(segm_len - offset, 523200);
                cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset);
                binblockwrite(f, data(1+offset:offset+len), 'int16', cmd);
                xfprintf(f, '');
            else
                len = min(segm_len - offset, 4800);
                cmd = sprintf(':TRACe%d:DATA %d,%d', chan, segm_num, offset);
                cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                xfprintf(f, cmd);
            end
            offset = offset + len;
        end
        query(f, '*opc?\n');
        if (run >= 0)
            xfprintf(f, sprintf(':TRACe%d:SELect %d', chan, segm_num));
        end
    end
    if (isfield(arbConfig, 'ampType'))
        xfprintf(f, sprintf(':OUTPut%d:ROUTe %s', chan, arbConfig.ampType));
    end
    if (isfield(arbConfig,'amplitude'))
        xfprintf(f, sprintf(':VOLTage%d:AMPLitude %g', chan, arbConfig.amplitude(chan)));    
    end
    if (isfield(arbConfig,'offset'))
        xfprintf(f, sprintf(':VOLTage%d:OFFSet %g', chan, arbConfig.offset(chan)));    
    end
    if (run >= 0) % when running in ping pong mode, don't set mode
        xfprintf(f, sprintf(':FUNCtion%d:MODE ARBitrary', chan));
    end
    xfprintf(f, sprintf(':OUTPut%d ON', chan));


function gen_arb_IQ_M8190A(arbConfig, f, chan, data, marker, segm_num)
% download an IQ waveform to a given channel and segment number.
% Set the sampling rate to fs
    if (isempty(chan) || ~chan)
        return;
    end
    segm_len = length(data);
    if (segm_len > 0)
        % Try to delete the segment, but ignore errors if it does not exist
        % Another approach would be to first find out if it exists and only
        % then delete it, but that takes much longer
        xfprintf(f, sprintf(':TRACe%d:DELete %d', chan, segm_num), 1);
        xfprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segm_num, segm_len));
        % split into I & Q
        dacData(1,:) = real(data);
        dacData(2,:) = imag(data);
        % scale to DAC values - data is assumed to be -1 ... +1
        dacData = int16(round(16383 * dacData) * 2);
        % insert marker data
        if (~isempty(marker))
            if (length(marker) ~= segm_len)
                errordlg('length of marker vector and data vector must be the same');
            else
                dacData(1,:) = dacData(1,:) + int16(bitget(uint16(marker'), 1));  % sample marker
                dacData(2,:) = dacData(2,:) + int16(bitget(uint16(marker'), 2));  % sync marker
            end
        end
        % merge I & Q into a vector
        data = dacData(:);        
        segm_len = length(data);
        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end
        % Download the arbitrary waveform. 
        % Split large waveform segments in reasonable chunks
        use_binblockwrite = 1;
        offset = 0;
        while (offset < segm_len)
            if (use_binblockwrite)
                len = min(segm_len - offset, 523200);
                cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset/2);
                binblockwrite(f, data(1+offset:offset+len), 'int16', cmd);
                xfprintf(f, '');
            else
                len = min(segm_len - offset, 4800);
                cmd = sprintf(':TRACe%d:DATA %d,%d', chan, segm_num, offset/2);
                cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                xfprintf(f, cmd);
            end
            offset = offset + len;
        end
        query(f, '*OPC?\n');
        xfprintf(f, sprintf(':TRACe%d:SELect %d', chan, segm_num));
    end
    if (isfield(arbConfig,'carrierFrequency'))
        xfprintf(f, sprintf(':CARRier%d:FREQuency %.0f,%g', ...
            chan, floor(arbConfig.carrierFrequency), arbConfig.carrierFrequency - floor(arbConfig.carrierFrequency)));
    end
    if (isfield(arbConfig, 'ampType'))
        xfprintf(f, sprintf(':OUTPut%d:ROUte %s', chan, arbConfig.ampType));
    end
    if (isfield(arbConfig,'amplitude'))
        xfprintf(f, sprintf(':VOLTage%d:AMPLitude %g', chan, arbConfig.amplitude(chan)));    
    end
    if (isfield(arbConfig,'offset'))
        xfprintf(f, sprintf(':VOLTage%d:OFFSet %g', chan, arbConfig.offset(chan)));    
    end
    xfprintf(f, sprintf(':FUNCtion%d:MODE ARBitrary', chan));
    xfprintf(f, sprintf(':OUTPut%d ON', chan));


function result = setupSequence(f, arbConfig, seqcmd, channelMapping, run, useM8192A, keepOpen)
% Perform sequencer-related functions. The format of "seqcmd" is described
% in iqseq.m
% check what to do: seqcmd.cmd contains the function to perform and
% seqcmd.sequence contains the parameter(s)
    result = [];
    switch (seqcmd.cmd)
        case 'list'
            s = sscanf(query(f, sprintf(':TRACe%d:CATalog?', find(channelMapping(:,1) + channelMapping(:,2), 1))), '%d,');
            s = reshape(s,2,length(s)/2);
            if (s(1,1) == 0)
                errordlg({'There are no segments defined.' ...
                    'Please load segments before calling this function and make sure' ...
                    'that the "send *RST" checkbox in the config window is un-checked'} );
            else
                errordlg(sprintf('The following segments are defined:%s', ...
                    sprintf(' %d', s(1,:))));
                result = s(1,:);
            end
        case 'delete'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                xfprintf(f, sprintf(':TRACe%d:DELete:ALL', i));
                xfprintf(f, sprintf(':STABle%d:RESET', i));
            end
        case 'event'
            xfprintf(f, ':TRIGger:ADVance:IMMediate');
        case 'trigger'
            xfprintf(f, ':TRIGger:BEGin:IMMediate');
        case 'define'
            defineSequence(f, seqcmd, channelMapping, run);
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':STAB%d:SCEN:ADV CONDitional', i));
            end
            doRun(f, arbConfig, useM8192A, channelMapping, run, keepOpen);
        case 'amplitudeTable'
            list = seqcmd.sequence;
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                binary = 0;
                if (binary)
                    list = 32767 * int32(list);
                    binblockwrite(f, list, 'int32', sprintf(':ATABle%d:DATA 0,', i));
                    xfprintf(f, '');
                else
                    cmd = sprintf(',%g', list);
                    xfprintf(f, sprintf(':ATABle%d:DATA 0%s', i, cmd));
                end
            end
        case 'frequencyTable'
            list = seqcmd.sequence;
            % convert frequencies into integral & fractional part
            list2 = zeros(1, 2*length(list));
            for i=1:length(list)
                list2(2*i-1) = floor(list(i));
                list2(2*i) = list(i) - floor(list(i));
            end
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                binary = 0;
                if (binary)
                    binblockwrite(f, list2, 'float32', sprintf(':FTABle%d:DATA 0,', i));
                    xfprintf(f, '');
                else
                    cmd = sprintf(',%.15g', list2);
                    xfprintf(f, sprintf(':FTABle%d:DATA 0%s', i, cmd));
                end
            end
        case 'actionDefine'
            list = seqcmd.sequence;
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                result = str2double(query(f, sprintf(':ACTion%d:DEFine:NEW?', i)));
            end
            seqcmd.cmd = 'actionAppend';
            seqcmd.sequence = [ result list ];
            setupSequence(f, arbConfig, seqcmd, channelMapping, run, useM8192A, keepOpen);
        case 'actionAppend'
            list = seqcmd.sequence;
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                for j = 2:2:length(list)
                    if (isempty(list{j+1}))   % no parameter e.g.      SRUN
                        xfprintf(f, sprintf(':ACTion%d:APPend %d,%s', ...
                            i, list{1}, list{j}));
                    elseif (isscalar(list{j+1}))    % single parameter e.g.   PBUMp, 0.4
                        if (strncmpi(list{j}, 'CFR', 3) || strncmpi(list{j}, 'SRAT', 4))
                            % for CFrequency and SRate, use the integral/fractional split
                            xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g,%.15g', ...
                                i, list{1}, list{j}, floor(list{j+1}), list{j+1}-floor(list{j+1})));
                        elseif (strncmpi(list{j}, 'PBUM', 4) || strncmpi(list{j}, 'POFF', 4))
                            % convert from degrees into -0.5 to +0.5
                            val = list{j+1} / 360;
                            val = val - floor(val);
                            if (val > 0.5)
                                val = val - 1;
                            end
                            xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g', ...
                                i, list{1}, list{j}, val ));
                        elseif (strncmpi(list{j}, 'PRES', 4))
                            % convert from degrees into 0...1
                            val = list{j+1} / 360;
                            val = val - floor(val);
                            xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g', ...
                                i, list{1}, list{j}, val ));
                        else
                            xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g', ...
                                i, list{1}, list{j}, list{j+1}));
                        end
                    else    % dual parameter e.g.   CFRequency, 100e6, 0.5
                        xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g,%.15g', ...
                            i, list{1}, list{j}, list{j+1}));
                    end
                end
            end
        case 'actionDelete'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                xfprintf(f, sprintf(':ACTion%d:DELete %d', i, seqcmd.sequence));
            end
        case 'actionDeleteAll'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                xfprintf(f, sprintf(':ACTion%d:DELete:ALL', i));
            end
        case 'dynamic'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                xfprintf(f, sprintf(':STABle%d:DYNamic %d', i, seqcmd.sequence));
            end
        case 'mode'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                xfprintf(f, sprintf(':FUNCtion%d:MODE %s', i, seqcmd.sequence));
                xfprintf(f, sprintf(':STAB%d:SCEN:ADV CONDitional', i));
            end
            doRun(f, arbConfig, useM8192A, channelMapping, run, keepOpen);
        case 'trigAdvance'
            xfprintf(f, sprintf(':TRIGger:SOURce:ADVance %s', seqcmd.sequence));
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':TRIGger:ADVance%d:HWDisable OFF', i));
            end
        case 'triggerMode'
            switch seqcmd.sequence
                case {1 'triggered'}
                    s = '0';
                case {0 'continuous'}
                    s = '1';
                otherwise
                    error('unknown triggerMode');
            end
%            xfprintf(f, sprintf(':ARM:TRIG:SOUR EXT'));
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':INIT:CONTinuous%d %s', i, s));
                xfprintf(f, sprintf(':INIT:GATE%d %s', i, s));
            end
        case 'stop'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
            end
        case 'readSequence'
            result = readSequence(f, seqcmd, channelMapping);
        otherwise
            errordlg(['undefined sequence command: ' seqcmd.cmd]);
    end

    
function defineSequence(f, seqcmd, channelMapping, run)
% define a new sequence table
    xfprintf(f, ':ABORt');
    seqtable = seqcmd.sequence;
% check if only valid fieldnames are used (typo?)
    fields = fieldnames(seqtable);
    fields(find(strcmp(fields, 'segmentNumber'))) = [];
    fields(find(strcmp(fields, 'segmentLoops'))) = [];
    fields(find(strcmp(fields, 'segmentAdvance'))) = [];
    fields(find(strcmp(fields, 'sequenceAdvance'))) = [];
    fields(find(strcmp(fields, 'sequenceLoops'))) = [];
    fields(find(strcmp(fields, 'markerEnable'))) = [];
    fields(find(strcmp(fields, 'sequenceInit'))) = [];
    fields(find(strcmp(fields, 'sequenceEnd'))) = [];
    fields(find(strcmp(fields, 'scenarioEnd'))) = [];
    fields(find(strcmp(fields, 'amplitudeInit'))) = [];
    fields(find(strcmp(fields, 'amplitudeNext'))) = [];
    fields(find(strcmp(fields, 'frequencyInit'))) = [];
    fields(find(strcmp(fields, 'frequencyNext'))) = [];
    fields(find(strcmp(fields, 'actionID'))) = [];
    if (~isempty(fields))
        disp('The following field names are unknown:');
        disp(fields);
        error('unknown field names');
    end
% check if all the segments are defined
    if (~isempty(find(channelMapping(:,1) + channelMapping(:,2), 1)))
        s = sscanf(query(f, sprintf(':trac%d:cat?', find(channelMapping(:,1) + channelMapping(:,2), 1))), '%d,');
        s = reshape(s,2,length(s)/2);
        notDef = [];
        for i = 1:length(seqtable)
            if (isempty(find(s(1,:) == seqtable(i).segmentNumber, 1)))
                notDef = [notDef seqtable(i).segmentNumber];
            end
        end
        notDef = notDef(notDef > 0);    % ignore zero and negative numbers, they are special commands
        if (~isempty(notDef))
            errordlg({ sprintf('The following segments are used in the sequence but not defined:%s.', ...
                sprintf(' %d', notDef)) ...
                'Please load segments before calling this function and make sure' ...
                'that the "send *RST" checkbox in the config window is un-checked'} );
            return;
        end
    end
% download the sequence table
    seqData = uint32(zeros(6 * length(seqtable), 1));
    for i = 1:length(seqtable)
            seqTabEntry = calculateSeqTableEntry(seqtable(i), i, length(seqtable));
            seqData(6*i-5:6*i) = seqTabEntry;
            % if the variable 'debugSeq' exists in the base workspace,
            % print out the sequence table as hex numbers
            if (evalin('base', 'exist(''debugSeq'', ''var'')'))
                fprintf('Seq Write %03d: ', i);
                fprintf('%08X ', seqTabEntry);
                fprintf('\n');
            end
    end
    % swap MSB and LSB bytes in case of TCP/IP connection
    if (strcmp(f.type, 'tcpip'))
        seqData = swapbytes(seqData);
    end
    for i = find(channelMapping(:,1) + channelMapping(:,2))'
        binblockwrite(f, seqData, 'uint32', sprintf(':STABle%d:DATA 0,', i));
        xfprintf(f, '');
%            cmd = sprintf(',%.0f', seqData);
%            xfprintf(f, sprintf(':STABle%d:DATA 0%s', i, cmd));
        xfprintf(f, sprintf(':STABle%d:SEQuence:SELect %d', i, 0));
        xfprintf(f, sprintf(':STABle%d:DYNamic:STATe 0', i));
        xfprintf(f, sprintf(':FUNCtion%d:MODE STSequence', i));
    end


function seqTabEntry = calculateSeqTableEntry(seqline, currLine, numLines)
% calculate the six 32-bit words that make up one sequence table entry.
% For details on the format, see user guide section 4.20.6
%
% The content of the six 32-bit words depends on the type of entry:
% Data Entry: Control / Seq.Loops / Segm.Loops / Segm.ID / Start Offset / End Offset
% Idle Cmd:   Control / Seq.Loops / Cmd Code(0) / Idle Sample / Delay / Unused
% Action:     Control / Seq.Loops / Cmd Code(1) + Act.ID / Segm.ID / Start Offset / End Offset
    cbitCmd = 32;
    cbitEndSequence = 31;
    cbitEndScenario = 30;
    cbitInitSequence = 29;
    cbitMarkerEnable = 25;
    cbitAmplitudeInit = 16;
    cbitAmplitudeNext = 15;
    cbitFrequencyInit = 14;
    cbitFrequencyNext = 13;
    cmaskSegmentAuto = hex2dec('00000000');
    cmaskSegmentCond = hex2dec('00010000');
    cmaskSegmentRept = hex2dec('00020000');
    cmaskSegmentStep = hex2dec('00030000');
    cmaskSequenceAuto = hex2dec('00000000');
    cmaskSequenceCond = hex2dec('00100000');
    cmaskSequenceRept = hex2dec('00200000');
    cmaskSequenceStep = hex2dec('00300000');
    seqLoopCnt = 1;

    ctrl = uint32(0);
    seqTabEntry = uint32(zeros(6, 1));        % initialize the return value
    if (seqline.segmentNumber == 0)           % segment# = 0 means: idle command
        ctrl = bitset(ctrl, cbitCmd);         % set the command bit
        seqTabEntry(3) = 0;                   % Idle command code = 0
        seqTabEntry(4) = 0;                   % Sample value
        if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops))
            seqTabEntry(5) = seqline.segmentLoops;  % use segment loops as delay
        else
            seqTabEntry(5) = 1;
        end
        seqTabEntry(6) = 0;                   % unused
    else
        if (isfield(seqline, 'actionID')&& ~isempty(seqline.actionID) && seqline.actionID >= 0)
            % if it is an actionID, set the command bit and action Cmd Code
            % and store actionID in 24 MSB of word#3.
            % The segment will not be repeated. segmentLoops is ignored
            ctrl = bitset(ctrl, cbitCmd);
            seqTabEntry(3) = 1 + bitshift(uint32(seqline.actionID), 16);
            if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops) && seqline.segmentLoops > 1)
                errordlg(['segmentLoops will be ignored when an actionID is specified (Seq.ID ' num2str(currLine-1) ')']);
            end
        else
            % normal data entries have the segment loop count in word#3
            if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops))
                seqTabEntry(3) = seqline.segmentLoops;
            else
                seqTabEntry(3) = 1;
            end
        end
        seqTabEntry(4) = seqline.segmentNumber;
        seqTabEntry(5) = 0;                   % start pointer
        seqTabEntry(6) = hex2dec('ffffffff'); % end pointer
        if (isfield(seqline, 'segmentAdvance') && ~isempty(seqline.segmentAdvance))
            switch (seqline.segmentAdvance)
                case 'Auto';        ctrl = bitor(ctrl, cmaskSegmentAuto);
                case 'Conditional'; ctrl = bitor(ctrl, cmaskSegmentCond);
                case 'Repeat';      ctrl = bitor(ctrl, cmaskSegmentRept);
                case 'Stepped';     ctrl = bitor(ctrl, cmaskSegmentStep);
                otherwise;          error(sprintf('unknown segment advance mode: %s', seqline.segmentAdvance));
            end
        end
        if (isfield(seqline, 'markerEnable') && ~isempty(seqline.markerEnable) && seqline.markerEnable)
            ctrl = bitset(ctrl, cbitMarkerEnable);
        end
    end
    % set the amplitude and frequency table flags
    if (isfield(seqline, 'amplitudeInit') && ~isempty(seqline.amplitudeInit) && seqline.amplitudeInit)
        ctrl = bitset(ctrl, cbitAmplitudeInit);
    end
    if (isfield(seqline, 'amplitudeNext') && ~isempty(seqline.amplitudeNext) && seqline.amplitudeNext)
        ctrl = bitset(ctrl, cbitAmplitudeNext);
    end
    if (isfield(seqline, 'frequencyInit') && ~isempty(seqline.frequencyInit) && seqline.frequencyInit)
        ctrl = bitset(ctrl, cbitFrequencyInit);
    end
    if (isfield(seqline, 'frequencyNext') && ~isempty(seqline.frequencyNext) && seqline.frequencyNext)
        ctrl = bitset(ctrl, cbitFrequencyNext);
    end
    % if the sequence fields exist, then set the sequence control bits
    % according to those fields
    if (isfield(seqline, 'sequenceInit'))
        if (seqline.sequenceInit)  % init sequence flag
            ctrl = bitset(ctrl, cbitInitSequence);
        end
        if (isfield(seqline, 'sequenceEnd')&& ~isempty(seqline.sequenceEnd) && seqline.sequenceEnd)
            ctrl = bitset(ctrl, cbitEndSequence);
        end
        if (isfield(seqline, 'sequenceLoops') && ~isempty(seqline.sequenceLoops))
            seqLoopCnt = seqline.sequenceLoops;
        end
        if (isfield(seqline, 'sequenceAdvance') && ~isempty(seqline.sequenceAdvance))
            switch (seqline.sequenceAdvance)  % sequence advance mode
                case 'Auto';        ctrl = bitor(ctrl, cmaskSequenceAuto);
                case 'Conditional'; ctrl = bitor(ctrl, cmaskSequenceCond);
                case 'Repeat';      ctrl = bitor(ctrl, cmaskSequenceRept);
                case 'Stepped';     ctrl = bitor(ctrl, cmaskSequenceStep);
                otherwise;          error(sprintf('unknown sequence advance mode: %s', seqline.sequenceAdvance));
            end
        end
        if (isfield(seqline, 'scenarioEnd') && ~isempty(seqline.scenarioEnd) && seqline.scenarioEnd)
            ctrl = bitset(ctrl, cbitEndScenario);
        end
    else
        % otherwise assume a single sequence and set start and
        % end of sequence flags automatically
        if (currLine == 1)
            ctrl = bitset(ctrl, cbitInitSequence);
        end
        if (currLine == numLines)
            ctrl = bitset(ctrl, cbitEndSequence);
            ctrl = bitset(ctrl, cbitEndScenario);
        end
    end
    seqTabEntry(1) = ctrl;                % control word
    seqTabEntry(2) = seqLoopCnt;          % sequence loops


function result = readSequence(f, seqcmd, channelMapping)
    clear seq;
    ch = 1;
    if (channelMapping(1,1) == 0)
        ch = 2;
    end
    start = 0;
    len = 100;  % maximum number of entries to read
    stab = query(f, sprintf(':STAB%d:DATA? %d,%d', ch, start, 6*len));
    stab = eval(sprintf('[%s]', stab));
    stab(stab < 0) = stab(stab < 0) + 2^32;
    stab = uint32(stab);
    for i = 1:length(stab)/6;
        if (evalin('base', 'exist(''debugSeq'', ''var'')'))
            fprintf('Seq Read  %03d: ', i-1);
            fprintf('%08X ', stab(6*(i-1)+1:6*(i-1)+6));
            fprintf('\n');
        end
        seq(i) = readSeqEntry(stab(6*(i-1)+1:6*(i-1)+6));
        seq(i).idx = i-1;
        if (seq(i).scenarioEnd ~= 0)
            break;
        end
    end
    result = seq;


function result = readSeqEntry(seqline)
% convert six 32-bit words into a table entry
% For details on the format, see user guide section 4.20.6
%
% The content of the six 32-bit words depends on the type of entry:
% Data Entry: Control / Seq.Loops / Segm.Loops / Segm.ID / Start Offset / End Offset
% Idle Cmd:   Control / Seq.Loops / Cmd Code(0) / Idle Sample / Delay / Unused
% Action:     Control / Seq.Loops / Cmd Code(1) + Act.ID / Segm.ID / Start Offset / End Offset

% initialize result struct.  Order is important!!
    result.idx = [];
    result.segmentNumber = [];
    result.segmentLoops = [];
    result.segmentAdvance = [];
    result.markerEnable = [];
    result.sequenceInit = [];
    result.sequenceLoops = [];
    result.sequenceAdvance = [];
    result.actionStr = [];
    result.amplCmd = [];
    result.freqCmd = [];
    %
    result.amplitudeInit = [];
    result.amplitudeNext = [];
    result.frequencyInit = [];
    result.frequencyNext = [];
    result.sequenceEnd = [];
    result.scenarioEnd = [];
    result.actionID = -1;

    cbitCmd = 32;
    cbitEndSequence = 31;
    cbitEndScenario = 30;
    cbitInitSequence = 29;
    cbitMarkerEnable = 25;
    cbitAmplitudeInit = 16;
    cbitAmplitudeNext = 15;
    cbitFrequencyInit = 14;
    cbitFrequencyNext = 13;
    cmaskSegmentAuto = hex2dec('00000000');
    cmaskSegmentCond = hex2dec('00010000');
    cmaskSegmentRept = hex2dec('00020000');
    cmaskSegmentStep = hex2dec('00030000');
    cmaskSequenceAuto = hex2dec('00000000');
    cmaskSequenceCond = hex2dec('00100000');
    cmaskSequenceRept = hex2dec('00200000');
    cmaskSequenceStep = hex2dec('00300000');
    seqLoopCnt = 1;

    ctrl = seqline(1);
    if (bitand(ctrl, bitshift(1,cbitCmd-1)))
        if (seqline(3) == 0)    % idle
            result.segmentNumber = 0;
            result.segmentLoops = seqline(5);
        else
            result.actionID = bitshift(seqline(3), -16);
            result.segmentNumber = seqline(4);
        end
    else
        result.segmentLoops = seqline(3);
        result.segmentNumber = seqline(4);
    end
    switch bitand(ctrl, cmaskSegmentStep)
        case cmaskSegmentAuto; result.segmentAdvance = 'Auto';
        case cmaskSegmentCond; result.segmentAdvance = 'Conditional';
        case cmaskSegmentRept; result.segmentAdvance = 'Repeat';
        case cmaskSegmentStep; result.segmentAdvance = 'Stepped';
        otherwise
            error('unexpected segment advance');
    end
    result.markerEnable = bitand(ctrl, bitshift(1, cbitMarkerEnable-1)) ~= 0;
    result.amplitudeInit = bitand(ctrl, bitshift(1, cbitAmplitudeInit-1)) ~= 0;
    result.amplitudeNext = bitand(ctrl, bitshift(1, cbitAmplitudeNext-1)) ~= 0;
    result.frequencyInit = bitand(ctrl, bitshift(1, cbitFrequencyInit-1)) ~= 0;
    result.frequencyNext = bitand(ctrl, bitshift(1, cbitFrequencyNext-1)) ~= 0;
    if (result.amplitudeInit)
        result.amplCmd = 'init';
    elseif (result.amplitudeNext)
        result.amplCmd = 'next';
    else
        result.amplCmd = 'none';
    end
    if (result.frequencyInit)
        result.freqCmd = 'init';
    elseif (result.frequencyNext)
        result.freqCmd = 'next';
    else
        result.freqCmd = 'none';
    end
    
    result.sequenceInit = bitand(ctrl, bitshift(1, cbitInitSequence-1)) ~= 0;
    result.sequenceEnd  = bitand(ctrl, bitshift(1, cbitEndSequence-1)) ~= 0;
    result.scenarioEnd  = bitand(ctrl, bitshift(1, cbitEndScenario-1)) ~= 0;
    result.sequenceLoops = seqline(2);
    switch bitand(ctrl, cmaskSequenceStep)
        case cmaskSequenceAuto; result.sequenceAdvance = 'Auto';
        case cmaskSequenceCond; result.sequenceAdvance = 'Conditional';
        case cmaskSequenceRept; result.sequenceAdvance = 'Repeat';
        case cmaskSequenceStep; result.sequenceAdvance = 'Stepped';
        otherwise
            error('unexpected sequence advance');
    end
    
    
 function result = iqseq_multi(cmd, sequence, varargin)
% define and run a sequence or execute sequence-related commands
% 
% 'cmd' must contain one of the following command strings:
%       'list' - shows a list of all defined segments (also returns a
%                vector with the defined segments)
%       'delete' - delete the sequence table
%       'event' - force an event signal
%       'trigger' - force a trigger signal
%       'select' - select the segment in sequence
%       'define' - define a sequence in sequence
% For the M8190A only, the following additional commands are available:
%       'amplitudeTable' - define the amplitude table
%       'frequencyTable' - define the frequency table
%       'actionDefine' - define a new action, returns the action ID
%       'actionAppend' - append a new action to a previously defined
%       'actionDelete' - delete the action in seqcmd.sequence
%       'actionDeleteAll' - delete all actions
%
% if cmd equals 'define', then
% sequence must contain a vector of structs with the following elements.
%     sequence(i).segmentNumber
%     sequence(i).segmentLoop    (Optional. Default = 1)
%     sequence(i).advanceMode    (Optional. Default = 'auto')
%     sequence(i).markerEnable   (Optional. Default = false)
% where:
% <segmentNumber> is the segment number (starting with 1)
% <segmentLoop> indicates how often the segment will be repeated (1 to 2^32)
% <advanceMode> is one of 'Auto', 'Conditional', 'Repeat', 'Stepped'
% <markerEnable> is true or false and indicated is the marker that is
%        defined in this segment will be generated on the output or not
%
% For the M8190A *ONLY*:
% The sequence struct can optionally contain 5 more elements:
%  sequence(i).sequenceInit        (0 or 1, 1=start of sequence, default: 0)
%  sequence(i).sequenceEnd         (0 or 1, 1=end of sequence, default: 0)
%  sequence(i).sequenceLoop        (1 to 2^32: sequence repeat count, default: 1)
%  sequence(i).sequenceAdvanceMode (same possible values as segmentAdvanceMode, default: 'auto')
%  sequence(i).scenarioEnd         (0 or 1, 1=end of scenario, default: 0)
%  sequence(i).amplitudeInit       (0 or 1, 1=initialize amplitude pointer. Default = 0)
%  sequence(i).amplitudeNext       (0 or 1, 1=use next amplitude value. Default = 0)
%  sequence(i).frequencyInit       (0 or 1, 1=initialize frequency pointer. Default = 0)
%  sequence(i).frequencyNext       (0 or 1, 1=use next frequency value. Default = 0)
%  sequence(i).actionID            (0 to 2^24-1, -1 = unused. Default: -1)
%
% For the M8190A *only*:
% <segmentNumber> can be zero to indicate an "idle" command. In that case,
% <segmentLoop> indicates the number of samples to pause
%
% For the M8190A *only*:
% if cmd equals 'actionDefine', then
% sequence must contain a cell array with alternating strings and values.
% The string represents the type of action and value is a vector of
% associated parameter(s). Valid action strings are:
% Action            Action String  Parameters
% Carrier Frequency CFRequency	   [ integral part of frequency in Hz, fractional part of frequency in Hz ]
% Phase Offset      POFFset        [ phase in parts of full cycle (-0.5 ... +0.5)]
% Phase Reset       PRESet         [ phase in parts of full cycle (-0.5 ... +0.5)]
% Phase Bump        PBUMp          [ phase in parts of full cycle (-0.5 ... +0.5)]
% Sweep Rate        SRATe          [ Sweep Rate integral part in Hz/us, sweep rate fractional part in Hz/us ]
% Sweep Run         SRUN           []
% Sweep Hold        SHOLd          []
% Sweep Restart     SREStart       []
% Amplitude         AMPLitude      [ Amplitude in the range 0...1 ]
% the call will return an "actionID", which can be used in a sequence entry
%
% For an example usage, see the source code of M8190A-specific examples:
% (seqtest1.m, seqtest3.m, etc.)
%
seqcmd.cmd = cmd;
seqcmd.sequence = sequence;
result = iqdownload_multi([], 0, 'sequence', seqcmd, varargin{:});

