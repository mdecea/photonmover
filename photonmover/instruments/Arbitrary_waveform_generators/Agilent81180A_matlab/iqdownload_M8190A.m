function result = iqdownload_M8190A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, chMap, sequence, run, segmentLength, segmentOffset)
% Download a waveform to the M8190A
% It is NOT intended that this function be called directly, only via iqdownload
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    result = [];
    if (isempty(segmentLength))
        segmentLength = length(data);
    end
    if (isempty(segmentOffset))
        segmentOffset = 0;
    end

    % find out if sync module is used
    useM8192A = 0;
    if (isfield(arbConfig, 'useM8192A') && (arbConfig.useM8192A ~= 0))
        useM8192A = 1;
    end
    
    % if multi-module configurations, call slave M8190A download routines
    if (isfield(arbConfig, 'amplitude'))
        chIdx = find(arbConfig.channelMask);
        ampTmp = zeros(1, length(arbConfig.channelMask));
        ampTmp(chIdx) = fixlength(arbConfig.amplitude, length(chIdx));
    else
        ampTmp = [];
    end
    if (isfield(arbConfig, 'offset'))
        chIdx = find(arbConfig.channelMask);
        offTmp = zeros(1, length(arbConfig.channelMask));
        offTmp(chIdx) = fixlength(arbConfig.offset, length(chIdx));
    else
        offTmp = [];
    end
    for m = 4:-1:2
        va = sprintf('visaAddr%d', m);
        if (size(chMap, 1) > 2*(m-1) && isfield(arbConfig, va))
            arbTmp = arbConfig;
            arbTmp.visaAddr = arbTmp.(va);
            arbTmp.setupSlave = useM8192A;  % mark calls to slave modules
            if (~isempty(ampTmp))
                arbTmp.amplitude = ampTmp(2*(m-1)+1:min(2*m,size(chMap,1)));
            end
            if (~isempty(offTmp))
                arbTmp.offset = offTmp(2*(m-1)+1:min(2*m,size(chMap,1)));
            end
            result = iqdownload_M8190A(arbTmp, fs, data, marker1, marker2, segmNum, keepOpen, chMap(2*(m-1)+1:min(2*m,size(chMap,1)),:), sequence, run, segmentLength, segmentOffset);
        end
    end
    % don't try to download more than 2 channels in first module
    chMap(3:end,:) = [];
    
    % interpolation factor for digital upconversion modes
    interpolationFactor = 1;
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    result = f;
    
    % find out if we have a one-channel or two channel instrument.
    try
        opts = query(f, '*opt?');
    catch ex
        errordlg({'Can not communicate with M8190A Firmware. Please try again.'
            'If this does not solve the problem, exit and restart MATLAB and the M8190A firmware'
            ['(Error message: ' ex.message]});
        instrreset();
        return;
    end
    if (~isempty(strfind(opts, '001')))
        numChannels = 1;
        % be graceful with one-channel instruments and ignore anything
        % that deals with the second channel
        chMap(2,:) = [0 0];
    else
        numChannels = 2;
    end
    % find out if we are in LPN mode
    if (~isempty(strfind(opts, 'LPN')))
        lpn = str2double(query(f, ':FREQ:RAST:LPN:ACT?'));
    else
        lpn = 0;
    end
    % treat sequence setup completely separate from waveform download
    if (~isempty(sequence))
        result = setupSequence(f, arbConfig, sequence, chMap, run, useM8192A, keepOpen);
    else
        % perform instrument reset if it is selected in the configuration
        if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
            if (isempty(find(chMap(1,:), 1)) || isempty(find(chMap(2,:), 1)))
                warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                         'waveform to only one channel. This will delete the waveform on the' ...
                         'other channel. If you want to keep the previous waveform, please' ...
                         'un-check the "send *RST" checkbox in the Configuration window.'});
            elseif (segmNum ~= 1)
                warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                         'waveform to segment number greater than 1. This will delete all other' ...
                         'waveform segments. If you want to keep the previous waveform, please' ...
                         'un-check the "send *RST" checkbox in the Configuration window.'});
            elseif (segmentOffset ~= 0)
                warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                         'waveform in a number of blocks. This will not work. Plase ' ...
                         'un-check the "send *RST" checkbox in the Configuration window.'});
            end
            xfprintf(f, '*RST');
        end
        % stop waveform output
        if (segmentOffset == 0)
            if (useM8192A)
                try
                    arbSync = loadArbConfig();
                    arbSync.visaAddr = arbConfig.visaAddrM8192A;
                    fsync = iqopen(arbSync);
                    xfprintf(fsync, ':ABOR');
                    xfprintf(fsync, ':inst:mmod:conf 1');
                    xfprintf(fsync, ':inst:slave:del:all');
                    xfprintf(fsync, ':inst:mast ""');
                    query(fsync, '*opc?');
                    fclose(fsync);
                catch ex
                    msgbox(ex.message);
                end
            else
                if (run >= 0)
                    for i = find(chMap(:,1) + chMap(:,2))'
                        xfprintf(f, sprintf(':ABORt%d', i));
                    end
                end
            end
        end
        % determine which version of the instrument we have and set parameters
        % accordingly
        switch (arbConfig.model)
            case 'M8190A_12bit'
                dwid = 'WSPeed';
            case 'M8190A_14bit'
                dwid = 'WPRecision';
            case { 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }
                interpolationFactor = eval(arbConfig.model(13:end));
                fs = fs * interpolationFactor;
                dwid = sprintf('INTX%d', interpolationFactor);
            otherwise
                dwid = [];
                % older instrument - do not send any command
        end
        % set frequency, int/ext and precision in a single command to avoid out-of-range errors
        if (fs ~= 0 && segmentOffset == 0)
            for i = find(chMap(:,1) + chMap(:,2))'
                cmd = sprintf(':FREQuency:RASTer %.15g;', fs);
                if ((isfield(arbConfig, 'extClk') && arbConfig.extClk) || lpn)
                    cmd = sprintf(':FREQuency:RASTer:SOURce%d EXTernal; :FREQuency:RASTer:EXTernal %.15g;', i, fs); % legacy: no clockFreq field
                elseif (isfield(arbConfig, 'clockSource'))
                    switch (arbConfig.clockSource)
                        case 'Unchanged'
                            cmd = sprintf(':FREQuency:RASTer %.15g;', fs);
                        case 'IntRef'
                            cmd = sprintf(':ROSC:SOURce INT; :FREQuency:RASTer:SOURce%d INTernal; :FREQuency:RASTer %.15g;', i, fs);
                        case 'AxieRef'
                            cmd = sprintf(':ROSC:SOURce AXI; :FREQuency:RASTer:SOURce%d INTernal; :FREQuency:RASTer %.15g;', i, fs);
                        case 'ExtRef'
                            cmd = sprintf(':ROSC:SOURce EXT; :ROSC:FREQuency %.15g; :FREQuency:RASTer:SOURce%d INTernal; :FREQuency:RASTer %.15g;', arbConfig.clockFreq, i, fs);
                        case 'ExtClk'
                            if (fs ~= arbConfig.clockFreq)
                                errordlg(sprintf('Mismatch between external sample clock frequency (%s) and waveform sample rate (%s)', iqengprintf(arbConfig.clockFreq), iqengprintf(fs)));
                            end
                            cmd = sprintf(':FREQuency:RASTer:SOURce%d EXTernal; :FREQuency:RASTer:EXTernal %.15g;', i, arbConfig.clockFreq);
                        otherwise error(['unexpected clockSource in arbConfig: ', arbConfig.clockSource]);
                    end
                end
                if (~isempty(dwid))
                    % set format on both channels in all cases
                    % otherwise, an error might occur if the channels
                    % are uncoupled
                    if (numChannels == 1)
                        cmd = sprintf('%s :TRACe1:DWIDth %s;', cmd, dwid);
                    else
                        cmd = sprintf('%s :TRACe1:DWIDth %s; :TRACe2:DWIDth %s;', cmd, dwid, dwid);
                    end
                end
                % if we get an error when setting the mode, don't attempt to
                % do anything else - it will not work
                % However, if the SYNC module is in use, ignore errors
                % (can't set sample rate in slave module)
                if (xfprintf(f, cmd, useM8192A) ~= 0)
%                if (xfprintf(f, cmd, 1) ~= 0)
                    return;
                end
                % workaround: read error queue one more time, because
                % the slave M8190A will throw two errors.
                % Ideally, this should be taken care of in xfprintf
                if (useM8192A)
                    query(f, ':syst:err?');
                    query(f, ':syst:err?');
                end
            end
            contMode = 1;
            gateMode = 0;
            if (isfield(arbConfig, 'triggerMode'))
                switch(arbConfig.triggerMode)
                    case 'Continuous'
                        contMode = 1;
                        gateMode = 0;
                    case 'Triggered'
                        contMode = 0;
                        gateMode = 0;
                    case 'Gated'
                        contMode = 0;
                        gateMode = 1;
                    otherwise
                        contMode = -1;
                        gateMode = -1;
                end
            end
            if (~useM8192A && contMode >= 0)
                for i = find(chMap(:,1) + chMap(:,2))'
                    xfprintf(f, sprintf(':INIT:CONTinuous%d %d;GATE%d %d', i, contMode, i, gateMode));
                end
            end
        end
        if (interpolationFactor ~= 1)
            % DUC mode waveform download
            for col = 1:size(chMap, 2) / 2
                for ch = find(chMap(:, 2*col-1))'
                    if (ch == 1); marker = marker1; else; marker = marker2; end
                    gen_arb_IQ_M8190A(arbConfig, f, ch, data(:,col), marker, segmNum, segmentLength, segmentOffset);
                end
            end
        else
            % direct mode waveform download
            for col = 1:size(chMap, 2) / 2
                for ch = find(chMap(:, 2*col-1))'
                    gen_arb_M8190A(arbConfig, f, ch, real(data(:,col)), marker1, segmNum, run, segmentLength, segmentOffset);
                end
                for ch = find(chMap(:, 2*col))'
                    gen_arb_M8190A(arbConfig, f, ch, imag(data(:,col)), marker2, segmNum, run, segmentLength, segmentOffset);
                end
            end
        end
        if (isfield(arbConfig,'skew') && isfloat(arbConfig.skew))
            % in arbConfig, there is no separate skew value for ch1 and
            % ch2. Positive values mean Ch1 is delayed, negative values
            % mean that Ch2 is delayed
            skew = arbConfig.skew;
            ch = 1;
            if (skew < 0)
                skew = -1 * skew;
                ch = 2;
            end
            if (arbConfig.skew > 30e-12)
                xfprintf(f, sprintf(':ARM:CDELay%d %.12g', ch, skew));
                xfprintf(f, sprintf(':ARM:DELay%d 0', ch));
                if (numChannels > 1)
                    xfprintf(f, sprintf(':ARM:CDELay%d %.12g', 3-ch, 0));
                    xfprintf(f, sprintf(':ARM:DELay%d 0', 3-ch));
                end
            else
                xfprintf(f, sprintf(':ARM:CDELay%d 0', ch));
                xfprintf(f, sprintf(':ARM:DELay%d %.12g', ch, arbConfig.skew));
                if (numChannels > 1)
                    xfprintf(f, sprintf(':ARM:CDELay%d 0', 3-ch));
                    xfprintf(f, sprintf(':ARM:DELay%d %.12g', 3-ch, 0));
                end
            end
        end
        if (isempty(segmentLength) || segmentOffset + length(data) >= segmentLength)
            doRun(f, arbConfig, useM8192A, chMap, run, keepOpen);
        end
    end
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end
end


function doRun(f, arbConfig, useM8192A, chMap, run, keepOpen)
    if (useM8192A)
        % don't do anything for the recursive call
        if (run ~= 0 && (~isfield(arbConfig, 'setupSlave') || arbConfig.setupSlave == 0))
            try
                arbSync = loadArbConfig();
                arbSync.visaAddr = arbSync.visaAddrM8192A;
                fsync = iqopen(arbSync);
                xfprintf(fsync, ':ABOR');
                xfprintf(fsync, ':INST:MMOD:CONF 1');
                xfprintf(fsync, ':INST:MAST ""');
                xfprintf(fsync, ':INST:SLAVE:DEL:ALL');
                xfprintf(fsync, sprintf(':INST:MAST "%s"', arbConfig.visaAddr));
                for m = 2:4
                    va = sprintf('visaAddr%d', m);
                    if (isfield(arbConfig, va))
                        xfprintf(fsync, sprintf(':INST:SLAVE:ADD "%s"', arbConfig.(va)));
                    end
                end
                xfprintf(fsync, ':INST:MMOD:CONF 0');
                % for triggered mode, switch the Trace Advance back to AUTO
                if (isfield(arbConfig, 'triggerMode') && strcmp(arbConfig.triggerMode, 'Triggered'))
                    for i = find(chMap(:,1) + chMap(:,2))'
                        xfprintf(f, sprintf(':TRACE%d:ADV AUTO', i));
                    end
                    for m = 2:4
                        va = sprintf('visaAddr%d', m);
                        if (isfield(arbConfig, va))
                            fx = iqopen(arbConfig.(va));
                            if (isempty(fx))
                                continue;
                            end
                            for i = find(chMap(:,1) + chMap(:,2))'
                                xfprintf(fx, sprintf(':TRACE%d:ADV AUTO', i));
                            end
                            fclose(fx);
                        end
                    end
                end
                xfprintf(fsync, ':INIT:IMM');
                xfprintf(fsync, ':TRIG:BEG');
                query(fsync, '*OPC?');
                fclose(fsync);
            catch ex
                msgbox(ex.message);
            end
        end
    else
        % turn on channel coupling only if download to both channels
        % otherwise keep the previous setting. If the user wants de-coupled
        % channels, he has to do that in the SFP or outside this script
        if (length(find(chMap(:,1) + chMap(:,2))) > 1)
            xfprintf(f, ':INST:COUP:STATe ON');
        end
        if (run ~= 0)
            % setting ARB mode is now done in gen_arb function
            for i = find(chMap(:,1) + chMap(:,2))'
                xfprintf(f, sprintf(':INIT:IMM%d', i));
            end
        end
    end
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end;
end


function gen_arb_M8190A(arbConfig, f, chan, data, marker, segm_num, run, segmentLength, segmentOffset)
% download an arbitrary waveform signal to a given channel and segment
    if (isempty(chan) || ~chan)
        return;
    end
    segm_len = length(data);
    if (segm_len > 0)
        % Try to delete the segment, but ignore errors if it does not exist
        % Another approach would be to first find out if it exists and only
        % then delete it, but that takes much longer
        if (run >= 0 && segmentOffset == 0)
            xfprintf(f, sprintf(':TRACe%d:DELete %d', chan, segm_num), 1);
            xfprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segm_num, segmentLength));
        end
        % scale to DAC values - data is assumed to be -1 ... +1
        % set debugBits = n in MATLAB workspace for custom bits
        if (evalin('base', 'exist(''debugBits'', ''var'')'))
            bits = evalin('base','debugBits');
            data =  int16(round((2^(bits)/2-1) * data) * 2^(16-bits));
        else
            data = int16(round(8191 * data) * 4);
        end
        if (~isempty(marker))
            if (length(marker) ~= length(data))
                errordlg('length of marker vector and data vector must be the same');
            else
                data = data + int16(bitand(uint16(marker), 3));
            end
        end
        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end
        % Download the arbitrary waveform. 
        % Split large waveform segments in reasonable chunks
        use_binblockwrite = 1;
        offset = 0;
        while (offset < segm_len)
            if (use_binblockwrite)
                len = min(segm_len - offset, 523200);
                cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset + segmentOffset);
                xbinblockwrite(f, data(1+offset:offset+len), 'int16', cmd);
                xfprintf(f, '');
            else
                len = min(segm_len - offset, 9600);
                cmd = sprintf(':TRACe%d:DATA %d,%d', chan, segm_num, offset + segmentOffset);
                cmd = [cmd sprintf(',%d', data(1+offset:offset+len))];
                xfprintf(f, cmd);
            end
            offset = offset + len;
        end
        query(f, '*opc?\n');
        if (run >= 0 && (segmentOffset + length(data) >= segmentLength))
            xfprintf(f, sprintf(':TRACe%d:SELect %d', chan, segm_num));
        end
    end
    if (segmentOffset + length(data) >= segmentLength)
        if (isfield(arbConfig, 'ampType'))
            xfprintf(f, sprintf(':OUTPut%d:ROUTe %s', chan, arbConfig.ampType));
        end
        if (isfield(arbConfig,'amplitude'))
            a = fixlength(arbConfig.amplitude, 2);
            xfprintf(f, sprintf(':VOLTage%d:AMPLitude %g', chan, a(chan)));
        end
        if (isfield(arbConfig,'offset'))
            a = fixlength(arbConfig.offset, 2);
            xfprintf(f, sprintf(':VOLTage%d:OFFSet %g', chan, a(chan)));    
        end
        if (run >= 0) % when running in ping pong mode, don't set mode
            xfprintf(f, sprintf(':FUNCtion%d:MODE ARBitrary', chan));
        end
        xfprintf(f, sprintf(':OUTPut%d ON', chan));
    end
