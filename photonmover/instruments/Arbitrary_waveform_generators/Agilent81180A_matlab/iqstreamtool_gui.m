function varargout = iqstreamtool_gui(varargin)
% IQSTREAMTOOL_GUI MATLAB code for iqstreamtool_gui.fig
%      IQSTREAMTOOL_GUI, by itself, creates a new IQSTREAMTOOL_GUI or raises the existing
%      singleton*.
%
%      H = IQSTREAMTOOL_GUI returns the handle to a new IQSTREAMTOOL_GUI or the handle to
%      the existing singleton*.
%
%      IQSTREAMTOOL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQSTREAMTOOL_GUI.M with the given input arguments.
%
%      IQSTREAMTOOL_GUI('Property','Value',...) creates a new IQSTREAMTOOL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqstreamtool_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqstreamtool_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqstreamtool_gui

% Last Modified by GUIDE v2.5 16-Oct-2019 13:16:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqstreamtool_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqstreamtool_gui_OutputFcn, ...
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


% --- Executes just before iqstreamtool_gui is made visible.
function iqstreamtool_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqstreamtool_gui (see VARARGIN)

% Choose default command line output for iqstreamtool_gui
handles.output = hObject;

checkfields([], [], handles);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqstreamtool_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqstreamtool_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
arbConfig = loadArbConfig();
digPort = evalin('base', ['[' get(handles.editDigitizerODIPort, 'String') ']']);
if (length(digPort) ~= length(arbConfig.recorderPorts))
    set(handles.editDigitizerODIPort, 'String', sprintf('%d ', 1:length(arbConfig.recorderPorts)));
end
varargout{1} = handles.output;



