function varargout = iqloadfile_gui(varargin)
% IQLOADFILE_GUI MATLAB code for iqloadfile_gui.fig
%      IQLOADFILE_GUI, by itself, creates a new IQLOADFILE_GUI or raises the existing
%      singleton*.
%
%      H = IQLOADFILE_GUI returns the handle to a new IQLOADFILE_GUI or the handle to
%      the existing singleton*.
%
%      IQLOADFILE_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQLOADFILE_GUI.M with the given input arguments.
%
%      IQLOADFILE_GUI('Property','Value',...) creates a new IQLOADFILE_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqloadfile_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqloadfile_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqloadfile_gui

% Last Modified by GUIDE v2.5 05-Feb-2019 14:16:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @iqloadfile_gui_OpeningFcn, ...
    'gui_OutputFcn',  @iqloadfile_gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before iqloadfile_gui is made visible.
function iqloadfile_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqloadfile_gui (see VARARGIN)

% Choose default command line output for iqloadfile_gui
handles.output = hObject;
arbConfig = loadArbConfig();
if (arbConfig.maxSegmentNumber <= 1)
    set(handles.editSegment, 'Enable', 'off');
    set(handles.textSegment, 'Enable', 'off');
end

% Update handles structure
guidata(hObject, handles);

set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editSamplesName, 'Enable', 'off');
set(handles.editSamplePeriodName, 'Enable', 'off');
set(handles.editMarkerName, 'Enable', 'off');
set(handles.popupmenuType, 'Value', 2);
set(handles.popupmenuN5110A_M1, 'Value', 2);
set(handles.popupmenuN5110A_M2, 'Value', 3);
set(handles.popupmenuN5110A_M3, 'Value', 4);
set(handles.popupmenuN5110A_M4, 'Value', 5);
set(handles.popupmenuResampleMethod, 'Value', 2);
popupmenuType_Callback([], [], handles);

% update all the fields
checkfields([], 0, handles);