end


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, numel(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
end


function gen_arb_IQ_M8190A(arbConfig, f, chan, data, marker, segm_num, segmentLength, segmentOffset)
% download an IQ waveform to a given channel and segment number.
% Set the sampling rate to fs
    if (isempty(chan) || ~chan)
        return;
    end
    segm_len = length(data);
    if (segm_len > 0)
        % Try to delete the segment, but ignore errors if it does not exist
        % Another approach would be to first find out if it exists and only
        % then delete it, but that takes much longer
        if (segmentOffset == 0)
            xfprintf(f, sprintf(':TRACe%d:DELete %d', chan, segm_num), 1);
            xfprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segm_num, segmentLength));
        end
        % split into I & Q
        dacData(1,:) = real(data);
        dacData(2,:) = imag(data);
        % scale to DAC values - data is assumed to be -1 ... +1
        dacData = int16(round(16383 * dacData) * 2);
        % insert marker data
        if (~isempty(marker))
            if (length(marker) ~= segm_len)
                errordlg('length of marker vector and data vector must be the same');
            else
                dacData(1,:) = dacData(1,:) + int16(bitget(uint16(marker'), 1));  % sample marker
                dacData(2,:) = dacData(2,:) + int16(bitget(uint16(marker'), 2));  % sync marker
            end
        end
        % merge I & Q into a vector
        data = dacData(:);        
        segm_len = length(data);
        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end
        % Download the arbitrary waveform. 
        % Split large waveform segments in reasonable chunks
        use_binblockwrite = 1;
        offset = 0;
        while (offset < segm_len)
            if (use_binblockwrite)
                len = min(segm_len - offset, 523200);
                cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset/2 + segmentOffset);
                xbinblockwrite(f, data(1+offset:offset+len), 'int16', cmd);
                xfprintf(f, '');
            else
                len = min(segm_len - offset, 4800);
                cmd = sprintf(':TRACe%d:DATA %d,%d', chan, segm_num, offset/2 + segmentOffset);
                cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                xfprintf(f, cmd);
            end
            offset = offset + len;
        end
        query(f, '*OPC?\n');
        xfprintf(f, sprintf(':TRACe%d:SELect %d', chan, segm_num));
    end
    if (segmentOffset + offset/2 >= segmentLength)
        if (isfield(arbConfig,'carrierFrequency'))
            xfprintf(f, sprintf(':CARRier%d:FREQuency %.0f,%g', ...
                chan, floor(arbConfig.carrierFrequency), arbConfig.carrierFrequency - floor(arbConfig.carrierFrequency)));
        end
        if (isfield(arbConfig, 'ampType'))
            xfprintf(f, sprintf(':OUTPut%d:ROUte %s', chan, arbConfig.ampType));
        end
        if (isfield(arbConfig,'amplitude'))
            a = fixlength(arbConfig.amplitude, 2);
            xfprintf(f, sprintf(':VOLTage%d:AMPLitude %g', chan, a(chan)));
        end
        if (isfield(arbConfig,'offset'))
            a = fixlength(arbConfig.offset, 2);
            xfprintf(f, sprintf(':VOLTage%d:OFFSet %g', chan, a(chan)));    
        end
        xfprintf(f, sprintf(':FUNCtion%d:MODE ARBitrary', chan));
        xfprintf(f, sprintf(':OUTPut%d ON', chan));
    end
end


function result = setupSequence(f, arbConfig, seqcmd, channelMapping, run, useM8192A, keepOpen)
% Perform sequencer-related functions. The format of "seqcmd" is described
% in iqseq.m
% check what to do: seqcmd.cmd contains the function to perform and
% seqcmd.sequence contains the parameter(s)
    result = [];
    switch (seqcmd.cmd)
        case 'list'
            s = sscanf(query(f, sprintf(':TRACe%d:CATalog?', find(channelMapping(:,1) + channelMapping(:,2), 1))), '%d,');
            s = reshape(s,2,length(s)/2);
            if (s(1,1) == 0)
                errordlg({'There are no segments defined.' ...
                    'Please load segments before calling this function and make sure' ...
                    'that the "send *RST" checkbox in the config window is un-checked'} );
            else
                errordlg(sprintf('The following segments are defined:%s', ...
                    sprintf(' %d', s(1,:))));
                result = s(1,:);
            end
        case 'delete'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                xfprintf(f, sprintf(':TRACe%d:DELete:ALL', i));
                xfprintf(f, sprintf(':STABle%d:RESET', i));
            end
        case 'event'
            xfprintf(f, ':TRIGger:ADVance:IMMediate');
        case 'trigger'
            xfprintf(f, ':TRIGger:BEGin:IMMediate');
        case 'define'
            defineSequence(f, seqcmd, channelMapping, run);
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':STAB%d:SCEN:ADV CONDitional', i));
            end
            doRun(f, arbConfig, useM8192A, channelMapping, run, keepOpen);
        case 'amplitudeTable'
            list = seqcmd.sequence;
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                binary = 0;
                if (binary)
                    list = 32767 * int32(list);
                    xbinblockwrite(f, list, 'int32', sprintf(':ATABle%d:DATA 0,', i));
                    xfprintf(f, '');
                else
                    cmd = sprintf(',%g', list);
                    xfprintf(f, sprintf(':ATABle%d:DATA 0%s', i, cmd));
                end
            end
        case 'frequencyTable'
            list = seqcmd.sequence;
            % convert frequencies into integral & fractional part
            list2 = zeros(1, 2*length(list));
            for i=1:length(list)
                list2(2*i-1) = floor(list(i));
                list2(2*i) = list(i) - floor(list(i));
            end
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                binary = 0;
                if (binary)
                    xbinblockwrite(f, list2, 'float32', sprintf(':FTABle%d:DATA 0,', i));
                    xfprintf(f, '');
                else
                    cmd = sprintf(',%.15g', list2);
                    xfprintf(f, sprintf(':FTABle%d:DATA 0%s', i, cmd));
                end
            end
        case 'actionDefine'
            list = seqcmd.sequence;
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                result = str2double(query(f, sprintf(':ACTion%d:DEFine:NEW?', i)));
            end
            seqcmd.cmd = 'actionAppend';
            seqcmd.sequence = [ result list ];
            setupSequence(f, arbConfig, seqcmd, channelMapping, run, useM8192A, keepOpen);
        case 'actionAppend'
            list = seqcmd.sequence;
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                for j = 2:2:length(list)
                    if (isempty(list{j+1}))   % no parameter e.g.      SRUN
                        xfprintf(f, sprintf(':ACTion%d:APPend %d,%s', ...
                            i, list{1}, list{j}));
                    elseif (isscalar(list{j+1}))    % single parameter e.g.   PBUMp, 0.4
                        if (strncmpi(list{j}, 'CFR', 3) || strncmpi(list{j}, 'SRAT', 4))
                            % for CFrequency and SRate, use the integral/fractional split
                            xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g,%.15g', ...
                                i, list{1}, list{j}, floor(list{j+1}), list{j+1}-floor(list{j+1})));
                        elseif (strncmpi(list{j}, 'PBUM', 4) || strncmpi(list{j}, 'POFF', 4))
                            % convert from degrees into -0.5 to +0.5
                            val = list{j+1} / 360;
                            val = val - floor(val);
                            if (val > 0.5)
                                val = val - 1;
                            end
                            xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g', ...
                                i, list{1}, list{j}, val ));
                        elseif (strncmpi(list{j}, 'PRES', 4))
                            % convert from degrees into 0...1
                            val = list{j+1} / 360;
                            val = val - floor(val);
                            xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g', ...
                                i, list{1}, list{j}, val ));
                        else
                            xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g', ...
                                i, list{1}, list{j}, list{j+1}));
                        end
                    else    % dual parameter e.g.   CFRequency, 100e6, 0.5
                        xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g,%.15g', ...
                            i, list{1}, list{j}, list{j+1}));
                    end
                end
            end
        case 'actionDelete'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                xfprintf(f, sprintf(':ACTion%d:DELete %d', i, seqcmd.sequence));
            end
        case 'actionDeleteAll'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                xfprintf(f, sprintf(':ACTion%d:DELete:ALL', i));
            end
        case 'dynamic'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                xfprintf(f, sprintf(':STABle%d:DYNamic %d', i, seqcmd.sequence));
            end
        case 'mode'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
                xfprintf(f, sprintf(':FUNCtion%d:MODE %s', i, seqcmd.sequence));
                xfprintf(f, sprintf(':STAB%d:SCEN:ADV CONDitional', i));
            end
            doRun(f, arbConfig, useM8192A, channelMapping, run, keepOpen);
        case 'trigAdvance'
            xfprintf(f, sprintf(':TRIGger:SOURce:ADVance %s', seqcmd.sequence));
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':TRIGger:ADVance%d:HWDisable OFF', i));
            end
        case 'triggerMode'
            switch seqcmd.sequence
                case {1 'triggered'}
                    s = '0';
                case {0 'continuous'}
                    s = '1';
                otherwise
                    error('unknown triggerMode');
            end
