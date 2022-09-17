function varargout = multi_16channel_sync_gui(varargin)
% MULTI_16CHANNEL_SYNC_GUI M-file for multi_16channel_sync_gui.fig
%      MULTI_16CHANNEL_SYNC_GUI, by itself, creates a new MULTI_16CHANNEL_SYNC_GUI or raises the existing
%      singleton*.
%
%      H = MULTI_16CHANNEL_SYNC_GUI returns the handle to a new MULTI_16CHANNEL_SYNC_GUI or the handle to
%      the existing singleton*.
%
%      MULTI_16CHANNEL_SYNC_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTI_16CHANNEL_SYNC_GUI.M with the given input arguments.
%
%      MULTI_16CHANNEL_SYNC_GUI('Property','Value',...) creates a new MULTI_16CHANNEL_SYNC_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before multi_16channel_sync_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to multi_16channel_sync_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help multi_16channel_sync_gui

% Last Modified by GUIDE v2.5 30-Jan-2015 12:29:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @multi_16channel_sync_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @multi_16channel_sync_gui_OutputFcn, ...
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


% --- Executes just before multi_16channel_sync_gui is made visible.
function multi_16channel_sync_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to multi_16channel_sync_gui (see VARARGIN)

% Choose default command line output for iqconfig
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

try
    arbConfig = loadArbConfig();
