function varargout = iqpulse(varargin)
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
    iqpulse_gui;
    return;
end
% assign default parameters
sampleRate = 8e9;
pri = 6e-6;
pw = 2e-6;
riseTime = 0;
fallTime = 0;
delay = 0;
phase = 0;
pulseShape = 'Raised Cosine';
amplitude = 0;
span = 1e9;
offset = 0;
chirpType = 'Increasing';
fmFormula = 'cos(pi*(x-1))';
pmFormula = 'zeros(1,length(x))';
correction = 0;
arbConfig = [];
normalize = 1;
customIQPulse = []; %WYCHOCK If we want to add custom IQ to a pulse
exactpri = false; %WYCHOCK If we want the exact PRI
channelMapping = [1 0; 0 1]; % channel mapping needed for applying corrections
continuousPhase = 'coherent'; %WYCHOCK If we want to set rules for phase changes on multiple dwells (FMCW vs. PSK)
timeOffset = 0;  % WYCHOCK If we want to merge multiple pulses adding time
phaseOffset = 0;  % WYCHOCK If we want to merge multiple pulses adding phase

for i = 1:2:nargin
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';   sampleRate = varargin{i+1};
            case 'pri';          pri = varargin{i+1};
            case 'pw';           pw = varargin{i+1};
            case 'risetime';     riseTime = varargin{i+1};
            case 'falltime';     fallTime = varargin{i+1};
            case 'delay';        delay = varargin{i+1};
            case 'phase';        phase = varargin{i+1};
            case 'pulseshape';   pulseShape = varargin{i+1};
            case 'fmformula';    fmFormula = varargin{i+1};
            case 'pmformula';    pmFormula = varargin{i+1};
            case 'amplitude';    amplitude = varargin{i+1};
            case 'span';         span = varargin{i+1};
            case 'offset';       offset = varargin{i+1};
            case 'chirptype';    chirpType = varargin{i+1};
            case 'modulationtype';chirpType = varargin{i+1};
            case 'correction';   correction = varargin{i+1};
            case 'normalize';    normalize = varargin{i+1};
            case 'arbconfig';    arbConfig = varargin{i+1};
            case 'customiqpulse'; customIQPulse = varargin{i+1};
            case 'exactpri';    exactpri = varargin{i+1};
            case 'channelmapping'; channelMapping = varargin{i+1};
            case 'continuousphase'; continuousPhase = varargin{i+1};
            case 'timeoffset'; timeOffset = varargin{i+1};
            case 'phaseoffset'; phaseOffset = varargin{i+1};
            otherwise
                error(['unexpected argument: ' varargin{i}]);
        end
    end
end

arbConfig = loadArbConfig(arbConfig);
% number of pulses to generate = length of longest parameter vector
numPulse = max([length(pri) length(delay) length(phase) length(pw) length(riseTime) length(fallTime) length(span) length(offset) length(amplitude)]);
% extend all the other parameter vectors to match the number of pulses
pri = fixlength(pri, numPulse);
pw  = fixlength(pw, numPulse);
riseTime = fixlength(riseTime, numPulse);
fallTime = fixlength(fallTime, numPulse);
delay = fixlength(delay, numPulse);
phase = fixlength(phase, numPulse);
span = fixlength(span, numPulse);
offset = fixlength(offset, numPulse);
amplitude = fixlength(amplitude, numPulse);

if ~iscell(continuousPhase)
    continuousPhase = {continuousPhase};
end
continuousPhase = fixlength(continuousPhase, numPulse);

if ~iscell(chirpType)
    chirpType = {chirpType};
end
chirpType = fixlength(chirpType, numPulse);

% make sure the total number of samples is a multiple of the granularity
% this simplifies the situation in a demo application like this
[pri, numSamples, numRepeats] = checkGranularity(pri, delay, pw, riseTime, fallTime, sampleRate, arbConfig, exactpri);
% Calculate the pulse envelope
[envelope, envelopeStarts, envelopeStops] = calcPulseShape(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, pulseShape, amplitude);
if (strcmpi(chirpType{1}, 'FMCW'))
    envelope = ones(size(envelope));
end
% handle custom IQ differently
if (strcmpi(chirpType{1}, 'custom IQ'))
    
    iqdata = calcCustomIQ(numSamples, sampleRate, pri, customIQPulse, envelope, offset, phase, envelopeStarts, envelopeStops);
