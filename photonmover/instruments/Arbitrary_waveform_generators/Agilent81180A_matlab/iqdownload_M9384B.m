function f = iqdownload_M9384B(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, amplitude, fCenter, segmName, segmentLength, segmentOffset)
% Download IQ to M9383B, M9384B

    % Open the arbconfig file
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    
    if (~isempty(sequence))
        errordlg('Sequence mode is currently not available for this Keysight VSG');
        f = [];
        return;
    end

    % Segment lengths involved in offset based downloads, if none set to
    % current data
    if(~exist('segmentLength', 'var') || isempty(segmentLength))
        segmentLength = numel(data);
    end

    % If there's a segment offset, set the current name of the arbconfig file
    if(~exist('segmentOffset', 'var') || isempty(segmentOffset))
        segmentOffset = 0;
    elseif segmentOffset > 0
        segmName = arbConfig.arbfilename;
    end

    if ((strcmp(arbConfig.connectionType, 'visa')) || (strcmp(arbConfig.connectionType, 'tcpip')))
        f.ByteOrder = 'bigEndian';
    else
        f.ByteOrder = 'littleEndian';
    end

    % Do a reset if commanded to
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        xfprintf(f, '*RST');
    end

    %% Download and/or play signal
    % For each channel inputted, download
    [channelCount, ~] = size(channelMapping);

    % If in coherent mode, ask for all at once, otherwise ask piece by piece
    if strcmp(arbConfig.model, 'M9384B_2Ch_COH')
        % prompt the user for center frequency and power
        % defaults are the current settings
        % added a conditional for scripting
        if ((isempty(amplitude) || isempty(fCenter) || isempty(segmName)) && segmentOffset == 0)
            fCenterSet1      = query(f, ':RF1:FREQuency?');
            amplitudeSet1    = query(f, ':RF1:POWer?');
            fCenterSet2      = query(f, ':RF2:FREQuency?');
            amplitudeSet2    = query(f, ':RF2:POWer?');
            segmNameSet     = sprintf('IQTools%04d', segmNum);
            prompt       = {'Ch 1 Amplitude (dBm):', 'Ch 1 Carrier Frequency (Hz): ','Ch 2 Amplitude (dBm):', 'Ch 2 Carrier Frequency (Hz): ' 'Segment Name: '};
            defaultVal   = {sprintf('%g', eval(amplitudeSet1)), sprintf('%g', eval(fCenterSet1)),...
                sprintf('%g', eval(amplitudeSet2)), sprintf('%g', eval(fCenterSet2)), sprintf(segmNameSet)};
            dlg_title    = 'Configure 2 Channel Coherent Setup';
            user_vals    = inputdlg(prompt, dlg_title, [1 50], defaultVal);
            drawnow;

            if (isempty(user_vals))
                return;
            end

            % If empty selections, fill them in for now
            if (isempty(user_vals{1})) && (isempty(user_vals{2}))
                amplitudeSet1 = 0;
                fCenterSet1   = 1e9;
                warndlg('The amplitude is set to 0 dBm, and carrier frequency to 1 GHz')
            else
                amplitudeSet1 = user_vals{1};
                fCenterSet1   = user_vals{2};
            end

            if (isempty(user_vals{1})) && ~(isempty(user_vals{2}))
                amplitudeSet1 = 0;
                warndlg('The amplitude is set to 0 dBm')
            else     
                amplitudeSet1 = user_vals{1};
            end

            if ~(isempty(user_vals{1})) && (isempty(user_vals{2}))
                fCenterSet1 = 1e9;    
                warndlg('Carrier frequency is set to 1 GHz')
            else
                fCenterSet1 = user_vals{2};
            end

            if (isempty(user_vals{3})) && (isempty(user_vals{4}))
                amplitudeSet2 = 0;
                fCenterSet2   = 1e9;
                warndlg('The amplitude is set to 0 dBm, and carrier frequency to 1 GHz')
            else
                amplitudeSet2 = user_vals{3};
                fCenterSet2   = user_vals{4};
            end

            if (isempty(user_vals{3})) && ~(isempty(user_vals{4}))
                amplitudeSet2 = 0;
                warndlg('The amplitude is set to 0 dBm')
            else     
                amplitudeSet2 = user_vals{3};
            end

            if ~(isempty(user_vals{3})) && (isempty(user_vals{4}))
                fCenterSet2 = 1e9;    
                warndlg('Carrier frequency is set to 1 GHz')
            else
                fCenterSet2 = user_vals{4};
            end

            if (isempty(user_vals{5}))
                segmNameSet  = sprintf('IQTools%04d', segmNum);
            else     
                segmNameSet  = user_vals{5};
            end           
        else
            % If batch downloading keep as current
            fCenterSet1      = query(f, ':RF1:FREQuency?');
            amplitudeSet1    = query(f, ':RF1:POWer?');
            fCenterSet2      = query(f, ':RF2:FREQuency?');
            amplitudeSet2    = query(f, ':RF2:POWer?');
            segmNameSet     = arbConfig.arbfilename;
        end     

        % Download the signal
        downloadSignal(f, data.', marker1, marker2,...
            segmNameSet, segmentLength, segmentOffset, 1, true,...
            fCenterSet1, amplitudeSet1);

        downloadSignal(f, data.', marker1, marker2,...
            segmNameSet, segmentLength, segmentOffset, 2, false,...
            fCenterSet2, amplitudeSet2);

        % Update latest filename for batch downloads
        arbCfgFile = iqarbConfigFilename();
        open(arbCfgFile);
        arbConfig.arbfilename = segmNameSet;

        if(exist('saConfig', 'var'))
            save(arbCfgFile, 'arbConfig', 'saConfig');
        else
            save(arbCfgFile, 'arbConfig');
        end

        % Only run the output if not doing a batch download
        if (isempty(segmentLength) || segmentOffset + length(data) >= segmentLength)
            doRun(f, segmNameSet, fs, fCenterSet1, amplitudeSet1, arbConfig.DACRange, 1, 1);
            doRun(f, segmNameSet, fs, fCenterSet2, amplitudeSet2, arbConfig.DACRange, 2, 1);
        end

        if (~keepOpen)
            fclose(f);delete(f); 
        end        
    else
        for channelIdx = 1:channelCount

            % If channel mapped, download
            if any(channelMapping(channelIdx,:))
                channelString = num2str(channelIdx);

                % prompt the user for center frequency and power
                % defaults are the current settings
                % added a conditional for scripting
                if ((isempty(amplitude) || isempty(fCenter) || isempty(segmName)) && segmentOffset == 0)
                    fCenterSet1      = query(f, [':RF' channelString ':FREQuency?']);
                    amplitudeSet1    = query(f, [':RF' channelString ':POWer?']);
                    segmNameSet     = sprintf('IQTools%04d', segmNum); %WBS: needs to have .wfm extension?      % filename for the data in the ARB
                    prompt       = {'Amplitude of Signal (dBm):', 'Carrier Frequency (Hz): ', 'Segment Name: '};
                    defaultVal   = {sprintf('%g', eval(amplitudeSet1)), sprintf('%g', eval(fCenterSet1)), sprintf(segmNameSet)};
                    dlg_title    = ['Configure Channel ' channelString];
                    user_vals    = inputdlg(prompt, dlg_title, [1 50], defaultVal);
                    drawnow;

                    if (isempty(user_vals))
                        return;
                    end

                    if (isempty(user_vals{1})) && (isempty(user_vals{2}))
                        amplitudeSet1 = 0;
                        fCenterSet1   = 1e9;
                        warndlg('The amplitude is set to 0 dBm, and carrier frequency to 1 GHz')
                    else
                        amplitudeSet1 = user_vals{1};
                        fCenterSet1   = user_vals{2};
                    end

                    if (isempty(user_vals{1})) && ~(isempty(user_vals{2}))
                        amplitudeSet1 = 0;
                        warndlg('The amplitude is set to 0 dBm')
                    else     
                        amplitudeSet1 = user_vals{1};
                    end

                    if ~(isempty(user_vals{1})) && (isempty(user_vals{2}))
                        fCenterSet1 = 1e9;    
                        warndlg('Carrier frequency is set to 1 GHz')
                    else
                        fCenterSet1 = user_vals{2};
                    end

                    if (isempty(user_vals{3}))
                        segmNameSet  = sprintf('IQTools%04d', segmNum);
                    else     
                        segmNameSet  = user_vals{3};
                    end 
                else
                    fCenterSet1      = query(f, [':RF' channelString ':FREQuency?']);
                    amplitudeSet1    = query(f, [':RF' channelString ':POWer?']);
                    segmNameSet     = arbConfig.arbfilename;
                end        

                % Download the signal
                downloadSignal(f, data.', marker1, marker2,...
                    segmNameSet, segmentLength, segmentOffset, channelIdx, true,...
                    fCenterSet1, amplitudeSet1);

                % Update latest filename for batch downloads
                arbCfgFile = iqarbConfigFilename();
                open(arbCfgFile);
                arbConfig.arbfilename = segmNameSet;

                if(exist('saConfig', 'var'))
                    save(arbCfgFile, 'arbConfig', 'saConfig');
                else
                    save(arbCfgFile, 'arbConfig');
                end

                % Only run the output if not doing a batch download
                if (isempty(segmentLength) || segmentOffset + length(data) >= segmentLength)
                    doRun(f, segmNameSet, fs, fCenterSet1, amplitudeSet1, arbConfig.DACRange, channelIdx, 1);
                end

                if (~keepOpen)
                    fclose(f);delete(f); 
                end
            end   
        end
    end
    
