function varargout = iqenob_gui(varargin)
% IQENOB_GUI MATLAB code for iqenob_gui.fig
%      IQENOB_GUI, by itself, creates a new IQENOB_GUI or raises the existing
%      singleton*.
%
%      H = IQENOB_GUI returns the handle to a new IQENOB_GUI or the handle to
%      the existing singleton*.
%
%      IQENOB_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQENOB_GUI.M with the given input arguments.
%
%      IQENOB_GUI('Property','Value',...) creates a new IQENOB_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqenob_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqenob_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqenob_gui

% Last Modified by GUIDE v2.5 27-Nov-2015 17:06:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqenob_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqenob_gui_OutputFcn, ...
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


% --- Executes just before iqenob_gui is made visible.
function iqenob_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqenob_gui (see VARARGIN)

% Choose default command line output for iqenob_gui
handles.output = hObject;
handles.result = [];

set(handles.popupmenuIScope, 'String', {'1A', '1B', 'DIFF1A', '1C', '1D', 'DIFF1C', '2A', '2B', 'DIFF2A', '2C', '2D', 'DIFF2C', '3A', '3B', 'DIFF3A', '3C', '3D', 'DIFF3C', '4A', '4B', 'DIFF4A', '4C', '4D', 'DIFF4C'});
if (get(handles.radiobuttonDCA, 'Value'))
    set(handles.popupmenuTrigScope, 'String', {'Front Panel'});
elseif (get(handles.radiobuttonDCA_IEEE, 'Value'))
    set(handles.popupmenuTrigScope, 'String', {'FP+PTB'});
end
try
    arbConfig = loadArbConfig();
    set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
    set(handles.editMaxFreq, 'String', iqengprintf(round(0.25 * arbConfig.defaultSampleRate/1e9)*1e9));
    set(handles.editBandwidth, 'String', iqengprintf(round(0.25 * arbConfig.defaultSampleRate/1e9)*1e9));
    if (~isempty(strfind(arbConfig.model, 'M8190A')))
        set(handles.popupmenuTrigAWG, 'String', {'1', '2', '3', '4', 'Sample Marker'});
        set(handles.popupmenuTrigAWG, 'Value', 5);
    elseif (strcmp(arbConfig.model, 'M8195A_1ch') || strcmp(arbConfig.model, 'M8195A_1ch_mrk'))
        set(handles.popupmenuTrigAWG, 'String', {'1', '2', '3', '4', 'Marker'});
        set(handles.popupmenuTrigAWG, 'Value', 5);
        set(handles.editBandwidth, 'String', iqengprintf(25e9));
        set(handles.editMaxFreq, 'String', iqengprintf(25e9));
    elseif (strcmp(arbConfig.model, 'M8195A_2ch') || strcmp(arbConfig.model, 'M8195A_2ch_mrk'))
        set(handles.popupmenuTrigAWG, 'Value', 4);
        set(handles.editBandwidth, 'String', iqengprintf(16e9));
        set(handles.editMaxFreq, 'String', iqengprintf(12.8e9));
    elseif (strcmp(arbConfig.model, 'M8195A_4ch'))
        set(handles.popupmenuTrigAWG, 'Value', 4);
        set(handles.editBandwidth, 'String', iqengprintf(8e9));
        set(handles.editMaxFreq, 'String', iqengprintf(6.4e9));
    elseif (strcmp(arbConfig.model, 'M8195A_4ch_256k'))
        set(handles.editBandwidth, 'String', iqengprintf(25e9));
        set(handles.editMaxFreq, 'String', iqengprintf(25e9));
    elseif (strcmp(arbConfig.model, 'M8195A_Rev1'))
        set(handles.editBandwidth, 'String', iqengprintf(20e9));
        set(handles.editMaxFreq, 'String', iqengprintf(20e9));
    elseif (strcmp(arbConfig.model, 'M8196A'))
        set(handles.editBandwidth, 'String', iqengprintf(32e9));
        set(handles.editMaxFreq, 'String', iqengprintf(32e9));
    elseif (strcmp(arbConfig.model, 'M8194A'))
        set(handles.editBandwidth, 'String', iqengprintf(40e9));
        set(handles.editMaxFreq, 'String', iqengprintf(40e9));
    end
