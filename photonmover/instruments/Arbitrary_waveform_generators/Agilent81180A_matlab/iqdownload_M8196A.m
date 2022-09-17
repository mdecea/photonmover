function result = iqdownload_M8196A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run)
% Download a waveform to the M8196A
% It is NOT intended that this function be called directly, only via iqdownload
%
% T.Dippon, Keysight Technologies 2015
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    result = [];
    if (~isempty(sequence))
        errordlg('Sorry, M8196A does not have a sequencer');
        return;
    end

    % open the VISA connection
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    result = f;
    
    % stop waveform output
    if (run >= 0)
        if (xfprintf(f, sprintf(':ABORt')) ~= 0)
            % if ABORT does not work, let's not try anything else...
            % we will probably get many other errors
            return;
        end
    end
    
    % find out if we have a two-channel or four-channel instrument
    try
        opts = xquery(f, '*opt?');
    catch ex
        errordlg({'Can not communicate with M8196A Firmware. Please try again.'
            'If this does not solve the problem, exit and restart MATLAB'
            ['(Error message: ' ex.message]});
        instrreset();
        return;
    end
    
% for testing purposes: simulate an Option 001 instrument
%    opts = '001';

    % be graceful with one/two-channel instruments and don't attempt
    % to access channels that are not available (to avoid a flood of error
    % messages)
    dacMode = xquery(f, ':INST:DACM?');
    % extend the channel mapping to 4 channels
    if (size(channelMapping, 1) < 4)
        channelMapping(4,:) = zeros(1,size(channelMapping, 2));
    end
    % if it is a two channel instrument, don't attempt to load channels 2 & 3
    if (~isempty(strfind(opts, '002')))
        xfprintf(f, ':INST:DACM DCMARKER', 1);
        channelMapping(2,:) = zeros(1,size(channelMapping, 2));
        channelMapping(3,:) = zeros(1,size(channelMapping, 2));
    end
    % if it is a one channel instrument, don't attempt to load channels 2, 3 & 4
    if (~isempty(strfind(opts, '001')))
        xfprintf(f, ':INST:DACM MARKER', 1);
        channelMapping(2,:) = zeros(1,size(channelMapping, 2));
        channelMapping(3,:) = zeros(1,size(channelMapping, 2));
        channelMapping(4,:) = zeros(1,size(channelMapping, 2));
    end
    % if it is a 4-channel instrument then
    % - if we have data to load in channels 2 or 3 and we are in 1-ch or 2-ch mode, switch to 4-ch mode
    % - if we have data to load in channel 4 and we are in 1-ch mode, switch to 4-ch mode
    if (~isempty(strfind(opts, '004')))
        if (~isempty(find(channelMapping(2:3,:), 1)))
            xfprintf(f, ':INST:DACM FOUR');
        elseif (~isempty(find(channelMapping(4,:), 1)) && ~isempty(strfind(dacMode, 'SING')))
            xfprintf(f, ':INST:DACM DUAL');
        end
    end
    
    % perform instrument reset if it is selected in the configuration
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        if (fs > 0 && sum(sum(channelMapping)) > 0 && (isempty(find(channelMapping(:,1), 1)) || isempty(find(channelMapping(:,2), 1))))
            warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                     'waveform to only one channel. This will delete the waveform on the' ...
                     'other channel. If you want to keep the previous waveform, please' ...
                     'un-check the "send *RST" checkbox in the Configuration window.'});
        end
        xfprintf(f, '*RST');
    end
    
    % stop waveform output
    if (xfprintf(f, sprintf(':ABORt')) ~= 0)
        % if ABORT does not work, let's not try anything else...
        % we will probably get many other errors
        return;
    end
    % set frequency
    if (fs ~= 0)
        if (isfield(arbConfig, 'clockSource'))
            switch (arbConfig.clockSource)
                case 'Unchanged'
                    xfprintf(f, sprintf(':FREQuency:RASTer %.15g;', fs));
                case 'IntRef'
                    xfprintf(f, sprintf(':ROSC:SOURce INT;:FREQuency:RASTer %.15g;', fs));
                case 'AxieRef'
                    xfprintf(f, sprintf(':ROSC:SOURce AXI;:FREQuency:RASTer %.15g;', fs));
                case 'ExtRef'
                    if (arbConfig.clockFreq <= 300e6)
                        range = 1;
                    elseif (arbConfig.clockFreq < 2.32e9)
                        range = 2;
                    elseif (arbConfig.clockFreq <= 3e9)
                        range = 3;
                    else
                        range = 2;
                    end
                    if (range == 3) % do not set :FREQ:RAST command in range 3
                        xfprintf(f, sprintf(':ROSC:SOURce EXT;RANGe RANG%d;FREQuency %.15g', range, arbConfig.clockFreq));
                        if (fs ~= 32 * arbConfig.clockFreq)
                            warndlg(sprintf('Sample Rate (%s) is not equal to 32 * RefClk frequency (%s)', iqengprintf(fs), iqengprintf(arbConfig.clockFreq)));
                        end
                    else
                        xfprintf(f, sprintf(':ROSC:SOURce EXT;RANGe RANG%d;FREQuency %.15g;:FREQuency:RASTer %.15g;', range, arbConfig.clockFreq, fs));
                    end
                case 'ExtClk'
                    errordlg('External sample clock is not supported for M8196A');
                    error('External sample clock is not supported for M8196A');
                otherwise error(['unexpected clockSource in arbConfig: ', arbConfig.clockSource]);
            end
        end
    end
    
    % apply skew if necessary
    if (isfield(arbConfig, 'skew') && arbConfig.skew ~= 0)
        data = iqdelay(data, fs, arbConfig.skew);
    end

    % direct mode waveform download
    for col = 1:size(channelMapping, 2) / 2
        for ch = find(channelMapping(:, 2*col-1))'
            gen_arb_M8196A(arbConfig, f, ch, real(data(:,col)), marker1, segmNum, run);
        end
        for ch = find(channelMapping(:, 2*col))'
            gen_arb_M8196A(arbConfig, f, ch, imag(data(:,col)), marker2, segmNum, run);
        end
    end
    
    if (run == 1 && sum(sum(channelMapping)) ~= 0)
        xfprintf(f, ':INIT:IMMediate');
    end
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end
end


