function result = iqpowersensorcal(varargin)
% Generate amplitude correction based on power sensor measurement
% Arguments are given as attrtibute/value pairs. Possible arguments:
%  - offset: frequency offset in Hz that is added to all tones before
%         taking a measurement (use offset when tones are upconverted)
%         if offset is negative, tone frequencies are subtracted
%  - tone: vector of tones at which measurement is performed.
%  - fs: samplerate to be used
%  - update: if set to 0, will not write the ampCorr file. (default = 1)
%  - plot: if set to 0, will not plot the result (default = 1)
%  - recalibrate: If set to 1, the list of frequencies is taken from
%          the existing amplitude correction file (iqampCorrFilename()). The
%          measurement is added to the existing correction in this case.
%  - msgbox: msgbox handle (will be reused)
%  returns a vector of measured magnitudes or [], if calibration was
%  aborted or failed

%% parse optional arguments
arbConfig = [];
result = [];
tone = [];
fs = 0;
correction = 0;
magnitude = 0;
offset = 0;
update = 1;
doPlot = 1;
recalibrate = 0;
hMsgBox = [];
handles = [];
chMap = [1 0; 1 0];
usePerChannelCorr = 1;
compareToSA = 0;
normalize = 0;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'arbconfig'; arbConfig = varargin{i+1};
            case 'offset'; offset = varargin{i+1};
            case 'tone'; tone = varargin{i+1};
            case 'magnitude'; magnitude = varargin{i+1};
            case 'samplerate'; fs = varargin{i+1};
            case 'correction'; correction = varargin{i+1};
            case 'update'; update = varargin{i+1};
            case 'plot'; doPlot = varargin{i+1};
            case 'recalibrate'; recalibrate = varargin{i+1};
            case 'msgbox'; hMsgBox = varargin{i+1};
            case 'handles'; handles = varargin{i+1};
            case 'chmap'; chMap = varargin{i+1};
            case 'perchannelcorr'; usePerChannelCorr = varargin{i+1};
            case 'comparetosa'; compareToSA = varargin{i+1};
            case 'normalize'; normalize = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

% close message box - we do our own
if (~isempty(hMsgBox))
    close(hMsgBox);
end
% make sure tone vector is the correct shape (one column)
if (size(tone,2) > 1)
    tone = tone';
end

% make sure that the power sensor is configured
arbConfig = loadArbConfig(arbConfig);
if (~isfield(arbConfig, 'isPowerSensorConnected') || arbConfig.isPowerSensorConnected == 0)
    errordlg('Please configure the VISA address of a power sensor in the Instrument Configuration window');
    return;
end

chs = find(sum(chMap,2));   % vector of channel numbers on which the signal was downloaded
% if a list of frequencies is specified, use them as a starting point for a
% new correction. Otherwise use existing correction is used as a starting
% point. The measurement is added to the existing correction in this case.
[acs, oldCorr, err] = getOldCorr(arbConfig, tone, chs, recalibrate, usePerChannelCorr);
if (err)
    return;
end

%% establish a connection to power sensor
f = iqopen(arbConfig.visaAddrPowerSensor);
if (isempty(f))
    return;
end
h = iqwaitbar('Initializing Power Sensor, please wait...');
xfprintf(f, '*RST');
query(f, '*OPC?');
xfprintf(f, 'CAL:AUTO 0');
%xfprintf(f, 'CAL:ALL');
query(f, '*OPC?');
xfprintf(f, 'TRIG:SOUR IMM');
xfprintf(f, 'SENS:DET:FUNC AVER');
xfprintf(f, sprintf('AVER:COUNT %s', arbConfig.powerSensorAverages));
xfprintf(f, 'INIT:CONT OFF');
xfprintf(f, 'SENS:MRATE NORM');
xfprintf(f, 'UNIT:POW DBM');


if (compareToSA)
    [~, sa] = loadArbConfig();
    fSa = iqopen(sa.visaAddr);
    if (isempty(fSa))
        return;
    end
end

if (isempty(magnitude))
    magnitude = 0;
end
magnitude = fixlength(magnitude, length(tone));

% determine the crest factor of the overall signal - 
[sig, ~, ~, ~, ~] = iqtone('samplerate', fs, 'tone', tone, 'magnitude', magnitude, ...
    'correction', correction, 'channelMapping', chMap, 'normalize', 0, 'nowarning', 1, 'arbConfig', arbConfig);
rms = norm(sig) / sqrt(length(sig));
peak = max(abs(sig));
crest = peak / rms;

