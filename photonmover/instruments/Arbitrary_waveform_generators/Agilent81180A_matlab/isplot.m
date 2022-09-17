function isplot(data, sampleRate, dataRate)
% isplot plots a serial data waveform and analyzes jitter
% Arguments:
% data - signal vector
% sampleRate - sample rate in Hz
% dataRate - data Rate in bits/s (optional)
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 


% make sure data is of the correct format
if (isempty(data))
    return;
end
if (~isvector(data))
    error('data must be a vector');
end
if (size(data,2) > 1)
    data = data.';
end
if (~isreal(data))
    qdata = imag(data);
    data = real(data);
else
    qdata = [];
end

% modify data to be symmetric around zero
maxdata = max(data);
mindata = min(data);
midpoint = (maxdata + mindata) / 2;
amplitude = (maxdata - mindata);
% Generate a vector with the sign of the data if it is outside
% of the guardband and zero if it is inside the guardband. 
guardband = amplitude / 20;
sig = (data > midpoint + guardband) - (data <= midpoint - guardband); 

% Find the index of all the points outside of the guardband 
idx = find(sig);

% Generate indices of the transition from one state to the other. 
% Remember a derivative (diff) is zero for constant values and a number
% if there is a change. 
w = find(diff(sig(idx)));
if (length(w) < 2)
    errordlg('isplot: input must contain at least two edges');
end

idx1 = idx(w); % Valid Point before Crossing 
idx2 = idx(w+1); % Valid Point after Crossing 
y1 = data(idx1) - midpoint;
y2 = data(idx2) - midpoint; % Get y values for interp 

% Find crossing using linear interpolation 
% index_value = current_index - current_y/slope 
% Times are the index_value/SampleRate. 
edgetimes = ((idx1 - y1.*(idx2-idx1)./(y2-y1))-1)/sampleRate;

% if the dataRate is not specified, try to estimate it
if (~exist('dataRate'))
    % find the durations of 1's or 0's 
    de = diff(edgetimes);
    % assume that bit duration is the shortest duration of a 1 or 0 
    estimatedBitTime = min(de);
    % find out how many bits are in each period
    df = round(de / estimatedBitTime);
    totalTime = (edgetimes(end) - edgetimes(1));
    totalBits = sum(df);
    % calculate dataRate as: total number of bits / (last edge - first edge)
    dataRate = totalBits / totalTime;
    %fprintf('estimated data rate: %s\n', iqengprintf(dataRate));
end
% better estimate on totalBits
totalTime = length(data) / sampleRate;
totalBits = round(dataRate * totalTime);
%fprintf('number of bits: %s\n', iqengprintf(totalBits));

% make sure we start close to an integral clock number in order to 
% minimize the chance of jitter overrun into the next UI.
% Take the average from the first 5 edges to find the correction value
t = edgetimes(1:min(5,length(edgetimes))) * dataRate;
corrA = (t - round(t)) / dataRate;
corr = sum(corrA) / length(corrA);
edgetimes = edgetimes - corr;

% Derive the ideal clock based on the symbol rate.
clocks = round(edgetimes * dataRate); 

% If the jitter is less than +/- 0.5 UI, then the simple formula
%      clocks = round(edgetimes * dataRate); 
% works. However, if the jitter exceeds 0.5 UI this does not work,
% because the algorithm will assume that the transition belongs to 
% the "next" bit.
% Workaround: If we assume that the TIE is a smooth curve, we can
% detect overflows by looking at the first difference of the 
% deviation of real clocks vs. ideal clock
deviation = (edgetimes * dataRate) - clocks;
threshold = 0.5;
df = diff(deviation);
ds = [0; cumsum((df > threshold) - (df < -threshold))];
deviation = deviation - ds;
% center deviation around zero since we don't know the absolute value
deviation = deviation - (sum(deviation) / length(deviation));

% ready to plot
figure(1);
subplot(2,1,1);
t = totalTime * linspace(0, 1-1/length(data), length(data));
if (~isempty(qdata))
    plot(t, [data qdata], '.-');
else
    plot(t, data, 'b.-');
end
xlim([0 totalTime]);
ymin = mindata - 0.1 * amplitude;
ymax = maxdata + 0.1 * amplitude;
ylim([ymin ymax]);
xlabel('time (s)');
ylabel('data');
subplot(2,1,2);
plot(edgetimes, deviation, 'r.-');
xlim([0 totalTime]);
% if deviation is *really* large, we probably have SSC on it
if (max(abs(deviation)) <= 0.5)
    ylim([-0.5 0.5]);
end
xlabel('time (s)');
ylabel('jitter (UI)');
end
