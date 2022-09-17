function result = iqcaltone(varargin)
% Generate CW signals with calibrated power level
% Parameters are passed as property/value pairs. Properties are:
%  cmd - 'calibrate', 'run', 'load' or 'save'
%  arbConfig - AWG configuration structure (default: [])
%  sampleRate - sample rate in Hz
%  channelMapping - array to specify into which AWG channel to download
%  hMsgBox - handle to a waitbar, can be used to indicate progress
%  if cmd == 'calibrate'
%    tones - vector of frequencies at which calibration will be done
%    amplitudes - vector of amplitudes at which calibration will be done
%  if cmd == 'run'
%    freq - output frequency in Hz
%    power - desired output power in dBm
%    phase - desired phase in degrees
%    cal - calibration struct (as returned when called with cmd = 'calibrate'
%    autoSA - if set to 1, will set up spectrum analyzer to measure power
%  if cmd == 'load' or 'save'
%    filename - full filename from where to load/save the calibration
%
% If called without arguments, opens a graphical user interface to specify
% parameters.
%
% T.Dippon, Keysight Technologies 2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

%% parse arguments
if (nargin == 0)
    iqcaltone_gui;
    return;
end
% some default parameters
cmd = '';
arbConfig = [];
sampleRate = 64e9;
tones = linspace(1e9, 20e9, 20);
amplitudes = linspace(0.1, 1, 5);
freq = 10e9;
power = -6;
phase = 0;
cal = [];
myAxes = [];
hMsgBox = [];
filename = [];
autoSA = 0;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'cmd';            cmd = varargin{i+1};
            case 'arbconfig';      arbConfig = varargin{i+1};
            case 'samplerate';     sampleRate = varargin{i+1};
            case 'tones';          tones = varargin{i+1};
            case 'amplitudes';     amplitudes = varargin{i+1};
            case 'axes';           myAxes = varargin{i+1};
            case 'channelmapping'; channelMapping = varargin{i+1};
            case 'frequency';      freq = varargin{i+1};
            case 'power';          power = varargin{i+1};
            case 'phase';          phase = varargin{i+1};
            case 'autosa';         autoSA = varargin{i+1};
            case 'cal';            cal = varargin{i+1};
            case 'filename';       filename = varargin{i+1};
            case 'hmsgbox';        hMsgBox = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end
switch lower(cmd)
    case 'run'; result = doRun(arbConfig, sampleRate, freq, power, phase, channelMapping, cal, myAxes, autoSA, 1);
    case 'setfreq'; result = doRun(arbConfig, sampleRate, freq, power, phase, channelMapping, cal, myAxes, autoSA, 0);
    case 'calibrate'; result = doCal(arbConfig, sampleRate, tones, amplitudes, channelMapping, myAxes, hMsgBox);
    case 'load'; result = doLoad(filename, myAxes);
    case 'save'; result = doSave(filename, cal);
end
end


%%
function result = doLoad(filename, myAxes)
result = [];
try
    result = load(filename);
    doPlot(result, myAxes);
catch ex
    msgbox(sprintf('Error loading %s\n%s', filename, ex.message));
end
end


%%
function result = doSave(filename, cal)
result = [];
try
    save(filename, '-struct', 'cal');
catch ex
    msgbox(sprintf('Error writing to %s\n%s', filename, ex.message));
end
end


%%
function doPlot(result, myAxes, freq, power)
if (~isempty(myAxes))
    plot(myAxes, result.tones/1e9, result.cal, '.-');
    xlabel(myAxes, 'Frequency (GHz)');
    ylabel(myAxes, 'dBm');
    grid(myAxes, 'on');
    leg = cell(length(result.amplitudes), 1);
    for i=1:length(result.amplitudes)
        leg{i} = sprintf('%s V', iqengprintf(result.amplitudes(i), 3));
    end
    legend(myAxes, leg);
    if (exist('freq', 'var'))
        hold(myAxes, 'on');
        plot(myAxes, freq/1e9, power, 'ko');
        hold(myAxes, 'off');
    end
end
end



%%
function result = doRun(arbConfig, sampleRate, freq, power, phase, channelMapping, cal, myAxes, autoSA, runFlag)
result = [];
[arbConfig, saConfig] = loadArbConfig(arbConfig);
if (isempty(cal))
    errordlg('no cal structure provided');
    return;
end
doPlot(cal, myAxes, freq, power);
% find the fractional index into the frequency table
fidx = interp1(cal.tones, 1:length(cal.tones), freq, 'linear');
if (~isnan(fidx))
    pVec1 = cal.cal(floor(fidx),:);
    pVec2 = cal.cal(ceil(fidx),:);
    pmod = fidx - floor(fidx);
    pVec = (1-pmod)*pVec1 + pmod*pVec2;
    logAmp = interp1(pVec, log10(cal.amplitudes), power, 'linear');
    if (~isnan(logAmp))
        amp = 10.^logAmp;
        result = amp;
        if (runFlag)
            arbConfig.amplitude = amp;
            iqdata = iqtone('sampleRate', sampleRate, 'tone', freq, 'phase', phase*pi/180, 'nowarning', 1);
            iqdownload(iqdata, sampleRate, 'arbConfig', arbConfig, 'channelMapping', channelMapping, 'keepOpen', 1);
            if (autoSA)
                fSA = iqopen(saConfig.visaAddr);
                if (~isempty(fSA))
                    xfprintf(fSA, ':INIT:CONT ON');
                    xfprintf(fSA, sprintf(':FREQ:CENT %15g', freq));
                    xfprintf(fSA, sprintf(':FREQ:SPAN 0'));
                    xfprintf(fSA, ':CALC:MARK1:STAT ON');
                    xfprintf(fSA, ':CALC:MARK1:MODE POS');
                    fclose(fSA);
                end
            end
        else
            fAWG = iqopen();
            if (~isempty(fAWG))
                for ch = find(sum(channelMapping, 2))'
                    fprintf(fAWG, sprintf(':VOLT%d %.15g', ch, amp));
                end
                fclose(fAWG);
            end
        end
    end
end
end



%%
function result = doCal(arbConfig, sampleRate, tones, amplitudes, channelMapping, myAxes, hMsgBox)
[arbConfig, saConfig] = loadArbConfig(arbConfig);
result = [];
fAWG = iqopen(arbConfig);
if (isempty(fAWG))
    return;
end
fclose(fAWG);
fSA = iqopen(saConfig.visaAddr);
if (isempty(fSA))
    return;
end
xfprintf(fSA, ':INST:SEL SA');
xfprintf(fSA, ':INIT:CONT OFF');
xfprintf(fSA, sprintf(':FREQ:SPAN %.15g', 0));
xfprintf(fSA, sprintf(':BWID %g', 8e6));
xfprintf(fSA, ':BWID:VID:AUTO ON');
%xfprintf(f, ':DISP:WIND:TRAC:Y:RLEV -10 dBm');
%xfprintf(f, ':DISP:WIND:TRAC:Y:PDIV 10 dB');
cal = nan(length(tones), length(amplitudes));
abort = 0;
clear result;
result.tones = tones;
result.amplitudes = amplitudes;
for nt = 1:length(tones)
    tone =  tones(nt);
    xfprintf(fSA, sprintf(':FREQ:CENT %.15g', tone));
    xfprintf(fSA, ':CALC:MARK1:STAT ON');
    xfprintf(fSA, ':CALC:MARK1:MODE POS');
    for na = 1:length(amplitudes)
        amplitude = amplitudes(na);
        arbConfig.amplitude = amplitude;
        if (na == 1)
            iqdata = iqtone('sampleRate', sampleRate, 'tone', tone, 'nowarning', 1);
            iqdownload(iqdata, sampleRate, 'arbConfig', arbConfig, 'channelMapping', channelMapping, 'keepOpen', 1);
        else
            for ch = find(sum(channelMapping, 2))'
                fprintf(fAWG, sprintf(':VOLT%d %.15g', ch, amplitude));
            end
        end
        fprintf(fSA, ':INIT:IMM');
        while (query(fSA, '*OPC?') == 0)
            pause(0.05); % don't hit it too often
        end
        fprintf(fSA, ':INIT:IMM');
        while (query(fSA, '*OPC?') == 0)
            pause(0.05); % don't hit it too often
        end
        mag = sscanf(query(fSA, 'CALC:MARK1:Y?'), '%g');
        cal(nt, na) = mag;
        result.cal = cal;
        doPlot(result, myAxes);
        if (~isempty(hMsgBox))
            waitbar((na/length(amplitudes)*nt)/length(tones), hMsgBox, sprintf('Calibrating tone %d / %d', nt, length(tones)));
            figure(hMsgBox);
            pause(0.01); % allow waitbar to be visible
            if (getappdata(hMsgBox, 'cancel'))
                abort = 1;
                break;
            end
        end
    end
    if (abort)
        break;
    end
end
if (abort)
    result = [];
end
xfprintf(fSA, ':INIT:CONT ON');
fclose(fSA);
end


function xfprintf(f, s)
% Send the string s to the instrument object f
% and check the error status

% un-comment the following line to see a trace of commands
%    fprintf('cmd = %s\n', s);
    fprintf(f, s);
    cal = query(f, ':syst:err?');
    if (isempty(cal))
        fclose(f);
        error(':syst:err query failed');
    end
    if (~strncmp(cal, '+', 1))
        fprintf('cmd = %s / result = %s', s, cal);
    end
end


