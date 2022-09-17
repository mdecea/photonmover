function varargout = iqpulsegen(varargin)
% Generate I/Q samples for a pulse with given parameters.
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sampleRate in Hz
% 'pw' - pulse width in samples (can be a vector)
% 'rise' - rise time in samples (can be a vector)
% 'fall' - fall time in samples (can be a vector)
% 'off' - off time in samples (can be a vector)
% 'pulseShape' - pulse shape ('Trapezodial', 'Raised Cosine', 'Gaussian')
% 'alpha' - alpha value for Gaussian pulse
% 'low' - DAC value for off-time (-1 ... +1) (can be a vector)
% 'high' - DAC value for pulse (-1 ... +1) (can be a vector)
% If 'iqpulsegen' is called without arguments, opens a graphical user interface
% to specify parameters
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

if (nargin == 0)
    iqpulsegen_gui;
    return;
end
% assign default parameters
sampleRate = 8e9;
pw = 10;
rise = 20;
fall = 20;
off = 50;
pulseShape = 'Trapezodial';
alpha = 6;
low = -1;
high = 1;
correction = 0;
arbConfig = [];
channelMapping = [1 0];
for i = 1:2:nargin
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';   sampleRate = varargin{i+1};
            case 'pw';           pw = varargin{i+1};
            case 'rise';         rise = varargin{i+1};
            case 'fall';         fall = varargin{i+1};
            case 'off';          off = varargin{i+1};
            case 'pulseshape';   pulseShape = varargin{i+1};
            case 'alpha';        alpha = varargin{i+1};
            case 'low';          low = varargin{i+1};
            case 'high';         high = varargin{i+1};
            case 'arbconfig';    arbConfig = varargin{i+1};
            case 'correction';   correction = varargin{i+1};
            case 'channelmapping'; channelMapping = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    end
end

if (~(isvector(pw) && isvector(rise) && isvector(fall) && isvector(off) && isvector(low) && isvector(high) && isvector(alpha)))
    errordlg('pw, rise, fall, off, alpha, low and high must be scalars or vectors');
    return;
end
len = max([length(pw) length(rise) length(fall) length(off) length(low) length(high) length(alpha)]);
pw = repmat(reshape(pw, 1, length(pw)), 1, ceil(len / length(pw)));
pw = pw(1:len);
rise = repmat(reshape(rise, 1, length(rise)), 1, ceil(len / length(rise)));
rise = rise(1:len);
fall = repmat(reshape(fall, 1, length(fall)), 1, ceil(len / length(fall)));
fall = fall(1:len);
off = repmat(reshape(off, 1, length(off)), 1, ceil(len / length(off)));
off = off(1:len);
low = repmat(reshape(low, 1, length(low)), 1, ceil(len / length(low)));
low = low(1:len);
high = repmat(reshape(high, 1, length(high)), 1, ceil(len / length(high)));
high = high(1:len);
alpha = repmat(reshape(alpha, 1, length(alpha)), 1, ceil(len / length(alpha)));
alpha = alpha(1:len);

arbConfig = loadArbConfig(arbConfig);
numSamples = sum(rise) + sum(pw) + sum(fall) + sum(off);
if (numSamples <= 0)
    errordlg('zero length not allowed');
    return;
end
% for a large number of samples, adjust the number so that it fits into the
% segment granularity (relative error is small in this case)
if (numSamples > 1000000)
    samples = adjustSampleNum([rise' pw' fall' off'], arbConfig.segmentGranularity);
    rise = samples(:,1);
    pw = samples(:,2);
    fall = samples(:,3);
    off = samples(:,4);
end
pulse = calcPulseShape(low, high, rise, pw, fall, off, pulseShape, alpha);
% make sure the waveform has an even number of samples because the
% correction does not work properly with an odd number of samples
if (mod(length(pulse), 2) ~= 0)
    pulse = repmat(pulse, 2, 1);
end
if (correction)
    [pulse, channelMapping] = iqcorrection(pulse, sampleRate, 'chMap', channelMapping);
end

% determine how many times the pulse has to be repeated to fit into the
% AWG's segment granularity
numSamples = size(pulse, 1);
k = lcm(numSamples, arbConfig.segmentGranularity) / numSamples;
if (k * length(pulse) < arbConfig.minimumSegmentSize)
    k = k * ceil(arbConfig.minimumSegmentSize / (k * numSamples));
end
% if two output arguments are given, return the pulse and the number of
% times is needs to be repeated, so that the plot tool shows only one pulse
if (nargout >= 1)
    varargout{1} = pulse;
end
if (nargout >= 2)
    varargout{2} = k;
end
if (nargout >= 3)
    varargout{3} = channelMapping;
end
end


function samples = adjustSampleNum(samples, granularity)
% adjust an array with a number of samples, so that their sum will be a
% multiple of granularity.  Adjustment is done proportionally.
numSamples = sum(samples(1:end));
modval = mod(numSamples, granularity);
if (modval ~= 0)
    modval = granularity - modval;
    % corrGoal contains the number of samples that have to be added -
    % unfortunately it contains non-integer values. rounding all of them to
    % the nearest integer does not work, because the sum night not be equal
    % to modval, so here's an iterative process - not very elegant...
    corrGoal = (samples .* modval) ./ numSamples;
    corr = zeros(size(samples,1), size(samples,2));
    for i = 1:modval
        d = abs(corrGoal - corr);
        idx = find((d(1:end) == max(d(1:end))),1);
        corr(idx) = corr(idx) + 1;
    end
    samples = samples + corr;
end
end


function pulse = calcPulseShape(low, high, rise, pw, fall, off, pulseShape, alpha)
% calculate the pulseShape
pulse = [];
for i = 1:length(high)
    if (i == 1)
        lx = low(end);
    else
        lx = low(i-1);
    end
    switch lower(pulseShape)
        case 'trapezodial'
            rise_wave = linspace(lx,high(i),rise(i)+1);
            fall_wave = linspace(high(i),low(i),fall(i)+1);
        case 'raised cosine'
            rise_wave = (cos(pi * linspace(-1,0,rise(i)+1)) + 1) / 2 * (high(i) - lx) + lx;
            fall_wave = (cos(pi * linspace(0,1,fall(i)+1)) + 1) / 2 * (high(i) - low(i)) + low(i);
        case 'gaussian'
            gauss = gausswin(2*rise(i), alpha(i))';
            if (rise(i) > 0)
                rise_wave = gauss(1:rise(i)+1) * (high(i) - lx) + lx;
            else
                rise_wave = [];
            end
            gauss = gausswin(2*fall(i), alpha(i))';
            fall_wave = gauss(fall(i)+1:end) * (high(i) - low(i)) + low(i);
            fall_wave = [fall_wave 0]; % add one sample which will be removed below
        case 'exponential'
%            rise_wave = (cos(pi * linspace(-1,0,rise(i)+1)) + 1) / 2 * (high(i) - lx) + lx;
            rise_wave = exp(linspace(0, -alpha(i), rise(i)+1)) * (lx - high(i)) + high(i);
            fall_wave = exp(linspace(0, -alpha(i), fall(i)+1)) * (high(i) - low(i)) + low(i);
        otherwise
            error(['undefined pulse shape: ' pulseShape]);
    end
    pulse = [pulse rise_wave(1:end-1) high(i)*ones(1,pw(i)) fall_wave(1:end-1) low(i)*ones(1,off(i))];
end
pulse = real(pulse)';
end


function result = makeRowVector(a)
if (iscolumn(a))
    result = a.';
else
    result = a;
end
end
