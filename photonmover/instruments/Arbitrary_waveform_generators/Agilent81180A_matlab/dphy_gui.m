function varargout = dphy_gui(varargin)
% DPHY_GUI MATLAB code for dphy_gui.fig
%      DPHY_GUI, by itself, creates a new DPHY_GUI or raises the existing
%      singleton*.
%
%      H = DPHY_GUI returns the handle to a new DPHY_GUI or the handle to
%      the existing singleton*.
%
%      DPHY_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DPHY_GUI.M with the given input arguments.
%
%      DPHY_GUI('Property','Value',...) creates a new DPHY_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before dphy_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to dphy_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help dphy_gui

% Last Modified by GUIDE v2.5 29-Jul-2019 14:59:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dphy_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @dphy_gui_OutputFcn, ...
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


% --- Executes just before dphy_gui is made visible.
function dphy_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to dphy_gui (see VARARGIN)

% Choose default command line output for dphy_gui
handles.output = hObject;
handles.channelNames = {'A', 'B', 'C', 'Clock'};
handles.mode = 'CPHY';

% Update handles structure
guidata(hObject, handles);

cfg = loadArbConfig();
set(handles.editSampleRate, 'String', iqengprintf(cfg.defaultSampleRate));
if (~isempty(strfind(cfg.model, 'M8195A_Rev0')))
    set(handles.editSampleRate, 'String', '60e9');
    set(handles.editLPpattern, 'String', '0 3 7 0 3 7 7 0');
    set(handles.editLPhigh, 'String', '0.5');
    set(handles.editLPlow, 'String', '-0.5');
    set(handles.editHShigh, 'String', '0.4');
    set(handles.editHSlow, 'String', '-0.4');
end
if (~isempty(strfind(cfg.model, 'M8195A_Rev1')) || ~isempty(strfind(cfg.model, 'M8195A_4ch_256k')))
    set(handles.editSampleRate, 'String', '60e9');
    set(handles.editLPpattern, 'String', '0 3 7 0 3 7 7 0');
end
set(handles.editClockHigh,  'Position', get(handles.editDelayA, 'Position'));
set(handles.editClockLow,   'Position', get(handles.editDelayB, 'Position'));
set(handles.editClockDelay, 'Position', get(handles.editDelayC, 'Position'));
set(handles.editClockHigh,  'Visible', 'off');
set(handles.editClockLow,   'Visible', 'off');
set(handles.editClockDelay, 'Visible', 'off');
arbConfig = loadArbConfig();
% default channel mapping:  assign first four channels to A/B/C/clock
if (isempty(get(handles.pushbuttonChannelMapping, 'Userdata')))
%     ud = zeros(length(arbConfig.channelMask), 8);
%     cmIdx = find(arbConfig.channelMask);
%     for i = 1:4
%         if (i <= length(cmIdx))
%             ud(cmIdx(i),2*i-1) = 1;
%         else
%             break;
%         end
%     end
%     set(handles.pushbuttonChannelMapping, 'Userdata', ud);
    iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig, handles.channelNames);
end

% Numbers from 0 to 4 can be used to represent any of the 5 possible “transitions” (0 = CCW/neg, 1 = CCW/pos, 2 = CW/neg, 3 = CW/pos, 4 = samePhase). In addition, numbers between -1 and -6 can be used to represent any of the 6 possible states (+x, -x, +y, -y, +z, -z).  It is permissible to mix positive and negative numbers (i.e. states and transitions).  The individual elements can be separated by spaces or comma, e.g.:     0 4 3 2 -1 -4 3 0 2 -1 -5
% Alternatively, it is also possible to use a MATLAB expression to represent the pattern. E.g. the expression “randi([0 4], 1, 2560)” will generate 2560 random numbers between 0 and 4.  To read from a CSV file, the MATLAB command “csvread('filename')” can be used.  This will allow any sequence from a file.
% The maximum length of the pattern is limited by the amount of memory in the AWG (2 GSamples for M8190A) divided by the the sample rate multiplied by the data rate. (Example: sample rate: 12 GSa/s, data rate 1 GSym/s.  In this case, the maximum length is:  2 / 12 * 1 = 166 MSymbols)

