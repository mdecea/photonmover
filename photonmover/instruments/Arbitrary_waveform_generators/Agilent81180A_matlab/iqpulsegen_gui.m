function varargout = iqpulsegen_gui(varargin)
% IQPULSEGEN_GUI MATLAB code for iqpulsegen_gui.fig
%      IQPULSEGEN_GUI, by itself, creates a new IQPULSEGEN_GUI or raises the existing
%      singleton*.
%
%      H = IQPULSEGEN_GUI returns the handle to a new IQPULSEGEN_GUI or the handle to
%      the existing singleton*.
%
%      IQPULSEGEN_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQPULSEGEN_GUI.M with the given input arguments.
%
%      IQPULSEGEN_GUI('Property','Value',...) creates a new IQPULSEGEN_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqpulsegen_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqpulsegen_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqpulsegen_gui

% Last Modified by GUIDE v2.5 06-Jun-2014 13:36:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqpulsegen_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqpulsegen_gui_OutputFcn, ...
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


% --- Executes just before iqpulsegen_gui is made visible.
function iqpulsegen_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqpulsegen_gui (see VARARGIN)

% Choose default command line output for iqpulsegen_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

arbConfig = loadArbConfig();
switch arbConfig.model
    case '81180A'
    case {'M8190A', 'M8190A_base', 'M8190A_14bit', 'M8190A_12bit', 'M8190A_prototype'}
    case 'M933XA'
    otherwise
end
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
editPWSec_Callback(0, 0, handles);
editRiseSec_Callback(0, 0, handles);
editFallSec_Callback(0, 0, handles);
editOffSec_Callback(0, 0, handles);
calcPRI(handles);
checkfields(hObject, 0, handles);

if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'Enter the AWG sample rate in Hertz. For simulation, the sample rate\n' ...
    'can have any value, but if you want to download to the AWG, you have\n' ...
    'to stay within the range that is supported by the AWG.']));
set(handles.editPWSec, 'TooltipString', sprintf([ ...
    'Pulse width in seconds. You can specify a list of values to generate\n' ...
    'multiple pulses with different pulse width.']));
set(handles.editPWSamples, 'TooltipString', sprintf([ ...
    'Pulse width in number of samples. You can specify a list of values to generate\n' ...
    'multiple pulses with different pulse width.']));
set(handles.editRiseSec, 'TooltipString', sprintf([ ...
    'Rise time in seconds. You can specify a list of values\n' ...
    'to generate multiple pulses with different rise times.']));
set(handles.editRiseSamples, 'TooltipString', sprintf([ ...
    'Rise time in number of samples. You can specify a list of values\n' ...
    'to generate multiple pulses with different rise times.']));
set(handles.editFallSec, 'TooltipString', sprintf([ ...
    'Fall time in seconds. You can specify a list of values\n' ...
    'to generate multiple pulses with different fall times.']));
set(handles.editFallSamples, 'TooltipString', sprintf([ ...
    'Fall time in number of samples. You can specify a list of values\n' ...
    'to generate multiple pulses with different fall times.']));
set(handles.editOffSec, 'TooltipString', sprintf([ ...
    'Off time in seconds. You can specify a list of values\n' ...
    'to generate multiple pulses with different off times.']));
set(handles.editOffSamples, 'TooltipString', sprintf([ ...
    'Off time in number of samples. You can specify a list of values\n' ...
    'to generate multiple pulses with different off times.']));
set(handles.editLow, 'TooltipString', sprintf([ ...
    'DAC value for the "off" portion of the pulse. A value of -1 corresponds\n' ...
    'to the low level, 1 corresponds to the high level. You can specify a list\n' ...
    'of values to generate multiple pulses with different "off" voltage.']));
set(handles.editHigh, 'TooltipString', sprintf([ ...
    'DAC value for the "on" portion of the pulse. A value of -1 corresponds\n' ...
    'to the low level, 1 corresponds to the high level. You can specify a list\n' ...
    'of values to generate multiple pulses with different "on" voltage.']));
set(handles.popupmenuPulseShape, 'TooltipString', sprintf([ ...
    'Select the "shape" of the rising and falling edge of the pulse']));
