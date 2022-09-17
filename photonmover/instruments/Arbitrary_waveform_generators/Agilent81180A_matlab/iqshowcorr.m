function iqshowcorr()
% plot the magnitude correction (and phase correction if available)
% If a filename is given, will take information from that file.
% Otherwise will take default file: ampCorr.mat
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

% try to read the correction
ampCorr = iqcorrection([]);
if (~isempty(ampCorr))
    figure(10);
    clf(10);
    hold off;
    if (size(ampCorr,2) > 2)  % complex correction available
        phase = -1 * 180 / pi * unwrap(angle(ampCorr(:,3)));
        % if phase is *very* small, plot it as zero to avoid confusion...
        if (max(abs(phase)) < 1e-10)
            phase = zeros(size(phase,1), size(phase,2));
        end
        subplot(2,1,1);
        plot(ampCorr(:,1), -1*ampCorr(:,2), '.-');
        xlabel('Frequency (Hz)');
        ylabel('dB');
        grid on;
        subplot(2,1,2);
        plot(ampCorr(:,1), phase, 'm.-');
        xlabel('Frequency (Hz)');
        ylabel('degree');
        grid on;
        set(10, 'Name', 'Frequency and Phase Response');
    else
        plot(ampCorr(:,1), -1 * ampCorr(:,2), '.-');
        set(10, 'Name', 'Frequency Reponse');
        xlabel('Frequency (Hz)');
        ylabel('dB');
        grid on;
    end
else
    errordlg('No correction file available. Please use "Calibrate" to create a correction file');
end
