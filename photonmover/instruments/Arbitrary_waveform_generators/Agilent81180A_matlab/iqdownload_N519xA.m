function f = iqdownload_N519xA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, amplitude, fCenter, segmName, segmentLength, segmentOffset)
% Download IQ to N5194A
% Ver 1.1, Robin Wang, Feb 2013
% Ver 2.0, Thomas Wychock, Aug 2017

    % Open the arbconfig file
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end

    if (~isempty(sequence))
        errordlg('Sequence mode is not available for the Keysight VSG');
        f = [];
        return;
    end

    % Segment lengths involved in offset based downloads, if none set to
    % current data
    if(~exist('segmentLength', 'var') || isempty(segmentLength))
        segmentLength = numel(data);
    end

    % If there's a segment offset, set the current name of the arbconfig file
    if(~exist('segmentOffset','var') || isempty(segmentOffset))
        segmentOffset = 0;
    elseif segmentOffset > 0
        segmName = arbConfig.arbfilename;
    end

    % Walt Schulte added 10/11 to set visa object user data to the N5194A arb
    % used for download
    f.UserData = arbConfig.model;

    if ((strcmp(arbConfig.connectionType, 'visa')) || (strcmp(arbConfig.connectionType, 'tcpip')))
        f.ByteOrder = 'bigEndian';
    else
        f.ByteOrder = 'littleEndian';
    end

    % Do a reset if commanded to
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        xfprintf(f, '*RST');
    end

    % prompt the user for center frequency and power
    % defaults are the current settings
    % added a conditional for scripting
    if ((isempty(amplitude) || isempty(fCenter) || isempty(segmName)) && segmentOffset == 0)
        fCenter      = query(f, ':freq? ');
        amplitude    = query(f, ':power?');
        segmName     = sprintf('IQTools%04d', segmNum); % filename for the data in the ARB
        prompt       = {'Amplitude of Signal (dBm):', 'Carrier Frequency (Hz): ', 'Segment Name: '};
        defaultVal   = {iqengprintf(eval(amplitude)), iqengprintf(eval(fCenter)), sprintf(segmName)};
        dlg_title    = 'Inputs for VSG';
        user_vals    = inputdlg(prompt, dlg_title, 1, defaultVal);
        drawnow;

        if (isempty(user_vals))
            return;
        end

        if (isempty(user_vals{1})) && (isempty(user_vals{2}))
            amplitude = 0;
            fCenter   = 1e9;
            warndlg('The amplitude is set to 0 dBm, and carrier frequency to 1 GHz')
        else
            amplitude = user_vals{1};
            fCenter   = user_vals{2};
        end

        if (isempty(user_vals{1})) && ~(isempty(user_vals{2}))
            amplitude = 0;
            warndlg('The amplitude is set to 0 dBm')
        else     
            amplitude = user_vals{1};
        end

        if ~(isempty(user_vals{1})) && (isempty(user_vals{2}))
            fCenter = 1e9;    
            warndlg('Carrier frequency is set to 1 GHz')
        else
            fCenter = user_vals{2};
        end

        if (isempty(user_vals{3}))
            segmName  = sprintf('IQTools%04d', segmNum);
        else     
            segmName  = user_vals{3};
        end
    else
        fCenter      = query(f, ':freq? ');
        amplitude    = query(f, ':power?');
        segmName     = arbConfig.arbfilename;
    end

    if ((strcmp(arbConfig.model, 'N5194A_250MHz')) || (strcmp(arbConfig.model, 'N5194A_2GHz')))
        downloadSignal(f, data.', segmName, marker1, marker2,...
            segmentLength, segmentOffset, fCenter, amplitude,...
            arbConfig.LOIPAddr);
    else
        downloadSignal(f, data.', segmName, marker1, marker2,...
            segmentLength, segmentOffset, fCenter, amplitude);
    end

    % Update latest filename for batch downloads
    arbCfgFile = iqarbConfigFilename();
    open(arbCfgFile);
    arbConfig.arbfilename = segmName;

    if(exist('saConfig', 'var'))
        save(arbCfgFile, 'arbConfig', 'saConfig');
    else
        save(arbCfgFile, 'arbConfig');
    end

    % Only run the output if not doing a batch download
    if (isempty(segmentLength) || segmentOffset + length(data) >= segmentLength)
        doRun(f, segmName, fs, fCenter, amplitude, arbConfig.DACRange, 1);
    end

    if (~keepOpen)
        fclose(f);delete(f); 
    end

