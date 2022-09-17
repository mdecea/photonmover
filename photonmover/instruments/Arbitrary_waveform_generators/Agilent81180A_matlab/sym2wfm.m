%
% Convert serial data into a waveform with arbitrary resampling.
% Input data can be binary or multi-level (in the range 0...1)
% Conversion is performed blockwise in order to support large data sets.
%
% T.Dippon, Keysight Technologies 2015-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

classdef sym2wfm < handle
    properties
        tts             % transition time in number of samples
        sps             % samples per symbol
        prevData        % previous symbols
        prevOffset      % previous offset in units of symbols
    end
    methods
        function this = sym2wfm(sps, transitionTime)
            % constructor for convesion
            % input arguments: samples per symbol (can be non-integer)
            % transition time in units of UI
            this.sps = sps;
            this.tts = transitionTime * this.sps;
            this.init();
        end
        function init(this)
            % initialize a new conversion (delete history)
            this.prevData = [];
            this.prevOffset = 0;
        end
        function samples = convert(this, data, maxSamples)
            % Convert serial data into a waveform using the given sps and transition time.
            % Consecutive calls to this method will return a continuous waveform when appended to each other
            data = reshape(data, length(data), 1); % make sure data is a column-vector
            numSymbols = length(data) + this.prevOffset - 1; % number of symbols that will be processed. Subtract 1 because the last symbol will never be processed because the transition is unknown
            data = [this.prevData; data];       % prepend previous data
            numSamples = floor(this.sps * (numSymbols + 1e-9)); % add a small fraction of a symbol to avoid cutting of the last sample of an integer number of samples
            if (exist('maxSamples', 'var'))     % limit the number of output samples if desired
                numSamples = min(numSamples, maxSamples);
            end
            samples = zeros(numSamples, 1);     % resulting waveform
            dpos = find(diff(data));            % find transitions in the data pattern (in units of symbols)
            pt = this.sps * (dpos - length(this.prevData) + this.prevOffset - 0.5) + 1; % transitions position in units of samples
            pt(end+1) = numSamples + this.tts;  % add one more point at the end to avoid array index violation
            dpos(end+1) = 0;                    % dito
            k = 1;                              % k counts transitions
            newlev = data(dpos(1)+1);           % new level is the data value after the first transition
            oldlev = data(1);                   % previous level is tht data value before the first transition
            i = 1;                              % i counts samples
            tts2 = this.tts/2;                  % half transition time (pre-calculated for speed optimization)
            while i <= numSamples
                if (i <= pt(k) - tts2)          % before transition
                    samples(i) = oldlev;        %   set to previous level
                    i = i + 1;                  %   and go to next sample
                elseif (i >= pt(k) + tts2)      % after transition
                    k = k + 1;                  %   check next transition (don't increment sample ptr!)
                    oldlev = newlev;            %   remember previous level
                    newlev = data(dpos(k)+1);   %   load new level
                else                            % during the transition
                    m = (i - (pt(k) - tts2)) / this.tts; % determine where we are inside the transition
                    % sample value is on a raised cosine shape between old and new level
                    samples(i) = oldlev + (cos(pi*(m-1))+1)/2 * (newlev - oldlev);
                    i = i + 1;
                end
            end
            % remember how many (fractional) symbols need to be considered on the next call of this method
            this.prevOffset = numSymbols + 1 - numSamples / this.sps;
            this.prevData = data(end - ceil(this.prevOffset) + 1:end);
            % shift from [0...1] to [-1...+1]
            samples = 2 * samples - 1;
        end
    end
end
