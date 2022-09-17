function result = iqdownload_M8121A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run, segmentLength, segmentOffset)
% Download a waveform to the M8121A
% It is NOT intended that this function be called directly, only via iqdownload
%
% Thomas Dippon, Keysight Technologies 2018
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
    
    % if called with more than two channels, send data to second M8190A
    if (size(channelMapping, 1) > 2 && isfield(arbConfig, 'visaAddr2')) % && max(max(channelMapping(3:4,:))) > 0)
        arb2 = arbConfig;
        arb2.visaAddr = arb2.visaAddr2;
        result = iqdownload_M8190A(arb2, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping(3:4,:), sequence, run, segmentLength, segmentOffset);
        % if nothing on channels 1 & 2, return the result
        if (max(max(channelMapping(1:2,:))) == 0)
            return;
        end
    end
    channelMapping(3:end,:) = [];
    
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
        channelMapping(2,:) = [0 0];
    else
        numChannels = 2;
    end
    % find out if we are in LPN mode
%    if (~isempty(strfind(opts, 'LPN')))
%        lpn = str2double(query(f, ':FREQ:RAST:LPN:ACT?'));
%    else
        lpn = 0;
%    end
    % treat sequence setup completely separate from waveform download
    if (~isempty(sequence))
        errordlg('Sequencing is not supported by the M8121A');
        return
    else
        % perform instrument reset if it is selected in the configuration
        if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
            if (isempty(find(channelMapping(1,:), 1)) || isempty(find(channelMapping(2,:), 1)))
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
                    for i = find(channelMapping(:,1) + channelMapping(:,2))'
                        xfprintf(f, sprintf(':ABORt%d', i));
                    end
                end
            end
        end
        % determine which version of the instrument we have and set parameters
        % accordingly
        switch (arbConfig.model)
            case 'M8121A_12bit'
                dwid = 'WSPeed';
            case 'M8121A_14bit'
                dwid = 'WPRecision';
            case { 'M8121A_DUC_x3' 'M8121A_DUC_x12' 'M8121A_DUC_x24' 'M8121A_DUC_x48' }
                interpolationFactor = eval(arbConfig.model(13:end));
                fs = fs * interpolationFactor;
                dwid = sprintf('INTX%d', interpolationFactor);
            otherwise
                error('unknown instrument model: %s', arbConfig.model);
        end
        % set frequency, int/ext and precision in a single command to avoid out-of-range errors
        if (fs ~= 0 && segmentOffset == 0)
            cmd = sprintf(':FREQuency:RASTer %.15g;', fs);
            if ((isfield(arbConfig, 'extClk') && arbConfig.extClk) || lpn)
                cmd = sprintf(':FREQuency:RASTer:SOURce EXTernal; :FREQuency:RASTer:EXTernal %.15g;', fs); % legacy: no clockFreq field
            elseif (isfield(arbConfig, 'clockSource'))
                switch (arbConfig.clockSource)
                    case 'Unchanged'
                        cmd = sprintf(':FREQuency:RASTer %.15g;', fs);
                    case 'IntRef'
                        cmd = sprintf(':ROSC:SOURce INT; :FREQuency:RASTer:SOURce INTernal; :FREQuency:RASTer %.15g;', fs);
                    case 'AxieRef'
                        cmd = sprintf(':ROSC:SOURce AXI; :FREQuency:RASTer:SOURce INTernal; :FREQuency:RASTer %.15g;', fs);
                    case 'ExtRef'
                        cmd = sprintf(':ROSC:SOURce EXT; :ROSC:FREQuency %.15g; :FREQuency:RASTer:SOURce INTernal; :FREQuency:RASTer %.15g;', arbConfig.clockFreq, fs);
                    case 'ExtClk'
                        if (fs ~= arbConfig.clockFreq)
                            errordlg(sprintf('Mismatch between external sample clock frequency (%s) and waveform sample rate (%s)', iqengprintf(arbConfig.clockFreq), iqengprintf(fs)));
                        end
                        cmd = sprintf(':FREQuency:RASTer:SOURce EXTernal; :FREQuency:RASTer:EXTernal %.15g;', arbConfig.clockFreq);
                    otherwise
                        error(['unexpected clockSource in arbConfig: ', arbConfig.clockSource]);
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
            end
