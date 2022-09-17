function result = iqdownload_M8195A_Rev1(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run)
% Download a waveform to the M8195A
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
    if (~isempty(sequence))
        errordlg('Sorry, M8195A_Rev1 does not have a sequencer');
        return;
    end

    % open the VISA connection
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    result = f;
    
    % find out if we have a two-channel or four-channel instrument
    try
        opts = xquery(f, '*opt?');
    catch ex
        errordlg({'Can not communicate with M8195A Firmware. Please try again.'
            'If this does not solve the problem, exit and restart MATLAB'
            ['(Error message: ' ex.message]});
        instrreset();
        return;
    end
    % be graceful with one/two-channel instruments and don't attempt
    % to access channels that are not available (to avoid a flood of error
    % messages)
    if (size(channelMapping, 1) < 4)
        channelMapping(4,:) = [0 0];
    end
    dacMode = xquery(f, ':INST:DACM?');
    if (~isempty(strfind(opts, '002')) || ~isempty(strfind(opts, 'R12')))
        channelMapping(2,:) = [0 0];
        channelMapping(3,:) = [0 0];
    end
    if (~isempty(strfind(opts, '001')))
        channelMapping(2,:) = [0 0];
        channelMapping(3,:) = [0 0];
        channelMapping(4,:) = [0 0];
    end
    if (~isempty(strfind(opts, '004')) || ~isempty(strfind(opts, 'R14')))
        if (~isempty(find(channelMapping(2:3,:), 1)) && (~isempty(strfind(dacMode, 'DUAL')) || ~isempty(strfind(dacMode, 'SING'))))
            xfprintf(f, ':INST:DACM FOUR');
        elseif (~isempty(find(channelMapping(4,:), 1)) && ~isempty(strfind(dacMode, 'SING')))
            xfprintf(f, ':INST:DACM DUAL');
        end
    end
    
    % perform instrument reset if it is selected in the configuration
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        if (isempty(find(channelMapping(:,1), 1)) || isempty(find(channelMapping(:,2), 1)))
            warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                     'waveform to only one channel. This will delete the waveform on the' ...
                     'other channel. If you want to keep the previous waveform, please' ...
                     'un-check the "send *RST" checkbox in the Configuration window.'});
        elseif (segmNum ~= 1)
            warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                     'waveform to segment number greater than 1. This will delete all other' ...
                     'waveform segments. If you want to keep the previous waveform, please' ...
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
        xfprintf(f, sprintf(':FREQuency:RASTer %.15g;', fs));
    end
    
    % apply skew if necessary
    if (isfield(arbConfig, 'skew') && arbConfig.skew ~= 0)
        data = iqdelay(data, fs, arbConfig.skew);
    end

    % direct mode waveform download
    for ch = find(channelMapping(:,1))'
        gen_arb_M8195A(arbConfig, f, ch, real(data), marker1, segmNum, run, fs);
    end
    for ch = find(channelMapping(:,2))'
        gen_arb_M8195A(arbConfig, f, ch, imag(data), marker2, segmNum, run, fs);
    end
    
    if (run == 1 && sum(sum(channelMapping)) ~= 0)
        xfprintf(f, ':INIT:IMMediate');
%        for i = find(channelMapping(:,1) + channelMapping(:,2))'
%            xfprintf(f, sprintf(':INIT:IMMediate%d', i));
%        end
    end
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end;
end


function gen_arb_M8195A(arbConfig, f, chan, data, marker, segm_num, run, fs)
% download an arbitrary waveform signal to a given channel and segment
    if (isempty(chan) || ~chan)
        return;
    end
    
    if (isfield(arbConfig, 'M8195Acorrection') && arbConfig.M8195Acorrection ~= 0)