end


function downloadSignal(deviceObject, IQData, ArbFileName,...
    marker1, marker2, segmentLength, segmentOffset,...,
    centerFrequency, outputPower, varargin)
% This function downloads IQ Data to the signal generator's non-volatile memory

    if ~isvector(IQData)
        error('downloadWaveform: invalidInput');
    else
        IQsize = size(IQData); %WBS: if Wideband vector UXG, needs to be > 800 samples
        % User gave input as column vector. Reshape it to row vector.
        if ~isequal(IQsize(1),1)
            IQData = reshape(IQData,1,IQsize(1));
        end
    end
    
        % Some settings commands to make sure we don't damage the instrument
    % Assume we only do these on segment offset == 0
    if segmentOffset == 0   
        
        % Clear error queue
        deviceObject.Timeout = 60;
        xfprintf(deviceObject,'*CLS');
        
        xfprintf(deviceObject,':OUTPut:STATe OFF');
        xfprintf(deviceObject,':SOURce:RADio:ARB:STATe OFF');
        xfprintf(deviceObject,':OUTPut:MODulation:STATe OFF');
        
        % set center frequency (Hz)
        xfprintf(deviceObject, [':SOURce:FREQuency ' num2str(centerFrequency)]); %WBS: turns LO RF off 
        % set output power (dBm)
        xfprintf(deviceObject, ['POWer ' num2str(outputPower)]);

        % “[:SOURce]:FREQuency:LO:SOURce INTernal|EXTernal”
        % initialize SCPI control of LO
        % SCPI: “[:SOURce]:FREQuency:LO:CONTrol:SCPI:INITialize ON|OFF|1|0”
        %
        if strcmp(deviceObject.UserData, 'N5194A_250MHz')  
            % WBS: change to mode ARB
            % See if the mode is the one we will pick.
            % If so, skip the mode state, and if not, wait until set up
            setAndWait(deviceObject, ':INST:SEL?', 'VECT', ':INST:SEL VECT');

            % See if the mode is the one we will pick.
            % If so, skip the mode state, and if not, wait until set up
            setAndWait(deviceObject, ':FREQuency:LO:SOURce?', 'EXT', ':FREQuency:LO:SOURce EXTernal');

            % Set the LO state accordingly
            lOControl(deviceObject, varargin{1})   
        elseif (strcmp(deviceObject.UserData, 'N5194A_2GHz'))
            % WBS: change to mode ARB
            % See if the mode is the one we will pick.
            % If so, skip the mode state, and if not, wait until set up   
            setAndWait(deviceObject, ':INST:SEL?', 'WVEC', ':INST:SEL WVEC');

            % See if the mode is the one we will pick.
            % If so, skip the mode state, and if not, wait until set up   
            setAndWait(deviceObject, ':FREQuency:LO:SOURce?', 'EXT', ':FREQuency:LO:SOURce EXTernal');

            % Set the LO state accordingly
            lOControl(deviceObject, varargin{1})
 
        elseif strcmp(deviceObject.UserData, 'N5194A_250MHz_In')  
            % WBS: change to mode ARB
            % See if the mode is the one we will pick.
            % If so, skip the mode state, and if not, wait until set up
            setAndWait(deviceObject, ':INST:SEL?', 'VECT', ':INST:SEL VECT');

            % See if the mode is the one we will pick.
            % If so, skip the mode state, and if not, wait until set up
            setAndWait(deviceObject, ':FREQuency:LO:SOURce?', 'INT', ':FREQuency:LO:SOURce INTernal');
        else
        end
    end

    %% Download signal
    % Seperate out the real and imaginary data in the IQ Waveform
    wave = [real(IQData);imag(IQData)];
    wave = wave(:)';    % transpose the waveform

    % Scale the waveform if necessary
    tmp = max(abs([max(wave) min(wave)]));
    
    % Only scale if one waveform is being downloaded and not portions
    % Otherwise scaling will make EVMs worse
    if (tmp == 0 || numel(IQData) < segmentLength)
        tmp = 1;
    end

    % ARB binary range is 2's Compliment -32768 to + 32767
    % So scale the waveform to +/- 32767 not 32768
    scale  = 2^15-1;
    scale  = scale/tmp;
    wave   = round(wave * scale);
    modval = 2^16;
    % Get data from double to unsigned int
    wave = uint16(mod(modval + wave, modval));

    % IQ Data
    % Check the chunksize and if it's larger than the buffer and if so download
    % in chunks
    threshold = 2000000;

    % If over in terms of the chunksize, break into and download smaller pieces
    if numel(wave) > threshold

        % Get number of samples
        numSamples = numel(wave);

        % Write the first chunk, if it's an offset just assume we're starting
        % from last point we left off as the SCPI command set can only append
        if(segmentOffset > 0)
            binblockwrite(deviceObject,wave(1:threshold),'uint16',[':MEMory:DATA:APPend "WFM1:' ArbFileName '", ']);
            fprintf(deviceObject,'\n'); 
        else
            binblockwrite(deviceObject,wave(1:threshold),'uint16',[':MEMory:DATA "WFM1:' ArbFileName '", ']);
            fprintf(deviceObject,'\n'); 
        end

        % Update chunk
        chunkIdx = threshold + 1;
        chunkEnd = chunkIdx + threshold;

        % Keep chunking until we reach number of samples
        while chunkEnd <= numSamples
            binblockwrite(deviceObject,wave(chunkIdx:chunkEnd),'uint16',[':MEMory:DATA:APPend "WFM1:' ArbFileName '", ']);
            fprintf(deviceObject,'\n');     

            chunkIdx = chunkIdx + threshold + 1;
            chunkEnd = chunkIdx + threshold;

            if (isempty(segmentLength) || segmentOffset + length(IQData) >= segmentLength)
                disp(['Waveform Download: ' num2str(chunkIdx/numSamples*100) ' percent complete'])        
            end            
        end

        % Write the last portion of the waveform
        binblockwrite(deviceObject,wave(chunkIdx:numSamples),'uint16',[':MEMory:DATA:APPend "WFM1:' ArbFileName '", ']);
        fprintf(deviceObject,'\n'); 

    else
        % Just send one portion of the waveform    
        if(segmentOffset > 0)
            binblockwrite(deviceObject,wave,'uint16',[':MEMory:DATA:APPend "WFM1:' ArbFileName '", ']);
            fprintf(deviceObject,'\n');
        else
            binblockwrite(deviceObject,wave,'uint16',[':MEMory:DATA "WFM1:' ArbFileName '", ']);
            fprintf(deviceObject,'\n');
        end
    end

    if (isempty(segmentLength) || segmentOffset + length(IQData) >= segmentLength)
        disp('Waveform Download Complete')
    end
    
    % Create marker file
    if (~isempty(marker1) || ~isempty(marker2))

        % Marker 1, track the signal
        if (~isempty(marker1))
            %Normalize
            marker1 = marker1/(max(marker1));
        else
            marker1 = zeros(length(wave));
        end

        % Marker 2, invert to the signal
        if (~isempty(marker2))
            % Normalize
            marker2 = uint16(2*(~(marker2/(max(marker2)))));
        else
            marker2 = zeros(length(wave));
        end

        marker = uint8(marker1+marker2);

        % Marker Data
        numMarkers = numel(marker);
        if numMarkers > threshold
            % numSamples = numel(marker);

            % Write the first chunk, if it's an offset just assume we're starting
            % from last point we left off as the SCPI command set can only append
            if(segmentOffset > 0)
