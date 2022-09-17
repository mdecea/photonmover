function enobs = iqenob(varargin)
% calculate ENOB based on DCA or SA measurement
%
% Parameters are passed as property/value pairs. Properties are:
% 'analyzer' - can be 'DCA' or 'SA'
% 'sim' - 0=use real hardware, 1=read from file, 2=offline simulation
% 'scopeavg' - number of averages during scope acquisition
% 'analysisavg' - number of repeated measurements that are averaged
% 'tones' - vector of frequencies at which the measurement will be performed
% 'bandwidth' - frequency up to which noise&distortions are considered
% 'awgchannels' - vector of AWG channels for which calibration is performed.
%    The last element specifies the trigger channel
% 'scopechannels' - cell array of scope channel represented as strings
%    The last element specifes the trigger channel
% 'amplitude' - amplitude of the signal used for setting up the scope.
% 'hmsgbox' - handle to a message to display status messages
% 'axes' - cell array of two axes handles to display the graphs
% 'scoperst' - if set to 1, a *RST command is sent to the scope
% 'awgrst' - if set to 1, a *RST command is sent to the AWG
% 'autoscopeampl' - if set to 1, scope amplitude will be determined automatically
% 'oldvalues' - vector of structs with previous measurements (fields: freqs, enobs, legend)
% 'debuglevel' - 0=no debug output, value between 1 and 3 - more debug output
%
% If called without arguments, opens a graphical user interface to specify
% parameters

% T.Dippon, Keysight Technologies 2015
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS.

global debugLevel;
global gScopeAmpl;
if (nargin == 0)
    iqenob_gui();
    return;
end
gScopeAmpl = [];
enobs = [];
sim = 0;
axesHandles = [];
analyzer = 'IEEE';
% averaging on capture
scopeAvg = 4;
% scopeAmpl of the signal
scopeAmpl = 800e-3;
% number of averages during analysis
analysisAvg = 1;
% AWG channels [DUT trigger]
awgChannels = [1 4];
% measured channels (NOTE:  cell array of strings!!!)
scopeChannels = {'1' '4'};
% handle to msgbox for status updates
hMsgBox = [];
% reset the scope
scopeRST = 1;
% reset the AWG
awgRST = 1;
% AWG sample rate
[arbConfig, saConfig] = loadArbConfig();
if (isempty(arbConfig))
    return;
end
% AWG sample rate
fsAWG = arbConfig.defaultSampleRate;
% tones
tones = (1:10)/10 * fsAWG / 3;
% max noise
bandwidth = fsAWG / 2;
% automatic amplitude detection on the scope
autoScopeAmpl = 1;
% number of periods captured
nPer = 300;
% legend for plot
lgText = 'Meas #1';
% previous measurements
oldResults = [];
% set debugLevel
debugLevel = 0;
%
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'analyzer';       analyzer = varargin{i+1};
            case 'sim';            sim = varargin{i+1};
            case 'scopeavg';       scopeAvg = varargin{i+1};
            case 'analysisavg';    analysisAvg = varargin{i+1};
            case 'tones';          tones = varargin{i+1};
            case 'bandwidth';      bandwidth = varargin{i+1};
            case 'nper';           nPer = varargin{i+1};
            case 'awgchannels';    awgChannels = varargin{i+1};
            case 'scopechannels';  scopeChannels = varargin{i+1};
            case 'amplitude';      scopeAmpl = varargin{i+1};
            case 'hmsgbox';        hMsgBox = varargin{i+1};
            case 'axes';           axesHandles = varargin{i+1};
            case 'scoperst';       scopeRST = varargin{i+1};
            case 'awgrst';         awgRST = varargin{i+1};
            case 'samplerate';     fsAWG = varargin{i+1};
            case 'autoscopeampl';  autoScopeAmpl = varargin{i+1};
            case 'oldresults';     oldResults = varargin{i+1};
            case 'lgtext';         lgText = varargin{i+1};
            case 'debuglevel';     debugLevel = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end
if (max(tones) > bandwidth)
    errordlg('Bandwidth must be set to a value greater than max. tone frequency');
    return;
end
scopeChannels = scopeChannels(1:end-1);
awgTrig = awgChannels(end);
%awgChannels(end) = [];

% if "debugLevel" is set in the workspace, it overwrites the local setting
if (evalin('base', 'exist(''debugLevel'', ''var'')'))
    debugLevel = evalin('base', 'debugLevel');
end

if (strcmpi(analyzer, 'dca_ieee'))
    enobs = iqenobieee(arbConfig.visaAddr, arbConfig.visaAddrDCA, tones, fsAWG, ...
        awgChannels, awgTrig, scopeChannels, scopeRST, autoScopeAmpl, scopeAmpl, ...
        scopeAvg, analysisAvg, bandwidth, hMsgBox, axesHandles, oldResults, lgText);
    return;