if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
    set(handles.editFilename, 'TooltipString', sprintf([ ...
        'Enter the filename that you would like to download. You can use the\n' ...
        '"..." button on the right to open a file selection dialog.']));
    set(handles.popupmenuType, 'TooltipString', sprintf([ ...
        'Select the type of input file to download. For "CSV", the file must contain\n' ...
        'one or two columns of data (separated by comma) that are loaded into channel 1\n' ...
        'resp. channel 2 of the AWG.\n\n' ...
        'For file type "MAT", the MATLAB file must contain at least one vector that\n' ...
        'contains the data. A real data vector will be loaded in channel 1, a complex\n' ...
        'vector will be loaded in both channels (real to channel 1, imaginary to channel 2\n' ...
        'Optionally the MATLAB file can contain another scalar variable that holds\n' ...
        'the sampling period. The names of these variable must be specified in the fields\n' ...
        'below.']));
    set(handles.editSampleRate, 'TooltipString', sprintf([ ...
        'Enter the sample rate at which the file has been captured. In case\n' ...
        'of MATLAB files, the sample rate can also be stored in the file.\n' ...
        'Note: Even if the waveform is up-converted, this field must contain\n' ...
        'the sample rate of the samples in the file.']));
    set(handles.checkboxFromFile, 'TooltipString', sprintf([ ...
        'If the sample period is stored in a MATLAB file, check this checkbox;\n' ...
        'otherwise uncheck it and specify the sample rate in the "Sample Rate" field.']));
    set(handles.checkboxResample, 'TooltipString', sprintf([ ...
        'If the sample rate of the file is too slow for the AWG, you can check this\n' ...
        'checkbox to perform re-sampling and convert the waveform to a higher \n' ...
        'sampling rate.']));
    set(handles.popupmenuResampleMethod, 'TooltipString', sprintf([ ...
        'Defines the method used for re-sampling. "Interpolation" uses a low-pass\n' ...
        'filter, whereas "FFT" performs an FFT, adds zeros and performs in IFFT.\n' ...
        '"resample" uses fractional re-sampling (i.e. it allows you to specify a non-integer\n' ...
        'resampling factor) and "linear" applies linear interpolation between points.\n' ...
        'Depending on the type of the signal one or the other method works better.\n' ...
        'In case of doubt, try it out...']));
    set(handles.editSamplesName, 'TooltipString', sprintf([ ...
        'Specify the name of the variable that is used in the MATLAB data file\n' ...
        'that holds the signal vector.']));
    set(handles.editSamplePeriodName, 'TooltipString', sprintf([ ...
        'Specify the name of the variable that is used in the MATLAB data file\n' ...
        'that holds the sample period.']));
    set(handles.checkboxCorrection, 'TooltipString', sprintf([ ...
        'Use this checkbox to pre-distort the signal using the previously established\n' ...
        'calibration values. Calibration can be performed using the multi-tone or\n' ...
        'digital modulation utilities.']));
    set(handles.pushbuttonShowCorrection, 'TooltipString', sprintf([ ...
        'Use this button to visualize the frequency and phase response that has\n' ...
        'been captured using the "Calibrate" functionality in the multi-tone or\n' ...
        'digital modulation utility. In multi-tone, only magnitude corrections\n' ...
        'are captured whereas in digital modulation, both magnitude and phase\n' ...
        'response are calculated.']));
    set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
        'Use this button to calculate and show the simulated waveform using MATLAB plots.\n' ...
        'The signal will be displayed both in the time- as well as frequency\n' ...
        'domain (spectrum). This function can be used even without any hardware\n' ...
        'connected.']));
    set(handles.pushbuttonDisplayVSA, 'TooltipString', sprintf([ ...
        'Use this button to calculate and show the simulated waveform using Keysight 89601B VSA.\n' ...
        'The signal will be loaded to VSA but no additional setup steps will occur.\n' ...
        'This function can be used even without any hardware connected.']));
    set(handles.editSegment, 'TooltipString', sprintf([ ...
        'Enter the AWG waveform segment to which the signal will be downloaded.\n' ...
        'If you download to segment #1, all other segments will be automatically\n' ...
        'deleted.']));
    set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
        'Use this button to calculate and download the signal to the configured AWG.\n' ...
        'Make sure that you have configured the connection parameters in "Configure\n' ...
        'instrument connection" before using this function.']));
    set(handles.pushbuttonChannelMapping, 'TooltipString', sprintf([ ...
        'Select into which channels the real and imaginary part of the waveform\n' ...
        'is loaded. By default, I is loaded into Channel 1, Q into channel 2, but\n' ...
        'it is also possible to load the same signal into both channels.\n' ...
        'In DUC modes, both I and Q are used for the same channel.\n' ...
        'In dual-M8190A configurations, channels 3 and 4 are on the second module.']));
    set(handles.popupmenuDataColumn, 'TooltipString', sprintf([ ...
        'Select if the file contains one or two data columns.\n' ...
        'In case of two columns, they will be loaded into channels 1 and 2\n' ...
        'or treated as I + Q components in DUC mode.\n']));
