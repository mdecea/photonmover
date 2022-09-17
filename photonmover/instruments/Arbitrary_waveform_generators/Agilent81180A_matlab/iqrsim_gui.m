function varargout = iqrsim_gui(varargin)
% IQRSIM_GUI MATLAB code for iqrsim_gui.fig
%      IQRSIM_GUI, by itself, creates a new IQRSIM_GUI or raises the existing
%      singleton*.
%
%      H = IQRSIM_GUI returns the handle to a new IQRSIM_GUI or the handle to
%      the existing singleton*.
%
%      IQRSIM_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQRSIM_GUI.M with the given input arguments.
%
%      IQRSIM_GUI('Property','Value',...) creates a new IQRSIM_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqrsim_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqrsim_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqrsim_gui

% Last Modified by GUIDE v2.5 06-Nov-2017 18:13:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqrsim_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqrsim_gui_OutputFcn, ...
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


% --- Executes just before iqrsim_gui is made visible.
function iqrsim_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqrsim_gui (see VARARGIN)

% Choose default command line output for iqrsim_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
axes(handles.axes1);
title('target path');
axes(handles.axes2);
title('distance to receiver');
axes(handles.axes3);
title('pulse envelope');
axes(handles.axes4);
title('pulse on time');

arbConfig = loadArbConfig();
if (isempty(find(strcmp(arbConfig.model, {'M8190A_12bit', 'M8190A_14bit', 'M8195A_1ch', 'M8195A_2ch', 'M8195A_2ch_mrk', 'M8195A_4ch'}), 1)))
    errordlg({'This utility currently only supports M8190A in 12 or 14 bit mode ' ...
        'or the M8195A in one of the deep memory modes (1ch/2ch/4ch).' ...
        'Please use the "Configure Instrument Connection" utility to select an' ...
        'appropriate instrument configuration.'});
    close(handles.iqtool);
    return;
end
if (isfield(arbConfig, 'do_rst') && arbConfig.do_rst)
    errordlg({'Please turn off the "send *RST" checkbox in the' ...
        'IQTools "Configuration" window, then restart this utility.'});
    close(handles.iqtool);
    return;
end
if (arbConfig.numChannels > 2)
    set(handles.pushbuttonRcvrMore, 'Enable', 'on')
end
if (strncmp(arbConfig.model, 'M8195A', 6))
    handles.editSampleRate.String = iqengprintf(arbConfig.defaultSampleRate);
end

% update the graphs
startSimulation(handles, -1);

% set the tooltips
if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editFMFormula, 'TooltipString', sprintf([ ...
    'Enter a MATLAB expression with "x" as an independent variable.\n' ...
    'The expression will be evaluated with x set to a row-vector with\n' ...
    'values in the range [0...1). The expression should return a row-vector\n' ...
    'with the same length as x and values between -1 and 1 to indicate\n' ...
    'a frequency deviation from -span/2 to span/2. In case of multiple\n' ...
    'pulses, the variable "i" will contain the pulse number starting from 1.\n' ...
    'Example: cos(pi*(x-1)) will generate a cosine shaped FM pulse. If you\n' ...
    'want no FM modulation at all, put a zero in this field.']));
set(handles.editPMFormula, 'TooltipString', sprintf([ ...
    'Enter a MATLAB expression with "x" as an independent variable.\n' ...
    'The expression will be evaluated with x set to a row-vector with\n' ...
    'values in the range [0...1). The expression should return a row-vector\n' ...
    'with the same length as x and values representing the phase in radians.\n' ...
    'In case of multiple pulses, the variable "i" will contain the pulse\n' ...
    'number starting from 1. Example: floor(x*4)/4*pi generates a pulse with\n' ...
    'four 45 degree phase steps within the pulse.  If you want no PM modulation\n' ...
    'enter zero in this field.']));
set(handles.popupmenuShape, 'TooltipString', sprintf([ ...
    'Select the shape of the rising and falling edge of the pulse.\n' ...
    '"trapezodial" results in a linear increase/decrease of amplitude.\n' ...
    'With "raised cosine", the amplitude follows a cosine wave, which\n' ...
    'reduces the occupied bandwidth. "Zero signal during rise time"\n' ...
    'can be used to delay the pulse by a certain amount of time relative\n', ...
    'to the beginning of the waveform segment']));
set(handles.popupmenuModulation, 'TooltipString', sprintf([ ...
    'Select the type of modulation on the pulse (or IMOP).\n' ...
    'Increasing, decreasing and V-shape modulations are linear FM chirps.\n' ...
    'Barker-11 and -13 generate barker codes of the given length.\n' ...
    '"User defined" allows you to specify a MATLAB formula to describe the\n' ...
    'frequency modulation on the pulse.']));