end

if (~isempty(hMsgBox))
    waitbar(0.01, hMsgBox, 'Trying to connect to AWG...');
end
f = iqopen();
if (isempty(f) || (~isempty(hMsgBox) && getappdata(hMsgBox, 'cancel')))
    return;
end
if (awgRST)
    fprintf(f, '*RST');
    query(f, '*OPC?');
end
if (awgTrig == 5)  % trigger using markers on M8190A & M8195A_1ch
    if (~isempty(strfind(arbConfig.model, 'M8190A')))
        trigAmpl = 500e-3;
        trigOffs = 0;
        fprintf(f, sprintf(':mark1:sample:volt:ampl %g; offs %g', trigAmpl, trigOffs));
        fprintf(f, sprintf(':mark2:sample:volt:ampl %g; offs %g', trigAmpl, trigOffs));
        fprintf(f, sprintf(':mark1:sync:volt:ampl %g; offs %g', trigAmpl, trigOffs));
        fprintf(f, sprintf(':mark2:sync:volt:ampl %g; offs %g', trigAmpl, trigOffs));
    elseif (~isempty(strfind(arbConfig.model, 'M8195A_1ch')))
        trigAmpl = 500e-3;
        trigOffs = 0;
        awgTrig = 4;
        fprintf(f, sprintf(':VOLT3:AMPL %g; offs %g', trigAmpl, trigOffs));
        fprintf(f, sprintf(':VOLT4:AMPL %g; offs %g', trigAmpl, trigOffs));
    else
        errordlg('Markers are only supported on M8190A and M8195A_1ch', 'Error', 'replace');
        return;
    end
end
fclose(f);
if (strcmp(analyzer, 'DCA'))
    if (~isempty(hMsgBox))
        waitbar(0.02, hMsgBox, 'Trying to connect to DCA...');
    end
    f = iqopen(arbConfig.visaAddrDCA);
    if (isempty(f) || (~isempty(hMsgBox) && getappdata(hMsgBox, 'cancel')))
        return;
    end
    try
        fprintf(f, '*CLS');
        query(f, ':SYST:ERR?');
    catch ex
        if (strfind(ex.message, 'locked resource'))
            errordlg('Remote access to scope is locked - Please use Control->Disconnect in VSA to unlock remote access to scope');
            return;
        else
            errordlg('Can''t access DCA. Please check the VISA address in the configuration window');
            instrreset();
            return;
        end
    end
    % reset the scope to make sure we have well-defined starting conditions
    if (scopeRST)
        fprintf(f, '*RST');
    end
    fclose(f);
elseif (strcmp(analyzer, 'SA'))
    if (~isempty(hMsgBox))
        waitbar(0.02, hMsgBox, 'Trying to connect to spectrum analyzer...');
    end
    f = iqopen(saConfig.visaAddr);
    if (isempty(f) || (~isempty(hMsgBox) && getappdata(hMsgBox, 'cancel')))
        return;
    end
    try
        fprintf(f, '*CLS');
        query(f, ':SYST:ERR?');
    catch ex
        errordlg('Can''t access Spectrum Analyzer. Please check the VISA address in the configuration window');
        instrreset();
        return;
    end
    % reset the scope to make sure we have well-defined starting conditions
    if (scopeRST)
        fprintf(f, '*RST');
    end
    fclose(f);
end

% if no axes are specified, create new windows
if (isempty(axesHandles))
    figure(51);
    axesHandles(1) = gca();
    figure(52);
    axesHandles(2) = gca();
end
numTones = length(tones);
enobs = NaN(numTones, 1);

