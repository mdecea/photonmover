function iqrsim(varargin)
% Direction of arrival simulation with a moving target
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

% if called without arguments, start the graphical UI
if (nargin == 0)
    iqrsim_gui;
    return;
end

% default values for parameters that are not explicitly defined
%--------------------------------------------------------------
% Number of discrete pulses to calculate.
% The higher this number, the more accurate the simulation
% HOWEVER: a larger number of pulses will take more time to calculate
numSteps = 50;
% interpolation method for flight path ('linear', 'pchip', 'spline')
interpolationMethod = 'pchip';
% position of the receivers (assumed to be stationary)
radarPos = [ 0 -1 0 ; 0 1 0 ];
%radarPos = [ 0 -.1 0 ];
% set to 1 to download to AWG, set to 0 to run animation only, 
% set to -1 to only draw initial graphs (no simulation)
downloadToAWG = 0;
% AWG sample rate
fs = 8e9;
% pulse width
pw = 20e-9;
% pulse repetition interval
pri = 2e-6;
% rise & fall time
tt = 2e-9;
% modulation type 'Increasing', 'Decreasing', etc. (see switch below)
modulationType = 'Increasing';
% frequency modulation on pulse
foffset = 200e6;
fspan = 0;
% external LO frequency
flo = 0;
% rise- and falltime functions (x will run from 0 to 1)
riseFct = @(x) (1-cos(pi*x))/2;     % raised cosine
fallFct = @(x) (1+cos(pi*x))/2;
% max. amplitude reduction in dB (>= 0)
amplRatioMax = 6;
% doppler exaggeration (-1:nominal, 0:no doppler at all, 0..1:doppler ratio of fc)
dopplerEx = 0;
% targetSelection can be either 'Circle' or 'User defined'
targetSelection = 'User defined';
% specify the path of the target in 3-dimensional space over time
%        time   X  Y   Z     (time in sec; X,Y,Z in m)
target = [ 0  -10 -10  0;    
          10   12   8  0 ];
ax = [];
arbConfig = [];
pulseShape = 'Raised Cosine';
showMsgBox = false;
hMsgBox = [];
triggerMode = 1;  % 1=continuous, 2=stepped, 3=dynamic
sigGen = 1;       % 1=RF, 2=IQ
for i = 1:2:nargin
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'axes';         ax = varargin{i+1};
            case 'msgbox';       showMsgBox = varargin{i+1};
            case 'numsteps';     numSteps = varargin{i+1};
            case 'download';     downloadToAWG = varargin{i+1};
            case 'samplerate';   fs = varargin{i+1};
            case 'pri';          pri = varargin{i+1};
            case 'pw';           pw = varargin{i+1};
            case 'tt';           tt = varargin{i+1};
            case 'pulseshape';   pulseShape = varargin{i+1};
            case 'fmformula';    fmFormula = varargin{i+1};
            case 'pmformula';    pmFormula = varargin{i+1};
            case 'amplratio';    amplRatioMax = varargin{i+1};
            case 'span';         fspan = varargin{i+1};
            case 'offset';       foffset = varargin{i+1};
            case 'modulationtype'; modulationType = varargin{i+1};
            case 'correction';   correction = varargin{i+1};
            case 'movingphase';  movingPhase = varargin{i+1};
            case 'extmovingphase'; extMovingPhase = varargin{i+1};
            case 'extlo';        flo = varargin{i+1};
            case 'dopplerex';    dopplerEx = varargin{i+1};
            case 'targetselection'; targetSelection = varargin{i+1};
            case 'targetpos';    target = varargin{i+1};
            case 'radarpos';     radarPos = varargin{i+1};
            case 'triggermode';  triggerMode = varargin{i+1};
            case 'siggen';       sigGen = varargin{i+1};
            case 'arbconfig';    arbConfig = varargin{i+1};
            otherwise
                error(['unexpected argument: ' varargin{i}]);
        end
    end
end

if (showMsgBox)
    hMsgBox = waitbar(0, 'Please wait...', 'Name', 'Please wait...', 'CreateCancelBtn', 'setappdata(gcbf,''cancel'',1)');
    setappdata(hMsgBox, 'cancel', 0);
end

% put the rest of the code in a try/catch block so that we can make sure
% that the waitbar gets deleted under all circumstances
try
switch (targetSelection)
    case 'Circle'
        target = [ linspace(0, 10, numSteps);
           target(1,2) * cos(2*pi*(1:numSteps)/numSteps);
           target(1,3) * sin(2*pi*(1:numSteps)/numSteps) ]';
    case 'Straight line'
    case 'User defined'
    otherwise
        error(['unknown targetSelection: ' targetSelection]);
end

