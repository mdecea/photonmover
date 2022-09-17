function keysight(varargin)
% Generate the KEYSIGHT logo on an AWG
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sample rate in Hz
% 'carrierFreq' - frequency of the sine wave inside the logo in Hz
% 'duration' - of the logo waveform in seconds
% 'wiggling' - 1 = wiggling turned on (requires SEQ option), 0 = wiggling turned off
% 'steps' - number of discrete steps used for the wiggling effect
% 'doDownload' - 1 = download to AWG, 0 = display only

if (nargin == 0)
    keysight_gui;
    return;
end
sampleRate = 12e9;
carrierFreq = 501e6;
duration = 8e-6;
wiggling = 0;
steps = 100;
wiggleRate = 6;
wiggleDepth = 0.7;
extend = 0;
average = 1;
filename = 'keysight_logo.png';
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';     sampleRate = varargin{i+1};
            case 'carrierfreq';    carrierFreq = varargin{i+1};
            case 'duration';       duration = varargin{i+1};
            case 'wiggling';       wiggling = varargin{i+1};
            case 'steps';          steps = varargin{i+1};
            case 'wigglerate';     wiggleRate = varargin{i+1};
            case 'wiggledepth';    wiggleDepth = varargin{i+1};
            case 'average';        average = varargin{i+1};
            case 'extend';         extend = varargin{i+1};
            case 'filename';       filename = varargin{i+1};
            case 'dodownload';     doDownload = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end
try
%    filename = [fileparts(which('keysight.m')) '\keysight_logo.png'];
    [path file ext] = fileparts(filename);
    a = imread(filename, ext(2:end));
catch ex
    msgbox(sprintf('Can''t read: %s', filename));
    return;
end
b = double(a);
% change to greyscale
if (size(b,3) > 1)
    b = sum(b,3) / size(b,3);
end
% compare against threshold (middle value between brightest and darkest)
thres = (max(b(1:end)) + min(b(1:end))) / 2;
% c will be 1 where the image is darker than the threshold
c = (b < thres);
% find columns with no content at beginning and end
emptyCols = (max(c)==0);
first = find((emptyCols == 0), 1, 'first');
last = find((emptyCols == 0), 1, 'last');
% remove empty columns at the beginning and end
c(:,(last + 1):end) = [];
c(:,1:(first - 1)) = [];
% find upper and lower boundary
for i = 1:size(c,2)
    tmp = find(c(:,i), 1, 'first');
    if (isempty(tmp))
        tmp = -1;
    end
    m1(i) = tmp;
    tmp = find(c(:,i), 1, 'last');
    if (isempty(tmp))
        tmp = -1;
    end
    m2(i) = tmp;
end
% replace gaps with average value (dont know what else to do...)
avgval = (sum(m1) + sum(m2)) / (length(m1) + length(m2));
m1(m1 == -1) = avgval;
m2(m2 == -1) = avgval;
% extend left and right
oldlen = size(c,2);
%newlen = 1920;
newlen = round(oldlen * (1 + extend/100));
off = floor((newlen - size(c,2)) / 2);
off2 = newlen - size(c,2) - off;
avgval = (m1(1) + m2(1))/2;
m1 = [repmat(avgval, 1, off) m1 repmat(avgval, 1, off2)];
m2 = [repmat(avgval, 1, off) m2 repmat(avgval, 1, off2)];
% center around zero
mid = (m2(1) + m1(1)) / 2;
m1 = -1 * (m1 - mid);
m2 = -1 * (m2 - mid);
% averaging
if (average)
    avlen = 20;
    for i = length(m1):-1:avlen
        m1(i) = sum(m1(i-avlen+1:i))/avlen;
        m2(i) = sum(m2(i-avlen+1:i))/avlen;
    end
