function result = iqdownload_M8195A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, chMap, sequence, run, segmentLength, segmentOffset)
% Download a waveform to the M8195A
% It is NOT intended that this function be called directly, only via iqdownload
%
% T.Dippon, Keysight Technologies 2015-2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS.

result = [];
% set default values for segmentLength and segmentOffset
if (isempty(segmentLength))
    segmentLength = length(data);
end
if (isempty(segmentOffset))
    segmentOffset = 0;
end

% find out if sync module is used (Note: for legacy reasons, the field name is "useM8192A"
useM8197A = isfield(arbConfig, 'useM8192A') && (arbConfig.useM8192A ~= 0);

% if called with more than 4/8/12 channels, send data to additional M8195A's
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
    if (size(chMap, 1) > 4*(m-1) && isfield(arbConfig, va)) % && max(max(chMap(4*(m-1)+1:min(4*m,size(chMap,1)),:))) > 0)
        arbTmp = arbConfig;
        arbTmp.visaAddr = arbTmp.(va);
        arbTmp.setupSlave = useM8197A;  % mark calls to slave modules
        if (~isempty(ampTmp))
            arbTmp.amplitude = ampTmp(4*(m-1)+1:min(4*m,size(chMap,1)));
        end
        if (~isempty(offTmp))
            arbTmp.offset = offTmp(4*(m-1)+1:min(4*m,size(chMap,1)));
        end
        result = iqdownload_M8195A(arbTmp, fs, data, marker1, marker2, segmNum, keepOpen, chMap(4*(m-1)+1:min(4*m,size(chMap,1)),:), sequence, run, segmentLength, segmentOffset);
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

% treat sequence setup completely separate from waveform download
if (~isempty(sequence))
    result = setupSequence(f, arbConfig, sequence, chMap, run, 0, keepOpen);
else
    
    % stop the generator - unless we are in the middle of a multi-segment download
    if (segmentOffset == 0)
        % Stop the sync module
        if (useM8197A)
            try
