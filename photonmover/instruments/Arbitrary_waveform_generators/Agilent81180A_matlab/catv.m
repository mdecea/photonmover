function [sig, sampleRate] = catv(varargin)
% Demonstrate CATV signal generation using the M8190A
% with CW tones on analog channels and 256QAM signals on digital channels.
%
% Signals can either be generated on a single M8190A output channel or
% distributed to two channels
% Adjustable parameters include: frequencies, tilt, modulation scheme,
% filter, etc.etc.

% T.Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

if (nargin == 0)
    catv_gui;
    return;
end

% tilt in dB across the whole frequency range 
tilt = 15;
% sample rate (0 for automatic selection)
sampleRate = 0;
% Parameters for the digital channels
numSymbols = 960;   % number of symbols that are transmitter
filterNSym = 20;    % filter length in symbols
filterBeta = 0.12;  % filter roll-off
sameData = 1;       % use the same data pattern for all carriers (improves processing speed)
hMsgBox = [];
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';     sampleRate = varargin{i+1};
            case 'freqtable';      fTable = varargin{i+1};
            case 'tilt';           tilt = varargin{i+1};
            case 'numsymbols';     numSymbols = varargin{i+1};
            case 'filtertype';     filterType = varargin{i+1};
            case 'filternsym';     filterNSym = varargin{i+1};
            case 'filterbeta';     filterBeta = varargin{i+1};
            case 'correction';     correction = varargin{i+1};
            case 'samedata';       sameData = varargin{i+1};
            case 'hmsgbox';        hMsgBox = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

if (isempty(fTable))
    sig = [];
    return;
end

% determine the list of symbol rates and frequencies
symRates = [];
freqList = [];
for i = 1:length(fTable)
    if (fTable(i).enable && strncmp(fTable(i).modulation, 'QAM', 3))
        symRates = [symRates fTable(i).bandwidth];
    end
    freqList = [freqList fTable.frequency];
end
symRates = unique(symRates);
freqList = unique(freqList);
if (length(symRates) > 1)
    errordlg('currently, only a single symbol rate for all digital carriers is supported');
    sig = [];
    return;
end
if (isempty(symRates))
    nx = 2400;
    dx = 1;
else
    [n, d] = rat(symRates);
    nx = lcm2(n);
    dx = lcm2(d);
end

% round number of symbols to a multiple of the granularity so that we don't
% need to repeat waveforms inside iqmod
arbConfig = loadArbConfig();
numSymbols = ceil(numSymbols / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;

% calculate a "good" sample rate if it is not specified
if (sampleRate == 0)
    if (isempty(symRates))
        sampleRate = arbConfig.defaultSampleRate;
        numSamples = 960000;
    else
        sampleRate = round(arbConfig.defaultSampleRate / nx) * nx;
        oversampling = round(sampleRate / nx * dx);    % t.b.d. handle this for multiple symbol rates !!!!
        numSamples = round(numSymbols * oversampling);
    end
else
    if (isempty(symRates))
        numSamples = 960000;
    else
        oversampling = round(sampleRate / nx * dx);    % t.b.d. handle this for multiple symbol rates !!!!
        numSamples = round(numSymbols * oversampling);
    end
end

sig1 = zeros(numSamples, 1);
sig2 = zeros(numSamples, 1);

% adjust digital carriers and noise to match tone power
pwrOffset = -3;
%% generate the carriers
for i = 1:length(fTable)
    if (fTable(i).enable)
        freq = fTable(i).frequency;
        if (length(freqList) > 1)
            mag = (freq - min(freqList)) * tilt / (max(freqList) - min(freqList));
        else
            mag = zeros(size(freqList));
        end
        switch (upper(fTable(i).modulation))
            case 'CW'
                sig = real(iqtone('sampleRate', sampleRate, 'tone', freq, 'magnitude', mag + fTable(i).power, ...
                    'numSamples', numSamples, 'normalize', 0, 'correction', correction, 'nowarning', 1));
            case {'QAM16' 'QAM32' 'QAM64' 'QAM128' 'QAM256' 'QAM512' 'QAM1024' 'QAM2048' 'QAM4096'}
                sig = real(iqmod('sampleRate', sampleRate, 'oversampling', oversampling, 'modType', fTable(i).modulation, ...
                    'numSymbols', numSymbols, 'filterNsym', filterNSym, 'filterBeta', filterBeta, ...
                    'carrierOffset', fTable(i).frequency, 'filterType', filterType, 'correction', correction, ...
                    'magnitude', mag, 'normalize', 0, 'newdata', ~sameData, 'hMsgBox', hMsgBox));
                numCarrier = length(freq);
                rmsTotal = norm(sig) / sqrt(length(sig));
                rmsAvg = rmsTotal / sqrt(numCarrier);   % this is amplitude, not power!
                sig = sig / rmsAvg * 10^((sum(mag)/length(mag) + fTable(i).power + pwrOffset)/20);
            case 'OFDM'
                sig = zeros(numSamples, 1);
            case 'NOISE'
                sig = zeros(numSamples, 1);
                for k = 1:length(freq)
                    if (~isempty(hMsgBox))
                        hMsgBox = msgbox(sprintf('Calculating waveform (%d / %d). Please wait...', k, length(freq)), 'Please wait...', 'replace');
                    end
                    sigTmp = real(iqnoise('sampleRate', sampleRate, 'numSamples', numSamples, ...
                        'start', freq(k) - fTable(i).bandwidth/2, ...
                        'stop', freq(k) + fTable(i).bandwidth/2, 'normalize', 0));
                    rmsAvg = norm(sigTmp) / sqrt(length(sigTmp));
                    sig = sig + sigTmp / rmsAvg * 10^((mag(k) + fTable(i).power + pwrOffset) / 20);
                end
            otherwise
                errordlg(['unknown modulation: ' fTable(i).modulation]);
                sig = zeros(numSamples, 1);
        end
        switch (upper(fTable(i).channel))
            case 'CH. 1'
                sig1 = sig1 + sig;
            case 'CH. 2'
                sig2 = sig2 + sig;
            case 'CH.1+2'
                sig1 = sig1 + sig;
                sig2 = sig2 + sig;
            otherwise
                errordlg(['unknown channel: ' fTable(i).channel]);
        end
    end
end
sig = complex(sig1, sig2);



function result = lcm2(x)
% calculate least common multiple for a vector
result = 1;
for i=1:length(x)
    result = lcm(result,x(i));
end
