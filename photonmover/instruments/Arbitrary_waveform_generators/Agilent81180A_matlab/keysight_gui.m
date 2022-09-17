function varargout = keysight_gui(varargin)
% KEYSIGHT_GUI MATLAB code for keysight_gui.fig
%      KEYSIGHT_GUI, by itself, creates a new KEYSIGHT_GUI or raises the existing
%      singleton*.
%
%      H = KEYSIGHT_GUI returns the handle to a new KEYSIGHT_GUI or the handle to
%      the existing singleton*.
%
%      KEYSIGHT_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in KEYSIGHT_GUI.M with the given input arguments.
%
%      KEYSIGHT_GUI('Property','Value',...) creates a new KEYSIGHT_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before keysight_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to keysight_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help keysight_gui

% Last Modified by GUIDE v2.5 13-Jun-2015 06:04:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @keysight_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @keysight_gui_OutputFcn, ...
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


% --- Executes just before keysight_gui is made visible.
function keysight_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to keysight_gui (see VARARGIN)

% Choose default command line output for keysight_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

arbConfig = loadArbConfig();
if (isdeployed)
    [~, result] = system('path');
    mypath = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
    set(handles.editFilename, 'String', fullfile(mypath, 'keysight_logo.png'));
end
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
duration = evalin('base',get(handles.editDuration, 'String'));
maxDuration = arbConfig.maximumSegmentSize / arbConfig.defaultSampleRate;
if (duration > maxDuration)
    duration = maxDuration;
    set(handles.editDuration, 'String', iqengprintf(duration));
end
% UIWAIT makes keysight_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = keysight_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editSampleRate as a double


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



function editCarrierFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to editCarrierFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCarrierFrequency as text
%        str2double(get(hObject,'String')) returns contents of editCarrierFrequency as a double


% --- Executes during object creation, after setting all properties.
function editCarrierFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCarrierFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDuration_Callback(hObject, eventdata, handles)
% hObject    handle to editDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDuration as text
%        str2double(get(hObject,'String')) returns contents of editDuration as a double


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


% --- Executes on button press in checkboxWiggling.
function checkboxWiggling_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxWiggling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxWiggling
w = get(hObject,'Value');
arbConfig = loadArbConfig();
if (isempty(strfind(arbConfig.model, 'M8190A')))
    set(hObject, 'Value', false);
    msgbox('Wiggling is only supported for M8190A');
    return;
end
if (w)
    set(handles.editSteps, 'Enable', 'on');
    set(handles.textSteps, 'Enable', 'on');
    set(handles.editWiggleRate, 'Enable', 'on');
    set(handles.textWiggleRate, 'Enable', 'on');
    set(handles.editWiggleDepth, 'Enable', 'on');
    set(handles.textWiggleDepth, 'Enable', 'on');
else
    set(handles.editSteps, 'Enable', 'off');
    set(handles.textSteps, 'Enable', 'off');
    set(handles.editWiggleRate, 'Enable', 'off');
    set(handles.textWiggleRate, 'Enable', 'off');
    set(handles.editWiggleDepth, 'Enable', 'off');
    set(handles.textWiggleDepth, 'Enable', 'off');
end

% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
doKeysight(handles, 0);

% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
doKeysight(handles, 1);

function doKeysight(handles, doDownload)
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
carrierFreq = evalin('base',get(handles.editCarrierFrequency, 'String'));
duration = evalin('base',get(handles.editDuration, 'String'));
steps = evalin('base',get(handles.editSteps, 'String'));
wiggleRate = evalin('base',get(handles.editWiggleRate, 'String'));
wiggleDepth = evalin('base',get(handles.editWiggleDepth, 'String'));
wiggling = get(handles.checkboxWiggling, 'Value');
average = get(handles.checkboxAverage, 'Value');
extend = evalin('base',get(handles.editExtend, 'String'));
filename = get(handles.editFilename, 'String');
keysight('sampleRate', sampleRate, 'carrierFreq', carrierFreq, ...
    'duration', duration, 'wiggling', wiggling, 'steps', steps, ...
    'wiggleRate', wiggleRate, 'wiggleDepth', wiggleDepth, ...
    'average', average, 'extend', extend, ...
    'filename', filename, 'doDownload', doDownload);


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
arbConfig = loadArbConfig();

% --- editSampleRate
value = [];
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
    set(handles.editSampleRate,'BackgroundColor','white');
else
    set(handles.editSampleRate,'BackgroundColor','red');
end



function editSteps_Callback(hObject, eventdata, handles)
% hObject    handle to editSteps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSteps as text
%        str2double(get(hObject,'String')) returns contents of editSteps as a double


% --- Executes during object creation, after setting all properties.
function editSteps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSteps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editWiggleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editWiggleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWiggleRate as text
%        str2double(get(hObject,'String')) returns contents of editWiggleRate as a double


% --- Executes during object creation, after setting all properties.
function editWiggleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWiggleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editWiggleDepth_Callback(hObject, eventdata, handles)
% hObject    handle to editWiggleDepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWiggleDepth as text
%        str2double(get(hObject,'String')) returns contents of editWiggleDepth as a double


% --- Executes during object creation, after setting all properties.
function editWiggleDepth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWiggleDepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxAverage.
function checkboxAverage_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAverage



function editExtend_Callback(hObject, eventdata, handles)
% hObject    handle to editExtend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editExtend as text
%        str2double(get(hObject,'String')) returns contents of editExtend as a double


% --- Executes during object creation, after setting all properties.
function editExtend_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editExtend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



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


% --- Executes on button press in pushbuttonGetFile.
function pushbuttonGetFile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonGetFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename pathname] = uigetfile('*.png;*.jpg');
if (filename ~= 0)
    set(handles.editFilename, 'String', strcat(pathname, filename));
end
set(handles.checkboxAverage, 'Value', 0);
