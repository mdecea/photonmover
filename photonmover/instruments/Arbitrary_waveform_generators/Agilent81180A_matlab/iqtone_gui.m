function varargout = iqtone_gui(varargin)
% IQTONE_GUI M-file for iqtone_gui.fig
%      IQTONE_GUI, by itself, creates a new IQTONE_GUI or raises the existing
%      singleton*.
%
%      H = IQTONE_GUI returns the handle to a new IQTONE_GUI or the handle to
%      the existing singleton*.
%
%      IQTONE_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQTONE_GUI.M with the given input arguments.
%
%      IQTONE_GUI('Property','Value',...) creates a new IQTONE_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqtone_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqtone_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqtone_gui

% Last Modified by GUIDE v2.5 04-Aug-2019 01:30:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqtone_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqtone_gui_OutputFcn, ...
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

% --- Executes just before iqtone_gui is made visible.
function iqtone_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqtone_gui (see VARARGIN)

% Choose default command line output for iqtone_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

[arbConfig, saConfig] = loadArbConfig();

% set some default parameter - depending on the AWG model
switch arbConfig.model
    case { '81180A' '81180B' }
        startFreq = 30e6;
        stopFreq = 900e6;
        notchFreq = 200e6;
        notchSpan = 60e6;
        numTones = 30;
    case { 'M8190A', 'M8190A_base', 'M8190A_14bit', 'M8190A_12bit', 'M8190A_prototype' }
        startFreq = 20e6;
        stopFreq = 2e9;
        notchFreq = 1e9;
        notchSpan = 100e6;
        numTones = 100;
    case { 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }
        startFreq = -50e6;
        stopFreq = 50e6;
        notchFreq = 0;
        notchSpan = 10e6;
        numTones = 21;
    case { 'M8195A_Rev0' 'M8195A_Rev1' 'M8195A_1ch' 'M8195A_2ch_256k' 'M8195A_4ch_256k' }
        startFreq = 20e7;
        stopFreq = 20e9;
        notchFreq = 10e9;
        notchSpan = 10e6;
        numTones = 100;
    case { 'M8195A_2ch', 'M8195A_2ch_mrk' }
        startFreq = 10e7;
        stopFreq = 10e9;
        notchFreq = 5e9;
        notchSpan = 100e6;
        numTones = 100;
    case { 'M8195A_4ch' }
        startFreq = 5e7;
        stopFreq = 5e9;
        notchFreq = 2.5e9;
        notchSpan = 100e6;
        numTones = 100;
    case 'M933xA'
        startFreq = 10e6;
        stopFreq = 300e6;
        notchFreq = 100e6;
        notchSpan = 30e6;
        numTones = 30;
    case { '81150A', '81160A' }
        startFreq = 10e6;
        stopFreq = 200e6;
        notchFreq = 100e6;
        notchSpan = 40e6;
        numTones = 20;
    case { '3351x', '3352x', '3361x', '3362x' }
        startFreq = 1e6;
        stopFreq = 10e6;
        notchFreq = 5e6;
        notchSpan = 3e6;
        numTones = 10;
    otherwise
        startFreq = 10e6;
        stopFreq = 100e6;
        notchFreq = 50e6;
        notchSpan = 10e6;
        numTones = 10;
end
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editStartFreq, 'String', iqengprintf(startFreq));
set(handles.editStopFreq, 'String', iqengprintf(stopFreq));
set(handles.editNotchFreq, 'String', iqengprintf(notchFreq));
set(handles.editNotchSpan, 'String', iqengprintf(notchSpan));
set(handles.editTones, 'String', num2str(numTones));
editTones_Callback(handles.editTones, eventdata, handles);
set(handles.popupmenuPhase, 'Value', 2);  % random
if (isfield(arbConfig, 'defaultFc'))
    set(handles.editCarrier, 'String', iqengprintf(arbConfig.defaultFc));
end
% update all the fields
checkfields([], 0, handles);

if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'Enter the AWG sample rate in Hertz. For simulation, the sample rate\n' ...
    'can have any value, but if you want to download to the AWG, you have\n' ...
    'to stay within the range that is supported by the AWG.']));
set(handles.checkboxAutoSampleRate, 'TooltipString', sprintf([ ...
    'If you select "Auto", the utility will try to find the smallest\n' ...
    'number of samples that can represent the signal and at the same time\n' ...
    'meet any limitations that the AWG might have in terms of minimum segment\n' ...
    'length and segment granularity.']));
set(handles.editTones, 'TooltipString', sprintf([ ...
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
set(handles.popupmenuPhase, 'TooltipString', sprintf([ ...
    'Select the phase relationship of the individual tones with respect to\n' ...
    'each other. "Random" is usually the best choice to get a reasonably low\n' ...
    'crest factor. "Parabolic" will generate the lowest possible crest factor\n' ...
    'but the signal has some (possibly undesired) symmetries. You might want\n' ...
    'to experiment with various phase settings and observe the difference\n' ...
    'using "Visualize in MATLAB"']));
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
set(handles.pushbuttonCal, 'TooltipString', sprintf([ ...
    'This button uses either a spectrum analyzer or the VSA software to perform\n' ...
    'a magnitude calibration. The "Ampl.Corr.using" popupmenu allows you to select\n' ...
    'which method is used. After pressing this button, the magnitude of each of\n' ...
    'tone is determined and the deviation from the average is stored in a file.\n' ...
    'Once the file has been created, pre-distortion is automatically applied\n' ...
    'to the original signal; the pre-distorted waveform is downloaded into the\n' ...
    'AWG\n\n' ...
    'Please verify that you have the "Fc (calibration only)" parameter set to the\n' ...
    'correct value before starting the calibration process.']));
set(handles.editCarrier, 'TooltipString', sprintf([ ...
    'Use this field to set the "center" frequency when performing flatness\n' ...
    'correction. If you have the AWG output connected directly to a spectrum\n' ...
    'analyzer or oscilloscope, enter a zero. If you are correcting the flatness\n' ...
    'of an up-converted signal, enter the LO frequency of your upconverter in\n' ...
    'this field if you are using the upper sideband or the LO frequency with\n' ...
    'a negative sign if you are using the lower sideband.']));
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
set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the simulated waveform using MATLAB plots.\n' ...
    'The signal will be displayed both in the time- as well as frequency\n' ...
    'domain (spectrum). This function can be used even without any hardware\n' ...
    'connected.']));
set(handles.pushbuttonChannelMapping, 'TooltipString', sprintf([ ...
    'Select into which channels the real and imaginary part of the waveform\n' ...
    'is loaded. By default, I is loaded into Channel 1, Q into channel 2, but\n' ...
    'it is also possible to load the same signal into both channels.\n' ...
    'In DUC modes, both I and Q are used for the same channel.\n' ...
    'In dual-M8190A configurations, channels 3 and 4 are on the second module.']));