function result = checkfields(~, ~, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
arbConfig = loadArbConfig();
switch arbConfig.model
    case 'M8121A_12bit'; set(handles.popupmenuAWGMode, 'Value', 1);
    case 'M8121A_14bit'; set(handles.popupmenuAWGMode, 'Value', 2);
    case 'M8121A_DUC_x3'; set(handles.popupmenuAWGMode, 'Value', 3);
    case 'M8121A_DUC_x12'; set(handles.popupmenuAWGMode, 'Value', 4);
    case 'M8121A_DUC_x24'; set(handles.popupmenuAWGMode, 'Value', 5);
    case 'M8121A_DUC_x48'; set(handles.popupmenuAWGMode, 'Value', 6);
end
if (~isempty(strfind(arbConfig.model, 'DUC')))
    set(handles.textAWGFc, 'Enable', 'on');
    set(handles.editAWGFc, 'Enable', 'on');
else
    set(handles.textAWGFc, 'Enable', 'off');
    set(handles.editAWGFc, 'Enable', 'off');
end
try
    sampleRate = evalin('base', get(handles.editAWGSampleRate, 'String'));
catch
    sampleRate = 0;
end
if (sampleRate < arbConfig.minimumSampleRate(1))
    set(handles.editAWGSampleRate, 'String', iqengprintf(arbConfig.minimumSampleRate(1)));
end
if (sampleRate > arbConfig.maximumSampleRate(1))
    set(handles.editAWGSampleRate, 'String', iqengprintf(arbConfig.maximumSampleRate(1)));
end


% --- Executes on button press in pushbuttonRecord.
function pushbuttonRecord_Callback(hObject, eventdata, handles)
exec_iqstreamtool('Record', hObject, handles);
pushbuttonUpdateListing_Callback([], eventdata, handles)


% --- Executes on button press in pushbuttonPlayback.
function pushbuttonPlayback_Callback(hObject, eventdata, handles)
exec_iqstreamtool('Playback', hObject, handles);


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
exec_iqstreamtool('Download', hObject, handles);


% --- Executes on button press in pushbuttonUpload.
function pushbuttonUpload_Callback(hObject, eventdata, handles)
exec_iqstreamtool('Upload', hObject, handles);
pushbuttonUpdateListing_Callback([], eventdata, handles)


function res = exec_iqstreamtool(cmd, hObject, handles)
res = [];
arbConfig = loadArbConfig();
params = getParams(handles);
set(handles.pushbuttonRecord, 'Enable', 'off');
set(handles.pushbuttonPlayback, 'Enable', 'off');
set(handles.pushbuttonDownload, 'Enable', 'off');
set(handles.pushbuttonUpload, 'Enable', 'off');
set(handles.pushbuttonDelete, 'Enable', 'off');
set(handles.pushbuttonUpdateListing, 'Enable', 'off');
set(handles.pushbuttonRecordingName, 'Enable', 'off');
drawnow();
try
    res = iqstreamtool('arbConfig', arbConfig, 'cmd', cmd, 'params', params);
%        'logFct', @(eventdata)iqstreamtool_gui('addLog', hObject, eventdata, guidata(hObject)));
catch ex
    if (isprop(ex, 'stack'))
        msg = sprintf('%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line);
    else
        msg = ex.message;
    end
    errordlg(msg);
end
set(handles.pushbuttonRecord, 'Enable', 'on');
set(handles.pushbuttonPlayback, 'Enable', 'on');
set(handles.pushbuttonDownload, 'Enable', 'on');
set(handles.pushbuttonUpload, 'Enable', 'on');
set(handles.pushbuttonDelete, 'Enable', 'on');
set(handles.pushbuttonUpdateListing, 'Enable', 'on');
set(handles.pushbuttonRecordingName, 'Enable', 'on');


function params = getParams(handles)
params = struct();
params.recordingName = strtrim(get(handles.editRecordingName, 'String'));
params.recordingLen = str2double(get(handles.editFileSize, 'String'));
params.filename = strtrim(get(handles.editFilename, 'String'));
digModeList = get(handles.popupmenuDigitizerMode, 'String');
params.digMode = digModeList{get(handles.popupmenuDigitizerMode, 'Value')};
digDDCList = get(handles.popupmenuDDC, 'String');
params.digDDC = str2double(digDDCList{get(handles.popupmenuDDC, 'Value')});
params.digPort = evalin('base', ['[' get(handles.editDigitizerODIPort, 'String') ']']);
params.awgPort = evalin('base', ['[' get(handles.editAWGODIPort, 'String') ']']);
params.awgSampleRate = evalin('base', get(handles.editAWGSampleRate, 'String'));
params.digFc = evalin('base', ['[' get(handles.editDigFc, 'String') ']']);
params.digPhaseReset = get(handles.checkboxPhaseReset, 'Value');
params.awgFc = evalin('base', get(handles.editAWGFc, 'String'));
awgFormatList = get(handles.popupmenuAWGFormat, 'String');
params.awgFormat = awgFormatList{get(handles.popupmenuAWGFormat, 'Value')};
formatList = get(handles.popupmenuFormatConversion, 'String');
params.formatConversion = formatList{get(handles.popupmenuFormatConversion, 'Value')};
params.numLoops = evalin('base', get(handles.editNumLoops, 'String'));


function editRecordingName_Callback(hObject, eventdata, handles)
% hObject    handle to editRecordingName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRecordingName as text
%        str2double(get(hObject,'String')) returns contents of editRecordingName as a double


% --- Executes during object creation, after setting all properties.
function editRecordingName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRecordingName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonRecordingName.
function pushbuttonRecordingName_Callback(hObject, eventdata, handles)
name = showRecordings('OK', hObject, handles);
if (~isempty(name))
    set(handles.editRecordingName, 'String', name);
end


% --- Executes on selection change in popupmenuDigitizerMode.
function popupmenuDigitizerMode_Callback(hObject, eventdata, handles)
modeList = get(handles.popupmenuDigitizerMode, 'String');
mode = modeList{get(handles.popupmenuDigitizerMode, 'Value')};
if (~isempty(strfind(mode, 'DDC')))
    set(handles.popupmenuDDC, 'Value', 1);
    set(handles.popupmenuDDC, 'String', {'4', '8', '16', '32', '64', '128', '256'});
    set(handles.textDigFc, 'Enable', 'on');
    set(handles.editDigFc, 'Enable', 'on');
    set(handles.textPhaseReset, 'Enable', 'on');
    set(handles.checkboxPhaseReset, 'Enable', 'on');
else
    if (get(handles.popupmenuDDC, 'Value') > 3)
        set(handles.popupmenuDDC, 'Value', 1);
    end
    set(handles.popupmenuDDC, 'String', {'1', '2', '4'});
    set(handles.textDigFc, 'Enable', 'off');
    set(handles.editDigFc, 'Enable', 'off');
    set(handles.textPhaseReset, 'Enable', 'off');
    set(handles.checkboxPhaseReset, 'Enable', 'off');
end
editFileSize_Callback([], [], handles);
calculateDigitizerDataRate(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuDigitizerMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDigitizerMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDDC.
function popupmenuDDC_Callback(hObject, eventdata, handles)
editFileSize_Callback([], [], handles);
calculateDigitizerDataRate(handles);


function calculateDigitizerDataRate(handles)
modeList = get(handles.popupmenuDigitizerMode, 'String');
mode = modeList{get(handles.popupmenuDigitizerMode, 'Value')};
ddcList = get(handles.popupmenuDDC, 'String');
ddcStr = ddcList{get(handles.popupmenuDDC, 'Value')};
ddc = str2double(ddcStr);
if (~isempty(strfind(mode, '32')))
    sampleRate = 32e9;
else
    sampleRate = 16e9;
end
if (~isempty(strfind(mode, 'DDC')))
    dataRate = 16e9/ddc*4;
    format = '16 bit I/Q';
else
    if (ddc == 1)
        dataRate = 20e9;
        format = '10 bit packed';
    else
        dataRate = 16e9/ddc*2;
        format = '16 bit real';
    end
end
sampleRate = sampleRate / ddc;
if (sampleRate >= 1e9)
    set(handles.editDigitizerSampleRate, 'String', sprintf('%g GSa/s', sampleRate/1e9));
else
    set(handles.editDigitizerSampleRate, 'String', sprintf('%g MSa/s', sampleRate/1e6));
end
if (dataRate >= 1e9)
    set(handles.editDigitizerDataRate, 'String', sprintf('%.0f GB/s', dataRate/1e9));
else
    set(handles.editDigitizerDataRate, 'String', sprintf('%.0f MB/s', dataRate/1e6));
end
set(handles.editDigitizerFormat, 'String', format);


% --- Executes during object creation, after setting all properties.
function popupmenuDDC_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDDC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editDuration_Callback(hObject, eventdata, handles)
value = -1;
try
    value = evalin('base', get(handles.editDuration, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value > 0 && value <= 100000)
    set(handles.editDuration, 'BackgroundColor', 'white');
    params = getParams(handles);
    if (~isempty(strfind(params.digMode, 'DDC')))
        dataRate = 16 / params.digDDC * 4;  % dataRate in GB/s (4 Byte per sample)
    else
        if (params.digDDC == 1)
            dataRate = 20;                    % dataRate in GB/s  (10 bit per sample)
        else
            dataRate = 16 / params.digDDC * 2; % dataRate in GB/s  (16 bit per sample)
        end
    end
    set(handles.editFileSize, 'String', iqengprintf(value * dataRate, 3));
else
    set(handles.editDuration, 'BackgroundColor', 'red');
end


% --- Executes during object creation, after setting all properties.
function editDuration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFileSize_Callback(hObject, eventdata, handles)
value = -1;
try
    value = evalin('base', get(handles.editFileSize, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value > 0 && value <= 100000)
    set(handles.editFileSize, 'BackgroundColor', 'white');
    params = getParams(handles);
    if (~isempty(strfind(params.digMode, 'DDC')))
        dataRate = 16 / params.digDDC * 4;  % dataRate in GB/s (4 Byte per sample)
    else
        if (params.digDDC == 1)
            dataRate = 20;                    % dataRate in GB/s  (10 bit per sample)
        else
            dataRate = 16 / params.digDDC * 2; % dataRate in GB/s  (16 bit per sample)
        end
    end
    set(handles.editDuration, 'String', iqengprintf(value / dataRate, 3));
else
    set(handles.editFileSize, 'BackgroundColor', 'red');
end


% --- Executes during object creation, after setting all properties.
function editFileSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFileSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editRecorderAddr_Callback(hObject, eventdata, handles)
% hObject    handle to editRecorderAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRecorderAddr as text
%        str2double(get(hObject,'String')) returns contents of editRecorderAddr as a double


% --- Executes during object creation, after setting all properties.
function editRecorderAddr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRecorderAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDigitizerAddr_Callback(hObject, eventdata, handles)
% hObject    handle to editDigitizerAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDigitizerAddr as text
%        str2double(get(hObject,'String')) returns contents of editDigitizerAddr as a double


% --- Executes during object creation, after setting all properties.
function editDigitizerAddr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDigitizerAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAWGAddr_Callback(hObject, eventdata, handles)
% hObject    handle to editAWGAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAWGAddr as text
%        str2double(get(hObject,'String')) returns contents of editAWGAddr as a double


% --- Executes during object creation, after setting all properties.
function editAWGAddr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAWGAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menuGenerateMATLAB_Callback(hObject, eventdata, handles)
% hObject    handle to menuGenerateMATLAB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function editFilename_Callback(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFilename as text
%        str2double(get(hObject,'String')) returns contents of editFilename as a double


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


% --- Executes on button press in pushbuttonFilename.
function pushbuttonFilename_Callback(hObject, eventdata, handles)
if (isfield(handles, 'LastFileName'))
    lastFilename = handles.LastFileName;
else
    lastFilename = '';
end
try
    [FileName,PathName] = uigetfile('*.*', 'Select file to load', lastFilename);
    if(FileName ~= 0)
        FileName = strcat(PathName,FileName);
        set(handles.editFilename, 'String', FileName);
        editFilename_Callback([], eventdata, handles);
        % remember pathname for next time
        handles.LastFileName = FileName;
        guidata(hObject, handles);
    end
catch
end


% --- Executes on selection change in popupmenuAWGMode.
function popupmenuAWGMode_Callback(hObject, eventdata, handles)
warndlg('Please change the AWG mode in the "Instrument Configuration" window');
checkfields([], [], handles);


% --- Executes during object creation, after setting all properties.
function popupmenuAWGMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuAWGMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editAWGFc_Callback(hObject, eventdata, handles)
% hObject    handle to editAWGFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAWGFc as text
%        str2double(get(hObject,'String')) returns contents of editAWGFc as a double


% --- Executes during object creation, after setting all properties.
function editAWGFc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAWGFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDigFc_Callback(hObject, eventdata, handles)
value = -1;
try
    value = evalin('base', get(handles.editDigFc, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value))
    set(handles.editDigFc, 'BackgroundColor', 'white');
else
    set(handles.editDigFc, 'BackgroundColor', 'red');
end


% --- Executes during object creation, after setting all properties.
function editDigFc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDigFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAWGSampleRate_Callback(hObject, eventdata, handles)
value = -1;
try
    value = evalin('base', get(handles.editAWGSampleRate, 'String'));
catch ex
    msgbox(ex.message);
end
arbConfig = loadArbConfig();
if (isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
    set(handles.editAWGSampleRate, 'BackgroundColor', 'white');
else
    set(handles.editAWGSampleRate, 'BackgroundColor', 'red');
    result = 0;
end


% --- Executes during object creation, after setting all properties.
function editAWGSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAWGSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuAWGFormat.
function popupmenuAWGFormat_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuAWGFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuAWGFormat contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuAWGFormat


% --- Executes during object creation, after setting all properties.
function popupmenuAWGFormat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuAWGFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuFormatConversion.
function popupmenuFormatConversion_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuFormatConversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuFormatConversion contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuFormatConversion


% --- Executes during object creation, after setting all properties.
function popupmenuFormatConversion_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuFormatConversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDigitizerFormat_Callback(hObject, eventdata, handles)
% hObject    handle to editDigitizerFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDigitizerFormat as text
%        str2double(get(hObject,'String')) returns contents of editDigitizerFormat as a double


% --- Executes during object creation, after setting all properties.
function editDigitizerFormat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDigitizerFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDigitizerDataRate_Callback(hObject, eventdata, handles)
% hObject    handle to editDigitizerDataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDigitizerDataRate as text
%        str2double(get(hObject,'String')) returns contents of editDigitizerDataRate as a double


% --- Executes during object creation, after setting all properties.
function editDigitizerDataRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDigitizerDataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDigitizerSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editDigitizerSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDigitizerSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editDigitizerSampleRate as a double


% --- Executes during object creation, after setting all properties.
function editDigitizerSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDigitizerSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonDelete.
function pushbuttonDelete_Callback(hObject, eventdata, handles)
name = showRecordings('Delete', hObject, handles);
if (~isempty(name))
    set(handles.editRecordingName, 'String', name);
    exec_iqstreamtool('delete', hObject, handles);
    pushbuttonUpdateListing_Callback([], eventdata, handles);
end


function name = showRecordings(buttonText, hObject, handles)
% get a list of recordings and show them in a listbox
% returns the selected recording or empty if user cancelled
listAll = exec_iqstreamtool('getrecordings', hObject, handles);
list = listAll{1};
str = cell(0, 0);
if (isfield(list(1), 'name'))   % ~isempty(list) does not work here
    str = cell(length(list), 1);
    for i = 1:length(list)
        str{i} = sprintf('%12d%12.2f%12.2f  %s', ...
            list(i).packetCount, double(list(i).length)/1e9, double(list(i).fileLength)/1e9, char(list(i).name));
    end
end
title = '     Packets   Length(GB)    File(GB) Name';
res = iqrecordinglist(str, title, buttonText);
if (~isempty(res) && res > 0 && isfield(list(1), 'name'))
    name = char(list(res).name);
else
    name = [];
end



function editDigitizerODIPort_Callback(hObject, eventdata, handles)
digPort = [];
try
    digPort = evalin('base', ['[' get(handles.editDigitizerODIPort, 'String') ']']);
    if (length(digPort) < 1 || length(digPort) > 4 || min(digPort) < 1 || max(digPort) > 4)
        digPort = [];
    end
%     arbConfig = loadArbConfig();
%     if (length(digPort) ~= length(arbConfig.recorderPorts))
%         msgbox('number of digitizer ports must match number of recorder channels');
%         digPort = [];
%     end
catch
end
if (isempty(digPort))
    set(handles.editDigitizerODIPort, 'Background', 'red');
else
    set(handles.editDigitizerODIPort, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editDigitizerODIPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDigitizerODIPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonConfig.
function pushbuttonConfig_Callback(hObject, eventdata, handles)
iqconfig();


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox3.
function listbox3_Callback(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox3


% --- Executes during object creation, after setting all properties.
function listbox3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox4.
function listbox4_Callback(hObject, eventdata, handles)
% hObject    handle to listbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox4


% --- Executes during object creation, after setting all properties.
function listbox4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonUpdateListing.
function pushbuttonUpdateListing_Callback(hObject, eventdata, handles)
listAll = exec_iqstreamtool('getrecordings', hObject, handles);
for i=1:4
    if (i <= length(listAll))
        list = listAll{i};
        title = '     Packets   Length(GB)    File(GB) Name';
        str = cell(length(list)+1, 0);
        str{1} = title;
        if (isfield(list(1), 'name'))   % ~isempty(list) does not work here
            for k = 1:length(list)
                str{k+1} = sprintf('%12d%12.2f%12.2f  %s', ...
                    list(k).packetCount, double(list(k).length)/1e9, double(list(k).fileLength)/1e9, char(list(k).name));
            end
        end
        set(handles.(['listbox' num2str(i)]), 'String', str);
        set(handles.(['listbox' num2str(i)]), 'Value', 1);
        set(handles.(['listbox' num2str(i)]), 'Enable', 'on');
    else
        set(handles.(['listbox' num2str(i)]), 'String', {'','','','-----  not available  ------'});
        set(handles.(['listbox' num2str(i)]), 'Value', 4);
        set(handles.(['listbox' num2str(i)]), 'Enable', 'inactive');
    end
end


% --- Executes on button press in checkboxPhaseReset.
function checkboxPhaseReset_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxPhaseReset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxPhaseReset



function editAWGODIPort_Callback(hObject, eventdata, handles)
% hObject    handle to editAWGODIPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAWGODIPort as text
%        str2double(get(hObject,'String')) returns contents of editAWGODIPort as a double


% --- Executes during object creation, after setting all properties.
function editAWGODIPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAWGODIPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumLoops_Callback(hObject, eventdata, handles)
% hObject    handle to editNumLoops (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumLoops as text
%        str2double(get(hObject,'String')) returns contents of editNumLoops as a double


% --- Executes during object creation, after setting all properties.
function editNumLoops_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumLoops (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