%     assignin('base', 'sampleRate', sampleRate);         % allow the formula use current sampleRate
%     iqdata = evalin('base', ['[' customIQPulse ']']);
%     iqdata = reshape(iqdata, 1, length(iqdata));        % make sure it has the right shape
%     iqdata = repmat(iqdata, 1, ceil(length(envelope)/length(iqdata)));
%     iqdata = iqdata(1:length(envelope));
%     iqdata = iqdata .* exp(1i * 2 * pi * (1:length(envelope)) * offset(1) / sampleRate);
%     iqdata = envelope .* iqdata;
else
    [sig, mag] = calcPhase(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, ...
        phase, span, offset, chirpType, pulseShape, fmFormula, pmFormula,...
        correction, continuousPhase, timeOffset, phaseOffset);
    iqdata = envelope .* exp(1i * sig);
    
    % if the double math adds another sample, remove it from the iqdata
    if length(iqdata) > length(mag)
        iqdata = iqdata(1:length(iqdata)-1);
    end
    iqdata = power(10,(mag/20)) .* iqdata;
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


function [pri, numSamples, numRepeats] = checkGranularity(pri, delay, pw, riseTime, fallTime, sampleRate, arbConfig, exactpri)
% check that the total length matches the required segment granularity.
% if necessary adjust PRI's by stretching them equally
% In a real application, this has to be solved changing the delay of
% subsequent pulses - but this is not possible here
    numRepeats = 0;
    offTime = pri - delay - pw - riseTime - fallTime;
    if (min(offTime) < 0)  % Wychock: Double handling
        % If PRI is set to zero, don't complain and silently make it equal to delay+rise+pw+fall 
        if (min(offTime) < -1.0e-18) && (pri(1) ~= 0)
            errordlg('delay + pulse width + risetime + falltime > repeat interval');
        end
        % set PRI to at least the sum of delay+pw+rise+fall
        tmp = delay + pw + riseTime + fallTime;
        pri(offTime < 0) = tmp(offTime < 0);
    end
    % round pri to full ps to reduce the chance of floating point rounding errors
    spri = round(sum(pri) * 1e12);
    numSamples = ceil(spri * sampleRate / 1e12);
   
    % round PRI's to match the segment granularity
    % always round UP, to avoid negative off-times
    modval = mod(numSamples, arbConfig.segmentGranularity);
    if (modval ~= 0)
        %WYCHOCK If we want to get the PRI to be EXACT, try to get the LCM of the
        %granularity and PRI and see if we can repeat it
        if exactpri && lcm(numSamples, arbConfig.segmentGranularity) < arbConfig.maximumSegmentSize/2
            numRepeats = lcm(numSamples, arbConfig.segmentGranularity)/numSamples;
        else            
            corr = arbConfig.segmentGranularity - modval;
            
            % WYCHOCK only add samples to the last PRI if array of them
            pri(end) = pri(end) .* (corr + numSamples) / numSamples;
            % note the use of round() here to avoid a "jump" to the next integer
            numSamples = round(sum(pri) * sampleRate / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
        end
    end
end


function [envelope envelopeStarts envelopeStops] = calcPulseShape(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, pulseShape, amplitude)
% calculate the pulse envelope
    envelope = zeros(1, numSamples);
    envelopeStarts = zeros(1, length(pri));
    envelopeStops = zeros(1, length(pri));
    
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
        ridx = (ih(1):ih(2)-1);
        pidx = (ih(2):ih(3)-1);
        fidx = (ih(3):ih(4)-1);
        
        envelopeStarts(i) = ih(2);
        envelopeStops(i) = ih(3);
        
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


function [pm, mag] = calcPhase(numSamples, pri, delay, riseTime, pw, fallTime, ...
    sampleRate, phase, span, offset, chirpType, pulseShape, fmFormula, pmFormula,...
    correction, continuousPhase, timeOffset, phaseOffset)
% calculate the phase based on span and offset
    mag = zeros(1, numSamples);
    fm = zeros(1, numSamples);
    pm = zeros(1, numSamples);
    try
        eval(['fm_fct = @(x,i) ' fmFormula ';']);
        eval(['pm_fct = @(x,i) ' pmFormula ';']);
    catch ex
        errordlg(ex.message);
    end
    priSoFar = 0;
    for i = 1:length(pri)
        % t(1) and t(2) point to start and end of pulse on-time
        % for FMCW, pulse is on during the whole PRI
        if (strcmpi(chirpType{i}, 'fmcw'))
            t(1) = priSoFar;
            t(2) = t(1) + pri(i);
        else
            t(1) = priSoFar + delay(i);
            t(2) = t(1) + riseTime(i) + pw(i) + fallTime(i);
        end
        ih = ceil(t * sampleRate);
        % index for pulse
        pidx = (ih(1):ih(2)-1);
        
        % Deal with a no time
        if isempty(pidx)
            break;
        end
        
        pr = (pidx ./ sampleRate - t(1)) / (t(2) - t(1));
        fm_on = zeros(1, length(pr));
        pm_on = zeros(1, length(pr));
        switch lower(chirpType{i})
            case 'none'
                % nothing to do - use the default
            case 'increasing'
                fm_on = 2 * pr - 1;
            case 'decreasing'
                fm_on = 1 - 2 * pr;
            case 'v-shape'
                fm_on = 2*abs(2 * pr - 1) - 1;
            case 'inverted v'
                fm_on = -2*abs(2 * pr - 1) + 1;
            case 'barker-2 +-'
                tmp = [+1 -1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 2), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'barker-2 ++'
                tmp = [+1 +1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 2), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'barker-3'
                tmp = [+1 +1 -1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 3), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'barker-4 ++-+'
                tmp = [+1 +1 -1 +1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 4), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'barker-4 +++-'
                tmp = [+1 +1 +1 -1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 4), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'barker-5'
                tmp = [+1 +1 +1 -1 +1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 5), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'barker-7'
                tmp = [+1 +1 +1 -1 -1 +1 -1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 7), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'barker-11'
                tmp = [+1 +1 +1 -1 -1 -1 +1 -1 -1 +1 -1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 11), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'barker-13'
                tmp = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 13), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'frank-4'
                n = 4;
                tmp = (0:n-1)' * (0:n-1); % from http://www.radartutorial.eu/08.transmitters/Frank%20Code.en.html
                tmp = tmp(1:end);
                tmp = repmat(tmp, ceil(length(pr) / (n^2)), 1);
                pm_on = 360 / n * tmp(1:length(pr));
            case 'frank-6'
                n = 6;
                tmp = (0:n-1)' * (0:n-1); % from http://www.radartutorial.eu/08.transmitters/Frank%20Code.en.html
                tmp = tmp(1:end);
                tmp = repmat(tmp, ceil(length(pr) / (n^2)), 1);
                pm_on = 360 / n * tmp(1:length(pr));
            case 'fmcw'
                % determine delay, rise, fall, PW relative to PRI
                rDelay = delay ./ pri;
                rRise = riseTime ./ pri;
                rFall = fallTime ./ pri;
                rPW = pw ./ pri;
                fm_on = zeros(size(pr));
                % before and after the pulse
                idx = (pr <= rDelay(i) | pr > (rDelay(i)+rRise(i)+rPW(i)+rFall(i)));
                fm_on(idx) = -1;
                % during rise time
                idx = (pr > rDelay(i) & pr <= rDelay(i)+rRise(i));
                fm_on(idx) = (pr(idx)-rDelay(i))/rRise(i)*2-1;
                % during pulse width
                idx = (pr > rDelay(i)+rRise(i) & pr <= (rDelay(i)+rRise(i)+rPW(i)));
                fm_on(idx) = 1;
                % during fall time
                idx = (pr > (rDelay(i)+rRise(i)+rPW(i)) & pr <= (rDelay(i)+rRise(i)+rPW(i)+rFall(i)));
                fm_on(idx) = (pr(idx)-rDelay(i)-rRise(i)-rPW(i))/rFall(i)*-2+1;
                switch lower(pulseShape)
                    case 'raised cosine'
                        fm_on = sin(fm_on * pi / 2);
                    case 'trapezodial'
                        % leave it as is
                    case 'zero signal during rise time'
                        fm_on(fm_on ~= -1 & fm_on ~= 1) = 0;
                    otherwise
                        error(['undefined pulse shape: ' pulseShape]);
                end
            case 'user defined'
                x = pr;
                try
                    fm_on = fixlength(fm_fct(x,i),length(pr));
                    pm_on = fixlength(pm_fct(x,i),length(pr));
                catch ex
                    errordlg(ex.message);
                end
            otherwise
                error('undefined chirp type');
        end
        % scale frequency modulation to +/- span/2 and shift by center frequency
        fmTmp = (span(i)/2 * fm_on) + offset(i);
        % store frequency for amplitude correction
        fm(pidx+1) = fmTmp;
        % convert FM to PM  (in units of rad/(2*pi))
        pmTmp = cumsum(fmTmp) / sampleRate;
        % initial phase need to reflect the offset of the first sample from
        % the "ideal" pulse starting point
        dT = pidx(1) / sampleRate - t(1);   % delta time
        pOffset = phase(i)/360 + fmTmp(1) * dT;   % corrected phase
        
        % add the modifier if there's an initial time
        phaseAccum = 0;
        if ~fmTmp(1) == 0
            phaseAccum = 1 / fmTmp(1) * timeOffset; 
        end
        
        % add FM, PM and initial phase, with switching options
        % add just a simple trend fit for now...
        switch lower(continuousPhase{i})
            case 'coherent'  % coherent phase...treat as default
                phaseAdd = 2 * pi * (pmTmp + pm_on/360 + pOffset + phaseOffset) + phaseAccum; 
            case 'continuous'  % continuous phase...try to stitch previous and next phases and add a relative phase bump
                phaseAdd = 2 * pi * (pmTmp + pm_on/360 + pOffset + phaseOffset) + phaseAccum; 
                if i > 1                    
                    % add the offset to stitch if there's any errors
                    phaseMerge = (pm(max(pidx) + 1 - length(pr)) - phaseAdd(1));
                    
                    % Get the last two and get linear next fit
                    try
                        phaseSlope = (pm(max(pidx) + 1 - length(pr))) - (pm(max(pidx) - length(pr)));
                        phaseMerge = (pm(max(pidx) + 1 - length(pr)) + phaseSlope - phaseAdd(1)); 
                    catch
                        phaseMerge = (pm(max(pidx) + 1 - length(pr)) - phaseAdd(1));
                    end           
                    
                    % add the last phase bump with relative
                    phaseAdd = phaseAdd + phaseMerge + 2 * pi * (phase(i)-phase(i-1))/360;
                else
                    phaseAdd = phaseAdd + 2 * pi * (phase(i))/360; 
                end
            case 'exact'  % try to set the initial phase to be exactly relative to the phase called out at start
                phaseAdd = 2 * pi * (pmTmp + pm_on/360 + pOffset + phaseOffset) + phaseAccum; 
                phaseAdd = phaseAdd - (phaseAdd(1) +  2 * pi * phase(i)/360); 
                
            case 'bump'  % continuous phase...try to stitch previous and next phases and add a absolute phase bump
                phaseAdd = 2 * pi * (pmTmp + pm_on/360 + pOffset + phaseOffset) + phaseAccum; 
                if i > 1                    
                    % add the offset to stitch if there's any errors
                    phaseMerge = (pm(max(pidx) + 1 - length(pr)) - phaseAdd(1));
                    
                    % Get the last two and get linear next fit
                    try
                        phaseSlope = (pm(max(pidx) + 1 - length(pr))) - (pm(max(pidx) - length(pr)));
                        phaseMerge = (pm(max(pidx) + 1 - length(pr)) + phaseSlope - phaseAdd(1)); 
                    catch
                        phaseMerge = (pm(max(pidx) + 1 - length(pr)) - phaseAdd(1));
                    end           
                    
                    % add the last phase bump with absolute
                    phaseAdd = phaseAdd + phaseMerge + 2 * pi * (phase(i))/360;                  
                else
                    phaseAdd = phaseAdd + 2 * pi * (phase(i))/360;    
                end
            otherwise
                phaseAdd = 2 * pi * (pmTmp + pm_on/360 + pOffset + phaseOffset) + phaseAccum;          
        end
        
        pm(pidx+1) = phaseAdd;
        priSoFar = priSoFar + pri(i);
        
    end %for