set(handles.pushbuttonChannelMapping, 'TooltipString', sprintf([ ...
    'Select into which channels the waveform is downloaded.\n' ...
    'In dual-M8190A configurations, channels 3 and 4 are on the second module.']));
set(handles.editSegment, 'TooltipString', sprintf([ ...
    'Enter the AWG waveform segment to which the signal will be downloaded.\n' ...
    'If you download to segment #1, all other segments will be automatically\n' ...
    'deleted.']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Use this button to calculate and download the signal to the configured AWG.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
end
% UIWAIT makes iqpulsegen_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqpulsegen_gui_OutputFcn(hObject, eventdata, handles) 
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



function editPRISec_Callback(hObject, eventdata, handles)
% hObject    handle to editPRISec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPRISec as text
%        str2double(get(hObject,'String')) returns contents of editPRISec as a double
value = [];
sampleRate = 1;
pw = 0;
rise = 0;
fall = 0;
try
    value = evalin('base', get(handles.editPRISec, 'String'));
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
    pw = evalin('base', get(handles.editPWSec, 'String'));
    rise = evalin('base', get(handles.editRiseSec, 'String'));
    fall = evalin('base', get(handles.editFallSec, 'String'));
    off = evalin('base', get(handles.editFallSec, 'String'));
catch ex
end
arbConfig = loadArbConfig();
if (isscalar(value) && value >= 1e-12 && value <= 1 && (pw + rise + fall) <= value)
    priSamples = round(value * sampleRate);
    priSamples = ceil(priSamples / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
    if (priSamples < arbConfig.minimumSegmentSize)
        priSamples = arbConfig.minimumSegmentSize;
    end
    priSec = priSamples / sampleRate;
    set(handles.editPRISamples, 'String', sprintf('%d', priSamples));
    set(handles.editPRISec, 'String', sprintf('%.3g', priSec));
    set(handles.editPRISec,'BackgroundColor','white');
else
    set(handles.editPRISec,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPRISec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPRISec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPWSec_Callback(hObject, eventdata, handles)
% hObject    handle to editPWSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPWSec as text
%        str2double(get(hObject,'String')) returns contents of editPWSec as a double
value = [];
sampleRate = 1;
try
    value = evalin('base', ['[' get(handles.editPWSec, 'String') ']']);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(handles.editPWSamples, 'String', strtrim(sprintf('%d ', round(value .* sampleRate))));
    set(handles.editPWSec,'BackgroundColor','white');
    calcPRI(handles);
else
    set(handles.editPWSec,'BackgroundColor','red');
end



% --- Executes during object creation, after setting all properties.
function editPWSec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPWSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editRiseSec_Callback(hObject, eventdata, handles)
% hObject    handle to editRiseSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRiseSec as text
%        str2double(get(hObject,'String')) returns contents of editRiseSec as a double
value = [];
sampleRate = 1;
try
    value = evalin('base', ['[' get(handles.editRiseSec, 'String') ']']);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(handles.editRiseSamples, 'String', strtrim(sprintf('%d ', round(value .* sampleRate))));
    set(handles.editRiseSec,'BackgroundColor','white');
    calcPRI(handles);
else
    set(handles.editRiseSec,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editRiseSec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRiseSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFallSec_Callback(hObject, eventdata, handles)
% hObject    handle to editFallSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFallSec as text
%        str2double(get(hObject,'String')) returns contents of editFallSec as a double
value = [];
sampleRate = 1;
try
    value = evalin('base', ['[' get(handles.editFallSec, 'String') ']']);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(handles.editFallSamples, 'String', strtrim(sprintf('%d ', round(value .* sampleRate))));
    set(handles.editFallSec,'BackgroundColor','white');
    calcPRI(handles);
else
    set(handles.editFallSec,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editFallSec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFallSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuPulseShape.
function popupmenuPulseShape_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuPulseShape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuPulseShape contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuPulseShape
contents = cellstr(get(handles.popupmenuPulseShape,'String'));
if (strcmpi(contents{get(handles.popupmenuPulseShape,'Value')}, 'Gaussian') || ...
    strcmpi(contents{get(handles.popupmenuPulseShape,'Value')}, 'Exponential'))
    set(handles.textAlpha, 'Enable', 'on');
    set(handles.editAlpha, 'Enable', 'on');
else
    set(handles.textAlpha, 'Enable', 'off');
    set(handles.editAlpha, 'Enable', 'off');
end


% --- Executes during object creation, after setting all properties.
function popupmenuPulseShape_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuPulseShape (see GCBO)
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
[pulse, rpt, sampleRate, ~] = calcPulse(handles, 0);
assignin('base', 'pulse', pulse);
iqplot(pulse, sampleRate, 'nospectrum');


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
[pulse, rpt, sampleRate, channelMapping] = calcPulse(handles, 0);
assignin('base', 'pulse', pulse);
pulse = repmat(pulse, rpt, 1);
segmentNum = evalin('base', get(handles.editSegment, 'String'));
iqdownload(pulse, sampleRate, 'channelMapping', channelMapping, 'segmentNumber', segmentNum);
close(hMsgBox);


function editFallSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editFallSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFallSamples as text
%        str2double(get(hObject,'String')) returns contents of editFallSamples as a double
value = [];
sampleRate = 1;
try
    value = evalin('base', ['[' get(handles.editFallSamples, 'String') ']']);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1e9 && isequal(floor(value),value))
    set(handles.editFallSec, 'String', strtrim(sprintf('%g ', value / sampleRate)));
    set(handles.editFallSamples,'BackgroundColor','white');
    calcPRI(handles);
else
    set(handles.editFallSamples,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editFallSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFallSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editRiseSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editRiseSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRiseSamples as text
%        str2double(get(hObject,'String')) returns contents of editRiseSamples as a double
value = [];
sampleRate = 1;
try
    value = evalin('base', ['[' get(handles.editRiseSamples, 'String') ']']);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1e9 && isequal(floor(value),value))
    set(handles.editRiseSec, 'String', strtrim(sprintf('%g ', value / sampleRate)));
    set(handles.editRiseSamples,'BackgroundColor','white');
    calcPRI(handles);
else
    set(handles.editRiseSamples,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editRiseSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRiseSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPWSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editPWSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPWSamples as text
%        str2double(get(hObject,'String')) returns contents of editPWSamples as a double
value = [];
sampleRate = 1;
try
    value = evalin('base', ['[' get(handles.editPWSamples, 'String') ']']);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1e9 && isequal(floor(value),value))
    set(handles.editPWSec, 'String', strtrim(sprintf('%g ', value / sampleRate)));
    set(handles.editPWSamples,'BackgroundColor','white');
    calcPRI(handles);
else
    set(handles.editPWSamples,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPWSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPWSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPRISamples_Callback(hObject, eventdata, handles)
% hObject    handle to editPRISamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPRISamples as text
%        str2double(get(hObject,'String')) returns contents of editPRISamples as a double
value = [];
sampleRate = 1;
try
    value = evalin('base', get(handles.editPRISamples, 'String'));
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1e9 && (floor(value) == value))
    set(handles.editPRISec, 'String', sprintf('%.3g', value / sampleRate));
    set(handles.editPRISamples,'BackgroundColor','white');
    editPRISec_Callback(hObject, eventdata, handles);
else
    set(handles.editPRISamples,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPRISamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPRISamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLow_Callback(hObject, eventdata, handles)
% hObject    handle to editLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLow as text
%        str2double(get(hObject,'String')) returns contents of editLow as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= -1 && max(value) <= 1)
    set(hObject,'BackgroundColor','white');
    calcPRI(handles);
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editLow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editHigh_Callback(hObject, eventdata, handles)
% hObject    handle to editHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editHigh as text
%        str2double(get(hObject,'String')) returns contents of editHigh as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= -1 && max(value) <= 1)
    set(hObject,'BackgroundColor','white');
    calcPRI(handles);
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editHigh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editOffSec_Callback(hObject, eventdata, handles)
% hObject    handle to editOffSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOffSec as text
%        str2double(get(hObject,'String')) returns contents of editOffSec as a double
value = [];
sampleRate = 1;
try
    value = evalin('base', ['[' get(handles.editOffSec, 'String') ']']);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(handles.editOffSamples, 'String', strtrim(sprintf('%d ', round(value .* sampleRate))));
    set(handles.editOffSec,'BackgroundColor','white');
    calcPRI(handles);
else
    set(handles.editOffSec,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editOffSec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOffSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editOffSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editOffSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOffSamples as text
%        str2double(get(hObject,'String')) returns contents of editOffSamples as a double
value = [];
sampleRate = 1;
try
    value = evalin('base', ['[' get(handles.editOffSamples, 'String') ']']);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1e9 && isequal(floor(value),value))
    set(handles.editOffSec, 'String', strtrim(sprintf('%g ', value / sampleRate)));
    set(handles.editOffSamples,'BackgroundColor','white');
    calcPRI(handles);
else
    set(handles.editOffSamples,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editOffSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOffSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function editFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to editFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFrequency as text
%        str2double(get(hObject,'String')) returns contents of editFrequency as a double


% --- Executes during object creation, after setting all properties.
function editFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function result = calcPRI(handles)
try
    pw = evalin('base', ['[' get(handles.editPWSamples, 'String') ']']);
    rise = evalin('base', ['[' get(handles.editRiseSamples, 'String') ']']);
    fall = evalin('base', ['[' get(handles.editFallSamples, 'String') ']']);
    off = evalin('base', ['[' get(handles.editOffSamples, 'String') ']']);
    low = evalin('base', ['[' get(handles.editLow, 'String') ']']);
    high = evalin('base', ['[' get(handles.editHigh, 'String') ']']);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
end
if (isvector(pw) && isvector(rise) && isvector(fall) && isvector(off) && isvector(low) && isvector(high))
    len = max([length(pw) length(rise) length(fall) length(off) length(low) length(high)]);
    pw = repmat(makeRowVector(pw), 1, ceil(len / length(pw)));
    rise = repmat(makeRowVector(rise), 1, ceil(len / length(rise)));
    fall = repmat(makeRowVector(fall), 1, ceil(len / length(fall)));
    off = repmat(makeRowVector(off), 1, ceil(len / length(off)));
    pri = sum(pw(1:len)) + sum(rise(1:len)) + sum(fall(1:len)) + sum(off(1:len));
    priTime = pri / sampleRate;
    set(handles.editPRISec, 'String', iqengprintf(priTime));
    set(handles.editPRISamples, 'String', sprintf('%d', pri));
    if (priTime ~= 0)
        set(handles.editFrequency, 'String', iqengprintf(1/priTime));
    end
end


function result = makeRowVector(a)
    result = reshape(a, 1, length(a));

    
function [pulse, rpt, sampleRate, channelMapping] = calcPulse(handles, doCode)
%try
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
pw = evalin('base', ['[' get(handles.editPWSamples, 'String') ']']);
rise = evalin('base', ['[' get(handles.editRiseSamples, 'String') ']']);
fall = evalin('base', ['[' get(handles.editFallSamples, 'String') ']']);
off = evalin('base', ['[' get(handles.editOffSamples, 'String') ']']);
shapeList = get(handles.popupmenuPulseShape, 'String');
shapeIdx = get(handles.popupmenuPulseShape, 'Value');
alpha = evalin('base', ['[' get(handles.editAlpha, 'String') ']']);
low = evalin('base', ['[' get(handles.editLow, 'String') ']']);
high = evalin('base', ['[' get(handles.editHigh, 'String') ']']);
corr = get(handles.checkboxCorrection, 'Value');
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
rpt = 1;
if (isempty(alpha))
    alpha = 0;
end
if (doCode)
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
    chanMapStr = iqchannelsetup('arraystring', get(handles.pushbuttonChannelMapping, 'UserData'));
    pulse = sprintf(['[pulse, rpt, chMap] = iqpulsegen(''sampleRate'', %s, ...\n' ...
        '              ''pw'', %s, ''rise'', %s, ''fall'', %s, ...\n' ...
        '              ''off'', %s, ''low'', %s, ''high'', %s, ...\n' ...
        '              ''pulseShape'', ''%s'', ''alpha'', %d, ''correction'', %d, ''channelMapping'', %s);\n\n' ...
        'iqdownload(repmat(pulse, rpt, 1), %s, ''channelMapping'', chMap, ''segmentNumber'', %d);\n'], ...
        iqengprintf(sampleRate), vectorStr(pw), vectorStr(rise), vectorStr(fall), vectorStr(off), ...
        vectorStr(low), vectorStr(high), shapeList{shapeIdx}, alpha, corr, ...
        chanMapStr, iqengprintf(sampleRate), segmentNum);
else
    sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
    pw = evalin('base', ['[' get(handles.editPWSamples, 'String') ']']);
    rise = evalin('base', ['[' get(handles.editRiseSamples, 'String') ']']);
    fall = evalin('base', ['[' get(handles.editFallSamples, 'String') ']']);
    off = evalin('base', ['[' get(handles.editOffSamples, 'String') ']']);
    shapeList = get(handles.popupmenuPulseShape, 'String');
    shapeIdx = get(handles.popupmenuPulseShape, 'Value');
    alpha = evalin('base', ['[' get(handles.editAlpha, 'String') ']']);
    low = evalin('base', ['[' get(handles.editLow, 'String') ']']);
    high = evalin('base', ['[' get(handles.editHigh, 'String') ']']);
    corr = get(handles.checkboxCorrection, 'Value');
    [pulse, rpt, channelMapping] = iqpulsegen('sampleRate', sampleRate, ...
                     'pw', pw, 'rise', rise, 'fall', fall, ...
                     'off', off, 'low', low, 'high', high, ...
                     'pulseShape', shapeList{shapeIdx}, 'alpha', alpha, ...
                     'correction', corr, 'channelMapping', channelMapping);
end
%catch ex
%    errordlg(ex.message);
%end


function str = vectorStr(x)
if (length(x) > 1)
    str = '[';
    for i = 1:length(x)
        str = [str iqengprintf(x(i)) ' ']
    end
    str = [str(1:end-1) ']'];
else
    str = iqengprintf(x);
end



% --------------------------------------------------------------------
function Preset_Callback(hObject, eventdata, handles)
% hObject    handle to Preset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function editSegment_Callback(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSegment as text
%        str2double(get(hObject,'String')) returns contents of editSegment as a double
checkfields(hObject, 0, handles);

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


% --------------------------------------------------------------------
function DCLevel_Callback(hObject, eventdata, handles)
% hObject    handle to DCLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% --------------------------------------------------------------------
set(handles.editPWSamples, 'String', '0');
set(handles.editRiseSamples, 'String', '0');
set(handles.editFallSamples, 'String', '0');
set(handles.editOffSamples, 'String', '100');
set(handles.editLow, 'String', '0');
set(handles.editHigh, 'String', '1');
set(handles.popupmenuPulseShape, 'Value', 1);
popupmenuPulseShape_Callback(0, 0, handles);
editPWSamples_Callback(0, 0, handles);
editRiseSamples_Callback(0, 0, handles);
editFallSamples_Callback(0, 0, handles);
editOffSamples_Callback(0, 0, handles);
pushbuttonDisplay_Callback(0, 0, handles);


function Impulse_Callback(hObject, eventdata, handles)
% hObject    handle to Impulse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editPWSamples, 'String', '1');
set(handles.editRiseSamples, 'String', '1');
set(handles.editFallSamples, 'String', '0');
set(handles.editOffSamples, 'String', '30');
set(handles.editLow, 'String', '0');
set(handles.editHigh, 'String', '1');
set(handles.popupmenuPulseShape, 'Value', 1);
popupmenuPulseShape_Callback(0, 0, handles);
editPWSamples_Callback(0, 0, handles);
editRiseSamples_Callback(0, 0, handles);
editFallSamples_Callback(0, 0, handles);
editOffSamples_Callback(0, 0, handles);
pushbuttonDisplay_Callback(0, 0, handles);


% --------------------------------------------------------------------
function Cosine_Callback(hObject, eventdata, handles)
% hObject    handle to Cosine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editPWSamples, 'String', '0');
set(handles.editRiseSamples, 'String', '30');
set(handles.editFallSamples, 'String', '30');
set(handles.editOffSamples, 'String', '40');
set(handles.editLow, 'String', '0');
set(handles.editHigh, 'String', '1');
set(handles.popupmenuPulseShape, 'Value', 2);
popupmenuPulseShape_Callback(0, 0, handles);
editPWSamples_Callback(0, 0, handles);
editRiseSamples_Callback(0, 0, handles);
editFallSamples_Callback(0, 0, handles);
editOffSamples_Callback(0, 0, handles);
pushbuttonDisplay_Callback(0, 0, handles);

% --------------------------------------------------------------------
function MultiLevel_Callback(hObject, eventdata, handles)
% hObject    handle to MultiLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editPWSamples, 'String', '20');
set(handles.editRiseSamples, 'String', '5');
set(handles.editFallSamples, 'String', '5');
set(handles.editOffSamples, 'String', '20');
set(handles.editLow, 'String', 'linspace(-1,-0.7,5)');
set(handles.editHigh, 'String', 'linspace(1,0,5)');
set(handles.popupmenuPulseShape, 'Value', 2);
popupmenuPulseShape_Callback(0, 0, handles);
editPWSamples_Callback(0, 0, handles);
editRiseSamples_Callback(0, 0, handles);
editFallSamples_Callback(0, 0, handles);
editOffSamples_Callback(0, 0, handles);
pushbuttonDisplay_Callback(0, 0, handles);


% --------------------------------------------------------------------
function Square_Callback(hObject, eventdata, handles)
% hObject    handle to Square (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editPWSamples, 'String', '40');
set(handles.editRiseSamples, 'String', '0');
set(handles.editFallSamples, 'String', '0');
set(handles.editOffSamples, 'String', '40');
set(handles.editLow, 'String', '-1');
set(handles.editHigh, 'String', '1');
set(handles.popupmenuPulseShape, 'Value', 1);
popupmenuPulseShape_Callback(0, 0, handles);
editPWSamples_Callback(0, 0, handles);
editRiseSamples_Callback(0, 0, handles);
editFallSamples_Callback(0, 0, handles);
editOffSamples_Callback(0, 0, handles);
pushbuttonDisplay_Callback(0, 0, handles);

% --------------------------------------------------------------------
function Triangle_Callback(hObject, eventdata, handles)
% hObject    handle to Triangle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editPWSamples, 'String', '0');
set(handles.editRiseSamples, 'String', '40');
set(handles.editFallSamples, 'String', '40');
set(handles.editOffSamples, 'String', '0');
set(handles.editLow, 'String', '-1');
set(handles.editHigh, 'String', '1');
set(handles.popupmenuPulseShape, 'Value', 1);
popupmenuPulseShape_Callback(0, 0, handles);
editPWSamples_Callback(0, 0, handles);
editRiseSamples_Callback(0, 0, handles);
editFallSamples_Callback(0, 0, handles);
editOffSamples_Callback(0, 0, handles);
pushbuttonDisplay_Callback(0, 0, handles);

% --------------------------------------------------------------------
function PWM_Callback(hObject, eventdata, handles)
% hObject    handle to PWM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editPWSamples, 'String', 'linspace(10,90,9)');
set(handles.editRiseSamples, 'String', '0');
set(handles.editFallSamples, 'String', '0');
set(handles.editOffSamples, 'String', 'linspace(90,10,9)');
set(handles.editLow, 'String', '-1');
set(handles.editHigh, 'String', '1');
set(handles.popupmenuPulseShape, 'Value', 1);
popupmenuPulseShape_Callback(0, 0, handles);
editPWSamples_Callback(0, 0, handles);
editRiseSamples_Callback(0, 0, handles);
editFallSamples_Callback(0, 0, handles);
editOffSamples_Callback(0, 0, handles);
pushbuttonDisplay_Callback(0, 0, handles);

% --------------------------------------------------------------------
function Serial_Callback(hObject, eventdata, handles)
% hObject    handle to Serial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editPWSamples, 'String', '40+45*randi([0,7],1,10)');
set(handles.editRiseSamples, 'String', '5');
set(handles.editFallSamples, 'String', '5');
set(handles.editOffSamples, 'String', '40+45*randi([0,7],1,10)');
set(handles.editLow, 'String', '-1');
set(handles.editHigh, 'String', '1');
set(handles.popupmenuPulseShape, 'Value', 1);
popupmenuPulseShape_Callback(0, 0, handles);
editPWSamples_Callback(0, 0, handles);
editRiseSamples_Callback(0, 0, handles);
editFallSamples_Callback(0, 0, handles);
editOffSamples_Callback(0, 0, handles);
pushbuttonDisplay_Callback(0, 0, handles);

