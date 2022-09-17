function [iqdata, sampleRate, marker, rpt, chMap] = iqloadfile(varargin)
% Download a waveform file into an AWG. Supports multiple file formats,
% re-sampling, scaling and applying corrections
%
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sample rate in Hz (if sampleRate is empty or zero, it is
%                         expected to be retrieved from the waveform file)
% 'normalize' - if set to 1 will normalize the output to [-1 ... +1]
% 'correction' - if set to 1 will apply predistortion
% 'arbConfig' - struct as created by iqconfig
%
% If called without arguments, opens a graphical user interface to specify
% parameters.
%
% Thomas Dippon, Keysight Technologies 2018
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

%% parse arguments
if (nargin == 0)
    iqloadfile_gui;
    return;
end
% initialize output arguments
iqdata = [];
marker = [];
rpt = 1;
% set default parameters
fileType = [];
filename = [];
sampleRate = [];
correction = 0;
arbConfig = [];
chMap = [1 0; 0 1];
csvDataColumn = '1';
csvMarkerMap = [0 0 0 0];
matlabVarNames = {};
binaryMarkerMap = [0 0 0 0];
resampleMethod = [];
resampleFactor = 1;
frequencyShift = [];
scaleMinMax = [];
windowMethod = [];
windowFactor = 0.0005;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'filetype';        fileType = varargin{i+1};
            case 'filename';        filename = varargin{i+1};
            case 'samplerate';      sampleRate = varargin{i+1};
            case 'csvdatacolumn';   csvDataColumn = varargin{i+1};
            case 'csvmarkercolumn'; error('csvMarkerColumn is no longer supported. Please use csvMarkerMap.');
            case 'csvmarkermap';    csvMarkerMap = varargin{i+1};
            case 'binarymarkermap'; binaryMarkerMap = varargin{i+1};
            case 'resamplemethod';  resampleMethod = varargin{i+1};
            case 'resamplefactor';  resampleFactor = varargin{i+1};
            case 'matlabvarnames';  matlabVarNames = varargin{i+1};
            case 'frequencyshift';  frequencyShift = varargin{i+1};
            case 'scaleminmax';     scaleMinMax = varargin{i+1};
            case 'correction';      correction = varargin{i+1};
            case 'arbconfig';       arbConfig = varargin{i+1};
            case 'chmap';           chMap = varargin{i+1};
            case 'channelmapping';  chMap = varargin{i+1};
            case 'windowmethod';      windowMethod = varargin{i+1}; 
            case 'windowfactor';      windowFactor = varargin{i+1}; 
            otherwise, error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

arbConfig = loadArbConfig(arbConfig);

% can specify sample rate or period
if (~isempty(sampleRate) && sampleRate > 0 && sampleRate < 1)
    sampleRate = 1 / sampleRate;
end

err = ['Error opening file: ' filename];
if (~exist(filename, 'file'))
    errordlg(err);
    return;