end
if (exist('arbConfig', 'var'))
    if (isfield(arbConfig, 'visaAddrSync1'))
        set(handles.checkboxVisaAddrM8192A_1, 'Value', 1);
        set(handles.editVisaAddrM8192A_1, 'String', arbConfig.visaAddrSync1);
        set(handles.editVisaAddrM8192A_1, 'Enable', 'on');
        set(handles.pushbuttonTestM8192A_1, 'Enable', 'on');
    else
        set(handles.checkboxVisaAddrM8192A_1, 'Value', 0);
        set(handles.editVisaAddrM8192A_1, 'Enable', 'off');
        set(handles.pushbuttonTestM8192A_1, 'Enable', 'off');
    end
    if (isfield(arbConfig, 'visaAddrSync2'))
        set(handles.checkboxVisaAddrM8192A_2, 'Value', 1);
        set(handles.editVisaAddrM8192A_2, 'String', arbConfig.visaAddrSync2);
        set(handles.editVisaAddrM8192A_2, 'Enable', 'on');
        set(handles.pushbuttonTestM8192A_2, 'Enable', 'on');
    else
        set(handles.checkboxVisaAddrM8192A_2, 'Value', 0);
        set(handles.editVisaAddrM8192A_2, 'Enable', 'off');
        set(handles.pushbuttonTestM8192A_2, 'Enable', 'off');
    end
    if (isfield(arbConfig, 'visaAddrM1'))
        set(handles.checkboxVisaAddrM8190A_M1, 'Value', 1);
        set(handles.editVisaAddrM8190A_M1, 'String', arbConfig.visaAddrM1);
        set(handles.editVisaAddrM8190A_M1, 'Enable', 'on');
        set(handles.pushbuttonTestM8190A_M1, 'Enable', 'on');
    else
        set(handles.checkboxVisaAddrM8190A_M1, 'Value', 0);
        set(handles.editVisaAddrM8190A_M1, 'Enable', 'off');
        set(handles.pushbuttonTestM8190A_M1, 'Enable', 'off');
    end
    if (isfield(arbConfig, 'visaAddrS1a'))
        set(handles.checkboxVisaAddrM8190A_S1a, 'Value', 1);
        set(handles.editVisaAddrM8190A_S1a, 'String', arbConfig.visaAddrS1a);
        set(handles.editVisaAddrM8190A_S1a, 'Enable', 'on');
        set(handles.pushbuttonTestM8190A_S1a, 'Enable', 'on');
    else
        set(handles.checkboxVisaAddrM8190A_S1a, 'Value', 0);
        set(handles.editVisaAddrM8190A_S1a, 'Enable', 'off');
        set(handles.pushbuttonTestM8190A_S1a, 'Enable', 'off');
    end
    if (isfield(arbConfig, 'visaAddrS1b'))
        set(handles.checkboxVisaAddrM8190A_S1b, 'Value', 1);
        set(handles.editVisaAddrM8190A_S1b, 'String', arbConfig.visaAddrS1b);
        set(handles.editVisaAddrM8190A_S1b, 'Enable', 'on');
        set(handles.pushbuttonTestM8190A_S1b, 'Enable', 'on');
    else
        set(handles.checkboxVisaAddrM8190A_S1b, 'Value', 0);
        set(handles.editVisaAddrM8190A_S1b, 'Enable', 'off');
        set(handles.pushbuttonTestM8190A_S1b, 'Enable', 'off');
    end
    if (isfield(arbConfig, 'visaAddrS1c'))
        set(handles.checkboxVisaAddrM8190A_S1c, 'Value', 1);
        set(handles.editVisaAddrM8190A_S1c, 'String', arbConfig.visaAddrS1c);
        set(handles.editVisaAddrM8190A_S1c, 'Enable', 'on');
        set(handles.pushbuttonTestM8190A_S1c, 'Enable', 'on');
    else
        set(handles.checkboxVisaAddrM8190A_S1c, 'Value', 0);
        set(handles.editVisaAddrM8190A_S1c, 'Enable', 'off');
        set(handles.pushbuttonTestM8190A_S1c, 'Enable', 'off');
    end
    if (isfield(arbConfig, 'visaAddrM2'))
        set(handles.checkboxVisaAddrM8190A_M2, 'Value', 1);
        set(handles.editVisaAddrM8190A_M2, 'String', arbConfig.visaAddrM2);
        set(handles.editVisaAddrM8190A_M2, 'Enable', 'on');
        set(handles.pushbuttonTestM8190A_M2, 'Enable', 'on');
    else
        set(handles.checkboxVisaAddrM8190A_M2, 'Value', 0);
        set(handles.editVisaAddrM8190A_M2, 'Enable', 'off');
        set(handles.pushbuttonTestM8190A_M2, 'Enable', 'off');
    end
    if (isfield(arbConfig, 'visaAddrS2a'))
        set(handles.checkboxVisaAddrM8190A_S2a, 'Value', 1);
        set(handles.editVisaAddrM8190A_S2a, 'String', arbConfig.visaAddrS2a);
        set(handles.editVisaAddrM8190A_S2a, 'Enable', 'on');
        set(handles.pushbuttonTestM8190A_S2a, 'Enable', 'on');
    else
        set(handles.checkboxVisaAddrM8190A_S2a, 'Value', 0);
        set(handles.editVisaAddrM8190A_S2a, 'Enable', 'off');
        set(handles.pushbuttonTestM8190A_S2a, 'Enable', 'off');
    end
    if (isfield(arbConfig, 'visaAddrS2b'))
        set(handles.checkboxVisaAddrM8190A_S2b, 'Value', 1);
        set(handles.editVisaAddrM8190A_S2b, 'String', arbConfig.visaAddrS2b);
        set(handles.editVisaAddrM8190A_S2b, 'Enable', 'on');
        set(handles.pushbuttonTestM8190A_S2b, 'Enable', 'on');
    else
        set(handles.checkboxVisaAddrM8190A_S2b, 'Value', 0);
        set(handles.editVisaAddrM8190A_S2b, 'Enable', 'off');
        set(handles.pushbuttonTestM8190A_S2b, 'Enable', 'off');
    end
    if (isfield(arbConfig, 'visaAddrS2c'))
        set(handles.checkboxVisaAddrM8190A_S2c, 'Value', 1);
        set(handles.editVisaAddrM8190A_S2c, 'String', arbConfig.visaAddrS2c);
        set(handles.editVisaAddrM8190A_S2c, 'Enable', 'on');
        set(handles.pushbuttonTestM8190A_S2c, 'Enable', 'on');
    else
        set(handles.checkboxVisaAddrM8190A_S2c, 'Value', 0);
        set(handles.editVisaAddrM8190A_S2c, 'Enable', 'off');
        set(handles.pushbuttonTestM8190A_S2c, 'Enable', 'off');
    end
