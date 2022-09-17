function result = iqvsamultical(varargin)
% iqvsacal generates a calibration file for pre-distortion by reading the
% channel response from the VSA software
% usage: iqvsacal('param_name', value, 'param_name', value, ...)
% valid parameter names are:
%   symbolRate - symbol rate in Hz
%   modType - modulation type ('BPSK', 'QPSK', 'QAM4', 'QAM16', etc.)
%   filterType - type of pulse shaping filter
%   filterBeta - beta value of pulse shaping filter
%   carrierOffset - center frequency in Hz (0 in case of baseband data)
%   recalibrate - add new corr values to existing file
%
% iqvsacal looks for a variable called hVsaApp in the base MATLAB context.
% If it exists, it is assumed to be a handle to an instance of the VSA
% software. If it does not exist, it opens a new instance

result = -1;
symbolRate = 1e9;
modType = 'QAM16';
filterType = 'Square Root Raised Cosine';
filterBeta = 0.35;
carrierOffset = 2e9;
fc = 2e9;
filterLength = 99;
convergence = 1e-7;
resultLength = 256;
recalibrate = 0;
performAutorange = 0;
measure_Q = 0;          % "special" modulation type to measure the "Q" portion of the signal
useHW = 1;
doCal = 1;
i = 1;
mixerMode = 'Normal';
customFilterFile = '';
range = -10;
doOBP = 0;

while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'symbolrate';     symbolRate = varargin{i+1};
            case 'modtype';        modType = varargin{i+1};
            case 'filtertype';     filterType = varargin{i+1};
            case 'filterbeta';     filterBeta = varargin{i+1};
            case 'carrieroffset';  carrierOffset = varargin{i+1};
            case 'fc';             fc = varargin{i+1};
            case 'filterlength';   filterLength = varargin{i+1};
            case 'convergence';    convergence = varargin{i+1};
            case 'resultlength';   resultLength = varargin{i+1};
            case 'recalibrate';    recalibrate = varargin{i+1};
            case 'usehw';          useHW = varargin{i+1};
            case 'docal';          doCal = varargin{i+1};
            case 'mixermode';      mixerMode = varargin{i+1};
            case 'customfilterfile';   customFilterFile = varargin{i+1};
            case 'range';   range = varargin{i+1};
                                
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
        return;
    end
    i = i+2;
end
result = vsaMultiCal(symbolRate, modType, filterType, filterBeta, carrierOffset, fc, filterLength, convergence, resultLength, recalibrate, useHW, doCal, mixerMode, customFilterFile, range);
end

function result = vsaMultiCal(symbolRate, modType, filterType, filterBeta, carrierOffset, fc, filterLength, convergence, resultLength, recalibrate, useHW, doCal, mixerMode, customFilterFile, range)
    result = -1;
    vsaApp = vsafunc([], 'open');
    
    if (~isempty(vsaApp))
        hMsgBox = msgbox('Configuring VSA software. Please wait...');
        if (useHW)
            vsafunc(vsaApp, 'preset');
            vsafunc(vsaApp, 'fromHW');
            fcx = fc;
            if (fc == 0 && strcmp(modType, 'PAM4'))
                fcx = 1;    % pretend that it is an RF signal
            end
            vsafunc(vsaApp, 'input', fcx);
            vsafunc(vsaApp, 'DigDemod', modType, symbolRate, filterType, filterBeta, resultLength);
            if (strcmp(filterType, 'Gaussian'))
                spanScale = 9 * filterBeta;
            else
                spanScale = 1 + filterBeta;
            end
            vsafunc(vsaApp, 'freq', abs(fc), symbolRate * spanScale, 102401, 'flattop', 3);
            vsafunc(vsaApp, 'xSeriesMixerMode', mixerMode);
            vsafunc(vsaApp, 'loadIFCorrectionFile', customFilterFile);
        end
        
        if isempty(range)
            vsafunc(vsaApp, 'autorange');
        else
            vsafunc(vsaApp, 'autorange', range);
        end
        
        if (doCal)
            vsafunc(vsaApp, 'trace', 6, 'DigDemod');
        else
            vsafunc(vsaApp, 'trace', 4, 'DigDemod');
        end
        vsafunc(vsaApp, 'start', 1);
        vsafunc(vsaApp, 'equalizer', doCal, filterLength, convergence);
        pause(2);
        try
            close(hMsgBox);
        catch
        end
        if (~doCal)
            return;
        end
        res = questdlg('VSA measurement running. Please press OK when Equalizer has stabilized. (Don''t forget to check input range...)','VSA Calibration','OK','Cancel','OK');
        if (strcmp(res, 'OK'))
            result = vsafunc(vsaApp, 'readEqData', recalibrate, abs(fc)-carrierOffset);
            if (result == 0)
                iqshowcorr();
            end
        end
        vsafunc(vsaApp, 'equalizer', false, filterLength, convergence);
        vsafunc(vsaApp, 'trace', 4, 'DigDemod');
        vsafunc(vsaApp, 'start', 1);
    end
end
