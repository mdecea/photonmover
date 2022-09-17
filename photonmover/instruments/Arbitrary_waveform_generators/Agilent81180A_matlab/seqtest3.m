function seqtest3()
% Demonstration of M8190A sequencing capabilities
% using a number of different radar pulses.
% This demo also shows how to set up "idle" segments to generate a pause
% without using up waveform memory.
%
% AWG Configuration has to be set up using IQtools config dialog
% before using this function
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 


fs = 4e9;       % sample rate
fc = 800e6;     % center frequency for pulses
span = 250e6;   % modulation BW
pw = 1e-6;      % pulse width
pri = 10e-6;    % pulse repetition interval (without additional pause segments)
dur = 1;        % how long to loop the same pulse shape before moving to the next one (in seconds)
tt = 50e-9;     % rise and fall time for the pulses
fm = {'2*x-1', 'abs(4*x-2)-1', 'sin(2*pi*x)', '(2.*x-1).^3'};

% make sure that we can connect to the M8190A
f = iqopen();
if (isempty(f))
    return;
end
fprintf(f, ':abort');

% delete all waveform segments before programming new ones
iqseq('delete', [], 'keepOpen', 1);
% calculate and download waveform segments
for i=1:length(fm)
    signal = iqpulse('sampleRate', fs, 'offset', fc, 'span', span, ...
        'PRI', 2*pw, 'PW', pw, 'riseTime', tt, 'fallTime', tt, ...
        'chirpType', 'user defined', 'fmformula', fm{i});
    % fprintf('downloading segment #%d...\n', i);
    iqdownload(signal, fs, 'segmentNumber', i, 'keepOpen', 1);
end
% set up the sequence
advanceMode = 'Auto';       % replace 'Auto' with 'Conditional' to wait for an event
clear seq;
for i=1:length(fm)
    % the pulse segment
    seq(2*i-1).segmentNumber = i;    % segment #
    seq(2*i-1).segmentLoops = 1;    % loop count
    seq(2*i-1).segmentAdvance = advanceMode;
    seq(2*i-1).markerEnable = true; % marker
    seq(2*i-1).sequenceInit = 1;    % seq init
    seq(2*i-1).sequenceEnd = 0;    % seq end
    seq(2*i-1).sequenceLoops = floor(dur/pri); % loop
    seq(2*i-1).sequenceAdvance = advanceMode;    % seq adv
    % the pause segment
    seq(2*i-0).segmentNumber = 0;      % idle segment
    seq(2*i-0).segmentLoops = floor((pri-2*pw) * fs); % idle duration
    seq(2*i-0).segmentAdvance = advanceMode;
    seq(2*i-0).sequenceInit = 0;    % seq init
    seq(2*i-0).sequenceEnd = 1;    % seq end
    seq(2*i-0).sequenceAdvance = advanceMode;    % seq adv
end
% set the scenario end flag in the last sequence table entry
seq(2*length(fm)).scenarioEnd = 1;
% fprintf('downloading sequence...\n');
iqseq('define', seq, 'keepOpen', 1);
% switch to "scenario" mode and run

% file should still be open due to 'keepOpen' arguments above
%f = iqopen();
fprintf(f, ':abort');
fprintf(f, ':func1:mode stsc');
fprintf(f, ':func2:mode stsc');
fprintf(f, ':init:imm');
% fprintf(sprintf('Result = %s', query(f, ':syst:err?')));
fclose(f);

end