end

% UIWAIT makes iqconfig16 wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = multi_16channel_sync_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonSave.
function pushbuttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saveConfig(handles);


function saveConfig(handles)
if (~exist('arbConfig', 'var') || isempty(arbConfig))
    arbConfig.model = 'unknown';
    try
        arbCfgFile = iqarbConfigFilename();
    catch
        arbCfgFile = 'arbConfig.mat';
    end
    try
        load(arbCfgFile);
    catch e
        errordlg({sprintf('Can''t load configuration file (%s)', arbCfgFile) ...
            'Please use "Configure Instrument Connection" to create it.'}, 'Error');
        error('Can''t load configuration file. Please use "Configure Instrument Connection" to create it.');
    end
end
% retrieve all the field values
if (get(handles.checkboxVisaAddrM8192A_1, 'Value'))
    arbConfig.visaAddrSync1 = strtrim(get(handles.editVisaAddrM8192A_1, 'String'));
end
if (get(handles.checkboxVisaAddrM8192A_2, 'Value'))
    arbConfig.visaAddrSync2 = strtrim(get(handles.editVisaAddrM8192A_2, 'String'));
    if (get(handles.checkboxVisaAddrM8192A_1, 'Value'))
        arbConfig.useM8192A = 2;
    end
end
if (get(handles.checkboxVisaAddrM8190A_M1, 'Value'))
    arbConfig.visaAddrM1 = strtrim(get(handles.editVisaAddrM8190A_M1, 'String'));
end
if (get(handles.checkboxVisaAddrM8190A_S1a, 'Value'))
    arbConfig.visaAddrS1a = strtrim(get(handles.editVisaAddrM8190A_S1a, 'String'));
end
if (get(handles.checkboxVisaAddrM8190A_S1b, 'Value'))
    arbConfig.visaAddrS1b = strtrim(get(handles.editVisaAddrM8190A_S1b, 'String'));
end
if (get(handles.checkboxVisaAddrM8190A_S1c, 'Value'))
    arbConfig.visaAddrS1c = strtrim(get(handles.editVisaAddrM8190A_S1c, 'String'));
end
if (get(handles.checkboxVisaAddrM8190A_M2, 'Value'))
    arbConfig.visaAddrM2 = strtrim(get(handles.editVisaAddrM8190A_M2, 'String'));
end
if (get(handles.checkboxVisaAddrM8190A_S2a, 'Value'))
    arbConfig.visaAddrS2a = strtrim(get(handles.editVisaAddrM8190A_S2a, 'String'));
end
if (get(handles.checkboxVisaAddrM8190A_S2b, 'Value'))
    arbConfig.visaAddrS2b = strtrim(get(handles.editVisaAddrM8190A_S2b, 'String'));
end
if (get(handles.checkboxVisaAddrM8190A_S2c, 'Value'))
    arbConfig.visaAddrS2c = strtrim(get(handles.editVisaAddrM8190A_S2c, 'String'));
end
try
    save(arbCfgFile, 'arbConfig', 'saConfig');
    notifyIQToolWindows(handles);
catch
    msgbox(sprintf('Can''t write "%s". Please make sure the file is writeable.', arbCfgFile));
end


function notifyIQToolWindows(handles)
% Notify all open iqtool utilities that arbConfig has changed 
% Figure windows are recognized by their "iqtool" tag
try
    TempHide = get(0, 'ShowHiddenHandles');
    set(0, 'ShowHiddenHandles', 'on');
    figs = findobj(0, 'Type', 'figure', 'Tag', 'iqtool');
    set(0, 'ShowHiddenHandles', TempHide);
    for i = 1:length(figs)
        fig = figs(i);
        [path file ext] = fileparts(get(fig, 'Filename'));
        handles = guihandles(fig);
        feval(file, 'checkfields', fig, 'red', handles);
    end
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end


function editDefaultFc_Callback(hObject, eventdata, handles)
% hObject    handle to editDefaultFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDefaultFc as text
%        str2double(get(hObject,'String')) returns contents of editDefaultFc as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 0)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
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


