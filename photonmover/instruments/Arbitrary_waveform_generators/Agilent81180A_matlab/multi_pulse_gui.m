function varargout = multi_pulse_gui(varargin)
% MULTI_PULSE_GUI MATLAB code for multi_pulse_gui.fig
%      MULTI_PULSE_GUI, by itself, creates a new MULTI_PULSE_GUI or raises the existing
%      singleton*.
%
%      H = MULTI_PULSE_GUI returns the handle to a new MULTI_PULSE_GUI or the handle to
%      the existing singleton*.
%
%      MULTI_PULSE_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTI_PULSE_GUI.M with the given input arguments.
%
%      MULTI_PULSE_GUI('Property','Value',...) creates a new MULTI_PULSE_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before multi_pulse_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to multi_pulse_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help multi_pulse_gui

% Last Modified by GUIDE v2.5 14-Aug-2019 18:12:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @multi_pulse_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @multi_pulse_gui_OutputFcn, ...
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


% --- Executes just before multi_pulse_gui is made visible.
function multi_pulse_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to multi_pulse_gui (see VARARGIN)

% Choose default command line output for multi_pulse_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes multi_pulse_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);
arbConfig = loadArbConfig();
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
if (~isempty(strfind(arbConfig.model, 'N5194A')) || ...
    ~isempty(strfind(arbConfig.model, 'M8196A')) || ...
    ~isempty(strfind(arbConfig.model, 'M8194A')))
    menuBasicExample_Callback([], [], handles);
elseif (~isempty(strfind(arbConfig.model, 'M8121A')))
    menuPulseAndToneExample_Callback([], [], handles);
end
checkfields([], [], handles);


