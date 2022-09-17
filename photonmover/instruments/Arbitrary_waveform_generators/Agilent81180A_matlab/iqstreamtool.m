function varargout = iqstreamtool(varargin)
% Perform Streaming operations using the Wideband Solution Platform
%
% Parameters are passed as property/value pairs. Properties are:
% 'arbConfig' - struct that contains instrument addresses
% 'cmd' - string that contains one of the commands
%         'Test Connection', 'Record', 'Playback'
% 'params' - struct with further parameters, depending on the cmd
%
% If called without arguments, opens a graphical user interface to specify
% parameters.
%
% Th.Dippon, Keysight Technologies 2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

%% parse arguments
global useVISA_Instrument;
global hMsgBox;
global logFct;
global time0;
useVISA_Instrument = (~isempty(which('VISA_Instrument')));
if (nargin == 0)
    iqstreamtool_gui;
    return;
end
varargout{1} = [];
% some default parameters
cmd = [];
arbConfig = [];
params = struct();
hMsgBox = [];
logFct = @(s) defaultLogFct(s);
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'arbconfig';    arbConfig = varargin{i+1};
            case 'cmd';          cmd = varargin{i+1};
            case 'params';       params = varargin{i+1};
            case 'logfct';       logFct = varargin{i+1};
            otherwise
                error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

arbConfig = loadArbConfig(arbConfig);
if (isempty(cmd))
    error('no cmd specified\n');
end

% create a process bar
hMsgBox = iqwaitbar('Please wait...');
try
    switch lower(cmd)
        case 'test connection'
            varargout{1} = testConnection(arbConfig);
        case 'record'
            varargout{1} = recordFromDigitizer(arbConfig, params);
        case 'playback'
            playbackRecording(arbConfig, params);
        case 'download'
            varargout{1} = downloadRecording(arbConfig, params);
        case 'upload'
            varargout{1} = uploadRecording(arbConfig, params);
        case 'delete'
            varargout{1} = deleteRecording(arbConfig, params);
        case 'getrecordings'
            varargout{1} = getRecordings(arbConfig, params);
        otherwise
            errordlg(sprintf('streamtool: cmd "%s" is not implemented', cmd));
    end
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
delete(hMsgBox);
    

function result = downloadRecording(arbConfig, params)
result = 0;
global logFct;
global hMsgBox;
recorder = [];
try
    recorder = openRecorder(arbConfig);
    if (isempty(recorder))
        return;
    end
    % check, if the recording exists
    found = true;
    for i = 1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            recordings = recorder{i}.Recordings;
            foundOnThisRecorder = false;
            for k = 0:recordings.Count-1
                name = recordings.Item(k).Name;
                if (strcmp(char(name), params.recordingName))
                    foundOnThisRecorder = true;
                    break;
                end
            end
            if (~foundOnThisRecorder)
                found = false;
                break;
            end
        end
        if (~found)
            break;
        end
    end
    if (~found)
        error(sprintf('recording "%s" not found on at least one recorder', params.recordingName));
    else
        if (~isempty(params.filename) && ~strcmp(params.filename, ''))
            fileCnt = 1;
            for i = 1:length(recorder)
                recCount = recorder{i}.GetRecorderCount();
                if recorder{i}.IsRecorderChained(); recCount = 1; end
                for j = 0:recCount-1
                    recorder{i}.SelectedRecorder(int32(j));
                    % always use numeric extension to denote recorder number
%                    if (length(recorder) > 1 || recCount > 1)
                        [path, base, ext] = fileparts(params.filename);
                        filename = fullfile(path, sprintf('%s_%d%s', base, fileCnt, ext));
                        fileCnt = fileCnt + 1;