set(handles.checkboxCorrection, 'TooltipString', sprintf([ ...
    'Use this checkbox to pre-distort the signal using the previously established\n' ...
    'calibration values. Calibration can be performed using the multi-tone or\n' ...
    'digital modulation utilities.']));
set(handles.pushbuttonCorrection, 'TooltipString', sprintf([ ...
    'Use this button to visualize the frequency and phase response that has\n' ...
    'been captured using the "Calibrate" functionality in the multi-tone or\n' ...
    'digital modulation utility. In multi-tone, only magnitude corrections\n' ...
    'are captured whereas in digital modulation, both magnitude and phase\n' ...
    'response are calculated.']));
set(handles.editSpan, 'TooltipString', sprintf([ ...
    'Set the frequency span of the chirped signal.\n' ...
    'The frequency of the pulse will be in the range -span/2 to +span/2\n' ...
    'relative to the frequency offset. It is possible to specify a single\n' ...
    'or multiple frequency span values. In case of a list, multiple pulses\n' ...
    'will be generated; each with its own frequency span.']));
set(handles.editOffset, 'TooltipString', sprintf([ ...
    'Set the frequency offset to 0 to generate a baseband I/Q signal.\n' ...
    'Set it to a value greater than zero to perform digital upconversion\n' ...
    'to that center frequency. (Depending on the selection in "Download",\n' ...
    'the output signal will be available on channel 1 or 2 or both.\n' ...
    'It is possible to specify a single or multiple frequency offset values.\n' ...
    'In case of a list, multiple pulses will be generated; each with its own\n' ...
    'offset.']));
set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the simulated waveform using the\n' ...
    'MATLAB plots on the right. This function can be used without any hardware\n' ...
    'connected.']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Use this button to calculate and download the signal to the configured AWG.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
set(handles.checkboxMovingPhase, 'TooltipString', sprintf([ ...
    'This selection determines if the phase of the pulse changes with the delay\n' ...
    'or remains the same. The behaviour is best explained by running the simulation\n' ...
    'with and without this checkbox checked.']));
set(handles.editDoppler, 'TooltipString', sprintf([ ...
    'If set to zero, no doppler simulation will be done. Any value between\n' ...
    '0 and 1 will cause an "exaggerated" doppler effect to be simulated where\n' ...
    '1 means simulate a doppler shift up to the carrier frequency. A value\n' ...
    'of -1 will cause the nominal doppler shift to be simulated.']));
set(handles.popupmenuTargetSelection, 'TooltipString', sprintf([ ...
    'Use this popupmenu to select the path of the target. If you select "circle"\n' ...
    'the simulation will assume that the target moves on a circle that is defined\n' ...
    'by the first two entries in the table. If you select "user defined", the target\n' ...
    'will move along a path that is interpolated between the points given in the table']));
set(handles.checkboxExtUpconversion, 'TooltipString', sprintf([ ...
    'Check this checkbox if you are up-converting the AWG output signal using an\n' ...
    'external mixer. In this case, specify the external LO frequency in the field\n' ...
    'below.']));
set(handles.editExtLO, 'TooltipString', sprintf([ ...
    'Enter the frequency of an external LO that is used to up-convert the AWG\n' ...
    'output signal. The phases of the pulses need to be calculated accordingly.']));
set(handles.checkboxExtMovingPhase, 'TooltipString', sprintf([ ...
    'The checkbox is similar to the "Moving Phase" checkbox and determines if the\n' ...
    'phase of the pulse moves with the delay in case of external up-conversion']));
set(handles.editAmplitudeRatio, 'TooltipString', sprintf([ ...
    'Specify by how many dB the amplitude of the pulse will varied between the\n' ...
    'target being farthest and closest to the receive antenna. A value of zero\n' ...
    'causes no amplitude varied at all']));
set(handles.editNumSteps, 'TooltipString', sprintf([ ...
    'Specify into how many steps the simulation will be divided into.\n' ...
    'A smaller number will reduce calculation time, larger values will\n' ...
    'generate "smoother" changes, but simulation time will increase.\n' ...
    'A good compromise is typically between 100 and 5000 steps.']));
set(handles.editTT, 'TooltipString', sprintf([ ...
    'Specify the transition time (i.e. rise and fall time)\n' ...
    'of the pulse in seconds, e.g. 50e-9 for 50 nanoseconds)']));
set(handles.editPRI, 'TooltipString', sprintf([ ...
    'Specify the pulse repetition interval in seconds (e.g. 100e-6 for 100 microseconds)']));
set(handles.editPW, 'TooltipString', sprintf([ ...
    'Specify the pulse width in seconds (e.g. 20e-6 for 20 microseconds)']));
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'Enter the AWG sample rate in Hertz. For simulation, the sample rate\n' ...
    'can have any value, but if you want to download to the AWG, you have\n' ...
    'to stay within the range that is supported by the AWG.']));
