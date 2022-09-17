function [totalSamples, maxVal] = multi_pulse(varargin)
% Set up multiple pulses on M8190A, M8195A, M8121A
% 'sampleRate' - the samplerate that will be used by both M8190A modules
% 'pulseTable' - struct array that describes the desired pulses.
%                each struct element is expected to have the following
%                fields:
%                  pri, pw, tt, offset, span, ampl
%                which will generate a LFM chirp at CF, BW wide
% 'toneTable'  - struct array that describes tones with FM and AM
%                each stuct element is expected to have the following
%                fields:
%                offset, fmfreq, fmdev, amfreq, amdepth
% 'maxSamples' - limits the number of samples downloaded or written to a
%                file. If set to zero, will generate samples until waveform
%                repeats
% 'fc'         - center frequency (used in direct mode & DUC mode)
% 'function'   - 'display', 'save', 'download', 'check'
% 'filename'   - if function is 'save', the filename can optionally be
%                provided. If filename is empty, the user will be prompted
% 'filetype'   - if function is 'save', the filetype can optionally be
%                provided. If filetype is empty, filetype will be derived
%                from filename extension (see iqsavewaveform.m)
%
% T.Dippon, Keysight Technologies 2011-2018
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

if (nargin == 0)
    multi_pulse_gui;
    return;
end
debugPrint = 0;
% set default values - will be overwritten by arguments
sampleRate = [];
maxSamples = 0;
pulseTable = [];
toneTable = [];
correction = 0;
fct = 'display';
amplCutoff = -60;
showDropped = 0;
filename = [];
filetype = [];
normalize = 1;
segNum = 1;
maxVal = 1;
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
            case 'amplcutoff';     amplCutoff = varargin{i+1};
            case 'showdropped';    showDropped = varargin{i+1};
            case 'maxsamples';     maxSamples = varargin{i+1};
            case 'normalize';      normalize = varargin{i+1};
            case 'segmentnumber';  segNum = varargin{i+1};
            case {'chmap' 'channelmapping'}; chMap = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

hMsgBox = [];
% if (~strcmp(fct, 'check'))
%     hMsgBox = msgbox('Calculating Pulses. Please wait...', 'Please wait...', 'replace');
% end

useSeq = 0;
arbConfig = loadArbConfig();
if (isempty(sampleRate))
    sampleRate = arbConfig.defaultSampleRate;
end
% number of entries in the pulse table
pulseTableLen = length(pulseTable);
% the number of samples needed for pulse pattern to repeat (excl. antenna scan)
totalSamples = arbConfig.segmentGranularity;
% the number of samples needed for complete antenna scan
totalScanSamples = 1;
for i=1:pulseTableLen
    % number of pulses in *this* entry
    pulseTable(i).numPulse = max([length(pulseTable(i).pri) ...
                       length(pulseTable(i).pw) ...
                       length(pulseTable(i).tt) ...
                       length(pulseTable(i).span) ...
                       length(pulseTable(i).offset) ...
                       length(pulseTable(i).ampl)]);
    % extend pri to match the number of pulses
    pulseTable(i).pri    = fixlength(pulseTable(i).pri, pulseTable(i).numPulse);
    % PRI in samples
    pulseTable(i).prs    = round(pulseTable(i).pri * sampleRate);
    % sum of all PRI's in this entry (in samples)
    pulseTable(i).sumprs = round(sum(pulseTable(i).pri) * sampleRate);
    % running lcm of samples required to represent all pulses
    totalSamples = lcm(totalSamples, pulseTable(i).sumprs);
    if (debugPrint)
        fprintf('pulseTable(%d) - numSamples %.15g, lcm %.15g\n', i, pulseTable(i).sumprs, totalSamples);
    end
    % for antenna scans, always use sequence mode
    if (~strcmp(pulseTable(i).scanType, 'None'))
        useSeq = 1;
    end
    % unless we are operating in DUC mode, add center frequency to offset
    if (isempty(strfind(arbConfig.model, 'DUC')))
        pulseTable(i).offset = pulseTable(i).offset + fc;
    end
    % calculate scan formula
    pulseTable(i).scanOffset = rand(1,1);
    switch (pulseTable(i).scanType)
        case 'None'
            pulseTable(i).scanPerS = 1;
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
% go through all tones
toneTableLen = length(toneTable);
tone = [];
for i=1:toneTableLen
    % unless we are operating in DUC mode, add center frequency to offset
    if (isempty(strfind(arbConfig.model, 'DUC')))
        toneTable(i).offset = toneTable(i).offset + fc;
    end
    % find the minimum number of samples to generate the desired signal without phase discontinuities
    tone = [tone; reshape(toneTable(i).offset, length(toneTable(i).offset), 1)];
    if (toneTable(i).fmfreq ~= 0 && toneTable(i).fmdev ~= 0)
        tone = [tone; toneTable(i).fmfreq];
    end
    if (toneTable(i).amfreq ~= 0 && toneTable(i).amdepth ~= 0)
        tone = [tone; toneTable(i).amfreq];
    end