function result = checkfields(hObject, eventdata, handles)
result = [];


function paramChangedNote(handles)
% at least one parameter has changed --> notify user that the change will
% only be sent to hardware on the next waveform download
set(handles.textNote, 'Background', 'yellow');


% --- Executes on button press in checkboxVisaAddrM8190A_M2.
function checkboxVisaAddrM8190A_M2_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8190A_M2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8190A_M2
M8190A_M2Connected = get(handles.checkboxVisaAddrM8190A_M2, 'Value');
if (~M8190A_M2Connected)
    set(handles.editVisaAddrM8190A_M2, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_M2, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_M2, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8190A_M2, 'Enable', 'on');
    set(handles.pushbuttonTestM8190A_M2, 'Enable', 'on');
end



function editVisaAddrM8190A_M2_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_M2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8190A_M2 as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8190A_M2 as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8190A_M2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_M2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestM8190A_M2.
function pushbuttonTestM8190A_M2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8190A_M2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cfg = loadArbConfig();
cfg.visaAddr = strtrim(get(handles.editVisaAddrM8190A_M2, 'String'));
testConnection(hObject, cfg);


% --- Executes on button press in checkboxVisaAddrM8192A_1.
function checkboxVisaAddrM8192A_1_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8192A_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8192A_1
M8192A_1Connected = get(handles.checkboxVisaAddrM8192A_1, 'Value');
if (~M8192A_1Connected)
    set(handles.editVisaAddrM8192A_1, 'Enable', 'off');
    set(handles.pushbuttonTestM8192A_1, 'Enable', 'off');
    set(handles.pushbuttonTestM8192A_1, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8192A_1, 'Enable', 'on');
    set(handles.pushbuttonTestM8192A_1, 'Enable', 'on');
end


function editVisaAddrM8192A_1_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8192A_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8192A_1 as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8192A_1 as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8192A_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8192A_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestM8192A_1.
function pushbuttonTestM8192A_1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8192A_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M8192ACfg = loadArbConfig();
M8192ACfg.visaAddr = strtrim(get(handles.editVisaAddrM8192A_1, 'String'));
found = 0;
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
f = iqopen(M8192ACfg);
try close(hMsgBox); catch ex; end
if (~isempty(f))
    try
        res = query(f, '*IDN?');
        if (~isempty(strfind(res, 'M8192A')))
            found = 1;
        else
            errordlg({'Unexpected IDN response:' '' res ...
                'Please specify the VISA address of an M8192A module' ...
                'and make sure the corresponding firmware is running'});
        end
    catch ex
        errordlg({'Error reading IDN:' '' ex.message});
    end
    fclose(f);
end
if (found)
    set(hObject, 'Background', 'green');
else
    set(hObject, 'Background', 'red');
end


% --- Executes on button press in checkboxVisaAddrM8192A_2.
function checkboxVisaAddrM8192A_2_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8192A_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8192A_2
M8192A_2Connected = get(handles.checkboxVisaAddrM8192A_2, 'Value');
if (~M8192A_2Connected)
    set(handles.editVisaAddrM8192A_2, 'Enable', 'off');
    set(handles.pushbuttonTestM8192A_2, 'Enable', 'off');
    set(handles.pushbuttonTestM8192A_2, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8192A_2, 'Enable', 'on');
    set(handles.pushbuttonTestM8192A_2, 'Enable', 'on');
end


function editVisaAddrM8192A_2_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8192A_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8192A_2 as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8192A_2 as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8192A_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8192A_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestM8192A_2.
function pushbuttonTestM8192A_2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8192A_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M8192ACfg = loadArbConfig();
M8192ACfg.connectionType = 'visa';
M8192ACfg.visaAddr = strtrim(get(handles.editVisaAddrM8192A_2, 'String'));
found = 0;
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
f = iqopen(M8192ACfg);
try close(hMsgBox); catch ex; end
if (~isempty(f))
    try
        res = query(f, '*IDN?');
        if (~isempty(strfind(res, 'M8192A')))
            found = 1;
        else
            errordlg({'Unexpected IDN response:' '' res ...
                'Please specify the VISA address of an M8192A module' ...
                'and make sure the corresponding firmware is running'});
        end
    catch ex
        errordlg({'Error reading IDN:' '' ex.message});
    end
    fclose(f);