% --------------------------------------------------------------------
function Random_Callback(hObject, eventdata, handles)
% hObject    handle to Random (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editPWSamples, 'String', 'randi([0,40],1,5)');
set(handles.editRiseSamples, 'String', 'randi([0,40],1,5)');
set(handles.editFallSamples, 'String', 'randi([0,40],1,5)');
set(handles.editOffSamples, 'String', 'randi([0,40],1,5)');
set(handles.editLow, 'String', '-1*rand(1,5)');
set(handles.editHigh, 'String', 'rand(1,5)');
set(handles.popupmenuPulseShape, 'Value', 1);
popupmenuPulseShape_Callback(0, 0, handles);
editPWSamples_Callback(0, 0, handles);
editRiseSamples_Callback(0, 0, handles);
editFallSamples_Callback(0, 0, handles);
editOffSamples_Callback(0, 0, handles);
pushbuttonDisplay_Callback(0, 0, handles);


% --------------------------------------------------------------------
function menuGaussianPulse_Callback(hObject, eventdata, handles)
% hObject    handle to menuGaussianPulse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editPWSamples, 'String', '0');
set(handles.editRiseSamples, 'String', '60');
set(handles.editFallSamples, 'String', '60');
set(handles.editOffSamples, 'String', '0');
set(handles.editLow, 'String', '0');
set(handles.editHigh, 'String', '1');
set(handles.popupmenuPulseShape, 'Value', 3);
set(handles.editAlpha, 'String', '5');
popupmenuPulseShape_Callback(0, 0, handles);
editPWSamples_Callback(0, 0, handles);
editRiseSamples_Callback(0, 0, handles);
editFallSamples_Callback(0, 0, handles);
editOffSamples_Callback(0, 0, handles);
pushbuttonDisplay_Callback(0, 0, handles);


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


