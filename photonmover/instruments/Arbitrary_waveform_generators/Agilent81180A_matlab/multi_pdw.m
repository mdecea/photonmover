function [totalSamples, amplitudeModifierDB, timeModifierS, iqData] = multi_pdw(varargin)
    % Set up multiple pulses on IQTools instruments purely in IQ
    % 'sampleRate' - the sample rate that will be used by the AWG
    % 'pulseTable' - struct array that describes the desired pulses.
    %                each struct element is expected to have the following
    %                fields (that align with the iqpulse method):
    %                  'startTime'
    %                  'basePower'
    %                  'transitionType'
    %                  'sampleRate'
    %                  'PRI'
    %                  'PW'
    %                  'riseTime'
    %                  'fallTime'
    %                  'pulseShape'
    %                  'span'
    %                  'offset'
    %                  'amplitude'
    %                  'fmFormula'
    %                  'pmFormula'
    %                  'exactPRI'
    %                  'modulationType'
    %                  'correction'
    %                  'delay'
    %                  'phase'
    %                  'continuousPhase'
    %                  'channelMapping'           
    % 'maxSamples' - limits the number of samples downloaded or written to a
    %                file. If set to zero, will generate samples until waveform
    %                repeats
    % 'maxAmplitude'    - the maximum amplitude the process will clip to if set
    % 'minAmplitude'    - the minimum amplitude the process will drop to if set
    % 'signalToNoiseDB' - the signal to noise ratio of the scenario
    % 'fc'         - center frequency (used in direct mode & DUC mode)
    % 'function'   - 'display', 'save', 'download', 'check'
    % 'filename'   - if function is 'save', the filename can optionally be
    %                provided. If filename is empty, the user will be prompted
    % 'filetype'   - if function is 'save', the filetype can optionally be
    %                provided. If filetype is empty, filetype will be derived
    %                from filename extension (see iqsavewaveform.m)
    % 'offsetTime'   - if true, sets first time to 0 to preserve samples
    %
    % T.Wychock, T.Dippon, Keysight Technologies 2019
    %
    % Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
    % QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
    % NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
    % AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
    % FITNESS FOR A PARTICULAR PURPOSE.
    % THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    % Notes:
    % 1. Make list of pulses with parameters at each pulse
    % 2. Initial just initialize an array of size of cluster
    %   Have as optional length...if it's empty then make length of the PDW
    % 3.Have filters for high and low frequencies
    % 4.Have filters for amplitude ranges
    % 5.First sort frequencies
    % 6.Have option for amplitude over...do we just clip it????
    % 7.Once filter frequency then we can do an iq pulse for each frequency and
    % 8.add to the array
    % 9.add to the array by selecting the index
    % 10.can't assume order
    % 11.return new amplitude
    % 12.log to file?
    % 13. How to do amplitudes....maybe get max and scale?
    % 14. Maybe add a time between pulses option for PDWs?

    % Initialize the returns
    totalSamples = 0;
    timeModifierS = 0;
    amplitudeModifierDB = 0;

    if (nargin == 0)
        multi_pulse_gui;
        return;
    end
    debugPrint = 1;
    % set default values - will be overwritten by arguments
    minAmplitude = -174;
    maxAmplitude = 100;
    sampleRate = [];
    maxSamples = 0;
    offsetTime = true;
    pulseTable = [];
    toneTable = [];
    correction = 0;
    normalize = 1;
    fct = 'display';
    signalToNoiseDB = [];
    showDropped = 1;
    filename = [];
    filetype = [];
    chMap = [1 0; 0 0; 0 0; 0 0];
    i = 1;
    while (i <= nargin)
        if (ischar(varargin{i}))
            switch lower(varargin{i})
                case 'samplerate';     sampleRate = varargin{i+1};
                case 'pulsetable';     pulseTable = varargin{i+1};
                case 'tonetable';      toneTable = varargin{i+1};
                case 'fc';             fc = varargin{i+1};
                case 'correction';     correction = varargin{i+1};
                case 'function';       fct = varargin{i+1};
                case 'filename';       filename = varargin{i+1};
                case 'filetype';       filetype = varargin{i+1};
                case 'minamplitude';   minAmplitude = varargin{i+1};
                case 'maxamplitude';   maxAmplitude = varargin{i+1};
                case 'showdropped';    showDropped = varargin{i+1};
                case 'maxsamples';     maxSamples = varargin{i+1};
                case 'offsettime';     offsetTime = varargin{i+1};
                case 'normalize';      normalize = varargin{i+1};
                case 'debugmode';      debugPrint = varargin{i+1};
                case {'chmap' 'channelmapping'}; chMap = varargin{i+1};
                otherwise; error(['unexpected argument: ' varargin{i}]);
            end
        else
            error('string argument expected');
        end
        i = i+2;
    end

    arbConfig = loadArbConfig();
    if isempty(sampleRate)
        sampleRate = arbConfig.defaultSampleRate;
    end
    if maxSamples == 0
        maxSamples = arbConfig.maximumSegmentSize;
    end

    % if (~strcmp(fct, 'check'))
    %     hMsgBox = msgbox('Calculating Pulses. Please wait...', 'Please wait...', 'replace');
    % end

    % Sort and filter the pdws
    if (debugPrint)
        disp('Preprocessing pulse table...');
    end
    
    [pulseTable, totalSamples, timeModifierS]...
        = sortAndFilter(pulseTable, sampleRate, maxSamples, offsetTime,...
        minAmplitude, maxAmplitude, debugPrint, showDropped);

    if (debugPrint)
        disp(['Table processed with IQ size of ' num2str(totalSamples) ' samples']);
    end
    
    if (debugPrint)
        disp('Generating IQ...');
    end
    
    % Initialize the array, first taking into account granularity
    if mod(totalSamples, arbConfig.segmentGranularity) ~= 0
        totalSamples = totalSamples + (arbConfig.segmentGranularity - mod(totalSamples, arbConfig.segmentGranularity)); 
    end
    iqData = zeros(totalSamples, 1);
    
    % Get the size of the pulse table
    pulseTableLength = length(pulseTable);
    
    % Parse through the pulse table, adding the items one pulse at a time
    decadeCount = 0;
    for pulseIdx = 1:pulseTableLength

       % Get the current pulse
       pulseCurrent = pulseTable(pulseIdx);

       % Get the sample to index to 
       pulseSampleIdxStart = round(pulseCurrent.startTime * sampleRate) + 1;

       % TODO Figure out the phase part...I think time offset will do the trick
       timeOffsetIQ = timeModifierS + pulseCurrent.startTime;
       if timeOffsetIQ < 0 || ~strcmp(pulseCurrent.transitionType, 'coherent')  % Account for precision issues
           timeOffsetIQ = 0;
       end

       % Add to the array index, factoring in the amplitudes
       iqDataCurrent = 10^(pulseCurrent.basePower / 20) *...
                           iqpulse_pdw(pulseCurrent.sampleRate, ...
                            pulseCurrent.PRI, ...
                            pulseCurrent.PW, ...
                            pulseCurrent.riseTime, ...
                            pulseCurrent.fallTime, ...
                            pulseCurrent.pulseShape,...
                            pulseCurrent.span, ...
                            pulseCurrent.offset, ...
                            pulseCurrent.amplitude,...
                            pulseCurrent.fmFormula,...
                            pulseCurrent.pmFormula, ...
                            pulseCurrent.modulationType, ...
                            0, ...
                            pulseCurrent.delay, ...
                            pulseCurrent.phase, ...
                            pulseCurrent.continuousPhase, ...
                            pulseCurrent.channelMapping, ...
                            pulseCurrent.basePhase, ...
                            timeOffsetIQ, ...
                            arbConfig);
                        
        iqDataCurrentLength = length(iqDataCurrent);
        
        % Try to account for the rounding and extra indexing
        if (pulseSampleIdxStart + iqDataCurrentLength - 1) > totalSamples && ...
              (pulseSampleIdxStart + iqDataCurrentLength- 1) <= maxSamples                    
          iqData = [iqData; zeros(((pulseSampleIdxStart + iqDataCurrentLength - totalSamples - 1)), 1)];       
          totalSamples = length(iqData);
        end                

        % Insert into the preallocated array
        iqData(pulseSampleIdxStart:pulseSampleIdxStart + iqDataCurrentLength- 1) = ...
            iqData(pulseSampleIdxStart:pulseSampleIdxStart + iqDataCurrentLength- 1) + iqDataCurrent;
        
        if pulseIdx >= (pulseTableLength * decadeCount / 10)
            disp(['Pulse Combine: ' num2str(decadeCount * 10) ' percent complete']);
            decadeCount = decadeCount + 1;
        end

        if (debugPrint)
            disp(['Processed pulse ' num2str(pulseIdx) ' of ' num2str(pulseTableLength)]);
        end
    end

    % Add to meet granularity if necessary
    totalSamples = length(iqData);
    if mod(totalSamples, arbConfig.segmentGranularity) ~= 0
        iqData = [iqData; zeros(arbConfig.segmentGranularity - mod(totalSamples, arbConfig.segmentGranularity), 1)]; 
    end
    
    % TODO: Perform correction by convolving correction across the timespan

    % Normalize the data to 1, and return the amplitude modifier
    scale = max(max(max(abs(real(iqData))), max(abs(imag(iqData)))));

    % Deal with no scale
    % Deal with no scale
    if scale ~= 0
        if (normalize)
            iqData = iqData / scale;
        end
        amplitudeModifierDB = 20 * log10 (scale);
    end
        
    if (debugPrint)
        disp(['IQ generated with ' num2str(amplitudeModifierDB) ' dB amplitude shift']);
    end

    % Act on the function
    switch lower(fct)
        case 'download'
            disp('Downloading to instrument...')
            iqdownload(iqData, sampleRate, 'arbConfig', arbConfig, 'channelMapping', chMap, 'segmentLength', totalSamples);
            disp('File loaded!')
        case 'display'
            iqplot(iqData, sampleRate, 'spectrogram');
        case 'save'
            disp('Saving file...')
            iqsavewaveform(iqData, sampleRate, 'filetype', filetype, 'filename', filename, 'segmentLength', totalSamples);
            disp('File saved!')
        case 'vsa'
            disp('Loading to VSA...')

            vsaApp = vsafunc([], 'open');

            if (~isempty(vsaApp))
                vsafunc(vsaApp, 'input', 1);
                if(isreal(iqData))
                    iqData = complex(iqData); %Added if no mod
                end

                vsafunc(vsaApp, 'load', iqData, sampleRate);
            end

            disp('File loaded!')

        otherwise
            error(['unknown function: ', fct]);
    end