%                 arbSync = loadArbConfig();
%                 arbSync.visaAddr = arbConfig.visaAddrM8192A;
                fsync = iqopen(arbConfig.visaAddrM8192A);
                xfprintf(fsync, ':ABOR');
                xfprintf(fsync, ':INST:MMOD:CONF 1');
                xfprintf(fsync, ':INST:SLAVE:DEL:ALL');
                query(fsync, '*OPC?');
                fclose(fsync);
            catch ex
                msgbox(ex.message);
                return;
            end
        else
            if (run >= 0)
                if (xfprintf(f, sprintf(':ABORt')) ~= 0)
                    % if ABORT does not work, let's not try anything else...
                    % we will probably get many other errors
                    return;
                end
            end
        end
    end
    
    % perform instrument reset if it is selected in the configuration
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        if (sum(sum(chMap)) > 0 && (isempty(find(chMap(:,1), 1)) || isempty(find(chMap(:,2), 1))))
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
        if (xfprintf(f, '*RST') ~= 0)
            return;
        end
    end
    
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
    % make sure we have 4 rows in the channelmapping array
    if (size(chMap, 1) < 4)
        chMap(4,:) = zeros(1, size(chMap, 2));
    end
    
    % be graceful with one/two-channel instruments and don't attempt
    % to access channels that are not available (to avoid a flood of error
    % messages)
    if (~isempty(strfind(opts, '002')) || ~isempty(strfind(opts, 'R12')))
        if (strcmp(arbConfig.model, 'M8195A_2ch_mrk'))
            chMap(3,:) = zeros(1,size(chMap, 2));
            chMap(4,:) = zeros(1,size(chMap, 2));
        else
            chMap(2,:) = zeros(1,size(chMap, 2));
            chMap(3,:) = zeros(1,size(chMap, 2));
        end
    end
    if (~isempty(strfind(opts, '001')))
        chMap(2,:) = zeros(1,size(chMap, 2));
        chMap(3,:) = zeros(1,size(chMap, 2));
        chMap(4,:) = zeros(1,size(chMap, 2));
    end
    
    if (segmentOffset == 0)
        %dacMode = xquery(f, ':INST:DACM?');
        switch (arbConfig.model)
            case {'M8195A_1ch' 'M8195A_1ch_mrk'}
                chMap(2,:) = zeros(1,size(chMap, 2));
                chMap(3,:) = zeros(1,size(chMap, 2));
                chMap(4,:) = zeros(1,size(chMap, 2));
                fsDivider = 1;
                xfprintf(f, sprintf(':INST:DACM MARK;:TRAC1:MMOD EXT;:INST:MEM:EXT:RDIV DIV%d', fsDivider));
                xfprintf(f, ':OUTP3 ON;:OUTP4 ON');
            case 'M8195A_2ch'
                chMap(2,:) = zeros(1,size(chMap, 2));
                chMap(3,:) = zeros(1,size(chMap, 2));
                fsDivider = 2;
                xfprintf(f, sprintf(':INST:DACM DUAL;:TRAC1:MMOD EXT;:TRAC4:MMOD EXT;:INST:MEM:EXT:RDIV DIV%d', fsDivider));
            case 'M8195A_2ch_mrk'
                chMap(3,:) = zeros(1,size(chMap, 2));
                chMap(4,:) = zeros(1,size(chMap, 2));
                fsDivider = 2;
                xfprintf(f, sprintf(':INST:DACM DCM;:TRAC1:MMOD EXT;:TRAC2:MMOD EXT;:INST:MEM:EXT:RDIV DIV%d', fsDivider));
                xfprintf(f, ':OUTP3 ON;:OUTP4 ON');
            case 'M8195A_4ch'
                fsDivider = 4;
                xfprintf(f, sprintf(':INST:DACM FOUR;:TRAC1:MMOD EXT;:TRAC2:MMOD EXT;:TRAC3:MMOD EXT;:TRAC4:MMOD EXT;:INST:MEM:EXT:RDIV DIV%d', fsDivider));
            case 'M8195A_4ch_256k'
                fsDivider = 1;
                xfprintf(f, sprintf(':INST:DACM FOUR;:TRAC1:MMOD INT;:TRAC2:MMOD INT;:TRAC3:MMOD INT;:TRAC4:MMOD INT;:INST:MEM:EXT:RDIV DIV%d', fsDivider));
            case 'M8195A_2ch_256k'
                chMap(2,:) = zeros(1,size(chMap, 2));
                chMap(3,:) = zeros(1,size(chMap, 2));
                fsDivider = 1;
                xfprintf(f, sprintf(':INST:DACM DUAL;:TRAC1:MMOD INT;:TRAC4:MMOD INT;:INST:MEM:EXT:RDIV DIV%d', fsDivider));
            otherwise
                error(sprintf('unexpected arb model: %s', arbConfig.model));
        end
    end
    
    % set frequency
    if (fs ~= 0 && segmentOffset == 0)
        cmd = '';
        if (isfield(arbConfig, 'clockSource'))
            switch (arbConfig.clockSource)
                case 'Unchanged'
                    % nothing to do
                case 'IntRef'
                    cmd = sprintf(':ROSC:SOURce INT; ');
                case 'AxieRef'
                    cmd = sprintf(':ROSC:SOURce AXI; ');
                case 'ExtRef'
                    cmd = sprintf(':ROSC:SOURce EXT; :ROSC:FREQuency %.15g; ', arbConfig.clockFreq);
                case 'ExtClk'
                    errordlg('External sample clock is not supported for M8195A');
                    error('External sample clock is not supported for M8195A');
                otherwise error(['unexpected clockSource in arbConfig: ', arbConfig.clockSource]);
            end
        end
        xfprintf(f, sprintf('%s:FREQuency:RASTer %.15g;', cmd, fs * fsDivider));

        % apply skew if necessary
        if (isfield(arbConfig, 'skew') && arbConfig.skew ~= 0)
            data = iqdelay(data, fs, arbConfig.skew);
        end

        % set trigger mode
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
        if (contMode >= 0)
            xfprintf(f, sprintf(':INIT:CONT %d;GATE %d', contMode, gateMode));
        end
    end
    
    % don't load any data or run if fs == 0
    if (fs > 0)
        % direct mode waveform download
        for col = 1:min(size(chMap, 2) / 2, size(data,2))
            for ch = find(chMap(:, 2*col-1))'
                gen_arb_M8195A(arbConfig, f, ch, real(data(:,col)), marker1, segmNum, run, fs, segmentLength, segmentOffset);
            end
            for ch = find(chMap(:, 2*col))'
                gen_arb_M8195A(arbConfig, f, ch, imag(data(:,col)), marker2, segmNum, run, fs, segmentLength, segmentOffset);
            end
        end

        % call :INIT:IMM only if (a) the run flag is set, (b) we downloaded a waveform and 
        % (c) the waveform reaches to the end of the segment
        if (run ~= 0 && segmentOffset + length(data) >= segmentLength)
            xfprintf(f, sprintf(':FUNCtion:MODE ARBitrary'));
            doRun(f, arbConfig, useM8197A, chMap, run, keepOpen);
        end
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
                xfprintf(fsync, ':ABORT');
                xfprintf(fsync, ':INST:MMOD:CONF 1');
                xfprintf(fsync, ':INST:SLAVE:DEL:ALL');
                xfprintf(fsync, sprintf(':INST:SLAVE:ADD "%s"', arbConfig.visaAddr));
                for m = 2:4
                    va = sprintf('visaAddr%d', m);
                    if (isfield(arbConfig, va))
                        xfprintf(fsync, sprintf(':INST:SLAVE:ADD "%s"', arbConfig.(va)));
                    end
                end
                if (xfprintf(fsync, ':INST:MMOD:CONF 0'))
                    fclose(fsync);
                    return
                end
                xfprintf(fsync, ':INIT:IMM');
                xquery(fsync, '*OPC?');
                fclose(fsync);
            catch ex
                msgbox(ex.message);
            end
        end
    else
        if (run ~= 0)
            xfprintf(f, sprintf(':INIT:IMM'));
        end
    end