% UIWAIT makes dphy_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = dphy_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editHSdataRate_Callback(hObject, eventdata, handles)
checkFields(handles);


% --- Executes during object creation, after setting all properties.
function editHSdataRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHSdataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLPdataRate_Callback(hObject, eventdata, handles)
% hObject    handle to editLPdataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLPdataRate as text
%        str2double(get(hObject,'String')) returns contents of editLPdataRate as a double


% --- Executes during object creation, after setting all properties.
function editLPdataRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLPdataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editHShigh_Callback(hObject, eventdata, handles)
% hObject    handle to editHShigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editHShigh as text
%        str2double(get(hObject,'String')) returns contents of editHShigh as a double


% --- Executes during object creation, after setting all properties.
function editHShigh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHShigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editHSlow_Callback(hObject, eventdata, handles)
% hObject    handle to editHSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editHSlow as text
%        str2double(get(hObject,'String')) returns contents of editHSlow as a double


% --- Executes during object creation, after setting all properties.
function editHSlow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLPhigh_Callback(hObject, eventdata, handles)
% hObject    handle to editLPhigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLPhigh as text
%        str2double(get(hObject,'String')) returns contents of editLPhigh as a double


% --- Executes during object creation, after setting all properties.
function editLPhigh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLPhigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLPlow_Callback(hObject, eventdata, handles)
% hObject    handle to editLPlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLPlow as text
%        str2double(get(hObject,'String')) returns contents of editLPlow as a double


