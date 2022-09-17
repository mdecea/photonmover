function varargout = iqnoiseseq_gui(varargin)
% IQNOISESEQ_GUI M-file for iqnoiseseq_gui.fig
%      IQNOISESEQ_GUI, by itself, creates a new IQNOISESEQ_GUI or raises the existing
%      singleton*.
%
%      H = IQNOISESEQ_GUI returns the handle to a new IQNOISESEQ_GUI or the handle to
%      the existing singleton*.
%
%      IQNOISESEQ_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQNOISESEQ_GUI.M with the given input arguments.
%
%      IQNOISESEQ_GUI('Property','Value',...) creates a new IQNOISESEQ_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqnoiseseq_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqnoiseseq_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqnoiseseq_gui

% Last Modified by GUIDE v2.5 06-Nov-2016 19:06:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqnoiseseq_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqnoiseseq_gui_OutputFcn, ...
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

% --- Executes just before iqnoiseseq_gui is made visible.
function iqnoiseseq_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqnoiseseq_gui (see VARARGIN)

% Choose default command line output for iqnoiseseq_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

arbConfig = loadArbConfig();

% set some default parameter - depending on the AWG model
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
% update all the fields
checkfields([], 0, handles);

if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'Enter the AWG sample rate in Hertz. For simulation, the sample rate\n' ...
    'can have any value, but if you want to download to the AWG, you have\n' ...
    'to stay within the range that is supported by the AWG.']));
set(handles.editNumSegments, 'TooltipString', sprintf([ ...
    'Select the number of tones for your multi-tone signal.\n' ...
    'For numbers > 2, the tones will be equally spaced between the start-\n' ...
    'and stop frequency. If you set number of tones to 1, you can use the\n' ...
    '"Stop Frequency" field to put 1 or more frequencies. This is useful for\n' ...
    'non-equidistant tones.  If you set the number of tones to zero, the\n' ...
    'utility will generate band limited noise within the limits of Start-\n' ...
    'and Stop frequency. Notice that if you change the number of tones or\n' ...
    'the start/stop frequency, the tone spacing field is automatically updated.']));
set(handles.editStartFreq, 'TooltipString', sprintf([ ...
    'Enter the starting frequency in Hertz. If you enter a list of frequencies\n' ...
    'in this field and a list of the same length in the "Stop Frequency" field,\n' ...
    'a disjunct series of multi-tone signals, each with the specified number of\n' ...
    'of tones is generated.']));
set(handles.editStopFreq, 'TooltipString', sprintf([ ...
    'Enter the last frequency for your multi-tone signal. If you enter a list\n' ...
    'of frequencies while number of tones is set to "1", a set of non-equidistant\n' ...
    'tones are generated.']));
set(handles.editNotchFreq, 'TooltipString', sprintf([ ...
    'Select one of more frequencies where you would like a notch in the signal.\n' ...
    'The span and depth can be individually controlled for each notch using the\n' ...
    'Notch span and Notch depth fields.']));
set(handles.editNotchSpan, 'TooltipString', sprintf([ ...
    'Select the span (i.e. the width) of the notch. If you generate multiple\n' ...
    'notches (using a list of frequencies in the Notch frequency field), you\n' ...
    'can enter either one span that will apply to all or a list of spans.']));
set(handles.editNotchDepth, 'TooltipString', sprintf([ ...
    'Select the depth of the notch in dB. If you generate multiple notches\n' ...
    '(using a list of frequencies in the Notch frequency field), you can \n' ...
    'can enter either one depth that will apply to all or a list of depths.']));
set(handles.checkboxNotchEnable, 'TooltipString', sprintf([ ...
    'Turn on/off the notch(es) in the multitone signal.  \n' ...
    'For amplitude flatness correction, this checkbox has to be turned off.']));
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
set(handles.pushbuttonChannelMapping, 'TooltipString', sprintf([ ...
    'Select into which channels the real and imaginary part of the waveform\n' ...
    'is loaded. By default, I is loaded into Channel 1, Q into channel 2, but\n' ...
    'it is also possible to load the same signal into both channels.\n' ...
    'In DUC modes, both I and Q are used for the same channel.\n' ...
    'In dual-M8190A configurations, channels 3 and 4 are on the second module.']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Use this button to calculate and download the signal to the configured AWG.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
end
% UIWAIT makes iqnoiseseq_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqnoiseseq_gui_OutputFcn(hObject, eventdata, handles)
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



function editPoints_Callback(hObject, eventdata, handles)
% hObject    handle to editPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPoints as text
%        str2double(get(hObject,'String')) returns contents of editPoints as a double
checkfields(hObject, 0, handles);



% --- Executes during object creation, after setting all properties.
function editPoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumSegments_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSegments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSegments as text
%        str2double(get(hObject,'String')) returns contents of editNumSegments as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 0 && value <= 100)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNumSegments_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSegments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editStartFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editStartFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStartFreq as text
%        str2double(get(hObject,'String')) returns contents of editStartFreq as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && ~isempty(value) && isempty(find(abs(value) > 100e9)))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


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
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && ~isempty(value) && isempty(find(abs(value) > 100e9)))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


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


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
calculate(handles, 0);


