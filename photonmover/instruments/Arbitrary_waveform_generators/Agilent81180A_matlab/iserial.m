function [samples, sampleRate, numBits, numSamples, channelMapping] = iserial(varargin)
% This function generates a waveform from a digital data stream
% and adds selected distortions
%
% Parameters are passed as property/value pairs. Properties are:
% 'dataRate' - data rate in symbols/s
% 'transitionTime' - rise/fall time in UI (default: 0.5)
% 'numBits' - number of symbols to be generated
% 'symbolShift' - shift the data pattern by this number of symbols
%               this is useful to have uncorrelated PRBS patterns on
%               multiple channels
% 'data' - can be 'clock', 'random', 'MLT-3', 'PAM3', 'PAM4', 'PAM5'
%        'PRBS7', 'PRBS9', 'PRBS11', 'PRBS12', 'PRBS15' or a vector of values in the
%        range [0...1]
% 'format' - 'NRZ' or 'PAM4' --> data format for PRBS'es and Random
% 'noise' - amount of noise added, range [0...1] (default: 0)
% 'noiseFreq' - frequency of the noise in Hz or zero for gaussian noise
% 'isi' - amount of ISI in the range [0...1] (default = 0)
% 'jitterShape' - can be 'sine', 'square', 'ramp', 'triagle', 'noise'
% 'SJfreq' - sinusoidal jitter frequency in Hz (default: no jitter)
% 'SJpp' - sinusoidal jitter in UI
% 'RJpp' - 6-sigma value in UI
% 'sampleRate' - sample rate in Hz (if zero or not specified, the
%                default sample rate for the selected AWG is used
% 'amplitude' - data will be in the range (-ampl...+ampl) + noise
% 'dutyCycle' - will skew the duty cycle (default: 0.5)
% 'correction' - apply frequency/phase response correction
% 'precursor' - list of values in dB (default: empty)
% 'postcursor' - list of values in dB (default: empty)
% 'nowarning' - can be set to 1 to suppress warning messages (default: 0)
% 'normalize' - can be set to 0 to avoid automatic scaling to +/- 1 after freq/phase response corrections (default: 1)
% 'channelMapping' - channel mapping (see iqdownload.m for details)
%
% If called without arguments, opens a graphical user interface to specify
% parameters

% T.Dippon, Keysight Technologies 2011-2017
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

%% if called without arguments, open the GUI
if (nargin == 0)
    iserial_gui;
    return;
end
% set default parameters
arbConfig = [];
samples = [];
sampleRate = 0;
dataRate = 1e9;
rtUI = 0.5;
ftUI = 0.5;
ttProp = 0;
filterType = 'Transition Time';
filterNsym = 20;
filterBeta = 1;
numBits = -1;
numSamples = 0;
symbolShift = 0;
data = 'random';
format = 'NRZ';
fct = 'display';
filename = [];
isi = 0;
jitterShape = 'sine';
SJfreq = 10e6;
SJpp = 0;
RJpp = 0;
noise = 0;
noiseFreq = 20e6;
amplitude = 1;
dutyCycle = 0.5;
preCursor = [];
postCursor = [];
nowarning = 0;
correction = 0;
sscFreq = 0;
sscDepth = 0;
levels = [0 1/3 2/3 1];
normalize = 1;
channelMapping = [1 0];
useM8196RefClk = 0;
% parse input parameters
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'arbconfig';    arbConfig = varargin{i+1}; 
            case 'datarate';     dataRate = varargin{i+1};
            case 'ttproportional'; ttProp = varargin{i+1};
            case 'transitiontime'; tmp = varargin{i+1}; rtUI = tmp(1); ftUI = tmp(end);
            case 'risetime';     rtUI = varargin{i+1};
            case 'falltime';     ftUI = varargin{i+1};
            case 'filtertype';   filterType = varargin{i+1};
            case 'filternsym';   filterNsym = varargin{i+1};
            case 'filterbeta';   filterBeta = varargin{i+1};
            case 'numbits';      numBits = varargin{i+1};
            case 'symbolshift';  symbolShift = varargin{i+1};
            case 'data';         data = varargin{i+1};
            case 'format';       format = varargin{i+1};
            case 'function';     fct = varargin{i+1};
            case 'filename';     filename = varargin{i+1};
            case 'levels';       levels = varargin{i+1};
            case 'isi';          isi = varargin{i+1};
            case 'noisefreq';    noiseFreq = varargin{i+1};
            case 'noise';        noise = varargin{i+1};
            case 'jittershape';  jitterShape = varargin{i+1};
            case 'sjfreq';       SJfreq = varargin{i+1};
            case 'sjpp';         SJpp = varargin{i+1};
            case 'rjpp';         RJpp = varargin{i+1};
            case 'sscfreq';      sscFreq = varargin{i+1};
            case 'sscdepth';     sscDepth = varargin{i+1};
            case 'samplerate';   sampleRate = varargin{i+1};
            case 'amplitude';    amplitude = varargin{i+1};
            case 'dutycycle';    dutyCycle = varargin{i+1};
            case 'precursor';    preCursor = varargin{i+1};
            case 'postcursor';   postCursor = varargin{i+1};
            case 'nowarning';    nowarning = varargin{i+1};
            case 'correction';   correction = varargin{i+1};
            case 'normalize';    normalize = varargin{i+1};
            case 'channelmapping'; channelMapping = varargin{i+1};
            case 'usem8196refclk'; useM8196RefClk = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end
% make sure that SJfreq and SJpp have the same length
numSJ = max(length(SJfreq), length(SJpp));
SJfreq = fixlength(SJfreq, numSJ);
SJpp = fixlength(SJpp, numSJ);

if (numBits < 0)
    numBits = length(data);
end

arbConfig = loadArbConfig(arbConfig);
% remember the number of symbols, so that we can output a warning when the
% number of symbols needs to be changed
numBitsOld = numBits;

if (sampleRate ~= 0)    % sample rate is defined by the user
    fsApprox = sampleRate;
    % if sample rate AND data rate are given, round the number of bits
    % to match the granularity requirement
    [~, d] = rat(fsApprox / dataRate / arbConfig.segmentGranularity);
    numBits = ceil(numBits / d) * d;
    if (useM8196RefClk)
        [~,d] = rat(dataRate / (fsApprox/32));
        if (d ~= 1)
            warndlg('With this combination of sample rate and data rate, the RefClkOut signal is not synchronous to the data rate. Please turn on the "Auto" sample rate');
        end
    end
else
    % sample rate automatic --> start with the default sample rate
    fsApprox = arbConfig.defaultSampleRate;
    if (useM8196RefClk)
        % configure RefClk Out
        if (~isempty(strfind(arbConfig.model, 'M8196A')))
            if (strcmp(fct, 'download'))
                f = iqopen(arbConfig);
                if (~isempty(f))
                    fprintf(f, ':SOUR:ROSC:RANG RANG1;:SOUR:ROSC:SOUR INT;:OUTP:ROSC:SOUR SCLK1');
                    fprintf(f, ':OUTP:ROSC:SCD 1');
                    fclose(f);
                end
            end
        else
            errordlg('useM8196ARefClk is only supported with when M8196A is selected');
        end
        % calculate fs and number of symbols
        trigFactor1 = ceil(dataRate / arbConfig.maximumSampleRate * 32);
        trigFactor2 = floor(dataRate / arbConfig.minimumSampleRate * 32);
        fsApprox = dataRate / trigFactor1 * 32;
        if (fsApprox < arbConfig.minimumSampleRate)
            dr1 = trigFactor1 * arbConfig.minimumSampleRate / 32;
            dr2 = trigFactor2 * arbConfig.maximumSampleRate / 32;
            if (abs(dr1 - dataRate) < abs(dr2 - dataRate))
                suggestedDR = dr1;
            else
                suggestedDR = dr2;
            end
            errordlg(sprintf(['This symbol rate can not be generated with the M8196A with RefClkOut being an integer fraction of the symbol rate. ' ...
                'The closest supported data rate is %s GBaud'], iqengprintf(suggestedDR/1e9)));
            return;
        end
        [~, d] = rat(fsApprox / dataRate / arbConfig.segmentGranularity);
        numBits = ceil(numBits / d) * d;
    end
end
% approximate number of samples per bit
spbApprox = fsApprox / dataRate;

if (~ischar(data))    % PTRN or User defined data 
    reqMinBits = ceil(arbConfig.minimumSegmentSize / spbApprox);
    if length(data) < reqMinBits    %% if length is less than required then 
        NoCopies = ceil(reqMinBits/length(data));
        if (iscolumn(data))
            data = repmat(data, NoCopies, 1);
        else
            data = repmat(data, 1, NoCopies);
        end
    end
    maxSymbols = floor(arbConfig.maximumSegmentSize / spbApprox);
    if length(data) > maxSymbols    % if length is exceeded 
        data = data(1:maxSymbols);  % then truncate to adjust the length
    end
    if (numBits ~= length(data))
        if (useM8196RefClk)
            NoCopies = ceil(numBits / length(data));
            if (iscolumn(data))
                data = repmat(data, NoCopies, 1);
            else
                data = repmat(data, 1, NoCopies);
            end
            data = data(1:numBits);
        else
            numBits = length(data);
        end
    end
end

% check if the number of bits is large enough to find a valid sample rate
if (arbConfig.maximumSampleRate == arbConfig.minimumSampleRate)
    factor = 1;
else
    factor = ceil(arbConfig.segmentGranularity / numBits * dataRate / (max(arbConfig.maximumSampleRate) - max(arbConfig.minimumSampleRate)));
end
newFs = round((spbApprox * numBits) / arbConfig.segmentGranularity) * arbConfig.segmentGranularity / numBits * dataRate;
if (factor > 1 && (newFs > max(arbConfig.maximumSampleRate) || newFs < max(arbConfig.minimumSampleRate)))
    if (~ischar(data))
%        errordlg(['waveform too short - adjust number of symbols to at least ' num2str(ceil(arbConfig.minimumSegmentSize * dataRate / max(arbConfig.maximumSampleRate)))]);
        errordlg(['waveform too short - adjust number of symbols to at least ' num2str(numBits*factor)]);
        return;
    end
    numBits = numBits * factor;
end
if (numBits ~= numBitsOld)
    warndlg(['The number of symbols has been adjusted to ' num2str(numBits) ' to match waveform granularity and sample rate limitations']);
end
% calculate the number of samples to match segment granularity
numSamples = round((spbApprox * numBits) / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
% rounding might bring the the sample rate above the maximum
if (numSamples / numBits * dataRate > max(arbConfig.maximumSampleRate))
    numSamples = numSamples - arbConfig.segmentGranularity;
end
% ...or below the minimum
% if (numSamples / numBits * dataRate < max(arbConfig.minimumSampleRate))
%     numSamples = numSamples + arbConfig.segmentGranularity;
% end
if (numSamples < arbConfig.minimumSegmentSize && ~nowarning)
    errordlg(['Waveform too short - adjust number of symbols to at least ' num2str(ceil(arbConfig.minimumSegmentSize * dataRate / max(arbConfig.maximumSampleRate)))]);
    return;
end
if (numSamples > arbConfig.maximumSegmentSize && ~nowarning)
    errordlg(['Waveform too long - adjust number of symbols to less than ' num2str(floor(arbConfig.maximumSegmentSize * dataRate / max(arbConfig.minimumSampleRate)))]);
    return;
end
% calculate exact spb (will likely be NOT an integer value)
spb = numSamples / numBits;
if (sampleRate == 0)
    sampleRate = spb * dataRate;
end

% for large data sets, perform block-wise operation
if (numSamples > 8000000)
    if (~strcmp(filterType, 'Transition Time'))
        errordlg('Block-wise processing of very large waveforms is only implemented with pulse shape set to "Transition Time"');
        return;
    end
    if (ischar(data) && strncmp(data, 'PRBS', 4))
        iseriallarge(arbConfig, dataRate, spb, data, format, fct, filename, correction, rtUI, amplitude, arbConfig.segmentGranularity);
    else
        errordlg('Block-wise processing of very large waveforms is only supported with PRBS patterns');
    end
    return;
end

% use the same sequence every time so that results are comparable
randStream = RandStream('mt19937ar'); 
reset(randStream);

if (ischar(data))
    prbsPoly = [];
    switch(lower(data))
        case 'clock'
            if (mod(numBits, 2) ~= 0)
                errordlg('Clock pattern requires an even number of bits');
            end
            data = repmat([0 1], 1, ceil(numBits / 2));
        case 'random'
            if (strcmp(format, 'NRZ'))
                data = randStream.randi([0 1], 1, numBits);
            else
                data = levels(randStream.randi([1 length(levels)], 1, numBits));
            end
        case 'mlt-3'
            mltCode = [levels(2) levels(1) levels(2) levels(3)];
            data = mltCode(mod(cumsum(randStream.randi([0 1], 1, numBits)), 4) + 1);
        case 'pam3'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam4'
            prbsPoly = [11 9 0];
            format = 'PAM4';
        case 'pam5'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam6'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam7'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam8'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam16'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'prbs2^7-1'
            prbsPoly = [7 1 0];
        case 'prbs2^9-1'
            prbsPoly = [9 4 0];
        case 'prbs2^10-1'
            prbsPoly = [10 3 0];
        case 'prbs2^11-1'
            prbsPoly = [11 2 0];
        case 'prbs2^12-1'
            prbsPoly = [12 11 8 6 0]; % alternative [12 6 4 1 0]
%         case 'prbs2^12-1'
%             prbsPoly = [12 6 4 1 0]; % alternative [12 11 8 6 0]
        case 'prbs2^13-1'
            prbsPoly = [13 12 11 1 0]; % alternative [13 12 10 9 0];
        case 'prbs2^15-1'
            prbsPoly = [15 1 0];
        case 'doublet'
            if (mod(numBits, 2) ~= 0)
                errordlg('Doublet pattern requires an even number of bits');
                return;
            end
            data = randStream.rand(1,ceil(numBits/2)) < 0.5;
            data(2,:) = 1-data(1,:);
            data = data(1:end);
        case 'jp03b'
            data = repmat([repmat([1 0], 1, 15) repmat([0 1], 1, 16)], 1, ceil(numBits/62));
            data = data(1:numBits);
        case 'linearitytestpattern'
            data = levels(repmat([1 2 3 4 1 4 1 4 3 2], 16, ceil(numBits/160)));
            data = data(1:numBits);
        case 'ssprq'
            data = ssprq(numBits, levels);
        case 'qprbs13'
            data = qprbs13(numBits, levels);
        case 'qprbs13 rz'
            if (mod(numBits, 2) ~= 0)
                errordlg('QPRBS13 RZ pattern requires an even number of bits');
            end
            data = qprbs13(ceil(numBits/2), levels);
            data = [data; zeros(1, ceil(numBits/2))];
            data = data(1:numBits);
        case 'qprbs13 r1/2'
            if (mod(numBits, 2) ~= 0)
                errordlg('QPRBS13 R1/2 pattern requires an even number of bits');
            end
            data = qprbs13(ceil(numBits/2), levels);
            data = [data; 0.5 * ones(1, ceil(numBits/2))];
            data = data(1:numBits);
        case 'qprbs13 user defined levels'
            data = qprbs13(numBits, levels);
        case 'dual pam4'
            data1 = floor(4 * randStream.rand(1,numBits)) / 6;
            data2 = floor(4 * randStream.rand(1,numBits)) / 6;
            data = data1 + data2;
        otherwise
            errordlg(['undefined data pattern: ' data]);
            return;
    end
    if (~isempty(prbsPoly))
        if (strcmp(format, 'PAM4'))
            h = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', 2*numBits);
            data = h.generate()';
%            % apply a gray mapping (00 01 11 10)
%            mapping = [0 1 3 2]+1;
%--- gray mapping is now applied by setting the levels to 0  1/3  1  2/3
%--- this makes it more obvious to the user, that we are using gray coding
            mapping = [0 1 2 3]+1;
            data = levels(mapping(2 * data(1:2:end-1) + data(2:2:end) + 1));
        else
            h = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', numBits);
            data = h.generate()';
        end
    end
elseif (isvector(data))
    numBits = length(data);
else
    error('unexpected data type');
end
% make sure the data is in the correct format
if (isvector(data) && size(data,1) > 1)
    data = data.';
end
% shift by the specifed number of symbols
data = circshift(data, symbolShift, 2);
% assign variable in base workspace - mainly for testing purposes
assignin('base', 'data', data);

% apply pre/post-cursors
if (~isempty(preCursor) || (~isempty(postCursor) && ~isequal(postCursor, 1)))
    % make sure pre- and postCursor are row-vectors (same "shape" as data)
    preCursor = reshape(preCursor, 1, length(preCursor));
    postCursor = reshape(postCursor, 1, length(postCursor));
    % Assume linear cursor coefficients --> should sum up to zero
    % Assume the first postCursor to be the main cursor
    if (length(postCursor) >= 1)
        postCursor(1) = postCursor(1) - 1;
    end
    corr = cumsum([preCursor postCursor]);
    if (abs(corr(end)) > 1e-6)
        warndlg('Sum of cursor values should be 1');
    end
    len = length(corr);
    lenpre = length(preCursor);
    lenpost = length(postCursor);
    if (length(data) >= len)
        % prepend and append <len> symbols of data to avoid wrap-around artefacts
        data2 = [zeros(1, len) data(end - len + 1:end) data data(1:len) zeros(1, len)];
        % find transition points
        df = diff(data2);
        % at each transition, apply pre/de-emphasis
        for i = find(df)
            data2(i-lenpre+1:i+lenpost) = data2(i-lenpre+1:i+lenpost) + df(i) * corr;
        end
        % throw away the extra symbols that have been prepended and appended
        data = data2(2*len+1:end-2*len);
    else
        errordlg('data vector is too short to apply pre/postcursors');
    end
end

% convert transition time in number of samples
rt = rtUI * spb;
ft = ftUI * spb;
% define jitter as a function of sample position
SJcycles = round(SJfreq * numBits / dataRate);   % jitter cycles
for i = 1:numSJ
    if (SJpp(i) ~= 0 && SJfreq(i) ~= 0 && SJcycles(i) == 0 && ~nowarning)
         warndlg(sprintf(['Number of symbols is too small for the given SJ frequency of %s Hz.\n\n' ...
             'Please increase the number of symbols to at least %d \nor increase SJ frequency to %s\n'], ...
                iqengprintf(SJfreq(i)), ...
                ceil(dataRate / SJfreq(i)), ...
                iqengprintf(dataRate / numBits, 2)), ...
                'Warning', 'modal');
        SJcycles(i) = 1;
        break;
    end
end
% define SJ and RJ functions. The functions will be called with a vector of
% transition times (in units of samples) and are expected to return the
% deviation in units of samples
switch lower(jitterShape)
    case 'sine'; SJfct = @(x,i) SJpp(i) / 2 * spb * sin(SJcycles(i) * 2*pi*x/numSamples);
    case 'square'; SJfct = @(x,i) SJpp(i) / 2 * spb * (2*mod(floor(SJcycles(i) * 2*x/numSamples), 2)-1);
    case 'ramp'; SJfct = @(x,i) SJpp(i) / 2 * spb * (2*mod(SJcycles(i) * x/numSamples, 1)-1);
    case 'triangle'; SJfct = @(x,i) SJpp(i) / 2 * spb * (2*abs(2*mod(SJcycles(i) * x/numSamples, 1)-1)-1);
    case 'noise'; SJfct = @(x,i) SJpp(i) / 2 * spb * (2*rand(1, length(x))-1);
    otherwise; error('unknown jitter shape: "%s"', jitterShape);
end
RJfct = @(x) RJpp / 2 * spb * (sum(randStream.rand(6,length(x)))/6-0.5)*2;
if (noiseFreq == 0)
    noiseFct = @() noise * (sum(randStream.rand(6,numSamples))/6-0.5)*2;
else
    Ncycles = round(noiseFreq * numBits / dataRate);   % noise cycles
    if (noise ~= 0 && noiseFreq ~= 0 && Ncycles == 0 && ~nowarning)
%         warndlg(['Noise frequency too low for the given number of bits. Minimum is: ' ...
%             iqengprintf(dataRate / numBits) ' Hz'], 'Warning', 'modal');
% let's not complain too much and use a single cycle...
        Ncycles = 1;
    end
    noiseFct = @() noise * sin(Ncycles * 2*pi*(1:numSamples)/numSamples);
end
% the transition function will be called with values between 0 and 1 and is
% expected to return a value between 0 and 1
TTfct = @(x,spb) (cos(pi*(x-1))+1)/2;   % raised cosine shape
%TTfct = @(x,spb) x;   % trapezoidal line

% calculate transition deviation caused by SSC
% assume SSC to have "triangle" shape, centered at dataRate
% sscfct receives vector with values between 0 and 1 as input and returns
% a vector with values between -1 and +1
sscShape = @(x) (2*mod(2*x-1/2,1)-1) .* (2*mod(floor(2*x-1/2),2)-1);      % triangle
%sscShape = @(x) sin(2*pi*x);                                             % sine wave
sscCycles = round(sscFreq * numBits / dataRate);
if (sscDepth ~= 0 && sscFreq ~= 0 && sscCycles == 0 && ~nowarning)
     warndlg(['SSC frequency is too low for the given number of bits. Minimum is: ' iqengprintf(dataRate / numBits) ' Hz'], 'Warning', 'modal');
     sscCycles = 1;
end
% deviation from nominal UI period (in fraction of UI)
perDev = 0.5 * sscDepth * sscShape(sscCycles * (0:numBits)/numBits);
% sum of UI periods
cumDev = cumsum(perDev);

% calculate transition positions (start with first half bit to get the
% complete transition, add 1 because of array indices)
dpos = find(diff([data data(1)]));
ptx = spb * (dpos - 0.5) + 1;
% add jitter to the transition points
pt = ptx + RJfct(ptx);
for i = 1:numSJ
    pt = pt + SJfct(ptx, i);
end
% add SSC
if (sscDepth ~= 0)
    % SSC deviation in number of samples
    sscDev = spb * interp1((0:numBits) *  spb, cumDev, ptx);
    pt = pt + sscDev;
end
% add duty cycle distortion - works for NRZ and PAMn
% method: move the position of rising edge depending on whether the
% direction of voltage change
if (dutyCycle ~= 0.5)
    % extend the data pattern to avoid errors
    datax = [data data(1)];
    % determine which edges are rising edges
    isRisingEdge = (datax(dpos+1) > datax(dpos));
    % move the edge position of rising edges (falling edges stay where they are)
    pt = pt - isRisingEdge * spb * (dutyCycle - 0.5);
end

% now calculate the actual samples
if (strcmp(filterType, 'Transition Time'))
    samples = calcTime(numSamples, numBits, spb, pt, dpos, data, rt, ft, ttProp, TTfct);
else
    samples = calcFilter(numSamples, numBits, spb, pt, dpos, data, filterType, filterBeta, filterNsym);
end

% add ISI
tmp = repmat(samples, 1, 2);
tmp = filter([1-isi 0], [1 -1*isi], tmp);
samples = tmp(numSamples+1:end);

% shift from [0...1] to [-1...+1]
samples = (2*samples - 1);
% add noise
samples = samples + noiseFct();
%
% apply frequency correction
if (correction)
    nowarning = (strcmp(fct, 'clock'));
    [samples, channelMapping] = iqcorrection(samples, sampleRate, 'chMap', channelMapping, 'nowarning', nowarning, 'normalize', normalize);
end
% set range to [-ampl...+ampl]
samples = samples * amplitude;

delete(randStream);


function [samples] = calcTime(numSamples, numBits, spb, pt, dpos, data, rt, ft, ttProp, TTfct)
samples = zeros(1,numSamples);
numPts = length(pt);
pt(numPts + 1) = numSamples + rt;   % add one more point at the end to avoid overflow
dpos(end+1) = 1;                    % dito
k = 1;                              % k counts transitions
lev = data(dpos(1)+1);              % start with the first data value
oldlev = data(1);                   % remember the previous level in transitions
if (lev >= oldlev)                  % next edge is rising or falling
    tt = rt;
else
    tt = ft;
end
% make transition time proportional to level change
if (ttProp)
    tt = abs(lev - oldlev) * tt;
end
i = 1;                              % i counts samples
while i <= numSamples
    if (i <= pt(k)-tt/2)            % before transition
        samples(i) = oldlev;        %   set to current level
        i = i + 1;                  %   and go to next sample
    elseif (i >= pt(k)+tt/2)        % after transition
        k = k + 1;                  %   check next transition (don't increment sample ptr!)
        oldlev = lev;               %   remember previous level
        lev = data(mod(dpos(k),numBits)+1);  %   load new level
        if (lev >= oldlev)         % next edge is rising or falling
            tt = rt;
        else
            tt = ft;
        end
        % make transition time proportional to level change
        if (ttProp)
            tt = abs(lev - oldlev) * tt;
        end
    else                            % during the transition
        m = (i - (pt(k)-tt/2)) / tt;
        samples(i) = oldlev + TTfct(m,spb) * (lev - oldlev);
        i = i + 1;
    end
end
pt(numPts + 1) = [];                % remove temporary transition point



function [samples] = calcFilter(numSamples, numBits, spb, pt, dpos, data, filterType, filterBeta, filterNsym)
filt = [];
filterParams = [];
% for interpolation of the filter kernel
overN = 50;
switch (filterType)
    case 'None'
        filt.Numerator = 1;
    case 'Rectangular'
        filt.Numerator = ones(1, overN) / overN;
    case {'Root Raised Cosine' 'Square Root Raised Cosine' 'RRC'}
        filterType = 'Square Root Raised Cosine';
        filterParams = 'Nsym,Beta';
    case {'Raised Cosine' 'RC'}
        filterType = 'Raised Cosine';
        filterParams = 'Nsym,Beta';
    case 'Gaussian'
        warndlg('Gaussian Filter does not work correctly - please choose another filter type');
        filterParams = 'Nsym,BT';
        if (exist('filterBeta', 'var') && filterBeta ~= 0)
%            % in MATLAB the BT is given as 1/BT
%            filterBeta = 1 / filterBeta;
        end
    otherwise
        error(['unknown filter type: ' filterType]);
end
if (isempty(filt))
    try
        fdes = fdesign.pulseshaping(overN, filterType, filterParams, filterNsym, filterBeta);
        filt = design(fdes);
    catch ex
        errordlg({'Error during filter design. Please verify that' ...
            'you have the "Signal Processing Toolbox" installed' ...
            'MATLAB error message:' ex.message}, 'Error');
    end
end
flt = filt.Numerator * overN;
fltLen = length(flt);
% figure(50); plot(flt, '.-');
% start with end of data pattern for clean wrap around
if (size(data,1) ~= 1)
    error('unexpected data vector');
end
data = [data(end-filterNsym:end) data];
nsmp = floor(spb*filterNsym);
samples = zeros(1,numSamples + 2 * (nsmp+1));
len = length(data);
for i = 1:len
    x = data(i);
    if (x == 0)
        continue;
    end
    pos = (i-1) * spb;
    posi = ceil(pos);
    posf = posi - pos;
    tmp = x * interp1((0:fltLen-1)/overN, flt, (posf:posf+nsmp-1)/spb);
    samples(posi+1:posi+1+nsmp-1) = samples(posi+1:posi+1+nsmp-1) + tmp;
end
nsmp = nsmp + round(nsmp/2);
samples = samples(nsmp+1:nsmp+numSamples);



function data = qprbs13(numBits, levels)
% Matlab script to generate PAM4 QPRBS13 test pattern - Paul Forrest
% Date 2/13/2015
%
% Start with 3 and a bit repetitions of PRBS13 to X^13+X^12+X^2+X+1
% polynomial = 319096 bits. Then take each pair of bits, with 1st bit
% weighted at 2x amplitude of 2nd bit and add to get PAM4 symbol. Divide by
% 3 to normalize all values between 0 and 1 
% (PAM4 levels will be 0, 1/3, 2/3, 1)
% In this using the lane0 seed for the starting values of the shift
% registers in the LFSR model
%
% NOTE the taps used in Matlab are different to the polynomial above
% because Matlab defines the LFSR structure differently :) But these are
% the taps to use the generate the sequence of bits per the standard.

if (~exist('numBits', 'var'))
    numBits = 15548;
end
if (~exist('levels', 'var'))
    levels = [0 1/3 2/3 1];
end
z1 = commsrc.pn('Genpoly', [13 12 11 1 0], 'Initialstates', [0 0 0 0 0 1 0 1 0 1 0 1 1], 'Numbitsout', 8191,'Shift',13);
% generate 1x sequence of PRBS13 per PAM4 standard, this will be 8191 bits 1:8191 of the 31096 bit NRZ pattern
NRZ1 = z1.generate()';
% generate 1x sequence of PRBS13 per PAM4 standard, inverted, this will be 8191 bits 8192:16382 of the 31096 bit NRZ pattern
NRZ2 = 1 - z1.generate()';
% generate 1x sequence of PRBS13 per PAM4 standard, this will be 8191 bits 16383:24573 of the 31096 bit NRZ pattern
NRZ3 = z1.generate()';
%generate 1x truncated sequence of PRBS13 per PAM4 standard, inverted, this will be 6523 bits 24574:31096 of the 31096 bit NRZ pattern
NRZ4 = 1 - z1.generate()';
% add the segments together to get complete NRZ version of the QBPRS13
NRZ = [NRZ1 NRZ2 NRZ3 NRZ4(1:6523)];
% take pairs of bits, weight and add
data = levels(2*NRZ(1:2:end) + NRZ(2:2:end) + 1);
% adjust length to numBits (in case numBits is not equal to 15548)
data = repmat(data, 1, ceil(numBits / 15548));
data = data(1:numBits);


function mdata = ssprq(numBits, levels)
% generate SSPRQ pattern 
% according to http://www.ieee802.org/3/bs/public/adhoc/logic/oct27_16/anslow_02a_1016_logic.pdf
% verified against: http://www.ieee802.org/3/bs/public/adhoc/smf/16_04_19/anslow_03_0416_smf.csv 
%a = csvread('c:\temp\SSPRQ\anslow_03_0416_smf.csv')';
prbsPoly = [31 3 0];
% generate partial PRBS 31 sequences with defined seed
seed = double(dec2binvec(hex2dec('00000002'), 31));
prbs = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', 10924, 'InitialStates', seed(1:31));
data = prbs.generate();
seed = double(dec2binvec(hex2dec('34013FF7'), 31));
prbs = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', 10922, 'InitialStates', seed(1:31));
data = [data; prbs.generate()];
seed = double(dec2binvec(hex2dec('0CCCCCCC'), 31));
prbs = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', 10922, 'InitialStates', seed(1:31));
data = [data; prbs.generate()];

% PAM4: out = 3 - in  --> flip odd bits in binary data
datax = mod(data + repmat([1; 0], length(data)/2, 1), 2);
% append flipped data to original data
data2 = [data; datax];
% second sequence with first and last binary bit removed
% in order to match the data in the CSV from Anslow, last chunk must be inverted, don't know why
data = [data2; data(2:end-1); 1-data(end); 1-datax(1:end-1)];
%            % apply a gray mapping (00 01 11 10)
%            mapping = [0 1 3 2]+1;
%--- gray mapping is now applied by setting the levels to 0  1/3  1  2/3
%--- this makes it more obvious to the user, that we are using gray coding
mapping = [0 1 2 3]+1;
mdata = levels(mapping(2 * data(1:2:end-1) + data(2:2:end) + 1));
% adjust length to numBits (in case numBits is not equal to 65535)
mdata = repmat(mdata, 1, ceil(numBits / 65535));
mdata = mdata(1:numBits);


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);

