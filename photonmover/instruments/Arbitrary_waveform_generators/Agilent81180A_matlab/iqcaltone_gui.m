function varargout = iqcaltone_gui(varargin)
% IQCALTONE_GUI MATLAB code for iqcaltone_gui.fig
%      IQCALTONE_GUI, by itself, creates a new IQCALTONE_GUI or raises the existing
%      singleton*.
%
%      H = IQCALTONE_GUI returns the handle to a new IQCALTONE_GUI or the handle to
%      the existing singleton*.
%
%      IQCALTONE_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQCALTONE_GUI.M with the given input arguments.
%
%      IQCALTONE_GUI('Property','Value',...) creates a new IQCALTONE_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqcaltone_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqcaltone_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqcaltone_gui

% Last Modified by GUIDE v2.5 03-Jun-2016 12:22:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqcaltone_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqcaltone_gui_OutputFcn, ...
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


% --- Executes just before iqcaltone_gui is made visible.
function iqcaltone_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqcaltone_gui (see VARARGIN)

% Choose default command line output for iqcaltone_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% set some default parameter - depending on the AWG model
arbConfig = loadArbConfig();
switch arbConfig.model
    case { '81180A' '81180B' }
        fc = 900e6;
    case { 'M8190A', 'M8190A_base', 'M8190A_14bit', 'M8190A_12bit', 'M8190A_prototype' }
        fc = 2e9;
    case { 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }
        fc = 50e6;
    case { 'M8195A_Rev0' 'M8195A_Rev1' 'M8195A_1ch' 'M8195A_1ch_mrk' 'M8195A_2ch_256k' 'M8195A_4ch_256k' }
        fc = 10e9;
    case { 'M8195A_2ch' 'M8195A_2ch_mrk' }
        fc = 10e9;
    case { 'M8195A_4ch' }
        fc = 5e9;
    case { 'M8196A' }
        fc = 10e9;
    case 'M933xA'
        fc = 300e6;
    case { '81150A', '81160A' }
        fc = 200e6;
    case { '3351x', '3352x', '3361x', '3362x' }
        fc = 10e6;
    otherwise
        fc = 100e6;
end
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editFreq, 'String', iqengprintf(fc));
set(handles.editPower, 'String', '-6');
f = iqopen();
if (~isempty(f))
    minAmpl = str2double(query(f, ':VOLT? MIN'));
    maxAmpl = str2double(query(f, ':VOLT? MAX'));
    set(handles.editStartAmpl, 'String', iqengprintf(minAmpl));
    set(handles.editStopAmpl, 'String', iqengprintf(maxAmpl));
end
% update all the fields
checkfields([], 0, handles);

if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'Enter the AWG sample rate in Hertz. For simulation, the sample rate\n' ...
    'can have any value, but if you want to download to the AWG, you have\n' ...
    'to stay within the range that is supported by the AWG.']));
set(handles.editFreq, 'TooltipString', sprintf([ ...
    'Enter the frequency to be generated in Hz.']));
set(handles.pushbuttonChannelMapping, 'TooltipString', sprintf([ ...
    'Select into which channels the real and imaginary part of the waveform\n' ...
    'is loaded. By default, I is loaded into Channel 1, Q into channel 2, but\n' ...
    'it is also possible to load the same signal into both channels.\n' ...
    'In DUC modes, both I and Q are used for the same channel.\n' ...
    'In dual-M8190A configurations, channels 3 and 4 are on the second module.']));
