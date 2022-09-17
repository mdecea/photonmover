function f = iqdownload_81180A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)
% download an IQ waveform to the 81180A
% This routine is NOT intended to be called directly from a user script
% It should only be called via iqdownload()
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        xfprintf(f, '*rst');
    end
    % common clock source for both channels
    xfprintf(f, ':inst:coup:state on');
    % set the skew - depending on whether it is positive or negative, it
    % has to be set on channel1 or channel2. The other one is always zero.
    if (isfield(arbConfig,'skew') && isfloat(arbConfig.skew))
        xfprintf(f, sprintf(':inst:coup:skew %.12g', arbConfig.skew));
    end
    for i = find(channelMapping(:,1)')
        gen_arb_81180A(arbConfig, f, i, real(data), marker1, fs, segmNum);
    end
    for i = find(channelMapping(:,2)')
        gen_arb_81180A(arbConfig, f, i, imag(data), marker2, fs, segmNum);
    end
    if (~isempty(sequence))
        setupSequence(f, sequence, channelMapping);
    end
    if (~exist('keepOpen') || keepOpen == 0)
        fclose(f);
    end
end


function setupSequence(f, sequence, channelMapping)
    switch (sequence.cmd)
        case 'list'
            errordlg('Sorry, the 81180A does not have a command to find out which segments are defined');
        case 'delete'
            xfprintf(f, ':inst 1');
            xfprintf(f, ':trac:del:all');
            xfprintf(f, ':inst 2');
            xfprintf(f, ':trac:del:all');
        case 'define'
            seq = sequence.sequence;
            for inst = 1:2
                if (sum(channelMapping(inst,:)) ~= 0)
                    xfprintf(f, sprintf(':inst %d', inst));
                    xfprintf(f, ':seq:del:all');
                    xfprintf(f, ':seq:sel 1');
                    for i = 1:size(seq,2)
                        jmp = 0;
                        switch (seq(i).segmentAdvance)
                            case 'Auto';        jmp = 0;
                            case 'Conditional'; jmp = 1;
                            case 'Repeat';      jmp = 1;
                            case 'Stepped';     jmp = 1;
                        end
                        loops = seq(i).segmentLoops; % segment loops
                        segmNum = seq(i).segmentNumber; % segment number
                        xfprintf(f, sprintf(':seq:def %d,%d,%d,%d', i, segmNum, loops, jmp));
                    end
                end
                xfprintf(f, ':func:mode seq');
            end
        otherwise
            errordlg({'unexpected sequence command: ' sequence.cmd});
    end
end


function gen_arb_81180A(arbConfig, f, chan, data, marker, fs, segm_num)
% download an arbitrary waveform signal to a given channel and segment
% number. Set the sampling rate to fs
    xfprintf(f, sprintf(':inst %d', chan));    
    xfprintf(f, ':abort');
    xfprintf(f, ':func:mode user');
    if (fs ~= 0)
        xfprintf(f, sprintf(':freq:rast %.12g', fs));    
    end
    if (isfield(arbConfig, 'ampType'))
        xfprintf(f, [':outp:coup ' arbConfig.ampType]);
        if (isfield(arbConfig,'amplitude') && ...
            isfloat(arbConfig.amplitude) && ...
            length(arbConfig.amplitude) == 2)
            switch arbConfig.ampType
                case 'DC'             
                    xfprintf(f, sprintf(':volt:ampl %g', arbConfig.amplitude(chan)));  
                    if (isfield(arbConfig, 'offset'))
                        xfprintf(f, sprintf(':volt:offs %g', arbConfig.offset(chan)));  
                    end
                case 'DAC'
                    xfprintf(f, sprintf(':volt:dac %g', arbConfig.amplitude(chan)));
                    if (isfield(arbConfig, 'offset'))
                        xfprintf(f, sprintf(':volt:offs %g', arbConfig.offset(chan)));  
                    end
                case 'AC'
                    p = 10 * log10((arbConfig.amplitude(chan)^2/400)) + 30;
                    xfprintf(f, sprintf(':pow %g', p));
            end
        end
    end
    % segment definition
    segm_len = length(data); % 128 to 16M/64M in multiples of 32
    if (segm_len > 0)
        xfprintf(f, sprintf(':trac:del %d', segm_num), 1);    
        xfprintf(f, sprintf(':trac:def %d,%d', segm_num, segm_len));
        xfprintf(f, sprintf(':trac:sel %d', segm_num));
        % scale to DAC values and apply an offset
        % data is assumed to be -1 ... +1
        data = round(2047 * data + 2048);

        % make 16-bit integers
        data = uint16(data);

        % set markers - they are strangly scrambled, see SCPI programming
        % manual under :TRACE
        if (~isempty(marker))
            for m = 1:2
                if (size(marker,2) >= m)
                    for i = 1:32:segm_len-31
                        for j = 0:7
                            data(i+j+24) = bitset(data(i+j+24), m+12, (marker(i+4*j+3,m)~=0));
                        end
                    end
                end
            end
        end

        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end

        % download an arbitrary waveform
        % the built-in binblockwrite command does not work correctly with the 81180A
        % binblockchunkwrite is a replacement for it.
%        binblockwrite(f, data, 'uint16', ':trac:data ');
        binblockchunkwrite(f, ':trac:data ', data, 1e6);
        fprintf(f, '');                      % seems to be required to terminate the binary transfer
        query(f, '*opc?');
        if (~isempty(marker))
            xfprintf(f, ':mark1 on');
            xfprintf(f, ':mark2 on');
        end
    end
    xfprintf(f, ':outp on');             % turn output on
end



%
%  binblockchunkwrite - 
%
function result = binblockchunkwrite(f, cmd, block, chunk_size)
% send the binary block to the instrument object f
% use chunk_size blocks in the fwrite command

% make a header of the binary block
    len = length(block);
    header = [cmd '#' int2str(length(int2str(len*2))) int2str(len*2)];
    % assign the chunk size
    if len < chunk_size
        chunk_size = len;
    end
    % write the header of binary block
    try
        f.EOImode = 'off';
    catch
    end
    fwrite(f, header);

    % write a data of binary block
    for i = 1 : chunk_size : len
        if i+(chunk_size-1) < len
            n = i+(chunk_size-1);
        else
            n = len; % remainder of data 
        end
        
        chunk = uint16(block(i:n));
        fwrite(f, chunk, 'uint16');
    end
    try
        f.EOImode = 'on';
    catch
    end
    
    result = 1;
end


function xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status

% set debugScpi=1 in MATLAB workspace to log SCPI commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s\n', s);
    end
    fprintf(f, s);
    result = query(f, ':syst:err?');
    if (length(result) == 0)
        fclose(f);
        errordlg('Instrument did not respond to :SYST:ERR query. Check the instrument.', 'Error');
        error(':syst:err query failed');
    end
    if (~exist('ignoreError', 'var'))
        if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
            errordlg(sprintf('Instrument returns error on cmd "%s". Result = %s\n', s, result));
        end
    end
end