set(handles.editSegment, 'TooltipString', sprintf([ ...
    'Enter the AWG waveform segment to which the signal will be downloaded.\n' ...
    'If you download to segment #1, all other segments will be automatically\n' ...
    'deleted.']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Use this button to calculate and download the signal to the configured AWG.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
set(handles.pushbuttonShowInVSA, 'TooltipString', sprintf([ ...
    'Use this button to calculate and visualize the signal using the VSA software.\n' ...
    'If the VSA software is not already running, it will be started. The utility will\n' ...
    'automatically configure the VSA software for the parameters of the generated signal.\n']));
end
% UIWAIT makes iqtone_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqtone_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
%function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
%function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%file = uigetfile('*.fig');
%if ~isequal(file, 0)
%    open(file);
%end


% --------------------------------------------------------------------
%function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%printdlg(handles.iqtool)


% --------------------------------------------------------------------
%function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%selection = questdlg(['Close ' get(handles.iqtool,'Name') '?'],...
%                     ['Close ' get(handles.iqtool,'Name') '...'],...
%                     'Yes','No','Yes');
%if strcmp(selection,'No')
%    return;
%end

%delete(handles.iqtool)


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



function editTones_Callback(hObject, eventdata, handles)
% hObject    handle to editTones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTones as text
%        str2double(get(hObject,'String')) returns contents of editTones as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 0 && value <= 100000)
    points = evalin('base',get(handles.editPoints, 'String'));
    numTones = evalin('base', get(handles.editTones, 'String'));
    startFreq = evalin('base', ['[' get(handles.editStartFreq, 'String') ']']);
    stopFreq = evalin('base', ['[' get(handles.editStopFreq, 'String') ']']);
    startFreq = startFreq(1); % in case the user entered a list
    stopFreq = stopFreq(1);   % in case the user entered a list
    if (numTones == 0)
        set(handles.editToneSpacing, 'String', 'n/a');
        set(handles.editStartFreq, 'Enable', 'on');
        set(handles.popupmenuPhase, 'Enable', 'off');
        % user must enter a number of samples. Suggest around 1 million.
        set(handles.checkboxAutoSampleRate, 'Value', 0);
        if (points < 900000)
            points = 1000000;
            set(handles.editPoints, 'String', sprintf('%d', points));
            editPoints_Callback(hObject, eventdata, handles);
        end
        checkboxAutoSampleRate_Callback(hObject, eventdata, handles);
    elseif (numTones == 1)
        set(handles.editToneSpacing, 'String', 'n/a');
        set(handles.editStartFreq, 'Enable', 'off');
        set(handles.popupmenuPhase, 'Enable', 'on');
    else
        spacing = (stopFreq - startFreq) / (numTones - 1);
        set(handles.editToneSpacing, 'String', iqengprintf(spacing));
        set(handles.editStartFreq, 'Enable', 'on');
        set(handles.popupmenuPhase, 'Enable', 'on');
    end
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end
resetCal(handles);


% --- Executes during object creation, after setting all properties.
function editTones_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTones (see GCBO)
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
    numTones = evalin('base', get(handles.editTones, 'String'));
    startFreq = value;
    stopFreq = evalin('base', ['[' get(handles.editStopFreq, 'String') ']']);
    if (numTones <= 1)
        set(handles.editToneSpacing, 'String', 'n/a');
    else
        spacing = (stopFreq(1) - startFreq(1)) / (numTones - 1);
        set(handles.editToneSpacing, 'String', iqengprintf(spacing));
    end
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end
resetCal(handles);


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
    numTones = evalin('base',get(handles.editTones, 'String'));
    startFreq = evalin('base', ['[' get(handles.editStartFreq, 'String') ']']);
    stopFreq = value;
    if (numTones <= 1)
        set(handles.editToneSpacing, 'String', 'n/a');
    else
        startFreq = startFreq(1);
        stopFreq = stopFreq(1);
        spacing = (stopFreq - startFreq) / (numTones - 1);
        set(handles.editToneSpacing, 'String', iqengprintf(spacing));
    end
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end
resetCal(handles);


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


% --- Executes on selection change in popupmenuPhase.
function popupmenuPhase_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenuPhase contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuPhase
phaseIdx = get(hObject, 'Value');
if (phaseIdx == 5)
    set(handles.editPhase, 'Enable', 'on');
else
    set(handles.editPhase, 'Enable', 'off');
end


% --- Executes during object creation, after setting all properties.
function popupmenuPhase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.lastDownload = 'HW';
guidata(hObject, handles);
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
[iqdata, sampleRate, channelMapping] = calculate(handles);
segmentNum = evalin('base', get(handles.editSegment, 'String'));
iqdownload(iqdata, sampleRate, 'channelMapping', channelMapping, ...
    'segmentNumber', segmentNum);
set(handles.pushbuttonCal, 'Enable', 'on');
set(handles.textCarrier, 'Enable', 'on');
set(handles.editCarrier, 'Enable', 'on');
set(handles.textCalType, 'Enable', 'on');
set(handles.popupmenuCalType, 'Enable', 'on');
try
    close(hMsgBox);
catch
end


% --- Executes on button press in checkboxAutoSampleRate.
function checkboxAutoSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAutoSampleRate
autoSamples = get(handles.checkboxAutoSampleRate, 'Value');
if (autoSamples)
    set(handles.editPoints, 'Enable', 'off');
else
    set(handles.editPoints, 'Enable', 'on');
end

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
resetCal(handles);


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


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata, sampleRate] = calculate(handles);
iqplot(iqdata, sampleRate);


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
resetCal(handles);


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



function editToneSpacing_Callback(hObject, eventdata, handles)
% hObject    handle to editToneSpacing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editToneSpacing as text
%        str2double(get(hObject,'String')) returns contents of editToneSpacing as a double


% --- Executes during object creation, after setting all properties.
function editToneSpacing_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editToneSpacing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCarrier_Callback(hObject, eventdata, handles)
% hObject    handle to editCarrier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCarrier as text
%        str2double(get(hObject,'String')) returns contents of editCarrier as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editCarrier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCarrier (see GCBO)
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
resetCal(handles);


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
%     set(handles.textMagnitude, 'Visible', 'Off');
%     set(handles.editMagnitude, 'Visible', 'Off');
    set(handles.editNotchDepth, 'Enable', 'On');
else
    set(handles.editNotchFreq, 'Enable', 'Off');
    set(handles.editNotchSpan, 'Enable', 'Off');