end


function gen_arb_M8195A(arbConfig, f, chan, data, marker, segm_num, run, fs, segmentLength, segmentOffset)
% download an arbitrary waveform signal to a given channel and segment
if (isempty(chan) || chan < 1 || chan > 4)
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
    dataSize = 'int8';
    data = int8(round(127 * data));
    % in case of 1 or 2 channel with marker mode, need to load 16 bit values
    if (strcmp(arbConfig.model, 'M8195A_1ch') || ...
        (strcmp(arbConfig.model, 'M8195A_2ch_mrk') && chan == 1))
        if (length(marker) ~= length(data))
            errordlg('length of marker vector and data vector must be the same');
            marker = zeros(size(data));
        end
        dataSize = 'int16';
        data = int16(data);
        data = bitand(data,255);
        data = data + int16(256 * marker);
        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end
    end
    % Download the arbitrary waveform.
    % Split large waveform segments in reasonable chunks
    use_binblockwrite = 1;
    offset = 0;
    while (offset < segm_len)
        if (use_binblockwrite)
            len = min(segm_len - offset, 512000);
            cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset + segmentOffset);
            xbinblockwrite(f, data(1+offset:offset+len), dataSize, cmd);
        else
            len = min(segm_len - offset, 5120);
            cmd = sprintf(':TRACe%d:DATA %d,%d', chan, segm_num, offset + segmentOffset);
            cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
            xfprintf(f, cmd);
        end
        offset = offset + len;
    end
    xquery(f, '*OPC?\n');
    if (run >= 0 && (segmentOffset + length(data) >= segmentLength))
        xfprintf(f, sprintf(':TRACe%d:SELect %d', chan, segm_num));
    end
