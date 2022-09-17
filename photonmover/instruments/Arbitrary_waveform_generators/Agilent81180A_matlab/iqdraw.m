function varargout = iqdraw(varargin)
% Generate I/Q samples for a pulse with given parameters.
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sampleRate in Hz
% 'PRI' - pulse repetition interval in seconds (can be scalar or vector)
% 'PW' - pulse width in seconds (can be a scalar or vector)
% 'riseTime' - rise time in seconds (can be a scalar or vector)
% 'fallTime' - fall time in seconds (can be a scalar or vector)
% 'delay' - initial delay before the pulse starts (scalar or vector)
% 'phase' - initial phase in degrees
% 'pulseShape' - pulse shape ('Raised Cosine', 'Trapezodial', 'Zero signal during rise time')
% 'amplitude' - relative amplitude in dB (scalar or vector)
% 'span' - frequency span for the chirp (can be scalar or vector)
% 'offset' - frequency offset (can be scalar or vector)
% 'modulationType' - the type of modulation on pulse ('None','Increasing','Decreasing','V-shape',
%                     'Inverted V','Barker-11','Barker-13','User defined')
% 'fmFormula' - formula for FM of the i-th pulse as a function of vector x
% 'pmFormula' - formula for PM of the i-th pulse as a function of vector x
% 'correction' - 1: perform correction, 0:no correction (default)
% 'normalize' - 1:normalize output vector, 0:leave as is
% 'customIQPulse' - use this waveform as the modulation on pulse
% 'exactPRI' - if set to false, will round PRI to match segment granularity (default)
%              if set to true, will attempt to repeat pulses to make PRI exact
%
% 'continuousphase' - phase changing rules for multiple dwells
% 'phaseoffset' - offset phase in degrees for combining
% 'timeOffset' - offset time in seconds for combining
%
% If 'iqpulse' is called without arguments, opens a graphical user interface
% to specify parameters
%
% T.Dippon, Agilent Technologies 2011-2013, Keysight Technologies 2014-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

if (nargin == 0)
    iqdraw_gui;
    return;
end
% assign default parameters
sampleRate = 8e9;
% pri = 6e-6;
% amplitude = 0;
offset = 0;
correction = 0;
arbConfig = [];
normalize = 0;
% exactpri = false; %WYCHOCK If we want the exact PRI
channelMapping = [1 0; 0 1]; % channel mapping needed for applying corrections

timeDrawAmp = [];
ampDraw = [];

timeDrawPhase = [];
phaseDraw = [];

timeDrawFreq = [];
freqDraw = [];
customIQPulse = [];

for i = 1:2:nargin
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';   sampleRate = varargin{i+1};
            case 'offset';       offset = varargin{i+1};
            case 'correction';   correction = varargin{i+1};
            case 'normalize';    normalize = varargin{i+1};
            case 'amplitude';    amplitude = varargin{i+1};
            case 'arbconfig';    arbConfig = varargin{i+1};
            case 'channelmapping'; channelMapping = varargin{i+1};
            case 'timedrawamp'; timeDrawAmp = varargin{i+1};
            case 'timedrawphase'; timeDrawPhase = varargin{i+1};
            case 'timedrawfreq'; timeDrawFreq = varargin{i+1};
            case 'ampdraw'; ampDraw = varargin{i+1};
            case 'phasedraw'; phaseDraw = varargin{i+1};
            case 'freqdraw'; freqDraw = varargin{i+1};
            case 'customiqpulse'; customIQPulse = varargin{i+1};
            otherwise
                error(['unexpected argument: ' varargin{i}]);
        end
    end
end

arbConfig = loadArbConfig(arbConfig);
numPulse = 1;
% number of pulses to generate = length of longest parameter vector
% numPulse = max([length(pri) length(offset) length(amplitude)]);
% extend all the other parameter vectors to match the number of pulses
% pri = fixlength(pri, numPulse);
offset = fixlength(offset, numPulse);
% amplitude = fixlength(amplitude, numPulse);

% make sure the total number of samples is a multiple of the granularity
% this simplifies the situation in a demo application like this
[timeDrawAmp, numSamples, numRepeats] = checkGranularity(timeDrawAmp, sampleRate, arbConfig);
[timeInterp, ampDraw, phaseDraw, freqDraw] = forceDraw(numSamples, sampleRate, timeDrawAmp, ampDraw, timeDrawPhase, phaseDraw, timeDrawFreq, freqDraw);

% Calculate the pulse envelope
envelope = ampDraw;

if isempty (customIQPulse)    
    [sig, mag] = calcPhase(numSamples, sampleRate, offset, correction, phaseDraw, freqDraw);
    iqdata = power(10,(envelope/20)) .* exp(1i * sig);
    
    % if the double math adds another sample, remove it from the iqdata
    if length(iqdata) > length(mag)
        iqdata = iqdata(1:length(iqdata)-1);