catch ex
    throw(ex);
end
checkfields([], [], handles);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqenob_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


function checkfields(hObject, eventdata, handles)
try
    [arbConfig saConfig] = loadArbConfig();
catch
    errordlg('Please set up connection to AWG and Scope in "Configure instrument connection"');
    close(handles.iqtool);
    return;
end
dcaConn = (isfield(arbConfig, 'isDCAConnected') && arbConfig.isDCAConnected ~= 0);
saConn = isfield(saConfig, 'visaAddr');
if (~saConn && ~dcaConn)
    errordlg('You must set up either a connection to a DCA or Spectrum Analyzer in "Configure instrument connection"');
    close(handles.iqtool);
    return;
end
if (~saConn)
    set(handles.radiobuttonSA, 'Value', 0);
end
if (~dcaConn)
    set(handles.radiobuttonDCA, 'Value', 0);
    set(handles.radiobuttonSA, 'Value', 1);
    radiobuttonSA_Callback([], [], handles);
end
% --- editSampleRate
value = -1;
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
    set(handles.editSampleRate, 'BackgroundColor', 'white');
else
    set(handles.editSampleRate, 'BackgroundColor', 'red');
end



% --- Outputs from this function are returned to the command line.
function varargout = iqenob_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenuAWGChan.
function popupmenuAWGChan_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuAWGChan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuAWGChan contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuAWGChan


% --- Executes during object creation, after setting all properties.
function popupmenuAWGChan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuAWGChan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuAWGTrig.
function popupmenuAWGTrig_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuAWGTrig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuAWGTrig contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuAWGTrig


% --- Executes during object creation, after setting all properties.
function popupmenuAWGTrig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuAWGTrig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuScopeChan.
function popupmenuScopeChan_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuScopeChan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuScopeChan contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuScopeChan


% --- Executes during object creation, after setting all properties.
function popupmenuScopeChan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuScopeChan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuIAWG.
function popupmenuIAWG_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuIAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuIAWG contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuIAWG


% --- Executes during object creation, after setting all properties.
function popupmenuIAWG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuIAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuIScope.
function popupmenuIScope_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuIScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuIScope contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuIScope


% --- Executes during object creation, after setting all properties.
function popupmenuIScope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuIScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu7.
function popupmenu7_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu7 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu7


% --- Executes during object creation, after setting all properties.
function popupmenu7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu8.
function popupmenu8_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu8 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu8


% --- Executes during object creation, after setting all properties.
function popupmenu8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuTrigAWG.
function popupmenuTrigAWG_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuTrigAWG contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuTrigAWG


% --- Executes during object creation, after setting all properties.
function popupmenuTrigAWG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuTrigScope.
function popupmenuTrigScope_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function popupmenuTrigScope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editMaxFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editMaxFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    errordlg(['Syntax error: ' ex.message]);
end
if (isempty(val) || ~isvector(val) || min(val) < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
    checkBW(handles);
end


function checkBW(handles)
valBW = [];
valMaxFreq = [];
try
    valBW = evalin('base', ['[' get(handles.editBandwidth, 'String') ']']);
    valMaxFreq = evalin('base', ['[' get(handles.editMaxFreq, 'String') ']']);
catch ex
end
if (~isempty(valBW) && ~isempty(valMaxFreq) && max(valMaxFreq) <= valBW)
    set(handles.editBandwidth, 'Background', 'white');
    set(handles.editMaxFreq, 'Background', 'white');
else
    set(handles.editBandwidth, 'Background', 'red');
    set(handles.editMaxFreq, 'Background', 'red');
    errordlg('Max. Frequency must be less than considered bandwidth');
end


% --- Executes during object creation, after setting all properties.
function editMaxFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMaxFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumTones_Callback(hObject, eventdata, handles)
% hObject    handle to editNumTones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumTones as text
%        str2double(get(hObject,'String')) returns contents of editNumTones as a double


% --- Executes during object creation, after setting all properties.
function editNumTones_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumTones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editScopeAverage_Callback(hObject, eventdata, handles)
% hObject    handle to editScopeAverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val) || ~isscalar(val) || val < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editScopeAverage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScopeAverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAnalysisAverages_Callback(hObject, eventdata, handles)
% hObject    handle to editAnalysisAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val) || ~isscalar(val) || val < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editAnalysisAverages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAnalysisAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in utoScopeAmplitude.
function checkboxAutoScopeAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoScopeAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject, 'Value');
if (val)
    set(handles.editAmplitude, 'Enable', 'off');
