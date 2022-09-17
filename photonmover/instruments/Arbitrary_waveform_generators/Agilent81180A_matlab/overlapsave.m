%
% This class implements blockwise FIR filtering using the overlap-save method
% It performs block-wise operation and is intended for use with large data
% sets. Optionally, the resulting waveform can be decimated.
%
% T.Dippon, Keysight Technologies 2015-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

classdef overlapsave < handle
    properties
        H            % FFT(h)
        M            % length(h);
        N            % convenient FFT size
        D            % decimation factor
        R            % remainder for decimation
        prevData     % remember previous data chunk
    end
    methods
        function this = overlapsave(h,d)
            % construct an overlap-and-save object
            % h is the desired FIR impulse reponse
            % d (optional) is the decimation factor
            this.M = length(h);
            this.N = 2^ceil(log2(4*this.M));
            this.H = fft(h, this.N);
            if (exist('d', 'var'))
                this.D = d;
            else
                this.D = 1;
            end
            this.reset();
        end
        function reset(this)
            this.prevData = [];
            this.R = 0;
        end
        function y = filter(this, x)
            % Apply the FIR to a "chunk" of waveform (x).
            % Consecutive calls to this method will return a continuous waveform when appended to each other
            step = this.N - this.M + 1;
            x = [this.prevData; reshape(x, length(x), 1)];
            L = length(x);
            ylen = floor((L-this.N)/step+1)*step;
            y = zeros(ylen, 1);
            pos = 0;
            while pos+this.N <= L
                ytmp = ifft(fft(x(1+pos:this.N+pos), this.N) .* this.H, this.N);
                y(1+pos:step+pos) = ytmp(this.M : this.N);    % discard M-1 y-values
                pos = pos + step;
            end
            this.prevData = x(pos+1:end);
            if (this.D > 1)
                y = downsample(y, this.D, this.R);
                this.R = mod(this.R - ylen, this.D);
            end
            if (isreal(x))
                y = real(y);
            end
        end
    end
    methods(Static)
        function h = makeFIR(fs, freq, cplxCorr, fpoints)
            % Create an FIR from an IQtools perChannelCorr.
            % If fpoints is not specified, make the frequency resolution as "fine" as in the
            % frequency spacing in freq. Use at least 64 points
            if (~exist('fpoints', 'var') || isempty(fpoints))
                fpoints = 64;
                ldspacing = ceil(log2(fs / fpoints / min(diff(freq))));
                if (ldspacing > 0)
                    fpoints = fpoints * 2^ldspacing;
                end
            end
            % if we don't have negative frequencies, mirror them
            if (min(freq) >= 0)
                if (freq(1) == 0)            % don't duplicate zero-frequency
                    startIdx = 2;
                else
                    startIdx = 1;
                end
                freq = [-1 * flipud(freq); freq(startIdx:end)];
                cplxCorr = [conj(flipud(cplxCorr)); cplxCorr(startIdx:end)];
            end
            % extend the frequency span to +/- fs/2
            % assume flat response before first, resp. after last correction value
            if (freq(1) > -fs/2)
                freq     = [-fs/2;        freq];
        %        cplxCorr = [ cplxCorr(1); cplxCorr];
                cplxCorr = [ 0; cplxCorr];
            end
            if (freq(end) < fs/2)
                freq     = [freq;     fs/2];
        %        cplxCorr = [cplxCorr; cplxCorr(end)];
                cplxCorr = [cplxCorr; 0];
            end
            % create a vector of equally spaced frequency points
            newfreq = linspace(-fs/2, fs/2 - fs/fpoints, fpoints)';
            % interpolate the correction at the new, equidistant frequency points
            newCorr = interp1(freq, cplxCorr, newfreq, 'linear');
            % derive a filter using inverse FFT
            h = fftshift(ifft(fftshift(newCorr)));
            % apply a window to smooth out the tails
            h = h .* [0; window(@blackmanharris, length(h)-1)];
        end
    end
end