list = nan(length(tone), 1);
listSa = nan(length(tone), 1);
% now run the power measurement for each tone
for i = 1:length(tone)
    % download each tone individually
    if (h.canceling())
        break;
    end
    [sig, ~, ~, ~, newChMap] = iqtone('samplerate', fs, 'tone', tone(i), 'magnitude', magnitude(i), ...
        'correction', correction, 'channelMapping', chMap, 'normalize', 0, 'nowarning', 1, 'arbConfig', arbConfig);
    % scale the signal by number of tones and crest factor if multi-tone is scaled to full DAC range
    if (normalize)
        sig = sig / sqrt(length(tone)) / crest;
    end
    iqdownload(sig, fs, 'chMap', newChMap, 'arbConfig', arbConfig);
    xfprintf(f, sprintf(':SENS:FREQ:CW %.15g', tone(i) + offset));
    pause(0.2);
    res = query(f, 'READ?');
    meas = sscanf(res, '%g');
    if (meas < -100 || meas > 40)
        break;
    end
    list(i) = meas;
    t = tone(i); unit = 'Hz';
    if (t >= 1e9); t = t/1e9; unit = 'GHz';
    elseif (t >= 1e6); t = t/1e6; unit = 'MHz';
    elseif (t >= 1e3); t = t/1e3; unit = 'KHz';
    end
    h.update(i/length(tone), sprintf('Tone %d of %d (%s %s, %s dBm)', i, length(tone), iqengprintf(t,4), unit, iqengprintf(meas,4)));
    
    if (compareToSA)
        mag_s = query(fSa, 'CALC:MARK1:Y?');
        mag = sscanf(mag_s, '%g');
        listSa(i) = mag;
    end
    
    % check, if absolute magnitude correction is used
    if (isfield(acs, 'absMagnitude') && acs.absMagnitude)
        % calculate deviation from desired magnitude
        delta = list - acs.absMagnitude;
        deltaSa = listSa - acs.absMagnitude;
    else
        % calculate deviation from average
        delta = list - sum(list)/length(list);
        deltaSa = listSa - sum(list)/length(list);  % note: subtract same value to make deltas comparable
    end
    newCorr = oldCorr - delta;

    if (doPlot)
        figure(10);
        title('Magnitude deviation');
        hold off;
        plot(tone, delta, 'r.-');
        hold on; plot(tone, -1 * oldCorr, 'b.-');
        plot(tone, -1 * newCorr, 'k.-');
        if (compareToSA)
            plot(tone, deltaSa, 'm.-');
            legend('current', 'previous', 'new', 'spectrum analyzer');
        else
            legend('current', 'previous', 'new');
        end
        hold off;
        xlabel('Frequency (Hz)');
        ylabel('dB');
        grid on;
        drawnow();
    end
end
fclose(f);
try delete(h); catch; end


%% calculate the new correction factors
% some sanity check
if (length(list) ~= length(tone) || ~isempty(find(isnan(list), 1)))
    errordlg(sprintf(['Measurement aborted or unexpected power sensor result. \n' ...
        '(Did you set the Fc parameter correctly?)']));
    return;
end

%% update correction file
if (update)
    % save updated correction file
    if (usePerChannelCorr)
        if (~updatePerChannelCorr(acs, chs, tone, newCorr))
            return;
        end
    else
        % use ampCorr structure for calibration
        acs.ampCorr = [tone newCorr];
        save(iqampCorrFilename(), '-struct', 'acs');
    end
end

result = list;
end


%%
function [acs, oldCorr, err] = getOldCorr(arbConfig, tone, chs, recalibrate, usePerChannelCorr)
% get starting values for calibration
% NOTE: asme routine as in iqcal.m - should be unified
err = 1;
oldCorr = zeros(length(tone),1);
[ampCorr, perChannelCorr, acs] = iqcorrection([], 0, 'arbConfig', arbConfig);
if (usePerChannelCorr)
    if (~isempty(perChannelCorr) && (recalibrate || isempty(tone)))
        if (isfield(acs, 'AWGChannels') && ~isempty(acs.AWGChannels))
            chanList = acs.AWGChannels;
        else
            chanList = 1:(size(acs.perChannelCorr, 2) - 1);
        end
        chPos = find(findIndex(chs, chanList), 1);
        if (isempty(chPos))
            errordlg('No previous calibration for any of the current channels. Please uncheck "Apply Correction" and try again.');
            return;
        else
            if (~isempty(setdiff(round(tone), round(perChannelCorr(:,1)))))
                errordlg('No previous calibration exists for those frequency points. Please uncheck "Apply Correction" and try again.');
                return;
            end
            % the channel from which previous cal exists
            ch = chs(chPos);
            % find the index of this channel in the previously calibrated channels
            chPos = find(chanList == ch, 1);
            % find the index of tones in the previous calibration
            tidx = findIndex(tone, perChannelCorr(:,1));
            oldCorr = 20*log10(abs(perChannelCorr(tidx, chPos+1)));
        end
    end
