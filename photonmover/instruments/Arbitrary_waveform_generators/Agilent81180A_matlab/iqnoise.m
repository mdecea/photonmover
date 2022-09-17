function varargout = iqnoise(varargin)
% This function generates bandlimited noise with a notch 
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sample rate in Hz
% 'numSamples' - number of samples in waveform (optional)
% 'start' - start frequency in Hz
% 'stop' - stop frequency in Hz
% 'notchFreq' - notch center frequency in Hz (can be a vector)
% 'notchSpan' - notch width in Hz (can be a vector)
% 'notchDepth' - attenuation of notch
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
    iqtone_gui;
    return;
end
sampleRate = 4.2e9;
numSamples = 65536;
startFreq = 100e6;
stopFreq = 500e6;
notchFreq = [];
notchSpan = [];
notchDepth = [];
normalize = 1;
correction = 0;
channelMapping = [1 0];
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate'; sampleRate = varargin{i+1};
            case 'numsamples'; numSamples = varargin{i+1};
            case 'start';      startFreq = varargin{i+1};
            case 'stop';       stopFreq = varargin{i+1};
            case 'notchfreq';  notchFreq = varargin{i+1};
            case 'notchspan';  notchSpan = varargin{i+1};
            case 'notchdepth'; notchDepth = varargin{i+1};
            case 'normalize';  normalize = varargin{i+1};
            case 'correction'; correction = varargin{i+1};
            case 'channelmapping'; channelMapping = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

% check frequencies
if ((startFreq > sampleRate / 2) || (startFreq < -sampleRate / 2) || ...
    (stopFreq > sampleRate / 2) || (stopFreq < -sampleRate / 2) || ...
    (~isempty(find(notchFreq > sampleRate / 2))) || (~isempty(find(notchFreq < -sampleRate / 2))))
    errordlg('frequencies must be in the range -Fs/2...Fs/2', 'Error');
    error('frequencies must be in the range -Fs/2...Fs/2');
end
if (size(notchSpan, 2) > 1)
    notchSpan = notchSpan.';
end
if (isempty(notchSpan))
    notchSpan = 0;
end
if (length(notchSpan) < length(notchFreq))
    notchSpan = repmat(notchSpan, ceil(length(notchFreq) / length(notchSpan)), 1);
end

if (size(notchDepth, 2) > 1)
    notchDepth = notchDepth.';
end
if (isempty(notchDepth))
    notchDepth = -3000 * ones(length(notchFreq), 1);
end
if (length(notchDepth) < length(notchFreq))
    notchDepth = repmat(notchDepth, ceil(length(notchFreq) / length(notchDepth)), 1);
end

% generate the noise signal.
% Start with random phases in frequency domain
iqf = exp(1i*2*pi*rand(numSamples,1));
% apply filter
cp = length(iqf)/2 + 1;
startp = round(startFreq * numSamples / sampleRate);
stopp  = round(stopFreq * numSamples / sampleRate);
nfp = round(notchFreq * numSamples / sampleRate);
nsp = round(notchSpan/2 * numSamples / sampleRate);
linMag = 10.^(notchDepth/20);
iqf(1:cp+startp) = 0;
iqf(cp+stopp:end) = 0;
for i = 1:length(nfp)
    iqf(cp+nfp(i)-nsp(i):cp+nfp(i)+nsp(i)) = iqf(cp+nfp(i)-nsp(i):cp+nfp(i)+nsp(i)) .* linMag(i);
end
% ...and convert into time domain
iqdata = ifft(fftshift(iqf));

% apply correction
if (correction)
    [iqdata, channelMapping] = iqcorrection(iqdata, sampleRate, 'chMap', channelMapping, 'normalize', normalize);
end
% normalize
if (normalize)
    scale = max(max(max(abs(real(iqdata))), max(abs(imag(iqdata)))));
    iqdata = iqdata / scale;
end
if (nargout >= 1)
    varargout{1} = iqdata;
end
if (nargout >= 2)
    varargout{2} = channelMapping;
end

end