%            xfprintf(f, sprintf(':ARM:TRIG:SOUR EXT'));
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':INIT:CONTinuous%d %s;GATE%d 0', i, s, i));
            end
        case 'stop'
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':ABORt%d', i));
            end
        case 'readSequence'
            result = readSequence(f, seqcmd, channelMapping);
        otherwise
            errordlg(['undefined sequence command: ' seqcmd.cmd]);
    end
end


function defineSequence(f, seqcmd, channelMapping, run)
% define a new sequence table
    xfprintf(f, ':ABORt');
    seqtable = seqcmd.sequence;
% check if only valid fieldnames are used (typo?)
    fields = fieldnames(seqtable);
    fields(find(strcmp(fields, 'segmentNumber'))) = [];
    fields(find(strcmp(fields, 'segmentLoops'))) = [];
    fields(find(strcmp(fields, 'segmentAdvance'))) = [];
    fields(find(strcmp(fields, 'sequenceAdvance'))) = [];
    fields(find(strcmp(fields, 'sequenceLoops'))) = [];
    fields(find(strcmp(fields, 'markerEnable'))) = [];
    fields(find(strcmp(fields, 'sequenceInit'))) = [];
    fields(find(strcmp(fields, 'sequenceEnd'))) = [];
    fields(find(strcmp(fields, 'scenarioEnd'))) = [];
    fields(find(strcmp(fields, 'amplitudeInit'))) = [];
    fields(find(strcmp(fields, 'amplitudeNext'))) = [];
    fields(find(strcmp(fields, 'frequencyInit'))) = [];
    fields(find(strcmp(fields, 'frequencyNext'))) = [];
    fields(find(strcmp(fields, 'actionID'))) = [];
    if (~isempty(fields))
        disp('The following field names are unknown:');
        disp(fields);
        error('unknown field names');
    end
