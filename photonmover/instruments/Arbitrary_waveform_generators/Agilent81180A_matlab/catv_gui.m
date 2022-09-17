function varargout = catv_gui(varargin)
% CATV_GUI MATLAB code for catv_gui.fig
%      CATV_GUI, by itself, creates a new CATV_GUI or raises the existing
%      singleton*.
%
%      H = CATV_GUI returns the handle to a new CATV_GUI or the handle to
%      the existing singleton*.
%
%      CATV_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CATV_GUI.M with the given input arguments.
%
%      CATV_GUI('Property','Value',...) creates a new CATV_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before catv_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to catv_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help catv_gui

% Last Modified by GUIDE v2.5 05-Aug-2015 20:57:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @catv_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @catv_gui_OutputFcn, ...
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


% --- Executes just before catv_gui is made visible.
function catv_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to catv_gui (see VARARGIN)

% Choose default command line output for catv_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
menuPresetNTSC_Callback([], [], handles);
arbConfig = loadArbConfig();
if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.checkboxAutoSampleRate, 'TooltipString', sprintf([ ...
    'Use this checkbox to automatically select the sample rate of the M8190A.\n' ...
    'The sample rate will be selected to be an integer multiple of the symbol\n' ...
    'rate for digital modulations.']));
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'Enter the AWG sample rate in Hertz. For simulation, the sample rate\n' ...
    'can have any value, but if you want to download to the AWG, you have\n' ...
    'to stay within the range that is supported by the AWG.']));
set(handles.editAmplitudeScale, 'TooltipString', sprintf([ ...
    'Amplitude scaling value. This should be set to a fixed value if multiple\n' ...
    'waveform segments must be generated and power must be kept constant']));
set(handles.checkboxAmplitudeAuto, 'TooltipString', sprintf([ ...
    'When this checkbox is checked, the waveform will be scaled to use the\n' ...
    'full AWG dynamic range. When unchecked, scaling can be set manually\n' ...
    'This is useful to generate multiple waveform segments with the same power level.']));
set(handles.uitable1, 'TooltipString', sprintf([ ...
    'The columns in the table are used as follows:\n' ...
    '- Enable - if checked, the corresponding carrier (or list of carriers) will be generated\n' ...
    '- Frequency - Carrier frequency in MHz. Can be a single number or a list of frequencies\n' ...
    '              separated by spaces or a range of frequencies, e.g. 91.25:6:115.25\n' ...
    '- Modulation - the modulation scheme on this carrier. If set to "Noise", gaussian noise will be generated\n' ...
    '- Bandwidth - Symbol rate for modulated carriers, bandwidth for noise, ignored for CW carriers\n' ...
    '- Power - relative power in dB\n' ...
    '- AWG Ch. - AWG channel(s) on which the signal will be generated']));
set(handles.editNumSymbols, 'TooltipString', sprintf([ ...
    'The utility will generate the given number of random symbols.\n' ...
    'A larger number will give a more realistic spectral shape but\n' ...
    'will also increase computation time. It is recommended to\n' ...
    'start with a small number of symbols (e.g. 120) to limit computation time.\n' ...
    'Then gradually increase the number. Computation time can be reduced\n' ...
    'sampleRate / symbolRate is a multiple of the AWG''s segment granularity.']));
set(handles.popupmenuFilterType, 'TooltipString', sprintf([ ...
    'Select the pulse shaping filter that will be applied to the modulated\n' ...
    'baseband signal. Root raised cosine is the default and should normally\n' ...
    'be used except for experimental purposes.']));
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
set(handles.pushbuttonExpand, 'TooltipString', sprintf([ ...
    'Expand the table so that each row will contain exactly one carrier frequency.\n' ...
    'This is useful e.g. to enable/disable individual carriers.']));
set(handles.pushbuttonCollapse, 'TooltipString', sprintf([ ...
    'Collapse the table. Multiple carriers with equidistant spacing but otherwise\n' ...
    'identical parameters will be combined into a single row.\n' ...
    'This is useful to get a better overview.']));
set(handles.pushbuttonInsert, 'TooltipString', sprintf([ ...
    'Insert one row at the selected position in the table.']));