%     set(handles.textMagnitude, 'Visible', 'On');
%     set(handles.editMagnitude, 'Visible', 'On');
    set(handles.editNotchDepth, 'Enable', 'Off');
end


% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection
correction = get(handles.checkboxCorrection, 'Value');
if (~correction)
    set(handles.pushbuttonCal, 'String', 'Calibrate');
end


% --- Executes on selection change in popupmenuCalType.
function popupmenuCalType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuCalType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuCalType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuCalType


% --- Executes during object creation, after setting all properties.
function popupmenuCalType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuCalType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editPhase_Callback(hObject, eventdata, handles)
% hObject    handle to editPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPhase as text
%        str2double(get(hObject,'String')) returns contents of editPhase as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (isvector(value) && isempty(find(value < -1e6)) && isempty(find(value > 1e6)))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
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


% --- Executes on button press in pushbuttonCal.
function pushbuttonCal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
notch = get(handles.checkboxNotchEnable, 'Value');
if (notch)
    errordlg('Can not perform calibration with a notch enabled. Please download a signal without notch and run calibration again');
    return;
end
numTones = evalin('base', get(handles.editTones, 'String'));
if (numTones == 0)
    errordlg('Can not perform calibration with a noise signal. Please set #of tones to a positive number');
    return;
end
correction = get(handles.checkboxCorrection, 'Value');
freqOffset = evalin('base', get(handles.editCarrier, 'String'));
[tone, ~] = calc_tones(handles);
calType = get(handles.popupmenuCalType, 'Value');

% check consistency
if (freqOffset >= 0 && min(tone + freqOffset) <= 0 && calType ~= 5)
   errordlg('Can''t calibrate negative RF frequencies. Please check "Fc (correction only)" parameter'); 
   return;
end
% if correction checkbox is on, perform a re-cal
if (correction)
    res = doCal(handles, tone, freqOffset, 1);
else
    % if correction is not turned on, do a "fresh" calibration
    % check if some corrections are turn on and warn the user
    [~, perChannelCorr] = iqcorrection([]);
    % ask for confirmation if perChannelCorrection exists and we are not
    % using power sensor cal (which handles perChannelCorr gracefully)
%     if (~isempty(perChannelCorr) && get(handles.popupmenuCalType, 'Value') ~= 7)
%         res = questdlg({'You have per-channel corrections defined, but they are not applied.' ...
%             'Do you want to continue?? ' ...
%             '(If you click "Yes", the per-channel corrections will be erased)'});
%         if (strcmp(res, 'Yes') == 0)
%             return;
%         end
%     end
    doLastDownload(hObject, eventdata, handles);
    res = doCal(handles, tone, freqOffset, 0);
    % turn on correction and download a newly calculated set of data
    if (~isempty(res))
        set(handles.checkboxCorrection, 'Value', 1);
    end
end
checkboxCorrection_Callback(hObject, eventdata, handles);
if (~isempty(res))
    doLastDownload(hObject, eventdata, handles);
end


function doLastDownload(hObject, eventdata, handles)
% perform the "last" download action: either download to HW or to VSA
if (isfield(handles, 'lastDownload') && strcmp(handles.lastDownload, 'VSA'))
    pushbuttonShowInVSA_Callback(hObject, eventdata, handles);
else
    pushbuttonDownload_Callback(hObject, eventdata, handles);
end
    
    

function res = doCal(handles, tone, freqOffset, recal)
res = [];
fs = evalin('base', get(handles.editSampleRate, 'String'));
mag = evalin('base', ['[' get(handles.editMagnitude, 'String') ']']);
mag = reshape(mag, numel(mag), 1);
correction = get(handles.checkboxCorrection, 'Value');
normalize = get(handles.checkboxNormalize, 'Value');
if (isfield(handles, 'lastDownload') && strcmp(handles.lastDownload, 'VSA'))
    useHW = 0;
else
    useHW = 1;
end
hMsgBox = msgbox('Performing Calibration. Please wait...', 'Please wait...', 'replace');
try 
    ch = get(hMsgBox, 'Children');
    set(ch(2), 'String', 'Cancel');
catch
end
try
    channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
    switch (get(handles.popupmenuCalType, 'Value'))
        case 1  % spectrum analyzer (zero span)
            res = iqcal('tone', tone, 'offset', freqOffset, 'recalibrate', recal, 'method', 'zero span', 'samplerate', fs, 'chMap', channelMapping, ...
                'normalize', normalize, 'correction', correction, 'magnitude', mag, 'handles', handles, 'msgbox', hMsgBox);
        case 2  % spectrum analyzer (marker)
            res = iqcal('tone', tone, 'offset', freqOffset, 'recalibrate', recal, 'method', 'marker', 'samplerate', fs, 'chMap', channelMapping, ...
                'normalize', normalize, 'correction', correction, 'magnitude', mag, 'handles', handles, 'msgbox', hMsgBox);
        case 3  % spectrum analyzer (list sweep)
            res = iqcal('tone', tone, 'offset', freqOffset, 'recalibrate', recal, 'method', 'list sweep', 'samplerate', fs, 'chMap', channelMapping, ...
                'normalize', normalize, 'correction', correction, 'magnitude', mag, 'handles', handles, 'msgbox', hMsgBox);
        case 4  % spectrum analyzer (single tone)
            res = iqcal('tone', tone, 'offset', freqOffset, 'recalibrate', recal, 'method', 'single tone', 'samplerate', fs, 'chMap', channelMapping, ...
                'normalize', normalize, 'correction', correction, 'magnitude', mag, 'handles', handles, 'msgbox', hMsgBox);
        case 5  % VSA Software
            res = iqvsamtone('tone', tone, 'fc', freqOffset, 'recalibrate', recal, 'useHW', useHW);
        case 6  % VSA using channel quality
            [~, freqPoints, magPoints, phasePoints , ~] = calculateCQM(handles);
            res = iqvsacqm('recalibrate', recal, 'tone', freqPoints, 'mag', magPoints, 'phase', phasePoints, 'fc', freqOffset);
        case 7  % Power Sensor
            res = iqpowersensorcal('tone', tone, 'offset', freqOffset, 'recalibrate', recal, 'samplerate', fs, 'chMap', channelMapping, ...
                'normalize', normalize, 'correction', correction, 'magnitude', mag, 'handles', handles, 'msgbox', hMsgBox);
    end
catch ex
    errordlg(getReport(ex, 'extended', 'hyperlinks', 'off'));
end
try
    close(hMsgBox);
catch
end
if (~isempty(res))
    updateCorrWindow();
end