function editNotchSpan_Callback(hObject, eventdata, handles)
% hObject    handle to editNotchSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNotchSpan as text
%        str2double(get(hObject,'String')) returns contents of editNotchSpan as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && isempty(find(value < 0)) && isempty(find(value > 50e9)))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNotchSpan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNotchSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editNotchFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editNotchFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNotchFreq as text
%        str2double(get(hObject,'String')) returns contents of editNotchFreq as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && isempty(find(value < -50e9)) && isempty(find(value > 50e9)))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNotchFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNotchFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNotchDepth_Callback(hObject, eventdata, handles)
% hObject    handle to editNotchDepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNotchDepth as text
%        str2double(get(hObject,'String')) returns contents of editNotchDepth as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && isempty(find(value < -1000)) && isempty(find(value > 1000)))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNotchDepth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNotchDepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxNotchEnable.
function checkboxNotchEnable_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxNotchEnable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxNotchEnable
notchEnable = get(handles.checkboxNotchEnable, 'Value');
if (notchEnable)
    set(handles.editNotchFreq, 'Enable', 'On');
    set(handles.editNotchSpan, 'Enable', 'On');
    set(handles.editNotchDepth, 'Enable', 'On');
else
    set(handles.editNotchFreq, 'Enable', 'Off');
    set(handles.editNotchSpan, 'Enable', 'Off');
    set(handles.editNotchDepth, 'Enable', 'Off');
end


% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in pushbuttonShowCorrection.
function pushbuttonShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqcorrmgmt();



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


% --- Executes on button press in pushbuttonSetupSA.
function pushbuttonSetupSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSetupSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
errordlg('Not yet implemented');



function [iqdata sampleRate] = calculate(handles, doCode)
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
points = evalin('base',get(handles.editPoints, 'String'));
correction = get(handles.checkboxCorrection, 'Value');
numSegm = evalin('base',get(handles.editNumSegments, 'String'));
startFreq = evalin('base', ['[' get(handles.editStartFreq, 'String') ']']);
stopFreq = evalin('base', ['[' get(handles.editStopFreq, 'String') ']']);
notchFreq = evalin('base', ['[' get(handles.editNotchFreq, 'String') ']']);
notchSpan = evalin('base', ['[' get(handles.editNotchSpan, 'String') ']']);
notchDepth = evalin('base', ['[' get(handles.editNotchDepth, 'String') ']']);
notchEnable = get(handles.checkboxNotchEnable, 'Value');
if (notchEnable == 0)
    notchFreq = [];
    notchSpan = [];
    notchDepth = [];
end
if (exist('doCode', 'var') && (doCode ~= 0))
    startFreqStr = ['[' strtrim(sprintf('%g ', startFreq)) ']'];
    stopFreqStr = ['[' strtrim(sprintf('%g ', stopFreq)) ']'];
    notchFreqStr = ['[' strtrim(sprintf('%g ', notchFreq)) ']'];
    notchSpanStr = ['[' strtrim(sprintf('%g ', notchSpan)) ']'];
    notchDepthStr = ['[' strtrim(sprintf('%g ', notchDepth)) ']'];
    channelMapping = iqchannelsetup('arraystring', get(handles.pushbuttonChannelMapping, 'UserData'));
    iqdata = sprintf(['iqnoiseseq(''sampleRate'', %s, ...\n' ...
        '    ''numSamples'', %g, ''start'', %s, ''stop'', %s, ...\n' ...
        '    ''notchFreq'', %s, ''notchSpan'', %s, ''notchDepth'', %s, ...\n' ...
        '    ''channelMapping'', %s, ''numSegments'', %d);\n'], ...
        iqengprintf(sampleRate), points, startFreqStr, stopFreqStr, notchFreqStr, ...
        notchSpanStr, notchDepthStr, channelMapping, numSegm);
else
    iqnoiseseq('sampleRate', sampleRate, 'numSamples', points, ...
        'numSegments', numSegm, ....
        'start', startFreq, 'stop', stopFreq, 'notchFreq', notchFreq, ...
        'notchSpan', notchSpan, 'notchDepth', notchDepth, ...
        'correction', correction);
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
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
[arbConfig saConfig] = loadArbConfig();
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
% --- editPoints
value = [];
try
    value = evalin('base', get(handles.editPoints, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value))
    if (value > arbConfig.maximumSegmentSize)
        value = arbConfig.maximumSegmentSize;
        value = value - mod(value, arbConfig.segmentGranularity);
        set(handles.editPoints, 'String', num2str(value));
    end
    if (mod(value, arbConfig.segmentGranularity) ~= 0)
        value = value - mod(value, arbConfig.segmentGranularity);
        set(handles.editPoints, 'String', num2str(value));
    end
    if (value < arbConfig.minimumSegmentSize)
        set(handles.editPoints, 'String', num2str(arbConfig.minimumSegmentSize));
    end
    set(handles.editPoints,'BackgroundColor','white');
else
    set(handles.editPoints,'BackgroundColor','red');
    result = 0;
end


% --------------------------------------------------------------------
function menuGenerateCode_Callback(hObject, eventdata, handles)
% hObject    handle to menuGenerateCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
code = calculate(handles, 1);
iqgeneratecode(handles, code);


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