set(handles.pushbuttonDelete, 'TooltipString', sprintf([ ...
    'Delete one row at the selected position in the table.']));
set(handles.editTilt, 'TooltipString', sprintf([ ...
    'Enter the value in dB by which the highest carrier is amplified vs. the lowest\n' ...
    'carrier.  All the carriers in between will be attenuated proportional to their\n' ...
    'frequency']));
set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the simulated waveform using MATLAB plots.\n' ...
    'The signal will be displayed both in the time- as well as frequency\n' ...
    'domain (spectrum). This function can be used even without any hardware\n' ...
    'connected.']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Use this button to calculate and download the signal to the configured AWG.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
end
arbConfig = loadArbConfig();
if (~exist('arbConfig', 'var') || isempty(arbConfig))
    errordlg({'No instrument connection configured. ' ...
        'Please use the "Configuration" utility to' ...
        'configure the instrument connection'});
    close(handles.iqtool);
    return;
end
if (~strcmp(arbConfig.model, 'M8190A_12bit') && ~strcmp(arbConfig.model, 'M8190A_14bit'))
    errordlg({'Invalid AWG model selected. ' ...
        'Please use the "Configuration" utility and' ...
        'select M8190A_14bit or M8190A_12bit mode'});
    close(handles.iqtool);
    return;
end

% UIWAIT makes catv_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = catv_gui_OutputFcn(hObject, eventdata, handles) 
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
checkfields([], [], handles);


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


% --- Executes on button press in checkboxAutoSampleRate.
function checkboxAutoSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
autoSampleRate = get(hObject,'Value');
if (autoSampleRate)
    set(handles.editSampleRate, 'Enable', 'off');
else
    set(handles.editSampleRate, 'Enable', 'on');
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



function editTilt_Callback(hObject, eventdata, handles)
% hObject    handle to editTilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isscalar(value) && value >= -100 && value <= 100)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editTilt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTilt (see GCBO)
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
try
    [data, sampleRate] = calc_signal(handles);
    plotFct(handles.axesCh1, real(data), sampleRate, 1);
    plotFct(handles.axesCh2, imag(data), sampleRate, 2);
    performScaling(data, handles);
    set(handles.textPlaceHolder1, 'Visible', 'off');
    set(handles.textPlaceHolder2, 'Visible', 'off');
catch ex
    errordlg(ex.message);
end


function plotFct(ax, data, sampleRate, ch)
data = awgn(data, 300);
len = length(data);
faxis = linspace(sampleRate / -2, sampleRate / 2 - sampleRate / len, len);
magnitude = 20 * log10(abs(fftshift(fft(data/len))));
axes(ax);
plot(ax, faxis, magnitude, '.-');
xlabel('Frequency (Hz)');
ylabel(sprintf('dB (Ch%d)', ch));
xlim([0 1.1e9]);
ylim([-40 10]);
grid;


function [data, sampleRate] = calc_signal(handles)
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
autoSamples = get(handles.checkboxAutoSampleRate, 'Value');
freqTable = getTable(handles);
tilt = evalin('base',get(handles.editTilt, 'String'));
numSymbols = evalin('base',get(handles.editNumSymbols, 'String'));
filterList = get(handles.popupmenuFilterType, 'String');
filterIdx = get(handles.popupmenuFilterType, 'Value');
filterNsym = evalin('base',get(handles.editFilterNSym, 'String'));
filterBeta = evalin('base',get(handles.editFilterBeta, 'String'));
correction = get(handles.checkboxCorrection, 'Value');
sameData = get(handles.checkboxSameData, 'Value');
if (autoSamples)
    sampleRate = 0;
end
for i = 1:length(freqTable)
    freqTable(i).frequency = 1e6 * evalin('base', ['[' freqTable(i).frequency ']']);
    freqTable(i).bandwidth = 1e6 * evalin('base', ['[' freqTable(i).bandwidth ']']);
    freqTable(i).power = evalin('base', ['[' freqTable(i).power ']']);
end
hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...', 'replace');
[data, sampleRate] = catv('freqTable', freqTable, 'sampleRate', sampleRate, ...
    'tilt', tilt, 'numSymbols', numSymbols, ...
    'filterType', filterList{filterIdx}, ...
    'filterNsym', filterNsym, 'filterBeta', filterBeta, ...
    'correction', correction, 'sameData', sameData, 'hMsgBox', hMsgBox);