end
else
    iqdata = zeros(1, numSamples);
    assignin('base', 'sampleRate', sampleRate);         % allow the formula use current sampleRate
    iqdataCalc = evalin('base', ['[' customIQPulse ']']);
    iqdataCalc = reshape(iqdataCalc, 1, length(iqdataCalc));        % make sure it has the right shape
    
    % Make the magnitudes from the envelope, everyting else from the phase
    iqdata = power(10,(envelope/20)) .* exp(1i * angle(iqdataCalc(1:length(envelope))));
end

% make sure we always return a colummn-vector
iqdata = reshape(iqdata, numel(iqdata), 1);

% create a marker with the shape of the envelope
marker = 15 * (envelope ~= 0);

% apply correction if requested
if (correction)
    [iqdata, channelMapping] = iqcorrection(iqdata, sampleRate, 'chMap', channelMapping);
end
%         if (isfield(acs, 'absMagnitude') && max(max(max(abs(real(iqdata)), abs(imag(iqdata))))) > 0)
%             warndlg(sprintf(['Absolute Magnitude can''t be achieved. ' ...
%                 'Please increase Magnitude Shift in Correction Management window ' ...
%                 'by at least %.1f dB.'], max(mag)), 'Warning', 'replace');
%         end

% check for NaN
nanCatch = find(isnan(iqdata));

for nanIdx = 1:length(nanCatch)
    
    if nanCatch(nanIdx) > 1
        iqdata(nanCatch(nanIdx)) = iqdata(nanCatch(nanIdx) - 1);
    else
        iqdata(nanCatch(nanIdx)) = 1;
    end
end

% normalize amplitude
if (normalize)
    scale = max(max(max(abs(real(iqdata))), max(abs(imag(iqdata)))));
    
    % Deal with no scale
    if scale ~= 0    
        iqdata = iqdata / scale;
    end
end

%Wychock
if (numRepeats > 1)
    iqdata = repmat(iqdata, numRepeats, 1);
    marker = repmat(marker, numRepeats, 1);
end


if (nargout >= 1)
    varargout{1} = iqdata;
end
if (nargout >= 2)
    varargout{2} = marker;
end
if (nargout >= 3) %WYCHOCK Output the number of repeats for sequencing purposes
    varargout{3} = numRepeats;
end
if (nargout >= 4)
    varargout{4} = channelMapping;
end

end

function [timeInterp, ampDraw, phaseDraw, freqDraw] = forceDraw(numSamples, sampleRate, timeDrawAmp, ampDraw, timeDrawPhase, phaseDraw, timeDrawFreq, freqDraw)
% Interpolate and force the draw inputs to match the dwell

    timeInterp = (0:(numSamples - 1)) / sampleRate;

    if isempty(ampDraw)
        ampDraw = zeros(1, numSamples);
    else
        [timeDrawAmp, ampDraw] = eliminateDuplicates(timeDrawAmp, ampDraw);
        ampDraw = interp1(timeDrawAmp,ampDraw,timeInterp);
    end
    
    if isempty(phaseDraw)
        phaseDraw = zeros(1, numSamples);
    else
        [timeDrawPhase, phaseDraw] = eliminateDuplicates(timeDrawPhase, phaseDraw);
        phaseDraw = interp1(timeDrawPhase,phaseDraw,timeInterp);
    end
    
    if isempty(freqDraw)
        freqDraw = zeros(1, numSamples);
    else
        [timeDrawFreq, freqDraw] = eliminateDuplicates(timeDrawFreq, freqDraw);
        freqDraw = interp1(timeDrawFreq,freqDraw,timeInterp);
    end

end

function [arrayFixTime, arrayFixData] = eliminateDuplicates(arrayFixTime, arrayFixData)
    
    % Check the size of the unique and nn uniques
    uniqueDifference = length(arrayFixTime) - length(unique(arrayFixTime));

    % Remove duplicates, assuming one might occur repeatdly or out of order
    if uniqueDifference > 0
        uniqueIdxRemove = [];        
        uniqueCheck = arrayFixTime(1);
        uniquePrevious =  arrayFixTime(1);
        for idx = 1:(length(arrayFixTime) - 1)
            uniqueCheck = arrayFixTime(idx);
            if uniqueCheck == arrayFixTime(idx + 1) || uniqueCheck < uniquePrevious
                uniqueIdxRemove = [uniqueIdxRemove idx];
            end   
            uniquePrevious = arrayFixTime(idx);
        end

        arrayFixTime(uniqueIdxRemove) = [];
        arrayFixData(uniqueIdxRemove) = [];    
    end
    
    % Handle a possible difference of elements
    arrayFixTimeDifference = length(arrayFixTime) - length(arrayFixData);
    if arrayFixTimeDifference > 0
        for idx = 1:arrayFixTimeDifference
            arrayFixData = [arrayFixData arrayFixData(end)];
        end
    elseif arrayFixTimeDifference < 0
        arrayFixData = arrayFixData(1:(end + arrayFixTimeDifference));
    end
end