% check if all the segments are defined
    if (~isempty(find(channelMapping(:,1) + channelMapping(:,2), 1)))
        s = sscanf(query(f, sprintf(':trac%d:cat?', find(channelMapping(:,1) + channelMapping(:,2), 1))), '%d,');
        s = reshape(s,2,length(s)/2);
        notDef = [];
        for i = 1:length(seqtable)
            if (isempty(find(s(1,:) == seqtable(i).segmentNumber, 1)))
                notDef = [notDef seqtable(i).segmentNumber];
            end
        end
        notDef = notDef(notDef > 0);    % ignore zero and negative numbers, they are special commands
        if (~isempty(notDef))
            errordlg({ sprintf('The following segments are used in the sequence but not defined:%s.', ...
                sprintf(' %d', notDef)) ...
                'Please load segments before calling this function and make sure' ...
                'that the "send *RST" checkbox in the config window is un-checked'} );
            return;
        end
    end
% download the sequence table
    seqData = uint32(zeros(6 * length(seqtable), 1));
    for i = 1:length(seqtable)
            seqTabEntry = calculateSeqTableEntry(seqtable(i), i, length(seqtable));
            seqData(6*i-5:6*i) = seqTabEntry;
            % if the variable 'debugSeq' exists in the base workspace,
            % print out the sequence table as hex numbers
            if (evalin('base', 'exist(''debugSeq'', ''var'')'))
                fprintf('Seq Write %03d: ', i);
                fprintf('%08X ', seqTabEntry);
                fprintf('\n');
            end
    end
    % swap MSB and LSB bytes in case of TCP/IP connection
    if (strcmp(f.type, 'tcpip'))
        seqData = swapbytes(seqData);
    end
    for i = find(channelMapping(:,1) + channelMapping(:,2))'
        xbinblockwrite(f, seqData, 'uint32', sprintf(':STABle%d:DATA 0,', i));
        xfprintf(f, '');