try close(hMsgBox); catch; end
assignin('base', 'iqdata', data);
set(handles.editSampleRate, 'String', iqengprintf(sampleRate));
set(handles.editNumSamples, 'String', num2str(length(data)));
set(handles.editPlaytime, 'String', iqengprintf(length(data)/sampleRate*1000));



function result = getTable(handles)
% get the contents of the frequency table
data = get(handles.uitable1, 'Data');
if (~isempty(data))
    result = cell2struct(get(handles.uitable1, 'Data'), ...
        {'number', 'enable', 'frequency', 'modulation', 'bandwidth', 'power', 'channel'}, 2);
else
    result = [];
end


function setTable(handles, table)
% set the contents of the frequency table
if (~isempty(table))
    if (size(table,2) > 1)
        table = table';
    end
    set(handles.uitable1, 'Data', struct2cell(table)');
else
    set(handles.uitable1, 'Data', []);
end


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (iqoptcheck([], 'bit', []))
    [data, sampleRate] = calc_signal(handles);
%    plotFct(handles.axesCh1, real(data), sampleRate, 1);
%    plotFct(handles.axesCh2, imag(data), sampleRate, 2);
%    set(handles.textPlaceHolder1, 'Visible', 'off');
%    set(handles.textPlaceHolder2, 'Visible', 'off');
    segment = evalin('base', get(handles.editSegment, 'String'));
    data = performScaling(data, handles);
    hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
    try
        if (isfield(handles, 'maxSegment') || segment > 1)
            iqdownload(data, sampleRate, 'segmentNumber', segment, 'run', 0);
            clear seq
            for i = 1:segment
                seq(i).segmentNumber = i;
                seq(i).segmentLoops = 1;
                seq(i).markerEnable = true;
                seq(i).segmentAdvance = 'Auto';
            end
            iqseq('define', seq, 'keepOpen', 1, 'run', 0);
            iqseq('dynamic', 1);
            iqseq('mode', 'arb');
            f = iqopen();
            fprintf(f, sprintf(':stab:dyn:sel %d', segment - 1));
            fprintf(f, ':init:imm');
            if (~isfield(handles, 'maxSegment') || segment > handles.maxSegment)
                handles.maxSegment = segment;
                guidata(hObject, handles);
                str = cell(1,segment);
                for i = 1:segment
                    str{i} = num2str(i);
                end
                set(handles.popupmenuPlaySegment, 'String', str);
                set(handles.popupmenuPlaySegment, 'Enable', 'on');
            end
            set(handles.popupmenuPlaySegment, 'Value', segment);
        else
            iqseq('dynamic', 0);
            iqdownload(data, sampleRate, 'segmentNumber', segment);
        end
    catch ex;
        errordlg(ex.message);
    end
    try close(hMsgBox); catch ex; end
end


function data = performScaling(data, handles)
scale = max(max(abs(real(data))), max(abs(imag(data))));
if (get(handles.checkboxAmplitudeAuto, 'Value'))
    set(handles.editAmplitudeScale, 'String', iqengprintf(scale, 4));
else
    scaleManual = evalin('base', get(handles.editAmplitudeScale, 'String'));
    if (scaleManual < scale)
        warndlg(sprintf('If scale value is less than %s, clipping will occur', iqengprintf(scale, 4)));
    end
    scale = scaleManual;
end
data = data ./ scale;


function editNumSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isscalar(value) && value >= 1 && value <= 2e9)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNumSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumSymbols_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSymbols (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isscalar(value) && value >= 1 && value <= 1024*1024)
    arbConfig = loadArbConfig();
    value = ceil(value / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
    set(hObject, 'String', sprintf('%d', value));
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNumSymbols_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSymbols (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuFilterType.
function popupmenuFilterType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuFilterType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuFilterType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuFilterType


% --- Executes during object creation, after setting all properties.
function popupmenuFilterType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuFilterType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFilterNSym_Callback(hObject, eventdata, handles)
% hObject    handle to editFilterNSym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isscalar(value) && value >= 1 && value <= 512*1024)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editFilterNSym_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilterNSym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFilterBeta_Callback(hObject, eventdata, handles)
% hObject    handle to editFilterBeta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isscalar(value) && value >= 0 && value <= 1000)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editFilterBeta_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilterBeta (see GCBO)
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
function menuPreset_Callback(hObject, eventdata, handles)
% hObject    handle to menuPreset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuPresetNTSC_Callback(hObject, eventdata, handles)
% hObject    handle to menuPresetNTSC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
data = [{ '.', true, '91.25 : 6 : 115.25', 'CW', '5', '0', 'Ch.1+2'};
        { '.', true, '151.25 : 6 : 169.25', 'CW', '5', '0', 'Ch.1+2'};
        { '.', true, '217.25 : 6 : 541.25', 'CW', '5', '0', 'Ch.1+2'};
        { '.', true, '547.25 : 6 : 997.25', 'QAM256', '5', '-6', 'Ch.1+2'}];
