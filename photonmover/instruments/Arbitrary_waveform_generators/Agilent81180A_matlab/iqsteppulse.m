%
% This class implements block-wise generation of pulsed signals
% Relies on iqpulse() for calculation of the pulse waveform
% Antenna scan is implemented in this class
%
% T.Dippon, Keysight Technologies 2018-2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

classdef iqsteppulse < handle
    properties
        pulse        % the pulse
        plen         % length of the pulse
        spsf         % samples processed so far
        spsfm        % samples processed so far, modulo pulse length
        samplerate   % samplerate
        scantype     % 'None', 'Conical', 'Circular'
        scanfct      % function that describes the amplitude vs. scan phase, e.g. sinc(x).^3
        scanperiod   % scan period in seconds
        scanaz       % 3 dB angle
        scansquint   % squint angle for conical scans
        scanoffset   % offset of start of scan
        scanps       % scan period in samples (calculated from scanperiod)
        ampFormula   % amplitude formula (calculated from scanfct)
        xFormula     % x-scaling formula (calculated from scanaz, scansquint)
    end
    methods
        function this = iqsteppulse(varargin)
            i = 1;
            this.scantype = 'None';
            this.scanfct = 'sinc(x).^3';
            this.scanperiod = 0.01;
            this.scanaz = 4;
            this.scansquint = 3;
            this.scanoffset = 0;
            while (i <= length(varargin))
                if (ischar(varargin{i}))
                    switch lower(varargin{i})
                        case 'samplerate'
                            this.samplerate = varargin{i+1};
                            i = i+2;
                        case 'scantype'
                            this.scantype = varargin{i+1};
                            varargin(i:i+1) = [];
                        case 'scanfct'
                            this.scanfct = varargin{i+1};
                            varargin(i:i+1) = [];
                        case 'scanperiod'
                            this.scanperiod = varargin{i+1};
                            varargin(i:i+1) = [];
                        case 'scanaz'
                            this.scanaz = varargin{i+1};
                            varargin(i:i+1) = [];
                        case 'scansquint'
                            this.scansquint = varargin{i+1};
                            varargin(i:i+1) = [];
                        case 'scanoffset'
                            this.scanoffset = varargin{i+1};
                            varargin(i:i+1) = [];
                        otherwise
                            i = i+2;
                    end
                end
            end
            switch lower(this.scantype)
                case 'none'
                    this.scanps = 0;
                case 'circular'
                    eval(['this.ampFormula = @(x) ' this.scanfct ';']);
                    eval(['this.xFormula = @(x) (x - 0.5) * ' num2str(264 / this.scanaz) ';']);
                    this.scanps = round(this.scanperiod * this.samplerate);
                case 'conical'
                    eval(['this.ampFormula = @(x) ' this.scanfct ';']);
                    r2 = num2str(this.scansquint / 2 / 360);
                    eval(['this.xFormula = @(x) ' ...
                        'sqrt((' r2 '*sin(2*pi*(x-0.5))).^2 + (' r2 '*cos(2*pi*(x-0.5))-' r2 ').^2) * ' ...
                        num2str(264 / this.scanaz / 2) ';']);
                    this.scanps = round(this.scanperiod * this.samplerate);
                otherwise
                    error(['unknown antenna scan type: ' this.scantype]);
            end
            this.pulse = iqpulse(varargin{1:end});
            this.plen = length(this.pulse);
            this.reset();
        end
        function reset(this)
            this.spsf = 0;
            this.spsfm = 0;
        end
        function iqdata = step(this, len)
% For performance reasons, pre-allocate the result buffer and assign fixed portions
%            iqdata = [this.pulse(this.spsfm+1:end); repmat(this.pulse, len2, 1); this.pulse(1:len3)];
            iqdata = zeros(len, 1);
            offs = this.plen - this.spsfm;
            if (offs <= len)
                iqdata(1:offs) = this.pulse(this.spsfm+1:end);  % copy remainder from last call to step()
                pcount = floor((len - offs) / this.plen);       % integer number of pulses that fit into output
                for i = 1:pcount
                    iqdata(offs+1:offs+this.plen) = this.pulse;
                    offs = offs + this.plen;
                end
                iqdata(offs+1:len) = this.pulse(1:len-offs);    % copy remaining samples
                this.spsfm = len - offs;                        % remember how many samples to copy next time
            else
                iqdata = this.pulse(this.spsfm+1:this.spsfm+len);
                this.spsfm = this.spsfm + len;                  % remember how many samples to copy next time
            end
% sanity check
            if (length(iqdata) ~= len)
                error(sprintf('length mismatch: buffer %d, len %d', length(iqdata), len));
            end
            % apply antenna scan if necessary
            if (this.scanps ~= 0)
                % find the position with a scan
                x = ((this.spsf+1):(this.spsf+len))' ./ this.scanps + this.scanoffset;
                % 0 = start of scan, 1 = end of scan
                x = x - floor(x);
                % apply amplitude formula
                xt = this.xFormula(x);
                amp = this.ampFormula(xt);
                iqdata = iqdata .* amp;
            end
            this.spsf = this.spsf + len;
        end
        function plotScan(this)
            x = 0:0.001:1;
            xt = this.xFormula(x);
            amp = this.ampFormula(xt);
            plot(x*360, 20*log10(abs(amp)));
            xlabel('degrees');
            ylabel('dB');
            grid on;
        end
    end
end
