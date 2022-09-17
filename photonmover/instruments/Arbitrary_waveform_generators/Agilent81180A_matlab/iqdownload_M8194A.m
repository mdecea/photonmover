function result = iqdownload_M8194A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, chMap, sequence, run)
% Download a waveform to the M8194A
% It is NOT intended that this function be called directly, only via iqdownload
%
% T.Dippon, Keysight Technologies 2018
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    result = [];
    if (~isempty(sequence))
        errordlg('Sorry, M8194A does not have a sequencer');
        return;
    end
    
    % if called with more than 4/8/12 channels, send data to additional M8194A's
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
    isSyncMaster = 0;
    for m = 4:-1:2
        va = sprintf('visaAddr%d', m);
        if (size(chMap, 1) > 4*(m-1) && isfield(arbConfig, va))
            isSyncMaster = 1;
            arbTmp = arbConfig;
            arbTmp.visaAddrMaster = arbTmp.visaAddr;  % remember the visa address of the master module
            arbTmp.visaAddr = arbTmp.(va);
            arbTmp.setupSlave = 1;  % mark calls to slave modules
            if (~isempty(ampTmp))
                arbTmp.amplitude = ampTmp(4*(m-1)+1:min(4*m,size(chMap,1)));
            end
            if (~isempty(offTmp))
                arbTmp.offset = offTmp(4*(m-1)+1:min(4*m,size(chMap,1)));
            end
            result = iqdownload_M8194A(arbTmp, fs, data, marker1, marker2, segmNum, keepOpen, chMap(4*(m-1)+1:min(4*m,size(chMap,1)),:), sequence, run);
        end
    end
    % don't try to download more than 4 channels in first module
    chMap(5:end,:) = [];

    % open the VISA connection
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    result = f;
    
    % stop waveform output
    if (run >= 0)
        if (isfield(arbConfig, 'setupSlave'))
            try
                fsync = iqopen(arbConfig.visaAddrMaster);
                xfprintf(fsync, ':ABOR');
% in the M8194A we can download new waveforms without switching to Config
% Mode. However, if we are about to send a *RST, switch to config mode and
% remove the slave(s)
                if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
                    xfprintf(fsync, ':INST:MMOD:CONF 1');
                    xfprintf(fsync, ':INST:SLAVE:DEL:ALL');
                end
                query(fsync, '*OPC?');
                fclose(fsync);
            catch ex
                msgbox(ex.message);
                return;
            end
        else
            if (xfprintf(f, sprintf(':ABOR')) ~= 0)
                % if ABORT does not work, let's not try anything else...
                % we will probably get many other errors
                return;
            end
        end
    end
    
    % perform instrument reset if it is selected in the configuration
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst && ~isfield(arbConfig, 'setupSlave'))
        if (fs > 0 && sum(sum(chMap)) > 0 && (isempty(find(chMap(:,1), 1)) || isempty(find(chMap(:,2), 1))))
            warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                     'waveform to only one channel. This will delete the waveform on the' ...
                     'other channels. If you want to keep the previous waveform, please' ...
                     'un-check the "send *RST" checkbox in the Configuration window.'});
        end
        xfprintf(f, '*RST');
    end
    
    % find out if we have a two-channel or four-channel instrument
    try
        opts = xquery(f, '*opt?');
    catch ex
        errordlg({'Can not communicate with M8194A Firmware. Please try again.'
            'If this does not solve the problem, exit and restart MATLAB'
            ['(Error message: ' ex.message]});
        instrreset();
        return;
    end
    
    % make sure we have 4 rows in the channelmapping array
    if (size(chMap, 1) < 4)
        chMap(4,:) = zeros(1, size(chMap, 2));
    end
    