set(handles.uitable1, 'Data', data);
setTable(handles, checkFreqTable(handles, getTable(handles)));
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editNumSymbols, 'String', '960');
set(handles.popupmenuFilterType, 'Value', 1);
set(handles.editFilterNSym, 'String', '60');
set(handles.editFilterBeta, 'String', '0.2');
set(handles.checkboxCorrection, 'Value', 0);


% --------------------------------------------------------------------
function preset_germany_Callback(hObject, eventdata, handles)
% hObject    handle to preset_germany (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
data = [{ '.', true, '140.25 : 7 : 294.25', 'CW', '5', '0', 'Ch.1+2'};
        { '.', true, '303.25 : 8 : 319.25', 'CW', '5', '0', 'Ch.1+2'};
        { '.', true, '327.25 : 8 : 463.25', 'QAM256', '5', '-6', 'Ch.1+2'};
        { '.', true, '471.25 : 8 : 511.25', 'CW', '5', '0', 'Ch.1+2'};
        { '.', true, '519.25 : 8 : 999.25', 'QAM256', '5', '-6', 'Ch.1+2'}];
set(handles.uitable1, 'Data', data);
setTable(handles, checkFreqTable(handles, getTable(handles)));
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editNumSymbols, 'String', '960');
set(handles.popupmenuFilterType, 'Value', 1);
set(handles.editFilterNSym, 'String', '60');
set(handles.editFilterBeta, 'String', '0.2');
set(handles.checkboxCorrection, 'Value', 0);


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
[Y fs] = calc_signal(handles);
iqsavewaveform(Y, fs);


% --- Executes on button press in pushbuttonVSA.
function pushbuttonVSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
carrierNum = evalin('base',get(handles.editVSACarrierNum, 'String'));
freqTable = getTable(handles);
found = 0;
for i = 1:length(freqTable)
    freq = 1e6 * evalin('base', ['[' freqTable(i).frequency ']']);
    symbolRate = 1e6 * evalin('base', ['[' freqTable(i).bandwidth ']']);
    modulation = freqTable(i).modulation;
    if (carrierNum >= 1 && carrierNum <= length(freq))
        found = 1;
        break;
    end
    carrierNum = carrierNum - length(freq);
end
if (found)
    filterList = get(handles.popupmenuFilterType, 'String');
    filterIdx = get(handles.popupmenuFilterType, 'Value');
    filterBeta = evalin('base',get(handles.editFilterBeta, 'String'));
    resultLength = evalin('base',get(handles.editVSAResultLength, 'String'));
    fc = freq(carrierNum);
    filterLength = 99;
    convergence = 1e-8;
    vsaApp = vsafunc([], 'open');
    if (~isempty(vsaApp))
        hMsgBox = msgbox('Configuring VSA software. Please wait...');
        vsafunc(vsaApp, 'preset');
        vsafunc(vsaApp, 'fromHW');
        vsafunc(vsaApp, 'input', fc);
        vsafunc(vsaApp, 'DigDemod', modulation, symbolRate, filterList{filterIdx}, filterBeta, resultLength);
        vsafunc(vsaApp, 'equalizer', false, filterLength, convergence);
        vsafunc(vsaApp, 'freq', fc, symbolRate * 1.6, 51201, 'flattop', 3);
        vsafunc(vsaApp, 'trace', 4, 'DigDemod');
        vsafunc(vsaApp, 'start', 1);
        vsafunc(vsaApp, 'autoscale');
        try
            close(hMsgBox);
        catch
        end
    end