else
    set(handles.editAmplitude, 'Enable', 'on');
end



function editAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val) || ~isscalar(val) || val < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end



% --- Executes during object creation, after setting all properties.
function editAmplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxScopeRST.
function checkboxScopeRST_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxScopeRST (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxScopeRST


% --- Executes on button press in checkboxAWGRST.
function checkboxAWGRST_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAWGRST (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAWGRST



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkfields(hObject, 0, handles);


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


% --- Executes on button press in checkboxAddGraph.
function checkboxAddGraph_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAddGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonRun.
function pushbuttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    maxFreq = evalin('base', ['[' get(handles.editMaxFreq, 'String') ']']);
    numTones = evalin('base', ['[' get(handles.editNumTones, 'String') ']']);
    if (length(maxFreq) == 1)
%         tones = (1:numTones)/numTones * maxFreq;
        tones = linspace(500e6,maxFreq,numTones);
    else
        tones = maxFreq;    % if maxFreq evaluates to a list of tones, then take that
    end
    bandwidth = evalin('base', ['[' get(handles.editBandwidth, 'String') ']']);
    nPer = evalin('base', ['[' get(handles.editNumPer, 'String') ']']);
    scopeAvg = evalin('base', ['[' get(handles.editScopeAverage, 'String') ']']);
    analysisAvg = evalin('base', ['[' get(handles.editAnalysisAverages, 'String') ']']);
    amplitude = evalin('base', ['[' get(handles.editAmplitude, 'String') ']']);
    awgChannels = [get(handles.popupmenuIAWG, 'Value') get(handles.popupmenuTrigAWG, 'Value')];
    iList = get(handles.popupmenuIScope, 'String');
    trigList = get(handles.popupmenuTrigScope, 'String');
    scopeChannels = { iList{get(handles.popupmenuIScope, 'Value')} ...
                      trigList{get(handles.popupmenuTrigScope, 'Value')}};
    scopeRST = get(handles.checkboxScopeRST, 'Value');
    AWGRST = get(handles.checkboxAWGRST, 'Value');
    sampleRate = evalin('base', ['[' get(handles.editSampleRate, 'String') ']']);
    autoScopeAmplitude = get(handles.checkboxAutoScopeAmplitude, 'Value');
    lgText = get(handles.editLegend, 'String');
    axes = [handles.axesEnob handles.axesSpectrum];
    sim = 0; %get(handles.popupmenuSimulation, 'Value') - 1;
    debugLevel = 0; %get(handles.popupmenuDebugLevel, 'Value') - 1;
    if (get(handles.radiobuttonDCA_IEEE, 'Value'))
        analyzer = 'DCA_IEEE';
    elseif (get(handles.radiobuttonDCA, 'Value'))
        analyzer = 'DCA';
    elseif (get(handles.radiobuttonSA, 'Value'))
        analyzer = 'SA';
    else
        errordlg('Please select an analysis device');
        return;
    end
catch ex
    errordlg({'Invalid parameter setting', ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    return;
end
% clear previous results
if (get(handles.checkboxAddGraph, 'Value') == 0)
    handles.result = [];
    guidata(hObject, handles);
end
try
    hMsgBox = waitbar(0, 'Please wait...', 'Name', 'Please wait...', 'CreateCancelBtn', 'setappdata(gcbf,''cancel'',1)');
    setappdata(hMsgBox, 'cancel', 0);
    enobs = iqenob('analyzer', analyzer, 'sim', sim, 'scopeAvg', scopeAvg, ...
            'scopeRST', scopeRST, 'AWGRST', AWGRST, ...
            'sampleRate', sampleRate, 'autoScopeAmpl', autoScopeAmplitude, ...
            'awgChannels', awgChannels, 'scopeChannels', scopeChannels, ...
            'tones', tones, 'analysisAvg', analysisAvg, 'nPer', nPer, ...
            'bandwidth', bandwidth, 'lgText', lgText, 'oldresults', handles.result, ...
            'amplitude', amplitude, 'hMsgBox', hMsgBox, 'axes', axes, ...
            'debugLevel', debugLevel);
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
try delete(hMsgBox); catch; end
if (exist('enobs', 'var') && ~isempty(enobs))
    clear thisResult;
    thisResult.enobs = enobs;
    thisResult.freqs = tones;
    thisResult.legend = lgText;
    if (isempty(handles.result))
        handles.result = thisResult;
    else
        handles.result(end+1) = thisResult;
    end
    guidata(hObject, handles);
end
% advance legend text
if (get(handles.checkboxAddGraph, 'Value') && strncmp(lgText, 'Meas #', 6))
    try
        lgText = sprintf('Meas #%d', str2double(lgText(7:end)) + 1);
        set(handles.editLegend, 'String', lgText);
    catch
    end
end


% --- Executes on button press in pushbuttoSaveAs.
function pushbuttoSaveAs_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttoSaveAs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (isempty(handles.result))
    errordlg('Nothing to save - please run a measurement first');
else
    [filename, pathname, filterindex] = uiputfile({...
    '.csv', 'CSV file (*.csv)'; ...
    }, ...
    'Save ENOB results as...');
    if (filename ~= 0)
        try
            r = handles.result;
            f = fopen(fullfile(pathname, filename), 'wt');
            for k = 1:length(r)
                fprintf(f, '%s\n', r(k).legend);
                for m = 1:length(r(k).freqs)
                    fprintf(f, '%g,%g\n', r(k).freqs(m), r(k).enobs(m));
                end
            end
            fclose(f);
        catch ex
            errordlg(ex.message);
        end
    end
end


function editLegend_Callback(hObject, eventdata, handles)
% hObject    handle to editLegend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLegend as text
%        str2double(get(hObject,'String')) returns contents of editLegend as a double


% --- Executes during object creation, after setting all properties.
function editLegend_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLegend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumPer_Callback(hObject, eventdata, handles)
% hObject    handle to editNumPer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumPer as text
%        str2double(get(hObject,'String')) returns contents of editNumPer as a double


% --- Executes during object creation, after setting all properties.
function editNumPer_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumPer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobuttonDCA.
function radiobuttonDCA_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonDCA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setAnalyzer(handles, 'DCA');

% --- Executes on button press in radiobuttonSA.
function radiobuttonSA_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setAnalyzer(handles, 'SA');


% --- Executes on button press in radiobuttonDCA_IEEE.
function radiobuttonDCA_IEEE_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonDCA_IEEE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setAnalyzer(handles, 'DCA_IEEE');


function setAnalyzer(handles, analyzer)
switch(analyzer)
    case 'DCA_IEEE'
        x = 'on';
        y = 'on';
        z = 'off';
    case 'DCA'
        x = 'on';
        y = 'on';
        z = 'on';
    case 'SA'
        x = 'off';
        y = 'on';
        z = 'off';
end
set(handles.textTrigger, 'Enable', x);
set(handles.textScopeChan, 'Enable', x);
set(handles.popupmenuTrigAWG, 'Enable', x);
set(handles.popupmenuTrigScope, 'Enable', x);
set(handles.popupmenuIScope, 'Enable', x);
set(handles.editScopeAverage, 'Enable', x);
set(handles.editNumPer, 'Enable', z);
set(handles.textNumPer, 'Enable', z);
set(handles.editBandwidth, 'Enable', y);
set(handles.textBandwidth, 'Enable', y);


function editBandwidth_Callback(hObject, eventdata, handles)
% hObject    handle to editBandwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val) || ~isscalar(val) || val < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
    checkBW(handles);
end


% --- Executes during object creation, after setting all properties.
function editBandwidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editBandwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