%                 binblockwrite(deviceObject,marker(1:threshold),'uint8',[':MEMory:DATA:APPend "MKR1:' ArbFileName '", ']);
%                 fprintf(deviceObject,'\n');
            else
                % xfprintf(deviceObject, [':MMEMory:DELete "MKR1:' ArbFileName '"']);
                binblockwrite(deviceObject,marker(1:threshold),'uint8',[':MEMory:DATA "MKR1:' ArbFileName '", ']);
                fprintf(deviceObject,'\n');     
            end

            % WYCHOCK: FW Fix for Marker append, until then just download
            % first batch
%             %Update chunk
%             chunkIdx = threshold + 1;
%             chunkEnd = chunkIdx + threshold;
% 
%             %Keep chunking until we reach the chunk count
%             while chunkEnd <= numMarkers
%                 binblockwrite(deviceObject,marker(chunkIdx:chunkEnd),'uint8',[':MEMory:DATA:APPend "MKR1:' ArbFileName '", ']);
%                 fprintf(deviceObject,'\n');     
% 
%                 chunkIdx = chunkIdx + threshold + 1;
%                 chunkEnd = chunkIdx + threshold;
% 
%                 if (isempty(segmentLength) || segmentOffset + length(IQData) >= segmentLength)
%                     disp(['Marker Download: ' num2str(chunkIdx/numMarkers*100) ' percent complete'])        
%                 end            
%             end
% 
%             %Write last portion
%             binblockwrite(deviceObject,marker(chunkIdx:numMarkers),'uint8',[':MEMory:DATA:APPend "MKR1:' ArbFileName '", ']);
%             fprintf(deviceObject,'\n'); 

        else
            % Just write the data once        
            if(segmentOffset > 0)