set(handles.pushbuttonRun, 'TooltipString', sprintf([ ...
    'Use this button to perform a calibration measurement using the parameters specified above.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
end
% UIWAIT makes iqcaltone_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqcaltone_gui_OutputFcn(hObject, eventdata, handles) 
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


function editFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
freq = -1;
try
    freq = evalin('base', get(handles.editFreq, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(freq) && freq >= get(handles.sliderFreq, 'Min') && freq <= get(handles.sliderFreq, 'Max'))
    set(handles.sliderFreq, 'Value', freq);
    set(handles.editFreq, 'BackgroundColor', 'white');
    checkfields(hObject, eventdata, handles);
else
    set(handles.editFreq, 'BackgroundColor', 'red');
end


% --- Executes during object creation, after setting all properties.
function editFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editPower_Callback(hObject, eventdata, handles)
% hObject    handle to editPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
power = -1;
try
    power = evalin('base', get(handles.editPower, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(power) && power >= get(handles.sliderPower, 'Min') && power <= get(handles.sliderPower, 'Max'))
    set(handles.sliderPower, 'Value', power);
    set(handles.editPower, 'BackgroundColor', 'white');
    checkfields(hObject, eventdata, handles);
else
    set(handles.editPower, 'BackgroundColor', 'red');
end


% --- Executes during object creation, after setting all properties.
function editPower_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonRun.
function pushbuttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    hMsgBox = waitbar(0, 'Calibrating... Please wait...', 'Name', 'Please wait...', 'CreateCancelBtn', 'setappdata(gcbf,''cancel'',1)');
    setappdata(hMsgBox, 'cancel', 0);
    doCalibrate(handles, hMsgBox, 0);
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
try delete(hMsgBox); catch; end



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



function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
[arbConfig, saConfig] = loadArbConfig();
% --- generic checks
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig, 'single');
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
% --- numFreq
numFreq = -1;
try
    numFreq = evalin('base', get(handles.editNumTones, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(numFreq) && numFreq > 0 && numFreq == floor(numFreq))
    set(handles.editNumTones, 'BackgroundColor', 'white');
else
    set(handles.editNumTones, 'BackgroundColor', 'red');
    result = 0;
end
% --- editStartFreq
startFreq = -1;
try
    startFreq = evalin('base', get(handles.editStartFreq, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(startFreq) && startFreq > 0)
    set(handles.editStartFreq, 'BackgroundColor', 'white');
else
    set(handles.editStartFreq, 'BackgroundColor', 'red');
    result = 0;
end
% --- editStopFreq
stopFreq = -1;
try
    stopFreq = evalin('base', get(handles.editStopFreq, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if ((numFreq > 1 && isscalar(stopFreq) && stopFreq > startFreq) || ...
    (numFreq == 1 && isvector(stopFreq) && min(stopFreq) > 0))
    set(handles.editStopFreq, 'BackgroundColor', 'white');
else
    set(handles.editStopFreq, 'BackgroundColor', 'red');
    result = 0;
end
% --- check output parameters only if cal is completed
cal = get(handles.iqtool, 'UserData');
if (result == 1 && ~isempty(cal))
    % Freq
    minVal = min(cal.tones);
    maxVal = max(cal.tones);
    set(handles.sliderFreq, 'Min', minVal);
    set(handles.sliderFreq, 'Max', maxVal);
    val = get(handles.sliderFreq, 'Value');
    if (val < minVal); set(handles.sliderFreq, 'Value', minVal); sliderFreq_changed(handles); end
    if (val > maxVal); set(handles.sliderFreq, 'Value', maxVal); sliderFreq_changed(handles); end
    % power
    minVal = min(min(cal.cal));
    maxVal = max(max(cal.cal));
    set(handles.sliderPower, 'Min', minVal);
    set(handles.sliderPower, 'Max', maxVal);
    val = get(handles.sliderPower, 'Value');
    if (val < minVal); set(handles.sliderPower, 'Value', minVal); sliderPower_changed(handles); end
    if (val > maxVal); set(handles.sliderPower, 'Value', maxVal); sliderPower_changed(handles); end
    % program freq/power in hardware
    setFreqAndPower(handles, eventdata);
end


function result = setFreqAndPower(handles, eventdata)
cal = get(handles.iqtool, 'UserData');
if (~isempty(cal))
    freq = get(handles.sliderFreq, 'Value');
    power = get(handles.sliderPower, 'Value');
    phase = eval(['[' get(handles.editPhase, 'String') ']']);
    sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
    channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
    autoSA = get(handles.checkboxAutoSA, 'Value');
    hMsgBox = msgbox('Downloading new data, please wait', 'Please wait...', 'replace');
    % if eventdata is 'set', then simply update the amplitude
    if (isstruct(eventdata) && isfield(eventdata, 'cmd') && strcmp(eventdata.cmd, 'setFreq'))
        channelMapping = eventdata.channelMapping;
        freq = eventdata.freq;
        power = eventdata.power;
        cmd = 'setFreq';
    elseif (strcmp(eventdata, 'check'))
        return;
    else
        cmd = 'run';
    end
    if (isfield(handles, 'axes1'))
        ax = handles.axes1;
    else
        ax = [];
    end
    result = iqcaltone('cmd', cmd, 'sampleRate', sampleRate, ...
        'channelMapping', channelMapping, 'axes', ax, 'autoSA', autoSA, ...
        'frequency', freq, 'power', power, 'phase', phase, 'cal', cal);
    try close(hMsgBox); catch; end
    if (isempty(result))
        errordlg('Power level outside of calibrated range', 'Error', 'replace');
        return;
    end
    if (~strcmp(cmd, 'setFreq'))
        setFreqInOtherTools(freq, power);
    end
end


function setFreqInOtherTools(freq, power)
% Update the Frequency Edit Field in Pulse and Modulation Utilities
% Figure windows are recognized by their "iqtool" tag
try
    TempHide = get(0, 'ShowHiddenHandles');
    set(0, 'ShowHiddenHandles', 'on');
    pulseFigs = findobj(0, 'Type', 'figure', 'Tag', 'iqtool', 'Name', 'Radar pulses & frequency chirps');
    modFigs = findobj(0, 'Type', 'figure', 'Tag', 'iqtool', 'Name', 'Digital Modulations');
    set(0, 'ShowHiddenHandles', TempHide);
    for i = 1:length(pulseFigs)
        fig = pulseFigs(i);
        [path file ext] = fileparts(get(fig, 'Filename'));
        xhandles = guihandles(fig);
        set(xhandles.editOffset, 'String', iqengprintf(freq));
        set(xhandles.editAmplitude, 'String', iqengprintf(power));
        set(xhandles.textAmplitude, 'String', 'Amplitude (dBm)');
    end
    for i = 1:length(modFigs)
        fig = modFigs(i);
        [path file ext] = fileparts(get(fig, 'Filename'));
        xhandles = guihandles(fig);
        set(xhandles.editCarrierOffset, 'String', iqengprintf(freq));
        set(xhandles.editMagnitudes, 'String', iqengprintf(power));
        set(xhandles.editMagnitudes, 'Enable', 'on');
        set(xhandles.textNotch, 'String', 'Amplitude (dBm)');
    end
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end


function doCalibrate(handles, hMsgBox, doCode)
% call calibration function
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
tones = calc_tones(handles);
amplitudes = calc_amplitudes(handles);
if (exist('doCode', 'var') && doCode ~= 0)
    errordlg('code generation not implemented yet');
else
    cal = iqcaltone('cmd', 'calibrate', 'sampleRate', sampleRate', ...
        'channelMapping', channelMapping, 'hMsgBox', hMsgBox, ...
        'tones', tones, 'amplitudes', amplitudes, 'axes', handles.axes1);
    updateRunPanel(handles, cal);
end


function tones = calc_tones(handles)
numTones = evalin('base', ['[' get(handles.editNumTones, 'String') ']']);
startFreq = evalin('base', ['[' get(handles.editStartFreq, 'String') ']']);
stopFreq = evalin('base', ['[' get(handles.editStopFreq, 'String') ']']);
if (numTones > 1)
    tones = linspace(startFreq(1), stopFreq(1), numTones);
else
    tones = stopFreq;
end


function amplitudes = calc_amplitudes(handles)
numAmpl = evalin('base', ['[' get(handles.editNumAmpl, 'String') ']']);
startAmpl = evalin('base', ['[' get(handles.editStartAmpl, 'String') ']']);
stopAmpl = evalin('base', ['[' get(handles.editStopAmpl, 'String') ']']);
if (numAmpl > 1)
    amplitudes = 10.^linspace(log10(startAmpl(1)), log10(stopAmpl(1)), numAmpl);
else
    amplitudes = stopAmpl;
end


function editStartFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editStartFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStartFreq as text
%        str2double(get(hObject,'String')) returns contents of editStartFreq as a double


% --- Executes during object creation, after setting all properties.
function editStartFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStartFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editStopFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editStopFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStopFreq as text
%        str2double(get(hObject,'String')) returns contents of editStopFreq as a double


% --- Executes during object creation, after setting all properties.
function editStopFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStopFreq (see GCBO)
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


% --- Executes on slider movement.
function sliderFreq_Callback(hObject, eventdata, handles)
% hObject    handle to sliderFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sliderFreq_changed(handles, eventdata);


function sliderFreq_changed(handles, eventdata)
val = get(handles.sliderFreq, 'Value');
set(handles.editFreq, 'String', iqengprintf(val));
set(handles.editFreq, 'BackgroundColor', 'white');
setFreqAndPower(handles, eventdata);



% --- Executes during object creation, after setting all properties.
function sliderFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderPower_Callback(hObject, eventdata, handles)
% hObject    handle to sliderPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sliderPower_changed(handles, eventdata);


function sliderPower_changed(handles, eventdata)
val = get(handles.sliderPower, 'Value');
set(handles.editPower, 'String', iqengprintf(val, 4));
set(handles.editPower, 'BackgroundColor', 'white');
setFreqAndPower(handles, eventdata);


% --- Executes during object creation, after setting all properties.
function sliderPower_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editNumAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to editNumAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumAmpl as text
%        str2double(get(hObject,'String')) returns contents of editNumAmpl as a double


% --- Executes during object creation, after setting all properties.
function editNumAmpl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editStartAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to editStartAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStartAmpl as text
%        str2double(get(hObject,'String')) returns contents of editStartAmpl as a double


% --- Executes during object creation, after setting all properties.
function editStartAmpl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStartAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editStopAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to editStopAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStopAmpl as text
%        str2double(get(hObject,'String')) returns contents of editStopAmpl as a double


% --- Executes during object creation, after setting all properties.
function editStopAmpl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStopAmpl (see GCBO)
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
function menuLoad_Callback(hObject, eventdata, handles)
% hObject    handle to menuLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename pathname] = uigetfile({ ...
    '*.mat', 'MATLAB file'; ...
%    '*.csv', 'CSV file'; ...
    });
if (filename ~= 0)
    cal = iqcaltone('cmd', 'load', 'filename', fullfile(pathname, filename), 'axes', handles.axes1);
    updateRunPanel(handles, cal);
end


function updateRunPanel(handles, cal)
set(handles.iqtool, 'UserData', cal);
if (~isempty(cal))
    set(handles.textFreq, 'Enable', 'on');
    set(handles.editFreq, 'Enable', 'on');
    set(handles.sliderFreq, 'Enable', 'on');
    set(handles.textPower, 'Enable', 'on');
    set(handles.editPower, 'Enable', 'on');
    set(handles.sliderPower, 'Enable', 'on');
    set(handles.textPhase, 'Enable', 'on');
    set(handles.editPhase, 'Enable', 'on');
    set(handles.checkboxAutoSA, 'Enable', 'on');
else
    set(handles.textFreq, 'Enable', 'off');
    set(handles.editFreq, 'Enable', 'off');
    set(handles.sliderFreq, 'Enable', 'off');
    set(handles.textPower, 'Enable', 'off');
    set(handles.editPower, 'Enable', 'off');
    set(handles.sliderPower, 'Enable', 'off');
    set(handles.textPhase, 'Enable', 'off');
    set(handles.editPhase, 'Enable', 'off');
    set(handles.checkboxAutoSA, 'Enable', 'off');
end
checkfields([], [], handles);


% --------------------------------------------------------------------
function menuSave_Callback(hObject, eventdata, handles)
% hObject    handle to menuSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cal = get(handles.iqtool, 'UserData');
if (~isempty(cal))
    [filename, pathname, filterindex] = uiputfile({...
        '.mat', 'MATLAB file (*.mat)'; ...
%        '.csv', 'CSV file (*.csv)' ...
        }, ...
        'Save Calibration As...');
    if (filename ~= 0)
        iqcaltone('cmd', 'save', 'filename', fullfile(pathname, filename), 'cal', cal);
    end
else
    msgbox('Nothing to save. Please run calibration first.');
end


% --- Executes on button press in checkboxAutoSA.
function checkboxAutoSA_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function uipushtoolNew_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolNew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cla(handles.axes1);
%legend(handles.axes1, {});
updateRunPanel(handles, []);


% --------------------------------------------------------------------
function uipushtoolSave_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
menuSave_Callback([], [], handles);


% --------------------------------------------------------------------
function uipushtoolLoad_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtoolLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
menuLoad_Callback([], [], handles);



function editPhase_Callback(hObject, eventdata, handles)
% hObject    handle to editPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
phase = [];
try
    phase = evalin('base', get(handles.editPhase, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(phase) && isreal(phase))
    set(handles.editPhase, 'BackgroundColor', 'white');
    checkfields(hObject, eventdata, handles);
else
    set(handles.editPhase, 'BackgroundColor', 'red');
end




% --- Executes during object creation, after setting all properties.
function editPhase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