%                 for i = find(channelMapping(:,1) + channelMapping(:,2))'
%                     xfprintf(f, sprintf(':INIT:CONTinuous%d %d;GATE%d %d', i, contMode, i, gateMode));
%                 end

        end
        if (interpolationFactor ~= 1)
            % DUC mode waveform download
            for col = 1:size(channelMapping, 2) / 2
                for ch = find(channelMapping(:, 2*col-1))'
                    if (ch == 1); marker = marker1; else; marker = marker2; end
                    gen_arb_IQ_M8121A(arbConfig, f, ch, data(:,col), marker, segmNum, segmentLength, segmentOffset);
                end
            end
        else
            % direct mode waveform download
            for col = 1:size(channelMapping, 2) / 2
                for ch = find(channelMapping(:, 2*col-1))'
                    gen_arb_M8121A(arbConfig, f, ch, real(data(:,col)), marker1, segmNum, run, segmentLength, segmentOffset);
                end
                for ch = find(channelMapping(:, 2*col))'
                    gen_arb_M8121A(arbConfig, f, ch, imag(data(:,col)), marker2, segmNum, run, segmentLength, segmentOffset);
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
            doRun(f, arbConfig, useM8192A, channelMapping, run, keepOpen);
        end
    end
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end
end


function doRun(f, arbConfig, useM8192A, channelMapping, run, keepOpen)
    if (useM8192A)
        % don't do anything for the recursive call
        if (run == 1 && ~strcmp(arbConfig.visaAddr, arbConfig.visaAddr2))
            try
                arbSync = loadArbConfig();
                arbSync.visaAddr = arbSync.visaAddrM8192A;
                fsync = iqopen(arbSync);
                xfprintf(fsync, ':ABOR');
                xfprintf(fsync, ':inst:mmod:conf 1');
                xfprintf(fsync, ':inst:mast ""');
                xfprintf(fsync, ':inst:slave:del:all');
                xfprintf(fsync, sprintf(':inst:mast "%s"', arbConfig.visaAddr));
                xfprintf(fsync, sprintf(':inst:slave:add "%s"', arbConfig.visaAddr2));
                xfprintf(fsync, ':inst:mmod:conf 0');
                % for triggered mode, switch the Trace Advance back to AUTO
                if (isfield(arbConfig, 'triggerMode') && strcmp(arbConfig.triggerMode, 'Triggered'))
                    for i = find(channelMapping(:,1) + channelMapping(:,2))'
                        xfprintf(f, sprintf(':trace%d:adv auto', i));
                    end
                    arb2 = loadArbConfig();
                    arb2.visaAddr = arb2.visaAddr2;
                    f2 = iqopen(arb2);
                    for i = find(channelMapping(:,1) + channelMapping(:,2))'
                        xfprintf(f2, sprintf(':trace%d:adv auto', i));
                    end
                    fclose(f2);
                end
                xfprintf(fsync, ':init:imm');
                xfprintf(fsync, ':trig:beg');
                query(fsync, '*opc?');
                fclose(fsync);
            catch ex
                msgbox(ex.message);
            end
        end
    else
        % turn on channel coupling only if download to both channels
        % otherwise keep the previous setting. If the user wants de-coupled
        % channels, he has to do that in the SFP or outside this script
        if (length(find(channelMapping(:,1) + channelMapping(:,2))) > 1)
            xfprintf(f, ':INSTrument:COUPle:STATe ON');
        end
        if (run ~= 0)
            % setting ARB mode is now done in gen_arb function
            for i = find(channelMapping(:,1) + channelMapping(:,2))'
                xfprintf(f, sprintf(':INIT:IMMediate%d', i));
            end
        end
    end
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end
end