%            cmd = sprintf(',%.0f', seqData);
%            xfprintf(f, sprintf(':STABle%d:DATA 0%s', i, cmd));
        xfprintf(f, sprintf(':STABle%d:SEQuence:SELect %d', i, 0));
        xfprintf(f, sprintf(':STABle%d:DYNamic:STATe 0', i));
        xfprintf(f, sprintf(':FUNCtion%d:MODE STSequence', i));
    end
end

function seqTabEntry = calculateSeqTableEntry(seqline, currLine, numLines)
% calculate the six 32-bit words that make up one sequence table entry.
% For details on the format, see user guide section 4.20.6
%
% The content of the six 32-bit words depends on the type of entry:
% Data Entry: Control / Seq.Loops / Segm.Loops / Segm.ID / Start Offset / End Offset
% Idle Cmd:   Control / Seq.Loops / Cmd Code(0) / Idle Sample / Delay / Unused
% Action:     Control / Seq.Loops / Cmd Code(1) + Act.ID / Segm.ID / Start Offset / End Offset
    cbitCmd = 32;
    cbitEndSequence = 31;
    cbitEndScenario = 30;
    cbitInitSequence = 29;
    cbitMarkerEnable = 25;
    cbitAmplitudeInit = 16;
    cbitAmplitudeNext = 15;
    cbitFrequencyInit = 14;
    cbitFrequencyNext = 13;
    cmaskSegmentAuto = hex2dec('00000000');
    cmaskSegmentCond = hex2dec('00010000');
    cmaskSegmentRept = hex2dec('00020000');
    cmaskSegmentStep = hex2dec('00030000');
    cmaskSequenceAuto = hex2dec('00000000');
    cmaskSequenceCond = hex2dec('00100000');
    cmaskSequenceRept = hex2dec('00200000');
    cmaskSequenceStep = hex2dec('00300000');
    seqLoopCnt = 1;

    ctrl = uint32(0);
    seqTabEntry = uint32(zeros(6, 1));        % initialize the return value
    if (seqline.segmentNumber == 0)           % segment# = 0 means: idle command
        ctrl = bitset(ctrl, cbitCmd);         % set the command bit
        seqTabEntry(3) = 0;                   % Idle command code = 0
        seqTabEntry(4) = 0;                   % Sample value
        if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops))
            seqTabEntry(5) = seqline.segmentLoops;  % use segment loops as delay
        else
            seqTabEntry(5) = 1;
        end
        seqTabEntry(6) = 0;                   % unused
    else
        if (isfield(seqline, 'actionID')&& ~isempty(seqline.actionID) && seqline.actionID >= 0)
            % if it is an actionID, set the command bit and action Cmd Code
            % and store actionID in 24 MSB of word#3.
            % The segment will not be repeated. segmentLoops is ignored
            ctrl = bitset(ctrl, cbitCmd);
            seqTabEntry(3) = 1 + bitshift(uint32(seqline.actionID), 16);
            if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops) && seqline.segmentLoops > 1)
                errordlg(['segmentLoops will be ignored when an actionID is specified (Seq.ID ' num2str(currLine-1) ')']);
            end
        else
            % normal data entries have the segment loop count in word#3
            if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops))
                seqTabEntry(3) = seqline.segmentLoops;
            else
                seqTabEntry(3) = 1;
            end
        end
        seqTabEntry(4) = seqline.segmentNumber;
        seqTabEntry(5) = 0;                   % start pointer
        seqTabEntry(6) = hex2dec('ffffffff'); % end pointer
        if (isfield(seqline, 'segmentAdvance') && ~isempty(seqline.segmentAdvance))
            switch (seqline.segmentAdvance)
                case 'Auto';        ctrl = bitor(ctrl, cmaskSegmentAuto);
                case 'Conditional'; ctrl = bitor(ctrl, cmaskSegmentCond);
                case 'Repeat';      ctrl = bitor(ctrl, cmaskSegmentRept);
                case 'Stepped';     ctrl = bitor(ctrl, cmaskSegmentStep);
                otherwise;          error(sprintf('unknown segment advance mode: %s', seqline.segmentAdvance));
            end
        end
        if (isfield(seqline, 'markerEnable') && ~isempty(seqline.markerEnable) && seqline.markerEnable)
            ctrl = bitset(ctrl, cbitMarkerEnable);
        end
    end
    % set the amplitude and frequency table flags
    if (isfield(seqline, 'amplitudeInit') && ~isempty(seqline.amplitudeInit) && seqline.amplitudeInit)
        ctrl = bitset(ctrl, cbitAmplitudeInit);
    end
    if (isfield(seqline, 'amplitudeNext') && ~isempty(seqline.amplitudeNext) && seqline.amplitudeNext)
        ctrl = bitset(ctrl, cbitAmplitudeNext);
    end
    if (isfield(seqline, 'frequencyInit') && ~isempty(seqline.frequencyInit) && seqline.frequencyInit)
        ctrl = bitset(ctrl, cbitFrequencyInit);
    end
    if (isfield(seqline, 'frequencyNext') && ~isempty(seqline.frequencyNext) && seqline.frequencyNext)
        ctrl = bitset(ctrl, cbitFrequencyNext);
    end
    % if the sequence fields exist, then set the sequence control bits
    % according to those fields
    if (isfield(seqline, 'sequenceInit'))
        if (seqline.sequenceInit)  % init sequence flag
            ctrl = bitset(ctrl, cbitInitSequence);
        end
        if (isfield(seqline, 'sequenceEnd')&& ~isempty(seqline.sequenceEnd) && seqline.sequenceEnd)
            ctrl = bitset(ctrl, cbitEndSequence);
        end
        if (isfield(seqline, 'sequenceLoops') && ~isempty(seqline.sequenceLoops))
            seqLoopCnt = seqline.sequenceLoops;
        end
        if (isfield(seqline, 'sequenceAdvance') && ~isempty(seqline.sequenceAdvance))
            switch (seqline.sequenceAdvance)  % sequence advance mode
                case 'Auto';        ctrl = bitor(ctrl, cmaskSequenceAuto);
                case 'Conditional'; ctrl = bitor(ctrl, cmaskSequenceCond);
                case 'Repeat';      ctrl = bitor(ctrl, cmaskSequenceRept);
                case 'Stepped';     ctrl = bitor(ctrl, cmaskSequenceStep);
                otherwise;          error(sprintf('unknown sequence advance mode: %s', seqline.sequenceAdvance));
            end
        end
        if (isfield(seqline, 'scenarioEnd') && ~isempty(seqline.scenarioEnd) && seqline.scenarioEnd)
            ctrl = bitset(ctrl, cbitEndScenario);
        end
    else
        % otherwise assume a single sequence and set start and
        % end of sequence flags automatically
        if (currLine == 1)
            ctrl = bitset(ctrl, cbitInitSequence);
        end
        if (currLine == numLines)
            ctrl = bitset(ctrl, cbitEndSequence);
            ctrl = bitset(ctrl, cbitEndScenario);
        end
    end
    seqTabEntry(1) = ctrl;                % control word
    seqTabEntry(2) = seqLoopCnt;          % sequence loops