% --------------------------------------------------------------------
function menuSaveWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[Y, rpt, sampleRate, ~] = calcPulse(handles, 0);
Y = repmat(Y, rpt, 1);
iqsavewaveform(Y, sampleRate);


function editAlpha_Callback(hObject, eventdata, handles)
% hObject    handle to editAlpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAlpha as text
%        str2double(get(hObject,'String')) returns contents of editAlpha as a double
value = [];
try
    value = evalin('base', ['[' get(handles.editAlpha, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) > 0 && max(value) <= 1e9)
    set(handles.editAlpha,'BackgroundColor','white');
else
    set(handles.editAlpha,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editAlpha_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAlpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
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
arbConfig = loadArbConfig();

% --- generic checks
if (arbConfig.maxSegmentNumber <= 1)
    set(handles.editSegment, 'Enable', 'off');
    set(handles.textSegment, 'Enable', 'off');
else
    set(handles.editSegment, 'Enable', 'on');
    set(handles.textSegment, 'Enable', 'on');
end
% --- channel mapping
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
    editPWSec_Callback(0, 0, handles);
    editRiseSec_Callback(0, 0, handles);
    editFallSec_Callback(0, 0, handles);
    editOffSec_Callback(0, 0, handles);
    set(handles.editSampleRate, 'BackgroundColor', 'white');
else
    set(handles.editSampleRate, 'BackgroundColor', 'red');
    result = 0;
end
% --- editSegment
value = -1;
try
    value = evalin('base', get(handles.editSegment, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && value >= 1 && value <= arbConfig.maxSegmentNumber)
    set(handles.editSegment,'BackgroundColor','white');
else
    set(handles.editSegment,'BackgroundColor','red');
    result = 0;
end


% --- Executes on button press in pushbuttonChannelMapping.
function pushbuttonChannelMapping_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonChannelMapping (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
[val, str] = iqchanneldlg(get(hObject, 'UserData'), arbConfig, handles.iqtool, 'single');
if (~isempty(val))
    set(hObject, 'UserData', val);
    set(hObject, 'String', str);
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

% --------------------------------------------------------------------
function menuGenerateCode_Callback(hObject, eventdata, handles)
% hObject    handle to menuGenerateCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[code, ~, ~, ~] = calcPulse(handles, 1);
iqgeneratecode(handles, code);