end


function downloadSignal(deviceObject, IQData, marker1, marker2, ArbFileName,...
    segmentLength, segmentOffset, downloadChannel, doDownload,...
    centerFrequency, outputPower)
% This function downloads IQ Data to the signal generator's non-volatile memory

    % Get the channel
    channelString = num2str(downloadChannel);

    % Some settings commands to make sure we don't damage the instrument
    % Assume we only do these on segment offset == 0
    if segmentOffset == 0  

        % Clear errors etc.
        deviceObject.Timeout = 60;
        xfprintf(deviceObject,'*CLS');

        % RF Off
        xfprintf(deviceObject,[':RF' channelString ':OUTPut OFF'])
        % ARB Off
        xfprintf(deviceObject,[':SIGNal' channelString ':STATe OFF'])
        % Modulation off
        xfprintf(deviceObject,[':RF' channelString ':OUTPut:MODulation:STATe OFF'])

        % set center frequency (Hz)
        xfprintf(deviceObject,[':RF' channelString ':FREQuency ' num2str(centerFrequency)]); 
        % set output power (dBm)
        xfprintf(deviceObject,[':RF' channelString ':POWer ' num2str(outputPower)]);
    end
    
    if doDownload        
        if ~isvector(IQData)
            error('downloadWaveform: invalidInput');
        else
            IQsize = size(IQData);
            % User gave input as column vector. Reshape it to row vector.
            if ~isequal(IQsize(1),1)
                IQData = reshape(IQData,1,IQsize(1));
            end
        end

        % Separate out the real and imaginary data in the IQ Waveform
        wave = [real(IQData);imag(IQData)];
        wave = wave(:)';    % transpose the waveform

        % Only scale if one waveform is being downloaded and not portions
        % Otherwise scaling will make EVMs worse
        tmp = max(abs([max(wave) min(wave)]));
        if (tmp == 0|| numel(IQData) < segmentLength)
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

        % Write the data to the instrument   
        
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
                binblockwrite(deviceObject,wave(1:threshold),'uint16',[':MEM:DATA:APPend "' ArbFileName '.wiq", ']);
                fprintf(deviceObject,'\n'); 
            else
                binblockwrite(deviceObject,wave(1:threshold),'uint16',['MEM:DATA "NVWFM:' ArbFileName '", ']);
                fprintf(deviceObject,'\n');
            end

            % Update chunk
            chunkIdx = threshold + 1;
            chunkEnd = chunkIdx + threshold;

            % Keep chunking until we reach number of samples
            while chunkEnd <= numSamples
                binblockwrite(deviceObject,wave(chunkIdx:chunkEnd),'uint16',[':MEM:DATA:APPend "' ArbFileName '.wiq", ']);
                fprintf(deviceObject,'\n');     

                chunkIdx = chunkIdx + threshold + 1;
                chunkEnd = chunkIdx + threshold;

                if (isempty(segmentLength) || segmentOffset + length(IQData) >= segmentLength)
                    disp(['Waveform Download: ' num2str(chunkIdx/numSamples*100) ' percent complete'])        
                end            
            end

            % Write the last portion of the waveform
            binblockwrite(deviceObject,wave(chunkIdx:numSamples),'uint16',[':MEM:DATA:APPend "' ArbFileName '.wiq", ']);
            fprintf(deviceObject,'\n'); 

        else
            % Just send one portion of the waveform    
            if(segmentOffset > 0)
                binblockwrite(deviceObject,wave,'uint16',[':MEM:DATA:APPend "' ArbFileName '.wiq", ']);
                fprintf(deviceObject,'\n');
            else
                binblockwrite(deviceObject,wave,'uint16',['MEM:DATA "NVWFM:' ArbFileName '", ']);
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
                % Normalize
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

            marker = uint16(marker1 + marker2);

            % Marker Data
            numMarkers = numel(marker);            
            if numMarkers > threshold
                % numSamples = numel(marker);

                % Write the first chunk, if it's an offset just assume we're starting
                % from last point we left off as the SCPI command set can only append
                if(segmentOffset > 0)
                    binblockwrite(deviceObject,marker(1:threshold),'uint8',[':MEM:DATA:APPend "' ArbFileName '.wmk", ']);
                    fprintf(deviceObject,'\n');
                else
                    % xfprintf(deviceObject, [':MMEMory:DELete "MKR1:' ArbFileName '"']);
                    binblockwrite(deviceObject,marker(1:threshold),'uint8',[':MEM:DATA "NVMKR:' ArbFileName '", ']);
                    fprintf(deviceObject,'\n');     
                end

            % Update chunk
            chunkIdx = threshold + 1;
            chunkEnd = chunkIdx + threshold;

            % Keep chunking until we reach the chunk count
            while chunkEnd <= numMarkers
                binblockwrite(deviceObject,marker(chunkIdx:chunkEnd),'uint8',[':MEM:DATA:APPend "' ArbFileName '.wmk", ']);
                fprintf(deviceObject,'\n');     

                chunkIdx = chunkIdx + threshold + 1;
                chunkEnd = chunkIdx + threshold;

                if (isempty(segmentLength) || segmentOffset + length(IQData) >= segmentLength)
                    disp(['Marker Download: ' num2str(chunkIdx/numMarkers*100) ' percent complete'])        
                end            
            end

            % Write last portion
            binblockwrite(deviceObject,marker(chunkIdx:numMarkers),'uint8',[':MEM:DATA:APPend "' ArbFileName '.wmk", ']);
            fprintf(deviceObject,'\n'); 

            else
                % Just write the data once        
                if(segmentOffset > 0)
                    binblockwrite(deviceObject,marker,'uint8',[':MEM:DATA:APPend "' ArbFileName '.wmk", ']);
                    fprintf(deviceObject,'\n');
                else
                    binblockwrite(deviceObject,marker,'uint8',[':MEM:DATA "NVMKR:' ArbFileName '", ']);
                    fprintf(deviceObject,'\n');
                end
            end

            if (isempty(segmentLength) || segmentOffset + length(IQData) >= segmentLength)
                disp('Marker Download Complete')         
            end         
        end
    