end

% filter the pulse data table
% TODO: Add priority smarts...
function [pulseTableOut, sampleCountOut, timeModifierOut] = sortAndFilter(...
        pulseTableIn, sampleRateIn, maxSamplesIn, offsetTimeIn,...
        minAmplitudeIn, maxAmplitudeIn, debugModeIn, showDroppedIn)
    
    % Initialize the variables
    timeModifierOut = 0;
    sampleCountOut = maxSamplesIn;

    % Get the times
    timeStartArray = [pulseTableIn.startTime];
    timeDwellArray = {pulseTableIn.PRI};
    amplitudeArray = [pulseTableIn.basePower];

    % Get the first time
    timeStart = min(timeStartArray); 

    % Figure out the max time the scenario can be
    maxTime = maxSamplesIn / sampleRateIn + timeStart;

    % Delete time samples over the time range by cycling through all, and
    % removing anything after the max sample count first
    timeIdxRangedInitial = find(timeStartArray <= maxTime);

    % Now, with the rest of the indices, parse through each one to account
    % for the dwells as well
    timeIdxFiltered = zeros(length(timeIdxRangedInitial), 1);
    pulseCounter = 0;

    % Parse through the times, and if any extend beyond the time limit,
    % filter
    % Also track the max time
    timeTrackMax = 0;
    for pulseCheckIdx = 1:length(timeIdxRangedInitial)
        timeCheckCurrent = timeStartArray(pulseCheckIdx) + sum(timeDwellArray{pulseCheckIdx});
        amplitudeCurrent = amplitudeArray(pulseCheckIdx);
        
        % Check for additional limits too
        if timeCheckCurrent < maxTime &&...
                amplitudeCurrent >= minAmplitudeIn &&...
                amplitudeCurrent <= maxAmplitudeIn
            
            pulseCounter = pulseCounter + 1;
            timeIdxFiltered(pulseCounter) = pulseCheckIdx;
            
            if timeCheckCurrent > timeTrackMax
                timeTrackMax = timeCheckCurrent;
                timeMaxIdx = pulseCounter;
            end
        end        
    end

    % Get the filtered data
    pulseTableOut = pulseTableIn(timeIdxFiltered(1:pulseCounter));  

    % Modify the sample count to match the array sizes
%     [timeTrackMax, timeMaxIdx] = max([pulseTableOut.startTime]);
    
    sampleCountOut = ...
        ceil((timeTrackMax - min([pulseTableOut.startTime])) * sampleRateIn);

    if offsetTimeIn
        timeModifierOut = min([pulseTableOut.startTime]);
    end
    
    if (debugModeIn || showDroppedIn)
        disp([num2str(pulseCounter) ' pulses to be processed out of ' num2str(length(timeIdxRangedInitial)) ' input pulses']);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% iqpulse leveraged commands

function varargout = iqpulse_pdw(sampleRate, pri, pw, riseTime, fallTime,...
    pulseShape, span, offset, amplitude, fmFormula, pmFormula,...
    chirpType, correction, delay, phase, continuousPhase, channelMapping,...
    phaseOffset, timeOffset, arbConfig)
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
    return;
end
% assign default parameters
normalize = 1;
customIQPulse = []; %WYCHOCK If we want to add custom IQ to a pulse

