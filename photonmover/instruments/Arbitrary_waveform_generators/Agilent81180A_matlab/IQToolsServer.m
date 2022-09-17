classdef IQToolsServer < handle
% IQToolsServer Class for external control of IQTools via server
%   This class contains the properties and methods necessary for
%   controlling IQTools via server, with focus on pulses and combining
%   of pulses and general purposes commands
%
% #TODO
% 1.Add correction file loading/management
% 2.Add calibration commands, with different calibration types
%
%
% Tom Wychock, Keysight Technologies 2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 
    
    properties
        
        %% Server properties
        
        Server = struct(...
            ...  % IO Properties
            'IPv4Address', '127.0.0.1',...              % The IPv4 Address of the instrument
            'SocketPort', 30000,...                     % The socket port of the instrument
            'ServerInstance', [],...                    % The server instance                           
            'ModelString', 'IQTools Server 1.0',...     % The version
            'UseUDP', false,...                         % Use TCPIP or UDP?
            ...  % Parser state, Error queue and debug
            'CurrentCommand', '',...                    % the currently processed command line
            'ParseNext', '',...                         % the portion of the command line that has not been parsed yet
            'ErrorQueue', {'0'},...                     % The error queue to query        
            'DebugMode', false);                        % Debug mode                            
                                               
        %% Instrument properties
        
        Instrument = struct(...
            'ModeString', 'Vector',...              % The instrument mode
            'SampleRateInHz', 250E6,...             % The sample rate of the source in Hz
            'ChannelMapping', [1 0; 0 1],...        % The channel mapping of the instrument
            'SegmentNumber', 1,...                  % Waveforms are downloaded to this segment number
            'SegmentName', 'IQTools0001',...        % Waveforms are downloaded with this name (if named)
            'InstrumentPathArray', {''},...         % The instruments present in the system
            'FileSaveType', '16-bit I/Q MSB',...    % The file type to save
            'RFFrequency', 0,...                    % The RF Frequency if upconverting
            'RFAmplitude', -120,...                	% The RF Amplitude if upconverting
            'RFOn', 0,...                           % The RF State if upconverting
            'Type', 'SignalGenerator');             % The instrument type                      
                
        %% Calibration properties
        
        Calibration = struct(...
            ...  % Type, span, spacing, wait time
            'ComplexCalibrationType', 'VSAChannel',...          % The type of calibration to perform
            'ComplexCalibrationSpanInHz', 100E6,...             % The frequency span of the calibration in Hz
            'ComplexCalibrationSpacingInHz', 1E6,...            % The frequency spacing of the calibration in Hz
            'ComplexCalibrationSettleTimeInS', 3,...            % The settling time of the calibration in seconds
            'ComplexCalibrationOffsetInHz', 0,...               % The offset frequency to avoid LO feedthru
            'ComplexCalibrationCenterFrequencyInHz', 0,...      % The center frequency of the calibration in Hz
            'Recalibrate', 0,...                                % Calibrate with signals generated using calibrated data?
            'Initialize', 1,...                                 % Calibrate with initialization?
            'AutoRange', 1,...                                  % Autorange during the calibration
            'RangeInDBm', 30,...                                % Calibration range during the calibration
            'CalibrationSavePath', 'AmpCorrTemporary');         % The save path of the calibration
                
        %% Command properties
        
        Scripting = struct(...
            'ScriptCommandCurrent', '',...   % The current command
            'ScriptCommandTable', []);       % The list of commands
    
        %% Correction #TODO: Add correction code
        
        Correction = struct(...
            'UseCorrection', 0,...      % Whether or not to use corrections
            'CorrectionFilePath', '');  % The correction file path
                       
        %% Single pulse properties
        
        % Pulses are created by giving them properties, then commanding the
        % server to create and save/preview the IQ data
        
        PulseGen = struct(...
            ...  % Time
            'PulseDwellInSeconds', 8E-6,...             % The dwell of the iq snippet in seconds
            'PulseWidthInSeconds', 2E-6,...             % The width of the pulse in seconds
            'PulseRiseTimeInSeconds', 20E-9,...         % The rise time of the pulse in seconds
            'PulseFallTimeInSeconds', 20E-9,...         % The fall time of the pulse in seconds
            'PulseDelayInSeconds', 0,...                % The delay time of the pulse in seconds
            ...  % Amplitude, phase, frequency. shaping
            'PulseAmplitudeInDB', 0,...                 % The amplitude in DB
            'PulsePhaseInDegrees', 0,...                % The phase of the signal in degrees
            'PulseFrequencyOffsetInHz', 0,...           % The frequency offset of the signal in Hz
            'PulseShape', 'Raised Cosine',...           % The rise/fall shape of the pulse
            ...  % Modulation
            'PulseModulationType', 'None',...           % The modulation type of the pulse
            'PulseModulationFrequencySpan', 100E6,...   % The modulation frequency span of the pulse
            'PulseFilePathSave', 'PulseTemporary',...   % The file path of the save
            'PulseFrequencyModulationFormula', '0',...  % The frequency modulation formula if custom
            'PulsePhaseModulationFormula', '0',...      % The phase modulation formula if custom
            'PulsePhaseTransitionState', 'coherent',... % The phase change rules
            'PulseNormalize', 1 );                      % 1:scale to DAC full range, 0: use PulseAmplitudeInDB as dBFS 
                                                              
        %% Multi pulse settings, for adding multiple pulses together
        
        % This works by creating an array of pulse structures that contain
        % the properties of a single pulse with the start time, base
        % amplitude, and phase transition rules.
        %
        % When processed, this will output a scaled amplitude output to
        % adjust the source to (the DAC bits might scale to be greater than
        % one, meaning the base amplitude must increase), and a time as
        % well (to save DAC samples).  
        
        PulseCombineGen = struct(...
            'MultiPulseTable', [],...                   % The array of pulse objects for combining etc.
            'MultiPulseStartTimeInSeconds', 0,...       % The start time of the pulse
            'MultiPulseTransitionType', 'coherent',...  % The conversion type
            'MultiPulseBasePulseAmplitudeInDB', 0,...   % When combining, the base amplitude in dBm
            'MultiPulseBasePulsePhaseInDegrees', 0,...  % When combining, the base phase in degrees
            'MultiPulseAmplitudeShiftInDB', 0,...       % When doing the combining, if adding, the new scale
            'MultiPulseTimeShiftInS', 0 );              % When doing the combining, if adding, the new time            
                        
        %% Multi-tone parameters
        
        ToneGen = struct(...
            'ToneFrequency', 100e6, ...  % frequency in Hz
            'ToneMagnitude', 0, ...      % magnitude in dBFS (if normalize == 0)
            'TonePhase', 'Random', ...   % phase in degrees or 'Random'
            'ToneNormalize', 1 );        % 1:scale to DAC full range, 0: use magnitude as dBFS

    end
    
    methods
        % Constructor
        function obj = IQToolsServer(IPv4AddressIn, SocketPortIn)
           % Pass in the address and port
           obj.Server.IPv4Address = IPv4AddressIn;
           obj.Server.SocketPort = SocketPortIn;           
           obj.DefaultPulse();
           obj.DefaultPulseCombo();
           obj.DefaultCommandList();
           obj.DefaultTone();
           obj.Server.ErrorQueue = {'0'};
        end
        
        % Destructor
        function delete(obj)
            % delete the tcpip instance, otherwise the list in instrfind keeps growing
            % disp('Destructor called');
            if (~isempty(obj.Server.ServerInstance))
                delete(obj.Server.ServerInstance);
            end
        end
                
        %% Server methods

        % TCPIP        
        function serverOut = LaunchServerTCPIP(obj)
            % LaunchServerTCPIP Launches a TCPIP server based on the configured port and socket properties
            disp('Launching TCPIP Server...')
            
            obj.Server.ServerInstance = tcpip(obj.Server.IPv4Address, obj.Server.SocketPort,...
            'NetworkRole', 'server');                   
        
            % Return the port
            obj.Server.SocketPort = obj.Server.ServerInstance.RemotePort;
                               
            % Link to IP
            disp(['Server TCPIP IP: ' num2str(obj.Server.ServerInstance.RemoteHost)]);

            % Link to port
            disp(['Server TCPIP port: ' num2str(obj.Server.ServerInstance.RemotePort)]);
            
            % Subscribe to bytes received
            obj.Server.ServerInstance.BytesAvailableFcn = @obj.parseReceivedDataAndReact; 
            
            % Set buffer            
            obj.Server.ServerInstance.InputBufferSize = 4000000;
            obj.Server.ServerInstance.OutputBufferSize = 40000;
            
            % Launch
            disp('Listening for connection...press CTRL+C in the command window to cancel...')
            
            fopen(obj.Server.ServerInstance);                        
            disp('Connected!')
            
            serverOut = obj.Server.ServerInstance;
            obj.Server.UseUDP = false;
        end
        
        function CloseServerTCPIP(obj)
           % CloseServerTCPIP   Closes a TCPIP server if launched
           disp('Closing TCPIP Server...')
           fclose(obj.Server.ServerInstance);
           disp('Server closed.')
        end
        
        % UDP
        function serverOut = LaunchServerUDP(obj, remotePort)
            % LaunchServerUDP Launches a UDP server based on the configured port and sockets properties
            disp('Launching UDP Server...')
            
            obj.Server.ServerInstance = udp(obj.Server.IPv4Address,...
                'LocalPort', obj.Server.SocketPort, 'RemotePort', remotePort);                   
        
            % Return the port
            obj.Server.SocketPort = obj.Server.ServerInstance.LocalPort;
                               
            % Link to IP
            disp(['Server UDP IP: ' num2str(obj.Server.ServerInstance.LocalPort)]);

            % Link to port
            disp(['Server UDP Receive port: ' num2str(obj.Server.ServerInstance.LocalPort)]);
            disp(['Server UDP Send port: ' num2str(obj.Server.ServerInstance.RemotePort)]);
            
            % Subscribe to bytes received
            obj.Server.ServerInstance.BytesAvailableFcn = @obj.parseReceivedDataAndReact; 
            
            % Set buffer            
            obj.Server.ServerInstance.InputBufferSize = 4000000;
            obj.Server.ServerInstance.OutputBufferSize = 40000;
            
            % Launch
            fopen(obj.Server.ServerInstance);                        
            disp('Connected!')
            
            serverOut = obj.Server.ServerInstance;
            obj.Server.UseUDP = true;
        end
        
        function CloseServerUDP(obj)
           % CloseServerUDP   Closes a UDP server if launched
           disp('Closing UDP Server...')
           fclose(obj.Server.ServerInstance);
           disp('Server closed.')
        end
        
        % Configuration settings
        function setInstruments(obj, instrumentArrayIn)
            % Set the instruments in the server
            obj.Instrument.InstrumentPathArray = instrumentArrayIn;
        end
                
        function setMode(obj, modeStringIn)
            % Sets the arbconfig correctly
            if obj.Server.DebugMode
               disp('Loading arb config file...') 
            end
            
            arbConfigMod = load(iqarbConfigFilename());
            arbConfig = arbConfigMod.arbConfig;
            
            if ~isfield(arbConfigMod, 'saConfig')
                arbConfigMod.('saConfig') = [];
            end
            
            saConfig = arbConfigMod.saConfig;
            
            if obj.Server.DebugMode
               disp('Saving arb config file...') 
            end
            
            arbConfig.model = modeStringIn;
            save(iqarbConfigFilename(), 'arbConfig', 'saConfig');    
            
            if obj.Server.DebugMode
               disp('File saved.') 
            end
        end
        
        function Reset(obj)
            % reset server parameters *EXCEPT* mode
            obj.Correction.UseCorrection = 0;                % Whether or not to use corrections
            obj.Correction.CorrectionFilePath = '';          % The correction file path
            obj.Instrument.ChannelMapping = [1 0; 0 1];      % The channel mapping of the instrument
            obj.Instrument.SegmentNumber = 1;                % Waveforms are downloaded to this segment
            obj.Instrument.FileSaveType = '16-bit I/Q MSB';  % The file type                
            obj.DefaultPulse();
            obj.DefaultPulseCombo();
            obj.DefaultTone();
            arbConfig = loadArbConfig();
            obj.Instrument.SampleRateinHz = arbConfig.defaultSampleRate;
        end

        %% Custom command methods
                
        function ExecuteScriptCommandCurrent(obj)
            % ExecuteScriptCommandCurrent   Executes a single command
            if obj.Server.DebugMode
                disp(['Executing:' obj.Scripting.ScriptCommandCurrent])
            end

            % Execute the command and log error if error
            try
                eval(obj.Scripting.ScriptCommandCurrent);
            catch ex
                disp(['Error executing command: ' getReport(ex,'extended')]);
                obj.Server.ErrorQueue{end + 1} = ['Error executing command: ' ex.message];
            end 
        end
                
        function ExecuteCommandList(obj)
            % ExecuteCommandList    Executes the command list
            if obj.Server.DebugMode
                disp('Executing command list')
            end

            % Execute the command list
            try
                if length(obj.Scripting.ScriptCommandTable) > 0  
                    
                    % Get commands
                    commandArray = {obj.Scripting.ScriptCommandTable.command};
                    
                    % Execute each one
                    for commandIdx = 1:length(commandArray)
                        if obj.Server.DebugMode
                            disp(['Executing:' commandArray{commandIdx}])
                        end
                        
                        % Execute command
                        eval(commandArray{commandIdx});
                    end
                end
            catch ex
                disp(['Error executing command list: ' getReport(ex,'extended')]);
                obj.Server.ErrorQueue{end + 1} = ['Error executing command list: ' ex.message];
            end 
            

        end
                
        function DefaultCommand(obj)
            % DefaultCommand    Resets the current command
            obj.Scripting.ScriptCommandCurrent = '';
        end
                
        function DefaultCommandList(obj)
            % DefaultCommandList    Resets the command list
            obj.Scripting.ScriptCommandTable = [];
        end
                
        function commandStructureOut = CreateCommandStructure(obj)
            % CreateCommandStructure    Adds a command to the list (can add structure items if desired)
            commandStructureOut = struct(...
                'command', obj.Scripting.ScriptCommandCurrent);
        end
            
        %% Pulse generation methods
                
        function DefaultPulse(obj)
            % DefaultPulse  Reverts the pulse to default data
                        
            obj.PulseGen.PulseAmplitudeInDB = 0;  % The amplitude in DB
            obj.PulseGen.PulsePhaseInDegrees = 0;  % The phase of the signal in degrees
            obj.PulseGen.PulseFrequencyOffsetInHz = 0;  % The frequency offset of the signal in Hz
            obj.PulseGen.PulseShape = 'Raised Cosine';  % The rise shape of the pulse
            obj.PulseGen.PulseDelayInSeconds = 0;  % The delay time of the pulse in seconds
            obj.PulseGen.PulseModulationType = 'None';  % The modulation type of the pulse
            obj.PulseGen.PulseFilePathSave = 'PulseTemporary';  % The file path of the save
            obj.PulseGen.PulseFrequencyModulationFormula = '0';  % The frequency modulation formula if custom
            obj.PulseGen.PulsePhaseModulationFormula = '0';  % The phase modulation formula if custom
            obj.PulseGen.PulsePhaseTransitionState = 'coherent';  % The phase change rules
            obj.PulseGen.PulseNormalize = 1;  % 1: scale to full DAC range, 0: use PulseAmplitudeInDB as dbFS

            switch obj.Instrument.ModeString
               case {'Vector', 'N5194A_250MHz', 'Vector Internal', 'N5194A_250MHz_In'}  % N5194A Vector Mode
                    obj.Instrument.SampleRateInHz = 250E6;
                    obj.PulseGen.PulseDwellInSeconds = 8E-6;  % The dwell of the iq snippet in seconds
                    obj.PulseGen.PulseWidthInSeconds = 2E-6;  % The width of the pulse in seconds
                    obj.PulseGen.PulseRiseTimeInSeconds = 20E-9;  % The rise time of the pulse in seconds
                    obj.PulseGen.PulseFallTimeInSeconds = 20E-9;  % The fall time of the pulse in seconds
                    
                    obj.PulseGen.PulseModulationFrequencySpan = 100E6;  % The modulation frequency span of the pulse                       
                case {'Wideband Vector', 'N5194A_2GHz'}   % N5194A Wideband Mode
                    obj.Instrument.SampleRateInHz = 2E9;  % The sample rate can only be 2 GHz
                    obj.PulseGen.PulseDwellInSeconds = 8E-6;  % The dwell of the iq snippet in seconds
                    obj.PulseGen.PulseWidthInSeconds = 2E-6;  % The width of the pulse in seconds
                    obj.PulseGen.PulseRiseTimeInSeconds = 20E-9;  % The rise time of the pulse in seconds
                    obj.PulseGen.PulseFallTimeInSeconds = 20E-9;  % The fall time of the pulse in seconds

                    obj.PulseGen.PulseModulationFrequencySpan = 500E6;  % The modulation frequency span of the pulse     
                case 'M8190A_12bit'  % M8190A
                    obj.Instrument.SampleRateInHz = 12E9;  % The sample rate can only be 2 GHz
                    obj.PulseGen.PulseDwellInSeconds = 8E-6;  % The dwell of the iq snippet in seconds
                    obj.PulseGen.PulseWidthInSeconds = 2E-6;  % The width of the pulse in seconds
                    obj.PulseGen.PulseRiseTimeInSeconds = 20E-9;  % The rise time of the pulse in seconds
                    obj.PulseGen.PulseFallTimeInSeconds = 20E-9;  % The fall time of the pulse in seconds

                    obj.PulseGen.PulseModulationFrequencySpan = 2E9;  % The modulation frequency span of the pulse 
                    obj.PulseGen.PulseFrequencyOffsetInHz = 2E9;
                case 'M8190A_14bit'  % M8190A
                    obj.Instrument.SampleRateInHz = 8E9;  % The sample rate can only be 2 GHz
                    obj.PulseGen.PulseDwellInSeconds = 8E-6;  % The dwell of the iq snippet in seconds
                    obj.PulseGen.PulseWidthInSeconds = 2E-6;  % The width of the pulse in seconds
                    obj.PulseGen.PulseRiseTimeInSeconds = 20E-9;  % The rise time of the pulse in seconds
                    obj.PulseGen.PulseFallTimeInSeconds = 20E-9;  % The fall time of the pulse in seconds

                    obj.PulseGen.PulseModulationFrequencySpan = 2E9;  % The modulation frequency span of the pulse 
                    obj.PulseGen.PulseFrequencyOffsetInHz = 2E9;
            end            
        end
        
        function DefaultPulseCombo(obj)
            % DefaultPulseCombo Reverts the pulse combining properties to defaults
            
            obj.Correction.UseCorrection = 0;
            obj.PulseCombineGen.MultiPulseStartTimeInSeconds = 0;
            obj.PulseCombineGen.MultiPulseTable = [];
            obj.PulseCombineGen.MultiPulseBasePulseAmplitudeInDB = 0;
            obj.PulseCombineGen.MultiPulseTransitionType = 'coherent';
            obj.PulseCombineGen.MultiPulseBasePulsePhaseInDegrees = 0;

            obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB = 0;
            obj.PulseCombineGen.MultiPulseTimeShiftInS = 0;
        end
                
		function pulseStructureOut = CreatePulseStructure(obj)
            % If any of the start time, powers, transition types, or base
            % phases are larger than one, create N pulse structures to that
            % length and do a repeat of everything else
            
            
            if ~iscell(obj.PulseCombineGen.MultiPulseTransitionType)
                obj.PulseCombineGen.MultiPulseTransitionType = {obj.PulseCombineGen.MultiPulseTransitionType};
            end
            
            numPulse = max([length(obj.PulseCombineGen.MultiPulseStartTimeInSeconds)...
                length(obj.PulseCombineGen.MultiPulseBasePulseAmplitudeInDB)...
                length(obj.PulseCombineGen.MultiPulseTransitionType)...
                length(obj.PulseCombineGen.MultiPulseBasePulsePhaseInDegrees)]);

            if numPulse == 1
                % CreatePulseStructure  Creates a pulse structure for combining
                pulseStructureOut = struct(...
                                    'startTime', obj.PulseCombineGen.MultiPulseStartTimeInSeconds,...
                                    'basePower', obj.PulseCombineGen.MultiPulseBasePulseAmplitudeInDB,...
                                    'transitionType', obj.PulseCombineGen.MultiPulseTransitionType,...
                                    'basePhase', obj.PulseCombineGen.MultiPulseBasePulsePhaseInDegrees,...
                                    'sampleRate', obj.Instrument.SampleRateInHz,...
                                    'PRI', obj.PulseGen.PulseDwellInSeconds,...
                                    'PW', obj.PulseGen.PulseWidthInSeconds,...
                                    'riseTime', obj.PulseGen.PulseRiseTimeInSeconds,...
                                    'fallTime', obj.PulseGen.PulseFallTimeInSeconds,...
                                    'pulseShape', obj.PulseGen.PulseShape,...
                                    'span', obj.PulseGen.PulseModulationFrequencySpan,...
                                    'offset', obj.PulseGen.PulseFrequencyOffsetInHz,...
                                    'amplitude', obj.PulseGen.PulseAmplitudeInDB,...
                                    'fmFormula', obj.PulseGen.PulseFrequencyModulationFormula,...
                                    'pmFormula', obj.PulseGen.PulsePhaseModulationFormula,...
                                    'exactPRI', 0, ...
                                    'modulationType', obj.PulseGen.PulseModulationType,...
                                    'correction', obj.Correction.UseCorrection,...
                                    'delay', obj.PulseGen.PulseDelayInSeconds,...
                                    'phase', obj.PulseGen.PulsePhaseInDegrees,...
                                    'continuousPhase', obj.PulseGen.PulsePhaseTransitionState,...
                                    'channelMapping', obj.Instrument.ChannelMapping);
            else
                % extend all the other parameter vectors to match the number of pulses
                multiPulseStartTimeInSeconds = obj.fixlength(obj.PulseCombineGen.MultiPulseStartTimeInSeconds, numPulse);
                multiPulseBasePulseAmplitudeInDB = obj.fixlength(obj.PulseCombineGen.MultiPulseBasePulseAmplitudeInDB, numPulse);
                multiPulseBasePulsePhaseInDegrees = obj.fixlength(obj.PulseCombineGen.MultiPulseBasePulsePhaseInDegrees, numPulse);
                
                if ~iscell(obj.PulseCombineGen.MultiPulseTransitionType)
                    obj.PulseCombineGen.MultiPulseTransitionType = {obj.PulseCombineGen.MultiPulseTransitionType};
                end
                multiPulseTransitionType = obj.fixlength(obj.PulseCombineGen.MultiPulseTransitionType, numPulse);
                
                
                % Create N structures of pulses
                pulseStructureOut = [];
                
                for pulseIdx = 1:numPulse
                    pulseStructureOut = [pulseStructureOut; struct(...
                                    'startTime', multiPulseStartTimeInSeconds(pulseIdx),...
                                    'basePower', multiPulseBasePulseAmplitudeInDB(pulseIdx),...
                                    'transitionType', multiPulseTransitionType(pulseIdx),...
                                    'basePhase', multiPulseBasePulsePhaseInDegrees(pulseIdx),...
                                    'sampleRate', obj.Instrument.SampleRateInHz,...
                                    'PRI', obj.PulseGen.PulseDwellInSeconds,...
                                    'PW', obj.PulseGen.PulseWidthInSeconds,...
                                    'riseTime', obj.PulseGen.PulseRiseTimeInSeconds,...
                                    'fallTime', obj.PulseGen.PulseFallTimeInSeconds,...
                                    'pulseShape', obj.PulseGen.PulseShape,...
                                    'span', obj.PulseGen.PulseModulationFrequencySpan,...
                                    'offset', obj.PulseGen.PulseFrequencyOffsetInHz,...
                                    'amplitude', obj.PulseGen.PulseAmplitudeInDB,...
                                    'fmFormula', obj.PulseGen.PulseFrequencyModulationFormula,...
                                    'pmFormula', obj.PulseGen.PulsePhaseModulationFormula,...
                                    'exactPRI', 0, ...
                                    'modulationType', obj.PulseGen.PulseModulationType,...
                                    'correction', obj.Correction.UseCorrection,...
                                    'delay', obj.PulseGen.PulseDelayInSeconds,...
                                    'phase', obj.PulseGen.PulsePhaseInDegrees,...
                                    'continuousPhase', obj.PulseGen.PulsePhaseTransitionState,...
                                    'channelMapping', obj.Instrument.ChannelMapping)];
                    
                end
            end                       
        end
        
        function x = fixlength(obj, x, len)
        % make a vector with <len> elements by duplicating or cutting <x> as
        % necessary
            x = reshape(x, 1, length(x));
            x = repmat(x, 1, ceil(len / length(x)));
            x = x(1:len);
        end
                                          
        %% Tone generation methods
        
        function DefaultTone(obj)
            % DefaultTone - reset tone parameters
            
            obj.ToneGen.ToneFrequency = 100e6;       % frequency in Hz
            obj.ToneGen.ToneMagnitude = 0;           % dbFS
            obj.ToneGen.TonePhase = 'Random';        % phase relation between tones
            obj.ToneGen.ToneNormalize = 1;           % 1: scale to full DAC range, 0: use ToneMagnitude as dBFS
        end
        
        %% RF Tuning methods
        
        function TuneRF(obj, carrierFrequencyIn, carrierAmplitudeIn, outputOnIn)
           % TuneRF  Tunes a signal to the specific frequency and
           % power, and amplitude
           
           % Since the commands are rather similar and simple, just respond
           % to case structures for now
            switch lower(obj.Instrument.Type)
                case 'signalgenerator'  % Signal generator
                    
                    % Connect
                    arbConfig = loadArbConfig();
                    f = iqopen(arbConfig);
                    if (isempty(f))
                        return;
                    end
                    
                    % Send the commands
                    try
                        fprintf(f, [':SOURce:FREQuency ' num2str(carrierFrequencyIn)]);
                        fprintf(f, [':POWer ' num2str(carrierAmplitudeIn)]);
                        fprintf(f, [':OUTPut:STATe ' num2str(outputOnIn)]);
                    catch
                        
                    end
                    
                    % Close
                    fclose(f);delete(f);  
                    
                otherwise
            end
            
        end
        
        %% Command parsing methods
                
        function parseReceivedDataAndReact(obj, tcpipObj, ~)
            % parseReceivedDataAndReact parses the received data and decides what to do with the commands
            
            % fscanf may not read to the end of line
            % dataIn = strtrim(fscanf(tcpipObj, '%c', tcpipObj.BytesAvailable));
            dataIn = strtrim(fgetl(tcpipObj));
            
            if (obj.Server.DebugMode)
                fprintf('recv: %s\n', dataIn);
            end
            
            if (~isempty(dataIn))
                obj.parseCommandData(dataIn);
            end
        end        
        
        