function updateCorrWindow()
% If Correction Mgmt Window is open, refresh it
try
    TempHide = get(0, 'ShowHiddenHandles');
    set(0, 'ShowHiddenHandles', 'on');
    figs = findobj(0, 'Type', 'figure', 'Name', 'Correction Management');
    set(0, 'ShowHiddenHandles', TempHide);
    if (~isempty(figs))
        iqcorrmgmt();
    end
catch ex
end


function resetCal(handles)
set(handles.pushbuttonCal, 'String', 'Calibrate');


% --------------------------------------------------------------------
function Preset_Callback(hObject, eventdata, handles)
% hObject    handle to Preset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function preset_default_Callback(hObject, eventdata, handles)
% hObject    handle to preset_default (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editStartFreq, 'String', '-900e6');
set(handles.editStopFreq, 'String', '900e6');
set(handles.editTones, 'String', '37');
editTones_Callback(handles.editTones, eventdata, handles);
set(handles.editNotchFreq, 'String', '0');
set(handles.editNotchSpan, 'String', '0');
set(handles.checkboxNotchEnable, 'Value', 0);
checkboxNotchEnable_Callback(hObject, eventdata, handles);
set(handles.checkboxAutoSampleRate, 'Value', 1);
checkboxAutoSampleRate_Callback(hObject, eventdata, handles);
set(handles.checkboxCorrection, 'Value', 0);
checkboxCorrection_Callback(hObject, eventdata, handles);
set(handles.popupmenuPhase, 'Value', 1);
checkfields(hObject, 0, handles);

% --------------------------------------------------------------------
function preset_asymm_2GHz_Callback(hObject, eventdata, handles)
% hObject    handle to preset_asymm_2GHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editStartFreq, 'String', '-1e9 + 2e7/4');
set(handles.editStopFreq, 'String', '+1e9 + 2e7/4');
set(handles.editTones, 'String', '101');
editTones_Callback(handles.editTones, eventdata, handles);
set(handles.editNotchFreq, 'String', '0');
set(handles.editNotchSpan, 'String', '0');
set(handles.checkboxNotchEnable, 'Value', 0);
checkboxNotchEnable_Callback(hObject, eventdata, handles);
set(handles.checkboxAutoSampleRate, 'Value', 1);
checkboxAutoSampleRate_Callback(hObject, eventdata, handles);
set(handles.checkboxCorrection, 'Value', 0);
checkboxCorrection_Callback(hObject, eventdata, handles);
set(handles.popupmenuPhase, 'Value', 2);
checkfields(hObject, 0, handles);

% --------------------------------------------------------------------
function positive_100_tones_Callback(hObject, eventdata, handles)
% hObject    handle to positive_100_tones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editStartFreq, 'String', '10e6');
set(handles.editStopFreq, 'String', '1000e6');
set(handles.editTones, 'String', '100');
editTones_Callback(handles.editTones, eventdata, handles);
set(handles.editNotchFreq, 'String', '0');
set(handles.editNotchSpan, 'String', '0');
set(handles.editNotchDepth, 'String', '-300');
set(handles.checkboxNotchEnable, 'Value', 0);
checkboxNotchEnable_Callback(hObject, eventdata, handles);
set(handles.checkboxAutoSampleRate, 'Value', 1);
checkboxAutoSampleRate_Callback(hObject, eventdata, handles);
set(handles.checkboxCorrection, 'Value', 0);
checkboxCorrection_Callback(hObject, eventdata, handles);
set(handles.popupmenuPhase, 'Value', 2);
checkfields(hObject, 0, handles);


% --------------------------------------------------------------------
function noise_100M_1G_Callback(hObject, eventdata, handles)
% hObject    handle to noise_100M_1G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
points = min(200000, arbConfig.maximumSegmentSize);
points = points - mod(points, arbConfig.segmentGranularity);
set(handles.editPoints, 'String', num2str(points));
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editStartFreq, 'String', '100e6');
set(handles.editStopFreq, 'String', '1000e6');
set(handles.editTones, 'String', '0');
editTones_Callback(handles.editTones, eventdata, handles);
set(handles.editNotchFreq, 'String', '500e6');
set(handles.editNotchSpan, 'String', '100e6');
set(handles.editNotchDepth, 'String', '-300');
set(handles.checkboxNotchEnable, 'Value', 1);
checkboxNotchEnable_Callback(hObject, eventdata, handles);
set(handles.checkboxAutoSampleRate, 'Value', 0);
checkboxAutoSampleRate_Callback(hObject, eventdata, handles);
set(handles.checkboxCorrection, 'Value', 0);
checkboxCorrection_Callback(hObject, eventdata, handles);
set(handles.popupmenuPhase, 'Value', 2);
checkfields(hObject, 0, handles);

% --------------------------------------------------------------------
function multi_notch_Callback(hObject, eventdata, handles)
% hObject    handle to multi_notch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editPoints, 'String', '96000');
set(handles.editStartFreq, 'String', '1e7');
set(handles.editStopFreq, 'String', '3e9');
set(handles.editTones, 'String', '300');
editTones_Callback(handles.editTones, eventdata, handles);
set(handles.editNotchFreq, 'String', '1e8:3e8:3e9');
set(handles.editNotchSpan, 'String', '1e8');
set(handles.editNotchDepth, 'String', '-50:5:-5');
set(handles.checkboxNotchEnable, 'Value', 1);
checkboxNotchEnable_Callback(hObject, eventdata, handles);
set(handles.checkboxAutoSampleRate, 'Value', 1);
checkboxAutoSampleRate_Callback(hObject, eventdata, handles);
set(handles.checkboxCorrection, 'Value', 0);
checkboxCorrection_Callback(hObject, eventdata, handles);
set(handles.popupmenuPhase, 'Value', 2);
checkfields(hObject, 0, handles);

function xfprintf(f, s)
% Send the string s to the instrument object f
% and check the error status

% un-comment the following line to see a trace of commands
%    fprintf('cmd = %s\n', s);
fprintf(f, s);
res = query(f, ':syst:err?');
if (length(res) == 0)
    fclose(f);
    error(':syst:err query failed');
end
if (~strcmp(res, ['+0,"No error"' 10]))
    fprintf('cmd = %s / result = %s', s, res);
end