end


function result = readSequence(f, seqcmd, channelMapping)
    clear seq;
    ch = 1;
    if (channelMapping(1,1) == 0)
        ch = 2;
    end
    start = 0;
    len = 100;  % maximum number of entries to read
    stab = query(f, sprintf(':STAB%d:DATA? %d,%d', ch, start, 6*len));
    stab = eval(sprintf('[%s]', stab));
    stab(stab < 0) = stab(stab < 0) + 2^32;
    stab = uint32(stab);
    for i = 1:length(stab)/6;
        if (evalin('base', 'exist(''debugSeq'', ''var'')'))
            fprintf('Seq Read  %03d: ', i-1);
            fprintf('%08X ', stab(6*(i-1)+1:6*(i-1)+6));
            fprintf('\n');
        end
        seq(i) = readSeqEntry(stab(6*(i-1)+1:6*(i-1)+6));
        seq(i).idx = i-1;
        if (seq(i).scenarioEnd ~= 0)
            break;
        end
    end
    result = seq;
end


function result = readSeqEntry(seqline)
% convert six 32-bit words into a table entry
% For details on the format, see user guide section 4.20.6
%
% The content of the six 32-bit words depends on the type of entry:
% Data Entry: Control / Seq.Loops / Segm.Loops / Segm.ID / Start Offset / End Offset
% Idle Cmd:   Control / Seq.Loops / Cmd Code(0) / Idle Sample / Delay / Unused
% Action:     Control / Seq.Loops / Cmd Code(1) + Act.ID / Segm.ID / Start Offset / End Offset