end
try
    if (strfind(fileType, 'ASCII'))
        try
            err = 'CSV Format error';
            data = csvread(filename);
            err = 'CSV Format error (data columns)';
            [dcol, cnt] = sscanf(csvDataColumn, '%d and %d');
            if (cnt == 2)
                iqdata = complex(data(:,dcol(1)), data(:,dcol(2)));
            elseif (cnt == 1)
                iqdata = data(:,dcol(1));
            else
                error(err);
            end
            err = 'CSV Format error (marker columns)';
            for i=1:length(csvMarkerMap)
                m = csvMarkerMap(i);
                switch (m)
                    case 0   % unused
                    case {1, 2, 3, 4, 5}  % col 2...6
                        if (m >= size(data,2))
                            err = 'CSV file does not have enough columns';
                            error(err);
                        end
                        if (isempty(marker))
                            marker = zeros(size(data,1),1);
                        end
                        marker = bitor(marker, bitshift(double(data(:,m+1)~=0), i-1));
                    case {6, 7} % bit 0...1
                        bitNum = m - 6;
                        if (isempty(marker))
                            marker = zeros(size(data,1),1);
                        end
                        c = dcol(1);
                        if (i > 2 && length(dcol) > 1)
                            c = dcol(2);
                        end
                        marker = bitor(marker, bitshift((bitand(data(:,dcol),bitNum)~=0), i-1));
                    otherwise
                        error('invalid csvMarkerMap entry: %d', m);
                end
            end
            err = 'Invalid sample rate';
            if (isempty(sampleRate))
                err = 'Must specify sample rate with CSV format';
                error(err);
            end
        catch ex
            errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
        end
    elseif (~isempty(strfind(fileType, 'FlexDCA')))
        [iqdata, sampleRate, marker] = readFlexDCA(filename);
    elseif (~isempty(strfind(fileType, 'MATLAB')))
        data = load(filename);
        fields = fieldnames(data);
        if (~isempty(matlabVarNames))
            samplesName = matlabVarNames{1};
            samplePeriodName = matlabVarNames{2};
            markerName = matlabVarNames{3};
        else
            samplesName = '';
            samplePeriodName = '';
            markerName = '';
        end
        err = 'Expected variables not found in mat file';
        % try to "guess" which field names are used
        if (length(fieldnames(data)) == 1)
            samplesName = fields{1};
        elseif (length(fieldnames(data)) == 2)
            samplesName = fields{1};    % assume that samples are first
            periodName = fields{2};
            samples = eval(['data.' samplesName]);
            if (isscalar(samples))     % well, try the other way round
                samplesName = fields{2};
                periodName = fields{1};
            end
            if (~isscalar(eval(['data.' periodName])))
            end
        end
        err = sprintf('Variable name for samples (%s) not found in mat file', samplesName);
        iqdata = double(eval(['data.' samplesName]));
        if (isempty(sampleRate))
            err = sprintf('Variable name for sample period (%s) not found in mat file', samplePeriodName);
            sampleRate = eval(['data.' samplePeriodName]);
            if (sampleRate < 1)
                sampleRate = 1 / sampleRate;    % can specify either sample rate or sample period
            end
        end
        if (~strcmp(markerName, ''))
            err = sprintf('Variable name for Markers (%s) not found in mat file', markerName);
            marker = eval(['data.' markerName]);
        end
    elseif (~isempty(strfind(fileType, '16-bit I/Q')) || ...
            ~isempty(strfind(fileType, '16-bit binary')))
        if (~isempty(strfind(fileType, 'MSB')))
            byteOrder = 'ieee-be';
        else
            byteOrder = 'ieee-le';
        end
        f = fopen(filename, 'r', byteOrder);
        a = uint16(fread(f, inf, 'uint16'));
        fclose(f);
        err = 'File format error';
        % markers are stored in the least significant 2 bits
        mkr = bitand(a, 3);
        % remove markers from signal
        a = bitand(a, hex2dec('FFFC'));
        % convert into two's complement
        a = mod((int32(a) + 32768), 65536) - 32768;
        if (~isempty(strfind(fileType, 'I/Q')))
            % separate I and Q into separate rows
            a = double(reshape(a, 2, length(a)/2)) / 32768;
            % separate marker 1&3 and 2&4 also into separate rows
            mkr = reshape(mkr, 2, length(mkr)/2);
            % combine all markers into a single vector with lower 4 bits
            % representing the markers
            mkr(1,:) = 4 * mkr(2,:) + mkr(1,:);
            % second column in no longer needed
            mkr(2,:) = [];
            % create complex data from the two rows
            iqdata = complex(a(1,:), a(2,:));
        else
            mkr = reshape(mkr, 1, length(mkr));
            iqdata = double(a) / 32768;
        end
        % initialize the "final" marker vector
        marker = uint16(zeros(1, length(mkr)));
        % rearrange the marker bits according to user input
        for i=1:4
            if (binaryMarkerMap(i) >= 2)
                marker = bitor(marker, bitshift(bitand(bitshift(mkr, -i+1), 1), binaryMarkerMap(i)-1));
            end
        end
    elseif (~isempty(strfind(fileType, '12-bit packed')))
        f = fopen(filename, 'r');
        a = uint8(fread(f, inf, 'uint8'));
        fclose(f);
        if (mod(length(a), 3) ~= 0)
            errordlg(sprintf('File size is not a multiple of 3 - truncating %d byte(s)', mod(length(a), 3)));
            a = a(1:floor(length(a)/3)*3);
        end
        % byte swap by extracting every second value into new vectors