% main loop over the tones
for i = 1:length(tones)
    toneFreq = tones(i);
    trigFreq = toneFreq;
    if (strcmp(analyzer, 'DCA'))
        while (trigFreq > 2.5e9)
            trigFreq = trigFreq / 2;
        end
    end
    trigWfm = iqtone('sampleRate', fsAWG, 'tone', trigFreq, 'nowarning', 1);
    toneWfm = iqtone('sampleRate', fsAWG, 'tone', toneFreq, 'numSamples', length(trigWfm), 'nowarning', 1);
    if (~isempty(hMsgBox))
        if (getappdata(hMsgBox, 'cancel'))
            break;
        end
        waitbar((2*i-1)/(2*numTones), hMsgBox, 'Downloading waveform to AWG...');
    end
    chMap = [1 0; 1 0; 1 0; 1 0];
    if (strcmp(analyzer, 'DCA'))
        chMap(awgTrig,:) = [0 1];
    end
    iqdownload(complex(real(toneWfm), real(trigWfm)), fsAWG, 'channelMapping', chMap);
    if (~isempty(hMsgBox))
        if (getappdata(hMsgBox, 'cancel'))
            break;
        end
        waitbar((2*i)/(2*numTones), hMsgBox, 'Reading data from analyzer...');
    end
    % nPer can be duration or number of periods on the screen
    if (nPer < 1)
        duration = nPer;
    else
        duration = nPer / toneFreq;
    end
    sumVal = 0;
    for k = 1:analysisAvg
        if (strcmp(analyzer, 'DCA'))
            val = getEnobScope(arbConfig, i, scopeChannels, duration, toneFreq, scopeAvg, autoScopeAmpl, scopeAmpl, bandwidth, axesHandles);
        else
            val = getEnobSA(saConfig, tones, i, bandwidth, axesHandles);
        end
        if (isnan(val))
            sumVal = NaN;
            break;
        end
        sumVal = sumVal + val;
    end
    if (isnan(sumVal))
        break;
    end
    enobs(i) = sumVal / k;
    cla(axesHandles(2), 'reset');
    hold(axesHandles(2), 'all');
    leg = {};
    if (~isempty(oldResults))
        for k = 1:length(oldResults)
            plot(axesHandles(2), oldResults(k).freqs/1e9, oldResults(k).enobs, '.-', 'linewidth', 2, 'Marker', 'd');
            leg{end+1} = oldResults(k).legend;
        end
    end
    plot(axesHandles(2), tones/1e9, enobs, '.-', 'linewidth', 2, 'Marker', 'd');
    leg{end+1} = lgText;
    legend(axesHandles(2), leg);
    grid(axesHandles(2), 'on');
    xlabel(axesHandles(2), 'Frequency (GHz)');
    ylabel(axesHandles(2), 'ENOB');
    title(axesHandles(2), sprintf('ENOB @ %g GSa/s, BW %g GHz', fsAWG/1e9, bandwidth/1e9));
end


function enob = getEnobSA(saConfig, tones, toneNum, bandwidth, axesHandles)
global sigDb;
global sigPwr;
fmin = 10e6;
fmax = bandwidth;
resbw = 500e3;
awgTone = tones(toneNum);
f = iqopen(saConfig);
xfprintf(f, ':INST SA');
xfprintf(f, ':CORR:NOIS:FLO ON');
xfprintf(f, sprintf(':FREQ:START %.15g', fmin));
xfprintf(f, sprintf(':FREQ:STOP %.15g', fmax * 1.05));
xfprintf(f, sprintf(':BWID %g', resbw));
%xfprintf(f, sprintf(':BWID:AUTO ON'));
xfprintf(f, ':INIT:CONT OFF');
xfprintf(f, ':INIT:IMM');
while (query(f, '*OPC?') == 0)
    pause(0.1); % don't hit it too often
end
xfprintf(f, ':CALC:MARK1:MAX');
toneFreq = str2double(query(f, 'CALC:MARK1:X?'));
if (((toneFreq - awgTone) / awgTone) > 0.05)
    errordlg(sprintf('Peak measurement on spectrum analyzer deviates by more than 5%% from generated tone. Please check the connection (%.10g - %.10g)', awgTone, toneFreq), 'Warning', 'replace');
    enob = NaN;
    return;
end
width = (fmax - fmin) / 200;
toneLeft = toneFreq - width;
toneRight = toneFreq + width;
xfprintf(f, sprintf(':CALC:MARK2:FUNC BPOW'));
xfprintf(f, sprintf(':CALC:MARK2:FUNC:BAND:LEFT %g', min(fmin, toneLeft)));
xfprintf(f, sprintf(':CALC:MARK2:FUNC:BAND:RIGHT %g', max(fmin, toneLeft)));
xfprintf(f, sprintf(':CALC:MARK3:FUNC BPOW'));
xfprintf(f, sprintf(':CALC:MARK3:FUNC:BAND:LEFT %g', min(fmax, toneRight)));
xfprintf(f, sprintf(':CALC:MARK3:FUNC:BAND:RIGHT %g', max(fmax, toneRight)));
xfprintf(f, sprintf(':CALC:MARK1:FUNC BPOW'));
xfprintf(f, sprintf(':CALC:MARK1:FUNC:BAND:LEFT %g', toneLeft));
xfprintf(f, sprintf(':CALC:MARK1:FUNC:BAND:RIGHT %g', toneRight));
xfprintf(f, ':INIT:IMM');
while (query(f, '*OPC?') == 0)
    pause(0.1); % don't hit it too often
end

n1dB = str2double(query(f, 'CALC:MARK2:Y?'));
n1Pwr = 10^(n1dB/10);
if (fmin >= toneLeft)
    n1Pwr = 0;
