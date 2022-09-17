function result = iqdownload(iqdata, fs, varargin)
% Download signal(s) to one or more AWG channels
%
% - iqdata - can be either 
%        a) a array of real or complex samples. Each column is considered
%           to be a real or complex waveform  (support for more than one
%           column is still in-the-works)
%        b) empty. In this case, only a connection check is carried out.
%           If the connection can not be established, an error message
%           is displayed and an empty result is returned
%
% - fs - sample rate in Hz
%
% additional parameters can be specified as attribute/value pairs:
% - 'segmentNumber' - specify the segment number to use (default = 1)
% - 'normalize' - auto-scale the data to max. DAC range (default = 1)
% - 'downloadToChannel - no longer supported
% - 'channelMapping' - new format for AWG channel mapping:
%              vector with 2*m columns and n rows. rows represent AWG channels,
%              Columns represent I and Q for each of column in iqdata.
%              (channelmapping must have twice the number of columns than
%              iqdata)
%              Each element is either 1 or 0, indicating whether the signal
%              is downloaded to the respective AWG channel
% - 'sequence' - description of the sequence table 
% - 'marker' - vector of integers that must have the same length as iqdata
%              low order bits correspond to marker outputs
% - 'arbConfig' - struct as described in loadArbConfig (default: [])
% - 'keepOpen' - if set to 1, will keep the connection to the AWG open
%              after downloading the waveform
% - 'run' - determines if the AWG will be started immediately after
%              downloading the waveform/sequence. (default: 1)
%
% If arbConfig is not specified as an additional parameter, the AWG configuration
% is taken from the default "arbConfig.mat" file (located at
% iqArbConfigFilename())
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

%% parse optional arguments
segmNum = 1;
result = [];
keepOpen = 0;
normalize = 1;
downloadToChannel = [];
channelMapping = [];
sequence = [];
arbConfig = [];
segmentLength = [];
segmentOffset = [];
lOamplitude = [];
lOfCenter = [];
segmName = [];

clear marker;
run = 1;
i = 1;
while (i <= nargin-2)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'segmentnumber';  segmNum = varargin{i+1};
            case 'keepopen'; keepOpen = varargin{i+1};
            case 'normalize'; normalize = varargin{i+1};
            case 'downloadtochannel'; downloadToChannel = varargin(i+1);
            case 'channelmapping'; channelMapping = varargin{i+1};
            case 'chmap'; channelMapping = varargin{i+1};       % synonym for channelmapping
            case 'marker'; marker = varargin{i+1};
            case 'sequence'; sequence = varargin{i+1};
            case 'arbconfig'; arbConfig = varargin{i+1};
            case 'run'; run = varargin{i+1};
            case 'segmentlength'; segmentLength = varargin{i+1};
            case 'segmentoffset'; segmentOffset = varargin{i+1};
            case 'loamplitude'; lOamplitude = varargin{i+1};
            case 'lofcenter'; lOfCenter = varargin{i+1};
            case 'segmname'; segmName = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end


% convert the old format for "downloadToChannel" to channelMapping
% new format is array with row=channel, column=I/Q
if (~isempty(downloadToChannel))
    warndlg('"downloadToChannel" is deprecated, please use "channelMapping" instead');
    if (iscell(downloadToChannel))
        downloadToChannel = downloadToChannel{1};
    end
    if (ischar(downloadToChannel))
        switch (downloadToChannel)
            case 'I+Q to channel 1+2'
                channelMapping = [1 0; 0 1];
            case 'I+Q to channel 2+1'
                channelMapping = [0 1; 1 0];
            case 'I to channel 1'
                channelMapping = [1 0; 0 0];
            case 'I to channel 2'
                channelMapping = [0 0; 1 0];
            case 'Q to channel 1'
                channelMapping = [0 1; 0 0];
            case 'Q to channel 2'
                channelMapping = [0 0; 0 1];
            case 'RF to channel 1'
                channelMapping = [1 1; 0 0];
            case 'RF to channel 2'
                channelMapping = [0 0; 1 1];
            case 'RF to channel 1+2'
                channelMapping = [1 1; 1 1];
            otherwise
                error(['unexpected value for downloadToChannel argument: ' downloadToChannel]);
        end
    end
