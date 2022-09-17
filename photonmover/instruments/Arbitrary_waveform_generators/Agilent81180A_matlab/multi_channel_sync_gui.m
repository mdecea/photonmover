 function varargout = multi_channel_sync_gui(varargin)
% MULTI_CHANNEL_SYNC_GUI MATLAB code for multi_channel_sync_gui.fig
%      MULTI_CHANNEL_SYNC_GUI, by itself, creates a new MULTI_CHANNEL_SYNC_GUI or raises the existing
%      singleton*.
%
%      H = MULTI_CHANNEL_SYNC_GUI returns the handle to a new MULTI_CHANNEL_SYNC_GUI or the handle to
%      the existing singleton*.
%
%      MULTI_CHANNEL_SYNC_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTI_CHANNEL_SYNC_GUI.M with the given input arguments.
%
%      MULTI_CHANNEL_SYNC_GUI('Property','Value',...) creates a new MULTI_CHANNEL_SYNC_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before multi_channel_sync_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to multi_channel_sync_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help multi_channel_sync_gui

% Last Modified by GUIDE v2.5 13-Jun-2015 20:50:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @multi_channel_sync_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @multi_channel_sync_gui_OutputFcn, ...
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


% --- Executes just before multi_channel_sync_gui is made visible.
function multi_channel_sync_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to multi_channel_sync_gui (see VARARGIN)

% Choose default command line output for multi_channel_sync_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

arbConfig = loadArbConfig();
if (~isempty(arbConfig))
    if (isempty(strfind(arbConfig.model, 'bit')))
        errordlg({'Currently, only M8190A direct modes (12bit or 14bit) are' ...
            'implemented in this demo utility.' ...
            ' ' ...
            'Please use the "Configure Instrument Connection" utility' ...
            'to configure M8190A 12bit or 14bit mode under "Instrument model"'});
        close(handles.iqtool);
        return;
    end
    set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate'));
end
set(handles.popupmenuWaveform, 'Value', 3);

if (isfield(arbConfig, 'useM8192A') && arbConfig.useM8192A ~= 0)
    set(handles.radiobuttonM8192A, 'Value', 1);
end

% UIWAIT makes multi_channel_sync_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = multi_channel_sync_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonConnectionDiagram.
function pushbuttonConnectionDiagram_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonConnectionDiagram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (isdeployed)
    [~, result] = system('path');
    path = fullfile(char(regexpi(result, 'Path=(.*?);', 'tokens', 'once')), 'M8190A_sync_setup2.gif');
else
    path = fullfile(fileparts(which('multi_channel_sync_gui.m')), 'M8190A_sync_example', 'M8190A_sync_setup2.gif');
end
try
    system(path);
catch
    errordlg(['Can''t display: ' path]);
end


% --- Executes on button press in pushbuttonManualDeskew.
function pushbuttonManualDeskew_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonManualDeskew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox({'Downloading Calibration data to both AWG modules...' ...
    ' ' ...
    'Please observe the analog outputs (resp. marker outputs) of both' ...
    'modules on an oscilloscope and use the Soft Front Panel to de-skew' ...
    'the channels'}, 'replace');
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
slaveClkList = get(handles.popupmenuSlaveClk, 'String');
slaveClk = slaveClkList{get(handles.popupmenuSlaveClk, 'Value')};
useMarkers = get(handles.radiobuttonMarkersConnected, 'Value');
triggered = get(handles.radiobuttonTriggered, 'Value');
waveformID = get(handles.popupmenuWaveform, 'Value');
fixedSkew = [get(handles.sliderSkewM1C1, 'Value') ...
             get(handles.sliderSkewM1C2, 'Value') ...
             get(handles.sliderSkewM2C1, 'Value') ...
             get(handles.sliderSkewM2C2, 'Value')] * 1e-12;
multi_channel_sync('cmd', 'manualDeskew', 'fixedSkew', fixedSkew, ...
    'sampleRate', sampleRate, 'slaveClk', slaveClk, 'useMarkers', useMarkers, ...
    'triggered', triggered, 'waveformID', waveformID);
pause(2);
try
    close(hMsgBox);
catch
end
enableStartStop(handles);


function enableStartStop(handles)
set(handles.pushbuttonStart, 'Enable', 'on');
set(handles.pushbuttonStop, 'Enable', 'on');
set(handles.pushbuttonDownload, 'Enable', 'on');
set(handles.pushbuttonTrigger, 'Enable', 'on');
set(handles.textWaveform, 'Enable', 'on');
set(handles.popupmenuWaveform, 'Enable', 'on');
set(handles.radiobuttonTriggered, 'Enable', 'on');
set(handles.radiobuttonContinuous, 'Enable', 'on');


% --- Executes on button press in pushbuttonAutoDeskew.
function pushbuttonAutoDeskew_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAutoDeskew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox({'Downloading Calibration data to both AWG modules...'}, 'replace');
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
slaveClkList = get(handles.popupmenuSlaveClk, 'String');
slaveClk = slaveClkList{get(handles.popupmenuSlaveClk, 'Value')};
useMarkers = get(handles.radiobuttonMarkersConnected, 'Value');
triggered = get(handles.radiobuttonTriggered, 'Value');
waveformID = get(handles.popupmenuWaveform, 'Value');
fixedSkew = [get(handles.sliderSkewM1C1, 'Value') ...
             get(handles.sliderSkewM1C2, 'Value') ...
             get(handles.sliderSkewM2C1, 'Value') ...
             get(handles.sliderSkewM2C2, 'Value')] * 1e-12;
