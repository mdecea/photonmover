function result = iqvsacqm(varargin)
% iqvsacqm generates a calibration file for pre-distortion by reading the
% channel response from the VSA software using the channel quality mode.
% usage: iqvsacal('param_name', value, 'param_name', value, ...)
% valid parameter names are:
% Tone parameters
% tone = [0];         % Tone relative frequencies in Hz
% mag = [0];          % Tone relative magnitudes in dB
% phase = [0];        % Tone relative phases in degrees
% fc = 0;             % Tone carrier frequency in Hz
% carrierOffset = 0;  % Tone carrier offset in Hz
% 
% % Calibration parameters
% recalibrate = 0;    % Recalibrate or not
% useHW = 1;          % Use Hardware or not
% doCal = 1;          % Do a calibration or just set up
% useFile = true;     % Use a file or load
% initialize = true;  % Initialize measurement or not
% settleTime = 0;     % Wait time for equalizer to settle in seconds
%
% iqvsacqm looks for a variable called vsaApp in the base MATLAB context.
% If it exists, it is assumed to be a handle to an instance of the VSA
% software. If it does not exist, it opens a new instance

result = [];

% Tone parameters
tone = [0];         % Tone relative frequencies in Hz
mag = [0];          % Tone relative magnitudes in dB
phase = [0];        % Tone relative phases in degrees
fc = 0;             % Tone carrier frequency in Hz
carrierOffset = 0;  % Tone carrier offset in Hz

% Calibration parameters
recalibrate = 0;    % Recalibrate or not
useHW = 1;          % Use Hardware or not
doCal = 1;          % Do a calibration or just set up
useFile = true;     % Use a file or load
initialize = true;  % Initialize measurement or not
settleTime = 0;     % Wait time for equalizer to settle in seconds
autoRange = true;   % Auto range the front end?
rangeInDBm = 30;    % Set the range

% Parse arguments
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'tone';            tone = varargin{i+1};
            case 'mag';             mag = varargin{i+1};
            case 'phase';           phase = varargin{i+1};
            case 'fc';              fc = varargin{i+1};
            case 'carrieroffset';   carrierOffset = varargin{i+1};
            case 'recalibrate';     recalibrate = varargin{i+1};
            case 'usehw';           useHW = varargin{i+1};
            case 'docal';           doCal = varargin{i+1};
            case 'usefile';         useFile = varargin{i+1};
            case 'initialize';      initialize = varargin{i+1};
            case 'settletime';      settleTime = varargin{i+1};
            case 'autorange';       autoRange = varargin{i+1};
            case 'rangeindbm';      rangeInDBm = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
        return;
    end
    i = i+2;
end

% If the fc is 0, set the carrier to the median tone
if (fc == 0)
  fc = median(tone);
  carrierOffset = fc;
end

% Perform the setup
result = vsaCal(tone, mag, phase, fc, recalibrate, useHW, doCal, carrierOffset, useFile, initialize, settleTime, autoRange, rangeInDBm);
end


function result = vsaCal(freq, mag, phase, fc, recalibrate, useHW, doCal, carrierOffset, useFile, initialize, settleTime, autoRange, rangeInDBm)
    % Performs the setup for the channel quality measurement and also the
    % calibration if configured to do so

    result = [];
    
    spanScale = 1.01;   % What percentage of the tone span should be used in setup
    
    % If initialize, set up all traces, otherwise update the setup settings
    if (initialize)
        
        % Open the VSA session
        vsaApp = vsafunc([], 'open');
        if (~isempty(vsaApp))
            
            % If no settle time, do not show the messagebox for
            % configuration
            if (settleTime == 0)
                hMsgBox = msgbox('Configuring VSA software. Please wait...');
            end
            
            % If using hardware, preset, and set up measurement
            if (useHW)
                vsafunc(vsaApp, 'preset');
                vsafunc(vsaApp, 'fromHW');
                fcx = fc;
                vsafunc(vsaApp, 'input', fcx);
                vsafunc(vsaApp, 'channelQuality', freq, mag, phase*360/(2*pi), true, useFile);
                
                %Find the span and set the offset correctly
                spanSet = max(freq) - min(freq);
                tuneOffset = (max(freq)+ min(freq))/2;
                vsafunc(vsaApp, 'freq', abs(fcx)+tuneOffset, spanSet*spanScale);
            end
            
            % Autorange the setup and add the traces            
            vsafunc(vsaApp, 'start', 1);
            vsafunc(vsaApp, 'trace', 6, 'CQM');
            
            if (autoRange)
                vsafunc(vsaApp, 'autorange');
            else
                vsafunc(vsaApp, 'autorange', rangeInDBm);
            end
                        
            % Close the messagebox if opened
            if (settleTime == 0)
                try
                    close(hMsgBox);
                catch
                end
            end
            
            if (~doCal)
                return;
            end
            
            % If no settle time configured, show dialog for settle
            if (settleTime <= 0)
                pause(2);
                vsafunc(vsaApp, 'autoscale');
                
                res = questdlg('VSA measurement running. Please press OK when Equalizer has stabilized. (Don''t forget to check input range...)','VSA Calibration','OK','Cancel','OK');

                if (~strcmp(res, 'OK'))
                    return;
                end

                % Acquire the equalizer data
                result = vsafunc(vsaApp, 'readEqDataChannel', recalibrate, freq, abs(fcx)-carrierOffset, true);
                
                if (result == 0)
                        iqshowcorr();           
                end
            % If settle time, wait then acquire equalizer
            else
                pause(settleTime); 
                result = vsafunc(vsaApp, 'readEqDataChannel', recalibrate, freq, abs(fcx)-carrierOffset, false);
            end

            % Restart the measurement
            vsafunc(vsaApp, 'start', 1);        
        end
    % If no initialize, minimize steps for setup so just the tuning and ranging occurs
    else
        
        % Open the VSA session        
        vsaApp = vsafunc([], 'open');
        
        if (useHW)            
            % vsafunc(vsaApp, 'channelQuality', freq, mag, phase*360/(2*pi), true, useFile);

            %Find the span and set the offset correctly
            fcx = fc;
            spanSet = max(freq) - min(freq);
            tuneOffset = (max(freq)+ min(freq))/2;
            vsafunc(vsaApp, 'freq', abs(fcx)+tuneOffset);
        end
        
        % Range and start the measurement        
        vsafunc(vsaApp, 'start', 1);
        
        if (autoRange)
            vsafunc(vsaApp, 'autorange');
        else
            vsafunc(vsaApp, 'autorange', rangeInDBm);
        end
        
        if (~doCal)
            return;
        end
          
        % If no settling time selected, prompt for measurement
        if (settleTime <= 0)
            pause(2); 
            
            vsafunc(vsaApp, 'autoscale');
            res = questdlg('VSA measurement running. Please press OK when Equalizer has stabilized. (Don''t forget to check input range...)','VSA Calibration','OK','Cancel','OK');

            if (~strcmp(res, 'OK'))
                return;
            end
            
            % Acquire the equalizer data
            result = vsafunc(vsaApp, 'readEqDataChannel', recalibrate, freq, abs(fcx)-carrierOffset, true);
            
            if (result == 0)
                    iqshowcorr();           
            end
        % If a settling time, just wait then acquire the equalizer data
        else
            pause(settleTime); 
            result = vsafunc(vsaApp, 'readEqDataChannel', recalibrate, freq, abs(fcx)-carrierOffset, false);
        end
    end
end