end
n2dB = str2double(query(f, 'CALC:MARK3:Y?'));
n2Pwr = 10^(n2dB/10);
if (toneRight >= fmax)
    n2Pwr = 0;
end
if (toneNum == 1)
    sigDb = str2double(query(f, 'CALC:MARK1:Y?'));
    sigPwr = 10^(sigDb/10);
end
if (sigDb < -60)
    errordlg('Signal power is less than -60 dBm. Please check the connection', 'Power too low', 'replace');
    enob = NaN;
    return;
end

xfprintf(f, ':INIT:CONT ON');
noisePwr = n1Pwr + n2Pwr;

%--- old calculation method
% sinad = 10*log10((sigPwr + noisePwr) / noisePwr);
% sinad = 10*log10(sigPwr/noisePwr);
% A = 2*sqrt(2)*sqrt(sigPwr/1000*50);
% enob = (sinad - 1.76 - 20*log10(A/FSR)) / 6.02;

%--- new calculation method
FSR = 2*sqrt(2)*sqrt(sigPwr/1000*50);     % amplitude into 50 Ohms
enob = log2( FSR/(sqrt(12)*sqrt(noisePwr/1000*50)) );

fclose(f);


function enob = getEnobScope(arbConfig, idx, scopeChannels, duration, toneFreq, scopeAvg, autoScopeAmpl, scopeAmpl, bandwidth, axesHandles)
global gScopeAmpl;
global sigPwr;
if (autoScopeAmpl)
    if (idx == 1)
        if (~isempty(strfind(scopeChannels, 'DIFF')))
            scopeAmpl = 1.6;
        else
            scopeAmpl = 0.8;
        end
        [sig, fsScope] = iqreaddca(arbConfig, scopeChannels, 0, duration, 1, scopeAmpl);
        gScopeAmpl = max(abs(sig)) * 2.2;
    end
    scopeAmpl = gScopeAmpl;
end
[sig, fsScope] = iqreaddca(arbConfig, scopeChannels, 0, duration, scopeAvg, scopeAmpl);
if (autoScopeAmpl)
    gScopeAmpl = max(abs(sig)) * 2.2;
end
len = length(sig);
fRes = fsScope / len;
% remove DC offset
sig = sig - mean(sig);
% apply window
w = window(@blackmanharris, len);
%w = gausswin(len, 3);
sig = sig .* w;
% fft
fsig = fft(sig)/len;
fsigabs = abs(fsig);
kmax = find(max(fsigabs) == fsigabs);
sigwin = 4;
% according to IEEE ENOB measurement, determine signal power 
if (idx == 1)
    sigPwr = sum(fsigabs(kmax-sigwin:kmax+sigwin));
end
faxis = (0:floor(len/2)) * fRes;
cla(axesHandles(1), 'reset');
plot(axesHandles(1), faxis / 1e9, 20*log10(fsigabs(1:floor(len/2)+1)), '.-');
hold(axesHandles(1), 'all');
plot(axesHandles(1), faxis(kmax-sigwin:kmax+sigwin) / 1e9, 20*log10(fsigabs(kmax-sigwin:kmax+sigwin)), '.-');
xlabel(axesHandles(1), 'Frequency (GHz)');
title(axesHandles(1), sprintf('Spectrum @ %g GHz', toneFreq/1e9));
xlim(axesHandles(1), [0 bandwidth/1e9]);
ylim(axesHandles(1), [-100 0]);
grid(axesHandles(1), 'on');
fsigabs(kmax-sigwin:kmax+sigwin) = 0;
% consider noise & distortions only up to a certain frequency
maxIdx = ceil(bandwidth / fRes);
fsigabs(maxIdx:end) = 0;
% calculate noise & distortions power
noise_rms = (1/rms(w))*sqrt(sum(fsigabs.^2));
sinad = 20*log10((sigPwr + noise_rms)/noise_rms);
enob = (sinad - 1.76) / 6.02;



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
if (evalin('base', 'exist(''debugNoQuery'', ''var'')'))
    return;
end
result = query(f, ':syst:err?');
if (isempty(result))
    fclose(f);
    errordlg({'The M8190A firmware did not respond to a :SYST:ERRor query.' ...
        'Please check that the firmware is running and responding to commands.'}, 'Error');
    retVal = -1;
    return;
end
if (~exist('ignoreError', 'var') || ignoreError == 0)
    while (~strncmp(result, '+0,No error', 11) && ~strncmp(result, '+0,"No error"', 13))
        errordlg({'M8190A firmware returns an error on command:' s 'Error Message:' result});
        if (evalin('base', 'exist(''debugScpi'', ''var'')'))
            fprintf('ERROR = %s\n', result);
        end
        result = query(f, ':syst:err?');
        retVal = -1;
    end
end