end

% catch the case where channelMapping is (accidently) given as a string
if (ischar(channelMapping))
    errordlg('unexpected format for parameter channelMapping: string');
    error('unexpected format for parameter channelMapping: string');
end

% if markers are not specified, generate square wave marker signal
if (~exist('marker', 'var') || isempty(marker))
    marker = [15*ones(floor(length(iqdata)/2),1); zeros(length(iqdata)-floor(length(iqdata)/2),1)];
end

% make sure the data is in the correct format
if (size(iqdata,1) < size(iqdata,2))
    iqdata = iqdata.';
end

% try to load the configuration from the file arbConfig.mat
arbConfig = loadArbConfig(arbConfig);

% set default channelMapping is none was specified
if (isempty(channelMapping))
    if (isempty(iqdata))
        % make sure that multi-module systems get properly initialized
        channelMapping = zeros(size(arbConfig.channelMask, 2), 2*arbConfig.numChannels);
    elseif (size(iqdata, 2) > 1)
        switch (arbConfig.numChannels)
            case 1
                channelMapping = [1 0];
            case 2
                channelMapping = [1 0 0 0; ...
                                  0 0 1 0];
            otherwise
                channelMapping = [1 0 0 0 0 0 0 0; ...
                                  0 0 1 0 0 0 0 0; ...
                                  0 0 0 0 1 0 0 0; ...
                                  0 0 0 0 0 0 1 0];
        end
    else
        switch (arbConfig.numChannels)
            case 1
                channelMapping = [1 0];
            case 2
                channelMapping = [1 0; 0 1];
            otherwise
                channelMapping = [1 0; 0 1; 1 0; 0 1];
        end
    end
end

% make sure channelMapping has the right width
if (size(channelMapping, 2) < 2 * size(iqdata, 2))
    channelMapping(:, 2 * size(iqdata, 2)) = 0;
end

% normalize if required
if (normalize && ~isempty(iqdata))
    scale = max(max(max(abs(real(iqdata)), abs(imag(iqdata)))));
    if (scale > 1)
        if (normalize)
            iqdata = iqdata / scale;
        else
            errordlg('Data must be in the range -1...+1', 'Error');
        end
    end
end

% apply DAC range
if (isfield(arbConfig, 'DACRange') && arbConfig.DACRange ~= 1)
    iqdata = iqdata .* arbConfig.DACRange;
    % > 100% DAC range --> clip
    if (arbConfig.DACRange > 1)
        if (isreal(iqdata))
            iqdata(iqdata > 1) = 1;
            iqdata(iqdata < -1) = -1;
        else
            idata = real(iqdata);
            qdata = imag(iqdata);
            idata(idata > 1) = 1;
            idata(idata < -1) = -1;
            qdata(qdata > 1) = 1;
            qdata(qdata < -1) = -1;
            iqdata = complex(idata, qdata);
        end
    end
end
    
% apply I/Q gainCorrection if necessary
if (isfield(arbConfig, 'gainCorrection') && arbConfig.gainCorrection ~= 0)
    iqdata = complex(real(iqdata) * 10^(arbConfig.gainCorrection/20), imag(iqdata));
    scale = max(max(max(abs(real(iqdata)), abs(imag(iqdata)))));
    if (scale > 1)
        iqdata = iqdata ./ scale;
    end
end

% extract markers - assume there are two markers per channel
marker = reshape(marker, numel(marker), 1);
marker1 = bitand(uint16(marker),3);
marker2 = bitand(bitshift(uint16(marker),-2),3);

% check granularity
len = length(iqdata);
if (mod(len, arbConfig.segmentGranularity) ~= 0)
    errordlg(['Segment size is ' num2str(len) ', must be a multiple of ' num2str(arbConfig.segmentGranularity)], 'Error');
    return;
elseif (isempty(segmentLength) && len < arbConfig.minimumSegmentSize && len ~= 0)
    errordlg(['Segment size is ' num2str(len) ', must be >= ' num2str(arbConfig.minimumSegmentSize)], 'Error');
    return;