end

% UIWAIT makes iqrsim_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqrsim_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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



function editPRI_Callback(hObject, eventdata, handles)
% hObject    handle to editPRI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editPRI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPRI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPW_Callback(hObject, eventdata, handles)
% hObject    handle to editPW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editPW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editTT_Callback(hObject, eventdata, handles)
% hObject    handle to editTT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editTT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuShape.
function popupmenuShape_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuShape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function popupmenuShape_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuShape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuModulation.
function popupmenuModulation_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuModulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = cellstr(get(hObject,'String'));
modType = contents{get(hObject,'Value')};
if (strcmp(modType, 'User defined'))
    set(handles.textPMFormula, 'Enable', 'on');
    set(handles.editPMFormula, 'Enable', 'on');
    set(handles.textFMFormula, 'Enable', 'on');
    set(handles.editFMFormula, 'Enable', 'on');
else
    set(handles.textPMFormula, 'Enable', 'off');
    set(handles.editPMFormula, 'Enable', 'off');
    set(handles.textFMFormula, 'Enable', 'off');
    set(handles.editFMFormula, 'Enable', 'off');
end
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function popupmenuModulation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuModulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPMFormula_Callback(hObject, eventdata, handles)
% hObject    handle to editPMFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editPMFormula_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPMFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmplitudeRatio_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplitudeRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editAmplitudeRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplitudeRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSpan_Callback(hObject, eventdata, handles)
% hObject    handle to editSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editSpan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editOffset_Callback(hObject, eventdata, handles)
% hObject    handle to editOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editOffset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOffset (see GCBO)
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
startSimulation(handles, -1);


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, 0);


function startSimulation(handles, download)
set(handles.textHelper1, 'Visible', 'off');
numSteps = evalin('base', ['[' get(handles.editNumSteps, 'String') ']']);
amplRatio = evalin('base', ['[' get(handles.editAmplitudeRatio, 'String') ']']);
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
pri = evalin('base', ['[' get(handles.editPRI, 'String') ']']);
pw = evalin('base', ['[' get(handles.editPW, 'String') ']']);
tt = evalin('base', ['[' get(handles.editTT, 'String') ']']);
shapeList = get(handles.popupmenuShape, 'String');
shapeIdx = get(handles.popupmenuShape, 'Value');
FMFormula = get(handles.editFMFormula, 'String');
PMFormula = get(handles.editPMFormula, 'String');
span_f = evalin('base', ['[' get(handles.editSpan, 'String') ']']);
offset_f = evalin('base', ['[' get(handles.editOffset, 'String') ']']);
modulationList = get(handles.popupmenuModulation, 'String');
modulationIdx = get(handles.popupmenuModulation, 'Value');
correction = get(handles.checkboxCorrection, 'Value');
movingPhase = get(handles.checkboxMovingPhase, 'Value');
extMovingPhase = get(handles.checkboxExtMovingPhase, 'Value');
extUp = get(handles.checkboxExtUpconversion, 'Value');
extLO = evalin('base', ['[' get(handles.editExtLO, 'String') ']']);
targetList = get(handles.popupmenuTargetSelection, 'String');
targetIdx = get(handles.popupmenuTargetSelection, 'Value');
targetPos = get(handles.uitableTargetPos, 'Data');
radarPos = get(handles.uitableRcvrPos, 'Data');
doppler = evalin('base', ['[' get(handles.editDoppler, 'String') ']']);
triggerMode = get(handles.popupmenuTrigger, 'Value');
siggen = get(handles.popupmenuSigGen, 'Value');
if (~extUp)
    extLO = 0;
    extMovingPhase = 0;
end

try
iqrsim('axes', [handles.axes1 handles.axes2 handles.axes3 handles.axes4], ...
    'msgbox', download, 'download', download, 'numSteps', numSteps, ...
    'PRI', pri, 'PW', pw, 'tt', tt, ...
    'pulseShape', shapeList{shapeIdx}, 'span', span_f, 'offset', offset_f, ...
    'amplRatio', amplRatio, 'fmFormula', FMFormula, 'pmFormula', PMFormula, ...
    'modulationType', modulationList{modulationIdx}, 'sampleRate', sampleRate, ...
    'movingPhase', movingPhase, 'extMovingPhase', extMovingPhase, 'extLO', extLO, ...
    'correction', correction, 'targetSelection', targetList{targetIdx}, ...
    'targetPos', targetPos, 'radarPos', radarPos, 'dopplerex', doppler, ...
    'triggerMode', triggerMode, 'sigGen', siggen);
catch ex
    [path name ext] = fileparts(ex.stack(1).file);
    errordlg(['Unexpected error in ' name ext ...
        ', line ' num2str(ex.stack(1).line) ': ' ex.message]);
end

