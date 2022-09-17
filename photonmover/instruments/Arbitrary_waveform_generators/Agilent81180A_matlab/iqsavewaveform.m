function iqsavewaveform(Y, fs, varargin)
% Save a (real or complex) waveform to a file in various formats.
% Besides the waveform and sample rate, additional parameters can be passed
% as property/value pairs. Unless the "savefile" parameter is provided, the
% user is prompted for a filename.
% Parameters: 
% Y - the waveform (or chunk of waveform) to be saved
% fs - sample rate
% 'marker' - vector of markers that can optionally be saved in some file formats
% 'filename' - if provided, this filename will be used as a filename. 
% 'filetype' - if provided, is used to derive the file format. Otherwise,
%              the file format is derived from the filename extension.
% 'segmentLength' - overall number of samples that will be saved (this is
%              only needed in conjunction with block-wise saving
% 'segmentOffset' - when provided, indicates block-wise saving. The value
%              is the file offset (in samples) of the current data block.
%              When segmentOffset + length(Y) >= segmentLength, or 
%              length(Y) == 0 the file is closed. iqsavewaveform MUST
%              be called with contiguous blocks from beginning to end
global fSave;
global filterindex;
if (~isvector(Y))
    errordlg('Cannot save multiple waveforms. Please select only one channel for download when corrections are applied');
    return;
end
Y = reshape(Y, 1, length(Y));
marker = '';
filetype = [];
filename = [];
segmentLength = [];
segmentOffset = [];
for i = 1:2:nargin-2
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'marker';   marker = varargin{i+1};
            case 'filetype'; filetype = varargin{i+1};
            case 'filename'; filename = varargin{i+1};
            case 'segmentlength'; segmentLength = varargin{i+1};
            case 'segmentoffset'; segmentOffset = varargin{i+1};
            otherwise, error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
end

% catch the case where "large" file is written, but the complete waveform
% is provided in the first call to iqsavewaveform
if (~isempty(segmentOffset) && segmentOffset == 0 && length(Y) == segmentLength)
    segmentOffset = [];
    segmentLength = [];
end
% if this is the first or the only waveform segment,
% determine the file format and filename  
if (isempty(segmentOffset) || segmentOffset == 0)
    fSave = [];
    filterindex = 0;
    if (~isempty(filetype))
    % determine the file format based on the specified filetype
        if (~isempty(strfind(filetype, 'MATLAB v6'))) %#ok<STREMP>
            filterindex = 2;
        elseif (~isempty(strfind(filetype, 'MATLAB'))) %#ok<STREMP>
            filterindex = 1;
        elseif (~isempty(strfind(filetype, 'CSV (X/Y)'))) %#ok<STREMP>
            filterindex = 4;
        elseif (~isempty(strfind(filetype, 'CSV'))) %#ok<STREMP>
            filterindex = 3;
        elseif (~isempty(strfind(filetype, '16-bit I/Q')) && ~isempty(strfind(filetype, 'LSB'))) %#ok<STREMP>
            filterindex = 5;
        elseif (~isempty(strfind(filetype, '16-bit I/Q')) && ~isempty(strfind(filetype, 'MSB'))) %#ok<STREMP>
            filterindex = 6;
        elseif (~isempty(strfind(filetype, '16-bit binary')) && ~isempty(strfind(filetype, 'LSB'))) %#ok<STREMP>
            filterindex = 7;
        elseif (~isempty(strfind(filetype, '16-bit binary')) && ~isempty(strfind(filetype, 'MSB'))) %#ok<STREMP>
            filterindex = 8;
        elseif (~isempty(strfind(filetype, '12-bit'))) %#ok<STREMP>
            filterindex = 9;
        elseif (~isempty(strfind(filetype, 'Signal Studio for Pulse Building'))) %#ok<STREMP>
            filterindex = 10;
        else
            error(['unknown filetype: ' filetype]);
        end
    elseif (~isempty(filename))
    % if only a filename is provided, try to guess the file format based on the extension
        if (~isempty(strfind(filename, '.mat'))) %#ok<STREMP>
            filterindex = 1;
        elseif (~isempty(strfind(filename, '.csv'))) %#ok<STREMP>
            filterindex = 3;
        elseif (~isempty(strfind(filename, '.iqbin'))) %#ok<STREMP>
            filterindex = 5;
        elseif (~isempty(strfind(filename, '.iq16b'))) %#ok<STREMP>
            filterindex = 6;
        elseif (~isempty(strfind(filename, '.bin'))) %#ok<STREMP>
            filterindex = 7;
        elseif (~isempty(strfind(filename, '.bin16b'))) %#ok<STREMP>
            filterindex = 8;
        elseif (~isempty(strfind(filename, '.pbin12'))) %#ok<STREMP>
            filterindex = 9;
        elseif (~isempty(strfind(filename, '.txt_tab'))) %#ok<STREMP>
            filterindex = 10;
        else
            error('Can''t determine file type based on the extension');
        end
    else
        [FileName, PathName, filterindex] = uiputfile({...
            '.mat', 'MATLAB file'; ...
            '.mat', 'MATLAB v6 file'; ...
            '.csv', 'ASCII CSV file'; ...
            '.csv', 'ASCII CSV (X/Y)'; ...
            '.*', '16-bit I/Q pairs, LSB first'; ...  % .iqbin
            '.*', '16-bit I/Q pairs, MSB first'; ...  % .iq16b
            '.*', '16-bit binary, LSB first'; ...     % .bin
            '.*', '16-bit binary, MSB first'; ...     % .bin16b
            '.pbin12', '12-bit packed binary (*.pbin12)'; ...
            '.txt', 'Signal Studio for Pulse Building IQ Import Compatible text file'}, ...
            'Save Waveform As...');
        if (FileName ~= 0)
            filename = fullfile(PathName, FileName);
        end
    end
end

%
% write the waveform (or waveform chunk) to the file
%
if (~isempty(filename) || ~isempty(fSave))
    % empty waveform signals end of file
    if (~isempty(fSave) && isempty(Y))
        fclose(fSave);
        fSave = [];
        return;
    end
    XDelta = 1/fs;
    XStart = 0; %#ok<NASGU>
    InputZoom = 1; %#ok<NASGU>
    try
        switch (filterindex)
            case 1 % MATLAB
                if (~isempty(segmentOffset))
                    if (segmentOffset == 0)
                        errordlg('This file format is not yet supported with large data sets');
                    end
                else
                    save(filename, 'Y', 'XDelta', 'XStart', 'InputZoom');
                end
            case 2 % MATLAB v6
                if (~isempty(segmentOffset))
                    if (segmentOffset == 0)
                        errordlg('This file format is not supported with large data sets');
                    end
                else
                    Y = single(Y);
                    save(filename, '-v6', 'Y', 'XDelta', 'XStart', 'InputZoom');
                end
            case 3 % CSV
                if (isempty(segmentOffset) || segmentOffset == 0)
                    dlmwrite(filename, [real(Y)' imag(Y)']);
                else
                    dlmwrite(filename, [real(Y)' imag(Y)'], '-append');
                end
            case 4 % CSV X/Y
                if (isempty(segmentOffset) || segmentOffset == 0)
                    dlmwrite(filename, [linspace(0,(length(Y)-1)*XDelta, length(Y))', real(Y.')], 'precision', 8);
                else
                    dlmwrite(filename, [linspace(segmentOffset,(segmentOffset+length(Y)-1)*XDelta, length(Y))', real(Y)'], 'precision', 8, '-append');
                end
            case {5 6} % 16-bit I/Q pairs
                a1 = real(Y);
                a2 = imag(Y);
                scale = max(max(abs(a1)), max(abs(a2)));
                if (scale > 1)
                    a1 = a1 / scale;
                    a2 = a2 / scale;
                end
                if (isempty(marker))
                    len = size(Y,2);
                    marker = zeros(1,len);
                    marker(1:floor(len/2)) = ones(1,floor(len/2));
                end
                data1 = int16(round(16383 * a1) * 2);
                data1 = data1 + int16(bitand(uint16(marker), 1));
                data2 = int16(round(16383 * a2) * 2);
                data2 = data2 + int16(bitand(uint16(marker), 1));
                data = [data1; data2];
                data = data(1:end);
                if (filterindex == 6)
                    byteOrder = 'ieee-be';
                else
                    byteOrder = 'ieee-le';
                end
                checkOpen(filename, segmentOffset, byteOrder);
                fwrite(fSave, data, 'int16');
            case {7 8} % 16-bit values (real part only)
                a1 = real(Y);
                scale = max(abs(a1));
                if (scale > 1)
                    a1 = a1 / scale;
                end
                if (isempty(marker))
                    len = size(Y,2);
                    marker = zeros(1,len);
                    marker(1:floor(len/2)) = ones(1,floor(len/2));
                end
                data = int16(round(16383 * a1) * 2);
                data = data + int16(bitand(uint16(marker), 1));
                if (filterindex == 8)
                    byteOrder = 'ieee-be';
                else
                    byteOrder = 'ieee-le';
                end
                checkOpen(filename, segmentOffset, byteOrder);
                fwrite(fSave, data, 'int16');
                
            case 9 % 12-bit packed  (2 samples -> 3 bytes)
                if (mod(length(Y), 2) ~= 0)
                    errordlg('Saving in 12-bit packed format requires an even number of samples');
                    return
                end
                a1 = real(Y);
                scale = max(abs(a1));
                if (scale > 1)
                    a1 = a1 / scale;
                end
                % convert to 12 bit values
                data1 = bitand(4095, int32(round(2047 * a1)));
                % split into 2 rows of 12-bit values
                data12 = reshape(data1, 2, length(data1)/2);
                % combine into vector of 24-bit values
                data24 = bitor(data12(2,:), bitshift(data12(1,:), 12));
                % split into 3 rows of 8-bit values
                data3 = uint8([bitshift(data24, -16); bitand(bitshift(data24, -8), 255); bitand(data24, 255)]);
                % convert to a single 8-bit vector
                data4 = data3(1:end);
                % byte swap by extracting every second value into new vectors
                % and recombine