%                 binblockwrite(deviceObject,marker,'uint8',[':MEMory:DATA:APPend "MKR1:' ArbFileName '", ']);
%                 fprintf(deviceObject,'\n');
            else
                binblockwrite(deviceObject,marker,'uint8',[':MEMory:DATA "MKR1:' ArbFileName '", ']);
                fprintf(deviceObject,'\n');
            end

        end

        if (isempty(segmentLength) || segmentOffset + length(IQData) >= segmentLength)
            disp('Marker Download Complete')         
        end               
    end
    
    % Local Mode
    xfprintf(deviceObject, 'SYST:COMM:GTL');

end

function doRun(deviceObject, ArbFileName, sampleRate, centerFrequency, outputPower, scalingFactor, run)
% This function plays the signal

    if run ~= 0
        % Set the scaling to Scaling range
        xfprintf(deviceObject, [':SOURce:RADio:ARB:RSCaling ' num2str(scalingFactor*100)]);

        % Set the sample rate (Hz) for the signal.
        % You can get this info for the standard signals by looking at the data in the 'waveforms' variable
        xfprintf(deviceObject,[':SOURce:RADio:ARB:SCLock:RATE ' num2str(sampleRate)]); %WBS: no sample clock feature for N5194A W-ARB
        % set center frequency (Hz)
        xfprintf(deviceObject, [':SOURce:FREQuency ' num2str(centerFrequency)]); %WBS: turns LO RF off 
        % set output power (dBm)
        xfprintf(deviceObject, ['POWer ' num2str(outputPower)]);

        % Play back the selected waveform 
        xfprintf(deviceObject, [':SOURce:RAD:ARB:WAV "WFM1:' ArbFileName '"']);%wbs: command still valid for 250 MHz arb
        %WBS: could be fprintf(deviceObject, [':SOURce:RAD:WARB:WAV "WFM1:'
        %ArbFileName '"']); for wideband arb
        opcComp = query(deviceObject, '*OPC?');
        while str2double(opcComp)~= 1
            pause(0.5);
            opcComp = query(deviceObject, '*OPC?');
        end

        % ARB Radio on
        xfprintf(deviceObject, ':SOURce:RADio:ARB:STATe ON');
        % modulator on
        xfprintf(deviceObject, ':OUTPut:MODulation:STATe ON');
        % RF output on
        xfprintf(deviceObject, ':OUTPut:STATe ON');

        %Local Mode
        xfprintf(deviceObject, 'SYST:COMM:GTL');
    end