function gen_arb_M8196A(arbConfig, f, chan, data, marker, segm_num, run)
% download an arbitrary waveform signal to a given channel and segment
    if (isempty(chan) || ~chan)
        return;
    end
    if (isfield(arbConfig, 'peaking'))
        a = fixlength(arbConfig.peaking, 4);
        xfprintf(f, sprintf(':OUTP%d:VPCORR %f', chan, a(chan)));
    end
    segm_len = length(data);
    if (segm_len > 0)
        % Try to delete the segment, but ignore errors if it does not exist
        % Another approach would be to first find out if it exists and only
        % then delete it, but that takes much longer
        if (run >= 0)
            xfprintf(f, sprintf(':TRACe%d:DELete %d', chan, segm_num), 1);
            xfprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segm_num, segm_len));
        end
        % scale to DAC values - data is assumed to be -1 ... +1
        data = int8(round(127 * data));
        dataSize = 'int8';
        dacMode = xquery(f, ':INST:DACM?');
        if (chan == 1 && (strncmp(dacMode, 'MARK', 4) || strncmp(dacMode, 'DCM', 3)))
            dataSize = 'int16';
            if (isempty(marker))
                marker = zeros(length(data), 1);
            end
            if (length(marker) ~= length(data))
                errordlg('length of marker vector and data vector must be the same');
            else
                data = int16(data);
                data = bitand(data, 255);
                data = data + int16(256 * marker);
                % swap MSB and LSB bytes in case of TCP/IP connection
                if (strcmp(f.type, 'tcpip'))
                    data = swapbytes(data);
                end
                % marker outputs are not automatically turned on
                xfprintf(f, sprintf(':OUTPut2 ON;:OUTPut3 ON'));
            end
        end
        % Download the arbitrary waveform. 
        % Split large waveform segments in reasonable chunks
        use_binblockwrite = 1;
        offset = 0;
        while (offset < segm_len)
            if (use_binblockwrite)
                len = min(segm_len - offset, 524288);
                cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset);
                xbinblockwrite(f, data(1+offset:offset+len), dataSize, cmd);
            else
                len = min(segm_len - offset, 9600);
                cmd = sprintf(':TRACe%d:DATA %d,%d', chan, segm_num, offset);
                cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                xfprintf(f, cmd);
            end
            offset = offset + len;
        end
        xquery(f, '*opc?');
    end
    if (isfield(arbConfig,'amplitude'))
        a = fixlength(arbConfig.amplitude, 4);
        xfprintf(f, sprintf(':VOLTage%d:AMPLitude %g', chan, a(chan)));
    end
    if (isfield(arbConfig,'offset'))
        a = fixlength(arbConfig.offset, 4);
        xfprintf(f, sprintf(':VOLTage%d:OFFSet %g', chan, a(chan)));
    end
    xfprintf(f, sprintf(':OUTPut%d ON', chan));
end


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, numel(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
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


function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, -1 for errors

    retVal = 0;
% set debugScpi=1 in MATLAB workspace to log SCPI commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s\n', s);
    end
    fprintf(f, s);
    result = query(f, ':syst:err?');
    if (isempty(result))
        fclose(f);
        errordlg({'The M8196A firmware did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'}, 'Error');
        retVal = -1;
        return;
    end
    if (~exist('ignoreError', 'var') || ignoreError == 0)
        while (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
            errordlg({'M8196A firmware returns an error on command:' s 'Error Message:' result});
            result = query(f, ':syst:err?');
            retVal = -1;
        end
    end
end