end

function iqdata = calcCustomIQ(numSamples, sampleRate, pri, customIQPulse, envelope, offset, phase, envelopeStarts, envelopeStops)

    iqdata = zeros(1, numSamples);
    assignin('base', 'sampleRate', sampleRate);         % allow the formula use current sampleRate
    iqdataCalc = evalin('base', ['[' customIQPulse ']']);
    iqdataCalc = reshape(iqdataCalc, 1, length(iqdataCalc));        % make sure it has the right shape
    iqdataCalc = repmat(iqdataCalc, 1, ceil(length(envelope)/length(iqdataCalc)));
    
    % For each envelope, inject into the respective item, maintaining phase
    % as well
    for i = 1:length(pri)
    
        % Also add the phase offsets and frequency tracking phase
        % initial phase need to reflect the offset of the first sample from
        % the "ideal" pulse starting point
        dT = envelopeStarts(i) / sampleRate;   % delta time
        pOffset = phase(i)/360 + offset(i) * dT;   % corrected phase
        
        iqdataInject = iqdataCalc(1:(envelopeStops(i) - envelopeStarts(i) + 1));
        iqdataInject = iqdataInject .* exp(1i * (2 * pi * (1:length(iqdataInject)) * offset(i) / sampleRate + pOffset));
                     
        iqdata(envelopeStarts(i):envelopeStops(i)) = envelope(envelopeStarts(i):envelopeStops(i)) .* iqdataInject;

    end

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