end
if (found)
    set(hObject, 'Background', 'green');
else
    set(hObject, 'Background', 'red');
end


% --- Executes on button press in checkboxVisaAddrM8190A_S2c.
function checkboxVisaAddrM8190A_S2c_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8190A_S2c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8190A_S2c
M8190A_S2cConnected = get(handles.checkboxVisaAddrM8190A_S2c, 'Value');
if (~M8190A_S2cConnected)
    set(handles.editVisaAddrM8190A_S2c, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S2c, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S2c, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8190A_S2c, 'Enable', 'on');
    set(handles.pushbuttonTestM8190A_S2c, 'Enable', 'on');
end


function editVisaAddrM8190A_S2c_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S2c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8190A_S2c as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8190A_S2c as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8190A_S2c_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S2c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestM8190A_S2c.
function pushbuttonTestM8190A_S2c_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8190A_S2c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cfg = loadArbConfig();
cfg.visaAddr = strtrim(get(handles.editVisaAddrM8190A_S2c, 'String'));
testConnection(hObject, cfg);


% --- Executes on button press in checkboxVisaAddrM8190A_S1c.
function checkboxVisaAddrM8190A_S1c_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8190A_S1c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8190A_S1c
M8190A_S1cConnected = get(handles.checkboxVisaAddrM8190A_S1c, 'Value');
if (~M8190A_S1cConnected)
    set(handles.editVisaAddrM8190A_S1c, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S1c, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S1c, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8190A_S1c, 'Enable', 'on');
    set(handles.pushbuttonTestM8190A_S1c, 'Enable', 'on');
end


function editVisaAddrM8190A_S1c_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S1c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8190A_S1c as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8190A_S1c as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8190A_S1c_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S1c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestM8190A_S1c.
function pushbuttonTestM8190A_S1c_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8190A_S1c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cfg = loadArbConfig();
cfg.visaAddr = strtrim(get(handles.editVisaAddrM8190A_S1c, 'String'));
testConnection(hObject, cfg);


% --- Executes on button press in checkboxVisaAddrM8190A_S2b.
function checkboxVisaAddrM8190A_S2b_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8190A_S2b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8190A_S2b
M8190A_S2bConnected = get(handles.checkboxVisaAddrM8190A_S2b, 'Value');
if (~M8190A_S2bConnected)
    set(handles.editVisaAddrM8190A_S2b, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S2b, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S2b, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8190A_S2b, 'Enable', 'on');
    set(handles.pushbuttonTestM8190A_S2b, 'Enable', 'on');
end


function editVisaAddrM8190A_S2b_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S2b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8190A_S2b as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8190A_S2b as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8190A_S2b_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S2b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestM8190A_S2b.
function pushbuttonTestM8190A_S2b_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8190A_S2b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cfg = loadArbConfig();
cfg.visaAddr = strtrim(get(handles.editVisaAddrM8190A_S2b, 'String'));
testConnection(hObject, cfg);


% --- Executes on button press in checkboxVisaAddrM8190A_S1b.
function checkboxVisaAddrM8190A_S1b_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8190A_S1b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8190A_S1b
M8190A_S1bConnected = get(handles.checkboxVisaAddrM8190A_S1b, 'Value');
if (~M8190A_S1bConnected)
    set(handles.editVisaAddrM8190A_S1b, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S1b, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S1b, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8190A_S1b, 'Enable', 'on');
    set(handles.pushbuttonTestM8190A_S1b, 'Enable', 'on');
end


function editVisaAddrM8190A_S1b_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S1b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8190A_S1b as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8190A_S1b as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8190A_S1b_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S1b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestM8190A_S1b.
function pushbuttonTestM8190A_S1b_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8190A_S1b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cfg = loadArbConfig();
cfg.visaAddr = strtrim(get(handles.editVisaAddrM8190A_S1b, 'String'));
testConnection(hObject, cfg);