% --------------------------------------------------------------------
function single555_Callback(hObject, eventdata, handles)
% hObject    handle to single555 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[arbConfig saConfig] = loadArbConfig();
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editStartFreq, 'String', '555e6');
set(handles.editStopFreq, 'String', '555e6');
set(handles.editTones, 'String', '1');
editTones_Callback(handles.editTones, eventdata, handles);
set(handles.editNotchFreq, 'String', '0');
set(handles.editNotchSpan, 'String', '0');
set(handles.editNotchDepth, 'String', '-300');
set(handles.checkboxNotchEnable, 'Value', 0);
checkboxNotchEnable_Callback(hObject, eventdata, handles);
set(handles.checkboxAutoSampleRate, 'Value', 1);
checkboxAutoSampleRate_Callback(hObject, eventdata, handles);
set(handles.checkboxCorrection, 'Value', 0);
checkboxCorrection_Callback(hObject, eventdata, handles);
set(handles.popupmenuPhase, 'Value', 2);
set(handles.popupmenuCalType, 'Value', 1);
set(handles.pushbuttonChannelMapping, 'UserData', []);
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig);
checkfields(hObject, 0, handles);
pushbuttonDownload_Callback(hObject, eventdata, handles);
if (saConfig.connected ~= 0)
    try
        f = iqopen(saConfig);
        xfprintf(f, ':INST SA');
        xfprintf(f, '*RST');
        xfprintf(f, ':BWID 30e3');
        xfprintf(f, ':FREQ:START 10e6');
        xfprintf(f, ':FREQ:STOP 1e9');
        xfprintf(f, ':DISP:WIND:TRAC:Y:RLEV 0 dBm');
        xfprintf(f, ':INIT:CONT ON');
        xfprintf(f, ':INIT:IMM');
        query(f, '*OPC?');
        xfprintf(f, ':CALC:MARK1:STAT ON');
        xfprintf(f, ':CALC:MARK1:MODE POS');
        xfprintf(f, ':CALC:MARK1:MODE FIX');
        xfprintf(f, ':CALC:MARK1:MAX');
        xfprintf(f, ':CALC:MARK2:STAT ON');
        xfprintf(f, ':CALC:MARK2:REF 1');
        xfprintf(f, ':CALC:MARK2:X -109.01e6');
        fclose(f);
    catch e
        msgbox(e.message);
    end
end

% --------------------------------------------------------------------
function twoTone_100kHz_Callback(hObject, eventdata, handles)
% hObject    handle to twoTone_100kHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[arbConfig saConfig] = loadArbConfig();
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editStartFreq, 'String', '555e6 - 50e3');
set(handles.editStopFreq, 'String', '555e6 + 50e3');
set(handles.editTones, 'String', '2');
editTones_Callback(handles.editTones, eventdata, handles);
set(handles.editNotchFreq, 'String', '0');
set(handles.editNotchSpan, 'String', '0');
set(handles.editNotchDepth, 'String', '-300');
set(handles.checkboxNotchEnable, 'Value', 0);
checkboxNotchEnable_Callback(hObject, eventdata, handles);
set(handles.checkboxAutoSampleRate, 'Value', 1);
checkboxAutoSampleRate_Callback(hObject, eventdata, handles);
set(handles.checkboxCorrection, 'Value', 0);
checkboxCorrection_Callback(hObject, eventdata, handles);
set(handles.popupmenuPhase, 'Value', 2);
set(handles.popupmenuCalType, 'Value', 1);
set(handles.pushbuttonChannelMapping, 'UserData', []);
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig);
checkfields(hObject, 0, handles);
pushbuttonDownload_Callback(hObject, eventdata, handles);
if (saConfig.connected ~= 0)
    try
        f = iqopen(saConfig);
        xfprintf(f, ':INST SA');
        xfprintf(f, '*RST');
        xfprintf(f, ':BWID 3e3');
        xfprintf(f, ':FREQ:CENT 555e6');
        xfprintf(f, ':FREQ:SPAN 10e6');
        xfprintf(f, ':DISP:WIND:TRAC:Y:RLEV -5 dBm');
        xfprintf(f, ':INIT:CONT ON');
        xfprintf(f, ':INIT:IMM');
        query(f, '*OPC?');
        xfprintf(f, ':CALC:MARK1:STAT ON');
        xfprintf(f, ':CALC:MARK1:MODE POS');
        xfprintf(f, ':CALC:MARK1:MODE FIX');
        xfprintf(f, ':CALC:MARK1:MAX');
        xfprintf(f, ':CALC:MARK2:STAT ON');
        xfprintf(f, ':CALC:MARK2:REF 1');
        xfprintf(f, ':CALC:MARK2:X -100e3');
        fclose(f);
    catch e
        msgbox(e.message);
    end
end


% --------------------------------------------------------------------
function twoTone_1MHz_Callback(hObject, eventdata, handles)
% hObject    handle to twoTone_1MHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[arbConfig saConfig] = loadArbConfig();
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editStartFreq, 'String', '500e6 - 500e3');
set(handles.editStopFreq, 'String', '500e6 + 500e3');
set(handles.editTones, 'String', '2');
editTones_Callback(handles.editTones, eventdata, handles);
set(handles.editNotchFreq, 'String', '0');
set(handles.editNotchSpan, 'String', '0');
set(handles.editNotchDepth, 'String', '-300');
set(handles.checkboxNotchEnable, 'Value', 0);
checkboxNotchEnable_Callback(hObject, eventdata, handles);
set(handles.checkboxAutoSampleRate, 'Value', 1);
checkboxAutoSampleRate_Callback(hObject, eventdata, handles);
set(handles.checkboxCorrection, 'Value', 0);
checkboxCorrection_Callback(hObject, eventdata, handles);
set(handles.popupmenuPhase, 'Value', 2);
set(handles.popupmenuCalType, 'Value', 1);
set(handles.pushbuttonChannelMapping, 'UserData', []);
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig);
checkfields(hObject, 0, handles);
pushbuttonDownload_Callback(hObject, eventdata, handles);
if (saConfig.connected ~= 0)
    try
        f = iqopen(saConfig);
        xfprintf(f, ':INST SA');
        xfprintf(f, '*RST');
        xfprintf(f, ':BWID 10e3');
        xfprintf(f, ':FREQ:CENT 500e6');
        xfprintf(f, ':FREQ:SPAN 5e6');
        xfprintf(f, ':DISP:WIND:TRAC:Y:RLEV -5 dBm');
        xfprintf(f, ':INIT:CONT ON');
        xfprintf(f, ':INIT:IMM');
        query(f, '*OPC?');
        xfprintf(f, ':CALC:MARK1:STAT ON');
        xfprintf(f, ':CALC:MARK1:MODE POS');
        xfprintf(f, ':CALC:MARK1:MODE FIX');
        xfprintf(f, ':CALC:MARK1:MAX');
        xfprintf(f, ':CALC:MARK2:STAT ON');
        xfprintf(f, ':CALC:MARK2:REF 1');
        xfprintf(f, ':CALC:MARK2:X -1e6');
        fclose(f);
    catch e
        msgbox(e.message);
    end
end