%                     else
%                         filename = params.filename;
%                     end
                    pci = strncmpi(arbConfig.recorderConnectionType, 'PCI', 3);
                    if (pci)
                        % if we are connected through PCI, download the
                        % whole file in one chunk - this will guarantee
                        % best performance
                        % The API cannot overwrite a file
                        fileID = fopen(filename, 'r');
                        if (~isempty(fileID) && fileID > 0)
                            fclose(fileID);
                            delete(filename);
                        end
                        if (~isempty(hMsgBox))
                            if hMsgBox.canceling(); break; end
                            hMsgBox.update(0.2 + 0.2 * fileCnt, sprintf('downloading from recorder %d, please wait...', fileCnt-1));
                        end
                        recorder{i}.DownloadRecording(params.recordingName, filename);
                    else
                        fileID = fopen(filename, 'w');
                        if (isempty(fileID) || fileID <= 0)
                            error(sprintf('cannot open local file: "%s"', filename));
                        else
                            recorder{i}.OpenRecording(params.recordingName, true);  % true means: read
                            pktCount = recorder{i}.GetPacketCount(params.recordingName);
                            %logFct(sprintf('PacketCount in recording = %d', pktCount));
                            %pktSize = recorder{i}.GetPacketSize(params.recordingName);     % GetPacketSize does not work...
                            pktSize = 32000;
                            pkt1 = NET.createArray('System.Byte', pktSize);
                            for j = 1:pktCount
                                res = recorder{i}.ReadPacket(j, pkt1);
        %                        fprintf('ReadPacket #%d returns %d\n', j, res);
                                if (j < 10 || mod(j, 500) == 0)
                                    if (~isempty(hMsgBox))
                                        if hMsgBox.canceling(); break; end
                                        hMsgBox.update(0.1+0.9*(double(j)/double(pktCount)), sprintf('downloading from recorder %d, %.1f%% (%.3g GB)', fileCnt-1, 100*double(j)/double(pktCount), double(pktSize)/1e9*j));
                                    end
                                end
                                switch params.formatConversion
                                    case 'none'
                                        sig = uint8(pkt1);
                                        fmt = 'uint8';
                                    case 'swap endianness'
                                        sig = uint8(pkt1);
                                        sig2 = reshape(sig, 2, length(sig)/2);
                                        sig = reshape(flipud(sig2), length(sig), 1);
                                        fmt = 'uint8';
                                    case '10 bit packed -- 16 bit'
                                        sig = conv10b16b(uint8(pkt1));
                                        fmt = 'int16';
                                    case '12 bit packed -- 16 bit'
                                        sig = conv12b16b(uint8(pkt1));
                                        fmt = 'int16';
                                    otherwise
                                        error(sprintf('unknown format conversion %s', params.formatConversion));
                                end
                                res = fwrite(fileID, sig, fmt);
                                if (res ~= length(sig))
                                    error(sprintf('error writing to file (res=%d / len=%d)', res, length(sig)));
                                    break;
                                end
                            end
                            recorder{i}.CloseRecording();
                            fclose(fileID);
                        end % if fileID > 0
                    end
                end % for j=0:recCount-1
            end % for i=1:length(recorder)
        else % if isempty(param)
            error(sprintf('no local filename specified'));
        end
    end
    closeRecorder(recorder);
