function iqnoiseseq(varargin)
% This function generates bandlimited noise, optionally with a notch.
% Unlike the basic iqnoise function, the sequencer is used to avoid
% individual tones and increase the "randomness" of the noise signal.
% Calling the function will calculate AND DOWNLOAD the noise signal
%
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sample rate in Hz
% 'numSamples' - number of samples oer waveform
% 'numSegments' - number of segments (numSeg^2 segments will be created)
% 'numSeqSteps' - number of steps in sequence table
% 'start' - start frequency in Hz
% 'stop' - stop frequency in Hz
% 'notchFreq' - notch center frequency in Hz (can be a vector)
% 'notchSpan' - notch width in Hz (can be a vector)
% 'notchDepth' - attenuation of notch
% 'correction' - if set to 1, freq/phase response correction will be applied
% 'channelMapping' - defines which channel to download the noise signal to
%
% T.Dippon, Keysight Technologies 2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS.

%% parse arguments
if (nargin == 0)
    iqnoiseseq_gui;
    return;
end
sampleRate = 12e9;
numSamples = 76800;
numSegm = 10;
numSeqSteps = 100000;
startFreq = 450e6;
stopFreq = 550e6;
notchFreq = [];
notchSpan = [];
notchDepth = [];
correction = 0;
arbConfig = [];
channelMapping = [1 0; 0 1];
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate'; sampleRate = varargin{i+1};
            case 'numsamples'; numSamples = varargin{i+1};
            case 'numsegments';numSegm = varargin{i+1};
            case 'numseqsteps';numSeqSteps = varargin{i+1};
            case 'start';      startFreq = varargin{i+1};
            case 'stop';       stopFreq = varargin{i+1};
            case 'notchfreq';  notchFreq = varargin{i+1};
            case 'notchspan';  notchSpan = varargin{i+1};
            case 'notchdepth'; notchDepth = varargin{i+1};
            case 'correction'; correction = varargin{i+1};
            case 'channelmapping'; channelMapping = varargin{i+1};
            case 'arbconfig';  arbConfig = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

% load arbconfig parameters
arbConfig = loadArbConfig(arbConfig);
% check frequencies
if ((startFreq > sampleRate / 2) || (startFreq < -sampleRate / 2) || ...
        (stopFreq > sampleRate / 2) || (stopFreq < -sampleRate / 2) || ...
        (~isempty(find(notchFreq > sampleRate / 2))) || (~isempty(find(notchFreq < -sampleRate / 2))))
    errordlg('Frequencies must be in the range -Fs/2...Fs/2', 'Error');
    error('Frequencies must be in the range -Fs/2...Fs/2');
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

if (numSegm * numSegm * numSamples > arbConfig.maximumSegmentSize)
    errordlg('Out of waveform memory: numSamples * numSegments ^ 2 must be less or equal to available waveform memory');
    return
end

% make sure that numSamples matches the granularity
segLen = floor(numSamples / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
% segment length variation
gran = arbConfig.segmentGranularity;

% just as a sanity check - make sure we can talk to the AWG
if (~iqoptcheck(arbConfig, {'M8190A', 'M8195A'}, 'SEQ', []))
    return;
end

hMsgBox = waitbar(0, 'Please wait...');
try
    doWaveformDownload = 1;
    if (doWaveformDownload)
        % calculate <numSegm> different noise waveforms
        % each waveform has slightly different length to avoid beat frequency
        % in the sequence
        for i = 1:numSegm
            waitbar(i/numSegm/2, hMsgBox, sprintf('Calculating waveform %d/%d. Please wait...', i, numSegm));
            len(i) = segLen + i*gran;
            seg{i} = real(iqnoise('sampleRate', sampleRate, 'numSamples', len(i), ...
                'start', startFreq, 'stop', stopFreq, ...
                'notchFreq', notchFreq, 'notchDepth', -300, 'notchSpan', notchSpan));
            %     freq = startFreq + i * (stopFreq - startFreq) / numSegm;
            %     seg{i} = real(iqtone('sampleRate', fs, 'numSamples', len(i), ...
            %         'tone', freq, 'nowarning', 1))';
            if (correction)
                seg(i) = iqcorrection(seg(i), sampleRate, 'chMap', channelMapping);
            end
            win{i} = (cos(pi*(1:len(i))'/len(i))+1)/2;
        end
        
        % create numSegm * numSegm waveforms with smooth transitions all the
        % possible combinations of segments
        for i = 1:numSegm
            waitbar(i/numSegm/2, hMsgBox, sprintf('Downloading waveform %d/%d. Please wait...', i, numSegm));
            for k = 1:numSegm
                newSeg = zeros(max(len(i), len(k)), 1);
                newSeg(1:len(k)) = win{k} .* seg{k};
                newSeg(end-len(i)+1:end) = newSeg(end-len(i)+1:end) + (1-win{i}) .* seg{i};
                iqdownload(newSeg, sampleRate, 'arbConfig', arbConfig, 'segmentNumber', numSegm*(i-1)+k, 'channelMapping', channelMapping, 'run', 0, 'keepOpen', 1);
            end
        end
    end
    
    % define a random sequence of segments
    segNum = randi([1 numSegm], numSeqSteps, 1);
    % create a certain number of duplicates that can be looped
    %nRpt = 2;
    %idx = 2:nRpt:length(segNum);
    idx = [];
    loopCnt = 10000;
    segNum(idx) = segNum(idx-1);
    % last segment number must match the first to get a clean wrap-around
    segNum(end+1) = segNum(1);
    
    %% sequence table download
    seq = uint32(zeros(6*numSeqSteps, 1));
    m1 = uint32(hex2dec('FFFFFFFF'));
    pc = -1;
    for i = 1:numSeqSteps
        if (floor(i/numSeqSteps*10) > pc)
            pc = floor(i/numSeqSteps*10);
            waitbar(0.5+i/numSeqSteps/2, hMsgBox, sprintf('Calculating sequence %d%%. Please wait...', pc*10));
        end
        i6 = 6 * i;
        seq(i6-5) = 0;  % ctrl
        seq(i6-4) = 1;  %
        seq(i6-3) = ismember(i+1, idx) * (loopCnt-1) + 1;  % segment loops
        seq(i6-2) = numSegm*(segNum(i+1)-1)+segNum(i);
        seq(i6-0) = m1;
    end
    seq(1) = hex2dec('10000000');
    seq(end-5) = hex2dec('60000000');
    waitbar(0.99, hMsgBox, sprintf('Downloading sequence. Please wait...'));
    f = iqopen(arbConfig);
    for ch = find(channelMapping(:,1) + channelMapping(:,2))';
        fprintf(f, sprintf(':ABORt%d', ch));
        binblockwrite(f, seq, 'uint32', sprintf(':STAB%d:DATA 0,', ch));
        fprintf(f, '');
        fprintf(f, sprintf(':STABle%d:SEQuence:SELect %d', ch, 0));
        fprintf(f, sprintf(':STABle%d:DYNamic:STATe 0', ch));
        fprintf(f, sprintf(':FUNCtion%d:MODE STSC', ch));
    end
    fprintf(f, sprintf(':INIT:IMM'));
    res = strtrim(query(f, ':SYST:ERR?'));  % must issue a query before closing to flush the buffer
    fclose(f);
catch(ex)
end
delete(hMsgBox);