%         a = a(:)';
%         d = [a(2:2:end); a(1:2:end)];
%         % then recombine
%         d = d(1:end);
%         a = d;

        % group into columns with 3 rows each
        a = reshape(a, 3, length(a)/3);
        % convert each column into a 24-bit value
        b = int32(a(3,:)) + bitshift(int32(a(2,:)), 8) + bitshift(int32(a(1,:)), 16);
        % align at MSB, so that conversion into double does the right thing
        c = bitshift([bitshift(bitand(bitshift(b, -12), 4095), 20); bitshift(bitand(b, 4095), 20)], -20);
        % convert to interval [-1 ... +1]
        iqdata = double(c(1:end)) / 2047;
        % no markers in packed format
        marker = [];
    elseif (~isempty(strfind(fileType, 'scilloscope')))
        [iqdata, fileFs] = osc2data(filename);
        if (isempty(sampleRate))
            sampleRate = fileFs;
            if (isempty(sampleRate))
                errordlg('The file format does not contain a sample rate. Please enter the sample rate manually');
            end
        end
    elseif (~isempty(strfind(fileType, 'ELT format')))
        f = fopen(filename, 'r', 'l');
        data = fread(f, inf, 'uint16=>uint16');
        fclose(f);
        if (mod(length(data), 3) ~= 0)
            errordlg('Length of file must be a multiple of 6 bytes')
            iqdata = [];
        else
            % convert 3 x 16-bit values to 4 x 12-bit values  
            val = [bitshift(data(1:3:end),-4), ...
                   bitor(bitshift(bitand(data(1:3:end),15),8),bitshift(data(2:3:end),-8)), ...
                   bitor(bitshift(bitand(data(2:3:end),255),4),bitshift(data(3:3:end),-12)), ...
                   bitand(data(3:3:end),4095)];
            % sign extend from bit 11 -> 15
            val = bitshift(bitshift(int16(val),4),-4);
            % treat the 4 values as 2 complex numbers
            iqdata = [complex(val(:,1), val(:,2)), complex(val(:,3), val(:,4))].';
            % interleave the two rows to a single vector
            iqdata = double(iqdata(:));
        end
    else
        errordlg(['Unknown file format: ' fileType]);
    end