% initialize result struct.  Order is important!!
    result.idx = [];
    result.segmentNumber = [];
    result.segmentLoops = [];
    result.segmentAdvance = [];
    result.markerEnable = [];
    result.sequenceInit = [];
    result.sequenceLoops = [];
    result.sequenceAdvance = [];
    result.actionStr = [];
    result.amplCmd = [];
    result.freqCmd = [];
    %
    result.amplitudeInit = [];
    result.amplitudeNext = [];
    result.frequencyInit = [];
    result.frequencyNext = [];
    result.sequenceEnd = [];
    result.scenarioEnd = [];
    result.actionID = -1;

    cbitCmd = 32;
    cbitEndSequence = 31;
    cbitEndScenario = 30;
    cbitInitSequence = 29;
    cbitMarkerEnable = 25;
    cbitAmplitudeInit = 16;
    cbitAmplitudeNext = 15;
    cbitFrequencyInit = 14;
    cbitFrequencyNext = 13;
    cmaskSegmentAuto = hex2dec('00000000');
    cmaskSegmentCond = hex2dec('00010000');
    cmaskSegmentRept = hex2dec('00020000');
    cmaskSegmentStep = hex2dec('00030000');
    cmaskSequenceAuto = hex2dec('00000000');
    cmaskSequenceCond = hex2dec('00100000');
    cmaskSequenceRept = hex2dec('00200000');
    cmaskSequenceStep = hex2dec('00300000');
    seqLoopCnt = 1;

    ctrl = seqline(1);
    if (bitand(ctrl, bitshift(1,cbitCmd-1)))
        if (seqline(3) == 0)    % idle
            result.segmentNumber = 0;
            result.segmentLoops = seqline(5);
        else
            result.actionID = bitshift(seqline(3), -16);
            result.segmentNumber = seqline(4);
        end
    else
        result.segmentLoops = seqline(3);
        result.segmentNumber = seqline(4);
    end
    switch bitand(ctrl, cmaskSegmentStep)
        case cmaskSegmentAuto; result.segmentAdvance = 'Auto';
        case cmaskSegmentCond; result.segmentAdvance = 'Conditional';
        case cmaskSegmentRept; result.segmentAdvance = 'Repeat';
        case cmaskSegmentStep; result.segmentAdvance = 'Stepped';
        otherwise
            error('unexpected segment advance');
    end
    result.markerEnable = bitand(ctrl, bitshift(1, cbitMarkerEnable-1)) ~= 0;
    result.amplitudeInit = bitand(ctrl, bitshift(1, cbitAmplitudeInit-1)) ~= 0;
    result.amplitudeNext = bitand(ctrl, bitshift(1, cbitAmplitudeNext-1)) ~= 0;
    result.frequencyInit = bitand(ctrl, bitshift(1, cbitFrequencyInit-1)) ~= 0;
    result.frequencyNext = bitand(ctrl, bitshift(1, cbitFrequencyNext-1)) ~= 0;
    if (result.amplitudeInit)
        result.amplCmd = 'init';
    elseif (result.amplitudeNext)
        result.amplCmd = 'next';
    else
        result.amplCmd = 'none';
    end
    if (result.frequencyInit)
        result.freqCmd = 'init';
    elseif (result.frequencyNext)
        result.freqCmd = 'next';
    else
        result.freqCmd = 'none';
    end
    
    result.sequenceInit = bitand(ctrl, bitshift(1, cbitInitSequence-1)) ~= 0;
    result.sequenceEnd  = bitand(ctrl, bitshift(1, cbitEndSequence-1)) ~= 0;
    result.scenarioEnd  = bitand(ctrl, bitshift(1, cbitEndScenario-1)) ~= 0;
    result.sequenceLoops = seqline(2);
    switch bitand(ctrl, cmaskSequenceStep)
        case cmaskSequenceAuto; result.sequenceAdvance = 'Auto';
        case cmaskSequenceCond; result.sequenceAdvance = 'Conditional';
        case cmaskSequenceRept; result.sequenceAdvance = 'Repeat';
        case cmaskSequenceStep; result.sequenceAdvance = 'Stepped';
        otherwise
            error('unexpected sequence advance');
    end
end


function xbinblockwrite(f, data, format, cmd)
% set debugScpi=1 in MATLAB workspace to log SCPI commands
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    fprintf('binblockwrite: %s %s, %d elements\n', cmd, format, length(data));
end
binblockwrite(f, data, format, cmd);
fprintf(f, '');
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
    if (evalin('base', 'exist(''debugNoQuery'', ''var'')'))
        return;
    end
    result = query(f, ':syst:err?');
    if (isempty(result))
        fclose(f);
        errordlg({'The M8190A firmware did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'}, 'Error');
        retVal = -1;
        return;
    end
    if (~exist('ignoreError', 'var') || ignoreError == 0)
        while (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
            errordlg({'M8190A firmware returns an error on command:' s 'Error Message:' result});
            if (evalin('base', 'exist(''debugScpi'', ''var'')'))
                fprintf('ERROR = %s\n', result);
            end
            result = query(f, ':syst:err?');
            retVal = -1;
        end
    end
end