%         function [isCommand, valueOut] = equateOrReturn(obj, dataIn, variableToParseIn, variableType)
%             % equateOrReturn    Decide whether to set or return value 
%             isCommand = false;
%             valueOut = variableToParseIn;
%             
%             if contains(dataIn, '?')  % Returning                
%                 switch variableType
%                     case 'double'
%                         fprintf(obj.Server.ServerInstance, num2str(variableToParseIn));
%                         isCommand = true;
%                     case 'string'
%                         fprintf(obj.Server.ServerInstance, variableToParseIn);
%                         isCommand = true;
%                     case 'cell'
%                         fprintf(obj.Server.ServerInstance, variableToParseIn);
%                         isCommand = true;
%                    case 'bool'
%                         if variableToParseIn > 0
%                             variableToParseIn = 1;
%                         else
%                             variableToParseIn = 0;
%                         end
%                         
%                         fprintf(obj.Server.ServerInstance, num2str(variableToParseIn));
%                         isCommand = true;
%                 end  
%             else  % Setting
%                 splitCommand = strsplit(dataIn, ' ');                
%                 if length(splitCommand) > 1
%                     switch variableType
%                         case 'double'
%                             valueOut = double(str2num(splitCommand{2}));
%                             isCommand = true;
%                         case 'string'
%                             splitCommand = strjoin(splitCommand(2:length(splitCommand)));
%                             valueOut = strrep(splitCommand, newline, '');
%                             
%                             while (valueOut(end) == ' ' || valueOut(end) == sprintf('\r'))
%                                 valueOut = valueOut(1:end-1);
%                             end
%                             
%                             isCommand = true;
%                         case 'cell'
%                             splitCommand = strjoin(splitCommand(2:length(splitCommand)));
%                             valueOut = strrep(splitCommand, newline, '');
%                             
%                             while (valueOut(end) == ' ' || valueOut(end) == sprintf('\r'))
%                                 valueOut = valueOut(1:end-1);
%                             end
%                             
%                             valueOut = eval(valueOut);
%                             isCommand = true;
%                         case 'bool'
%                             valueOut = str2double(splitCommand{2});
%                             
%                             if valueOut > 0
%                                 valueOut = 1;
%                             else
%                                 valueOut = 0;
%                             end
%                             
%                             isCommand = true;
%                     end  
%                 end
%             end            
%         end
        
                
        function sendResponse(obj, s)
            % send a response to a query
            fprintf(obj.Server.ServerInstance, '%s\n', s);
        end
        
                               
        function setget(obj, varName, type)
            % set or get the value of variable <varName> (Note: pass <varName> as a string!)
            % to be done: check for correct data type (<type>)
            
            if (isempty(obj.Server.ParseNext))
                obj.setError('syntax error (expected a "?" or a parameter after a command)');
            else
                switch obj.Server.ParseNext(1)           
                    case ' ' % command
                        val = strtrim(obj.Server.ParseNext);
                        switch type
                            case 'string'
                                % if the argument is not enclosed in quotes, add them
                                if (~isempty(val) && val(1) ~= '''')
                                    val = ['''' val ''''];
                                end
                            case 'cell'
                                % if the argument is not enclosed in {...}, add them
                                if (~isempty(val) && val(1) ~= '{')
                                    val = ['{' val '}'];
                                end
                            case 'double'
                                % if the argument is not enclosed in [...], add them
                                if (~isempty(val) && val(1) ~= '[')
                                    val = ['[' val ']'];
                                end
                        end

                        if (obj.Server.DebugMode)
                            fprintf('setget: %s = %s\n', varName, val);
                        end
                        try
                            % make the variable assignment
                            % (ideally, I'd like to use "assignin", but can't
                            % figure out how to do this with class members)
                            eval([varName '=' val ';']);
                        catch ex
                            obj.setError(['cannot parse parameter: ' ex.message]);
                        end
                    case '?' % query
                        retVal = obj.toString(eval(varName));
                        if (obj.Server.DebugMode)
                            fprintf('setget: %s --> %s\n', varName, retVal);
                        end
                        fprintf(obj.Server.ServerInstance, '%s\n', retVal);
                    otherwise
                        obj.setError('syntax error (expect "?" or " " after command)');
                end % switch
            end % isempty
        end % function
        
                
        function found = parseToken(obj, s)
            % check, if the next token in the command line equals <s>
            % if yes, return true and advance the ParseNext pointer; otherwise return false.
            [token, remainder] = strtok(obj.Server.ParseNext, ':? ');
            % consider a match if delimiter is a ":" and <s> equals the
            % beginning of the next token (e.g. PULS would also match :PULSE)
            found = (~isempty(obj.Server.ParseNext) && obj.Server.ParseNext(1) == ':' && strncmpi(s, token, length(s)));
            % if a match is found, advance ParseNext
            if (found)
                obj.Server.ParseNext = remainder;
            end
        end
        
                
        function setError(obj, s)
            % add an error to the error queue
            obj.Server.ErrorQueue{end + 1} = strtrim(strrep(s, newline, ''));
        end
        
                
        function setCommandError(obj)
            % report an "unknown command" error
            obj.setError(['unknown command: ' obj.Server.CurrentCommand]);
        end
        
        
        function setQueryOnlyError(obj)
            % report a "query only" error
            obj.setError('this command is only available as query');
        end
        
        
        function setCommandOnlyError(obj)
            % report a "command only" error
            obj.setError('this command is only available as a command');
        end
        
                                      
        function parseCommandData(obj, dataIn)
            % parseCommandData  Parses the command
                        
            isCommand = false;
            % initialize the parsing process
            obj.Server.CurrentCommand = dataIn;
            obj.Server.ParseNext = dataIn;

            % Check if generic command
            if dataIn(1) == '*'
                % Standard SCPI
                isCommand = obj.parseGenericData(dataIn);              
            else  
                try
                    if obj.parseToken('INST')  % Instrument specific
                      isCommand = obj.parseInstrumentCommands(dataIn);
                    elseif obj.parseToken('GEN')  % Signal generation commands
                      isCommand = obj.parseGenerateCommands(dataIn);
                    elseif obj.parseToken('SYST')  % System level commands
                      isCommand = obj.parseSystemCommands(dataIn);
                    elseif obj.parseToken('SCRIPT')  % Scripting commands
                      isCommand = obj.parseScriptingCommands(dataIn);
                    elseif obj.parseToken('CAL')  % Calibration commands
                      isCommand = obj.parseCalibrationCommands(dataIn);
                    end
                
                catch ex
                    disp(getReport(ex));
                    isCommand = false;
                end
            end
                
            if isCommand ~= true                
                % If the command contains null data, try and modify and
                % test once more
                if any(contains(dataIn, sprintf('\0')))
                    obj.parseCommandData(strrep(dataIn, sprintf('\0'), ''))
                else
                    fprintf('command error: %s\n', dataIn);
                    obj.setCommandError();
                end                
            end
        end
                
        %% Calibration methods
        
        function executeCQMCalibration(obj)
           
            % Generate the tones for a calibration based on the given
            % parameters
            
            % Get the tone count, frequencies, magnitudes
            toneCount =...
                round(obj.Calibration.ComplexCalibrationSpanInHz / obj.Calibration.ComplexCalibrationSpacingInHz) + 1;
            
            toneFrequencies =...
                linspace(-1 * (obj.Calibration.ComplexCalibrationSpanInHz / 2),...
                (obj.Calibration.ComplexCalibrationSpanInHz / 2), toneCount) ;
            
            toneMagnitudes = zeros(1, toneCount);
            
            % Generate an initial array of tones
            [iqdata, freq, magnitude, phase, chMap] = iqtone('sampleRate', obj.Instrument.SampleRateInHz, 'numSamples', 0, ...
            'tone', toneFrequencies, 'phase', 'Parabolic', 'normalize', 1, ...
            'magnitude', toneMagnitudes, 'correction', 0, 'channelMapping', obj.Instrument.ChannelMapping);
        
            % If recalibrating
            if obj.Calibration.Recalibrate
                [iqdata, ~, ~, ~, chMap] = iqtone('sampleRate', obj.Instrument.SampleRateInHz, 'numSamples', 0, ...
                'tone', toneFrequencies, 'phase', 'Parabolic', 'normalize', 1, ...
                'magnitude', toneMagnitudes, 'correction', 1, 'channelMapping', obj.Instrument.ChannelMapping);
            end
            
            % Download them
            if obj.Calibration.Initialize
                iqdownload(iqdata, obj.Instrument.SampleRateInHz, 'channelMapping', chMap,...
                    'segmentNumber', obj.Instrument.SegmentNumber, 'segmname', obj.Instrument.SegmentName,...
                    'loamplitude', obj.Instrument.RFAmplitude, 'lofcenter', obj.Instrument.RFFrequency);
            end
            
            % Perform the calibration
            iqvsacqm('recalibrate', obj.Calibration.Recalibrate,...
                'tone', freq, 'mag', magnitude, 'phase', phase, 'fc', obj.Calibration.ComplexCalibrationCenterFrequencyInHz,...
                'usefile', false, 'initialize', obj.Calibration.Initialize, 'settletime', obj.Calibration.ComplexCalibrationSettleTimeInS,...
                'autorange', obj.Calibration.AutoRange, 'rangeindbm', obj.Calibration.RangeInDBm);            
        end
        
        %% Command documentation methods
        
        function DocumentCommandDataTextFile(obj, filePathIn)
            % DocumentCommandData   Saves the commands to the file in plain text
            
            % First open this file
            fileReadPath = mfilename('fullpath');
            
            if ~endsWith(fileReadPath, '.m')
                fileReadPath = [fileReadPath '.m'];
            end
            
            if obj.Server.DebugMode
                disp(['Reading file: ' fileReadPath])
            end
            
            fileRead = fileread(fileReadPath);
                        
            % Now break the file apart by commands and write to them
            matchStringBreak = 'break';
            matchStringCommands = 'document';
            matchStringName = 'command';
            matchStringType = 'type';
            matchStringDescription = 'description';
            matchStringExample = 'example';
            
            % List of documented commands
            commandDocumentation = regexp(fileRead,...
                ['<' matchStringCommands '>(.*?|\n)*?<\/' matchStringCommands '>'], 'tokens');
            
            % For each, write the markup'd text
            commandDocumentLength = length(commandDocumentation);
            
            if obj.Server.DebugMode
                disp(['Command count: ' num2str(commandDocumentLength)])
            end
            
            if commandDocumentLength > 0
                                
                % Create a file
                fileWrite = fopen(filePathIn, 'w');
                fprintf(fileWrite, ['Command Set' newline newline]);
                
                if obj.Server.DebugMode
                    disp(['Creating file: ' filePathIn])
                end
                
                if obj.Server.DebugMode
                    disp('Documenting commands...')
                end
                
                for commandIndex = 1:commandDocumentLength
                    commandStringDocument = '';
                    
                    % See if there is a break
                    
                    commandBreak = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringBreak '>(.*?|\n)*?<\/' matchStringBreak '>'], 'tokens');
                        
                    if ~isempty(commandBreak)
                        commandStringDocument = ['----------------------------------------'...
                            newline commandBreak{1}{1} newline newline];
                    end
                                   
                    try                    
                        % Get the command
                        commandName = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringName '>(.*?|\n)*?<\/' matchStringName '>'], 'tokens');

                        commandStringDocument = [commandStringDocument 'Command: ' commandName{1}{1} newline];

                        % Then the type
                        commandType = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringType '>(.*?|\n)*?<\/' matchStringType '>'], 'tokens');

                        commandStringDocument = [commandStringDocument 'Type: ' commandType{1}{1} newline];
                        
                        % Then the description
                        commandDescription = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringDescription '>(.*?|\n)*?<\/' matchStringDescription '>'], 'tokens');

                        commandStringDocument = [commandStringDocument 'Description: ' commandDescription{1}{1} newline];
                        
                        % Then the example
                        commandExample = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringExample '>(.*?|\n)*?<\/' matchStringExample '>'], 'tokens');

                        commandStringDocument = [commandStringDocument 'Example: ' commandExample{1}{1} newline newline];
                        
                    catch
                        
                    end
                    
                    if obj.Server.DebugMode
                        disp(commandStringDocument)
                    end
                    
                    % Write to the file
                    fprintf(fileWrite, commandStringDocument);
                end
                
                % Close the file
                fclose(fileWrite);
                
                if obj.Server.DebugMode
                    disp('File document complete')  
                end
                
                disp(['Documented commands saved to ' filePathIn])
            end            
        end
                    
        function DocumentCommandDataHTMLFile(obj)
            % DocumentCommandDataHTMLFile   Saves the commands to the file in plain text
            
            filePathDocumentationHTML = 'IQToolsServerCommands.html';
            
            % First open this file
            fileReadPath = mfilename('fullpath');
            
            if ~endsWith(fileReadPath, '.m')
                fileReadPath = [fileReadPath '.m'];
            end
            
            if obj.Server.DebugMode
                disp(['Reading file: ' fileReadPath]);
            end
            
            fileRead = fileread(fileReadPath);
                        
            % Now break the file apart by commands and write to them
            matchStringBreak = 'break';
            matchStringCommands = 'document';
            matchStringName = 'command';
            matchStringType = 'type';
            matchStringDescription = 'description';
            matchStringExample = 'example';
            
            % List of documented commands
            commandDocumentation = regexp(fileRead,...
                ['<' matchStringCommands '>(.*?|\n)*?<\/' matchStringCommands '>'], 'tokens');
            
            % For each, write the markup'd text
            commandDocumentLength = length(commandDocumentation);
            
            if obj.Server.DebugMode
                disp(['Command count: ' num2str(commandDocumentLength)]);
            end
            
            if commandDocumentLength > 0
                                
                % Create a file
                fileWrite = fopen(filePathDocumentationHTML, 'w');
                fprintf(fileWrite, ['<HTML><HEAD><TITLE>IQTools Server Command Set</TITLE></HEAD>' newline]);
                fprintf(fileWrite, ['<HR><H1>IQTools Server Command Set</H1>' newline]);
                fprintf(fileWrite, ['<H3>' obj.Server.ModelString '</H3>' newline]);
                
                if obj.Server.DebugMode
                    disp(['Creating file: ' filePathDocumentationHTML])
                end
                
                if obj.Server.DebugMode
                    disp('Documenting commands...')
                end
                
                for commandIndex = 1:commandDocumentLength
                    commandStringDocument = '';
                    
                    % See if there is a break                    
                    commandBreak = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringBreak '>(.*?|\n)*?<\/' matchStringBreak '>'], 'tokens');
                        
                    if ~isempty(commandBreak)
                        commandStringDocument = ['<hr><H2>' commandBreak{1}{1} '</H2>' newline];
                                        
                    else
                        try                    
                            % Get the command
                            commandName = regexp(commandDocumentation{commandIndex}{1},...
                                ['<' matchStringName '>(.*?|\n)*?<\/' matchStringName '>'], 'tokens');

                            commandStringDocument = [commandStringDocument '<P><B>Command: ' strrep(strrep(commandName{1}{1},'<','&#60;'), '>','&#62;') '</B>' newline];

                            % Then the type
                            commandType = regexp(commandDocumentation{commandIndex}{1},...
                                ['<' matchStringType '>(.*?|\n)*?<\/' matchStringType '>'], 'tokens');

                            commandStringDocument = [commandStringDocument '<BR>Type: ' commandType{1}{1} newline];

                            % Then the description
                            commandDescription = regexp(commandDocumentation{commandIndex}{1},...
                                ['<' matchStringDescription '>(.*?|\n)*?<\/' matchStringDescription '>'], 'tokens');

                            commandStringDocument = [commandStringDocument '<BR>Description: ' commandDescription{1}{1} newline];

                            % Then the example
                            commandExample = regexp(commandDocumentation{commandIndex}{1},...
                                ['<' matchStringExample '>(.*?|\n)*?<\/' matchStringExample '>'], 'tokens');

                            commandStringDocument = [commandStringDocument '<BR>Example: ' commandExample{1}{1} newline newline];

                        catch

                        end
                    end
                    
                    if obj.Server.DebugMode
                        disp(commandStringDocument)
                    end
                    
                    % Write to the file
                    fprintf(fileWrite, commandStringDocument);
                end
                
                % Add the last tags
                fprintf(fileWrite, '</HR></HTML>');
                
                % Close the file
                fclose(fileWrite);
                
                % Open the file
                winopen(filePathDocumentationHTML);
                
                if obj.Server.DebugMode
                    disp('File document complete')  
                end
                
                disp(['Documented commands saved to ' filePathDocumentationHTML])
            end            
        end
        
        %% Parse * commands
        
        function isCommand = parseGenericData(obj, dataIn)   
            % parseGenericData  Parses generic commands (*)
            
            % <document>
            % <break>Generic Commands (*)</break>
            % </document>
            
            isCommand = true;
        
            if contains(dataIn, 'IDN?')
                % <document>
                % <command>*IDN?</command>
                % <type>Query Only</type>
                % <description>Returns the name and version of the server</description>
                % <example>*IDN?</example>
                % </document>
                fprintf(obj.Server.ServerInstance, obj.Server.ModelString);               
            elseif contains(dataIn, 'OPC?')
                % <document>
                % <command>*OPC?</command>
                % <type>Query Only</type>
                % <description>Returns a '1' when all operations are complete</description>
                % <example>*OPC?</example>
                % </document>
                fprintf(obj.Server.ServerInstance, '1');
            elseif contains(dataIn, 'RST')
                % <document>
                % <command>*RST</command>
                % <type>Send Only</type>
                % <description>Resets the server to its default values</description>
                % <example>*RST</example>
                % </document>
                obj.Reset();
            elseif contains(dataIn, 'CLS')
                % <document>
                % <command>*CLS</command>
                % <type>Send Only</type>
                % <description>Clears the error queue</description>
                % <example>*CLS</example>
                % </document>
                obj.Server.ErrorQueue = {'0'};
            else
                isCommand = false;
            end
        end
        
        %% Parse INST commands
        
        function isCommand = parseInstrumentCommands(obj, dataIn)
            % parseInstrumentCommands  Parses instrument commands (:INST)
            
            % <document>
            % <break>Instrument Commands (:INST)</break>
            % </document>
            
            isCommand = true;
        
            if obj.parseToken('MODE')
                if (obj.Server.ParseNext(1) == '?')
                    % <document>
                    % <command>:INST:MODE <Mode String></command>
                    % <type>Send and Query</type>
                    % <description>Gets or sets the server's instrument mode (N5194A_250MHz, N5194A_2GHz, M8190A_12bit, M8190A_14bit)</description>
                    % <example>:INST:MODE?; :INST:MODE N5194A_250MHz</example>
                    % </document>
                    acs = loadArbConfig();
                    switch (acs.model)
                        case 'N5194A_2GHz'; model = 'Wideband Vector';
                        case 'N5194A_250MHz'; model = 'Vector';
                        case 'N5194A_250MHz_In'; model = 'Vector Internal';                            
                        otherwise; model = acs.model;
                    end
                    obj.Instrument.ModeString = model;
                    obj.sendResponse(model);
                elseif contains(dataIn, ' Wideband Vector')  % UXG 2GHz Mode
                    obj.Instrument.ModeString = 'Wideband Vector';
                    obj.setMode('N5194A_2GHz');
                    obj.DefaultPulse()
                elseif contains(dataIn, ' Vector Internal')  % UXG 250MHz Mode
                    obj.Instrument.ModeString = 'Vector Internal';
                    obj.setMode('N5194A_250MHz_In');
                    obj.DefaultPulse()
                elseif contains(dataIn, ' Vector')  % UXG 250MHz Mode
                    obj.Instrument.ModeString = 'Vector';
                    obj.setMode('N5194A_250MHz');
                    obj.DefaultPulse()
                else                                % use whatever is being passed
                    obj.Instrument.ModeString = strtrim(obj.Server.ParseNext);
                    obj.setMode(obj.Instrument.ModeString);
                    obj.DefaultPulse()
                end
            elseif obj.parseToken('SCPI')
                % <document>
                % <command>:INST:SCPI <SCPI Command String></command>
                % <type>Send Only</type>
                % <description>Sends a SCPI command to the configured instrument</description>
                % <example>:INST:SCPI *RST</example>
                % </document>
                if ~isempty(obj.Instrument.InstrumentPathArray)
                    dataSend = strsplit(dataIn, ':SCPI ');
                    dataSend = dataSend{2};
                    
                    for idx = 1:length(obj.Instrument.InstrumentPathArray)
                        try
                            if ~isempty(obj.Instrument.InstrumentPathArray{idx})
                                % Send the command
                                serverTemp = tcpip(obj.Instrument.InstrumentPathArray{idx}, 5025);
                                serverTemp.InputBufferSize = 10000;
                                serverTemp.OutputBufferSize = 10000;
                                serverTemp.Terminator = {'LF', 'LF'};
                                fopen(serverTemp);
                                fprintf(serverTemp, dataSend);
                                fclose(serverTemp);
                                delete(serverTemp);
                            end
                       catch ex
                           obj.Server.ErrorQueue{end + 1} = ['Error sending SCPI: ' ex.message];                                                  
                       end
                    end                    
                else
                    obj.Server.ErrorQueue{end + 1} = 'Error sending SCPI: No instruments specified';
                end
            elseif obj.parseToken('CHMAP')  % Set the channel mapping
                % <document>
                % <command>:INST:CHMAP <Channel Map String></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the configured instrument's channel mapping</description>
                % <example>:INST:CHMAP?; :INST:CHMAP [1 0; 0 1]</example>
                % </document>
                obj.setget('obj.Instrument.ChannelMapping', 'double');
                if (ischar(obj.Instrument.ChannelMapping))
                    % in case channel mapping was enclosed in quotes
                    obj.Instrument.ChannelMapping = eval(obj.Instrument.ChannelMapping);
                end
            elseif obj.parseToken('SNUM')  % Set/get the segment number
                % <document>
                % <command>:INST:SNUM <segmentNumber></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the segment number into which a waveform is downloaded</description>
                % <example>:INST:SNUM?; :INST:SNUM 1</example>
                % </document>
                obj.setget('obj.Instrument.SegmentNumber', 'double');
            elseif obj.parseToken('SNAME')  % Set/get the segment name
                % <document>
                % <command>:INST:SNAME <segmentName></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the segment name that is used for download</description>
                % <example>:INST:SNAME?; :INST:SNAME 'waveform001'</example>
                % </document>
                obj.setget('obj.Instrument.SegmentName', 'string');
            elseif obj.parseToken('FTYPE')  % Set the file save type
                % <document>
                % <command>:INST:FTYPE <Channel Map String></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the server's file save type</description>
                % <example>:INST:FTYPE?; :INST:FTYPE '16-bit I/Q MSB'</example>
                % </document>
                obj.setget('obj.Instrument.FileSaveType', 'string');
            elseif obj.parseToken('CORR')  % Set the corrections
                % <document>
                % <command>:INST:CORR <0 or 1></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the if corrections are enabled</description>
                % <example>:INST:CORR?; :INST:CORR 1</example>
                % </document>
                obj.setget('obj.Correction.UseCorrection', 'double');
            elseif obj.parseToken('FCORR')  % Set the correction file path
                % <document>
                % <command>:INST:FCORR <File Path></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the correction file path, which overwrites the current file present</description>
                % <example>:INST:FCORR?; :INST:FCORR 'ampCorr.mat'</example>
                % </document>
                obj.setget('obj.Correction.CorrectionFilePath', 'string');
                
                % Load the file
                try
                    copyfile(obj.Correction.CorrectionFilePath, iqampCorrFilename());
                catch ex
                    obj.setError(['cannot load correction file: ' ex.message]);
                end
            elseif obj.parseToken('RFFREQ')  % Set upconverting frequency
                % <document>
                % <command>:INST:RFFREQ <Frequency in Hz></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the carrier frequency for the signal if using a signal generator</description>
                % <example>:INST:RFFREQ?; :INST:RFFREQ 4E9</example>
                % </document>
                obj.setget('obj.Instrument.RFFrequency', 'double');
                
                try
                    obj.TuneRF(obj.Instrument.RFFrequency, obj.Instrument.RFAmplitude, obj.Instrument.RFOn)
                catch ex
                    obj.setError(['cannot tune to frequency: ' ex.message]);
                end
            elseif obj.parseToken('RFPOW')  % Set upconverting frequency
                % <document>
                % <command>:INST:RFPOW <Power in dBm></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the carrier power for the signal if using a signal generator</description>
                % <example>:INST:RFPOW?; :INST:RFPOW -20</example>
                % </document>
                obj.setget('obj.Instrument.RFAmplitude', 'double');
                
                try
                    obj.TuneRF(obj.Instrument.RFFrequency, obj.Instrument.RFAmplitude, obj.Instrument.RFOn)
                catch ex
                    obj.setError(['cannot set amplitude: ' ex.message]);
                end
            elseif obj.parseToken('RFON')  % Set upconverting state
                % <document>
                % <command>:INST:RFON <0 or 1></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the carrier output state</description>
                % <example>:INST:RFON?; :INST:RFON 1</example>
                % </document>
                obj.setget('obj.Instrument.RFOn', 'double');
                
                try
                    obj.TuneRF(obj.Instrument.RFFrequency, obj.Instrument.RFAmplitude, obj.Instrument.RFOn)
                catch ex
                    obj.setError(['cannot set amplitude: ' ex.message]);
                end
            else
                isCommand = false;
            end
        end
        
        %% Parse CAL commands
        
        function isCommand = parseCalibrationCommands(obj, dataIn)
            % parseCalibrationCommands  Parses calibration commands (:CAL)
            
            % <document>
            % <break>Calibration Commands (:CAL)</break>
            % </document>
            
            isCommand = true;
        
            if obj.parseToken('TYPE')  % Set the cal type
                % <document>                
                % <command>:CAL:TYPE <Calibration Type></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current calibration type to perform</description>
                % <example>:CAL:TYPE?; :CAL:TYPE vsachannel</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationType', 'string');
            elseif obj.parseToken('FSPAN')  % Set the span
                % <document>                
                % <command>:CAL:FSPAN <Span in Hz></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current calibration's frequency span in Hz</description>
                % <example>:CAL:FSPAN?; :CAL:FSPAN 1E9</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationSpanInHz', 'double');
            elseif obj.parseToken('FSPAC')  % Set the spacing
                % <document>                
                % <command>:CAL:FSPAC <Spacing in Hz></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current calibration's frequency spacing in Hz</description>
                % <example>:CAL:FSPAC?; :CAL:FSPAC 1E6</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationSpacingInHz', 'double');
            elseif obj.parseToken('FOFFS')  % Set the frequency offset
                % <document>                
                % <command>:CAL:FOFFS <Offset in Hz></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current calibration's frequency offset in Hz (useful to avoid LO feedthru)</description>
                % <example>:CAL:FOFFS?; :CAL:FOFFS 10E3</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationOffsetInHz', 'double');
            elseif obj.parseToken('FCENT')  % Set the tune frequency
                % <document>                
                % <command>:CAL:FCENT <Tune Frequency in Hz></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current calibration's center frequency in Hz</description>
                % <example>:CAL:FCENT?; :CAL:FCENT 10E9</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationCenterFrequencyInHz', 'double');
            elseif obj.parseToken('TSETT')  % Set the settling time for the measurement
                % <document>                
                % <command>:CAL:TSETT <Cal Measurement Time in S></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current calibration's measurement time in S</description>
                % <example>:CAL:TSETT?; :CAL:TSETT 2.5</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationSettleTimeInS', 'double');
            elseif obj.parseToken('FSAV')  % Set the cal save file path
                % <document>                
                % <command>:CAL:FSAV <Calibration file save path></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the file path a calibration file will be saved to</description>
                % <example>:CAL:FSAV?; :CAL:FSAV Cal_Save_FC_1E9</example>
                % </document> 
                obj.setget('obj.Calibration.CalibrationSavePath', 'string');
            elseif obj.parseToken('INIT')  % Set if cal initializes or just tunes and ranges
                % <document>                
                % <command>:CAL:INIT <0 or 1></command>
                % <type>Send and Query</type>
                % <description>Gets or sets whether or not the calibration runs through an initialization</description>
                % <example>:CAL:INIT?; :CAL:INIT 1</example>
                % </document> 
                obj.setget('obj.Calibration.Initialize', 'double'); 
            elseif obj.parseToken('ARANG')  % Set if cal autoranges or not
                % <document>                
                % <command>:CAL:ARANG <0 or 1></command>
                % <type>Send and Query</type>
                % <description>Gets or sets whether or not the calibration autoranges the front end</description>
                % <example>:CAL:ARANG?; :CAL:ARANG 1</example>
                % </document> 
                obj.setget('obj.Calibration.AutoRange', 'double'); 
            elseif obj.parseToken('RANG')  % Set cal manual range
                % <document>                
                % <command>:CAL:RANG <Power in dBm></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the power the calibration will range to</description>
                % <example>:CAL:RANG?; :CAL:RANG -10</example>
                % </document> 
                obj.setget('obj.Calibration.RangeInDBm', 'double'); 
            elseif obj.parseToken('EXE')  % Execute the calibration                
                % <document>
                % <command>:CAL:EXE</command>
                % <type>Send Only</type>
                % <description>Performs a calibration based on the parameters defined</description>
                % <example>:CAL:EXE</example>
                % </document>
                isCommand = true;   
                                
                try
                    disp('Calibrating...')
                    obj.executeCQMCalibration()
                    disp('Calibration complete')
                catch ex
                    disp(['Error calibrating: ' ex.message])  
                    obj.Server.ErrorQueue{end + 1} = ['Error calibrating: ' ex.message];
                end  
            elseif obj.parseToken('SAVE')  % Save current calibration data to the defined path
                % <document>
                % <command>:CAL:SAVE</command>
                % <type>Send Only</type>
                % <description>Saves the current calibration to the defined path</description>
                % <example>:GEN:PULS:SAVE</example>
                % </document>
                isCommand = true;                    
                try
                    disp('Saving calibration data...')           
                    
                    % Copy the current correction file to the new location
                    copyfile(iqampCorrFilename(), obj.Calibration.CalibrationSavePath);
                    disp('File saved!');

                catch ex
                    disp(['Error saving file: ' ex.message])  
                    obj.Server.ErrorQueue{end + 1} = ['Error saving file: ' ex.message];
                end                
            else
                isCommand = false;
            end
        end
 
        %% Parse SYST Commands
        
        function isCommand = parseSystemCommands(obj, dataIn)
            % parseSystemCommands  Parses system commands (:SYST)
            
            % <document>
            % <break>System Commands (:SYST)</break>
            % </document>
            
            isCommand = true;   
            
            if obj.parseToken('TCPIP')
                if (strncmpi(strtrim(obj.Server.ParseNext), 'CLOS', 4))  % Close the TCPIP server and listen for new connection
                  % <document>
                  % <UDP></UDP>
                  % <command>:SYST:TCPIP:CLOS</command>
                  % <type>Send Only</type>
                  % <description>Closes the current TCPIP Server connection and listens again for a new connection</description>
                  % <example>:SYST:TCPIP:CLOS</example>
                  % </document>
                  if obj.Server.UseUDP == false
                      obj.CloseServerTCPIP()
                      % don't re-launch the server from here. This will
                      % be done from IQToolsServer_Launch
                      % obj.LaunchServerTCPIP()
                  end
               end
            elseif obj.parseToken('ERR')  % Return error or the last '0'
                % <document>
                % <command>:SYST:ERR?</command>
                % <type>Query Only</type>
                % <description>Return the last error in the error queue or '0' if no errors are present</description>
                % <example>:SYST:ERR?</example>
                % </document>
                if (obj.Server.ParseNext(1) == '?')
                    obj.sendResponse(obj.Server.ErrorQueue{end});
                    if (length(obj.Server.ErrorQueue) > 1)                    
                        obj.Server.ErrorQueue(end) = [];
                    end

                    if obj.Server.DebugMode
                       disp(['Error Queue size: ' num2str(length(obj.Server.ErrorQueue))])
                    end
                else
                    obj.setQueryOnlyError();
                end
                
            elseif obj.parseToken('DEBUG')
                % <document>
                % <command>:SYST:DEBUG <0 or 1></command>
                % <type>Send and Query</type>
                % <description>Gets or sets if debug mode is enabled</description>
                % <example>:SYST:DEBUG?; :SYST:DEBUG 1</example>
                % </document>                
                obj.setget('obj.Server.DebugMode', 'bool');
            else
                isCommand = false;
            end
        end
        
        %% Parse SCRIPT commands
        
        function isCommand = parseScriptingCommands(obj, dataIn)  
            % parseScriptingCommands    Parses scripting commands (:SCRIPT)
            
            % <document>
            % <break>Script Commands (:SCRIPT)</break>
            % </document>
            
            isCommand = false;

            if obj.parseToken('EVAL')  % Runs whatever it gets
                % <document>
                % <command>:SCRIPT:EVAL '<MATLAB syntax expression>'</command>
                % <type>Send and Query</type>
                % <description>Evaluates the expression and/or returns the expression's result</description>
                % <example>:SCRIPT:EVAL? '1 + 1'; :SCRIPT:EVAL 'plot(1:10, 2:2:20);'</example>
                % </document> 
                
                params = obj.Server.ParseNext;
                isQuery = false;
                if (params(1) == '?')
                    isQuery = true;
                    params = params(2:end);
                end
                params = strtrim(params);
                % Run it
                if obj.Server.DebugMode
                    disp(['Executing:' params])
                end
                result = [];
                try
                    if (isQuery)
                        result = eval(params);
                    else
                        % handle both quoted and unquoted commands
                        if (params(1) == '''' && params(end) == '''')
                            params = params(2:end-1);
                        end
                        eval(params);
                    end
                catch ex
                    disp(['Error executing command: ' getReport(ex,'extended')]);
                    obj.setError(['Error executing command: ' ex.message]);
                end
                % return the result of a query to the caller
                if (isQuery)
                    try
                        fprintf(obj.Server.ServerInstance, '%s\n', obj.toString(result));
                    catch ex
                        disp(getReport(ex));
                    end
                end
                isCommand = true;
            elseif obj.parseToken('COMMAND')
                if obj.parseToken('SET')  % Set the current command
                    % <document>
                    % <command>:SCRIPT:COMMAND:SET '<MATLAB syntax expression>'</command>
                    % <type>Send and Query</type>
                    % <description>Gets or sets the command to evaulate with :EXE or add to a list with :LIST:ADD</description>
                    % <example>:SCRIPT:COMMAND:SET?; :SCRIPT:COMMAND:SET 'plot(1:10, 2:2:20);'</example>
                    % </document>                
                    isCommand = true;
                    obj.setget('obj.Scripting.ScriptCommandCurrent', 'cell');
                elseif obj.parseToken('RESET')  % Reset the current command
                    % <document>
                    % <command>:SCRIPT:COMMAND:RESET</command>
                    % <type>Send Only</type>
                    % <description>Resets the current set command</description>
                    % <example>:SCRIPT:COMMAND:RESET</example>
                    % </document> 
                    isCommand = true;
                    obj.DefaultCommand();
                elseif obj.parseToken('EXE')  % Execute the current command
                    % <document>
                    % <command>:SCRIPT:COMMAND:EXE</command>
                    % <type>Send Only</type>
                    % <description>Executes the current set command</description>
                    % <example>:SCRIPT:COMMAND:EXE</example>
                    % </document> 
                    isCommand = true;
                    obj.ExecuteScriptCommandCurrent();
                end
            elseif obj.parseToken('LIST')
                if obj.parseToken('ADD')  % Add the current command to the command list
                    % <document>
                    % <command>:SCRIPT:LIST:ADD</command>
                    % <type>Send Only</type>
                    % <description>Adds the current set command to the list of commands to execute with :LIST:EXE</description>
                    % <example>:SCRIPT:COMMAND:EXE</example>
                    % </document> 
                    isCommand = true;
                    obj.setget('obj.Scripting.ScriptCommandCurrent', 'cell');
                    obj.Scripting.ScriptCommandTable = [obj.Scripting.ScriptCommandTable; obj.CreateCommandStructure()];
                elseif obj.parseToken('RESET')  % Reset the commands
                    % <document>
                    % <command>:SCRIPT:LIST:RESET</command>
                    % <type>Send Only</type>
                    % <description>Resets the list of commands</description>
                    % <example>:SCRIPT:COMMAND:RESET</example>
                    % </document> 
                    isCommand = true;
                    obj.DefaultCommandList();              
                elseif obj.parseToken('COUNT')  % Get the length of the command list
                    % <document>
                    % <command>:SCRIPT:LIST:COUNT</command>
                    % <type>Query Only</type>
                    % <description>Gets the number of commands currently in the command list</description>
                    % <example>:SCRIPT:COMMAND:LIST:COUNT?</example>
                    % </document> 
                    if (obj.Server.ParseNext(1) == '?')
                        isCommand = true;
                        fprintf(obj.Server.ServerInstance, num2str(length(obj.Scripting.ScriptCommandTable)));
                    else
                        obj.setQueryOnlyError();
                    end
                elseif obj.parseToken('EXE')  % Run the list of commands
                    % <document>
                    % <command>:SCRIPT:LIST:EXE</command>
                    % <type>Send Only</type>
                    % <description>Executes the current list of commands</description>
                    % <example>:SCRIPT:COMMAND:LIST:EXE</example>
                    % </document>
                    isCommand = true;
                    obj.ExecuteCommandList();
                end
            end
        end
        
                
        function result = toString(obj, x)
            % toString    Returns the current command as a string
            switch (class(x))
                case 'char'
                    result = sprintf('''%s''', x);
                case {'double', 'float'}
                    if (isscalar(x))
                        result = sprintf('%g', x);
                    elseif (length(size(x)) > 2)
                        result = sprintf('Error: cannot output arrays with more than 2 dimensions');
                    else
                        result = '[';
                        del = '';
                        for row = 1:size(x,1)
                            for col = 1:size(x,2)
                                result = sprintf('%s%s%g', result, del, x(row,col));
                                del = ',';
                            end
                            del = ';';
                        end
                        result = sprintf('%s]', result);
                    end
                case 'cell'
                    if (length(size(x)) > 2)
                        result = sprintf('Error: cannot output cell arrays with more than 2 dimensions');
                    else
                        result = '';
                        del = '{';
                        for row = 1:size(x,1)
                            for col = 1:size(x,2)
                                result = sprintf('%s%s%s', result, del, obj.toString(x{row,col}));
                                del = ',';
                            end
                            del = ';';
                        end
                        result = sprintf('%s}', result);
                    end
                otherwise
                    result = sprintf('Error: object of class %s', class(x));
            end
        end
                
        %% Parse GENs's (generating pulse data and saving)
        
        function isCommand = parseGenerateCommands(obj, dataIn) 
            % parseGenerateCommands    Parses generation commands (:GEN)
                        
            isCommand = false;
            
            if obj.parseToken('PULS')                
                isCommand = parsePulseGenerateCommands(obj, dataIn);
            elseif obj.parseToken('TONE')
                isCommand = parseToneGenerateCommands(obj, dataIn);
            end
        end
                
        %% Parse GEN:PULS (generating pulse data and saving)
        
        function isCommand = parsePulseGenerateCommands(obj, dataIn) 
            % parsePulseGenerateCommands    Parses pulse generation commands (:GEN)
            
            % <document>
            % <break>Pulse Generation Commands (:GEN:PULS)</break>
            % </document>
            
            isCommand = false;
        
            if obj.parseToken('COMB')  % Combining commands
                isCommand = obj.parsePulseCombineCommands(dataIn);
            elseif obj.parseToken('SRAT')  % Set the sample rate
                % <document>                
                % <command>:GEN:PULS:SRAT <Sample Rate in Hz></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's sample rate in Hz</description>
                % <example>:GEN:PULS:SRAT?; :GEN:PULS:SRAT 2E9</example>
                % </document> 
                isCommand = true;
                obj.setget('obj.Instrument.SampleRateInHz', 'double');
            elseif obj.parseToken('RESET')  % Reset the pulse parameters
                % <document>
                % <command>:GEN:PULS:RESET</command>
                % <type>Send Only</type>
                % <description>Resets the current pulse configuration to its default values</description>
                % <example>:GEN:PULS:RESET</example>
                % </document>
                isCommand = true;
                obj.DefaultPulse();
            elseif obj.parseToken('DWEL')  % Set the dwell
                % <document>
                % <command>:GEN:PULS:DWEL <Dwell Time in Seconds></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's dwell time/s (duration/s) in seconds</description>
                % <example>:GEN:PULS:DWEL?; :GEN:PULS:DWEL 100E-6; :GEN:PULS:DWEL [100E-6, 10E-6]</example>
                % </document> 
                isCommand = true;
                obj.setget('obj.PulseGen.PulseDwellInSeconds', 'double');
            elseif obj.parseToken('WIDT')  % Set the width
                % <document>
                % <command>:GEN:PULS:WIDT <Dwell Time in Seconds></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's width/s in seconds</description>
                % <example>:GEN:PULS:WIDT?; :GEN:PULS:WIDT 10E-6; :GEN:PULS:WIDT [10E-6, 1E-6]</example>
                % </document> 
                isCommand = true;
                obj.setget('obj.PulseGen.PulseWidthInSeconds', 'double');               
            elseif obj.parseToken('RISE')  % Set the rise time
                % <document>
                % <command>:GEN:PULS:RISE <Rise Time in Seconds></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's rise time/s in seconds</description>
                % <example>:GEN:PULS:RISE?; :GEN:PULS:RISE 10E-9; :GEN:PULS:RISE [10E-9, 20E-9]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseRiseTimeInSeconds', 'double');
            elseif obj.parseToken('FALL')  % Set the fall time
                % <document>
                % <command>:GEN:PULS:FALL <Fall Time in Seconds></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's fall time/s in seconds</description>
                % <example>:GEN:PULS:FALL?; :GEN:PULS:FALL 10E-9; :GEN:PULS:FALL [10E-9, 20E-9]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseFallTimeInSeconds', 'double');
            elseif obj.parseToken('DELA')  % Set the delay from start
                % <document>
                % <command>:GEN:PULS:DELA <Delay Time in Seconds></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's delay time/s in seconds</description>
                % <example>:GEN:PULS:DELA?; :GEN:PULS:DELA 10E-9; :GEN:PULS:DELA [10E-9, 20E-9]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseDelayInSeconds', 'double');
            elseif obj.parseToken('AMP')  % Set the amplitudes
                % <document>
                % <command>:GEN:PULS:AMP <Relative Amplitudes in dB></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's relative amplitude/s in dB</description>
                % <example>:GEN:PULS:AMP?; :GEN:PULS:AMP [0, -6]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseAmplitudeInDB', 'double');
            elseif obj.parseToken('PHAS')  % Set the phases
                % <document>
                % <command>:GEN:PULS:PHAS <Phase in Degrees></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's phase/s in degrees</description>
                % <example>:GEN:PULS:PHAS?; :GEN:PULS:PHAS 90; :GEN:PULS:PHAS [90, 45]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulsePhaseInDegrees', 'double');
            elseif obj.parseToken('FREQOF')  % Set the frequency offsets
                % <document>
                % <command>:GEN:PULS:FREQOF <Frequency Offset in Hz></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's frequency offset/s in Hz</description>
                % <example>:GEN:PULS:FREQOF?; :GEN:PULS:FREQOF 10E6; :GEN:PULS:FREQOF [10E6, -50E6]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseFrequencyOffsetInHz', 'double');
            elseif obj.parseToken('SHAP')  % Set the pulse shapes
                % <document>
                % <command>:GEN:PULS:SHAP <Pulse Shape String></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's pulse shape/s (Raised Cosine, Trapezodial, Gaussian, Zero signal during rise time)</description>
                % <example>:GEN:PULS:SHAP?; :GEN:PULS:SHAP Raised Cosine</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseShape', 'string');
            elseif obj.parseToken('MOD')  % Set the modulation types
                % <document>
                % <command>:GEN:PULS:MOD <Modulation Type Cell String Array></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's modulation type/s (None, Increasing, Decreasing, V-Shape, Inverted V, Barker-2 +-, Barker-2 ++, Barker-3, Barker-4 ++-+, Barker-4 +++-, Barker-5, Barker-7, Barker-11, Barker-13, Frank-4, Frank-6, FMCW)</description> 
                % <example>:GEN:PULS:MOD?; :GEN:PULS:MOD {'Increasing'}, :GEN:PULS:MOD {'Increasing', 'None'}</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseModulationType', 'cell');
            elseif obj.parseToken('FMOD')  % Set the frequency modulation formula
                % <document>
                % <command>:GEN:PULS:FMOD <MATLAB Syntax Modulation Formula></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's FM modulation formula. Use the variable "x" in the formula, which varies from 0 to 1 throughout the pulse</description> 
                % <example>:GEN:PULS:FMOD?; :GEN:PULS:FMOD cos(pi*(x-1))</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseFrequencyModulationFormula', 'string');
            elseif obj.parseToken('FSPA')  % Set the spans
                % <document>
                % <command>:GEN:PULS:FSPA <Frequency Span in Hz></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's frequency FM span/s in Hz</description>
                % <example>:GEN:PULS:FSPA?; :GEN:PULS:FSPA 10E6; :GEN:PULS:FSPA [10E6, 50E6]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseModulationFrequencySpan', 'double');
            elseif obj.parseToken('PMOD')  % Set the phase modulation formula
                % <document>
                % <command>:GEN:PULS:PMOD <MATLAB Syntax Modulation Formula></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's PM modulation formula. Use the variable "x" in the formula, which varies from 0 to 1 throughout the pulse</description> 
                % <example>:GEN:PULS:PMOD?; :GEN:PULS:PMOD zeros(1,length(x)))</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulsePhaseModulationFormula', 'string');    
            elseif obj.parseToken('PTRAN')  % Set the phase transition types
                % <document>
                % <command>:GEN:PULS:PTRAN <Phase Transition Type Cell String Array></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's phase transition type/s (Coherent, Continuous, Exact, Bump)</description>
                % <example>:GEN:PULS:PTRAN?; :GEN:PULS:PTRAN {'Continuous'}; GEN:PULS:PTRAN {'Continuous', 'Coherent'}]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulsePhaseTransitionState', 'cell');  
            elseif obj.parseToken('NORM')  % normalize
                % <document>
                % <command>:GEN:PULS:NORM <0|1></command>
                % <type>Send and Query</type>
                % <description>1: scale to full DAC range, 0: use :GEN:PULS:AMP as dbFS</description>
                % <example>:GEN:PULS:NORM?; :GEN:PULS:NORM 0</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseNormalize', 'double');
            elseif obj.parseToken('FSAV')  % Set the file save path
                % <document>
                % <command>:GEN:PULS:FSAV <File save path></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's file save path</description>
                % <example>:GEN:PULS:FSAV?; :GEN:PULS:FSAV Pulse_10_us</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseFilePathSave', 'string');
            elseif obj.parseToken('SAVE')  % Save the single pulse to a file
                % <document>
                % <command>:GEN:PULS:SAVE</command>
                % <type>Send Only</type>
                % <description>Calculates the I/Q Data for a pulse defined by its current settings, then saves to its defined path</description>
                % <example>:GEN:PULS:SAVE</example>
                % </document>
                isCommand = true; 
                try
                    disp('Saving waveform...')
                    disp(obj.PulseGen.PulseFilePathSave)
                    disp('Generating waveform IQ...')

                    [iqdata, ~, ~, ~] = obj.calculatePulse();

                    disp('IQ Generated.')
                    disp('Saving file...')

                    iqsavewaveform(iqdata, obj.Instrument.SampleRateInHz,...
                        'filename', obj.PulseGen.PulseFilePathSave,...
                        'filetype', obj.Instrument.FileSaveType)

                    disp(['File saved!' newline]);

                catch ex
                    disp(['Error saving file: ' ex.message])  
                    obj.Server.ErrorQueue{end + 1} = ['Error saving file: ' ex.message];
                end

            elseif obj.parseToken('VSA')  % Preview the single pulse in VSA
                % <document>
                % <command>:GEN:PULS:VSA</command>
                % <type>Send Only</type>
                % <description>Calculates the I/Q Data for a pulse defined by its current settings, then loads it to 89601B VSA to preview</description>
                % <example>:GEN:PULS:VSA</example>
                % </document>
                isCommand = true; 
                try
                    disp('Loading waveform to VSA...')
                    disp('Generating waveform IQ...')

                    [iqdata, ~, ~, ~] = obj.calculatePulse();

                    disp('IQ Generated.')
                    disp('Loading to VSA...')

                    vsaApp = vsafunc([], 'open');

                    if (~isempty(vsaApp))
                        vsafunc(vsaApp, 'input', 1);
                        if(isreal(iqdata))
                            iqdata = complex(iqdata); %Added if no mod
                        end

                        vsafunc(vsaApp, 'load', iqdata, obj.Instrument.SampleRateInHz);
                    end

                    disp(['File loaded!' newline]);

                catch ex
                    disp(['Error loading file to VSA: ' getReport(ex,'extended')]);
                    obj.Server.ErrorQueue{end + 1} = ['Error loading file to VSA: ' ex.message];
                end            

            elseif obj.parseToken('DOWNLOAD')  % Download to an instrument
                % <document>
                % <command>:GEN:PULS:DOWNLOAD</command>
                % <type>Send Only</type>
                % <description>Calculates the I/Q Data for a pulse defined by its current settings, then loads it to the defined instrument</description>
                % <example>:GEN:PULS:DOWNLOAD</example>
                % </document>
                isCommand = true; 
                try
                    disp('Downloading waveform...')
                    disp('Generating waveform IQ...')

                    [iqdata, marker, ~, chMap] = obj.calculatePulse();

                    disp('IQ Generated.')
                    disp('Loading to instrument...')

                    iqdownload(iqdata, obj.Instrument.SampleRateInHz, 'channelMapping', chMap,...
                        'segmentNumber', obj.Instrument.SegmentNumber, 'marker', marker, 'segmname', obj.Instrument.SegmentName);

                    disp(['File loaded!' newline]);

                catch ex
                    disp(['Error loading file to instrument: ' getReport(ex,'extended')]);
                    obj.Server.ErrorQueue{end + 1} = ['Error loading file to instrument: ' ex.message];
                end   
            else
                isCommand = false;
            end
        end
        
        
        
        function [iqdata, marker, numRepeats, chMap] = calculatePulse(obj)
            [iqdata, marker, numRepeats, chMap] = iqpulse(...
                'sampleRate', obj.Instrument.SampleRateInHz, ...
                'PRI', obj.PulseGen.PulseDwellInSeconds,...
                'PW', obj.PulseGen.PulseWidthInSeconds,...
                'riseTime', obj.PulseGen.PulseRiseTimeInSeconds, ...
                'fallTime', obj.PulseGen.PulseFallTimeInSeconds, ...
                'pulseShape', obj.PulseGen.PulseShape,...
                'span', obj.PulseGen.PulseModulationFrequencySpan, ...
                'offset', obj.PulseGen.PulseFrequencyOffsetInHz, ...
                'amplitude', obj.PulseGen.PulseAmplitudeInDB,...
                'fmFormula', obj.PulseGen.PulseFrequencyModulationFormula,...
                'pmFormula', obj.PulseGen.PulsePhaseModulationFormula, ...
                'exactPRI', 0, ...
                'modulationType', obj.PulseGen.PulseModulationType,...
                'correction', obj.Correction.UseCorrection, ...
                'delay', obj.PulseGen.PulseDelayInSeconds, ...
                'phase', obj.PulseGen.PulsePhaseInDegrees, ...
                'continuousPhase', obj.PulseGen.PulsePhaseTransitionState, ...
                'channelMapping', obj.Instrument.ChannelMapping, ...
                'normalize', obj.PulseGen.PulseNormalize);
        end


        
        %% Parse GEN:PULS:COMB's (generating combined pulses and saving)
        
        function isCommand = parsePulseCombineCommands(obj, dataIn)
            % parsePulseCombineCommands    Parses pulse combine generation commands (:GEN:COMB)
            
            % <document>
            % <break>Pulse Combining Generation Commands (:GEN:PULS:COMB)</break>
            % </document>
            
            isCommand = false;

            if obj.parseToken('RESET')  % Reset the pulse array
                % <document>
                % <command>:GEN:PULS:COMB:RESET</command>
                % <type>Send Only</type>
                % <description>Resets the current lists of pulses to combine</description>
                % <example>:GEN:PULS:COMB:RESET</example>
                % </document>
%                 if (obj.Server.ParseNext(1) == ' ')
%                     isCommand = true;
%                     obj.DefaultPulseCombo();
%                 else
%                     obj.setCommandOnlyError();
%                 end
%                 
                isCommand = true;
                obj.DefaultPulseCombo();
            elseif obj.parseToken('TSTART')  % Set start time in a combined pulse
                % <document>
                % <command>:GEN:PULS:COMB:TSTART <Start Time in Seconds></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse to combine's start time in seconds</description>
                % <example>:GEN:PULS:COMB:TSTART?; :GEN:PULS:COMB:TSTART 100E-6</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseCombineGen.MultiPulseStartTimeInSeconds', 'double');
            elseif obj.parseToken('AMP')  % Set base amplitude in a combined pulse
                % <document>
                % <command>:GEN:PULS:COMB:AMP <Amplitude in dBm></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse to combine's amplitude in dBm</description>
                % <example>:GEN:PULS:COMB:AMP?; :GEN:PULS:COMB:AMP -20</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseCombineGen.MultiPulseBasePulseAmplitudeInDB', 'double');
            elseif obj.parseToken('PTRAN')  % Set phase transition type
                % <document>
                % <command>:GEN:PULS:COMB:PTRAN <Phase Transition Type String></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse configuration's phase transition type/s (Coherent, Continuous, Exact, Bump)</description>
                % <example>:GEN:PULS:COMB:PTRAN?; :GEN:PULS:COMB:PTRAN Coherent</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseCombineGen.MultiPulseTransitionType', 'string'); 
            elseif obj.parseToken('PHAS')  % Set the phases
                % <document>
                % <command>:GEN:PULS:COMB:PHAS <Phase Offset in Degrees></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse to combine's phase offset in degrees</description>
                % <example>:GEN:PULS:COMB:PHAS?; :GEN:PULS:COMB:PHAS 90</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseCombineGen.MultiPulseBasePulsePhaseInDegrees', 'double');                
            elseif obj.parseToken('ADD')  % Add the current configured pulse to the array
                % <document>
                % <command>:GEN:PULS:COMB:ADD</command>
                % <type>Send Only</type>
                % <description>Adds the currently configured pulse combine entry to the list of pulses to combine</description>
                % <example>:GEN:PULS:COMB:ADD</example>
                % </document>
                isCommand = true;
                obj.PulseCombineGen.MultiPulseTable = [obj.PulseCombineGen.MultiPulseTable; obj.CreatePulseStructure()];
            elseif obj.parseToken('COUNT')  % Get the length of the pulse table
                % <document>
                % <command>:GEN:PULS:COMB:COUNT</command>
                % <type>Query Only</type>
                % <description>Gets the number of pulses that will be processed</description>
                % <example>:GEN:PULS:COMB:COUNT?</example>
                % </document>
                if (obj.Server.ParseNext(1) == '?')
                    isCommand = true;
                    obj.sendResponse(num2str(length(obj.PulseCombineGen.MultiPulseTable)));
                else
                    obj.setQueryOnlyError();
                end
            elseif obj.parseToken('OFFSETAMP')  % Get the offset amplitude
                % <document>
                % <command>:GEN:PULS:COMB:OFFSETAMP</command>
                % <type>Query Only</type>
                % <description>Gets the amplitude offset of the calculated pulses (if the combined pulses constructively interfere, they may clip the DAC, so the the levels are normalized and managed with an offset)</description>
                % <example>:GEN:PULS:COMB:OFFSETAMP?</example>
                % </document>
                if (obj.Server.ParseNext(1) == '?')
                    isCommand = true;
                    obj.sendResponse(num2str(obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB));
                else
                    obj.setQueryOnlyError();
                end
            elseif obj.parseToken('OFFSETTIME')  % Get the offset time
                % <document>
                % <command>:GEN:PULS:COMB:OFFSETTIME</command>
                % <type>Query Only</type>
                % <description>Gets the time offset of the calculated pulses (to save samples, the first pulse can be offset in time to zero)</description>
                % <example>:GEN:PULS:COMB:OFFSETTIME?</example>
                % </document>
                if (obj.Server.ParseNext(1) == '?')
                    isCommand = true;
                    fprintf(obj.Server.ServerInstance, num2str(obj.PulseCombineGen.MultiPulseTimeShiftInS));
                else
                    obj.setQueryOnlyError();
                end
            elseif obj.parseToken('FSAV')
                % <document>
                % <command>:GEN:PULS:COMB:FSAV <File save path></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current pulse combination configuration's file save path</description>
                % <example>:GEN:PULS:COMB:FSAV?; :GEN:PULS:COMB:FSAV Pulse_Combine_100_us</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseFilePathSave', 'string');
            elseif obj.parseToken('SAVE')  % Save to a file
                % <document>
                % <command>:GEN:PULS:COMB:SAVE</command>
                % <type>Send Only</type>
                % <description>Calculates the I/Q Data for a pulse combination defined by its current settings, then saves to its defined path</description>
                % <example>:GEN:PULS:COMB:SAVE</example>
                % </document>
                isCommand = true;                    
                try
                    [totalSamples,...
                        obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB,...
                        obj.PulseCombineGen.MultiPulseTimeShiftInS, ~] = ...
                        multi_pdw('samplerate', obj.Instrument.SampleRateInHz, ...
                            'pulsetable', obj.PulseCombineGen.MultiPulseTable, ...     
                            'correction', obj.Correction.UseCorrection, ...
                            'normalize', obj.PulseGen.PulseNormalize, ...
                            'function', 'save', ...
                            'filename', obj.PulseGen.PulseFilePathSave, ...
                            'filetype', obj.Instrument.FileSaveType, ...
                            'debugmode', obj.Server.DebugMode);

                if obj.Server.DebugMode
                    disp(['Total samples: ' num2str(totalSamples)]); 
                    disp(['Amplitude delta: ' num2str(obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB) ' dB']);   
                    disp(['Time delta: ' num2str(obj.PulseCombineGen.MultiPulseTimeShiftInS) ' s']);  
                end
                                        
                catch ex
                    disp(['Error saving file: ' getReport(ex,'extended')]);
                    obj.Server.ErrorQueue{end + 1} = ['Error saving file: ' ex.message];
                end 

            elseif obj.parseToken('VSA')  % Preview the single pulse in VSA
                % <document>
                % <command>:GEN:PULS:COMB:VSA</command>
                % <type>Send Only</type>
                % <description>Calculates the I/Q Data for a pulse combination defined by its current settings, then loads it to 89601B VSA to preview</description>
                % <example>:GEN:PULS:COMB:VSA</example>
                % </document>
                isCommand = true;                    
                try
                    [totalSamples,...
                        obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB,...
                        obj.PulseCombineGen.MultiPulseTimeShiftInS, ~] = ...
                        multi_pdw('samplerate', obj.Instrument.SampleRateInHz, ...
                            'pulsetable', obj.PulseCombineGen.MultiPulseTable, ...     
                            'correction', obj.Correction.UseCorrection, ...
                            'normalize', obj.PulseGen.PulseNormalize, ...
                            'function', 'vsa', ...
                            'debugmode', obj.Server.DebugMode, ...
                            'channelMapping', obj.Instrument.ChannelMapping);
                                        
                if obj.Server.DebugMode
                    disp(['Total samples: ' num2str(totalSamples)]); 
                    disp(['Amplitude delta: ' num2str(obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB) ' dB']);   
                    disp(['Time delta: ' num2str(obj.PulseCombineGen.MultiPulseTimeShiftInS) ' s']);  
                end

                catch ex
                    disp(['Error loading file to VSA: ' getReport(ex,'extended')]);
                    obj.Server.ErrorQueue{end + 1} = ['Error loading file to VSA: ' ex.message];
                end
                
            elseif obj.parseToken('DOWNLOAD')  % Download to an instrument
                % <document>
                % <command>:GEN:PULS:COMB:DOWNLOAD</command>
                % <type>Send Only</type>
                % <description>Calculates the I/Q Data for a pulse combination defined by its current settings, then loads it to the defined instrument</description>
                % <example>:GEN:PULS:COMB:DOWNLOAD</example>
                % </document>
                isCommand = true;                
                try
                    [totalSamples,...
                        obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB,...
                        obj.PulseCombineGen.MultiPulseTimeShiftInS, ~] = ...
                        multi_pdw('samplerate', obj.Instrument.SampleRateInHz, ...
                            'pulsetable', obj.PulseCombineGen.MultiPulseTable, ...     
                            'correction', obj.Correction.UseCorrection, ...
                            'normalize', obj.PulseGen.PulseNormalize, ...
                            'function', 'download', ...
                            'debugmode', obj.Server.DebugMode, ...
                            'channelMapping', obj.Instrument.ChannelMapping);
                                        
                if obj.Server.DebugMode
                    disp(['Total samples: ' num2str(totalSamples)]); 
                    disp(['Amplitude delta: ' num2str(obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB) ' dB']);   
                    disp(['Time delta: ' num2str(obj.PulseCombineGen.MultiPulseTimeShiftInS) ' s']);  
                end
                
                disp(['File loaded!' newline]);

                catch ex
                    disp(['Error loading file to instrument: ' getReport(ex,'extended')]);
                    obj.Server.ErrorQueue{end + 1} = ['Error loading file to instrument: ' ex.message];
                end      
            end
        end
        
        
        %% Parse GEN:TONE (generating tones and noise)
        
        function isCommand = parseToneGenerateCommands(obj, ~)
            
            % <document>
            % <break>Multi-tone Generation Commands (:GEN:TONE)</break>
            % </document> 
            
            isCommand = true;
            if obj.parseToken('RESET')
                % <document>
                % <command>:GEN:TONE:RESET</command>
                % <type>Send Only</type>
                % <description>Resets the current tone configuration to its default values</description>
                % <example>:GEN:TONE:RESET</example>
                % </document>
                obj.DefaultTone();
            elseif obj.parseToken('SRAT')
                % <document>
                % <command>:GEN:TONE:SRAT <Sample Rate in Hz></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current tone configuration's sample rate in Hz.</description>
                % <example>:GEN:TONE:SRAT?;  :GEN:TONE:SRAT 2E9</example>
                % </document> 
                obj.setget('obj.Instrument.SampleRateInHz', 'double');
            elseif obj.parseToken('FREQ')  % Set the frequencies
                % <document>
                % <command>:GEN:TONE:FREQ <frequencies in Hz></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current tone frequencies in Hz</description>
                % <example>:GEN:TONE:FREQ?; :GEN:TONE:FREQ 100E6; :GEN:TONE:FREQ [100e6, 200e6, 500e6]</example>
                % </document> 
                obj.setget('obj.ToneGen.ToneFrequency', 'double');
            elseif obj.parseToken('MAG')  % Set the magnitudes
                % <document>
                % <command>:GEN:TONE:MAG <magnitudes in dBFS></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current tone magnitude(s) in dBFS</description>
                % <example>:GEN:TONE:MAG?; :GEN:TONE:MAG -12; :GEN:TONE:MAG [-10 -20 -30]</example>
                % </document> 
                obj.setget('obj.ToneGen.ToneMagnitude', 'double');
            elseif obj.parseToken('PHASE')  % Set the tone phase(s)
                % <document>
                % <command>:GEN:TONE:PHASE <list of phase values in degrees or 'Random'></command>
                % <type>Send and Query</type>
                % <description>Gets or sets the current phase(s) in degrees</description>
                % <example>:GEN:TONE:PHASE?; :GEN:TONE:PHASE 'Random'; :GEN:TONE:PHASE [0 90 180 270]</example>
                % </document> 
                obj.setget('obj.ToneGen.TonePhase', 'any');
            elseif obj.parseToken('NORM')  % Set the magnitudes
                % <document>
                % <command>:GEN:TONE:NORM <1|0></command>
                % <type>Send and Query</type>
                % <description>When set to 1 (=default value), waveforms are scaled to use the full DAC range. When set to 0, scaling to full DAC range is only performed if the DAC range is exceeded.</description>
                % <example>:GEN:TONE:MAG?; :GEN:TONE:MAG -12; :GEN:TONE:MAG [-10 -20 -30]</example>
                % </document> 
                obj.setget('obj.ToneGen.ToneNormalize', 'double');
            elseif obj.parseToken('DOWNLOAD')  % Set the frequencies
                % <document>
                % <command>:GEN:TONE:DOWNLOAD</command>
                % <type>Send only</type>
                % <description>Calculates the I/Q data for a multi-tone signal defined by its current settings, then loads it to the defined instrument</description>
                % <example>:GEN:TONE:DOWNLOAD</example>
                % </document> 
                try
                    [iqdata, ~, ~, ~, chMap] = iqtone('sampleRate', obj.Instrument.SampleRateInHz, 'tone', obj.ToneGen.ToneFrequency, ...
                        'Magnitude', obj.ToneGen.ToneMagnitude, 'Phase', obj.ToneGen.TonePhase, 'normalize', obj.ToneGen.ToneNormalize, ...
                        'Correction', obj.Correction.UseCorrection, 'channelMapping', obj.Instrument.ChannelMapping);
                    iqdownload(iqdata, obj.Instrument.SampleRateInHz, 'channelMapping', chMap,...
                        'segmentNumber', obj.Instrument.SegmentNumber, 'segmname', obj.Instrument.SegmentName);
                catch ex
                    obj.setError(ex.message);
                end
            else
                obj.setCommandError();
            end
        end     
    end
end