else
    errordlg('carrier number not found');
end



function editVSAResultLength_Callback(hObject, eventdata, handles)
% hObject    handle to editVSAResultLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isscalar(value) && value >= 1 && value <= 512*1024)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editVSAResultLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVSAResultLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editVSACarrierNum_Callback(hObject, eventdata, handles)
% hObject    handle to editVSACarrierNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVSACarrierNum as text
%        str2double(get(hObject,'String')) returns contents of editVSACarrierNum as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isscalar(value) && value >= 1 && value <= 10000)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editVSACarrierNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVSACarrierNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSameData.
function checkboxSameData_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSameData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSameData


% --- Executes on button press in pushbuttonInsert.
function pushbuttonInsert_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
insertRow(handles, {'', true, '500', 'CW', '5', '0', 'Ch. 1'});


function data = insertRow(handles, default)
global currentTableSelection;
data = get(handles.uitable1, 'Data');
if (exist('currentTableSelection', 'var') && length(currentTableSelection) >= 2)
    row1 = currentTableSelection(1);
else
    row1 = 1;
end
row2 = size(data,1);
if (row1 > row2)
    row1 = row2;
end
set(handles.textEmpty, 'Visible', 'off');
% it seems that an assignment like this is not possible
% data{row1+1:row2+1,:} = data{row1:row2,:}
if (row2 < 1)    % empty
    for j=1:size(default,2)
        data{1,j} = default{j};
    end
else
    for i=row2:-1:row1
        for j=1:size(data,2)
            data{i+1,j} = data{i,j};
        end
    end
    if (~isempty(default))
        for j=1:size(default,2)
            data{row1,j} = default{j};
        end
    end
end
set(handles.uitable1, 'Data', data);


function deleteRow(handles, minimum)
global currentTableSelection;
data = getTable(handles);
if (exist('currentTableSelection', 'var') && length(currentTableSelection) >= 2)
    row1 = currentTableSelection(1);
else
    row1 = 1;
end
row2 = size(data,1);
newdata = data;
if (row2 <= minimum)
    return;
end
if (row2 == 1)
    set(handles.textEmpty, 'Visible', 'on');
end
% shift the rows up by one
if (row1 < row2)
    data(row1:row2-1) = data(row1+1:row2);
end
% delete last row
data(row2) = [];
setTable(handles, data);


% --- Executes on button press in pushbuttonDelete.
function pushbuttonDelete_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteRow(handles, 0);


% --- Executes on button press in pushbuttonExpand.
function pushbuttonExpand_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonExpand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
freqTable = getTable(handles);
freqTable = expandFreqTable(handles, freqTable);
freqTable = checkFreqTable(handles, freqTable);
setTable(handles, freqTable);


function freqTable = expandFreqTable(handles, freqTable)
len = size(freqTable, 1);
pos = len;
for i = 1:len
    fx = freqTable(i);
    freq = evalin('base', ['[' fx.frequency ']']);
    if (length(freq) > 1)
        freqTable(i).frequency = iqengprintf(freq(1));
        for j = 2:length(freq)
            pos = pos + 1;
            fp = fx;
            fp.frequency = iqengprintf(freq(j));
            freqTable(pos) = fp;
        end
    end
end
freqTable = sortFreqTable(freqTable);



function freqTable = sortFreqTable(freqTable)
for i = 1:size(freqTable, 1)
    for j = i+1:size(freqTable, 1)
        if (str2double(freqTable(i).frequency) > str2double(freqTable(j).frequency))
            tmp = freqTable(i);
            freqTable(i) = freqTable(j);
            freqTable(j) = tmp;
        end
    end
end