catch ex
    errordlg({err, ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    iqdata = [];
    return;
end
% make sure the data is a single column
iqdata = reshape(iqdata, numel(iqdata), 1);
if (~isempty(marker))
    marker = reshape(marker, length(iqdata), 1);
end

% window the data if desired
if (~isempty(windowMethod))
    windowSize = length(iqdata);
    % If windowFactor is > 1, it is assumed to be given as number of samples
    if (windowFactor > 1)
        windowFactor = windowFactor / windowSize;
    end
    switch (lower(windowMethod))
        case {'cosinetaper' 'cosine taper'}
            % filter the signal with tukeywindow
            win = tukeywin(windowSize, windowFactor);
            iqdata = iqdata .* win;
        case 'crossfade'
            % crossfade between beginning and end of waveform
            windowSamples = round(windowFactor * windowSize / 2) * 2;
            w2 = windowSamples / 2;
            win = (cos(pi*(1:windowSamples)/windowSamples)'+1)/2;
            iqTmp = iqdata;
            iqTmp(1:w2) = iqdata(1:w2) .* (1-win(w2+1:end)) + iqdata(end-w2+1:end) .* win(w2+1:end);
            iqTmp(end-w2+1:end) = iqdata(end-w2+1:end) .* win(1:w2) + iqdata(1:w2) .* (1-win(1:w2));
            iqdata = iqTmp;
        otherwise
            errordlg(['unknown windowMethod: ' resampleMethod]);
    end
end

% resample the data if desired
if (~isempty(resampleMethod))
    [p, q] = rat(resampleFactor);
    switch (resampleMethod)
        case 'interpolate'
            if (p/q < 1)
                errordlg('This resampling method is only supported for resampling factors > 1');
                return;
            end
            ipfct = @(data,p,q) interp(double(data), p/q);
        case 'resample'
            ipfct = @(data,p,q) resample(double(data), p, q);
        case 'fft'
            ipfct = @(data,p,q) interpft(data, round(p/q * length(data)));
        case 'linear'
            ipfct = @(data,p,q) linear_interp(data,p,q);
        case 'arbitrary'
            ipfct = @(data,p,q) iqresample(data, round(p/q * length(data)));
        otherwise
            errordlg(['unknown resampleMethod: ' resampleMethod]);
    end
    len = length(iqdata);
    [~, d] = rat(len * p / q, 0.01);
    if (d > 1)
        iqdata = repmat(iqdata, d, 1);
        marker = repmat(marker, d, 1);
    end
    try
        iqdata = ipfct(iqdata, p, q);
        if (~isempty(marker))
            marker = uint16(ipfct(double(marker), p, q));
        end
        sampleRate = sampleRate * p / q;
    catch ex
        errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    end
end
% shift frequency
if (~isempty(frequencyShift))
    n = length(iqdata);
    iqdata = iqdata .* exp(1i*2*pi*round(n*frequencyShift/sampleRate)/n*(1:n)');
end
if (correction)
    [iqdata, chMap] = iqcorrection(iqdata, sampleRate, 'chMap', chMap, 'normalize', ~isempty(scaleMinMax));
end
% set min/max values
minVal = min(min(min(real(iqdata)), min(imag(iqdata))));
maxVal = max(max(max(real(iqdata)), max(imag(iqdata))));
if (~isempty(scaleMinMax))
    scaleMin = scaleMinMax(1);
    scaleMax = scaleMinMax(2);
    if (length(scaleMinMax) >= 3)
        symm = scaleMinMax(3);
    else
        symm = 1;
    end
    if (symm)
        scale = min(abs(scaleMax / maxVal), abs(scaleMin / minVal));
        shift = 0;
    else
        scale = (scaleMax-scaleMin) / (maxVal-minVal);
        shift = scaleMin - (minVal * scale);
    end
    if (isreal(iqdata))
        iqdata = iqdata * scale + shift;
    else
        iqdata = complex(real(iqdata) * scale + shift, imag(iqdata) * scale + shift);
    end
end
assignin('base', 'iqdata', iqdata);
assignin('base', 'marker', marker);
assignin('base', 'sampleRate', sampleRate);
arbConfig = loadArbConfig(arbConfig);
len = size(iqdata, 1);
rpt = lcm(len, arbConfig.segmentGranularity) / len;
while (rpt * len < arbConfig.minimumSegmentSize)
    rpt = rpt+1;
end


function result = linear_interp(data,p,q)
x = linspace(0, length(data), length(data)+1)';
xq = linspace(0, length(data)*p/q-1, floor(length(data)*p/q))' / (p/q);
y = [data; data(1)];
result = interp1(x, y, xq, 'nearest');


function [iqdata, fs, marker] = readFlexDCA(filename)
fs = 0;
marker = [];
iqdata = [];
bitRate = 0;
try
    f = fopen(filename, 'r');
    a = fgetl(f);
    cnt = 0;
    points = 0;
    clear iqdata;
    while (ischar(a))
        %                    fprintf('%s\n', a);
        % process pairs
        if (cnt > 0)
            [val, readCnt] = sscanf(a, '%g'); % US style
            if (readCnt < 1)
                [val, readCnt] = sscanf(regexprep(a, ',', '.'), '%g'); % German style
                if (readCnt < 1)
                    errordlg({'unexpected number format in CSV file: ' a});
                    return;
                end
            end
            iqdata(cnt) = val(1);
            cnt = cnt + 1;
            if (cnt > points)
                break;
            end
        else
            [tok, remain] = strtok(a, ',;');
            switch (tok)
                case 'Data'
                    cnt = 1;
                case 'XInc'
                    fs = 1 / sscanf(regexprep(remain(2:end), ',', '.'), '%g');
                case 'Bit Rate (b/s)'
                    bitRate = sscanf(regexprep(remain(2:end), ',', '.'), '%g');
                case 'Points'
                    points = sscanf(regexprep(remain(2:end), ',', '.'), '%g');
                    iqdata = zeros(points,1);
            end
        end
        a = fgetl(f);
    end
    fclose(f);
    % if bitrate is specfified in the file, use it to calculate
    % the sample rate - it is more accurate
    if (bitRate > 0)
        [overN overD] = rat(fs / bitRate);
        fs = bitRate * overN / overD;
    end
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end