% number of pulses to generate = length of longest parameter vector
numPulse = max([length(pri) length(delay) length(phase) length(pw)...
    length(riseTime) length(fallTime) length(span) length(offset) length(amplitude)]);

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
%[pri, numSamples, numRepeats] = checkGranularity(pri, delay, pw, riseTime, fallTime, sampleRate, arbConfig, exactpri);

% round pri to full ps to reduce the chance of floating point rounding errors
spri = round(sum(pri) * 1e12);
numSamples = ceil(spri * sampleRate / 1e12);

% handle custom IQ differently
if (strcmpi(chirpType{1}, 'custom IQ'))    
    [envelope, envelopeStarts, envelopeStops] =...
        calcPulseShapeIQ(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, pulseShape, amplitude);
    iqdata =...
        calcCustomIQ(numSamples, sampleRate, pri, customIQPulse, envelope, offset, phase, envelopeStarts, envelopeStops);
else
    envelope =...
        calcPulseShape(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, pulseShape, amplitude);
    
    % Calculate the pulse envelope
    if (strcmpi(chirpType{1}, 'FMCW'))
        envelope = ones(size(envelope));
    end
    
    [sig, mag] = calcPhase(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, ...
        phase, span, offset, chirpType, pulseShape, fmFormula, pmFormula,...
        correction, continuousPhase, timeOffset, phaseOffset);
    
    iqdata = envelope .* exp(1i * sig);
    
    % if the double math adds another sample, remove it from the iqdata    
    if numel(iqdata) > numel(mag)
        iqdata = iqdata(1:numel(iqdata)-1);
    end
    iqdata = power(10,((mag)/20)) .* iqdata;
end

% make sure we always return a colummn-vector
iqdata = reshape(iqdata, numel(iqdata), 1);

% % create a marker with the shape of the envelope
% marker = 15 * (envelope ~= 0);

% apply correction if requested
if (correction)
    [iqdata, channelMapping] = iqcorrection(iqdata, sampleRate, 'chMap', channelMapping);
end

% normalize amplitude
if (normalize)
    scale = max(max(max(abs(real(iqdata))), max(abs(imag(iqdata)))));
    
    % Deal with no scale
    if scale ~= 0    
        iqdata = iqdata / scale;
    end
end

if (nargout >= 1)
    varargout{1} = iqdata;
end
% if (nargout >= 2)
%     varargout{2} = marker;
% end
% if (nargout >= 4)
%     varargout{4} = channelMapping;
% end

end

% Don't have to worry about this because we're combining at the end
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

function [envelope, envelopeStarts, envelopeStops] = calcPulseShapeIQ(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, pulseShape, amplitude)
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

function [envelope] = calcPulseShape(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, pulseShape, amplitude)
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
        ridx = (ih(1):ih(2)-1);
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


function [pm, mag] = calcPhase(numSamples, pri, delay, riseTime, pw, fallTime, ...
    sampleRate, phase, span, offset, chirpType, pulseShape, fmFormula, pmFormula,...
    correction, continuousPhase, timeOffset, phaseOffset)
% calculate the phase based on span and offset
    mag = zeros(1, numSamples);
    fm = zeros(1, numSamples);
    pm = zeros(1, numSamples);

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
                    eval(['fm_fct = @(x,i) ' fmFormula ';']);
                    eval(['pm_fct = @(x,i) ' pmFormula ';']);
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

%% Unused methods from leveraged multi_pulse