% --- Executes on button press in pushbuttonCollapse.
function pushbuttonCollapse_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCollapse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
freqTable = getTable(handles);
freqTable = expandFreqTable(handles, freqTable);
i = 1;
len = size(freqTable, 1);
while (i <= len)
    fx = freqTable(i);
    for j = i+1:len+1
        if (j > len)
            break;
        end
        fy = freqTable(j);
        if (fx.enable ~= fy.enable || ~strcmp(fx.modulation, fy.modulation) || ...
                str2double(fx.bandwidth) ~= str2double(fy.bandwidth) || ...
                str2double(fx.power) ~= str2double(fy.power) || ...
                ~strcmp(fx.channel, fy.channel))
            break;
        end
        if (j == i+1)
            delta = str2double(fy.frequency) - str2double(fx.frequency);
        elseif (str2double(fy.frequency) - lastFreq ~= delta)
            break;
        end
        lastFreq = str2double(fy.frequency);
    end
    if (j > i+1)
        freqTable(i).frequency = sprintf('%s : %s : %s', iqengprintf(str2double(fx.frequency)), iqengprintf(delta), iqengprintf(lastFreq));
        % move elements forward
        freqTable(i+1:(i+1+len-j)) = freqTable(j:len);
        % delete last (j-i-1) rows
        freqTable(len-(j-i-1)+1:len) = [];
        len = len - (j-i-1);
    end
    i = i + 1;
end
setTable(handles, checkFreqTable(handles, freqTable));



% --- Executes when selected cell(s) is changed in uitable1.
function uitable1_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitable1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelection;
if (~isempty(eventdata.Indices))
    currentTableSelection = eventdata.Indices;
end


% --- Executes when entered data in editable cell(s) in uitable1.
function uitable1_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitable1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
freqTable = checkFreqTable(handles, getTable(handles));
setTable(handles, freqTable);


function freqTable = checkFreqTable(handles, freqTable)
% check the consistency of the frequency table
num = 1;
for i = 1:length(freqTable)
    try
        freq = evalin('base', ['[' freqTable(i).frequency ']']);
        len = length(freq);
        if (len > 1)
            freqTable(i).number = sprintf('%d - %d', num, num + len - 1);
        else
            freqTable(i).number = sprintf('%d', num);
        end
        num = num + len;
    catch ex
        errordlg(sprintf('invalid frequency in line %d: %s', i, ex.message));
    end
    try
        bw = evalin('base', ['[' freqTable(i).bandwidth ']']);
    catch ex
        errordlg(sprintf('invalid bandwidth in line %d: %s', i, ex.message));
    end
    try
        pwr = evalin('base', ['[' freqTable(i).power ']']);
    catch ex
        errordlg(sprintf('invalid power in line %d: %s', i, ex.message));
    end
    if (strcmp(freqTable(i).modulation, 'CW'))
        freqTable(i).bandwidth = '';
    else
        if (strcmp(freqTable(i).bandwidth, ''))
            freqTable(i).bandwidth = sprintf('%d', 5);
        end
    end
end


function result = checkfields(hObject, eventdata, handles)
result = 0;
value = [];
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    msgbox(ex.message);
end
arbConfig = loadArbConfig();
if (~isempty(value) && isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
    set(handles.editSampleRate,'BackgroundColor','white');
else
    set(handles.editSampleRate,'BackgroundColor','red');
end



function editSegment_Callback(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isscalar(value) && value >= 1 && value <= 512*1024)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end



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


% --- Executes on button press in checkboxAmplitudeAuto.
function checkboxAmplitudeAuto_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAmplitudeAuto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject, 'Value');
if (val)
    set(handles.editAmplitudeScale, 'Enable', 'off');
else
    set(handles.editAmplitudeScale, 'Enable', 'on');
end

% --- Executes on selection change in popupmenuPlaySegment.
function popupmenuPlaySegment_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuPlaySegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject, 'Value');
try
    f = iqopen();
    fprintf(f, sprintf(':stab:dyn:sel %d', val - 1));
    fclose(f);
catch ex
    errordlg(ex.message);
end


% --- Executes during object creation, after setting all properties.
function popupmenuPlaySegment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuPlaySegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmplitudeScale_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplitudeScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isscalar(value) && value > 0 && value <= 1e9)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editAmplitudeScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplitudeScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPlaytime_Callback(hObject, eventdata, handles)
% hObject    handle to editPlaytime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPlaytime as text
%        str2double(get(hObject,'String')) returns contents of editPlaytime as a double


% --- Executes during object creation, after setting all properties.
function editPlaytime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPlaytime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