% --- Executes on selection change in popupmenuTargetSelection.
function popupmenuTargetSelection_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTargetSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function popupmenuTargetSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTargetSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonCorrection.
function pushbuttonCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);



function editNumSteps_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSteps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editNumSteps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSteps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFMFormula_Callback(hObject, eventdata, handles)
% hObject    handle to editFMFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editFMFormula_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFMFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editExtLO_Callback(hObject, eventdata, handles)
% hObject    handle to editExtLO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editExtLO_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editExtLO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxMovingPhase.
function checkboxMovingPhase_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxMovingPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes on button press in checkboxExtMovingPhase.
function checkboxExtMovingPhase_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxExtMovingPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes on button press in checkboxExtUpconversion.
function checkboxExtUpconversion_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxExtUpconversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxExtUpconversion
extup = get(hObject,'Value') + 1;
onoff = { 'off' 'on' };
set(handles.textExtLO, 'Enable', onoff{extup});
set(handles.editExtLO, 'Enable', onoff{extup});
set(handles.textExtMovingPhase, 'Enable', onoff{extup});
set(handles.checkboxExtMovingPhase, 'Enable', onoff{extup});
startSimulation(handles, -1);


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (iqoptcheck([], [], 'SEQ'))
    startSimulation(handles, 1);
end


% --- Executes on button press in pushbuttonVSA.
function pushbuttonVSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function editDoppler_Callback(hObject, eventdata, handles)
% hObject    handle to editDoppler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function editDoppler_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDoppler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonRcvrMore.
function pushbuttonRcvrMore_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRcvrMore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableRcvrPos, 'Data');
data(end+1,:) = -1 * data(end,:);
data(end,1) = size(data,1) - 1;
set(handles.uitableRcvrPos, 'Data', data);
arbConfig = loadArbConfig();
siggen = get(handles.popupmenuSigGen, 'Value');
if (size(data,1) >= floor(arbConfig.numChannels / siggen))
    set(handles.pushbuttonRcvrLess, 'Enable', 'on');
    set(handles.pushbuttonRcvrMore, 'Enable', 'off');
end
startSimulation(handles, -1);


% --- Executes on button press in pushbuttonRcvrLess.
function pushbuttonRcvrLess_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRcvrLess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableRcvrPos, 'Data');
data(end,:) = [];
set(handles.uitableRcvrPos, 'Data', data);
if (size(data,1) <= 1)
    set(handles.pushbuttonRcvrLess, 'Enable', 'off');
    set(handles.pushbuttonRcvrMore, 'Enable', 'on');
end
startSimulation(handles, -1);


% --- Executes on button press in pushbuttonTargetMore.
function pushbuttonTargetMore_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTargetMore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableTargetPos, 'Data');
data(end+1,:) = data(end,:);
data(end,:) = data(end,:) + 1;  % use different values to avoid errors
set(handles.uitableTargetPos, 'Data', data);
if (size(data,1) > 2)
    set(handles.pushbuttonTargetLess, 'Enable', 'on');
end
startSimulation(handles, -1);


% --- Executes on button press in pushbuttonTargetLess.
function pushbuttonTargetLess_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTargetLess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableTargetPos, 'Data');
data(end,:) = [];
set(handles.uitableTargetPos, 'Data', data);
if (size(data,1) <= 2)
    set(handles.pushbuttonTargetLess, 'Enable', 'off');
end
startSimulation(handles, -1);


% --- Executes when entered data in editable cell(s) in uitableTargetPos.
function uitableTargetPos_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableTargetPos (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes on selection change in popupmenuTrigger.
function popupmenuTrigger_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);


% --- Executes during object creation, after setting all properties.
function popupmenuTrigger_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuSigGen.
function popupmenuSigGen_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSigGen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSigGen contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSigGen
data = get(handles.uitableRcvrPos, 'Data');
len = size(data,1);
arbConfig = loadArbConfig();
siggen = get(handles.popupmenuSigGen, 'Value');
maxlen = floor(arbConfig.numChannels / siggen);
if (len > maxlen)
    if (maxlen > 1)
        set(handles.pushbuttonRcvrLess, 'Enable', 'on');
    else
        set(handles.pushbuttonRcvrLess, 'Enable', 'off');
    end
    for i = len:-1:maxlen+1
        data(i,:) = [];
    end
    set(handles.uitableRcvrPos, 'Data', data);
end
if (maxlen > len)
    set(handles.pushbuttonRcvrMore, 'Enable', 'on');
else
    set(handles.pushbuttonRcvrMore, 'Enable', 'off');
end
startSimulation(handles, -1);



% --- Executes during object creation, after setting all properties.
function popupmenuSigGen_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSigGen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
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


% --- Executes when entered data in editable cell(s) in uitableRcvrPos.
function uitableRcvrPos_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableRcvrPos (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
startSimulation(handles, -1);