% --------------------------------------------------------------------
function mtone_2GHz_Callback(hObject, eventdata, handles)
% hObject    handle to mtone_2GHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[arbConfig saConfig] = loadArbConfig();
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editStartFreq, 'String', '20e6');
set(handles.editStopFreq, 'String', '2e9');
set(handles.editTones, 'String', '100');
editTones_Callback(handles.editTones, eventdata, handles);
set(handles.editNotchFreq, 'String', '1e9');
set(handles.editNotchSpan, 'String', '1e8');
set(handles.editNotchDepth, 'String', '-300');
set(handles.checkboxNotchEnable, 'Value', 1);
checkboxNotchEnable_Callback(hObject, eventdata, handles);
set(handles.checkboxAutoSampleRate, 'Value', 1);
checkboxAutoSampleRate_Callback(hObject, eventdata, handles);
set(handles.checkboxCorrection, 'Value', 0);
checkboxCorrection_Callback(hObject, eventdata, handles);
set(handles.popupmenuPhase, 'Value', 2);
set(handles.popupmenuCalType, 'Value', 1);
set(handles.pushbuttonChannelMapping, 'UserData', []);
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig);
checkfields(hObject, 0, handles);
answer = questdlg('Perform flatness correction now?');
switch answer
    case 'Yes'
        set(handles.checkboxNotchEnable, 'Value', 0);
        pushbuttonCal_Callback(hObject, eventdata, handles);
        set(handles.checkboxNotchEnable, 'Value', 1);
    case 'No'
        set(handles.checkboxCorrection, 'Value', 1);
    case 'Cancel'
        return;
end
pushbuttonDownload_Callback(hObject, eventdata, handles);
if (saConfig.connected ~= 0)
    try
        f = iqopen(saConfig);
        xfprintf(f, ':INST SA');
        xfprintf(f, '*RST');
        xfprintf(f, ':BWID 30e3');
        xfprintf(f, ':FREQ:START 10e6');
        xfprintf(f, ':FREQ:STOP 2.1e9');
        xfprintf(f, ':DISP:WIND:TRAC:Y:RLEV -10 dBm');
        xfprintf(f, ':INIT:CONT ON');
        xfprintf(f, ':INIT:IMM');
        query(f, '*OPC?');
        xfprintf(f, ':CALC:MARK1:STAT ON');
        xfprintf(f, ':CALC:MARK1:MODE POS');
        xfprintf(f, ':CALC:MARK1:MODE FIX');
        xfprintf(f, ':CALC:MARK1:MAX');
        xfprintf(f, ':CALC:MARK2:STAT ON');
        xfprintf(f, ':CALC:MARK2:MODE POS');
        xfprintf(f, ':CALC:MARK2:X 1e9');
        xfprintf(f, ':CALC:MARK2:REF 1');
    catch e
        msgbox(e.message);
    end
    fclose(f);
end


% --------------------------------------------------------------------
function preset_dummy_Callback(hObject, eventdata, handles)
% hObject    handle to preset_dummy (see GCBO)
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


% --- Executes on button press in pushbuttonShowInVSA.
function pushbuttonShowInVSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowInVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% remember which kind of download was last used
handles.lastDownload = 'VSA';
guidata(hObject, handles);

[iqdata, sampleRate] = calculate(handles);
[tone, ~] = calc_tones(handles);
span = (max(tone) - min(tone)) * 1.1;
% for some reason that I don't know, VSA does not show a signal when the
% span is less than 4.1 GHz
%span = max(span, 4100e6);
fc = (max(tone) + min(tone)) / 2;
vsaApp = vsafunc([], 'open');
if (~isempty(vsaApp))
    hMsgBox = msgbox('Configuring VSA software. Please wait...', 'Please wait...', 'replace');
    vsafunc(vsaApp, 'preset', 'vector');
    vsafunc(vsaApp, 'load', iqdata, sampleRate);
    vsafunc(vsaApp, 'input', 1);
    vsafunc(vsaApp, 'freq', fc, span, 51201, 'flattop');
    vsafunc(vsaApp, 'trace', 1, 'Tones');
    vsafunc(vsaApp, 'start', 1);
    vsafunc(vsaApp, 'autoscale', 1);
    try
        close(hMsgBox);
    catch
    end
end




function [tone, mag] = calc_tones(handles, doCode)
% get a vector of tone frequencies based on data in edit fields
% handles    structure with handles and user data (see GUIDATA)
numTones = evalin('base', get(handles.editTones, 'String'));
startFreq = evalin('base', ['[' get(handles.editStartFreq, 'String') ']']);
stopFreq = evalin('base', ['[' get(handles.editStopFreq, 'String') ']']);
notchFreq = evalin('base', ['[' get(handles.editNotchFreq, 'String') ']']);
notchSpan = evalin('base', ['[' get(handles.editNotchSpan, 'String') ']']);
notchDepth = evalin('base', ['[' get(handles.editNotchDepth, 'String') ']']);
notchEnable = get(handles.checkboxNotchEnable, 'Value');
if (exist('doCode', 'var') && doCode ~= 0)
    if (numTones == 1)
        tone = sprintf('[ %s ]', iqengprintf(stopFreq));
        numTones = 1;
    elseif (numTones > 1)
        tone = '[';
        for i = 1:min(length(startFreq), length(stopFreq))
            tone = sprintf('%s linspace(%s, %s, %d)', tone, iqengprintf(startFreq(i)), iqengprintf(stopFreq(i)), numTones);
        end
        tone = [ tone ' ]'];
    else
        tone = sprintf('[ %s %s ]', iqengprintf(startFreq), iqengprintf(stopFreq));    % for VSA visualisation
        numTones = 2;
    end