% for testing purposes: simulate an Option 001 instrument
%    opts = '001';

    % be graceful with one/two-channel instruments and don't attempt
    % to access channels that are not available (to avoid a flood of error
    % messages)
    dacMode = xquery(f, ':INST:DACM?');
    % extend the channel mapping to 4 channels
    if (size(chMap, 1) < 4)
        chMap(4,:) = zeros(1,size(chMap, 2));
    end
    % if it is a two channel instrument, don't attempt to load channels 3 & 4
    if (~isempty(strfind(opts, '002')))
        xfprintf(f, ':INST:DACM DCMARKER', 1);
        chMap(3,:) = zeros(1,size(chMap, 2));
        chMap(4,:) = zeros(1,size(chMap, 2));
    end
    % if it is a one channel instrument, don't attempt to load channels 2, 3 & 4
    if (~isempty(strfind(opts, '001')))
        xfprintf(f, ':INST:DACM MARKER', 1);
        chMap(2,:) = zeros(1,size(chMap, 2));
        chMap(3,:) = zeros(1,size(chMap, 2));
        chMap(4,:) = zeros(1,size(chMap, 2));
    end
    % if it is a 4-channel instrument then
    % - if we have data to load in channels 2 or 3 and we are in 1-ch or 2-ch mode, switch to 4-ch mode
    % - if we have data to load in channel 4 and we are in 1-ch mode, switch to 4-ch mode
    if (~isempty(strfind(opts, '004')))
        if (~isempty(find(chMap(2:3,:), 1)))
            xfprintf(f, ':INST:DACM FOUR');
        elseif (~isempty(find(chMap(4,:), 1)) && ~isempty(strfind(dacMode, 'SING')))
            xfprintf(f, ':INST:DACM DUAL');
        end
    end
    
    % set frequency only when about to run, and not for slave modules
    oldFs = fs;
    if (run > 0 && fs ~= 0 && ~isfield(arbConfig, 'setupSlave'))
        oldFs = str2double(xquery(f, ':FREQ:RASTer?'));
        cmd = '';
        if (isfield(arbConfig, 'clockSource'))
            switch (arbConfig.clockSource)
                case 'Unchanged'
                    % nothing to do
                case 'IntRef'
                    cmd = sprintf(':ROSC:SOURce INT; ');
                case 'AxieRef'
                    errordlg('AXIe reference clock is not supported for M8194A');
                    error('AXIe reference clock is not supported for M8194A');
                case 'ExtRef'
                    cmd = sprintf(':ROSC:SOURce EXT; :ROSC:FREQuency %.15g; ', arbConfig.clockFreq);
                case 'ExtClk'
                    errordlg('External sample clock is not supported for M8194A');
                    error('External sample clock is not supported for M8194A');
                otherwise
                    error(['unexpected clockSource in arbConfig: ', arbConfig.clockSource]);
            end
        end
        if (fs >= arbConfig.minimumSampleRate(1))
            range = 'HIGH';
        elseif (fs >= arbConfig.minimumSampleRate(2))
            range = 'MED';
        else
            range = 'LOW';
        end
        % frequency change requires config mode
        if (isSyncMaster && fs ~= oldFs)
            xfprintf(f, ':INST:MMOD:CONF 1');
        end
        xfprintf(f, sprintf('%s:FREQ:RANG %s; :FREQuency:RASTer %.15g;', cmd, range, fs));
    end
    
    % apply skew if necessary
    if (isfield(arbConfig, 'skew') && arbConfig.skew ~= 0)
        data = iqdelay(data, fs, arbConfig.skew);
    end

    % don't load any data or run if fs == 0
    if (fs > 0)
        % direct mode waveform download
        for col = 1:min(size(chMap, 2) / 2, size(data,2))
            for ch = find(chMap(:, 2*col-1))'
                gen_arb_M8194A(arbConfig, f, ch, real(data(:,col)), marker1, segmNum, run);
            end
            for ch = find(chMap(:, 2*col))'
                gen_arb_M8194A(arbConfig, f, ch, imag(data(:,col)), marker2, segmNum, run);
            end
        end
        if (fs > 0 && run > 0)
            doRun(f, arbConfig, isSyncMaster, chMap, fs, oldFs);
        end
    end
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end
end