%                data8 = [data4(2:2:end); data4(1:2:end)];
%                data8 = data8(:)';
                checkOpen(filename, segmentOffset, 'ieee-le');
                fwrite(fSave, data4, 'uint8');

            case 10 % SignalStudio .TXT
                YWrite = [real(Y); imag(Y)];
                if (isempty(segmentOffset) || segmentOffset == 0)
                    dlmwrite(filename, YWrite(:), 'delimiter', '\t', 'precision', 16);
                else
                    dlmwrite(filename, YWrite(:), 'delimiter', '\t', 'precision', 16, '-append');
                end
        end
        if (~isempty(fSave) && (isempty(segmentLength) || isempty(segmentOffset) || (segmentOffset + length(Y) >= segmentLength)))
            fclose(fSave);
            fSave = [];
        end
    catch ex
        errordlg(ex.message);
    end
end   



function checkOpen(filename, segmentOffset, byteOrder)
% open or rewind the fileID, depending on segmentOffset
global fSave;
if (~isempty(fSave))
    if (segmentOffset == 0)
        fseek(fSave, 0, 'bof');     % rewind after scale changes
    end
else
    if (isempty(segmentOffset) || segmentOffset == 0)
        fSave = fopen(filename, 'w', byteOrder);
    else
        error('non-zero segmentOffset with no fileID');
    end
end