% --- Executes on button press in checkboxVisaAddrM8190A_S1a.
function checkboxVisaAddrM8190A_S1a_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8190A_S1a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8190A_S1a
M8190A_S1aConnected = get(handles.checkboxVisaAddrM8190A_S1a, 'Value');
if (~M8190A_S1aConnected)
    set(handles.editVisaAddrM8190A_S1a, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S1a, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S1a, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8190A_S1a, 'Enable', 'on');
    set(handles.pushbuttonTestM8190A_S1a, 'Enable', 'on');
end


function editVisaAddrM8190A_S1a_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S1a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8190A_S1a as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8190A_S1a as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8190A_S1a_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S1a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestM8190A_S1a.
function pushbuttonTestM8190A_S1a_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8190A_S1a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cfg = loadArbConfig();
cfg.visaAddr = strtrim(get(handles.editVisaAddrM8190A_S1a, 'String'));
testConnection(hObject, cfg);


% --- Executes on button press in checkboxVisaAddrM8190A_M1.
function checkboxVisaAddrM8190A_M1_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8190A_M1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8190A_M1
M8190A_M1Connected = get(handles.checkboxVisaAddrM8190A_M1, 'Value');
if (~M8190A_M1Connected)
    set(handles.editVisaAddrM8190A_M1, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_M1, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_M1, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8190A_M1, 'Enable', 'on');
    set(handles.pushbuttonTestM8190A_M1, 'Enable', 'on');
end



function editVisaAddrM8190A_M1_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_M1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8190A_M1 as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8190A_M1 as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8190A_M1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_M1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestM8190A_M1.
function pushbuttonTestM8190A_M1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8190A_M1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cfg = loadArbConfig();
cfg.visaAddr = strtrim(get(handles.editVisaAddrM8190A_M1, 'String'));
testConnection(hObject, cfg);


% --- Executes on button press in checkboxVisaAddrM8190A_S2a.
function checkboxVisaAddrM8190A_S2a_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8190A_S2a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8190A_S2a
% --- Executes on button press in pushbuttonTestM8190A_S2a.
M8190A_S2aConnected = get(handles.checkboxVisaAddrM8190A_S2a, 'Value');
if (~M8190A_S2aConnected)
    set(handles.editVisaAddrM8190A_S2a, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S2a, 'Enable', 'off');
    set(handles.pushbuttonTestM8190A_S2a, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8190A_S2a, 'Enable', 'on');
    set(handles.pushbuttonTestM8190A_S2a, 'Enable', 'on');
end


function editVisaAddrM8190A_S2a_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S2a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8190A_S2a as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8190A_S2a as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8190A_S2a_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8190A_S2a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pushbuttonTestM8190A_S2a_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8190A_S2a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cfg = loadArbConfig();
cfg.visaAddr = strtrim(get(handles.editVisaAddrM8190A_S2a, 'String'));
testConnection(hObject, cfg);


function result = testConnection(hObject, arbConfig)
model = arbConfig.model;
checkmodel = [];
checkfeature = [];
if (~isempty(strfind(model, 'M8190')))
    checkmodel = 'M8190A';
else
    msgbox({'The "Test Connection" function is not yet implemented for this model.' ...
            'Please download a waveform and observe error messages'});
    result = 1;
    return;
end
if (~isempty(strfind(model, 'DUC')))
    checkfeature = 'DUC';
end
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
if (iqoptcheck(arbConfig, [], checkfeature, checkmodel))
    set(hObject, 'Background', 'green');
    result = 1;
else
    set(hObject, 'Background', 'red');
    result = 0;
end
try close(hMsgBox); catch ex; end


% --- Executes on button press in pushbuttonConnectionDiagram.
function pushbuttonConnectionDiagram_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonConnectionDiagram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (isdeployed)
    [~, result] = system('path');
    path = fullfile(char(regexpi(result, 'Path=(.*?);', 'tokens', 'once')), 'M8190A_sync_setup16ch.pdf');