end
% UIWAIT makes iqloadfile_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqloadfile_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editFilename_Callback(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFilename as text
%        str2double(get(hObject,'String')) returns contents of editFilename as a double
filename = get(handles.editFilename, 'String');
try
    f = fopen(filename, 'r');
    fclose(f);
        % try to find associated .txt file and extract sample rate
        file2 = [filename '.txt'];
        try
            f = fopen(file2, 'r');
            a = fgetl(f);
            while (a ~= -1)
                if (~isempty(strfind(a, 'XDelta')))
                    sr = str2double(a(8:end));
                    set(handles.editSampleRate, 'String', iqengprintf(sr));
                    break;
                end
                a = fgetl(f);
            end
            fclose(f);
        catch ex % ignore any errors
        end
catch ex
    errordlg(sprintf('Can''t open %s', filename'));
end


% --- Executes during object creation, after setting all properties.
function editFilename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuType.
function popupmenuType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuType
val = get(handles.popupmenuType, 'Value');
filename = get(handles.editFilename, 'String');
setNewFilename = (~isempty(strfind(filename, 'example.')));
if (isdeployed)
    [~, result] = system('path');
    path = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
else
    path = 'iqtools';
end
switch (val)
    case 1 % csv
        set(handles.editSampleRate, 'Enable', 'on');
        set(handles.checkboxFromFile, 'Enable', 'off');
        set(handles.checkboxFromFile, 'Value', 0);
        set(handles.editSamplesName, 'Enable', 'off');
        set(handles.editSamplePeriodName, 'Enable', 'off');
        set(handles.editMarkerName, 'Enable', 'off');
        set(handles.uipanelCSV, 'Visible', 'on');
        set(handles.uipanelVarNames, 'Visible', 'off');
        set(handles.uipanelN5110A, 'Visible', 'off');
        if (setNewFilename)
            set(handles.editFilename, 'String', fullfile(path, 'example.csv'));
        end
    case 2 % mat
        set(handles.editSampleRate, 'Enable', 'off');
        set(handles.checkboxFromFile, 'Enable', 'on');
        set(handles.checkboxFromFile, 'Value', 1);
        set(handles.editSamplesName, 'Enable', 'on');
        set(handles.editMarkerName, 'Enable', 'on');
        set(handles.uipanelCSV, 'Visible', 'off');
        set(handles.uipanelVarNames, 'Visible', 'on');
        set(handles.uipanelN5110A, 'Visible', 'off');
        if (get(handles.checkboxFromFile, 'Value'))
            set(handles.editSamplePeriodName, 'Enable', 'on');
        else
            set(handles.editSamplePeriodName, 'Enable', 'off');
        end
        if (setNewFilename)
            set(handles.editFilename, 'String', fullfile(path, 'example.mat'));
        end
    case {3 4 5 6}
        set(handles.editSampleRate, 'Enable', 'on');
        set(handles.checkboxFromFile, 'Enable', 'off');
        set(handles.checkboxFromFile, 'Value', 0);
        set(handles.editSamplesName, 'Enable', 'off');
        set(handles.editSamplePeriodName, 'Enable', 'off');
        set(handles.editMarkerName, 'Enable', 'off');
        set(handles.uipanelVarNames, 'Visible', 'off');
        set(handles.uipanelCSV, 'Visible', 'off');
        set(handles.uipanelN5110A, 'Visible', 'on');
        if (setNewFilename)
            if (val == 3 || val == 5)
                set(handles.editFilename, 'String', fullfile(path, 'example.bin'));
            else
                set(handles.editFilename, 'String', fullfile(path, 'example.data'));
            end
        end
    case 7  % 12-bit packed
        set(handles.editSampleRate, 'Enable', 'on');
        set(handles.checkboxFromFile, 'Enable', 'off');
        set(handles.checkboxFromFile, 'Value', 0);
        set(handles.editSamplesName, 'Enable', 'off');
        set(handles.editSamplePeriodName, 'Enable', 'off');
        set(handles.editMarkerName, 'Enable', 'off');
        set(handles.uipanelVarNames, 'Visible', 'off');
        set(handles.uipanelCSV, 'Visible', 'off');
        set(handles.uipanelN5110A, 'Visible', 'off');
        if (setNewFilename)
            set(handles.editFilename, 'String', fullfile(path, 'example.pbin12'));
        end
    case 8 % Osc (*.bin,*.csv,*.tsv,*.txt,*.h5)
        set(handles.editSampleRate, 'Enable', 'off');
        set(handles.checkboxFromFile, 'Enable', 'on');
        set(handles.checkboxFromFile, 'Value', 1);
        
        set(handles.uipanelCSV, 'Visible', 'off');
        set(handles.uipanelVarNames, 'Visible', 'off');
        set(handles.uipanelN5110A, 'Visible', 'off');
        
        if (get(handles.checkboxFromFile, 'Value'))
            set(handles.editSamplePeriodName, 'Enable', 'on');
        else
            set(handles.editSamplePeriodName, 'Enable', 'off');
        end
        if (setNewFilename)
            set(handles.editFilename, 'String', 'iqtools/example.h5');
        end
    case 9
        set(handles.editSampleRate, 'Enable', 'on');
        set(handles.checkboxFromFile, 'Enable', 'off');
        set(handles.checkboxFromFile, 'Value', 0);
        set(handles.editSamplesName, 'Enable', 'off');
        set(handles.editSamplePeriodName, 'Enable', 'off');
        set(handles.editMarkerName, 'Enable', 'off');
        set(handles.uipanelVarNames, 'Visible', 'off');
        set(handles.uipanelCSV, 'Visible', 'off');
        set(handles.uipanelN5110A, 'Visible', 'off');
        if (setNewFilename)
            set(handles.editFilename, 'String', fullfile(path, 'example.pbin12'));
        end
    otherwise
        error('unexpected file type');
end


% --- Executes during object creation, after setting all properties.
function popupmenuType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata, fs, marker, ~, ~] = readFile(handles);
set(handles.editNumSamples, 'String', sprintf('%.0f', length(iqdata)));
if (~isempty(iqdata) && fs ~= 0)
    iqplot(iqdata, fs, 'marker', marker);
end


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...');
[iqdata, fs, marker, rpt, channelMapping] = readFile(handles);
if (~isempty(iqdata))
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
    set(handles.editNumSamples, 'String', sprintf('%.0f', rpt*length(iqdata)));
    iqdownload(repmat(iqdata, rpt, 1), fs, 'channelMapping', channelMapping, ...
        'segmentNumber', segmentNum, 'marker', repmat(marker, rpt, 1));
    assignin('base', 'iqdata', repmat(iqdata, rpt, 1));
end
try close(hMsgBox); catch; end


function [iqdata, fs, marker, rpt, channelMapping] = readFile(handles, doCode)
iqdata = [];
fs = 0;
marker = [];
rpt = 1;
channelMapping = [];
try
    fileTypeList = get(handles.popupmenuType, 'String');
    fileType = fileTypeList{get(handles.popupmenuType, 'Value')};
    filename = get(handles.editFilename, 'String');
    correction = get(handles.checkboxCorrection, 'Value');
    fromFile = get(handles.checkboxFromFile, 'Value');
    chMap = get(handles.pushbuttonChannelMapping, 'UserData');
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
    if (fromFile)
        sampleRate = [];
    end
    dtypeList = get(handles.popupmenuDataColumn, 'String');
    dtype = dtypeList{get(handles.popupmenuDataColumn, 'Value')};
    csvMarkerMap = [...
        get(handles.popupmenuCSV_M1, 'Value') ...
        get(handles.popupmenuCSV_M2, 'Value') ...
        get(handles.popupmenuCSV_M3, 'Value') ...
        get(handles.popupmenuCSV_M4, 'Value')] - 1;
%    mtypeList = get(handles.popupmenuMarkerColumn, 'String');
%    mtype = mtypeList{get(handles.popupmenuMarkerColumn, 'Value')};
    binaryMarkerMap = [...
        get(handles.popupmenuN5110A_M1, 'Value') ...
        get(handles.popupmenuN5110A_M2, 'Value') ...
        get(handles.popupmenuN5110A_M3, 'Value') ...
        get(handles.popupmenuN5110A_M4, 'Value')] - 1;
    matlabSamplesName = get(handles.editSamplesName, 'String');
    matlabSamplePeriodName = get(handles.editSamplePeriodName, 'String');
    matlabMarkerName = strtrim(get(handles.editMarkerName, 'String'));
    matlabVarNames = {matlabSamplesName, matlabSamplePeriodName, matlabMarkerName};
    if (get(handles.checkboxResample, 'Value'))
        methodList = cellstr(get(handles.popupmenuResampleMethod, 'String'));
        resampleMethod = methodList{get(handles.popupmenuResampleMethod, 'Value')};
        resampleMethodStr = ['''' resampleMethod ''''];
        resampleFactor = evalin('base', get(handles.editResampleFactor, 'String'));
    else
        resampleMethod = [];
        resampleMethodStr = '[]';
        resampleFactor = 1;
    end
    
    if (get(handles.checkboxWindow, 'Value'))
        methodList = cellstr(get(handles.popupmenuWindowType, 'String'));
        windowMethod = methodList{get(handles.popupmenuWindowType, 'Value')};        
        windowMethodStr = ['''' windowMethod ''''];        
        windowFactor = evalin('base', get(handles.editWindowFactor, 'String'));
    else
        windowMethod = [];
        windowMethodStr = '[]';
        windowFactor = 0;
    end
    
    if (get(handles.checkboxFreqShift, 'Value'))
        frequencyShift = evalin('base', get(handles.editFc, 'String'));
    else
        frequencyShift = [];
    end
    symm = get(handles.checkboxScaleSymm, 'Value');
    normalize = get(handles.checkboxNormalize, 'Value');
    if (~normalize)
        scaleMinMax = [];
    else
        minScale = evalin('base', get(handles.editScaleToMin, 'String'));
        maxScale = evalin('base', get(handles.editScaleToMax, 'String'));
        scaleMinMax = [minScale maxScale symm];
    end
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
catch ex
    errordlg(ex.message);
    return;
end
if (exist('doCode', 'var') && doCode ~= 0)
    % for MATLAB code generation, the variable "iqdata" holds the program code
    if (~isempty(sampleRate))
        sampleRateStr = iqengprintf(sampleRate);
    else
        sampleRateStr = '[]';
    end
    if (~isempty(frequencyShift))
        frequencyShiftStr = iqengprintf(frequencyShift);
    else
        frequencyShiftStr = '[]';
    end
    matlabVarNamesStr = '{';
    for i = 1:length(matlabVarNames)
        matlabVarNamesStr = [matlabVarNamesStr ' ''' matlabVarNames{i} ''''];
    end
    matlabVarNamesStr = [matlabVarNamesStr ' }'];
    chMapStr = iqchannelsetup('arraystring', get(handles.pushbuttonChannelMapping, 'UserData'));
    iqdata = sprintf(['[iqdata, fs, marker, rpt, chMap] = iqloadfile( ...\n' ...
            '    ''fileType'', ''%s'', ''filename'', ''%s'', ...\n' ...
            '    ''sampleRate'', %s, ''csvDataColumn'', ''%s'', ''csvMarkerMap'', ''%s'', ...\n' ...
            '    ''binaryMarkerMap'', %s, ''resampleMethod'', %s, ''resampleFactor'', %d, ...\n' ...
            '    ''matlabVarNames'', %s, ''frequencyShift'', %s, ''scaleMinMax'', %s, ...\n' ...
            '    ''correction'', %d, ''chMap'', %s, ''windowmethod'', %s, ''windowfactor'', %g);\n\n'...
            'if (~isempty(iqdata))\n' ...
            '    iqdownload(repmat(iqdata, rpt, 1), fs, ...\n' ...
            '        ''chMap'', chMap, ''segmentNumber'', %d, ''marker'', repmat(marker, rpt, 1));\n' ...
            'end\n'], ...
        fileType, filename, sampleRateStr, dtype, ...
        ['[' strtrim(sprintf('%d ', csvMarkerMap)) ']'], ...
        ['[' strtrim(sprintf('%d ', binaryMarkerMap)) ']'], ...
        resampleMethodStr, resampleFactor, ...
        matlabVarNamesStr, frequencyShiftStr, ...
        ['[' strtrim(sprintf('%d ', scaleMinMax)) ']'], ...
        correction, chMapStr, windowMethodStr, windowFactor, segmentNum);
else
    [iqdata, fs, marker, rpt, channelMapping] = iqloadfile(...
        'fileType', fileType, 'filename', filename, ...
        'sampleRate', sampleRate, ...
        'csvDataColumn', dtype, 'csvMarkerMap', csvMarkerMap, ...
        'binaryMarkerMap', binaryMarkerMap, ...
        'resampleMethod', resampleMethod, 'resampleFactor', resampleFactor, ...
        'matlabVarNames', matlabVarNames, ...
        'frequencyShift', frequencyShift, 'scaleMinMax', scaleMinMax, ...
        'correction', correction, ...
        'chMap', chMap, 'windowmethod', windowMethod, 'windowfactor', windowFactor);
    if (~isempty(iqdata))
        minVal = min(min(min(real(iqdata)), min(imag(iqdata))));
        maxVal = max(max(max(real(iqdata)), max(imag(iqdata))));
        set(handles.editMaxValue, 'String', iqengprintf(maxVal));
        set(handles.editMinValue, 'String', iqengprintf(minVal));
        if (isempty(resampleMethod) && isempty(sampleRate) && ~isempty(fs))
            set(handles.editSampleRate, 'String', iqengprintf(fs));
            editSampleRate_Callback(0, 0, handles);
        end
    end
end


function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editSampleRate as a double
value = -1;
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
arbConfig = loadArbConfig();
rs = get(handles.checkboxResample, 'Value');
if (isscalar(value) && rs || ~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1)))
    set(handles.editSampleRate,'BackgroundColor','white');
else
    set(handles.editSampleRate,'BackgroundColor','red');
end
calcNewSampleRate(handles);

% --- Executes during object creation, after setting all properties.
function editSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxFromFile.
function checkboxFromFile_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxFromFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxFromFile
val = get(handles.checkboxFromFile, 'Value');
onoff = {'on' 'off'};
set(handles.editSampleRate, 'Enable', onoff{val+1});
type = get(handles.popupmenuType,'Value');
if (type == 2) % mat
    if (val)
        set(handles.editSamplePeriodName, 'Enable', 'on');
    else
        set(handles.editSamplePeriodName, 'Enable', 'off');
    end
end


% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection



function editSamplePeriodName_Callback(hObject, eventdata, handles)
% hObject    handle to editSamplePeriodName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSamplePeriodName as text
%        str2double(get(hObject,'String')) returns contents of editSamplePeriodName as a double


% --- Executes during object creation, after setting all properties.
function editSamplePeriodName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSamplePeriodName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSamplesName_Callback(hObject, eventdata, handles)
% hObject    handle to editSamplesName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSamplesName as text
%        str2double(get(hObject,'String')) returns contents of editSamplesName as a double


% --- Executes during object creation, after setting all properties.
function editSamplesName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSamplesName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonShowCorrection.
function pushbuttonShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqcorrmgmt();


% --- Executes on button press in checkboxResample.
function checkboxResample_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxResample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxResample
val = get(hObject,'Value');
if (val)
    set(handles.editResampleFactor, 'Enable', 'on');
    set(handles.popupmenuResampleMethod, 'Enable', 'on');
    arbConfig = loadArbConfig();
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
    resampleFactor = arbConfig.defaultSampleRate / sampleRate;
    toleranceList = [1 1/2 1/5 1/10 1/20 1/100 1/1000];
    for i=1:length(toleranceList)
        [n, d] = rat(resampleFactor, toleranceList(i));
        newFs = sampleRate * n / d;
        if (~isempty(find(newFs >= arbConfig.minimumSampleRate & newFs <= arbConfig.maximumSampleRate, 1)))
            resampleFactor = n / d;
            break;
        end
    end
    set(handles.editResampleFactor, 'String', iqengprintf(resampleFactor));
else
    set(handles.editResampleFactor, 'Enable', 'off');
    set(handles.popupmenuResampleMethod, 'Enable', 'off');
end
editSampleRate_Callback(0, 0, handles);
%calcNewSampleRate(handles);


function editResampleFactor_Callback(hObject, eventdata, handles)
% hObject    handle to editResampleFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editResampleFactor as text
%        str2double(get(hObject,'String')) returns contents of editResampleFactor as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
if (isscalar(value) && value > 0 && value <= 10000)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end
calcNewSampleRate(handles);


function calcNewSampleRate(handles)
factor = evalin('base', get(handles.editResampleFactor,'String'));
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
newRate = sampleRate * factor;
set(handles.editNewSampleRate, 'String', iqengprintf(newRate));
rs = get(handles.checkboxResample, 'Value');
arbConfig = loadArbConfig();
if (~rs || (~isempty(find(newRate >= arbConfig.minimumSampleRate & newRate <= arbConfig.maximumSampleRate, 1))))
    set(handles.editNewSampleRate,'BackgroundColor','white');
    set(handles.editNewSampleRate,'Enable','off');
else
    set(handles.editNewSampleRate,'Enable','on');
    set(handles.editNewSampleRate,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editResampleFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editResampleFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNewSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editNewSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNewSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editNewSampleRate as a double


% --- Executes during object creation, after setting all properties.
function editNewSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNewSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuResampleMethod.
function popupmenuResampleMethod_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuResampleMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuResampleMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuResampleMethod


% --- Executes during object creation, after setting all properties.
function popupmenuResampleMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuResampleMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonFileName.
function pushbuttonFileName_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (isfield(handles, 'LastFileName'))
    lastFilename = handles.LastFileName;
else
    lastFilename = '';
end
type = get(handles.popupmenuType, 'Value');
types = {'*.csv;*.txt' '*.mat' '*.iqbin;*.bin' '*.iq16b;*.iqbin;*.bin;*.data' '*.bin' '*.bin16b;*.bin' '*.pbin12' '*.bin;*.h5;*.csv;*.tsv;*.txt' '*.bin'};
try
    [FileName,PathName] = uigetfile(types{type}, 'Select file to load', lastFilename);
    if(FileName~=0)
        FileName = strcat(PathName,FileName);
        set(handles.editFilename, 'String', FileName);
        editFilename_Callback([], eventdata, handles);
        % remember pathname for next time
        handles.LastFileName = FileName;
        guidata(hObject, handles);
    end
catch ex
end



function editFc_Callback(hObject, eventdata, handles)
% hObject    handle to editFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFc as text
%        str2double(get(hObject,'String')) returns contents of editFc as a double


% --- Executes during object creation, after setting all properties.
function editFc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxFreqShift.
function checkboxFreqShift_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxFreqShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxFreqShift
val = get(hObject,'Value');
if (val)
    set(handles.editFc, 'Enable', 'on');
else
    set(handles.editFc, 'Enable', 'off');
end


function editSegment_Callback(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSegment as text
%        str2double(get(hObject,'String')) returns contents of editSegment as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
arbConfig = loadArbConfig();
if (isscalar(value) && value >= 1 && value <= arbConfig.maxSegmentNumber)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSegment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editMarkerName_Callback(hObject, eventdata, handles)
% hObject    handle to editMarkerName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMarkerName as text
%        str2double(get(hObject,'String')) returns contents of editMarkerName as a double


% --- Executes during object creation, after setting all properties.
function editMarkerName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMarkerName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuMarkerColumn.
function popupmenuMarkerColumn_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuMarkerColumn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuMarkerColumn contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuMarkerColumn


% --- Executes during object creation, after setting all properties.
function popupmenuMarkerColumn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuMarkerColumn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuN5110A_M1.
function popupmenuN5110A_M1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuN5110A_M1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuN5110A_M1


% --- Executes during object creation, after setting all properties.
function popupmenuN5110A_M1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuN5110A_M2.
function popupmenuN5110A_M2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuN5110A_M2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuN5110A_M2


% --- Executes during object creation, after setting all properties.
function popupmenuN5110A_M2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuN5110A_M3.
function popupmenuN5110A_M3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuN5110A_M3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuN5110A_M3


% --- Executes during object creation, after setting all properties.
function popupmenuN5110A_M3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuN5110A_M4.
function popupmenuN5110A_M4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuN5110A_M4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuN5110A_M4


% --- Executes during object creation, after setting all properties.
function popupmenuN5110A_M4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuN5110A_M4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDataColumn.
function popupmenuDataColumn_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDataColumn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDataColumn contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDataColumn


% --- Executes during object creation, after setting all properties.
function popupmenuDataColumn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDataColumn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
[arbConfig saConfig] = loadArbConfig();
% --- channel mapping
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig);
% --- editSampleRate
value = -1;
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
    set(handles.editSampleRate, 'BackgroundColor', 'white');
else
    set(handles.editSampleRate, 'BackgroundColor', 'red');
    result = 0;
end


% --- Executes on button press in pushbuttonChannelMapping.
function pushbuttonChannelMapping_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonChannelMapping (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
[val, str] = iqchanneldlg(get(hObject, 'UserData'), arbConfig, handles.iqtool);
if (~isempty(val))
    set(hObject, 'UserData', val);
    set(hObject, 'String', str);
end



function editNumSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSamples as text
%        str2double(get(hObject,'String')) returns contents of editNumSamples as a double


% --- Executes during object creation, after setting all properties.
function editNumSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxNormalize.
function checkboxNormalize_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxNormalize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(handles.checkboxNormalize, 'Value');
if (value)
    set(handles.editScaleToMin, 'Enable', 'on');
    set(handles.editScaleToMax, 'Enable', 'on');
    set(handles.checkboxScaleSymm, 'Enable', 'on');
else
    set(handles.editScaleToMin, 'Enable', 'off');
    set(handles.editScaleToMax, 'Enable', 'off');
    set(handles.checkboxScaleSymm, 'Enable', 'off');
end


function editMaxValue_Callback(hObject, eventdata, handles)
% hObject    handle to editMaxValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMaxValue as text
%        str2double(get(hObject,'String')) returns contents of editMaxValue as a double


% --- Executes during object creation, after setting all properties.
function editMaxValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMaxValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editMinValue_Callback(hObject, eventdata, handles)
% hObject    handle to editMinValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMinValue as text
%        str2double(get(hObject,'String')) returns contents of editMinValue as a double



% --- Executes during object creation, after setting all properties.
function editMinValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMinValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editScaleToMax_Callback(hObject, eventdata, handles)
% hObject    handle to editScaleToMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkScaleValue(handles);


function checkScaleValue(handles)
minVal = 1.1;
maxVal = 1.1;
try
    minVal = evalin('base', get(handles.editScaleToMin, 'String'));
    maxVal = evalin('base', get(handles.editScaleToMax, 'String'));
catch ex
    errordlg({'invalid expression:', ex.message});
end
if (isscalar(maxVal) && maxVal >= -1 && maxVal <= 1 && maxVal >= minVal)
    set(handles.editScaleToMax,'BackgroundColor','white');
else
    set(handles.editScaleToMax,'BackgroundColor','red');
end
if (isscalar(minVal) && minVal >= -1 && minVal <= 1 && maxVal >= minVal)
    set(handles.editScaleToMin,'BackgroundColor','white');
else
    set(handles.editScaleToMin,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editScaleToMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScaleToMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editScaleToMin_Callback(hObject, eventdata, handles)
% hObject    handle to editScaleToMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkScaleValue(handles);


% --- Executes during object creation, after setting all properties.
function editScaleToMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScaleToMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxScaleSymm.
function checkboxScaleSymm_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxScaleSymm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonDisplayVSA.
function pushbuttonDisplayVSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplayVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata, fs , ~, ~, ~] = readFile(handles);
set(handles.editNumSamples, 'String', sprintf('%.0f', length(iqdata)));
if (~isempty(iqdata))
    %% View in VSA
    vsaApp = vsafunc([], 'open');
    if (~isempty(vsaApp))
        hMsgBox = msgbox('Configuring VSA software. Please wait...');
        vsafunc(vsaApp, 'load', iqdata, fs, 0);
        try
            close(hMsgBox);
        catch
        end
    end
end


% --------------------------------------------------------------------
function menuSaveWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata, fs, marker, ~, ~] = readFile(handles);
set(handles.editNumSamples, 'String', sprintf('%.0f', length(iqdata)));
if (~isempty(iqdata))
    iqsavewaveform(iqdata, fs, 'marker', marker);
end


% --------------------------------------------------------------------
function menuGenerateCode_Callback(hObject, eventdata, handles)
% hObject    handle to menuGenerateCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata, ~, ~, ~, ~] = readFile(handles, 1);
iqgeneratecode(handles, iqdata);


% --------------------------------------------------------------------
function menuLoadSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menuLoadSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqloadsettings(handles);


% --------------------------------------------------------------------
function menuSaveSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqsavesettings(handles);


% --- Executes on button press in checkboxWindow.
function checkboxWindow_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxWindow
val = get(hObject,'Value');
if (val)
    set(handles.editWindowFactor, 'Enable', 'on');
    set(handles.popupmenuWindowType, 'Enable', 'on');    
else
    set(handles.editWindowFactor, 'Enable', 'off');
    set(handles.popupmenuWindowType, 'Enable', 'off');
end

% --- Executes on selection change in popupmenuWindowType.
function popupmenuWindowType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuWindowType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuWindowType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuWindowType


% --- Executes during object creation, after setting all properties.
function popupmenuWindowType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuWindowType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editWindowFactor_Callback(hObject, eventdata, handles)
% hObject    handle to editWindowFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWindowFactor as text
%        str2double(get(hObject,'String')) returns contents of editWindowFactor as a double


% --- Executes during object creation, after setting all properties.
function editWindowFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWindowFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuCSV_M1.
function popupmenuCSV_M1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuCSV_M1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuCSV_M1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuCSV_M1


% --- Executes during object creation, after setting all properties.
function popupmenuCSV_M1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuCSV_M1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuCSV_M2.
function popupmenuCSV_M2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuCSV_M2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuCSV_M2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuCSV_M2


% --- Executes during object creation, after setting all properties.
function popupmenuCSV_M2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuCSV_M2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuCSV_M3.
function popupmenuCSV_M3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuCSV_M3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuCSV_M3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuCSV_M3


% --- Executes during object creation, after setting all properties.
function popupmenuCSV_M3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuCSV_M3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuCSV_M4.
function popupmenuCSV_M4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuCSV_M4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuCSV_M4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuCSV_M4


% --- Executes during object creation, after setting all properties.
function popupmenuCSV_M4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuCSV_M4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