catch ex
    if (isprop(ex, 'stack'))
        msg = sprintf('%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line);
    else
        msg = ex.message;
    end
    errordlg(msg);
    for i = 1:length(recorder)
        if (recorder{i}.IsRecordingOpen())
            recorder{i}.CloseRecording();
        end
    end
    closeRecorder(recorder);
end


function result = uploadRecording(arbConfig, params)
result = 0;
recorder = [];
global hMsgBox;
currRecorder = [];
try
    if (~isempty(params.filename) && ~strcmp(params.filename, '') && exist(params.filename, 'file'))
        fileID = fopen(params.filename, 'r');
        if (fileID >= 0)
            recorder = openRecorder(arbConfig);
            if (isempty(recorder))
                return;
            end
            fileCnt = 1;
            for i = 1:length(recorder)
                currRecorder = recorder{i};
                recCount = currRecorder.GetRecorderCount();
                if currRecorder.IsRecorderChained(); recCount = 1; end
                for j = 0:recCount-1
                    currRecorder.SelectedRecorder(int32(j));
                    % check, if the recording exists
                    recs = currRecorder.Recordings;
                    found = false;
                    for k = 0:recs.Count-1
                        name = recs.Item(k).Name;
                        if (strcmp(char(name), params.recordingName))
                            found = true;
                            break;
                        end
                    end
                    if (found)
                        currRecorder.DeleteRecording(params.recordingName);
                    end
                    fseek(fileID, 0, 'eof');
                    fileLen = ftell(fileID);
                    fseek(fileID, 0, 'bof');
                    currRecorder.CreateRecording(params.recordingName, fileLen);
                    currRecorder.OpenRecording(params.recordingName, false);  % false means: write
                    pktSize = 32000;
                    %pkt1 = NET.createArray('System.Byte', pktSize);
                    buf = uint8(fread(fileID, pktSize));
                    pktCnt = 0;
                    while (buf ~= -1)
                        if (pktCnt < 10 || mod(pktCnt, 500) == 0)
                            if (~isempty(hMsgBox))
                                if (hMsgBox.canceling()); break; end
                                hMsgBox.update(0.2+0.8*(pktCnt*32000/fileLen), sprintf('uploading... recorder %d, %.2g%% (%.3g GB)', fileCnt, pktCnt*pktSize/fileLen*100, pktSize/1e9*pktCnt));
                            end
                        end
                        pkt = NET.convertArray(buf, 'System.Byte');
                        currRecorder.WritePacket(pkt, length(buf));
                        buf = uint8(fread(fileID, pktSize));
                        pktCnt = pktCnt + 1;
                    end
                    currRecorder.CloseRecording();
                    fileCnt = fileCnt + 1;
                end
            end
            fclose(fileID);
            closeRecorder(recorder);
        else
            error(sprintf('cannot open local file: "%s"', params.filename));
        end
    else
        error(sprintf('no local file specified or file does not exist'));
    end
catch ex
    if (isprop(ex, 'stack'))
        msg = sprintf('%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line);
    else
        msg = ex.message;
    end
    errordlg(msg);
    if (~isempty(currRecorder))
        if (currRecorder.IsRecordingOpen())
            currRecorder.CloseRecording();
        end
    end
    closeRecorder(recorder);
end


function result = deleteRecording(arbConfig, params)
result = 0;
recorder = [];
try
    recorder = openRecorder(arbConfig);
    if (isempty(recorder))
        return;
    end
    for i=1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            recorder{i}.DeleteRecording(params.recordingName);
        end
    end
    closeRecorder(recorder);
catch ex
    if (isprop(ex, 'stack'))
        msg = sprintf('%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line);
    else
        msg = ex.message;
    end
    errordlg(msg);
    closeRecorder(recorder);
end


function result = playbackRecording(arbConfig, params)
global logFct;
global hMsgBox;
awg = [];
recorder = [];
result = [];
try
    if (~checkAWGIsConfigured(arbConfig) || ~checkRecorderIsConfigured(arbConfig))
        return;
    end
    awg = openAWG(arbConfig);
    if (isempty(awg))
        return;
    end
    recorder = openRecorder(arbConfig);
    if (isempty(recorder))
        return;
    end
    if (length(recorder) > 2)
        msgbox('more than one parallel recorders are currently not supported for playback');
        closeRecorder(recorder);
        return;
    end
    if (length(recorder) ~= length(params.awgPort))
        msgbox('number of recorder channels does not match number of AWG channels');
        closeRecorder(recorder);
        return;
    end
    
    %--- check, if the recording is available
    for i = 1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            recs = recorder{i}.Recordings;
            found = false;
            for k = 0:recs.Count-1
                name = recs.Item(k).Name;
                if (strcmp(char(name), params.recordingName))
                    found = true;
                    break;
                end
            end
            if (~found)
                error(sprintf('recording "%s" not found on recorder %d/%d', params.recordingName, i, j));
            end
        end
    end
    
    if (~isempty(hMsgBox))
        if (hMsgBox.canceling()); error('user break'); end
        hMsgBox.update(0.1, sprintf('configure AWG and recorder'));
    end
    % find out if we have a one-channel or two channel instrument.
    try
        opts = xquery(awg, '*opt?');
    catch ex
        errordlg({'Can not communicate with M8121A Firmware. Please try again.'
            'If this does not solve the problem, exit and restart MATLAB and the M8190A firmware'
            ['(Error message: ' ex.message]});
        instrreset();
        rethrow(ex);
    end
    if (~isempty(strfind(opts, '001')))
        numChannels = 1;
    else
        numChannels = 2;
    end
    if (length(params.awgPort) > numChannels || min(params.awgPort) < 1 || max(params.awgPort) > numChannels)
        error('invalid AWG port(s) specified');
    end
    xfprintf(awg, sprintf(':ABORT'));
    xfprintf(awg, sprintf(':FUNC:MODE OPT'));
    % determine which version of the instrument we have and set parameters accordingly
    fs = params.awgSampleRate;
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
    cmd = sprintf(':FREQuency:RASTer %.15g;', fs);
    if ((isfield(arbConfig, 'extClk') && arbConfig.extClk))
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
    xfprintf(awg, cmd);
    idn = xquery(awg, '*IDN?');
    idnSplit = strsplit(idn, ',');
    if (idnSplit{4}(1) == '1')
        switch (strtrim(params.awgFormat))
            case 'Packed 12 bit';        fmt = 'RE12BITPACKED1CH';
            case 'Real 12 bit + marker'; fmt = 'RE12BIT1EVENT1CH';
            case 'Real 14 bit + marker'; fmt = 'RE14BIT1EVENT1CH';
            case 'I/Q 15 bit + marker';  fmt = 'IQ15BIT1EVENT1CH';
            otherwise; error(sprintf('unexpected AWG format: %s', params.awgFormat));
        end
    else
        switch (strtrim(params.awgFormat))
            case 'Packed 12 bit';        fmt = 'RE12BITPACKED1CH';
            case 'Real 12 bit + marker'; fmt = 'RE12BIT4EVENT1CH';
            case 'Real 14 bit + marker'; fmt = 'RE14BIT2EVENT1CH';
            case 'I/Q 15 bit + marker';  fmt = 'IQ15BIT1EVENT1CH';
            otherwise; error(sprintf('unexpected AWG format: %s', params.awgFormat));
        end
    end
    
    %--- activate port and consumer
    if (~isempty(hMsgBox))
        if (hMsgBox.canceling()); error('user break'); end
        hMsgBox.update(0.15, sprintf('synchronizing ODI link...'));
    end
    for i = 1:length(params.awgPort)
        xfprintf(awg, sprintf(':OUTP%d ON', params.awgPort(i)));
        xfprintf(awg, sprintf(':ODI:PORT%d:ACT R141, 2048, CONS, NONE, IBAN', params.awgPort(i)));
        xfprintf(awg, sprintf(':ODI:CONS%d:ACT -1, NHE, "%s"', params.awgPort(i), fmt));
    end
    
    %--- activate port on rapids
    for i = 1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            portName = recorder{i}.Odi.Ports.Name.Item(1);
            recorder{i}.Odi.Ports.Item(portName).Deactivate();  % this seems to be the only way to clear error status
            recorder{i}.Odi.Ports.Item(portName).Activate(Conduant.StreamStor3.LaneRate.RATE_14R1G, 2048, Conduant.StreamStor3.FlowControl.INBAND, []);
        end
    end
    
    %--- check sync
    for syncRetry = 3:-1:1
        synced = true;
        recidx = 1;
        for i = 1:length(recorder)
            recCount = recorder{i}.GetRecorderCount();
            if recorder{i}.IsRecorderChained(); recCount = 1; end
            for j = 0:recCount-1
                recorder{i}.SelectedRecorder(int32(j));
                portName = recorder{i}.Odi.Ports.Name.Item(1);
                statRapids = recorder{i}.Odi.Ports.Item(portName).GetStatus();
                logFct(sprintf('Recorder(%d) status: %08x (%s)', recidx, uint32(double(statRapids)), char(statRapids.ToString())));
                if (bitand(double(statRapids), 7) ~= 7)
                    synced = false;
                    break;
                end
                recidx = recidx + 1;
            end
            if (~synced)
                break;
            end
        end
        for awgIdx = 1:length(params.awgPort)
            statAWG = uint32(str2double(xquery(awg, sprintf(':ODI:PORT%d:CSTATUS?', params.awgPort(awgIdx)))));
            logFct(sprintf('AWG port %d status %08x', params.awgPort(awgIdx), statAWG));
            if (bitand(statAWG, 5) ~= 5)
                synced = false;
                break;
            end
        end
        if (synced)
            break;
        end
        pause(1);
    end
    if (~synced)
        error(sprintf('At least one ODI link NOT synchronized!\n(Status: AWG channel %d: %08x, recorder #%d: %08x)', ...
            params.awgPort(awgIdx), statAWG, recidx, uint32(double(statRapids))));
    end
    %--- start AWG in triggered mode
    pause(1); % add one second for safety
    if (~isempty(hMsgBox))
        if (hMsgBox.canceling()); error('user break'); end
        hMsgBox.update(0.17, sprintf('starting AWG...'));
    end
    % xfprintf(awg, sprintf(':INIT'));
    xfprintf(awg, sprintf(':INIT:IMM'));

    if (~isempty(hMsgBox))
        if (hMsgBox.canceling()); error('user break'); end
        hMsgBox.update(0.18, sprintf('starting playback...'));
    end
    
    %--- start playback
    numLoops = params.numLoops;
    fileSize = recorder{1}.GetLength(params.recordingName);
    for i = 1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            if (numLoops == 1)
                recorder{i}.Playback(params.recordingName);
            elseif (numLoops == 0)
                recorder{i}.Playloop(params.recordingName);
            else
                recorder{i}.Playloop(params.recordingName, numLoops);
            end
        end
    end
    playbackTime = numLoops * double(fileSize) / 2 / params.awgSampleRate;   % assume 16 bits per sample

    %--- trigger AWG
    if (~isempty(hMsgBox))
        if (hMsgBox.canceling()); error('user break'); end
        hMsgBox.update(0.19, sprintf('triggering AWG...'));
    end
    % don't check error status because version 1.x does not support this command
    xfprintf(awg, sprintf(':TRIG:BEG'), 1);

    %--- wait until playback is complete
    pause(1); % add one second for safety
    progress = 0;
    if (numLoops == 0)
        while true
            newProgress = recorder{1}.GetProgress();
            if (newProgress ~= 0)
                progress = newProgress;
            end
            if (~isempty(hMsgBox))
                if (hMsgBox.canceling()); break; end
                hMsgBox.update(mod(double(progress)/1e9, 100), sprintf('playback %.1f GB', double(progress)/1e9));
            end
            if (~recorder{1}.IsPlaying())
                break;
            end
            pause(1);
        end
    else
        for i = 0:ceil(playbackTime)
            newProgress = recorder{1}.GetProgress();
            if (newProgress ~= 0)
                progress = newProgress;
            end
            if (~isempty(hMsgBox))
                if (hMsgBox.canceling()); break; end
                hMsgBox.update(0.2+0.8*i/ceil(playbackTime), sprintf('playback %.1f%% (%.1f GB)', 100*i/playbackTime, double(progress)/1e9));
            end
            if (~recorder{1}.IsPlaying())
                break;
            end
            pause(1);
        end
    end
    %--- stop AWG and playback
    xfprintf(awg, ':ABORT');
    for i = 1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            recorder{i}.Stop();
        end
    end
%     for i = 1:length(params.awgPort)
%         xfprintf(awg, sprintf(':ODI:CONS%d:DEAC', params.awgPort(i)));       % AWG does not support this command 
%     end
    for i = 1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            portName = recorder{i}.Odi.Ports.Name.Item(1);
            recorder{i}.Odi.Ports.Item(portName).Deactivate();
        end
    end
%     for i = 1:length(params.awgPort)
%         xfprintf(awg, sprintf(':ODI:PORT%d:DEAC', params.awgPort(i)));       % AWG does not support this command 
%     end
    closeRecorder(recorder);
    fclose(awg);
catch ex
    if (isprop(ex, 'stack'))
        msg = sprintf('%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line);
    else
        msg = ex.message;
    end
    errordlg(msg);
    if (~isempty(awg))
        fclose(awg);
    end
    closeRecorder(recorder);
end


function result = recordFromDigitizer(arbConfig, params)
global useVISA_Instrument;
global logFct;
global hMsgBox;
global time0;
digitizer = [];
recorder = [];
result = [];
try
    if (~checkDigitizerIsConfigured(arbConfig) || ~checkRecorderIsConfigured(arbConfig))
        return;
    end
    digitizer = openDigitizer(arbConfig.visaAddrScope);
    if (isempty(digitizer))
        return;
    end
    recorder = openRecorder(arbConfig);
    if (isempty(recorder))
        return;
    end
    recCount = recorder{1}.GetRecorderCount();
    if recorder{1}.IsRecorderChained(); recCount = 1; end
    if (length(params.digPort) ~= (length(recorder) * recCount))
        result = 'number of digitizer ports does not match number of recorders';
        errordlg(result);
        closeRecorder(recorder);
        return;
    end
    for i = 1:length(recorder)
        portName{i} = recorder{i}.Odi.Ports.Name.Item(0);
    end
    if (~isempty(hMsgBox))
        if (hMsgBox.canceling()); error('user break'); end
        hMsgBox.update(0.1, sprintf('configure digitizer and recorder...'));
    end
    xfprintf(digitizer, sprintf(':SSTREAM'));
    xfprintf(digitizer, sprintf(':STOP'));
    if (~isempty(strfind(params.digMode, '16')))
        xfprintf(digitizer, sprintf(':ACQ:SRAT S16G'));
    else
        xfprintf(digitizer, sprintf(':ACQ:SRAT S32G'));
    end
    if (~isempty(strfind(params.digMode, 'DDC')))
        xfprintf(digitizer, sprintf(':DPR:MODE DDC'));
        xfprintf(digitizer, sprintf(':DPR:DDC:DEC POW%d', log2(params.digDDC)));
        portMask = 0;
        for i = 1:length(params.digPort)
            portMask = bitor(portMask, bitshift(1, params.digPort(i) - 1));
            xfprintf(digitizer, sprintf(':CHAN%d:DPR:DDC:CFR %g', params.digPort(i), params.digFc(mod(i-1,length(params.digFc))+1)));
        end
        if (params.digPhaseReset)
            xfprintf(digitizer, sprintf(':DPR:DDC:RESET %d', portMask));
        end
        dataRate = 16 / params.digDDC * 4;  % dataRate in GB/s (4 Byte per sample)
    else
        xfprintf(digitizer, sprintf(':DPR:MODE DIR'));
        xfprintf(digitizer, sprintf(':DPR:DIR:DEC POW%d', log2(params.digDDC)));
        if (params.digDDC == 1)
            dataRate = 20;                    % dataRate in GB/s  (10 bit per sample)
        else
            dataRate = 16 / params.digDDC * 2; % dataRate in GB/s  (16 bit per sample)
        end
    end
    if (hMsgBox.canceling()); error('user break'); end
    hMsgBox.update(0.1, sprintf('synchronizing ODI link...'));
    for i = 1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            recorder{i}.Odi.Ports.Item(portName{i}).Activate(Conduant.StreamStor3.LaneRate.RATE_14R1G, 2048, Conduant.StreamStor3.FlowControl.INBAND, []);
        end
    end
    for i = 1:length(params.digPort)
        xfprintf(digitizer, sprintf(':ODI:PORT%d:ACT R141, 2048, PROD, IBAN, IBAN, ""', params.digPort(i)));
    end
    %--- sync ODI
    for syncRetry = 3:-1:1
        synced = true;
        recidx = 1;
        for i = 1:length(recorder)
            recCount = recorder{i}.GetRecorderCount();
            if recorder{i}.IsRecorderChained(); recCount = 1; end
            for j = 0:recCount-1
                recorder{i}.SelectedRecorder(int32(j));
                statRapids = recorder{i}.Odi.Ports.Item(portName{i}).GetStatus();
                logFct(sprintf('Recorder(%d) status: %08x (%s)', recidx, uint32(double(statRapids)), char(statRapids.ToString())));
                recidx = recidx + 1;
                if (bitand(double(statRapids), 7) ~= 7)
                    synced = false;
                    break;
                end
            end
            if (~synced)
                break;
            end
        end
        for digIdx = 1:length(params.digPort)
            statDigitizer = uint32(str2double(xquery(digitizer, sprintf(':ODI:PORT%d:CSTATUS?', params.digPort(digIdx)))));
            logFct(sprintf('Digitizer port %d status %08x', params.digPort(digIdx), statDigitizer));
            if (bitand(statDigitizer, 7) ~= 7)
                synced = false;
                break;
            end
        end
        if (synced)
            break;
        end
        pause(1);
    end
    if (~synced)
        error(sprintf('At least one ODI link NOT synchronized!\n(Status: Digitizer channel %d: %08x, recorder #%d: %08x)', ...
            digIdx, statDigitizer, recidx, uint32(double(statRapids))));
    end
    if (hMsgBox.canceling()); error('user break'); end
    hMsgBox.update(0.15, sprintf('create recording...'));
    for i = 1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            recs = recorder{i}.Recordings;
            found = false;
            for k = 0:recs.Count-1
                name = recs.Item(k).Name;
                if (strcmp(char(name), params.recordingName))
                    found = true;
                    break;
                end
            end
            if (found)
                recorder{i}.DeleteRecording(params.recordingName);
            end
            recorder{i}.CreateRecording(params.recordingName, ceil(params.recordingLen * 1e9 / 2048000)*2048000);
            recorder{i}.Record(params.recordingName, false, 0);
        end
    end
    for i = 1:length(params.digPort)
        xfprintf(digitizer, sprintf(':ODI:PROD%d:ACT 0, NHE, IQ16B1CH, ODIC, NTIM, 1, 262144', params.digPort(i)));
    end
    xfprintf(digitizer, sprintf(':STReam'));
    
    %--- wait until recording is complete
    pause(1); % add one second for safety
    recordingTime = params.recordingLen / dataRate;  % GB divided by GB/s
    for i = 1:1 % length(recorder)
        for j = 0:ceil(recordingTime)
            progress = recorder{i}.GetProgress();
            if (hMsgBox.canceling()); error('user break'); end
            hMsgBox.update(0.2+0.8*(j/ceil(recordingTime)), sprintf('recording %d / %d sec (%.3g GB)', j, ceil(recordingTime), double(progress)/1e9));
            if (~recorder{i}.IsRecording())
                errordlg('recorder is no longer recording');
            end
            pause(1);
        end
    end
    
    %--- end recording
    logFct(sprintf('stop recording...'));
    xfprintf(digitizer, sprintf(':SSTREAM'));
    for i = 1:length(params.digPort)
        xfprintf(digitizer, sprintf(':ODI:PROD%d:DEAC', params.digPort(i)));
    end
    for i = 1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            recorder{i}.Stop();
        end
    end
    for i = 1:length(params.digPort)
        xfprintf(digitizer, sprintf(':ODI:PORT%d:DEAC', params.digPort(i)));
    end
    for i = 1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            recorder{i}.Odi.Ports.Item(portName{i}).Deactivate();
        end
    end
%     res = xquery(digitizer, sprintf(':DIAG:SYNC:TSTamp:VALue? CHAN%d', params.digPort(1)));
%     logFct(sprintf('timestamp chan%d = %s', params.digPort(1), res));
%     time1 = str2double(res);
%     if (exist('time0', 'var') && ~isempty(time0))
%         logFct(sprintf('time since last capture: %g seconds\n', (time1 - time0)/16e9 * params.digDDC * 16));
%     end
%     time0 = time1;

    if (useVISA_Instrument)
        digitizer.Close();
    else
        fclose(digitizer);
    end
    closeRecorder(recorder);
catch ex
    if (isprop(ex, 'stack'))
        result = sprintf('%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line);
    else
        result = ex.message;
    end
    errordlg(result);
    if (~isempty(digitizer))
        if (useVISA_Instrument)
            digitizer.Close();
        else
            fclose(digitizer);
        end
    end
    closeRecorder(recorder);
end


function listAll = getRecordings(arbConfig, ~)
global hMsgBox;
recorder = [];
listAll = cell(0,0);
try
    recorder = openRecorder(arbConfig);
    if (isempty(recorder))
        return;
    end
    hMsgBox.update(0.5, 'reading list of recordings...');
    fileCnt = 1;
    for i=1:length(recorder)
        recCount = recorder{i}.GetRecorderCount();
        if recorder{i}.IsRecorderChained(); recCount = 1; end
        for j = 0:recCount-1
            recorder{i}.SelectedRecorder(int32(j));
            recs = recorder{i}.Recordings;
            listPerRec = struct();
            for k = 1:recs.Count
                name = char(recs.Item(k-1).Name);
                listPerRec(k).name = name;
                listPerRec(k).length = recorder{1}.GetLength(name);
                listPerRec(k).fileLength = recorder{1}.GetRecordingFileSize(name);
                listPerRec(k).packetCount = recorder{1}.GetPacketCount(name);
            end
            listAll{fileCnt} = listPerRec;
            fileCnt = fileCnt + 1;
        end
    end
    closeRecorder(recorder);
catch ex
    if (isprop(ex, 'stack'))
        msg = sprintf('%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line);
    else
        msg = ex.message;
    end
    errordlg(msg);
    closeRecorder(recorder);
end


function res = testConnection(arbConfig)
% try to open a connection to the recorder
% return 1 if successful, 0 if not
recorder = openRecorder(arbConfig);
if (isempty(recorder))
    res = 0;
else
    str = '';
    for i = 1:length(recorder)
        rec = recorder{i};
        apiVersion = char(rec.GetAPIVersion());
        fwVersion = char(rec.GetFirmwareVersion());
        recCount = rec.GetRecorderCount();
        chained = rec.IsRecorderChained();
        grouped = rec.IsRecorderGrouped();
        groupCnt = rec.GetRecorderGroupCount();
        str = sprintf('%sServer #%d, API %s, FW %s, Number of Recorders %d, chained %d\n', ...
            str, i, apiVersion, fwVersion, recCount, chained);
        for j = 0:recCount-1
            rec.SelectedRecorder(int32(j));
            totalCap = rec.GetTotalCapacity();
            freeCap = rec.GetFreeCapacity();
            str = sprintf('%s  Recorder #%d: Total %.0f GB, Free %.0f GB\n', str, j, totalCap/1e9, freeCap/1e9);
        end
        rec.SelectedRecorder(int32(0));
    end
    msgbox(str);
    closeRecorder(recorder);
    res = 1;
end


function recorder = openRecorder(arbConfig)
% Open the connection to a Recorder or set of Recorders
% Address is given in arbConfig.recorderConnectionType (PCIe or LAN)
% and arbConfig.recorderAddr (IP_addr or IP_addr:Port resp.
% PCIe_index or PCIe_module:PCIe_index)
% If successful a handle to the recorder is returned.
% If not, an error dialog is displayed and an empty value is returned
global hMsgBox;
recorder = cell(0,0);
try
    pci = strncmpi(arbConfig.recorderConnectionType, 'PCI', 3);
    if (pci)
        addr = arbConfig.recorderPCIAddr;
    else
        addr = arbConfig.recorderAddr;
    end
    hMsgBox.update(0.05, sprintf('open recorder on %s / %s', arbConfig.recorderConnectionType, addr));
    if (~loadSSAPI())
        return;
    end
    import Conduant.StreamStor3.*;
    try
        recorder = evalin('base', 'recorder');
        recorder.IsReady;
    catch
        recorder = cell(0,0);
    end
    if (isempty(recorder))
        if (pci)
            [addr, rem] = strtok(arbConfig.recorderPCIAddr, ' ,;\t');
            [res, cnt] = sscanf(addr, '%d:%d');
            switch cnt
                case 0; errordlg('Recorder address must be PCI_MODULE or PCI_MODULE:PCI_INDEX');
                case 1; recorder{1} = cOdiRecorder(1, res(1));
                case 2; recorder{1} = cOdiRecorder(res(2), res(1));
            end
            [res, cnt] = sscanf(rem, '%d:%d');
            switch cnt
                case 0 % only one recorder
                case 1; recorder{2} = cOdiRecorder(1, res(1));
                case 2; recorder{2} = cOdiRecorder(res(2), res(1));
            end
        else
            ip_addr = arbConfig.recorderAddr;
            port = arbConfig.recorderPorts;
            range = 1:length(port);
            for i = range
                if (strcmp(ip_addr, ''))
                    errordlg('Recorder address not specified');
                    break;
                else
                    try
                        % assign to tmp variable because it might create an exception
                        hMsgBox.update(0.1);
                        recTmp = cOdiRecorder(ip_addr, port(i));
                        hMsgBox.update(0.2);
                        recorder{i} = recTmp;
                    catch ex
                        if (isprop(ex, 'stack'))
                            errordlg(sprintf('%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line));
                        end
                        if (isa(ex, 'NET.NetException'))
                            errordlg(sprintf('%s\n%s', ex.message, char(ex.ExceptionObject.StackTrace)));
                        end
                        closeRecorder(recorder)
                        recorder = cell(0,0);
                    end
                end
            end
        end
        % store recorder in MATLAB workspace - just in case it is not properly closed
        assignin('base', 'recorder', recorder);
    end
catch ex
    if (isprop(ex, 'stack'))
        errordlg(sprintf('%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line));
    end
    if (isa(ex, 'NET.NetException'))
        errordlg(sprintf('%s\n%s', ex.message, char(ex.ExceptionObject.StackTrace)));
    end
end


function found = loadSSAPI()
% load ssapi3.dll
found = 0;
if isdeployed % Stand-alone mode
    [~, result] = system('path');
    mypath = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
else % MATLAB mode
    mypath = fullfile(fileparts(which('iqstreamtool')), 'Interfaces');
end
pwdpath = fullfile(pwd, 'Interfaces');
pathlist = { ...
    mypath ...
    pwdpath ...
    };
asmName = 'ssapi3.dll';
for i = 1:length(pathlist)
    fullAsmName = fullfile(pathlist{i}, asmName);
    if (exist(fullAsmName, 'file'))
        try
            asm = NET.addAssembly(fullAsmName);
            found = 1;
            break;  % if execution is at this point, we found the DLLs
        catch ex
            errordlg(sprintf('Error loading VSA Interface DLL\n%s\n%s', fullAsmName, ex.message));
        end
    end
end
if (~found)
    errordlg([{'Can''t find ' asmName ' in any of the following directories:' ' '} pathlist]);
    return;
end


function closeRecorder(recorder)
if (~isempty(recorder))
    for i = 1:length(recorder)
         recorder{i}.Close();
         recorder{i}.Dispose();
    end
    assignin('base', 'recorder', cell(0,0));
end


function awg = openAWG(arbConfig)
global hMsgBox;
if (~checkAWGIsConfigured(arbConfig))
    return;
end
if (~isempty(hMsgBox))
    hMsgBox.update(0.05, sprintf('open AWG on %s', arbConfig.visaAddr));
end
awg = iqopen(arbConfig);
if (isempty(awg))
    return;
end
res = xquery(awg, '*IDN?');
if (isempty(strfind(res, 'M8121A')))
    errordlg(sprintf('This utility only works with an M8121A.\n*IDN returns: %s', strtrim(res)));
    fclose(awg);
    awg = [];
end
return;


function digitizer = openDigitizer(visaAddr)
global useVISA_Instrument;
global hMsgBox;
if (~isempty(hMsgBox))
    hMsgBox.update(0.05, sprintf('open digitizer on %s', visaAddr));
end
if (useVISA_Instrument)
    digitizer = VISA_Instrument(visaAddr);
else
    digitizer = iqopen(visaAddr);
end
if (isempty(digitizer))
    return;
end
res = xquery(digitizer, '*IDN?');
if (isempty(strfind(res, 'M8131A')))
    errordlg(sprintf('This utility works only with an M8131A.\n*IDN returns: %s', strtrim(res)));
    if (useVISA_Instrument)
        digitizer.Close();
    else
        fclose(digitizer);
    end
    digitizer = [];
end
return;


function res = checkRecorderIsConfigured(arbConfig)
if (~exist('arbConfig', 'var') || isempty(arbConfig))
    arbConfig = loadArbConfig();
end
if (~isfield(arbConfig, 'isRecorderConnected') || arbConfig.isRecorderConnected == 0)
    errordlg('No Recorder is configured. Please go to the "Instrument Configuration" window, and set up the address of a Recorder');
    res = 0;
else
    res = 1;
end


function res = checkDigitizerIsConfigured(arbConfig)
if (~exist('arbConfig', 'var') || isempty(arbConfig))
    arbConfig = loadArbConfig();
end
if (~isfield(arbConfig, 'isScopeConnected') || arbConfig.isScopeConnected == 0)
    errordlg('No Digitizer is configured. Please go to the "Instrument Configuration" window, and set up the address of an M8131A under "Oscilloscope"');
    res = 0;
else
    res = 1;
end


function res = checkAWGIsConfigured(arbConfig)
if (~exist('arbConfig', 'var') || isempty(arbConfig))
    arbConfig = loadArbConfig();
end
if (~isfield(arbConfig, 'visaAddr') || isempty(arbConfig.visaAddr))
    errordlg('No AWG is configured. Please set up an M8121A in the "Instrument Configuration" window');
    res = 0;
else
    if (~isempty(strfind(arbConfig.model, 'M8121A')))
        res = 1;
    else
        res = 0;
        errordlg('This utility only works with an M8121A. Please configure an M8121A in the "Instrument Configuration" window');
    end
end


function c = conv10b16b(a)
l = length(a);
if (mod(l,5) ~= 0)
    error('length of input waveform must be a multiple of 5');
end
b = reshape(int16(a), 5, l/5);
b(1,:) = bitshift(b(1,:), 2) + bitand(bitshift(b(2,:), -6), 3);
b(2,:) = bitshift(bitand(b(2,:), 63), 4) + bitand(bitshift(b(3,:), -4), 15);
b(3,:) = bitshift(bitand(b(3,:), 15), 6) + bitand(bitshift(b(4,:), -2), 63);
b(4,:) = bitshift(bitand(b(4,:), 3), 8) + b(5,:);
b(5,:) = [];
c = b(:);
idx = (c > 511);
c(idx) = c(idx) - 1024;



function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, -1 for errors
global useVISA_Instrument;
retVal = 0;
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    fprintf('%s\n', s);
end
if (useVISA_Instrument)
    f.Write(s);
else
    fprintf(f, s);
end
rptErr = 0;
while rptErr < 50
    if (useVISA_Instrument)
        result = f.QueryString(':syst:err?');
    else
        result = query(f, ':syst:err?');
    end
    if (isempty(result))
        if (useVISA_Instrument)
            f.Close();
        else
            fclose(f);
        end
        errordlg(sprintf(['The instrument at %s did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'], f.Name), 'Error');
        retVal = -1;
        return;
    end
    if (strncmp(result, '0', 1) || strncmp(result, '+0', 2))
        break;
    elseif (~exist('ignoreError', 'var') || ignoreError == 0)
        fprintf('ERROR: %s -> %s\n', s, strtrim(result));
        errordlg({'Instrument returns an error on command:' s 'Error Message:' strtrim(result)}, 'Error', 'replace');
        retVal = -1;
    end
    rptErr = rptErr + 1;
end


function retVal = xquery(f, s)
% send a query to the instrument object f
global useVISA_Instrument;
if (useVISA_Instrument)
    retVal = f.QueryString(s);
else
    retVal = query(f, s);
end
% set debugScpi=1 in MATLAB workspace to log SCPI commands
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    if (length(retVal) > 60)
        rstr = sprintf('%s... (total %d chars)', retVal(1:60), length(retVal));
    else
        rstr = retVal;
    end
    fprintf('%s -> %s\n', s, strtrim(rstr));
end


function defaultLogFct(s)
fprintf('%s\n', s);