function gen_arb_M8121A(arbConfig, f, chan, data, marker, segm_num, run, segmentLength, segmentOffset)
% download an arbitrary waveform signal to a given channel and segment
    if (isempty(chan) || ~chan)
        return;
    end
    % file import is faster, but it only works if we are local
    if (~isempty(strfind(f.Name, 'localhost')))
        useFile = 1;
    else
        useFile = 0;
    end
    hMsgBox = [];
    segm_len = length(data);
    if (segm_len > 0)
        % switch to internal memory
        xfprintf(f, sprintf(':FUNCtion:MODE INT'));
        % Try to delete the segment, but ignore errors if it does not exist
        % Another approach would be to first find out if it exists and only
        % then delete it, but that takes much longer
        if (~useFile && run >= 0 && segmentOffset == 0)
            if (segmentLength > 4800)
                hMsgBox = waitbar(0, 'Transferring data, please wait...', 'Name', 'Transferring data, please wait...', 'CreateCancelBtn', 'setappdata(gcbf,''cancel'',1)');
                setappdata(hMsgBox, 'cancel', 0);
                drawnow();
            end
            xfprintf(f, sprintf(':TRACe%d:DELete %d', chan, segm_num), 1);
            xfprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segm_num, segmentLength));
        end
        % scale to DAC values - data is assumed to be -1 ... +1
        % set debugBits = n in MATLAB workspace for custom bits
        if (evalin('base', 'exist(''debugBits'', ''var'')'))
            bits = evalin('base','debugBits');
            data = int16(round((2^(bits)/2-1) * data) * 2^(16-bits));
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
        if (useFile)
            file = fullfile(iqScratchDir(), 'wfmtemp.bin');
            fid = fopen(file, 'w');
            if (~isempty(fid))
                fwrite(fid, data, 'int16');
                fclose(fid);
                xfprintf(f, sprintf(':TRAC%d:IMP %d, "%s", BIN', chan, segm_num, file));
            else
                errordlg(sprintf('can''t open %s', file));
            end
        else
            % swap MSB and LSB bytes in case of TCP/IP connection
            if (strcmp(f.type, 'tcpip'))
                data = swapbytes(data);
            end
            % Download the arbitrary waveform. 
            % Split large waveform segments in reasonable chunks
            use_binblockwrite = 1;
            offset = 0;
            tic;
            while (offset < segm_len)
                if (use_binblockwrite)
                    len = min(segm_len - offset, 9600);
                    cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset + segmentOffset);
                    xbinblockwrite(f, data(1+offset:offset+len), 'int16', cmd);
                    xfprintf(f, '');
                else
                    len = min(segm_len - offset, 4800);
                    cmd = sprintf(':TRACe%d:DATA %d,%d', chan, segm_num, offset + segmentOffset);
                    cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                    xfprintf(f, cmd);
                end
                offset = offset + len;
                t = toc;
                if (~isempty(hMsgBox))
                    waitbar(offset / segm_len, hMsgBox, sprintf('%.1f kSa, %.1f%%, %.1f sec, %.1f kSa/s', offset/1000, offset/segm_len*100, t, offset/1000/t));
                    drawnow();
                    if (~isempty(hMsgBox) && getappdata(hMsgBox, 'cancel'))
                        break;
                    end
                end
            end
        end
        query(f, '*opc?\n');
        if (run >= 0 && (segmentOffset + length(data) >= segmentLength))
            xfprintf(f, sprintf(':TRACe%d:SELect %d', chan, segm_num));
        end
        if (~isempty(hMsgBox))
            delete(hMsgBox);
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


function gen_arb_IQ_M8121A(arbConfig, f, chan, data, marker, segm_num, segmentLength, segmentOffset)
% download an IQ waveform to a given channel and segment number.
% Set the sampling rate to fs
    if (isempty(chan) || ~chan)
        return;
    end
    segm_len = length(data);
    if (segm_len > 0)
        % switch to internal memory
        xfprintf(f, sprintf(':FUNCtion:MODE INT'));
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
                len = min(segm_len - offset, 5120);
                cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset/2 + segmentOffset);
                xbinblockwrite(f, data(1+offset:offset+len), 'int16', cmd);
                xfprintf(f, '');
            else
                len = min(segm_len - offset, 5120);
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
%        xfprintf(f, sprintf(':FUNCtion%d:MODE ARBitrary', chan));
        xfprintf(f, sprintf(':OUTPut%d ON', chan));
    end
end



%-------------------------------------------------------------------------------------------

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
            errordlg({'M8121A firmware returns an error on command:' s 'Error Message:' result});
            if (evalin('base', 'exist(''debugScpi'', ''var'')'))
                fprintf('ERROR = %s\n', result);
            end
            result = query(f, ':syst:err?');
            retVal = -1;
        end
    end
end
