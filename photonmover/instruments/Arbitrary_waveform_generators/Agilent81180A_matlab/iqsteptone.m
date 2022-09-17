%
% This class implements block-wise generation of a multi-tone signal
%
% T.Dippon, Keysight Technologies 2018
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

classdef iqsteptone < handle
    properties
        sampleRate   % samplerate
        numTones     % number of tones
        tone         % tone frequencies, can be scalar or vector
        magnitude    % magnitude in dB, can be scalar or vector
        phase        % phase in radian, can be scalar or vector
        fmfct        % FM function
        pmfct        % PM function
        amfct        % AM function
        spsf         % samples processed so far
    end
    methods
        function this = iqsteptone(varargin)
            sampleRate = [];
            numSamples = 0;
            tone = linspace(-250e6, 250e6, 21);
            magnitude = [];
            phase = 'random';
            normalize = 1;
            correction = 0;
            arbConfig = [];
            nowarning = 0;
            channelMapping = [1 0; 0 1];
            fmfctstr = [];
            pmfctstr = [];
            amfctstr = [];
            i = 1;
            while (i <= nargin)
                if (ischar(varargin{i}))
                    switch lower(varargin{i})
                        case 'samplerate';   sampleRate = varargin{i+1};
                        case 'numsamples';   numSamples = varargin{i+1};
                        case 'tone';         tone = varargin{i+1};
                        case 'magnitude';    magnitude = varargin{i+1};
                        case 'phase';        phase = varargin{i+1};
                        case 'pmfct';        pmfctstr = varargin{i+1};
                        case 'amfct';        amfctstr = varargin{i+1};
                        case 'normalize';    normalize = varargin{i+1};
                        case 'correction';   correction = varargin{i+1};
                        case 'arbconfig';    arbConfig = varargin{i+1};
                        case 'nowarning';    nowarning = varargin{i+1};
                        case 'channelmapping'; channelMapping = varargin{i+1};
                        otherwise error(['unexpected argument: ' varargin{i}]);
                    end
                else
                    error('string argument expected');
                end
                i = i+2;
            end

            arbConfig = loadArbConfig(arbConfig);
            if (isempty(sampleRate))
                sampleRate = arbConfig.defaultSampleRate;
            end
            this.sampleRate = sampleRate;
            this.numTones = length(tone);
            this.tone = this.fixlength(tone, this.numTones);
            
            % set magnitude
            if (isempty(magnitude))
                magnitude = zeros(this.numTones, 1);
            end
            this.magnitude = this.fixlength(10.^(magnitude/20), this.numTones);

            % set phase
            if (isempty(phase))
                phase = 'random';
            end
            if (ischar(phase))
                switch lower(phase)
                    case 'random'
                        % use the same sequence every time so that results are comparable
                        randStream = RandStream('mt19937ar'); 
                        reset(randStream);
                        phase = randStream.rand(1,this.numTones) * 2 * pi;
                        delete(randStream);
                    case 'random-no-seed'
                        phase = rand(1,this.numTones) * 2 * pi;
                    case 'zero'
                        phase = zeros(1,this.numTones);
                    case 'increasing'
                        phase = pi * linspace(-1, 1 - 1/this.numTones, this.numTones);
                    case 'parabolic'
                        phase = cumsum(pi * linspace(-1, 1 - 1/this.numTones, this.numTones));
                    otherwise
                        error(['invalid phase argument: ' phase]);
                end
            end
            this.phase = this.fixlength(phase, this.numTones);
            
            if (~isempty(amfctstr))
                eval(['this.amfct = @(t) ' amfctstr ';']);
            end
            if (~isempty(pmfctstr))
                eval(['this.pmfct = @(t) ' pmfctstr ';']);
            end
            this.reset();
        end
        
        function reset(this)
            this.spsf = 0;
        end
        
        function y = step(this, len)
            phaseOffset = repmat(this.phase, len, 1);
            if (~isempty(this.amfct))
                t = (this.spsf:this.spsf+len-1)'/this.sampleRate;
                am = this.amfct(t);
            else
                am = 1;
            end
            if (~isempty(this.pmfct))
                t = (this.spsf:this.spsf+len-1)'/this.sampleRate;
                pm = this.pmfct(t);
            else
                pm = 0;
            end
            tmp = (this.spsf:(this.spsf+len-1))';
            y = sum(am .* this.magnitude .* exp(1i*(2*pi*tmp*this.tone/this.sampleRate + pm + phaseOffset)), 2);
            this.spsf = this.spsf + len;
        end
    end
    
    methods(Static)
        function x = fixlength(x, len)
            if (len > 0)
                x = reshape(x, 1, length(x));
                x = repmat(x, 1, ceil(len / length(x)));
                x = x(1:len);
            end
        end
    end
end