% --- Outputs from this function are returned to the command line.
function varargout = multi_pulse_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonInsertPulses.
function pushbuttonInsertPulses_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertPulses (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
default = {'0', '60e-6', '5e-6', '200e-9', '500e6', '10e6', '0', 'None', '', '', '', ''};
insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
checkPulseTable(handles, 1);


function insertRow(handles, rowData, uitable, emptyText)
% insert rowData in uitable before the currently selected row
data = get(uitable, 'Data');
% find out the currently selected row
if (isvector(uitable.UserData) && length(uitable.UserData) >= 2)
    row = uitable.UserData(1);
else
    row = 1;
end
% turn off the "click + to insert a row" text
set(emptyText, 'Visible', 'off');
numRows = size(data,1);
if (row > numRows+1)
    row = numRows+1;
end
if (numRows >= 1)    % not empty - move previous data out of the way
    data(row+1:numRows+1,:) = data(row:numRows,:);
end
if (isempty(data))   % can not assign a cell array to an empty double
    data = rowData;
else
    data(row,:) = rowData;
end
set(uitable, 'Data', data);



% --- Executes on button press in pushbuttonDeletePulses.
function pushbuttonDeletePulses_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeletePulses (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteRow(handles, handles.uitablePulses, handles.textEmptyPulses);
checkPulseTable(handles, 1);


% --- delete the currently selected row in uitable
function deleteRow(handles, uitable, emptyText)
data = get(uitable, 'Data');
% find out the currently selected row
if (isvector(uitable.UserData) && length(uitable.UserData) >= 2)
    row = uitable.UserData(1);
else
    row = 1;
end
numRows = size(data,1);
if (numRows <= 0)
    return;
end
if (numRows == 1)
    set(emptyText, 'Visible', 'on');
end
if (row > numRows)
    row = numRows;
end
newdata = data([1:row-1, row+1:numRows],:);
set(uitable, 'Data', newdata);


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Calculating waveform. Please wait...', 'Please wait...', 'replace');
calculatePulses(handles, 'display');
try
    close(hMsgBox);
catch e
end

% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading waveform. Please wait...', 'Please wait...', 'replace');
calculatePulses(handles, 'download');
try
    close(hMsgBox);
catch
end


function [numSamples, samplerate] = calculatePulses(handles, fct)
numSamples = 0;
try
    samplerate = evalin('base', get(handles.editSampleRate, 'String'));
    pulseTable = checkPulseTable(handles, 0);
    toneTable = checkToneTable(handles, 0);
    fc = evalin('base', get(handles.editCenterFrequency, 'String'));
    amplCutoff = evalin('base', get(handles.editAmplCutoff, 'String'));
    correction = get(handles.checkboxCorrection, 'Value');
    showDropped = get(handles.checkboxShowDropped, 'Value');
    maxsamples = evalin('base', get(handles.editMaxSamples, 'String'));
    normalize = get(handles.checkboxNormalize, 'Value');
    segmentNum = evalin('base', get(handles.editSegmentNumber, 'String'));
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
if (strcmp(fct, 'code'))
    chMapStr = iqchannelsetup('arraystring', get(handles.pushbuttonChannelMapping, 'UserData'));
    code = sprintf('pulseTable = struct([]);\n');
    code = sprintf('%stoneTable = struct([]);\n', code);
    for i=1:length(pulseTable)
        code = sprintf('%s%% --- pulseTable entry #%d ---\n', code, i);
        code = sprintf('%spulseTable(%d).delay = %s;\n', code, i, iqengprintf(pulseTable(i).delay));
        code = sprintf('%spulseTable(%d).pri = [%s];\n', code, i, iqengprintf(pulseTable(i).pri));
        code = sprintf('%spulseTable(%d).pw = [%s];\n', code, i, iqengprintf(pulseTable(i).pw));
        code = sprintf('%spulseTable(%d).tt = [%s];\n', code, i, iqengprintf(pulseTable(i).tt));
        code = sprintf('%spulseTable(%d).offset = [%s];\n', code, i, iqengprintf(pulseTable(i).offset));
        code = sprintf('%spulseTable(%d).span = [%s];\n', code, i, iqengprintf(pulseTable(i).span));
        code = sprintf('%spulseTable(%d).ampl = [%s];\n', code, i, iqengprintf(pulseTable(i).ampl));
        code = sprintf('%spulseTable(%d).scanType = ''%s'';\n', code, i, pulseTable(i).scanType);
        code = sprintf('%spulseTable(%d).scanPeriod = %s;\n', code, i, makeString(pulseTable(i).scanPeriod));
        code = sprintf('%spulseTable(%d).scanFct = ''%s'';\n', code, i, pulseTable(i).scanFct);
        code = sprintf('%spulseTable(%d).scanAz = %s;\n', code, i, makeString(pulseTable(i).scanAz));
        code = sprintf('%spulseTable(%d).scanSq = %s;\n', code, i, makeString(pulseTable(i).scanSq));
    end
    for i=1:length(toneTable)
        code = sprintf('%s%% --- toneTable entry #%d ---\n', code, i);
        code = sprintf('%stoneTable(%d).offset = [%s];\n', code, i, iqengprintf(toneTable(i).offset));
        code = sprintf('%stoneTable(%d).ampl = [%s];\n', code, i, iqengprintf(toneTable(i).ampl));
        code = sprintf('%stoneTable(%d).fmfreq = %s;\n', code, i, iqengprintf(toneTable(i).fmfreq));
        code = sprintf('%stoneTable(%d).fmdev = %s;\n', code, i, iqengprintf(toneTable(i).fmdev));
        code = sprintf('%stoneTable(%d).amfreq = %s;\n', code, i, iqengprintf(toneTable(i).amfreq));
        code = sprintf('%stoneTable(%d).amdepth = %s;\n', code, i, iqengprintf(toneTable(i).amdepth));
    end
    code = sprintf('%s\nfct = ''download'';\n', code);
    code = sprintf('%sfilename = ''pulses.bin'';\n', code);
    code = sprintf('%s\n[numSamples, maxVal] = multi_pulse(''sampleRate'', %s, ''pulseTable'', pulseTable, ''toneTable'', toneTable, ...\n', code, iqengprintf(samplerate));
    code = sprintf('%s            ''fc'', %g, ''correction'', %d, ...\n', code, fc, correction);
    code = sprintf('%s            ''maxsamples'', %g, ''function'', fct, ''filename'', filename, ...\n', code, maxsamples);
    code = sprintf('%s            ''normalize'', %d, ''segmentNumber'', %d, ...\n', code, normalize, segmentNum);
    code = sprintf('%s            ''amplCutoff'', %g, ''showDropped'', %d, ''chMap'', %s);\n\n', code, amplCutoff, showDropped, chMapStr);
    iqgeneratecode(handles, code);
else
    chMap = get(handles.pushbuttonChannelMapping, 'UserData');
    try
        [numSamples, maxVal] = multi_pulse('sampleRate', samplerate, 'pulseTable', pulseTable, 'toneTable', toneTable, 'fc', fc, 'correction', correction, ...
        'maxsamples', maxsamples, 'function', fct, 'amplCutoff', amplCutoff, 'showDropped', showDropped, 'chMap', chMap, ...
        'normalize', normalize, 'segmentNumber', segmentNum);
        maxValdB = 20*log10(maxVal);
        set(handles.editUsedRange, 'String', iqengprintf(maxValdB, 3));
        if (maxValdB > 0)
            set(handles.editUsedRange, 'Background', 'yellow');
        else
            set(handles.editUsedRange, 'Background', 'white');
        end
    catch ex
        errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    end
end


function res = makeString(x)
if (isempty(x))
    res = '[]';
else
    res = iqengprintf(x);
end


% --- Executes when entered data in editable cell(s) in uitablePulses.
function uitablePulses_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitablePulses (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
checkPulseTable(handles, 1);


function pulseTable = checkPulseTable(handles, doUpdate)
err = 0;
pulseTable = struct([]);
try
    data = get(handles.uitablePulses, 'Data');
    pulseTable = cell2struct(data, ...
    {'delay', 'pri', 'pw', 'tt', 'offset', 'span', 'ampl', ...
    'scanType', 'scanPeriod', 'scanFct', 'scanAz', 'scanSq'}, 2);
for i=1:length(pulseTable)
    switch (pulseTable(i).scanType)
        case {'Conical' 'Circular'}
            if (isempty(pulseTable(i).scanFct) || strcmp(pulseTable(i).scanFct, ''))
                data{i,10} = 'sinc(x).^3';
            end
            if (isempty(pulseTable(i).scanPeriod) || strcmp(pulseTable(i).scanPeriod, ''))
                data{i,9} = '3';
            end
            if (isempty(pulseTable(i).scanAz) || strcmp(pulseTable(i).scanAz, ''))
                data{i,11} = '4';
            end
            if (strcmp(pulseTable(i).scanType, 'Conical') &&  ...
                 (isempty(pulseTable(i).scanSq) || strcmp(pulseTable(i).scanSq, '')))
                data{i,12} = '4';
            end
            set(handles.uitablePulses, 'Data', data);
    end
    pulseTable(i).delay  = evalin('base', ['[' pulseTable(i).delay ']']);
    pulseTable(i).pri    = evalin('base', ['[' pulseTable(i).pri ']']);
    pulseTable(i).pw     = evalin('base', ['[' pulseTable(i).pw ']']);
    pulseTable(i).tt     = evalin('base', ['[' pulseTable(i).tt ']']);
    pulseTable(i).offset = evalin('base', ['[' pulseTable(i).offset ']']);
    pulseTable(i).span   = evalin('base', ['[' pulseTable(i).span ']']);
    pulseTable(i).ampl   = evalin('base', ['[' pulseTable(i).ampl ']']);
    pulseTable(i).scanPeriod = evalin('base', ['[' pulseTable(i).scanPeriod ']']);
    pulseTable(i).scanAz = evalin('base', ['[' pulseTable(i).scanAz ']']);
    pulseTable(i).scanSq = evalin('base', ['[' pulseTable(i).scanSq ']']);
    numPulse(i) = max([length(pulseTable(i).delay) ...
                       length(pulseTable(i).pri) ...
                       length(pulseTable(i).pw) ...
                       length(pulseTable(i).tt) ...
                       length(pulseTable(i).span) ...
                       length(pulseTable(i).offset) ...
                       length(pulseTable(i).ampl)]);
    % extend all the other parameter vectors to match the number of pulses
    pulseTable(i).pri    = fixlength(pulseTable(i).pri, numPulse(i));
    pulseTable(i).pw     = fixlength(pulseTable(i).pw, numPulse(i));
    pulseTable(i).tt     = fixlength(pulseTable(i).tt, numPulse(i));
    pulseTable(i).span   = fixlength(pulseTable(i).span, numPulse(i));
    pulseTable(i).offset = fixlength(pulseTable(i).offset, numPulse(i));
    pulseTable(i).ampl   = fixlength(pulseTable(i).ampl, numPulse(i));
    for k = 1:numPulse(i)
        if (sum(pulseTable(i).delay + pulseTable(i).pw(k) + 2*pulseTable(i).tt(k)) > pulseTable(i).pri(k))
            errordlg(sprintf('Line %d, Pulse #%d: Delay + Pulse Width + 2 * Rise/Fall Time > PRI', i, k));
            err = 1;
            break;
        end
    end
end
try
    close(hMsgBox);
catch e
end
catch e
    msgbox(e.message, 'Error', 'replace');
end
if (~err && (~exist('doUpdate', 'var') || doUpdate > 0))
    [numSamples, samplerate] = calculatePulses(handles, 'check');
    set(handles.editLoopSamples, 'String', iqengprintf(numSamples, 3));
    set(handles.editLoopTime, 'String', iqengprintf(numSamples/samplerate, 3));
end


function toneTable = checkToneTable(handles, doUpdate)
err = 0;
toneTable = [];
try
    data = get(handles.uitableTones, 'Data');
    toneTable = cell2struct(data, ...
    {'offset', 'ampl', 'fmfreq', 'fmdev', 'amfreq', 'amdepth'}, 2);
    for i=1:length(toneTable)
        toneTable(i).offset  = evalin('base', ['[' toneTable(i).offset ']']);
        if (~isvector(toneTable(i).offset)); error('frequency offset must be a vector of values'); end
        toneTable(i).ampl    = evalin('base', ['[' toneTable(i).ampl ']']);
        if (~isvector(toneTable(i).ampl)); error('magnitude must be a vector of values'); end
        toneTable(i).fmfreq  = evalin('base', ['[' toneTable(i).fmfreq ']']);
        if (~isscalar(toneTable(i).fmfreq)); error('FM frequency must be a scalar value'); end
        toneTable(i).fmdev   = evalin('base', ['[' toneTable(i).fmdev ']']);
        if (~isscalar(toneTable(i).fmdev)); error('FM deviation must be a scalar value');  end
        toneTable(i).amfreq  = evalin('base', ['[' toneTable(i).amfreq ']']);
        if (~isscalar(toneTable(i).amfreq)); error('AM frequency must be a scalar value');  end
        toneTable(i).amdepth = evalin('base', ['[' toneTable(i).amdepth ']']);
        if (~isscalar(toneTable(i).amdepth)); error('AM depth must be a scalar value');  end
    end
catch e
    err = 1;
    msgbox(e.message, 'Error', 'replace');
end
if (~err && (~exist('doUpdate', 'var') || doUpdate > 0))
    [numSamples, samplerate] = calculatePulses(handles, 'check');
    set(handles.editLoopSamples, 'String', iqengprintf(numSamples, 3));
    set(handles.editLoopTime, 'String', iqengprintf(numSamples/samplerate, 3));
end


% --- Executes when selected cell(s) is changed in uitablePulses.
function uitablePulses_CellSelectionCallback(hObject, eventdata, handles)
% remember the current selected position in the object's UserData
if (~isempty(eventdata.Indices))
    hObject.UserData = eventdata.Indices;
end



function editCenterFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to editCenterFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCenterFrequency as text
%        str2double(get(hObject,'String')) returns contents of editCenterFrequency as a double


% --- Executes during object creation, after setting all properties.
function editCenterFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCenterFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);


% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection


% --------------------------------------------------------------------
function menuAntennaScanExample_Callback(hObject, eventdata, handles)
% hObject    handle to menuAntennaScanExample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
set(handles.uitablePulses, 'Data', cell(0,length(get(handles.uitablePulses, 'ColumnName'))));
set(handles.uitableTones, 'Data', cell(0,length(get(handles.uitableTones, 'ColumnName'))));
if (~isempty(strfind(arbConfig.model, 'DUC')))
    default = {'60e-6', '750e-6', '2.7e-6', '270e-9', '[-5 -33 6 25 36]*1e6', '0', '-8', 'Circular', '5.76/2', 'sinc(x).^3', '4', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'40e-6', '1080e-6', '13e-6', '1300e-9', '-2e6', '50e6', '-10', 'Circular', '4.32', 'sinc(x).^3', '6', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'30e-6', '335.768e-6 335.768e-6 379.724e-6 379.724e-6 344.784e-6 344.784e-6 379.724e-6 379.724e-6', ...
        '1.5e-6', '150e-9', '-17e6', '10e6', '0', 'Circular', '8.64', 'sinc(x).^3', '4', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'15e-6', '100e-6', '8e-6', '800e-9', '33e6', '0', '-5', 'Conical', '0.18', 'sinc(x).^3', '2', '4'};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'0', '100e-6', '5e-6', '500e-9', '-37e6', '0', '0', 'Circular', '2.16', 'sinc(x).^3', '2', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
else
    default = {'60e-6', '750e-6', '2.7e-6', '270e-9', '1e6', '0', '-8', 'Circular', '2.88', 'sinc(x).^3', '20', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'40e-6', '1080e-6', '13e-6', '1300e-9', '-2e6', '50e6', '0', 'Circular', '4.32', 'sinc(x).^3', '5', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'30e-6', '335e-6', '1.5e-6', '150e-9', '-17e6', '10e6', '0', 'Circular', '8.64', 'sinc(x).^3', '20', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'15e-6', '200e-6', '8e-6', '800e-9', '33e6', '0', '-5', 'Conical', '0.36', 'sinc(x).^3', '2', '4'};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    %default = {'0', '100e-6', '5e-6', '500e-9', '-37e6', '0', '-3', 'Circular', '2.16', 'sinc(x).^3', '10', ''};
    %insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    set(handles.editAmplCutoff, 'String', '-30');
end
checkPulseTable(handles, 1);


% --------------------------------------------------------------------
function menuSimpleAntennaScan_Callback(hObject, eventdata, handles)
% hObject    handle to menuSimpleAntennaScan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.uitablePulses, 'Data', cell(0,length(get(handles.uitablePulses, 'ColumnName'))));
set(handles.uitableTones, 'Data', cell(0,length(get(handles.uitableTones, 'ColumnName'))));
default = {'0', '20e-6', '5e-6', '50e-9', '-50e6', '0', '0', 'Circular', '0.1', 'sinc(x).^2', '20', ''};
insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
default = {'10e-6', '20e-6', '5e-6', '50e-9', '200e6', '0', '0', 'Conical', '0.05', 'sinc(x).^2', '4', '4'};
insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
checkPulseTable(handles, 1);


% --------------------------------------------------------------------
function menuBasicExample_Callback(hObject, eventdata, handles)
% hObject    handle to menuBasicExample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
set(handles.uitablePulses, 'Data', cell(0,length(get(handles.uitablePulses, 'ColumnName'))));
set(handles.uitableTones, 'Data', cell(0,length(get(handles.uitableTones, 'ColumnName'))));
if (~isempty(strfind(arbConfig.model, 'DUC')))
    default = {'0', '60e-6', '5e-6', '20e-9', '50e6', '50e6', '0', 'None', '', '', '', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'0.2e-6', '10e-6', '1e-6', '100e-9', '-30e6', '10e6', '0', 'None', '', '', '', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'8e-6', '40e-6', '10e-6', '100e-9', '-10e6', '1e6', '-5', 'None', '', '', '', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'20e-6', '30e-6', '2e-6', '200e-9', '-60e6', '20e6', '0', 'None', '', '', '', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
else
    default = {'0', '6e-6', '0.5e-6', '2e-9', '50e6', '50e6', '0', 'None', '', '', '', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'0.2e-6', '1e-6', '0.1e-6', '10e-9', '-30e6', '10e6', '0', 'None', '', '', '', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'0.8e-6', '4e-6', '1e-6', '10e-9', '-10e6', '1e6', '-5', 'None', '', '', '', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
    default = {'2e-6', '3e-6', '0.2e-6', '20e-9', '-60e6', '20e6', '0', 'None', '', '', '', ''};
    insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
end
checkPulseTable(handles, 1);



% --------------------------------------------------------------------
function menuPulseAndToneExample_Callback(hObject, eventdata, handles)
% hObject    handle to menuPulseAndToneExample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
set(handles.uitablePulses, 'Data', cell(0,length(get(handles.uitablePulses, 'ColumnName'))));
set(handles.uitableTones, 'Data', cell(0,length(get(handles.uitableTones, 'ColumnName'))));
% pulses
default = {'0', '20e-6', '5e-6', '50e-9', '-200e6', '0', '0', 'None', '', '', '', ''};
insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
default = {'0', '5e-6', '2e-6', '50e-9', '200e6', '200e6', '0', 'None', '', '', '', ''};
insertRow(handles, default, handles.uitablePulses, handles.textEmptyPulses);
% tones
default = {'1e9 1.2e9', '0', '50e3', '300e6', '25e3', '1'};
insertRow(handles, default, handles.uitableTones, handles.textEmptyTones);
default = {'-500e6', '0', '0', '0', '150e3', '0.5'};
insertRow(handles, default, handles.uitableTones, handles.textEmptyTones);
checkPulseTable(handles, 1);
checkToneTable(handles, 1);



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



function editAmplCutoff_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplCutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editAmplCutoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplCutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxShowDropped.
function checkboxShowDropped_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxShowDropped (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxShowDropped


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
[arbConfig, saConfig] = loadArbConfig();
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
% --- editMaxSamples
value = -1;
try
    value = evalin('base', get(handles.editMaxSamples, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && value >= 0)
    set(handles.editMaxSamples, 'BackgroundColor', 'white');
else
    set(handles.editMaxSamples, 'BackgroundColor', 'red');
    result = 0;
end
% --- editMaxTime
value = -1;
try
    value = evalin('base', get(handles.editMaxTime, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && value >= 0)
    set(handles.editMaxTime, 'BackgroundColor', 'white');
else
    set(handles.editMaxTime, 'BackgroundColor', 'red');
    result = 0;
end
% --- editAmplCutoff
value = [];
try
    value = evalin('base', get(handles.editAmplCutoff, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && value <= 0)
    set(handles.editAmplCutoff, 'BackgroundColor', 'white');
else
    set(handles.editAmplCutoff, 'BackgroundColor', 'red');
    result = 0;
end
set(handles.pushbuttonChannelMapping, 'UserData', []);
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig);



% --- Executes when iqtool is resized.
function iqtool_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to iqtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    posWindow = get(hObject, 'Position');
    posTable = get(handles.uitablePulses, 'Position');
    posTable(4) = posWindow(4) - 340;
    set(handles.uitablePulses, 'Position', posTable);
catch 
end


% --------------------------------------------------------------------
function menuSaveWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
calculatePulses(handles, 'save');


% --------------------------------------------------------------------
function menuGenerateCode_Callback(hObject, eventdata, handles)
% hObject    handle to menuGenerateCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
calculatePulses(handles, 'code');



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkfields(hObject, eventdata, handles);
checkPulseTable(handles, 1);
editMaxSamples_Callback([], [], handles);


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



function editMaxSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editMaxSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkfields(hObject, eventdata, handles);
try
    samplerate = evalin('base', get(handles.editSampleRate, 'String'));
    val = evalin('base', get(handles.editMaxSamples, 'String'));
    set(handles.editMaxTime, 'String', iqengprintf(val / samplerate, 3));
catch
end


% --- Executes during object creation, after setting all properties.
function editMaxSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMaxSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLoopTime_Callback(hObject, eventdata, handles)
% hObject    handle to editLoopTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLoopTime as text
%        str2double(get(hObject,'String')) returns contents of editLoopTime as a double


% --- Executes during object creation, after setting all properties.
function editLoopTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLoopTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editMaxTime_Callback(hObject, eventdata, handles)
% hObject    handle to editMaxTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkfields(hObject, eventdata, handles);
try
    samplerate = evalin('base', get(handles.editSampleRate, 'String'));
    val = evalin('base', get(handles.editMaxTime, 'String'));
    set(handles.editMaxSamples, 'String', iqengprintf(round(val * samplerate), 3));
catch
end


% --- Executes during object creation, after setting all properties.
function editMaxTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMaxTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editLoopSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editLoopSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function editLoopSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLoopSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonInsertTones.
function pushbuttonInsertTones_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertTones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
default = {'1e9', '0', '10e3', '50e6', '20e3', '1'};
insertRow(handles, default, handles.uitableTones, handles.textEmptyTones);
checkToneTable(handles, 1);


% --- Executes on button press in pushbuttonDeleteTones.
function pushbuttonDeleteTones_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteTones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteRow(handles, handles.uitableTones, handles.textEmptyTones);
checkToneTable(handles, 1);


% --- Executes when entered data in editable cell(s) in uitableTones.
function uitableTones_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableTones (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
checkToneTable(handles, 1);


% --- Executes when selected cell(s) is changed in uitableTones.
function uitableTones_CellSelectionCallback(hObject, eventdata, handles)
% remember the current selected position in the object's UserData
if (~isempty(eventdata.Indices))
    hObject.UserData = eventdata.Indices;
end


% --- Executes on button press in pushbuttonSaveWaveform.
function pushbuttonSaveWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSaveWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
calculatePulses(handles, 'save');


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


% --- Executes on button press in pushbuttonShowCorrection.
function pushbuttonShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqcorrmgmt();


% --- Executes on button press in checkboxNormalize.
function checkboxNormalize_Callback(hObject, eventdata, handles)
val = get(handles.checkboxNormalize, 'Value');
if (val)
    set(handles.textUsedRange, 'Visible', 'off');
    set(handles.editUsedRange, 'Visible', 'off');
else
    set(handles.textUsedRange, 'Visible', 'on');
    set(handles.editUsedRange, 'Visible', 'on');
end


function editUsedRange_Callback(hObject, eventdata, handles)
% hObject    handle to editUsedRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editUsedRange as text
%        str2double(get(hObject,'String')) returns contents of editUsedRange as a double


% --- Executes during object creation, after setting all properties.
function editUsedRange_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editUsedRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSegmentNumber_Callback(hObject, eventdata, handles)
% hObject    handle to editSegmentNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSegmentNumber as text
%        str2double(get(hObject,'String')) returns contents of editSegmentNumber as a double


% --- Executes during object creation, after setting all properties.
function editSegmentNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSegmentNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