else
    path = fullfile(fileparts(which('multi_16channel_sync_gui.m')), 'M8190A_sync_example', 'M8190A_sync_setup16ch.pdf');
end
try
    system(path);
catch
    errordlg(['Can''t display: ' path]);
end


% --- Executes on button press in pushbuttonStart.
function pushbuttonStart_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox({'Downloading waveforms...'}, 'replace');
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
fixedSkew = [get(handles.sliderSkewM1_C1, 'Value') ...
             get(handles.sliderSkewM1_C2, 'Value') ...
             get(handles.sliderSkewM2_C1, 'Value') ...
             get(handles.sliderSkewM2_C2, 'Value') ...
             get(handles.sliderSkewS1aC1, 'Value') ...
             get(handles.sliderSkewS1aC2, 'Value') ...
             get(handles.sliderSkewS1bC1, 'Value') ...
             get(handles.sliderSkewS1bC2, 'Value') ...
             get(handles.sliderSkewS1cC1, 'Value') ...
             get(handles.sliderSkewS1cC2, 'Value') ...
             get(handles.sliderSkewS2aC1, 'Value') ...
             get(handles.sliderSkewS2aC2, 'Value') ...
             get(handles.sliderSkewS2bC1, 'Value') ...
             get(handles.sliderSkewS2bC2, 'Value') ...
             get(handles.sliderSkewS2cC1, 'Value') ...
             get(handles.sliderSkewS2cC2, 'Value')] * 1e-12;
multi_16channel_sync('cmd', 'start', 'fixedSkew', fixedSkew, ...
                     'sampleRate', sampleRate);
try
    close(hMsgBox);
catch
end


% --- Executes on button press in pushbuttonStop.
function pushbuttonStop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
multi_16channel_sync('cmd', 'stop');


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
fixedSkew = [get(handles.sliderSkewM1_C1, 'Value') ...
             get(handles.sliderSkewM1_C2, 'Value') ...
             get(handles.sliderSkewM2_C1, 'Value') ...
             get(handles.sliderSkewM2_C2, 'Value') ...
             get(handles.sliderSkewS1aC1, 'Value') ...
             get(handles.sliderSkewS1aC2, 'Value') ...
             get(handles.sliderSkewS1bC1, 'Value') ...
             get(handles.sliderSkewS1bC2, 'Value') ...
             get(handles.sliderSkewS1cC1, 'Value') ...
             get(handles.sliderSkewS1cC2, 'Value') ...
             get(handles.sliderSkewS2aC1, 'Value') ...
             get(handles.sliderSkewS2aC2, 'Value') ...
             get(handles.sliderSkewS2bC1, 'Value') ...
             get(handles.sliderSkewS2bC2, 'Value') ...
             get(handles.sliderSkewS2cC1, 'Value') ...
             get(handles.sliderSkewS2cC2, 'Value')] * 1e-12;
multi_16channel_sync('cmd', 'manualDeskew', 'fixedSkew', fixedSkew, ...
                     'sampleRate', sampleRate);
pause(2);
try
    close(hMsgBox);
catch
end
enableStartStop(handles)


% --- Executes on button press in pushbuttonAutoDeskew.
function pushbuttonAutoDeskew_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAutoDeskew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox({'Downloading Calibration data to AWG modules...'}, 'replace');
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
fixedSkew = [get(handles.sliderSkewM1_C1, 'Value') ...
             get(handles.sliderSkewM1_C2, 'Value') ...
             get(handles.sliderSkewM2_C1, 'Value') ...
             get(handles.sliderSkewM2_C2, 'Value') ...
             get(handles.sliderSkewS1aC1, 'Value') ...
             get(handles.sliderSkewS1aC2, 'Value') ...
             get(handles.sliderSkewS1bC1, 'Value') ...
             get(handles.sliderSkewS1bC2, 'Value') ...
             get(handles.sliderSkewS1cC1, 'Value') ...
             get(handles.sliderSkewS1cC2, 'Value') ...
             get(handles.sliderSkewS2aC1, 'Value') ...
             get(handles.sliderSkewS2aC2, 'Value') ...
             get(handles.sliderSkewS2bC1, 'Value') ...
             get(handles.sliderSkewS2bC2, 'Value') ...
             get(handles.sliderSkewS2cC1, 'Value') ...
             get(handles.sliderSkewS2cC2, 'Value')] * 1e-12;