% calculate one waveform segment that contains all pulses
function calculateAsOneSegment(hMsgBox, arbConfig, chMap, pulseTable, toneTable, totalSamples, sampleRate, fc, correction, fct, filetype, filename)
    % close the message box in case one was open - using a progressbar later on
    try close(hMsgBox); catch; end
    % length of the tables
    pulseTableLen = length(pulseTable);
    toneTableLen = length(toneTable);
    % create an arbConfig with granularity = 1 to get accurate PRIs
    arbc.model = 'generic';
    % create an iqsteppulse object for each entry in the pulse table
    for i=1:pulseTableLen
        % pulsewidth == 0 creates an AM/FM signal
        pulseTable(i).handle = iqsteppulse(...
            'arbConfig', arbc, ...
            'sampleRate', sampleRate, 'PRI', pulseTable(i).pri, ...
            'PW', pulseTable(i).pw, 'risetime', pulseTable(i).tt, ...
            'falltime', pulseTable(i).tt, 'offset', pulseTable(i).offset, ...
            'span', pulseTable(i).span, 'amplitude', pulseTable(i).ampl, 'normalize', 0, ...
            'correction', correction, 'delay', pulseTable(i).delay, ...
            'scanType', pulseTable(i).scanType, 'scanFct', pulseTable(i).scanFct, ...
            'scanPeriod', pulseTable(i).scanPeriod, 'scanAz', pulseTable(i).scanAz, ...
            'scanSquint', pulseTable(i).scanSq, 'scanOffset', pulseTable(i).scanOffset);
            if (strcmp(fct, 'display'))
                if (pulseTable(i).scanPerS ~= 1)
                    figure(100+i);
                    pulseTable(i).handle.plotScan();
                    title(sprintf('Antenna scan pattern for line #%d', i));
                end
            end
    end
    % create an iqsteptone instance for each line in the tone table
    for i=1:toneTableLen
        % FM
        if (toneTable(i).fmfreq ~= 0 && toneTable(i).fmdev ~= 0)
            pmfct = sprintf('%g*-cos(2*pi*%g*t)', toneTable(i).fmdev/toneTable(i).fmfreq, toneTable(i).fmfreq);
        else
            pmfct = [];
        end
        % AM
        if (toneTable(i).amfreq ~= 0 && toneTable(i).amdepth ~= 0)
            amfct = sprintf('(1-%g)+%g*sin(2*pi*%g*t)', toneTable(i).amdepth, toneTable(i).amdepth, toneTable(i).amfreq);
        else
            amfct = [];
        end
        toneTable(i).handle = iqsteptone(...
            'arbConfig', arbc, ...
            'sampleRate', sampleRate, 'tone', toneTable(i).offset, 'amFct', amfct, 'pmFct', pmfct, ...
            'magnitude', toneTable(i).ampl, 'normalize', 0, 'correction', correction);
    end
    % create the progress bar with cancel button
    hMsgBox = waitbar(0, '', 'Name', 'Please wait...', 'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
    waitbar(0, hMsgBox, sprintf('Processed %d MSa, %.1f%%, %.1f sec', 0, 0, 0));
    % use a try-catch block because the waitbar MUST be properly deleted under all circumstances
    try
        chunkSize = 522240; % block size for waveform generation
        sampleCnt = 0;      % running count of samples generated
        scale = 1;          % default scaling
        tic;
        tlast = toc;
        % calculate the block-wise waveform
        while (sampleCnt < totalSamples)
            % adjust chunkSize for last chunk
            if (sampleCnt + chunkSize > totalSamples)
                chunkSize = totalSamples - sampleCnt;
            end
            % update progress bar
            if getappdata(hMsgBox, 'canceling'); break; end
            t = toc;
            if (t - tlast > 1)  % no more than once per second
                tlast = t;
                newSampleCnt = sampleCnt + chunkSize;
                waitbar(newSampleCnt / totalSamples, hMsgBox, sprintf('Processed %g MSa, %.1f%%, %.1f sec', newSampleCnt/1e6, newSampleCnt / totalSamples * 100, t));
            end
            % calculate one waveform chunk
            iqsum = zeros(chunkSize, 1);
            for i=1:pulseTableLen
                iqsum = iqsum + pulseTable(i).handle.step(chunkSize);
            end
            for i=1:toneTableLen
                iqsum = iqsum + toneTable(i).handle.step(chunkSize);
            end
            % check for proper scaling
            maxVal = max(max(abs(real(iqsum))),max(abs(imag(iqsum))));
            if (maxVal > scale)
                % check, if this is the first chunk
                if (sampleCnt == 0)
                    scale = 1.05 * maxVal;  % set new scale value with a 5% margin and continue
                elseif (maxVal / scale < 1.05)   % if is less than 5% overflow, just clip the values to avoid excessive re-starts
                    % pretty complicated...  if someone can help me
                    % simplify the code, I'd appreciate it.
                    iqsumr = real(iqsum);
                    iqsumi = imag(iqsum);
                    iqsumr(iqsumr > scale) = scale;
                    iqsumi(iqsumi > scale) = scale;
                    iqsumr(iqsumr < -scale) = -scale;
                    iqsumi(iqsumi < -scale) = -scale;
                    iqsum = complex(iqsumr, iqsumi);
                else
                    % too bad, we found a larger maxVal somewhere in the
                    % middle of the calculation --> need to start over 
                    scale = 1.05 * maxVal;  % set new scale value and add a 5% margin
                    fprintf('restarting @ sampleCnt = %d, new scale = %g\n', sampleCnt, scale);
                    sampleCnt = 0;
                    % reset all the generators
                    for i=1:pulseTableLen
                        pulseTable(i).handle.reset();
                    end
                    for i=1:toneTableLen
                        toneTable(i).handle.reset();
                    end
                    continue;
                end
            end
            iqsum = iqsum / scale;
            switch (fct)
                case 'download'
                    iqdownload(iqsum, sampleRate, 'arbConfig', arbConfig, 'channelMapping', chMap, 'segmentLength', totalSamples, 'segmentOffset', sampleCnt);
                    if (sampleCnt + chunkSize == totalSamples)
    %                    setup_sa(arbConfig, fc, fc, 0);
                    end
                case 'display'
                    iqplot(iqsum, sampleRate, 'spectrogram');
                    if (sampleCnt == 0)
                        break;
                    end
                case 'save'
                    iqsavewaveform(iqsum, sampleRate, 'filetype', filetype, 'filename', filename, 'segmentLength', totalSamples, 'segmentOffset', sampleCnt);
                otherwise
                    error(['unknown function: ', fct]);

            end
            sampleCnt = sampleCnt + chunkSize;
        end
    catch ex
        errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    end
    % must use delete() for waitbar (see help waitbar)
    delete(hMsgBox);
    t = toc;
    fprintf('total %g MSa, %g sec, %g MSa/sec\n', totalSamples/1e6, t, totalSamples/1e6/t);
end

% calculate the waveforms for sequences with antenna scans
function calculateAsSequence(hMsgBox, arbConfig, chMap, pulseTable, toneTable, totalSamples, sampleRate, fc, correction, fct, minAmplitude, showDropped)
    tic;
    % number of entries in the pulse and tone table
    pulseTableLen = length(pulseTable);
    toneTableLen = length(toneTable);
    if (toneTableLen > 0)
        msgbox('Sequence generation with tones is not supported');
        return;
    end
    % count of generated pulses
    pulseCnt = 0;
    % count of dropped pulses (due to overlap)
    dropCnt = 0;
    % count of dropped pulses (due to low amplitude)
    lowAmplCnt = 0;
    % the number of samples needed for complete antenna scan
    totalScanSamples = 1;
    % initialize the random number generator to the same seed every time
    % in older MATLAB versions, setGlobalStream does not exist. In the
    % newer versions, setDefaultStream does not exist any more.
    try
        RandStream.setGlobalStream(RandStream('mt19937ar','seed',12345));
    catch
        RandStream.setDefaultStream(RandStream('mt19937ar','seed',12345));
    end
    for i=1:pulseTableLen
        % scan period in samples (0 = no scan)
        pulseTable(i).scanPerS = 0;
        % vector of starting samples
        pulseTable(i).starts = [];  
        % vector of amplitudes
        pulseTable(i).amplvec = [];
        % extend all the other parameter vectors to match the new number of pulses
        pulseTable(i).pri    = fixlength(pulseTable(i).pri, pulseTable(i).numPulse);
        pulseTable(i).pw     = fixlength(pulseTable(i).pw, pulseTable(i).numPulse);
        pulseTable(i).pws    = round(pulseTable(i).pw * sampleRate);
        pulseTable(i).tt     = fixlength(pulseTable(i).tt, pulseTable(i).numPulse);
        pulseTable(i).tts    = round(pulseTable(i).tt * sampleRate);
        pulseTable(i).span   = fixlength(pulseTable(i).span, pulseTable(i).numPulse);
        pulseTable(i).offset = fixlength(pulseTable(i).offset, pulseTable(i).numPulse);
        pulseTable(i).ampl   = fixlength(pulseTable(i).ampl, pulseTable(i).numPulse);
        pulseTable(i).sumprs = round(sum(pulseTable(i).pri) * sampleRate);
        pulseTable(i).scanOffset = rand(1,1);
        switch (pulseTable(i).scanType)
            case 'None'
            case 'Circular'
                eval(['pulseTable(i).ampFormula = @(x) ' pulseTable(i).scanFct ';']);
                eval(['pulseTable(i).xFormula = @(x) x * ' num2str(832 / pulseTable(i).scanAz) ';']);
                scanSamples = round(pulseTable(i).scanPeriod * sampleRate);
                pulseTable(i).scanPerS = scanSamples;
                totalScanSamples = lcm(totalScanSamples, scanSamples);
            case 'Conical'
                eval(['pulseTable(i).ampFormula = @(x) ' pulseTable(i).scanFct ';']);
                r2 = num2str(pulseTable(i).scanSq / 2 / 360);
                eval(['pulseTable(i).xFormula = @(x) ' ...
                    'sqrt((' r2 '*sin(2*pi*x)).^2 + (' r2 '*cos(2*pi*x)-' r2 ').^2) * ' ...
                    num2str(832 / pulseTable(i).scanAz / 2) ';']);
                scanSamples = round(pulseTable(i).scanPeriod * sampleRate);
                pulseTable(i).scanPerS = scanSamples;
                totalScanSamples = lcm(totalScanSamples, scanSamples);
            otherwise
                error('unknown antenna scan type');
        end
    end
    % in case we don't have any antenna scans, use the number of samples
    % required for the PRIs as the total number of samples
    totalScanSamples = max(totalScanSamples, totalSamples);
    if (strcmp(fct, 'check'))
        return;
    end
    %fprintf(sprintf('totalScanSamples: %.0f\n', totalScanSamples));
    %% go through pulse list again and calculate start times, end times & amplitudes
    showProgress(hMsgBox, 'Calculating start times & amplitudes...');
    % vector of all start samples
    allStarts = [];
    % vector of all end samples
    allEnds = [];
    % vector of pulse entry pointers, i.e. for each index in allStarts, tells
    % you the associated pulseTable entry
    pEntryPtr = [];
    % vector of index pointers, i.e. for each index in allStarts, tells you 
    % the parameter index inside the pulse entry
    pIndexPtr = [];
    % vector of amplitudes
    amplvec = [];
    % start indices of pulses 
    pidx = zeros(pulseTableLen+1, 1);
    for i=1:pulseTableLen
        % number of pulse "groups" (with individual pri's)
        numGroups = ceil(totalScanSamples / pulseTable(i).sumprs);
        % number of pulses per group
        numPPG = pulseTable(i).numPulse;
        if (numGroups * numPPG > 1000000)
            errordlg({'Scenario requires more than 1000000 pulses' ...
                sprintf('and %g seconds of playtime', totalScanSamples / sampleRate) ...
                'Consider adjusting your scan periods...'});
            return;
        end
        % initialize the vector of starting samples and end samples
        pulseTable(i).starts = zeros(numGroups * numPPG, 1);
        pulseTable(i).ends = zeros(numGroups * numPPG, 1);
        % initialize the index vector. It points to the pri/offset/etc
        pulseTable(i).idxvec = ones(numGroups * numPPG, 1);
        % waveform
        pulseTable(i).wfm = cell(1, pulseTable(i).numPulse);
        pulseTable(i).wfmUsed = cell(1, pulseTable(i).numPulse);
        % set first starting sample
        currps = round(pulseTable(i).delay * sampleRate);
    %     if (numPPG > 1)
    %         for k = 1:numGroups
    %             pulseTable(i).starts((k-1) * numPPG + 1: k * numPPG) = ...
    %                 cumsum(pulseTable(i).prs) + currps;
    %             pulseTable(i).ends((k-1) * numPPG + 1: k * numPPG) = ...
    %                 cumsum(pulseTable(i).prs) + currps + ...
    %                 max(pulseTable(i).pws + 2*pulseTable(i).tts, 6168); % 24 * 257
    %             pulseTable(i).idxvec((k-1) * numPPG + 1: k * numPPG) = 1:numPPG;
    %             currps = currps + pulseTable(i).sumprs;
    %         end
    %     else
            % vector of PRI's (in units of samples)
            priv = repmat(pulseTable(i).prs, 1, numGroups);
            % starting point is currps+0, last PRI is don't care
            pulseTable(i).starts = currps + cumsum([0 priv(1:end-1)]);
            % vector of PW's (in units of samples)
            pwv = repmat(pulseTable(i).pws + 2*pulseTable(i).tts, 1, numGroups);
            % make the width at least as big as the minimum segment size
            pwv = max(pwv, arbConfig.minimumSegmentSize);
            pulseTable(i).ends = pulseTable(i).starts + pwv;
            pulseTable(i).idxvec = repmat(1:numPPG, 1, numGroups);
    %     end
        % remove pulses that exceed the totalScanSamples
        idx = find(pulseTable(i).ends > totalScanSamples);
        pulseTable(i).idxvec(idx) = [];
        pulseTable(i).starts(idx) = [];
        pulseTable(i).ends(idx) = [];
        % calculate the amplitudes
        ampl = unique(pulseTable(i).ampl);
        if (~isscalar(ampl))
            error('expected scalar amplitude');
        end
        if (pulseTable(i).scanPerS ~= 0)
            scr = (pulseTable(i).starts + 1) ./ pulseTable(i).scanPerS + pulseTable(i).scanOffset;
            scr = scr - floor(scr);
            idx = find(scr > 0.5);
            scr(idx) = scr(idx) - 1;
            pulseTable(i).amplvec = ampl + 10*log10(abs(pulseTable(i).ampFormula(pulseTable(i).xFormula(scr))));
        else
            pulseTable(i).amplvec = repmat(ampl, 1, length(pulseTable(i).starts));
        end
        % remove those pulses where the amplitude is too small
        idx = find(pulseTable(i).amplvec < minAmplitude);
        lowAmplCnt = lowAmplCnt + length(idx);
        pulseTable(i).idxvec(idx) = [];
        pulseTable(i).starts(idx) = [];
        pulseTable(i).ends(idx) = [];
        pulseTable(i).amplvec(idx) = [];
        pulseTable(i).pulseCnt = length(pulseTable(i).starts);
        pulseCnt = pulseCnt + pulseTable(i).pulseCnt;
        pidx(i+1) = pulseTable(i).pulseCnt;
        allStarts = [allStarts; pulseTable(i).starts'];
        allEnds = [allEnds; pulseTable(i).ends'];
        pEntryPtr = [pEntryPtr; i*ones(pulseTable(i).pulseCnt, 1)];
        pIndexPtr = [pIndexPtr; pulseTable(i).idxvec'];
        amplvec = [amplvec; pulseTable(i).amplvec'];
    end
    pidx = cumsum(pidx);

    %% sort the pulses
    showProgress(hMsgBox, 'Sorting...');
    [allStarts sidx] = sort(allStarts);
    allEnds = allEnds(sidx);
    pEntryPtr = pEntryPtr(sidx);
    pIndexPtr = pIndexPtr(sidx);
    amplvec = amplvec(sidx);
    % calculate gaps between pulses
    if (~isempty(allStarts))
        gap = [allStarts(2:end); allStarts(1)+totalScanSamples] - allEnds(1:end);
    end
    % For now, remove pulses that overlap or are too close to their
    % predecessor. With some extra effort, these (overlapping & close together)
    % pulses could be handled as separate waveforms.

    % mininum gap is determined by the minimum idle delay of the AWG
    if (~isempty(strfind(arbConfig.model, 'M8195A')))
        minGap = 2560;
    else
        minGap = 240;
    end
    delIdx = find(gap < minGap) + 1;
    dropList = [];
    dropAmpl = [];
    while (~isempty(delIdx))
        dropCnt = dropCnt + length(delIdx);
        dropList = [dropList; allStarts(delIdx)];
        dropAmpl = [dropAmpl; amplvec(delIdx)];
        allStarts(delIdx) = [];
        allEnds(delIdx) = [];
        pEntryPtr(delIdx) = [];
        pIndexPtr(delIdx) = [];
        amplvec(delIdx) = [];
        % re-calculate the gaps
        if (~isempty(allStarts))
            gap = [allStarts(2:end); allStarts(1)+totalScanSamples] - allEnds(1:end);
        end
        delIdx = find(gap < minGap) + 1;
    end
    pulseCnt = pulseCnt - dropCnt;

    %fprintf('calculate %g\n', toc);
    tic;

    %% output result
    switch (fct)
        case 'display'
            figure(1);
            clf;
            set(gcf(),'Name','Multi Emitter Simulation');
            title(sprintf('%d pulses, %d dropped, %d low amplitude\n', pulseCnt, dropCnt, lowAmplCnt));
            hold on;
            grid on;
            xlabel('time');
            ylabel('amplitude');
            leg = {};
            if (showDropped)
                plot(dropList / sampleRate, dropAmpl, 'color', [0 0 0], 'marker', 'o');
                leg{1} = ['dropped (' num2str(dropCnt) ')'];
            end
            colors = repmat(get(gca, 'ColorOrder'), 3, 1);
            for k=1:pulseTableLen
                leg{end+1} = ['#' num2str(k) ' (' num2str(pulseTable(k).pulseCnt) ')'];
                plot(pulseTable(k).starts / sampleRate, pulseTable(k).amplvec, '.', 'color', colors(k,:));
            end
            legend(leg);
            hold off;
            printPulses = 0;
            if (printPulses)
                for k = 1:pulseCnt
                    fprintf('%3d: %10.3f %d %d %5.2f\n', ...
                        k, allStarts(k)/sampleRate*1000, pEntryPtr(k), pIndexPtr(k), amplvec(k));
                end
            end
        case 'download'
            downloadSeq(hMsgBox, arbConfig, chMap, pulseTable, toneTable, pulseTableLen, sampleRate, allStarts, gap, pEntryPtr, pIndexPtr, amplvec, minAmplitude, fc, correction, totalScanSamples);
        case 'save'
            errordlg('Save waveform is not implemented for waveforms that use sequencing');
        otherwise
            error(['unknown function: ', fct]);
    end
    %fprintf('download %g\n', toc);
end

% download the waveform segments and sequence
function downloadSeq(hMsgBox, arbConfig, chMap, pulseTable, toneTable, numEntries, sampleRate, allStarts, gap, pEntryPtr, pIndexPtr, amplvec, minAmplitude, fc, correction, totalScanSamples)
    ducMode = ~isempty(strfind(arbConfig.model, 'DUC'));
    if (ducMode)
        amplResolution = 0.25;
    else
        amplResolution = 0.25;
    end
    if (arbConfig.maxSegmentNumber <= 1)
        errordlg('The current AWG mode does not support sequencing. Please set all "scan type" to none in order to load the waveform into a single segment or select an AWG mode that supports sequencing');
        return;
    end
    m = 2;
    pulseCnt = length(allStarts);
    if (m * pulseCnt > arbConfig.maxSegmentNumber)
        errordlg({'Too many pulses - running out of sequence memory' ...
            sprintf('Scenario requires %d pulses. Sequence can only support up to %d', pulseCnt, floor(arbConfig.maxSegmentNumber/m))});
        return;
    end
    if (ducMode)
        showProgress(hMsgBox, 'Downloading action table...');
        atab = loadActionTable(hMsgBox, minAmplitude, amplResolution);
    end
    showProgress(hMsgBox, 'Downloading waveforms...');
    % check connectivity
    f = iqopen();
    if (isempty(f))
        return;
    end
    % create a zero segment
    segNum = 1;
    if (ducMode)
        iqdownload(zeros(24 * 257, 1), sampleRate, 'arbConfig', arbConfig, 'chMap', chMap, 'segmentNumber', segNum, 'keepopen', 1, 'run', 0);
    else
        iqdownload(zeros(arbConfig.minimumSegmentSize, 1), sampleRate, 'arbConfig', arbConfig, 'chMap', chMap, 'segmentNumber', segNum, 'keepopen', 1, 'run', 0);
    end
    segNum = 2;
    cplstat = 0;
    for i = 1:numEntries
        pulseTable(i).segNum = zeros(pulseTable(i).numPulse, 1);
        pulseTable(i).actualPriS = zeros(pulseTable(i).numPulse, 1);
        for k = 1:pulseTable(i).numPulse
            % the pri is NOT the real PRI, just long enough to represent
            % the pulse width + transition times
            pri = max(24 * 257 / sampleRate, ...
                pulseTable(i).pw(k) + 2*pulseTable(i).tt(k) + 1e-10);
            if (pri * sampleRate > arbConfig.maximumSegmentSize)
                errordlg('PW exceeds maximum segment size');
                return;
            end
            iqdata = iqpulse_pdw('arbConfig', arbConfig, ...
                'sampleRate', sampleRate, ...
                'PRI', pri, 'PW', pulseTable(i).pw(k), ...
                'risetime', pulseTable(i).tt(k), ...
                'falltime', pulseTable(i).tt(k), ...
                'offset', pulseTable(i).offset(k),...
                'span', pulseTable(i).span(k),...
                'amplitude', 0,...
                'correction', correction);
            if (ducMode)
                numAmpls = 1;
            else
                numAmpls = abs(minAmplitude / amplResolution);
            end
            scale = 1;
            iqdownload(iqdata * scale, sampleRate, 'arbConfig', arbConfig, 'chMap', chMap, 'segmentNumber', segNum, 'keepopen', 1, 'run', 0);
            pulseTable(i).segNum(k) = segNum;
            pulseTable(i).actualPriS(k) = length(iqdata);
            pulseTable(i).wfm{k} = iqdata;
            pulseTable(i).wfmUsed{k} = zeros(1,numAmpls);
            segNum = segNum + numAmpls;
        end
    end
    % now set up the sequence
    %ch = get(hMsgBox, 'Children');
    %set(ch(2), 'String', 'Cancel');
    if (ducMode)
        seq = struct('segmentNumber', {}, 'segmentLoops', {}, ...
            'actionID', {}, 'sequenceInit', {}, 'sequenceEnd', {}, ...
            'sequenceLoops', {}, 'scenarioEnd', {});
        seq(m*pulseCnt).scenarioEnd = 1;
        amps = zeros(pulseCnt,1); %%%
        for k=1:pulseCnt
            ncpl = floor(k / pulseCnt * 100);
            if (ncpl ~= cplstat)
                cplstat = ncpl;
                if (showProgress(hMsgBox, sprintf('Calculating Sequence... (%g %%)', ncpl)))
                    return;
                end
            end
            %--- the "action" segment
            n = 1;
            ai = min(max(round(-1 * amplvec(k) / amplResolution) + 1, 1), length(atab));
            amps(k) = ai;
            seq((k-1)*m+n).actionID = atab(ai);
            if (m == 3)
                seq((k-1)*m+n).segmentNumber = 1;
                seq((k-1)*m+n).segmentLoops = 1;
                n = n + 1;
            end
            %--- the pulse "on" segment
            segNum = pulseTable(pEntryPtr(k)).segNum(pIndexPtr(k));
            seq((k-1)*m+n).segmentNumber = segNum;
            seq((k-1)*m+n).segmentLoops = 1;
            seq((k-1)*m+n).markerEnable = 1;
            n = n + 1;
            %--- the "idle" segment
            % pulseTable(pEntryPtr(k)).actualPriS(pIndexPtr(k));
            if (m == 3)
                currGap = gap(k) - 6408;
            else
                currGap = gap(k) - 240;
            end
            if (currGap < 240)
                currGap = 240;
            end
            seq((k-1)*m+n).segmentNumber = 0;
            if (currGap > 100000000)
                seq((k-1)*m+1).sequenceLoops = round(currGap / 100000000);
                currGap = 100000000;
            end
            seq((k-1)*m+n).segmentLoops = floor(currGap/8)*8;
        end
    else
        seq = struct('segmentNumber', {}, 'segmentLoops', {}, ...
            'actionID', {}, 'sequenceInit', {}, 'sequenceEnd', {}, ...
            'sequenceLoops', {}, 'scenarioEnd', {});
        % probably the last entry - reserve the space
        seq(2*pulseCnt).segmentNumber = 0;
        n = 1;
        for k = 1:pulseCnt
            ncpl = floor(k / pulseCnt * 100);
            if (ncpl ~= cplstat)
                cplstat = ncpl;
                if (showProgress(hMsgBox, sprintf('Calculating Sequence... (%g %%)', ncpl)))
                    return;
                end
            end
            %--- the pulse "on" segment
            % segment offset 0 dB --> ai = 0
            ai = max(floor(-1 * amplvec(k) / amplResolution), 0);
            pulseTable(pEntryPtr(k)).wfmUsed{pIndexPtr(k)}(ai+1) = 1;
            segNum = pulseTable(pEntryPtr(k)).segNum(pIndexPtr(k)) + ai;
            seq(n).segmentNumber = segNum;
            seq(n).segmentLoops = 1;
            seq(n).markerEnable = 1;
            n = n + 1;
            %--- the "idle" segment
            currGap = gap(k);
            maxIdle = 100000000;
            if (currGap > 2*maxIdle)
                seq(n).segmentNumber = 0;   % idle sequence for coarse delay
                seq(n).segmentLoops = maxIdle;
                seq(n).sequenceLoops = floor(currGap / maxIdle) - 1;
                n = n + 1;
                seq(n).segmentNumber = 1;   % must have one regular segment in between
                seq(n).segmentLoops = 1;
                n = n + 1;
                seq(n).segmentNumber = 0;   % another idle with the remainer
                seq(n).segmentLoops = currGap - maxIdle * (floor(currGap / maxIdle) - 1) - arbConfig.minimumSegmentSize;
                n = n + 1;
            else
                seq(n).segmentNumber = 0;   % just a regular idle segment
                seq(n).segmentLoops = currGap;
                n = n + 1;
            end
        end
        seq(n-1).scenarioEnd = 1;
    end
    % load the remaining waveforms
    for i = 1:numEntries
        for k = 1:pulseTable(i).numPulse
            wfm = pulseTable(i).wfm{k};
            wfmUsed = pulseTable(i).wfmUsed{k};
            for m = 2:numAmpls
                if (wfmUsed(m))
                    ampldb = -1 * (m-1) * amplResolution;
                    scale = 10^(ampldb/20);
                    if (showProgress(hMsgBox, sprintf('Downloading Waveform... \nEmitter %d, Pulse %d, %.2f dB)', i, k, ampldb)))
                        return;
                    end
                    segNum = pulseTable(i).segNum(k) + m - 1;
                    iqdownload(wfm * scale, sampleRate, 'arbConfig', arbConfig, 'chMap', chMap, 'segmentNumber', segNum, 'keepopen', 1, 'run', 0);
                end
            end
        end    
    end
    % load the sequence and run in Scenario mode
    if (iqseqx(arbConfig, hMsgBox, seq) ~= 0)
        return;
    end
    setup_sa(arbConfig, fc, fc + pulseTable(1).offset(1), totalScanSamples / sampleRate);
end

function atab = loadActionTable(hMsgBox, minAmplitude, amplResolution)
    % delete action table
    iqseq('actionDeleteAll');
    numActs = abs(minAmplitude / amplResolution);
    atab = 1:numActs;
    cplstat = 0;
    f = iqopen();
    xfprintf(f, 'ABORt1');
    xfprintf(f, 'ABORt2');
    for i=1:numActs
        ncpl = floor(i / length(atab) * 100);
        if (ncpl ~= cplstat)
            cplstat = ncpl;
            showProgress(hMsgBox, sprintf('Loading Action Table... (%g %%)', ncpl));
        end
        ampldb = -1* (i-1) * amplResolution;
        ampl = 10^(ampldb/20);
    % this is the same but takes too long:
    %    atab(i) = iqseq('actionDefine', { 'AMPL', ampl });
        atab(i) = str2double(query(f, ':ACTion1:DEFine:NEW?'));
        xfprintf(f, sprintf(':ACTion1:APPend %d,%s,%.15g', atab(i), 'AMPL', ampl));
        atab(i) = str2double(query(f, ':ACTion2:DEFine:NEW?'));
        xfprintf(f, sprintf(':ACTion2:APPend %d,%s,%.15g', atab(i), 'AMPL', ampl));
    end
end

function retVal = iqseqx(arbConfig, hMsgBox, seqtable)
    realCh = 1;
    imagCh = 0;
    cbitCmd = 32;
    cmaskCmd = hex2dec('D0000000');
    ctrlInit = hex2dec('50000000');
    cbitEndSequence = 31;
    cbitEndScenario = 30;
    cbitInitSequence = 29;
    cbitMarkerEnable = 25;
    cbitAmplitudeInit = 16;
    cbitAmplitudeNext = 15;
    cbitFrequencyInit = 14;
    cbitFrequencyNext = 13;
    cmaskSegmentAuto = hex2dec('00000000');
    cmaskSegmentCond = hex2dec('00010000');
    cmaskSegmentRept = hex2dec('00020000');
    cmaskSegmentStep = hex2dec('00030000');
    cmaskSequenceAuto = hex2dec('00000000');
    cmaskSequenceCond = hex2dec('00100000');
    cmaskSequenceRept = hex2dec('00200000');
    cmaskSequenceStep = hex2dec('00300000');
    endptr = hex2dec('ffffffff');

    % download the sequence table
    f = iqopen(arbConfig);
    seqData = uint32(zeros(6 * length(seqtable), 1));
    cplstat = 0;
    if (showProgress(hMsgBox, 'Converting sequence...'))
        return;
    end
    for i = 1:length(seqtable)
        ncpl = floor(i/length(seqtable)*100);
        if (ncpl ~= cplstat)
            cplstat = ncpl;
            if (showProgress(hMsgBox, sprintf('Converting Sequence... (%g %%)', ncpl)))
                return;
            end
        end
        seqline = seqtable(i);
        seqLoopCnt = 1;
        ctrl = ctrlInit;
        seqTabEntry = uint32(zeros(6, 1));        % initialize the return value
        if (seqline.segmentNumber == 0)           % segment# = 0 means: idle command
            ctrl = cmaskCmd;                 % set the command bit
            %seqTabEntry(3) = 0;                   % Idle command code = 0
            %seqTabEntry(4) = 0;                   % Sample value
            seqTabEntry(5) = seqline.segmentLoops;  % use segment loops as delay
            %seqTabEntry(6) = 0;                   % unused
        else
            if (~isempty(seqline.actionID))
                % if it is an actionID, set the command bit and action Cmd Code
                % and store actionID in 24 MSB of word#3.
                % The segment will not be repeated. segmentLoops is ignored
                ctrl = cmaskCmd;
                seqTabEntry(3) = 1 + bitshift(uint32(seqline.actionID), 16);
            else
                seqTabEntry(3) = seqline.segmentLoops;
            end
            seqTabEntry(4) = seqline.segmentNumber;
            seqTabEntry(6) = endptr;         % end pointer
            if (~isempty(seqline.markerEnable))
                ctrl = bitset(ctrl, cbitMarkerEnable);
            end
        end
        % if the sequence fields exist, then set the sequence control bits
        % according to those fields

        %seqInit & End are always set
    %        if (~isempty(seqline.sequenceInit))
    %            ctrl = bitset(ctrl, cbitInitSequence);
    %        end
    %        if (~isempty(seqline.sequenceEnd))
    %            ctrl = bitset(ctrl, cbitEndSequence);
    %        end
        if (~isempty(seqline.sequenceLoops))
            seqLoopCnt = seqline.sequenceLoops;
        end
        if (~isempty(seqline.scenarioEnd))
            ctrl = bitset(ctrl, cbitEndScenario);
        end
        seqTabEntry(1) = ctrl;                % control word
        seqTabEntry(2) = seqLoopCnt;          % sequence loops
        %seqTabEntry = calculateSeqTableEntry(seqtable(i), i, length(seqtable));
        seqData(6*i-5:6*i) = seqTabEntry;
        if (evalin('base', 'exist(''debugSeq'', ''var'')'))
            fprintf('Seq Write %03d: ', i);
            fprintf('%08X ', seqTabEntry);
            fprintf('\n');
        end
    end
    % swap MSB and LSB bytes in case of TCP/IP connection
    if (strcmp(f.type, 'tcpip'))
        seqData = swapbytes(seqData);
    end
    for i = [realCh imagCh]
        if (i)
            if (showProgress(hMsgBox, sprintf('Downloading sequence ch%d...', i)))
                return;
            end
            xfprintf(f, sprintf(':STABle%d:RESet', i));
            chunkSize = 10000;
            offset = 0;
            len = length(seqData)/6;
            while (offset < len)
                eptr = min(len, offset + chunkSize);
                xbinblockwrite(f, seqData(6*offset+1:6*eptr), 'uint32', sprintf(':STABle%d:DATA %d,', i, offset));
                xfprintf(f, '');
                offset = eptr;
            end
            xfprintf(f, sprintf(':STABle%d:SEQuence:SELect %d', i, 0));
            xfprintf(f, sprintf(':STABle%d:DYNamic:STATe 0', i));
            xfprintf(f, sprintf(':FUNCtion%d:MODE STSC', i));
        end
    end
    retVal = xfprintf(f, sprintf(':INIT:IMMediate%d', 1));
end

function retVal = xxfprintf(f, s)
    % Send the string s to the instrument object f
    retVal = 0;
    fprintf(f, s);
end

function retVal = xfprintf(f, s, ignoreError)
    % Send the string s to the instrument object f
    % and check the error status
    % if ignoreError is set, the result of :syst:err is ignored
    % returns 0 for success, -1 for errors
    retVal = 0;
    % un-comment the following line to see a trace of commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s\n', s);
    end
    fprintf(f, s);
    result = query(f, ':syst:err?');
    if (isempty(result))
        fclose(f);
        errordlg({'The AWG firmware did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'}, 'Error');
        retVal = -1;
        return;
    end
    if (~exist('ignoreError', 'var') || ignoreError == 0)
        if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
            errordlg({'AWG firmware returns an error on command:' s 'Error Message:' result});
            retVal = -1;
        end
    end
end

function xbinblockwrite(f, data, format, cmd)
    % set debugScpi=1 in MATLAB workspace to log SCPI commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = "%s", format = %s, data = %d elements\n', cmd, format, length(data));
    end
    binblockwrite(f, data, format, cmd);
    fprintf(f, '');
end

function setup_sa(arbConfig, fc, fc_for_sa, sweeptime)
    try
        [arbConfig saConfig] = loadArbConfig();
        if (~isempty(strfind(arbConfig.model, 'DUC')))
            f = iqopen();
            if (~isempty(f))
                fprintf(f, sprintf(':carr1:freq %.0f,%g', floor(fc), fc - floor(fc)));
                fprintf(f, sprintf(':carr2:freq %.0f,%g', floor(fc), fc - floor(fc)));
                fclose(f);
            end
        end
        if (saConfig.connected)
            f = iqopen(saConfig);
            if (~isempty(f))
                span = 200e6;
                resbw = 300e3;
                fprintf(f, '*cls');
                fprintf(f, ':inst rtsa');
                r = query(f, ':syst:err?');
                if (strncmp(r, '+0', 2)) % RTSA is supported
                    fprintf(f, sprintf(':FREQuency:CENTer %g', fc));
                    fprintf(f, sprintf(':FREQuency:SPAN %g', 160e6));
                else
                    fprintf(f, sprintf(':FREQuency:CENTer %g', fc_for_sa));
                    fprintf(f, sprintf(':BWID %g', resbw));
                    fprintf(f, sprintf(':BWID:VID:AUTO ON'));
                    if (sweeptime ~= 0)
                        fprintf(f, sprintf(':SWEep:TIME %g', sweeptime));
                        fprintf(f, sprintf(':FREQuency:SPAN %g', 0));
                    else
                        fprintf(f, sprintf(':SWEep:TIME:AUTO ON'));
                        fprintf(f, sprintf(':FREQuency:SPAN %g', span));
                    end
                    fprintf(f, sprintf(':INIT:RESTart'));
                end
                fclose(f);
            else
                msgbox('Please observe AWG channel 1 on a spectrum analyzer', '', 'replace');
            end
        else
            msgbox('Please observe AWG channel 1 on a spectrum analyzer', '', 'replace');
        end
    catch e
        msgbox(e.message, 'Error', 'replace');
    end
end

function stop = showProgress(hMsgBox, text)
    stop = 0;
    try
        ch = get(hMsgBox, 'Children');
        msgbox(text, 'Please wait...', 'replace');
        drawnow;
    catch ex
        stop = 1;
    end
end