function [timeDraw, numSamples, numRepeats] = checkGranularity(timeDraw, sampleRate, arbConfig)
% check that the total length matches the required segment granularity.
% if necessary adjust PRI's by stretching them equally
% In a real application, this has to be solved changing the delay of
% subsequent pulses - but this is not possible here
    
    numRepeats = 0;

    % round pri to full ps to reduce the chance of floating point rounding errors
    spri = round(timeDraw(end) * 1e12);
    numSamples = ceil(spri * sampleRate / 1e12);
   
    % round PRI's to match the segment granularity
    % always round UP, to avoid negative off-times
    modval = mod(numSamples, arbConfig.segmentGranularity);
    if (modval ~= 0)
        corr = arbConfig.segmentGranularity - modval;

        % WYCHOCK only add samples to the last PRI if array of them
        timeDraw = [timeDraw timeDraw(end) .* (corr + numSamples) / numSamples];
        % note the use of round() here to avoid a "jump" to the next integer
        numSamples = round(timeDraw(end) * sampleRate / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
    end
end


function envelope = calcPulseShape(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, pulseShape, amplitude)
% calculate the pulse envelope
    envelope = zeros(1, numSamples);
    % remember where we are in time at the beginning of the pulse
    priSoFar = 0;
    % create the envelope for each pulse in turn
    for i = 1:length(pri)
        linamp = 10^(amplitude(i)/20);
        % points in time on the pulse
        t(1) = priSoFar + delay(i);
        t(2) = t(1) + riseTime(i);
        t(3) = t(2) + pw(i);
        t(4) = t(3) + fallTime(i);
        ih = ceil(t * sampleRate);
        % index range of rise, pulse and fall times
        ridx = (ih(1):ih(2)-1);sampleRate
        pidx = (ih(2):ih(3)-1);
        fidx = (ih(3):ih(4)-1);
        % arguments for rise and falltime, scaled to [0...1] interval
        if (t(2) > t(1))    % avoid division by zero
            rr = (ridx ./ sampleRate - t(1)) / (t(2) - t(1));
        else
            rr = [];
        end
        if (t(4) > t(3))
            fr = (fidx ./ sampleRate - t(3)) / (t(4) - t(3));
        else
            fr = [];
        end
        switch lower(pulseShape)
            case 'raised cosine'
                rise_wave = (cos(pi * (rr - 1)) + 1) / 2;
                fall_wave = (cos(pi * (fr)) + 1) / 2;
            case 'trapezodial'
                rise_wave = rr;
                fall_wave = 1 - fr;
            case 'gaussian'
                alpha = 5;
                gauss = gausswin(2*length(rr), alpha)';
                rise_wave = gauss(1:length(rr));
                gauss = gausswin(2*length(fr), alpha)';
                fall_wave = gauss(length(fr)+1:end);
            case 'zero signal during rise time'
                rise_wave = zeros(1, length(rr));
                fall_wave = zeros(1, length(fr));
            otherwise
                error(['undefined pulse shape: ' pulseShape]);
        end
        if (~isempty(rr))
            envelope(ridx+1) = linamp .* rise_wave;
        end
        envelope(pidx+1) = linamp;
        
        if (riseTime(i) == 0 && pidx(1) > 0)
            envelope(pidx(1)) = linamp;
        end
        
        if (~isempty(fr))
            envelope(fidx+1) = linamp .* fall_wave;
        end
        priSoFar = priSoFar + pri(i);
    end
end


function [pm, mag] = calcPhase(numSamples, sampleRate, offset, correction, phaseDraw, freqDraw)
% calculate the phase based on span and offset
    mag = zeros(1, numSamples);
    fm = zeros(1, numSamples);
    pm = zeros(1, numSamples);

%     fm_on = zeros(1, numSamples);
%     pm_on = zeros(1, numSamples);

    % scale frequency modulation to +/- span/2 and shift by center frequency
    fmTmp = freqDraw + offset(1);

    % convert FM to PM  (in units of rad/(2*pi))
    pmTmp = cumsum(fmTmp) / sampleRate;
    dT = 0;
    pOffset = fmTmp * dT;   % corrected phase

    % add the modifier if there's an initial time
    phaseAccum = 0;

    phaseAdd = 2 * pi * (pmTmp + phaseDraw / 360 + phaseAccum); 

    pm = phaseAdd;
    
end


function [mag, pm] = applyFFTcorr(fm, fs, freq, cplxCorr, mag, pm)
    % if we don't have negative frequencies, mirror them
    if (min(freq) >= 0)
        if (freq(1) == 0)            % don't duplicate zero-frequency
            startIdx = 2;
        else
            startIdx = 1;
        end
        freq = [-1 * flipud(freq); freq(startIdx:end)];
        cplxCorr = [conj(flipud(cplxCorr)); cplxCorr(startIdx:end,:)]; % negative side must use complex conjugate
    end
    % interpolate the correction curve to match the data
    corrLin = interp1(freq, cplxCorr, fm, 'linear', 1);
    % convert to dB
    mag = mag + 20*log10(abs(corrLin));
    phdelta = unwrap(angle(corrLin));
    pm = pm + phdelta;
end


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
end
