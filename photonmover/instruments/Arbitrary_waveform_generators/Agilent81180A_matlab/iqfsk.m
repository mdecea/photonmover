function iqdata = iqfsk(varargin)
% This function generates an IQ FSK waveform
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sample rate in Hz
% 'tone' - vector of tone frequencies in Hz
% 'toneTime' - amount of time per tone - can be a scalar or a vector
%             (will be rounded to integer multiple of 1/sampleRate)
% 'correction' - if set to 1, will perform amplitude correction
%
% If called without arguments, opens a graphical user interface to specify
% parameters
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

%% parse arguments
if (nargin == 0)
    iqfsk_gui;
    return;
end
iqdata = [];
sampleRate = 4e9;
toneTime = 1e-6;
tone = linspace(100e6, 500e6, 5);
correction = 0;
arbConfig = [];
for i = 1:nargin
    if (ischar(varargin{i}))
        switch varargin{i}
            case 'sampleRate';   sampleRate = varargin{i+1};
            case 'toneTime';     toneTime = varargin{i+1};
            case 'tone';         tone = varargin{i+1};
            case 'correction';   correction = varargin{i+1};
            case 'arbconfig';    arbConfig = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    end
end

%% determine the number of samples per tone and total number of samples
numTones = max([length(tone) length(toneTime)]);
tone = fixlength(tone, numTones);
toneTime = fixlength(toneTime, numTones);
toneSamples = round(toneTime * sampleRate);
numSamples = sum(toneSamples);
% make sure the number of samples is a multiple of segment granularity
arbConfig = loadArbConfig(arbConfig);
i = 1;
while (mod(numSamples, arbConfig.segmentGranularity) ~= 0)
    toneSamples(i) = toneSamples(i) + 1;
    i = (mod(i, numTones) + 1);
    numSamples = sum(toneSamples);
end
% sanity check
if (numSamples > arbConfig.maximumSegmentSize)
    errordlg('Waveform too long - adjust sample rate or tone duration');
    return;
end

%% generate signal 
fm = [];
am = [];
linmag = ones(1, numTones);
% if (correction)
%     try
%         load(iqampCorrFilename());
%         mag = interp1(ampCorr(:,1), ampCorr(:,2), tone, 'pchip');
%         linmag = 10.^(mag./20);
%     catch ex
%         warndlg('No correction file available. Please use iqtone to create it', 'Warning', 'modal');
%     end
% end
for i=1:numTones
    fm = [fm tone(i) * ones(1,toneSamples(i))];
    am = [am linmag(i) * ones(1,toneSamples(i))];
end

% for phase continuity, make sure that we end up with zero phase
endphase = sum(fm) / sampleRate;
d = round(endphase) - endphase;
if (d ~= 0)
    warndlg(sprintf('tone frequencies were modified %g Hz to achieve phase continuity', d * sampleRate / numSamples));
    fm = fm + (d * sampleRate / numSamples);
end
phase = cumsum(fm) / sampleRate;
iqdata = am .* exp(2*pi*1i*phase);
iqdata = iqdata.';
if (correction)
    iqdata = iqcorrection(iqdata, sampleRate);
end

end


function x = fixlength(x, len)
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
end