% --- Executes during object creation, after setting all properties.
function editLPlow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLPlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLPpattern_Callback(hObject, eventdata, handles)
% hObject    handle to editLPpattern (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLPpattern as text
%        str2double(get(hObject,'String')) returns contents of editLPpattern as a double


% --- Executes during object creation, after setting all properties.
function editLPpattern_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLPpattern (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editHSpattern_Callback(hObject, eventdata, handles)
% hObject    handle to editHSpattern (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editHSpattern as text
%        str2double(get(hObject,'String')) returns contents of editHSpattern as a double


% --- Executes during object creation, after setting all properties.
function editHSpattern_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHSpattern (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
doDownload(handles, 'display');


% --- Executes on button press in pushbuttonInit.
function pushbuttonInit_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Deskewing AWGs. Please wait...', 'Please wait...', 'replace');
result = doDownload(handles, 'init');
if (isempty(result))
    set(handles.pushbuttonDownload, 'Enable', 'on');
end
try
    close(hMsgBox);
catch
end


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading Waveforms. Please wait...', 'Please wait...', 'replace');
doDownload(handles, 'run');
try
    close(hMsgBox);
catch
end


function result = doDownload(handles, cmd)
clear dParam;
dParam.mode = handles.mode;
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
dParam.lpDataRate = evalin('base', get(handles.editLPdataRate, 'String'));
dParam.hsDataRate = evalin('base', get(handles.editHSdataRate, 'String'));
dParam.lpLow = evalin('base', get(handles.editLPlow, 'String'));
dParam.hsLow = evalin('base', get(handles.editHSlow, 'String'));
dParam.lpHigh = evalin('base', get(handles.editLPhigh, 'String'));
dParam.hsHigh = evalin('base', get(handles.editHShigh, 'String'));
if (get(handles.checkboxLPenable, 'Value'))
    dParam.lpPattern = evalin('base', ['[' get(handles.editLPpattern, 'String') ']']);
else
    dParam.lpPattern = [];
end
dParam.hsPattern = evalin('base', ['[' get(handles.editHSpattern, 'String') ']']);
dParam.lpTT = evalin('base', ['[' get(handles.editLPtt, 'String') ']']);
dParam.hsTT = evalin('base', ['[' get(handles.editHStt, 'String') ']']);
dParam.lpIsi = evalin('base', ['[' get(handles.editLPisi, 'String') ']']);
dParam.hsIsi = evalin('base', ['[' get(handles.editHSisi, 'String') ']']);
dParam.lpJitter = evalin('base', ['[' get(handles.editLPjitter, 'String') ']']);
dParam.hsJitter = evalin('base', ['[' get(handles.editHSjitter, 'String') ']']);
dParam.lpJitterFreq = evalin('base', ['[' get(handles.editLPjitterFreq, 'String') ']']);
dParam.hsJitterFreq = evalin('base', ['[' get(handles.editHSjitterFreq, 'String') ']']);
dParam.DelayA = evalin('base', ['[' get(handles.editDelayA, 'String') ']']) * 1e-12;
dParam.DelayB = evalin('base', ['[' get(handles.editDelayB, 'String') ']']) * 1e-12;
dParam.DelayC = evalin('base', ['[' get(handles.editDelayC, 'String') ']']) * 1e-12;
dParam.CMAmpl = evalin('base', ['[' get(handles.editCMAmpl, 'String') ']']);
dParam.CMFreq = evalin('base', ['[' get(handles.editCMFreq, 'String') ']']);
dParam.ClockHigh =  evalin('base', ['[' get(handles.editClockHigh, 'String') ']']);
dParam.ClockLow =   evalin('base', ['[' get(handles.editClockLow, 'String') ']']);
dParam.ClockDelay = evalin('base', ['[' get(handles.editClockDelay, 'String') ']']);
dParam.Correction = get(handles.checkboxCorrection, 'Value');
dParam.scopeMode = get(handles.popupmenuScopeMode, 'Value');
dParam.chMap = get(handles.pushbuttonChannelMapping, 'UserData');
if (~isempty(dParam.lpPattern) && dParam.scopeMode == 3)
    errordlg({'For Eye Diagram display, please turn off the "Transmit LP pattern"' ...
        'checkbox and re-download'});
    result = 0;
    return;
end
result = dphy('sampleRate', sampleRate, 'cmd', cmd, 'dParam', dParam);


function editSampleRate_Callback(hObject, eventdata, handles)
checkFields(handles);


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



function editHStt_Callback(hObject, eventdata, handles)
checkFields(handles);


% --- Executes during object creation, after setting all properties.
function editHStt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHStt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLPtt_Callback(hObject, eventdata, handles)
% hObject    handle to editLPtt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLPtt as text
%        str2double(get(hObject,'String')) returns contents of editLPtt as a double


% --- Executes during object creation, after setting all properties.
function editLPtt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLPtt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editHSisi_Callback(hObject, eventdata, handles)
% hObject    handle to editHSisi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editHSisi as text
%        str2double(get(hObject,'String')) returns contents of editHSisi as a double


% --- Executes during object creation, after setting all properties.
function editHSisi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHSisi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLPisi_Callback(hObject, eventdata, handles)
% hObject    handle to editLPisi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLPisi as text
%        str2double(get(hObject,'String')) returns contents of editLPisi as a double


% --- Executes during object creation, after setting all properties.
function editLPisi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLPisi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuScopeMode.
function popupmenuScopeMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuScopeMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuScopeMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuScopeMode
if (get(handles.pushbuttonDownload, 'Enable'))
    doDownload(handles, 'scope');
end


% --- Executes during object creation, after setting all properties.
function popupmenuScopeMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuScopeMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxLPenable.
function checkboxLPenable_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxLPenable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxLPenable
val = get(handles.checkboxLPenable, 'Value');
onoff = {'off', 'on'};
oo = onoff{val+1};
set(handles.editLPdataRate, 'Enable', oo);
set(handles.editLPhigh, 'Enable', oo);
set(handles.editLPlow, 'Enable', oo);
set(handles.editLPtt, 'Enable', oo);
set(handles.editLPisi, 'Enable', oo);
set(handles.editLPjitter, 'Enable', oo);
set(handles.editLPjitterFreq, 'Enable', oo);
set(handles.editLPpattern, 'Enable', oo);



function editHSjitter_Callback(hObject, eventdata, handles)
% hObject    handle to editHSjitter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editHSjitter as text
%        str2double(get(hObject,'String')) returns contents of editHSjitter as a double


% --- Executes during object creation, after setting all properties.
function editHSjitter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHSjitter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLPjitter_Callback(hObject, eventdata, handles)
% hObject    handle to editLPjitter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLPjitter as text
%        str2double(get(hObject,'String')) returns contents of editLPjitter as a double


% --- Executes during object creation, after setting all properties.
function editLPjitter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLPjitter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)
% hObject    handle to menuFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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



function editHSjitterFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editHSjitterFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editHSjitterFreq as text
%        str2double(get(hObject,'String')) returns contents of editHSjitterFreq as a double


% --- Executes during object creation, after setting all properties.
function editHSjitterFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHSjitterFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLPjitterFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editLPjitterFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLPjitterFreq as text
%        str2double(get(hObject,'String')) returns contents of editLPjitterFreq as a double


% --- Executes during object creation, after setting all properties.
function editLPjitterFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLPjitterFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDelayA_Callback(hObject, eventdata, handles)
% hObject    handle to editDelayA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDelayA as text
%        str2double(get(hObject,'String')) returns contents of editDelayA as a double
delay = [];
try
    delay = evalin('base', get(handles.editDelayA, 'String'));
catch
end
if (~isempty(delay) && isscalar(delay) && delay >= 0 && delay <= 10000)
    set(handles.editDelayA, 'BackgroundColor', 'white');
else
    set(handles.editDelayA, 'BackgroundColor', 'red');
end

% --- Executes during object creation, after setting all properties.
function editDelayA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDelayA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function editDelayB_Callback(hObject, eventdata, handles)
% hObject    handle to editDelayB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDelayB as text
%        str2double(get(hObject,'String')) returns contents of editDelayB as a double


% --- Executes during object creation, after setting all properties.
function editDelayB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDelayB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDelayC_Callback(hObject, eventdata, handles)
% hObject    handle to editDelayC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDelayC as text
%        str2double(get(hObject,'String')) returns contents of editDelayC as a double


% --- Executes during object creation, after setting all properties.
function editDelayC_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDelayC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCMFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editCMFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCMFreq as text
%        str2double(get(hObject,'String')) returns contents of editCMFreq as a double


% --- Executes during object creation, after setting all properties.
function editCMFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCMFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCMAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to editCMAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCMAmpl as text
%        str2double(get(hObject,'String')) returns contents of editCMAmpl as a double


% --- Executes during object creation, after setting all properties.
function editCMAmpl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCMAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uipanelCPHY_DPHY.
function uipanelCPHY_DPHY_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanelCPHY_DPHY 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
tag = get(eventdata.NewValue, 'Tag');
handles.mode = tag(12:end);
switch(handles.mode)
    case 'CPHY'
        set(handles.textDelay, 'String', 'Delay (ps)');
        set(handles.textDelayA, 'String', 'A');
        set(handles.textDelayB, 'String', 'B');
        set(handles.textDelayC, 'String', 'C');
        set(handles.editClockHigh,  'Visible', 'off');
        set(handles.editClockLow,   'Visible', 'off');
        set(handles.editClockDelay, 'Visible', 'off');
        set(handles.editDelayA, 'Visible', 'on');
        set(handles.editDelayB, 'Visible', 'on');
        set(handles.editDelayC, 'Visible', 'on');
        set(handles.textHSdescription, 'String', [...
            'use 0...4 to select one of 5 possible transitions. For defined states use:\n' ...
            '-1 = +x, -2 = -x, -3 = +y, -4 = -y, -5 = +z, -6 = -z. MATLAB exp. allowed']);
        set(handles.textLPdescription, 'String', [...
            'use values 0...7, bit0=A, bit1=B, bit2=C, MATLAB expressions allowed']);
        handles.channelNames = {'A', 'B', 'C', 'Clock'};
    case 'DPHY'
        set(handles.textDelay, 'String', 'Clock');
        set(handles.textDelayA, 'String', 'High');
        set(handles.textDelayB, 'String', 'Low');
        set(handles.textDelayC, 'String', 'Delay');
        set(handles.editClockHigh,  'Visible', 'on');
        set(handles.editClockLow,   'Visible', 'on');
        set(handles.editClockDelay, 'Visible', 'on');
        set(handles.editDelayA, 'Visible', 'off');
        set(handles.editDelayB, 'Visible', 'off');
        set(handles.editDelayC, 'Visible', 'off');
        set(handles.textHSdescription, 'String', [...
            'use values 0 (low) and 1 (high). MATLAB expressions are allowed']);
        set(handles.textLPdescription, 'String', [...
            'use values 0 (low) and 7 (high). MATLAB expressions are allowed.']);
        lpPat = get(handles.editLPpattern, 'String');
        lpPat = regexprep(lpPat, ' 3 ', ' 7 ');
        set(handles.editLPpattern, 'String', lpPat);
        hsPat = get(handles.editHSpattern, 'String');
        hsPat = regexprep(hsPat, 'randi\(\[0 4\]', 'randi([0 1]');
        set(handles.editHSpattern, 'String', hsPat);
        handles.channelNames = {'D+', 'D+(copy)', 'D-', 'Clock'};
end
% Update handles structure
guidata(hObject, handles);
arbConfig = loadArbConfig();
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig, handles.channelNames);
        



function editClockHigh_Callback(hObject, eventdata, handles)
% hObject    handle to editClockHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editClockHigh as text
%        str2double(get(hObject,'String')) returns contents of editClockHigh as a double


% --- Executes during object creation, after setting all properties.
function editClockHigh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editClockHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editClockLow_Callback(hObject, eventdata, handles)
% hObject    handle to editClockLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editClockLow as text
%        str2double(get(hObject,'String')) returns contents of editClockLow as a double


% --- Executes during object creation, after setting all properties.
function editClockLow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editClockLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editClockDelay_Callback(hObject, eventdata, handles)
% hObject    handle to editClockDelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editClockDelay as text
%        str2double(get(hObject,'String')) returns contents of editClockDelay as a double


% --- Executes during object creation, after setting all properties.
function editClockDelay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editClockDelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection


% --- Executes on button press in pushbuttonShowCorrection.
function pushbuttonShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqcorrmgmt();


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


% --- Executes on button press in pushbuttonChannelMapping.
function pushbuttonChannelMapping_Callback(hObject, eventdata, handles)
arbConfig = loadArbConfig();
[val, str] = iqchanneldlg(get(hObject, 'UserData'), arbConfig, handles.iqtool, handles.channelNames);
if (~isempty(val))
    set(hObject, 'UserData', val);
    set(hObject, 'String', str);
end


function checkFields(handles)
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
hsDataRate = evalin('base', get(handles.editHSdataRate, 'String'));
hsTT = evalin('base', ['[' get(handles.editHStt, 'String') ']']);
if (hsTT < 1 && hsTT < hsDataRate / sampleRate * 4)
    set(handles.editHStt, 'Background', 'yellow');
    set(handles.editHSdataRate, 'Background', 'yellow');
else
    set(handles.editHStt, 'Background', 'white');
    set(handles.editHSdataRate, 'Background', 'white');
end


% --- Executes on button press in radiobuttonDPHY.
function radiobuttonDPHY_Callback(hObject, eventdata, handles)


% --- Executes on button press in radiobuttonCPHY.
function radiobuttonCPHY_Callback(hObject, eventdata, handles)
    

    