%         % Local Mode
%         xfprintf(deviceObject, 'SYST:COMM:GTL');
    end
end

function doRun(deviceObject, ArbFileName, sampleRate,...
    centerFrequency, outputPower, scalingFactor, runChannel, run)
% This function plays the signal

    % Get the channel
    channelString = num2str(runChannel);

    if run ~= 0

        % Play back the selected waveform 
        xfprintf(deviceObject,[':SIGNal' channelString ':WAVeform:SELect "NVWFM:' ArbFileName '"']);
        xfprintf(deviceObject,[':SIGNal' channelString ':WAVeform:SELect "' ArbFileName '.wiq"']);
        opcComp = query(deviceObject, '*OPC?');

        while str2double(opcComp)~= 1
            pause(0.5);
            opcComp = query(deviceObject, '*OPC?');
        end
        
        % Set the scaling to Scaling range
        xfprintf(deviceObject,[':SIGNal' channelString ':WAV:SCAL ' num2str(scalingFactor*100)]);

        % Set the sample rate (Hz) for the signal.
        % You can get this info for the standard signals by looking at the data in the 'waveforms' variable
        xfprintf(deviceObject,[':SIGNal' channelString ':WAV:SCL:RATE ' num2str(sampleRate)]);
        
        % set center frequency (Hz)
        xfprintf(deviceObject,[':RF' channelString ':FREQuency ' num2str(centerFrequency)]); 
        % set output power (dBm)
        xfprintf(deviceObject,[':RF' channelString ':POWer ' num2str(outputPower)]);

        % Turn the arb on
        xfprintf(deviceObject,[':SIGNal' channelString ':STATe ON'])        
        % Modulation on
        xfprintf(deviceObject,[':RF' channelString ':OUTPut:MODulation:STATe ON'])
        % RF On
        xfprintf(deviceObject,[':RF' channelString ':OUTPut ON'])

        %Local Mode
        %xfprintf(deviceObject, 'SYST:COMM:GTL');
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