multi_16channel_sync('cmd', 'autoDeskew', 'fixedSkew', fixedSkew, ...
                     'sampleRate', sampleRate);
try
    close(hMsgBox);
catch
end
enableStartStop(handles);


function enableStartStop(handles)
set(handles.pushbuttonStart, 'Enable', 'on');
set(handles.pushbuttonStop, 'Enable', 'on');


function editSkewM1_C1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM1_C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM1_C1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM1_C1 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewM1_C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM1_C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM1_C2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM1_C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM1_C2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM1_C2 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewM1_C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM1_C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM2_C1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM2_C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM2_C1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM2_C1 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewM2_C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM2_C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewM2_C2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewM2_C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewM2_C2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewM2_C2 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewM2_C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewM2_C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editSkewAction(hObject, handles)
editTag = get(hObject, 'Tag');
sliderTag = ['handles.sliderSkew' editTag(9:13)];
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
editTag = ['handles.editSkew' sliderTag(11:15)];
editPtr = eval(editTag);
set(editPtr, 'String', num2str(get(hObject, 'Value')));


% --- Executes on slider movement.
function sliderSkewM1_C1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1_C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewM1_C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1_C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewM1_C2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1_C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewM1_C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM1_C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewM2_C1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2_C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewM2_C1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2_C1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewM2_C2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2_C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewM2_C2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewM2_C2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



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



function editResolution_Callback(hObject, eventdata, handles)
% hObject    handle to editResolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editResolution as text
%        str2double(get(hObject,'String')) returns contents of editResolution as a double


% --- Executes during object creation, after setting all properties.
function editResolution_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editResolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuModel.
function popupmenuModel_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuModel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuModel


% --- Executes during object creation, after setting all properties.
function popupmenuModel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderSkewS2cC1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2cC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS2cC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2cC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewS2cC2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2cC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS2cC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2cC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editSkewS2cC2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS2cC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS2cC2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS2cC2 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS2cC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS2cC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewS2cC1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS2cC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS2cC1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS2cC1 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS2cC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS2cC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderSkewS1cC1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1cC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS1cC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1cC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewS1cC2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1cC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS1cC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1cC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editSkewS1cC2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS1cC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS1cC2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS1cC2 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS1cC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS1cC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewS1cC1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS1cC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS1cC1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS1cC1 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS1cC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS1cC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderSkewS2bC1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2bC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS2bC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2bC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewS2bC2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2bC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS2bC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2bC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editSkewS2bC2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS2bC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS2bC2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS2bC2 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS2bC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS2bC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewS2bC1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS2bC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS2bC1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS2bC1 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS2bC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS2bC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderSkewS1bC1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1bC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS1bC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1bC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewS1bC2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1bC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS1bC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1bC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editSkewS1bC2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS1bC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS1bC2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS1bC2 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS1bC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS1bC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewS1bC1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS1bC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS1bC1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS1bC1 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS1bC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS1bC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderSkewS1aC1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1aC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS1aC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1aC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewS1aC2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1aC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS1aC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS1aC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editSkewS1aC2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS1aC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS1aC2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS1aC2 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS1aC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS1aC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewS1aC1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS1aC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS1aC1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS1aC1 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS1aC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS1aC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderSkewS2aC1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2aC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS2aC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2aC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSkewS2aC2_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2aC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderSkewS2aC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSkewS2aC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editSkewS2aC2_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS2aC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS2aC2 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS2aC2 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS2aC2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS2aC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkewS2aC1_Callback(hObject, eventdata, handles)
% hObject    handle to editSkewS2aC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkewS2aC1 as text
%        str2double(get(hObject,'String')) returns contents of editSkewS2aC1 as a double
editSkewAction(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editSkewS2aC1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkewS2aC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