%        figure(30);
%        if (chan == 1)
%            clf;
%            hold off;
%        else
%            hold on;
%        end
        a = xquery(f, sprintf(':CHAR%d?', chan));
        v = sscanf(strrep(strrep(a, '"', ''), ',', ' '), '%g');
        v = reshape(v, 3, length(v)/3)';
        freq = v(:,1);
        cplxCorr = v(:,2) .* exp(j * v(:,3));
        col = 'kgbrcmyg';
%        plot(freq/1e9, (v(:,3)/pi/2)./freq*1e12, [col(chan) '-'], 'LineWidth', 2);
%        xlabel('Frequency (GHz)');
%        ylabel('Skew (ps)');
%        grid on;
        cplxCorr = 1 ./ cplxCorr;
        % if we don't have negative frequencies, mirror them
        if (min(freq) >= 0)
            if (freq(1) == 0)            % don't duplicate zero-frequency
                startIdx = 2;
            else
                startIdx = 1;
            end
            freq = [-1 * flipud(freq); freq(startIdx:end)];
            cplxCorr = [conj(flipud(cplxCorr)); cplxCorr(startIdx:end)]; % negative side must use complex conjugate
        end
        fdata = fftshift(fft(data));
        points = length(fdata);
        newFreq = linspace(-0.5, 0.5-1/points, points) * fs;
        % interpolate the correction curve to match the data
        corrLin = interp1(freq, cplxCorr, newFreq, 'pchip', 1);
        % apply the correction and convert back to time domain
        % (it seems that corrLin is sometimes a row, sometimes a column...)
        try
            data2 = ifft(fftshift(fdata .* corrLin));
        catch
            try
                data2 = ifft(fftshift(fdata .* (corrLin.')));
            catch
                errordlg('error in FFT');
            end
        end
        data2 = real(data2);
        scale = max(abs(data2));
        if (scale > 1)
            data2(data2 > 1) = 1;
            data2(data2 < -1) = -1;
            msgbox(sprintf('DAC values on channel %d were clipped due to freq/phase response correction. Please reduce DAC range to %d%% to avoid clipping', chan, floor(100/scale)));
        end
        data = data2;
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
%        if (~isempty(marker))
%            if (length(marker) ~= length(data))
%                errordlg('length of marker vector and data vector must be the same');
%            else
%                data = data + int16(bitand(uint16(marker), 3));
%            end
%        end
        % Download the arbitrary waveform. 
        % Split large waveform segments in reasonable chunks
        use_binblockwrite = 1;
        offset = 0;
        while (offset < segm_len)
            if (use_binblockwrite)
                len = min(segm_len - offset, 523200);
                cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset);
                xbinblockwrite(f, data(1+offset:offset+len), 'int8', cmd);
            else
                len = min(segm_len - offset, 4800);
                cmd = sprintf(':TRACe%d:DATA %d,%d', chan, segm_num, offset);
                cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                xfprintf(f, cmd);
            end
            offset = offset + len;
        end
        xquery(f, '*opc?');
    end
    if (isfield(arbConfig,'amplitude'))
        if (size(arbConfig.amplitude, 2) < 4)
            arbConfig.amplitude = repmat(arbConfig.amplitude, 1, 2);
        end
        xfprintf(f, sprintf(':VOLTage%d:AMPLitude %g', chan, arbConfig.amplitude(chan)));
    end
    if (isfield(arbConfig,'offset'))
        if (size(arbConfig.offset, 2) < 4)
            arbConfig.offset = repmat(arbConfig.offset, 1, 2);
        end
        xfprintf(f, sprintf(':VOLTage%d:OFFSet %g', chan, arbConfig.offset(chan)));    
    end
    xfprintf(f, sprintf(':OUTPut%d ON', chan));
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
        errordlg({'The M8195A firmware did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'}, 'Error');
        retVal = -1;
        return;
    end
    if (~exist('ignoreError', 'var') || ignoreError == 0)
        while (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
            errordlg({'M8195A firmware returns an error on command:' s 'Error Message:' result});
            result = query(f, ':syst:err?');
            retVal = -1;
        end
    end
end