end
if (segmentOffset + length(data) >= segmentLength)
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
end


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, numel(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
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
        end
        xfprintf(f, sprintf(':STABle:RESET'));
    case 'event'
        xfprintf(f, ':TRIGger:ADVance:IMMediate');
    case 'trigger'
        xfprintf(f, ':TRIGger:BEGin:IMMediate');
    case 'define'
        defineSequence(f, seqcmd, channelMapping, run);
        xfprintf(f, sprintf(':STAB:SCEN:ADV CONDitional'));
        doRun(f, arbConfig, useM8192A, channelMapping, run, keepOpen);
    case 'dynamic'
        xfprintf(f, sprintf(':ABORt'));
        xfprintf(f, sprintf(':STABle:DYNamic %d', seqcmd.sequence));
    case 'mode'
        xfprintf(f, sprintf(':ABORt'));
        xfprintf(f, sprintf(':FUNCtion:MODE %s', seqcmd.sequence));
        if (strncmpi(seqcmd.sequence, 'STSC', 4) && isfield(arbConfig, 'triggerMode') && strcmp(arbConfig.triggerMode, 'Triggered'))
            xfprintf(f, sprintf(':STAB:SCEN:ADV AUTO'));
        else
            xfprintf(f, sprintf(':STAB:SCEN:ADV COND'));
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
        xfprintf(f, sprintf(':INIT:CONT %s', s));
        xfprintf(f, sprintf(':INIT:GATE %s', s));
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
fields(strcmp(fields, 'segmentNumber')) = [];
fields(strcmp(fields, 'segmentLoops')) = [];
fields(strcmp(fields, 'segmentAdvance')) = [];
fields(strcmp(fields, 'sequenceAdvance')) = [];
fields(strcmp(fields, 'sequenceLoops')) = [];
fields(strcmp(fields, 'markerEnable')) = [];
fields(strcmp(fields, 'sequenceInit')) = [];
fields(strcmp(fields, 'sequenceEnd')) = [];
fields(strcmp(fields, 'scenarioEnd')) = [];
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
xbinblockwrite(f, seqData, 'uint32', sprintf(':STABle:DATA 0,'));
xfprintf(f, '');
%            cmd = sprintf(',%.0f', seqData);
%            xfprintf(f, sprintf(':STABle:DATA 0%s', cmd));
xfprintf(f, sprintf(':STABle:SEQuence:SELect %d', 0));
xfprintf(f, sprintf(':STABle:DYNamic:STATe 0'));
xfprintf(f, sprintf(':FUNCtion:MODE STSequence'));
end


function seqTabEntry = calculateSeqTableEntry(seqline, currLine, numLines)
% calculate the six 32-bit words that make up one sequence table entry.
% For details on the format, see user guide section 4.20.6
%
% The content of the six 32-bit words depends on the type of entry:
% Data Entry: Control / Seq.Loops / Segm.Loops / Segm.ID / Start Offset / End Offset
% Idle Cmd:   Control / Seq.Loops / Cmd Code(0) / Idle Sample / Delay / Unused
cbitCmd = 32;
cbitEndSequence = 31;
cbitEndScenario = 30;
cbitInitSequence = 29;
cbitMarkerEnable = 25;
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
    % normal data entries have the segment loop count in word#3
    if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops))
        seqTabEntry(3) = seqline.segmentLoops;
    else
        seqTabEntry(3) = 1;
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
start = 0;
len = 200;  % maximum number of entries to read
xfprintf(f, ':ABORt');
stab = query(f, sprintf(':STAB:DATA? %d,%d', start, 6*len));
stab = eval(sprintf('[%s]', stab));
stab(stab < 0) = stab(stab < 0) + 2^32;
stab = uint32(stab);
for i = 1:length(stab)/6
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

% initialize result struct.  Order is important!!
result.idx = [];
result.segmentNumber = [];
result.segmentLoops = [];
result.segmentAdvance = [];
result.markerEnable = [];
result.sequenceInit = [];
result.sequenceLoops = [];
result.sequenceAdvance = [];
result.sequenceEnd = [];
result.scenarioEnd = [];

cbitCmd = 32;
cbitEndSequence = 31;
cbitEndScenario = 30;
cbitInitSequence = 29;
cbitMarkerEnable = 25;
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
    fprintf('%s - %s %s, %d elements\n', f.Name, cmd, format, length(data));
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
    fprintf('%s - %s -> %s\n', f.Name, s, strtrim(rstr));
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
    fprintf('%s - %s\n', f.Name, s);
%    fprintf('cmd = %s\n', s);
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
            errordlg({'M8195A firmware returns an error on command:' s 'Error Message:' result});
            retVal = -1;
        end
        rptErr = rptErr + 1;   % make sure we don't loop forever
    end
end
end