end
% scale to +1...-1
scale = max(abs([m1 m2]));
m1 = m1 / scale / 1.2;
m2 = m2 / scale / 1.2;
% create sine wave inside upper and lower boundaries
arbConfig = loadArbConfig();
numSamples = round(duration * sampleRate / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
numSamples = min(numSamples, arbConfig.maximumSegmentSize);
y0 = real(iqtone('samplerate', sampleRate, 'tone', carrierFreq, 'numsamples', numSamples, 'nowarning', 1));
n = length(y0);
lm = length(m1);
m1a = interp1(0:lm-1, m1, (0:n-1)/n*(lm-1));  % upper envelope
m2a = interp1(0:lm-1, m2, (0:n-1)/n*(lm-1));  % lower envelope
med = (m1a + m2a)/2;
amp = abs(m2a - m1a)/2;
y = y0 .* amp + med;
n2 = floor(numSamples/2);
marker = [-1*ones(1,n2) ones(1,numSamples-n2)];
if (doDownload)
    hMsgBox = msgbox('Downloading... Please wait');
    iqdownload(complex(y, marker), sampleRate, 'channelMapping', [1 0; 0 1; 1 0; 0 1]);
else
    figure(1);
    clf;
    plot(y);
    ylim([-1 +1]);
end

if (wiggling)
    overallDuration = 4;  % duration in seconds
    mx = wiggleRate * pi * linspace(-1,1-1/numSamples,numSamples);
    my = sin(mx)./mx;
    my = [ones(1,numSamples) 1-(my*wiggleDepth) ones(1,numSamples)];
    clear seq;
    seqidx = 1;
    for i = 1:steps
        idx = round(i * 2*numSamples / steps);
        y2 = y0 .* amp .* my(2*numSamples+1 - idx : 3*numSamples - idx) + med;
        figure(1);
        plot(y2);
        ylim([-1 +1]);
        title(sprintf('Calculating... (%d %%)', round(i/steps*100)));
        if (doDownload)
            iqdownload(complex(y2, marker), sampleRate, 'segmentNumber', seqidx, 'run', 0);
        end
        seq(seqidx).segmentNumber = seqidx;
        seq(seqidx).segmentLoops = round(overallDuration / duration / steps);
        seq(seqidx).markerEnable = 1;
        seqidx = seqidx + 1;
    end
    figure(1);
    title('');
    if (doDownload)
        iqseq('define', seq, 'channelMapping', [1 0; 1 0], 'run', 0);
        iqseq('mode', 'STSC');
        f = iqopen();
        fprintf(f, sprintf(':mark1:samp:volt:ampl %g; offs %g', 500e-3, 0));
        fprintf(f, sprintf(':mark1:sync:volt:ampl %g; offs %g', 500e-3, 0));
    end
end
if (doDownload)
    try
        close(hMsgBox);
    catch
    end
end


% set up the scope - if available
if (doDownload)
    arbConfig = loadArbConfig();
    if ((isfield(arbConfig, 'isScopeConnected') && arbConfig.isScopeConnected == 0) || ~isfield(arbConfig, 'visaAddrScope'))
        msgbox('Please observe AWG channel 1 on a scope, use channel 2 as a trigger');
    else
        f = iqopen(arbConfig.visaAddrScope);
        if (~isempty(f))
            fprintf(f, '*rst');
            fprintf(f, sprintf(':timebase:scal %g', duration / 12));
            fprintf(f, ':timebase:delay 0');
            fprintf(f, sprintf(':chan%d:disp on;  scale %g; offs 0', 1, 100e-3));
            fprintf(f, sprintf(':chan%d:disp off; scale %g; offs 0', 2, 100e-3));
            fprintf(f, sprintf(':chan%d:disp off; scale %g; offs 0', 3, 100e-3));
            fprintf(f, sprintf(':chan%d:disp off; scale %g; offs 0', 4, 100e-3));
            fprintf(f, sprintf(':trig:edge:source chan2'));
            fprintf(f, sprintf(':trig:edge:slope pos'));
            fprintf(f, sprintf(':trig:lev chan2,0'));
            fprintf(f, sprintf(':acquire:average:count 2'));
            fprintf(f, sprintf(':acquire:average %s', '1'));
            query(f, '*opc?');
            fclose(f);
        end
    end
end
