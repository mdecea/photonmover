function f = iqdownload_81150A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)
% download an IQ waveform to the 81150A
    if (~isempty(sequence))
        errordlg('Sequence mode is not available for the 81150A / 81160A');
        f = [];
        return;
    end
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    % remove anything that goes beyond 2 channels
    channelMapping(3:end,:) = [];
    % find out if we have a one-channel or two channel instrument.
    try
        opts = xquery(f, '*opt?');
    catch ex
        errordlg({'Can not communicate with 81150A Firmware. Please try again.'
            'If this does not solve the problem, exit and restart MATLAB'
            ['(Error message: ' ex.message]});
        instrreset;
        return;
    end
    oneChannelInstr = 0;
    if (~isempty(strfind(opts, '001')))
        % be graceful with one-channel instruments and ignore anything
        % that deals with the second channel
        oneChannelInstr = 1;
        channelMapping(2,:) = [0 0];
    end

    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        xfprintf(f, '*rst');
    end
    % couple both channels
    if (~oneChannelInstr)
        xfprintf(f, ':trac:chan1 off');
    end
    % set the skew - depending on whether it is positive or negative, it
    % has to be set on channel1 or channel2. The other one is always zero.
    if (isfield(arbConfig,'skew') && isfloat(arbConfig.skew))
        if (arbConfig.skew >= 0)
            xfprintf(f, sprintf(':puls:del1 %.12g', arbConfig.skew));
            xfprintf(f, sprintf(':puls:del2 %.12g', 0));
        else
            xfprintf(f, sprintf(':puls:del1 %.12g', 0));
            xfprintf(f, sprintf(':puls:del2 %.12g', -1.0 * arbConfig.skew));
        end
    end
    for ch = find(channelMapping(:,1))'
        gen_arb_81150A(arbConfig, f, ch, real(data), marker1, fs, segmNum);
    end
    for ch = find(channelMapping(:,2))'
        gen_arb_81150A(arbConfig, f, ch, imag(data), marker2, fs, segmNum);
    end
    if (~oneChannelInstr)
        xfprintf(f, ':trac:chan1 on');
    end
    if (~exist('keepOpen') || keepOpen == 0)
        fclose(f);
    end;
end



function gen_arb_81150A(arbConfig, f, chan, data, marker, fs, segm_num)
% download an arbitrary waveform signal to a given channel and segment
% number. Set the sampling rate to fs
    xfprintf(f, sprintf(':func%d user', chan));      % switch to arb mode
    % always extend the waveform to 16K or 512K samples
    % other numbers cause interpolation problems inside the 81150A
    orig_segm_len = length(data);
    if (orig_segm_len <= 16384)
        data = iqresample(data, 16384);
    else
        data = iqresample(data, 524288);
    end
    segm_len = length(data);
    if (fs ~= 0 && segm_len ~= 0)
        xfprintf(f, sprintf(':freq%d %.15g', chan, fs/orig_segm_len));
    end
    % segment definition
    if (segm_len > 0)
        % data is assumed to be -1 ... +1
        data = round(8191 * data);

        % make 16-bit integers
        data = int16(data);

        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            xfprintf(f, ':form:bord norm');
        else
            xfprintf(f, ':form:bord swap');
        end

        % download an arbitrary waveform
        % the built-in binblockwrite command does not work correctly with the 81180A
        % binblockchunkwrite is a replacement for it.
        cmd = sprintf(':data%d:dac volatile,', chan);
        xbinblockwrite(f, data, 'int16', cmd);
        fprintf(f, '');                      % seems to be required to terminate the binary transfer
        xquery(f, '*opc?');
    end
    if (isfield(arbConfig,'amplitude'))
        xfprintf(f, sprintf(':volt%d:ampl %g', chan, arbConfig.amplitude(chan)));    
    end
    if (isfield(arbConfig,'offset'))
        xfprintf(f, sprintf(':volt%d:offs %g', chan, arbConfig.offset(chan)));    
    end
    xfprintf(f, sprintf(':func%d:user volatile', chan));   % use VOLATILE waveform
    xfprintf(f, sprintf(':outp%d on', chan));             % turn output on
    xfprintf(f, sprintf(':outp%d:comp on', chan));             % turn output on
end


function xbinblockwrite(f, data, format, cmd)
% set debugScpi=1 in MATLAB workspace to log SCPI commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s %s, %d elements\n', cmd, format, length(data));
    end
    binblockwrite(f, data, format, cmd);
    fprintf(f, '');
end


function retVal = xquery(f, s)
% send a query to the instrument object f
    retVal = query(f, s);
% set debugScpi=1 in MATLAB workspace to log SCPI commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        if (length(retVal) > 60)
            rstr = sprintf('%s... (total %d chars)', retVal(1:60), length(retVal));
        else
            rstr = retVal;
        end
        fprintf('qry = %s -> %s\n', s, strtrim(rstr));
    end
end


function xfprintf(f, s)
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
    if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
        errordlg(sprintf('Instrument returns error on cmd "%s". Result = %s\n', s, result));
    end
end