end
numTones = length(tone);
if (numTones > 0)
    [~,d] = rat(tone - round(tone));
    mult = d(1);
    for m = 2:numTones
        mnext = lcm(mult, d(m)); 
        if (mnext > 1e4)     % if numbers grow too big it does not make sense to find a common multiple...
            break;
        end
        mult = mnext;
    end
    div = sampleRate;
    for m = 1:numTones
        div = gcd(div, round(tone(m) * mult));
    end
    numSamples = round(sampleRate / div * mult);
    totalSamples = lcm(totalSamples, numSamples);
    if (debugPrint)
        fprintf('tones:');
        fprintf(' %.15g', tone);
        fprintf(' - numSamples %.15g, div %.15g, mult %.15g, lcm = %.15g\n', numSamples, div, mult, totalSamples);
    end
end
% check maximum number of samples
if (~isempty(maxSamples) && maxSamples > 0 && totalSamples > maxSamples)
    totalSamples = maxSamples;
end
% Determine the method to use. Only M8190A and M8195A sequencers are supported
if (isempty(strfind(arbConfig.model, 'M8190A')) && isempty(strfind(arbConfig.model, 'M8195A')))
    useSeq = 0;
end

if (totalScanSamples > totalSamples)
    totalSamples = totalScanSamples;
end

% now generate the pulses 
if (~useSeq)
    if (totalScanSamples > totalSamples)
        totalSamples = totalScanSamples;
    end
    % round up to the nearest AWG granularity
    totalSamples = ceil(totalSamples / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
    if (strcmp(fct, 'check'))
        return;
    end
    if (strcmp(fct, 'download') && totalSamples > arbConfig.maximumSegmentSize)
        errordlg(sprintf('Waveform too large to download. (Waveform size is %s samples, Memory size is %s samples)', iqengprintf(totalSamples), iqengprintf(arbConfig.maximumSegmentSize)));
        return;
    end
    maxVal = calculateAsOneSegment(hMsgBox, arbConfig, chMap, pulseTable, toneTable, totalSamples, sampleRate, fc, correction, fct, filetype, filename, segNum, normalize);
else
    maxVal = calculateAsSequence(hMsgBox, arbConfig, chMap, pulseTable, toneTable, totalSamples, sampleRate, fc, correction, fct, amplCutoff, showDropped);
end
try
    close(hMsgBox);
catch ex
end



% calculate one waveform segment that contains all pulses
function maxVal = calculateAsOneSegment(hMsgBox, arbConfig, chMap, pulseTable, toneTable, totalSamples, sampleRate, fc, correction, fct, filetype, filename, segNum, normalize)
maxVal = 1e-20;
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
        pmfct = sprintf('%g*-cos(2*pi*%g*t)', toneTable(i).fmdev/toneTable(i).fmfreq/2, toneTable(i).fmfreq);
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
        if (normalize && maxVal > scale)
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
                marker = [];
                if (sampleCnt ~= 0)
                    marker = zeros(length(iqsum), 1);
                end
                iqdownload(iqsum, sampleRate, 'arbConfig', arbConfig, 'channelMapping', chMap, 'marker', marker, 'segmentLength', totalSamples, 'segmentOffset', sampleCnt, 'segmentNumber', segNum);
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


% calculate the waveforms for sequences with antenna scans
function maxVal = calculateAsSequence(hMsgBox, arbConfig, chMap, pulseTable, toneTable, totalSamples, sampleRate, fc, correction, fct, amplCutoff, showDropped)
maxVal = 1;
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
    idx = find(pulseTable(i).amplvec < amplCutoff);
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
        downloadSeq(hMsgBox, arbConfig, chMap, pulseTable, toneTable, pulseTableLen, sampleRate, allStarts, gap, pEntryPtr, pIndexPtr, amplvec, amplCutoff, fc, correction, totalScanSamples);
    case 'save'
        errordlg('Save waveform is not implemented for waveforms that use sequencing');
    otherwise
        error(['unknown function: ', fct]);
end
%fprintf('download %g\n', toc);



% download the waveform segments and sequence
function downloadSeq(hMsgBox, arbConfig, chMap, pulseTable, toneTable, numEntries, sampleRate, allStarts, gap, pEntryPtr, pIndexPtr, amplvec, amplCutoff, fc, correction, totalScanSamples)
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
    atab = loadActionTable(hMsgBox, amplCutoff, amplResolution);
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
        iqdata = iqpulse('arbConfig', arbConfig, ...
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
            numAmpls = abs(amplCutoff / amplResolution);
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


function atab = loadActionTable(hMsgBox, amplCutoff, amplResolution)
% delete action table
iqseq('actionDeleteAll');
numActs = abs(amplCutoff / amplResolution);
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



function retVal = xxfprintf(f, s)
% Send the string s to the instrument object f
retVal = 0;
fprintf(f, s);


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


function xbinblockwrite(f, data, format, cmd)
% set debugScpi=1 in MATLAB workspace to log SCPI commands
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    fprintf('cmd = "%s", format = %s, data = %d elements\n', cmd, format, length(data));
end
binblockwrite(f, data, format, cmd);
fprintf(f, '');





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



function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);



function stop = showProgress(hMsgBox, text)
stop = 0;
try
    ch = get(hMsgBox, 'Children');
    msgbox(text, 'Please wait...', 'replace');
    drawnow;
catch ex
    stop = 1;
end