elseif (len > arbConfig.maximumSegmentSize)
    errordlg(['Segment size is ' num2str(len) ', must be <= ' num2str(arbConfig.maximumSegmentSize)], 'Error');
    return;
end

% interleaving --> split to two channels
% this is only supported for a single vector
if (isfield(arbConfig, 'interleaving') && arbConfig.interleaving)
    fs = fs / 2;
    iqdata = real(iqdata(:,1));                           % take the I signal
    iqdata = complex(iqdata(1:2:end), iqdata(2:2:end));   % and split it into two channels
    if (~isempty(marker1))
        marker1 = marker1(1:2:end);
        marker2 = marker2(1:2:end);
    end
    if (size(channelMapping, 1) == 4)
        if (max(max(channelMapping(1:2,:))) > 0)
            channelMapping(1:2,:) = [1 0; 0 1];
        end
        if (max(max(channelMapping(3:4,:))) > 0)
            channelMapping(3:4,:) = [1 0; 0 1];
        end
    else
        channelMapping = [1 0; 0 1];
    end
end
    
    
%% establish a connection and download the data
    switch (arbConfig.model)
        case { '81180A' '81180B' }
            result = iqdownload_81180A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { 'M8190A' 'M8190A_base' 'M8190A_14bit' 'M8190A_12bit' 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }
            result = iqdownload_M8190A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run, segmentLength, segmentOffset);
        case { 'M8121A' 'M8121A_base' 'M8121A_14bit' 'M8121A_12bit' 'M8121A_DUC_x3' 'M8121A_DUC_x12' 'M8121A_DUC_x24' 'M8121A_DUC_x48' }
            result = iqdownload_M8121A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run, segmentLength, segmentOffset);
        case { 'M8195A_Rev0' }
            result = iqdownload_M8195A_Rev0(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case { 'M8195A_Rev1' }
            result = iqdownload_M8195A_Rev1(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case { 'M8195A_1ch' 'M8195A_1ch_mrk' 'M8195A_2ch' 'M8195A_2ch_mrk' 'M8195A_4ch' 'M8195A_2ch_256k' 'M8195A_4ch_256k' }
            result = iqdownload_M8195A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run, segmentLength, segmentOffset);
        case { 'M8196A' }
            result = iqdownload_M8196A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case { 'M8194A' }
            result = iqdownload_M8194A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case { 'M8198A_Rev0' }
            result = iqdownload_M8198A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case { 'M933xA' 'M9330A/M9331A' }
            result = iqdownload_M933xA(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case 'M9336A'
            result = iqdownload_M9336A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { 'M3201A' 'M3202A' 'M3201A_CLF' 'M3202A_CLF' 'M3201A_CLV' 'M3202A_CLV' }
            result = iqdownload_M3202A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case 'N824xA'
            result = iqdownload_N824xA(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { '81150A' '81160A' }
            result = iqdownload_81150A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case 'AWG7xxx'
            result = iqdownload_AWG7xxx(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case 'AWG7xxxx'
            result = iqdownload_AWG7xxxx(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { 'N5182A' 'N5182B' 'N5172B' 'E8267D' 'N51xxA (MXG)' 'E4438C'}
            result = iqdownload_N51xxA(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName);
        case { 'M9384B' 'M9384B_1Ch' 'M9384B_2Ch_IND' 'M9384B_2Ch_COH' 'M9383B'}
            result = iqdownload_M9384B(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName, segmentLength, segmentOffset);        
        case {'N5194A_250MHz' 'N5194A_2GHz' 'N5194A_250MHz_In'}
            result = iqdownload_N519xA(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName, segmentLength, segmentOffset);
        case {'M9383A'}
            result = iqdownload_M9383A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName);
        case { 'M9381A' 'M938xA' }
            result = iqdownload_M9381A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { '3351x' '3352x' '3361x' '3362x' }
            result = iqdownload_33xxx(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { 'MUXDAC' }
            result = iqdownload_MUXDAC(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        otherwise
            error(['instrument model ' arbConfig.model ' is not supported']);
    end
end