%
%  if isSyncMaster: add slaves
%  if master or standAlone: run
%
function doRun(f, arbConfig, isSyncMaster, chMap, fs, oldFs)
    if (isSyncMaster)
        slaves = xquery(f, ':INST:SLAV:LIST?');
        for m = 2:4
            va = sprintf('visaAddr%d', m);
            % try to add slave only if it is not already in the list
            if (isfield(arbConfig, va) && isempty(strfind(slaves, arbConfig.(va))))
                % try to delete it - it could be set to NONE
                xfprintf(f, sprintf(':INST:SLAVE:DEL "%s"', arbConfig.(va)), 1);
                % now add it, but ignore errors
                if (xfprintf(f, sprintf(':INST:SLAVE:ADD "%s"', arbConfig.(va)), 1))
% ignore errors because we did not remove slaves
%                    return;
                end
            end
        end
        if (xfprintf(f, ':INST:MMOD:CONF 0'))
            return;
        end
    end

    if (~isfield(arbConfig, 'setupSlave'))
        % check, if sample rate was changed.  This can take very long...
        if (fs ~= oldFs)
%            fprintf('new fs = %g GHz, old fs = %g GHz\n', fs/1e9, oldFs/1e9);
            f.Timeout = 90;
            tm = timer('TimerFcn', @timerFcn, 'StopFcn', @stopFcn, ...
                'Period', 1, 'TasksToExecute', 30, 'ExecutionMode', 'fixedRate');
            tm.UserData = waitbar(0, sprintf('Changing the sample rate on the M8194A\ncan take some time. Please be patient...'));
            start(tm);
        end
        xquery(f, '*ESR?'); % clear event status register
        if (isSyncMaster)
            if (xfprintf(f, ':INIT:IMM; *OPC'))
                return;
            end
        else
            if (xfprintf(f, ':INIT:ASYN; *OPC'))
                return;
            end
        end
        cnt = 90;
        while (cnt > 0)
            res = str2double(xquery(f, '*ESR?'));
%            fprintf('cnt = %d, ESR = %d\n', cnt, res);
            if (bitand(res,1) == 1)
                break;
            end
            pause(1);
            cnt = cnt - 1;
        end
        try
            stop(tm);
        catch
        end
    end
end


function stopFcn(obj,~)
  if (isvalid(obj.UserData))
      delete(obj.UserData);
  end
  delete(obj);
end

function timerFcn(obj,~)
  if (isvalid(obj.UserData))
      waitbar(obj.TasksExecuted/obj.TasksToExecute, obj.UserData);
  else
      stop(obj);
  end
end

function gen_arb_M8194A(arbConfig, f, chan, data, marker, segm_num, run)
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
            if (xfprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segm_num, segm_len)) ~= 0)
                return;
            end
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
                xfprintf(f, sprintf(':OUTP3 ON;:OUTP4 ON'));
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
        fprintf('%s - cmd = %s %s, %d elements\n', f.Name, cmd, format, length(data));
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
        fprintf('%s - qry = %s -> %s\n', f.Name, s, strtrim(rstr));
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
        fprintf('%s - cmd = %s\n', f.Name, s);
    end
    fprintf(f, s);
    rptErr = 0;
    while rptErr < 50
        result = query(f, ':syst:err?');
        if (isempty(result))
            fclose(f);
            errordlg(sprintf(['The instrument at %s did not respond to a :SYST:ERRor query.' ...
                'Please check that the firmware is running and responding to commands.'], f.Name), 'Error');
            retVal = -1;
            return;
        end
        if (strncmp(result, '0', 1))
            break;
        else
            if (evalin('base', 'exist(''debugScpi'', ''var'')'))
                fprintf('%s - %s: %s\n', f.Name, s, result);
            end
            if (~exist('ignoreError', 'var') || ignoreError == 0)
                errordlg({'M8194A firmware returns an error on command:' s 'Error Message:' result});
                retVal = -1;
            end
            rptErr = rptErr + 1;   % make sure we don't loop forever
        end
    end
end