multi_channel_sync('cmd', 'autoDeskew', 'fixedSkew', fixedSkew, ...
    'sampleRate', sampleRate, 'slaveClk', slaveClk, 'useMarkers', useMarkers, ...
    'triggered', triggered, 'waveformID', waveformID);
try
    close(hMsgBox);
catch
end
enableStartStop(handles);


function editVisaAddressScope_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddressScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddressScope as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddressScope as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddressScope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddressScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenuWaveform.
function popupmenuWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuWaveform contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuWaveform


% --- Executes during object creation, after setting all properties.
function popupmenuWaveform_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonStart.
function pushbuttonStart_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox({'Downloading waveforms...'}, 'replace');
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
slaveClkList = get(handles.popupmenuSlaveClk, 'String');
slaveClk = slaveClkList{get(handles.popupmenuSlaveClk, 'Value')};
useMarkers = get(handles.radiobuttonMarkersConnected, 'Value');
triggered = get(handles.radiobuttonTriggered, 'Value');
waveformID = get(handles.popupmenuWaveform, 'Value');
fixedSkew = [get(handles.sliderSkewM1C1, 'Value') ...
             get(handles.sliderSkewM1C2, 'Value') ...
             get(handles.sliderSkewM2C1, 'Value') ...
             get(handles.sliderSkewM2C2, 'Value')] * 1e-12;
multi_channel_sync('cmd', 'start', 'fixedSkew', fixedSkew, ...
    'sampleRate', sampleRate, 'slaveClk', slaveClk, 'useMarkers', useMarkers, ...
    'triggered', triggered, 'waveformID', waveformID);
try
    close(hMsgBox);
catch
end



% --- Executes on button press in pushbuttonStop.
function pushbuttonStop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
multi_channel_sync('cmd', 'stop');


% --- Executes on button press in pushbuttonTrigger.
function pushbuttonTrigger_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
waveformID = get(handles.popupmenuWaveform, 'Value');
multi_channel_sync('cmd', 'trigger', 'waveformID', waveformID);


% --- Executes on selection change in popupmenuMode.
function popupmenuMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuMode


% --- Executes during object creation, after setting all properties.
function popupmenuMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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
    msgbox(ex.message);
end
arbConfig = loadArbConfig();
if (isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
    set(handles.editSampleRate,'BackgroundColor','white');
else
    set(handles.editSampleRate,'BackgroundColor','red');
end


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


% --- Executes on selection change in popupmenuSlaveClk.
function popupmenuSlaveClk_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSlaveClk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSlaveClk contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSlaveClk


% --- Executes during object creation, after setting all properties.
function popupmenuSlaveClk_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSlaveClk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM1C1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM1C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM1C1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM1C1 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewM1C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM1C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM1C2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM1C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM1C2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM1C2 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewM1C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM1C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM2C1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM2C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM2C1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM2C1 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewM2C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM2C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM2C2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM2C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM2C2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM2C2 as a double
editSkewAction(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editSkewM2C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM2C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editSkewAction(hObject, handles)
editTag = get(hObject, 'Tag');
sliderTag = ['handles.sliderSkew' editTag(9:12)];
sliderPtr = eval(sliderTag);
val = [];
try
    val = round(str2double(get(hObject, 'String')));
    if (val < get(handles.sliderPtr, 'Min'))
        val = get(handles.sliderPtr, 'Min');
    end
    if (val > get(handles.sliderPtr, 'Max'))
        val = get(handles.sliderPtr, 'Max');
    end
catch ex
end
if (isempty(val) || isnan(val))
    val = get(handles.sliderPtr, 'Value');
end
if (isscalar(val))
    set(sliderPtr, 'Value', val);
    set(hObject, 'String', num2str(val));
end


function sliderSkewAction(hObject, handles)
sliderTag = get(hObject, 'Tag');
editTag = ['handles.editSkew' sliderTag(11:14)];
editPtr = eval(editTag);
set(editPtr, 'String', num2str(get(hObject, 'Value')));


% --- Executes on slider movement.
function sliderSkewM1C1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);

% --- Executes during object creation, after setting all properties.
function sliderSkewM1C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewM1C2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewM1C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewM2C1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewM2C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewM2C2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewM2C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes when selected object is changed in uipanel1.
function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel1 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
useM8192A = 0;
if (isfield(arbConfig, 'useM8192A') && arbConfig.useM8192A ~= 0)
    useM8192A = 1;
end
switch (get(eventdata.NewValue, 'Tag'))
    case 'radiobuttonM8192A'
        if (~useM8192A)
            errordlg({'If you want to use the M8192A SYNC module,' 'please check the checkbox in the Config window'});
            set(eventdata.OldValue, 'Value', 1);
            return
        end
    otherwise
        if (useM8192A)
            errordlg({'If you don''t want to use the M8192A SYNC module,' 'please uncheck the checkbox in the Config window'});
            set(handles.radiobuttonM8192A, 'Value', 1);
            return
        end
end

% --------------------------------------------------------------------
function uipanel1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to uipanel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
editSampleRate_Callback(hObject, eventdata, handles);
result = 1;