else
    if (numTones == 1)
        tone = stopFreq;    % can be a single number or a vector!
        numTones = length(stopFreq);
    elseif (numTones > 1)
        tone = [];
        for i = 1:min(length(startFreq), length(stopFreq))
            tone = [tone linspace(startFreq(i), stopFreq(i), numTones)'];
        end
        tone = tone(1:end)';
        numTones = length(tone);
    else
        tone = [startFreq stopFreq];    % for VSA visualisation
        numTones = 2;
    end
end
mag = zeros(numTones, 1);
if (notchEnable)
    if (size(notchSpan, 2) > 1)
        notchSpan = notchSpan.';
    end
    if (isempty(notchSpan))
        notchSpan = 0;
    end
    if (length(notchSpan) < length(notchFreq))
        notchSpan = repmat(notchSpan, ceil(length(notchFreq) / length(notchSpan)), 1);
    end
    if (size(notchDepth, 2) > 1)
        notchDepth = notchDepth.';
    end
    if (isempty(notchDepth))
        notchDepth = -3000 * ones(length(notchFreq), 1);
    end
    if (length(notchDepth) < length(notchFreq))
        notchDepth = repmat(notchDepth, ceil(length(notchFreq) / length(notchDepth)), 1);
    end
    for i=1:length(notchFreq)
        idx = (tone >= notchFreq(i) - notchSpan(i)/2 & tone <= notchFreq(i) + notchSpan(i)/2);
        mag(idx) = mag(idx) + notchDepth(i);
    end
end
mag0 = evalin('base', ['[' get(handles.editMagnitude, 'String') ']']);
mag0 = fixlength(mag0, numTones)';
mag = mag + mag0;



function x = fixlength(x, len)
if (len > 0)
    x = reshape(x, 1, length(x));
    x = repmat(x, 1, ceil(len / length(x)));
    x = x(1:len);
end


function [iqdata, sampleRate, channelMapping] = calculate(handles, doCode)
% calculate a complex IQ vector based on data in edit fields
% handles    structure with handles and user data (see GUIDATA)
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
autoSamples = get(handles.checkboxAutoSampleRate, 'Value');
points = evalin('base',get(handles.editPoints, 'String'));
phaseList = get(handles.popupmenuPhase, 'String');
phaseIdx = get(handles.popupmenuPhase, 'Value');
phase = phaseList{phaseIdx};
if (phaseIdx == 5)
    phase = evalin('base', ['[' get(handles.editPhase, 'String') ']']);
    phase = phase ./ 180 .* pi;
end
correction = get(handles.checkboxCorrection, 'Value');
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
numTones = evalin('base',get(handles.editTones, 'String'));
normalize = get(handles.checkboxNormalize, 'Value');
if (numTones == 0)
    if (autoSamples)
        errordlg('You must specify number of samples for noise');
    end
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
    if (exist('doCode', 'var'))
        startFreqStr = ['[' strtrim(sprintf('%g ', startFreq)) ']'];
        stopFreqStr = ['[' strtrim(sprintf('%g ', stopFreq)) ']'];
        notchFreqStr = ['[' strtrim(sprintf('%g ', notchFreq)) ']'];
        notchSpanStr = ['[' strtrim(sprintf('%g ', notchSpan)) ']'];
        notchDepthStr = ['[' strtrim(sprintf('%g ', notchDepth)) ']'];
        chanMapStr = iqchannelsetup('arraystring', get(handles.pushbuttonChannelMapping, 'UserData'));
        segmentNum = evalin('base', get(handles.editSegment, 'String'));
        iqdata = sprintf(['fs = %s;\n[iqdata, chMap] = iqnoise(''sampleRate'', fs, ...\n' ...
            '    ''numSamples'', %g, ''start'', %s, ''stop'', %s, ...\n' ...
            '    ''notchFreq'', %s, ''notchSpan'', %s, ''notchDepth'', %s, ...\n' ...
            '    ''correction'', %d, ''channelMapping'', %s);\n' ...
            'iqdownload(iqdata, fs, ''channelMapping'', chMap, ...\n' ...
            '    ''segmentNumber'', %d);\n'], ...
            iqengprintf(sampleRate), points, startFreqStr, stopFreqStr, notchFreqStr, ...
            notchSpanStr, notchDepthStr, correction, chanMapStr, segmentNum);
    else
        [iqdata, channelMapping] = iqnoise('sampleRate', sampleRate, 'numSamples', points, ...
            'start', startFreq, 'stop', stopFreq, 'notchFreq', notchFreq, ...
            'notchSpan', notchSpan, 'notchDepth', notchDepth, 'correction', correction, ...
            'channelMapping', channelMapping);
        assignin('base', 'iqdata', iqdata);
    end
else
    if (autoSamples)
        points = 0;
    end
    if (exist('doCode', 'var') && doCode ~= 0)
        [toneStr, mag] = calc_tones(handles, 1);
        fsStr = sprintf('fs = %s;\n', iqengprintf(sampleRate));
        if (ischar(phase))
            phase = ['''' phase ''''];
            phaseStr = '';
        else
            phaseStr = ['phase = [' strtrim(sprintf('%g ', phase)) '];\n'];
            phase = 'phase';
        end
        chanMapStr = iqchannelsetup('arraystring', get(handles.pushbuttonChannelMapping, 'UserData'));
        segmentNum = evalin('base', get(handles.editSegment, 'String'));
        toneStr = ['tone = ' strtrim(toneStr) ';\n'];
        if (isempty(find(mag ~= 0)))
            magStr = sprintf('magnitude = zeros(1, %d);\n', length(mag));
        else
            magStr = ['magnitude = [' strtrim(sprintf('%g ', mag)) '];\n'];
        end
        iqdata = [sprintf([fsStr toneStr magStr phaseStr '\n[iqdata, ~, ~, ~, chMap] = iqtone(''sampleRate'', fs, ''numSamples'', %g, ...\n' ...
        '    ''tone'', tone, ''phase'', ' phase ', ''normalize'', %d, ...\n' ...
        '    ''magnitude'', magnitude, ''correction'', %d, ''channelMapping'', %s);\n\n' ...
        'iqdownload(iqdata, fs, ''channelMapping'', chMap, ''segmentNumber'', %d);\n'], points, normalize, correction, chanMapStr, segmentNum)];
    else
        [tone, mag] = calc_tones(handles, 0);
        [iqdata, ~, ~, ~, channelMapping] = iqtone('tone', tone, 'numSamples', points, ...
            'sampleRate', sampleRate, 'phase', phase, 'normalize', normalize, ...
            'magnitude', mag, 'correction', correction, 'channelMapping', channelMapping);
        assignin('base', 'iqdata', iqdata);
        set(handles.editPoints, 'String', sprintf('%d', length(iqdata)));
    end
end
% only consider those parts that are in channelMapping
scale = 1e-50;
chx = sum(channelMapping);
for i = 1:length(chx)/2
    if (chx(2*i-1))
        scale = max(scale, max(abs(real(iqdata(:,i)))));
    end
    if (chx(2*i))
        scale = max(scale, max(abs(imag(iqdata(:,i)))));
    end
end
scaledB = 20*log10(scale);
set(handles.editUsedRange, 'String', iqengprintf(scaledB, 3));
if (scale > 1)
    set(handles.editUsedRange, 'Background', 'yellow');
%    warndlg(sprintf('Amplitude exceeds max DAC range by %s dB.\nPlease reduce "Magnitude"', iqengprintf(scaledB, 3)));
else
    set(handles.editUsedRange, 'Background', 'white');
end


function [iqdata, freqPoints, magPoints, phasePoints, sampleRate] = calculateCQM(handles)
% calculate a complex IQ vector based on data in edit fields
% handles    structure with handles and user data (see GUIDATA)
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
autoSamples = get(handles.checkboxAutoSampleRate, 'Value');
points = evalin('base',get(handles.editPoints, 'String'));
phaseList = get(handles.popupmenuPhase, 'String');
phaseIdx = get(handles.popupmenuPhase, 'Value');
phase = phaseList{phaseIdx};
if (phaseIdx == 5)
    phase = evalin('base', ['[' get(handles.editPhase, 'String') ']']);
    phase = phase ./ 180 .* pi;
end
correction = get(handles.checkboxCorrection, 'Value');
if (autoSamples)
    points = 0;
end
[tone, mag] = calc_tones(handles, 0);
[iqdata, freqPoints, magPoints, phasePoints] = iqtone('tone', tone, 'numSamples', points, ...
    'sampleRate', sampleRate, 'phase', phase, ...
    'magnitude', mag, 'correction', correction);
assignin('base', 'iqdata', iqdata);
set(handles.editPoints, 'String', sprintf('%d', length(iqdata)));


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


% --------------------------------------------------------------------
function menuSaveWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[iqdata fs] = calculate(handles);
iqsavewaveform(iqdata, fs);


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
[arbConfig saConfig] = loadArbConfig();

% if there is no spectrum analyzer connected, select VSA by default
if (~isfield(saConfig, 'connected') || ~saConfig.connected)
    if (isfield(arbConfig, 'isPowerSensorConnected') && arbConfig.isPowerSensorConnected)
        % if a power sensor is connected but no spectrum analyzer, select the power sensor as the default method
        set(handles.popupmenuCalType, 'Value', 7);
    else
        % otherwise VSA
        set(handles.popupmenuCalType, 'Value', 5);
    end
end
% --- generic checks
if (arbConfig.maxSegmentNumber <= 1)
    set(handles.editSegment, 'Enable', 'off');
    set(handles.textSegment, 'Enable', 'off');
else
    set(handles.editSegment, 'Enable', 'on');
    set(handles.textSegment, 'Enable', 'on');
end
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
resetCal(handles);
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
% --- normalize
% [~, ~, acs] = iqcorrection([], 0);
% if (isfield(acs, 'absMagnitude') && acs.absMagnitude)
%     set(handles.checkboxNormalize, 'Value', 0);
%     checkboxNormalize_Callback([], [], handles);
% end



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


% --------------------------------------------------------------------
function menuVSA_Callback(hObject, eventdata, handles)
% hObject    handle to menuVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuM8131A_VSA_Callback(hObject, eventdata, handles)
% hObject    handle to menuM8131A_VSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[tone, ~] = calc_tones(handles);
% ask the user for the channelmapping
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
if (length(find(sum(channelMapping, 1))) >= 2)
    fc = 0;
    span = 2 * max(abs(min(tone)), abs(max(tone)));
    if (length(tone) == 1)
        span = evalin('base', get(handles.editSampleRate, 'String')) / 2;
        fc = span/2;
    end
else
    fc = (min(tone) + max(tone)) / 2;
    span = max(tone) - min(tone);
    if (span == 0)
        span = evalin('base', get(handles.editSampleRate, 'String')) / 2;
        fc = span/2;
    end
end
if (fc ~= 0)
    defaultScopeChannel = {'1'};
    if (isfield(handles, 'defaultScopeChannel') && iscell(handles.defaultScopeChannel) && length(handles.defaultScopeChannel) == 1)
        defaultScopeChannel = handles.defaultScopeChannel;
    end
    chan = inputdlg({'Signal connected to M8131A channel'}, 'M8131A channel connections', 1, defaultScopeChannel);
    if (isempty(chan))
        return;
    end
    % remember the current DCA channel mapping
    handles.defaultScopeChannel = chan;
    guidata(hObject, handles);
else
    defaultScopeChannel = {'1', '3'};
    if (isfield(handles, 'defaultScopeChannel') && iscell(handles.defaultScopeChannel) && length(handles.defaultScopeChannel) == 2)
        defaultScopeChannel = handles.defaultScopeChannel;
    end
    chan = inputdlg({'"I" is connected to M8131A channel', '"Q" is connected to M8131A channel'}, 'M8131A channel connections', 1, defaultScopeChannel);
    if (isempty(chan))
        return;
    end
    % remember the current scope channel mapping
    handles.defaultScopeChannel = chan;
    guidata(hObject, handles);
end
vsaApp = vsafunc([], 'open');
if (isempty(vsaApp))
    return;
end
vsafunc(vsaApp, 'stop');
% just to be sure: download the waveform
pushbuttonDownload_Callback(hObject, eventdata, handles);
% autoscale
maxAmpl = -2;
arbConfig = loadArbConfig();
% acquire the signal from the DCA
hMsgBox = msgbox('Acquiring data from M8131A. Please wait...', 'Please wait...');
maxDuration = 8.1920e-05;
duration = maxDuration;
[sig, fsScope] = iqreadM8131A(arbConfig, chan, [], duration, 0, maxAmpl);
try close(hMsgBox); catch ex; end
if (fc ~= 0)
    if (size(sig,2) ~= 1)
        errordlg('Waveform capture from M8131A failed. Expected one trace. Please check connections');
        return;
    end
    sigScope = complex(sig, zeros(size(sig)));
else
    if (size(sig,2) ~= 2)
        errordlg('Waveform capture from M8131A failed. Expected two traces. Please check connections');
        return;
    end
    sigScope = complex(sig(:,1),sig(:,2));
end
% make the result visible in the MATLAB workspace for further manual analysis
assignin('base', 'fsScope', fsScope);
assignin('base', 'sigScope', sigScope);
% configure VSA
handles.lastDownload = 'VSA';
guidata(hObject, handles);
vsaApp = vsafunc([], 'open');
if (~isempty(vsaApp))
    hMsgBox = msgbox('Configuring VSA software. Please wait...');
    vsafunc(vsaApp, 'preset');
    vsafunc(vsaApp, 'input', 1);
    vsafunc(vsaApp, 'load', sigScope, fsScope);
    vsafunc(vsaApp, 'freq', fc, span, 51201, 'flattop', 3);
    vsafunc(vsaApp, 'trace', 1, 'Tones');
    vsafunc(vsaApp, 'start', 1);
    vsafunc(vsaApp, 'autoscale');
    try
        close(hMsgBox);
    catch
    end
end



function editMagnitude_Callback(hObject, eventdata, handles)
% hObject    handle to editMagnitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMagnitude as text
%        str2double(get(hObject,'String')) returns contents of editMagnitude as a double


% --- Executes during object creation, after setting all properties.
function editMagnitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMagnitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


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