end


function lOControl(deviceObject, lOConfig)
% Controls the VUXG to set its external LO accordingly
switch lOConfig
    case 'FCP'
        setAndWait(deviceObject, ':FREQuency:LO:CONTrol:TYPE?', 'FCP', ':FREQuency:LO:CONTrol:TYPE FCPort');
    case 'USB'
        setAndWait(deviceObject, ':FREQuency:LO:CONTrol:TYPE?', 'SCPI', ':FREQuency:LO:CONTrol:TYPE SCPI');
        setAndWait(deviceObject, ':SYSTem:LO:COMMunicate:TYPE?', 'USB', ':SYSTem:LO:COMMunicate:TYPE USB');
        setAndWait(deviceObject, ':FREQuency:LO:CONTrol:SCPI:INITialize?', '1', ':FREQuency:LO:CONTrol:SCPI:INITialize ON');
    case 'None'
        xfprintf(deviceObject, ':FREQuency:LO:CONTrol:TYPE NONE');
    case 'NONE'
        xfprintf(deviceObject, ':FREQuency:LO:CONTrol:TYPE NONE');
    otherwise
        setAndWait(deviceObject, ':FREQuency:LO:CONTrol:TYPE?', 'SCPI', ':FREQuency:LO:CONTrol:TYPE SCPI');
        setAndWait(deviceObject, ':SYSTem:LO:COMMunicate:TYPE?', 'SOCK', ':SYSTem:LO:COMMunicate:TYPE SOCKets');
        setAndWait(deviceObject, ':SYSTem:LO:COMMunicate:LAN:IP?', ['"' lOConfig '"'], [':SYSTem:LO:COMMunicate:LAN:IP "' lOConfig '"']);
        setAndWait(deviceObject, ':FREQuency:LO:CONTrol:SCPI:INITialize?', '1', ':FREQuency:LO:CONTrol:SCPI:INITialize ON');
end

end

function setAndWait(deviceObject, queryCommand, desiredState, setupCommand)
% Controls the VUXG to set its external LO accordingly
    modeCurrent = query(deviceObject, queryCommand);
    
    modeTest = desiredState;
    if numel(desiredState) < numel(modeCurrent)
        modeTest = modeCurrent(1:numel(desiredState)); 
    end
    
    if (~strcmp(modeTest, desiredState))    
        xfprintf(deviceObject, setupCommand);
        opcComp = query(deviceObject, '*OPC?');
        while str2double(opcComp)~= 1
            pause(0.1);
            opcComp = query(deviceObject, '*OPC?');
        end
    end

end

function xfprintf(f, s)
% Send the string s to the instrument object f
% and check the error status

% un-comment the following line to see a trace of commands
%    fprintf('cmd = %s\n', s);

    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s\n', s);
    end

    fprintf(f, s);
    count = 0;
    while (count<30)
        result = query(f, ':syst:err?');

        if (isempty(result))
            fclose(f);
            errordlg('Instrument did not respond to :SYST:ERR query. Check the instrument.', 'Error');
            error('Instrument did not respond to :SYST:ERR query. Check the instrument.');
            break;
        end

        if (~strncmpi(result, '+0,no error', 10) && ~strncmpi(result, '+0,"no error"', 12))
            errordlg(sprintf('Instrument returns error on cmd "%s". Result = %s\n', s, result));
        else
            break;
        end
        count = count + 1;
    end
end