%% calculation
% split the array
targetTime = target(:,1);
targetPos = target(:,2:end);
totalTime = max(targetTime) - min(targetTime);
% deltaTime is the time interval between position/speed calculations
deltaTime = totalTime / numSteps;
% time vector in deltaTime resolution
time = linspace(min(targetTime), max(targetTime), numSteps);
% target position at deltaTime resolution
pos = interp1(targetTime, targetPos, time, interpolationMethod);
% number of receivers
numRecv = size(radarPos,1);
% distance between target and radar over time
% posx and radx have dimensions 1:xyz 2:numRecv 3:numSteps
posx = shiftdim(repmat(shiftdim(pos, -1), [numRecv,1,1]), 2);
radx = repmat(shiftdim(radarPos, 1), [1,1,numSteps]);
dist = shiftdim(sqrt(sum((posx - radx) .^ 2)), 1);
% velocity in flight direction
vFlightDir = sqrt(sum(diff(pos)'.^2)) / deltaTime;
% velocity in the direction of the radar (for doppler)
vRadarDir = diff(dist')' / deltaTime;
% extend the vector to have the same number of elements as pos
vRadarDir(:,end+1) = 2*vRadarDir(:,end) - vRadarDir(:,end-1);
% speed of light
c = 3e8;
% doppler shift
doppler = (c - vRadarDir) ./ (c + vRadarDir);
% for testing purposes, pretend that the doppler shift is much larger
if (dopplerEx >= 0)
    dd = max(doppler(1:end) - 1) - min(doppler(1:end) - 1);
    if (dd ~= 0)
        doppler = dopplerEx * ((doppler - 1) / dd) + 1;
    end
end
% initial delay (pulse travels to target and back)
delay = dist / c;
% if requested, shift phase according to delay
phase = zeros(numRecv, numSteps);
if (exist('movingPhase', 'var') && movingPhase)
    phase = phase + 2 * pi * (floor(delay*fs)/fs * foffset);
end
if (exist('extMovingPhase', 'var') && extMovingPhase)
    phase = phase + 2 * pi * delay * flo;
end
% amplitude ratio
ddist = max(dist(1:end)) - min(dist(1:end));
if (ddist > 1e-12)
    amplRatio = amplRatioMax * (dist - min(dist(1:end))) / ddist;
else
    amplRatio = zeros(size(dist));
end

%% plot the results so far
if (~isempty(ax))
    hold(ax(1), 'off');
    plot(ax(1), pos(:,1), pos(:,2), '.-');
    hold(ax(1), 'on');
    rp = complex(radarPos(:,1), radarPos(:,2));
    plot(ax(1), [rp rp].', 's');
    plot(ax(1), targetPos(:,1), targetPos(:,2), 'k.');
    title(ax(1), 'target position (m)');
    grid(ax(1), 'on');
    hold(ax(2), 'off');
    plot(ax(2), time, dist, '.-');
    title(ax(2), 'distance from radar (m)');
    hold(ax(2), 'on');
    grid(ax(2), 'on');
    %plot(ax(2), time(1:end-1), vFlightDir, '.-');
    %title(ax(2), 'velocity in direction of flight (m/s)');
    %plot(ax(2), time, vRadarDir, '.-');
    %title(ax(2), 'velocity in direction of radar (m/s)');
end

%% calculate the pulse shape of a reflected radar signal including doppler

% first, determine waveform granularity (make sure IQTools is configured properly)
if (downloadToAWG == 1)
    arbConfig = loadArbConfig(arbConfig);
    granularity = arbConfig.segmentGranularity;
else
    granularity = 1;
end
% maximum duration of pulse envelope + initial delay (+ a few samples at the end for safety)
pTime = max(delay(1:end)) + 2*tt + pw / min(doppler(1:end)) + 6/fs;
% number of samples in the pulse - make sure it is a
% multiple of <granularity>. Zeros at the end don't hurt
pSamplesRaw = ceil(ceil(pTime * fs) / granularity) * granularity;
% make sure we have at least 257 vectors to avoid M8190A sequencer to complain
pSamples = max(pSamplesRaw, 257 * granularity);
%pSamples = pSamplesRaw;
% define FM and PM functions depending on the modulation type
switch lower(modulationType)
    case 'increasing'
        fmFunction = @(x) 2*x-1';
        pmFunction = @(x) 0';
    case 'decreasing'
        fmFunction = @(x) -2*x+1';
        pmFunction = @(x) 0';
    case 'v-shape'
        fmFunction = @(x) 4*abs(x-0.5)-1';
        pmFunction = @(x) 0';
    case 'inverted v'
        fmFunction = @(x) -4*abs(x-0.5)+1';
        pmFunction = @(x) 0';
    case 'barker-11'
        fmFunction = @(x) 0';
        tmp = [+1 +1 +1 -1 -1 -1 +1 -1 -1 +1 -1 0]; % from http://en.wikipedia.org/wiki/Barker_code
        pmFunction = @(x) pi/2 * tmp(floor(11*x)+1)';
    case 'barker-13'
        tmp = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1 0]; % from http://en.wikipedia.org/wiki/Barker_code
        fmFunction = @(x) 0';
        pmFunction = @(x) pi/2 * tmp(floor(13*x)+1)';
    case 'user defined'
        % convert fm and pm formulas into MATLAB functions
        try
            eval(['fmFunction = @(x) ' fmFormula ';']);
            eval(['pmFunction = @(x) ' pmFormula ';']);
        catch ex
            errordlg(ex.message);
        end
    otherwise
        error(['undefined modulation type: ' modulationType]);
end
% convert pulse shape into rise & fall functions
switch lower(pulseShape)
    case 'raised cosine'
        riseFct = @(x) (1-cos(pi*x))/2;
        fallFct = @(x) (1+cos(pi*x))/2;
    case 'trapezodial'
        riseFct = @(x) x;
        fallFct = @(x) 1-x;
    case 'zero signal during rise time'
        riseFct = @(x) 0;
        fallFct = @(x) 0;
    otherwise
        error(['undefined pulse shape: ' pulseShape]);
end
% calculate one pulse at a time - otherwise we run out of memory
clear seq;
seqIdx = 0;
for i=1:numSteps
    % pulse width changes with doppler (opposite direction as frequency)
    pw1 = repmat(pw,numRecv,1) ./ doppler(:,i);
    % initialize the pulse shape
    pShape = zeros(numRecv, pSamples);
    % calculate the indices between the parts of the pulse
    idx1 = floor(delay(:,i) * fs);     % end of initial delay
    idx2 = floor((delay(:,i) + tt) * fs); % end of rise time
    idx3 = floor((delay(:,i) + tt + pw1) * fs); % end of pw
    idx4 = floor((delay(:,i) + 2*tt + pw1) * fs); % end of pulse
    for k = 1:numRecv
        % calculate rise time
        range = (idx1(k)+1) : idx2(k);
        pShape(k,range+1) = riseFct(((range/fs) - delay(k,i))/tt);
        % pulse width
        range = (idx2(k)+1) : idx3(k);
        pShape(k,range+1) = 1;
        % fall time
        range = (idx3(k)+1) : idx4(k);
        pShape(k,range+1) = fallFct(((range/fs) - delay(k,i) - pw1(k) - tt)/tt);
        pShape(k,:) = pShape(k,:) * 10^(-amplRatio(k,i)/20);
    end
    % ---------- now calculate the modulation on pulse -------------
    pm = zeros(numRecv, pSamples);      % phase modulation
    fm = zeros(numRecv, pSamples);      % frequency modulation
    % assume the pulse on-time includes rise and fall times
    for k = 1:numRecv
        range = (idx1(k)+1) : idx4(k);
        % x runs from 0 to 1 over the pulse duration
        x = ((range/fs) - delay(k,i)) / (2*tt + pw1(k));
        fm(k,range+1) = (fspan/2 * fmFunction(x) + foffset) .* doppler(k,i);
        pm(k,range+1) = pmFunction(x) + phase(k,i);
    end
    % phase = integral (i.e. cumsum) of frequency
    pm2 = pm + 2 * pi / fs * cumsum(fm')';
    % put it all together: pulse shape is amplitude modulation
    iqdata = pShape .* exp(j .* pm2);
    idata = real(iqdata);
    numChan = numRecv;
    % if downloading IQ data, move the data accordingly
    if (sigGen == 2)
        numChan = 2 * numRecv;
        for k=1:numRecv
            idata(2*k-1,:) = real(iqdata(k,:));
            idata(2*k  ,:) = imag(iqdata(k,:));
        end
    end

    if (~isempty(ax))
        % animate the first three plots
        fmt = 'ro-';
        hold(ax(1), 'on');
        plot(ax(1), pos(1:i,1), pos(1:i,2), fmt);
        hold(ax(2), 'on');
        plot(ax(2), time(1:i), dist(:,1:i).', fmt);
%    plot(ax(2), time(1:i), vRadarDir(:,1:i).', fmt);
        plotIdx1 = max(0, floor(min(min(delay)) * fs) - 4);  % set plotIdx1 = 0 to start from beginning of segment
        plotIdx2 = pSamplesRaw - 1;
        plotRange = plotIdx1:plotIdx2;
        plot(ax(3), plotRange/fs, pShape(:,plotRange+1), '.-');
        title(ax(3), 'pulse envelope');
        xlim(ax(3), [plotIdx1/fs plotIdx2/fs]);
        ylim(ax(3), [-0.1 1.1]);
        grid(ax(3), 'on');
        % plot the pulse
        plot(ax(4), plotRange/fs, idata(:,plotRange+1));
        xlim(ax(4), [plotIdx1/fs plotIdx2/fs]);
        ylim(ax(4), [-1.1 1.1]);
        grid(ax(4), 'on');
        title(ax(4), 'pulse in time domain');
        % plot pulse on-time
%    focus = 1;
%    plotIdx1 = max(0, floor(delay(focus,i) * fs) - 4);
%    plotIdx2 = max(0, floor(delay(focus,i) * fs) + floor((pw / min(doppler(focus,:)) + 2*tt) * fs) + 4);
%    plotIdx3 = min(plotIdx2, length(idata)-1);
%    plotRange = plotIdx1:plotIdx3;
%    ylim(ax(4), [-1.1 1.1]);
%    plot(ax(4), plotRange/fs, idata(:,plotRange+1));
%    xlim(ax(4), [plotIdx1/fs plotIdx2/fs]);
%    title(ax(4), 'pulse on-time');
%    grid(ax(4), 'on');
    end

    % check if waitbar has been cancelled
    if (~isempty(hMsgBox) && getappdata(hMsgBox, 'cancel'))
        break;
    end
    if (~isempty(hMsgBox))
        waitbar(i/numSteps, hMsgBox, sprintf('Calculating step %d / %d', i, numSteps));
        figure(hMsgBox);
    end

    % pause briefly to allow display to be updated
    drawnow();
    
    % just update graph
    if (downloadToAWG == -1)
        break;
    end
    
    % download the pulse to the AWG and prepare sequence table
    if (downloadToAWG == 1)
        for k=1:numChan
            iqdownload(idata(k,:), fs, 'segmentNumber', i, 'keepOpen', 1, 'run', 0, ...
                'channelMapping', double([(k==1) 0; (k==2) 0; (k==3) 0; (k==4) 0]));
        end
    end
    segmentAdvanceMode = 'Auto';
    if (triggerMode == 2)  % stepped
        sequenceAdvanceMode = 'Stepped';
    else
        sequenceAdvanceMode = 'Auto';
    end
    seqIdx = seqIdx + 1;
    seq(seqIdx).segmentNumber = i;    % segment #
    seq(seqIdx).segmentLoops = 1;    % loop count
    seq(seqIdx).segmentAdvance = segmentAdvanceMode;
    seq(seqIdx).markerEnable = true; % marker
    seq(seqIdx).sequenceInit = 1;    % seq init
    seq(seqIdx).sequenceEnd = 0;    % seq end
    seq(seqIdx).sequenceLoops = floor(deltaTime/pri); % loop
    seq(seqIdx).sequenceAdvance = sequenceAdvanceMode;    % seq adv
    if (triggerMode ~= 1)
        % in stepped or dynamic mode, just program the pulse segemnt (no idle)
        seq(seqIdx).sequenceEnd = 1;
    else
        % the pause segment
        seqIdx = seqIdx + 1;
        seq(seqIdx).segmentNumber = 0;      % idle segment
        seq(seqIdx).segmentLoops = max(1280, floor(pri * fs) - pSamples); % idle duration
        seq(seqIdx).segmentAdvance = 'Auto';
        seq(seqIdx).sequenceInit = 0;    % seq init
        seq(seqIdx).sequenceEnd = 1;    % seq end
        seq(seqIdx).sequenceAdvance = sequenceAdvanceMode;    % seq adv
    end
end

if (downloadToAWG == 1)
    % set the scenario end flag in the last sequence table entry
    seq(seqIdx).scenarioEnd = 1;
    % fprintf('downloading sequence...\n');
    cm = double([(numChan>=1) 0; (numChan>=2) 0; (numChan>=3) 0; (numChan>=4) 0]);
    iqseq('define', seq, 'keepOpen', 1, 'run', 0, 'channelMapping', cm);
    switch (triggerMode)
        case 1 % continuous
            iqseq('mode', 'STSC', 'channelMapping', cm);
        case 2 % stepped
            iqseq('trigAdvance', 'trigger', 'channelMapping', cm);
            iqseq('mode', 'STSC', 'channelMapping', cm);
        case 3 % dynamic
            iqseq('dynamic', 1, 'channelMapping', cm);
            iqseq('triggerMode', 'triggered', 'channelMapping', cm);
            iqseq('mode', 'ARBitrary', 'channelMapping', cm);
    end
    f = iqopen();
    result = query(f, ':syst:err?');
    if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
        errordlg({'Instrument returns an error:' result});
    end
    fclose(f);
end

catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end

if (exist('hMsgBox', 'var') && ~isempty(hMsgBox))
    try
        delete(hMsgBox);
    catch
    end
end

end