else
    % use ampCorr structure for calibration
    if (~isempty(ampCorr) && (recalibrate || isempty(tone)))
        if (~isequal(ampCorr(:,1), tone))
            errordlg('Frequency points must be identical for re-calibration. Please perform initial calibration first.');
            return;
        end
        oldCorr = ampCorr(:,2);
    end
end
err = 0;
end


%%
function result = updatePerChannelCorr(acs, chs, tone, newCorr)
% update perChannelCorr structure and save updated ampCorr file
% NOTE: same routine as in iqcal.m - should be unified
result = 0;
if (~isfield(acs, 'perChannelCorr') || isempty(acs.perChannelCorr))
    % no perChannelCorr available yet
    acs.AWGChannels = chs;
    perChannelCorr = ones(length(tone),length(chs)+1);
    perChannelCorr(:,1) = tone;
    perChannelCorr(:,2:end) = repmat(10.^(newCorr/20), 1, length(chs));
    acs.perChannelCorr = perChannelCorr;
else
    res = questdlg('Do you want to overwrite the existing correction or merge with the existing correction?', 'Overwrite or Merge', 'Overwrite', 'Merge', 'Cancel', 'Overwrite');
    switch (res)
        case 'Merge'
            if (isfield(acs, 'AWGChannels') && ~isempty(acs.AWGChannels))
                chanList = acs.AWGChannels;
            else
                chanList = 1:(size(acs.perChannelCorr, 2) - 1);
            end
            newChan = union(chs, chanList);
            % create new list of tones. To avoid floating point rounding
            % problems, round frequencies to the closes integer Hz
            newFreq = union(round(acs.perChannelCorr(:,1)), round(tone));
            pc = ones(length(newFreq), length(newChan)+1);
            pc(:,1) = newFreq;
            for chIdx = 1:length(newChan)
                ch = newChan(chIdx);
                if (isempty(find(chs == ch, 1)))
                    % channel is only in acs, not in measurement -> interpolate at measured frequencies
                    chPos = find(chanList == ch, 1);
                    %idx = findIndex(round(acs.perChannelCorr(:,1)), newFreq);
                    pc(:, chIdx+1) = interp1(acs.perChannelCorr(:,1), acs.perChannelCorr(:, chPos+1), newFreq, 'linear', 1);
                elseif (isempty(find(chanList == ch, 1)))
                    % channel is only in measurement, not in acs -> interpolate at measured acs frequencies
                    % idx = findIndex(round(tone), newFreq);
                    pc(:, chIdx+1) = interp1(tone, 10.^(newCorr/20), newFreq, 'linear', 1);
                else
                    % channel is in measurement AND in acs
                    chPos = find(chanList == ch, 1);
                    % copy correction values from acs
                    idx = findIndex(round(acs.perChannelCorr(:,1)), newFreq);
                    pc(idx, chIdx+1) = acs.perChannelCorr(:, chPos+1);
                    % copy (or overwrite) correction values from measurement
                    idx = findIndex(round(tone), newFreq);
                    pc(idx, chIdx+1) = 10.^(newCorr/20);
                end
            end
            acs.AWGChannels = newChan;
            acs.perChannelCorr = pc;
        case 'Overwrite'
            acs.AWGChannels = chs;
            perChannelCorr = ones(length(tone),length(chs)+1);
            perChannelCorr(:,1) = tone;
            perChannelCorr(:,2:end) = repmat(10.^(newCorr/20), 1, length(chs));
            acs.perChannelCorr = perChannelCorr;
        otherwise
            return;
    end
end
save(iqampCorrFilename(), '-struct', 'acs');
result = 1;
end


function res = findIndex(s1, s2)
% return position of elements of s1 in s2
% e.g. findIndex([2 3 4], [6 4 2 1 3 0]) returns [3 5 2]
% if an element of s1 is not in s2, the corresponding index is zero
res = zeros(length(s1),1);
for i = 1:length(s1)
    tmp = find(abs(s2 - s1(i)) < 1, 1);
    if (isempty(tmp))
        res(i) = 0;
    else
        res(i) = tmp;
    end
end
end


function x = fixlength(x, len)
if (len > 0)
    x = reshape(x, 1, length(x));
    x = repmat(x, 1, ceil(len / length(x)));
    x = x(1:len);
end
end


function xfprintf(f, s)
% Send the string s to the instrument object f
% and check the error status

    if (evalin('base', 'exist(''debugCal'', ''var'')'))
        fprintf('cmd = %s\n', s);
    end
    fprintf(f, s);
    res = query(f, ':syst:err?');
    if (isempty(res))
        fclose(f);
        error(':syst:err query failed');
    end
    if (~strncmp(res, '+', 1))
        errordlg(sprintf('Error sending command: %s\n\n%s', s, res));
    end
end

