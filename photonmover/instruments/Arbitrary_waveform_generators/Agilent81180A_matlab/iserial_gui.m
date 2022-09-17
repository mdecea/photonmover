function varargout = iserial_gui(varargin)
% ISERIAL_GUI MATLAB code for iserial_gui.fig
%      ISERIAL_GUI, by itself, creates a new ISERIAL_GUI or raises the existing
%      singleton*.
%
%      H = ISERIAL_GUI returns the handle to a new ISERIAL_GUI or the handle to
%      the existing singleton*.
%
%      ISERIAL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ISERIAL_GUI.M with the given input arguments.
%
%      ISERIAL_GUI('Property','Value',...) creates a new ISERIAL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iserial_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iserial_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iserial_gui

% Last Modified by GUIDE v2.5 15-Oct-2019 14:18:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iserial_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iserial_gui_OutputFcn, ...
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


% --- Executes just before iserial_gui is made visible.
function iserial_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iserial_gui (see VARARGIN)

%current Path
handles.DirPath = pwd;
set(handles.editFilename,'String','example.ptrn');
% Choose default command line output for iserial_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

arbConfig = loadArbConfig();
switch arbConfig.model
    case '81180A'
        dataRate = 1e9;
        numBits = 128;
    case {'M8190A', 'M8190A_base', 'M8190A_14bit' }
        dataRate = 1e9;
        numBits = 192;
    case 'M8190A_12bit'
        dataRate = 3e9;
        numBits = 256;
    case 'M8190A_prototype'
        dataRate = 1e9;
        numBits = 200;
    case { 'M8195A_Rev1' 'M8195A_1ch', 'M8195A_1ch_mrk', 'M8195A_2ch', 'M8195A_2ch_mrk', 'M8195A_4ch', 'M8195A_4ch_256k', 'M8196A', 'M8194A' }
        dataRate = 6e9;
        numBits = 1024;
    case 'M933xA'
        dataRate = 250e6;
        numBits = 128;
    otherwise
        dataRate = 250e6;
        numBits = 128;
end
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editDataRate, 'String', iqengprintf(dataRate));
set(handles.checkboxAutoSampleRate, 'Value', 1);
set(handles.editNumBits, 'String', num2str(numBits));
checkfields([], 0, handles);

if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editDataRate, 'TooltipString', sprintf([ ...
    'Enter the data rate for the signal in symbols per second.\n' ...
    'The utility will adjust the sample rate and oversampling to exactly match\n' ...
    'the specified data rate.']));
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'If you enter the sample rate manually, the data rate might not be exact.']));
set(handles.popupmenuDataType, 'TooltipString', sprintf([ ...
    'Select the format and type of data. ''Random'', ''Clock'' and ''PRBS'' \n' ...
    'generate binary data. ''PAMx'' and ''MLT-3'' generate multi-level signals']));
set(handles.editNumBits, 'TooltipString', sprintf([ ...
    'Enter the number of random bits to be generated. For User Defined data pattern.\n' ...
    'this field is ignored.']));
set(handles.editUserData, 'TooltipString', sprintf([ ...
    'This field contains a MATLAB expression that evaluates to a vector of “symbol” values.\n' ...
    'The values must be in the range 0….1, with 0 representing the lowest voltage level and\n' ...
    '1 the highest voltage level. For NRZ signals, the field typically contain a vector of\n', ...
    '0''s and 1''s. For PAM4, the nominal values are 0, 1/3, 2/3 and 1. You can either \n', ...
    'fill in a list of values separated by spaces or comma (e.g.  1 0 0 1 1 1 0 1 0 0 1)\n', ...
    'or a MATLAB expression that evaluates to a vector of values (e.g. to generate a vector of\n', ...
    '256 random 0''s and 1''s, you can put in the expression:  randi([0 1], 256, 1)  ).\n', ...
    'In order to make PAM4 signals easier to read it can be written as  1/3*[0 1 2 3 …], instead\n', ...
    'of 0, 1/3, 2/3, 1 …\n', ...
    'In addition to the "nominal" values (0 & 1 for NRZ; 0, 1/3, 2/3, 1 for PAM4), you can\n', ...
    'also use any fractional value between 0 and 1 to represent intermediate voltage levels.\n', ...
    'E.g. 0, 0, 0, 0.8, 0, 0, 0 can be used to generate an isolated "1" that does not quite reach\n', ...
    'the correct voltage level.\n', ...
    'To simplify generating PRBS sequences with errors in them, I added the following function to \n', ...
    'the "User defined data" field:\n', ...
    'Whenever you change the selection in the "Type of Data" pull-down menu, the corresponding \n', ...
    'data pattern is copied to the "User defined data" field. (E.g. when you select PRBS2^7-1, PAM4\n', ...
    'as the "Type of data", the "User defined data" field changes to "1/3 * [1 2 2 3 2 2 3 1 2 3 3……]").\n', ...
    'If you change the selection to "User defined data" afterwards, that same data pattern will be \n', ...
    'generated. Now you have the possibility to change individual symbols by changing one of the \n', ...
    'numbers in the square brackets to another number in the range 0…3 or even force the signal to go\n', ...
    'through the middle of an eye by changing one of the numbers to a fractional value between 0 and 3.']));
set(handles.editTransitionTime, 'TooltipString', sprintf([ ...
    'Enter the transition time as portion of a UI. Although a zero transition time can be\n' ...
    'entered, the actual transition time will be limited by the hardware.  If you want to\n' ...
    'apply jitter or you have non-integer relationship between data rate and sample rate,\n' ...
    'you should choose the transition time big enough to contain at least two samples.']));
set(handles.editPreCursor, 'TooltipString', sprintf([ ...
    'Any number of pre-cursor values specified as a list of values in dB, separated \n' ...
    'by spaces or comma. Pre-cursors are typically positive dB values.\n']));
set(handles.editPostCursor, 'TooltipString', sprintf([ ...
    'Any number of post-cursor values specified as a list of values in dB, separated \n' ...
    'by spaces or comma. Post-cursors are typically negative dB values.\n']));
set(handles.editSJfreq, 'TooltipString', sprintf([ ...
    'Enter the frequency for sinusoidal jitter. Note that the smallest frequency for SJ\n' ...
    'is limited by the number of bits the oversampling rate because the utility must fit\n' ...
    'at least one full cycle of the jitter into the waveform']));
set(handles.editSJpp, 'TooltipString', sprintf([ ...
    'Enter the peak-to-peak deviation for sinusoidal jitter in portions of UI.\n' ...
    'Example: For a 1 Gb/s data rate, a 0.2 UI jitter will be 200ps (peak-to-peak)']));
set(handles.editRJpp, 'TooltipString', sprintf([ ...
    'Enter the peak-to-peak deviation for random jitter in portions of UI.\n' ...
    'RJ is simulated as a (near-)gaussian distribution with a maximum deviation\n' ...
    'of 6 sigma.']));
set(handles.editNoise, 'TooltipString', sprintf([ ...
    'Enter the amount of vertical noise that is added to waveform in the range 0 to 1.\n' ...
    'Zero means no noise, 1 means the same amplitude of noise as the signal itself.']));
set(handles.editISI, 'TooltipString', sprintf([ ...
    'Enter the amount of ISI in the range 0 to 1. Zero means no ISI at all, 1 is a\n' ...
    'completely distorted signal. The practial maximum is around 0.8.  ISI is modelled\n' ...
    'as a simple decay function (y=e^(-ax))']));
set(handles.editSegment, 'TooltipString', sprintf([ ...
    'Enter the AWG waveform segment to which the signal will be downloaded.\n' ...
    'If you download to segment #1, all other segments will be automatically\n' ...
    'deleted.']));
set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the simulated waveform using MATLAB plots.\n' ...
    'The plot will show the downloaded waveform along with the (mathematical) jitter analysis']));
set(handles.pushbuttonChannelMapping, 'TooltipString', sprintf([ ...
    'Select into which channels the waveform is downloaded.\n' ...
    'In dual-M8190A configurations, channels 3 and 4 are on the second module.']));
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
if (~isempty(strfind(arbConfig.model, 'DUC')))
    errordlg({'Can not work in DUC mode. ' ...
        'Please use the "Configuration" utility' ...
        'and select a non-DUC mode'});
    close(handles.iqtool);
    return;
end
pos1 = get(handles.editFilename, 'Position');
pos2 = get(handles.editUserData, 'Position');
pos3 = get(handles.editLevels, 'Position');
pos2(1:2) = pos1(1:2);
set(handles.editUserData, 'Position', pos2);
pos3(1:2) = pos1(1:2);
set(handles.editLevels, 'Position', pos3);
% UIWAIT makes iserial_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);

% --- Outputs from this function are returned to the command line.
function varargout = iserial_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;


function editDataRate_Callback(hObject, eventdata, handles)
% hObject    handle to editDataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDataRate as text
%        str2double(get(hObject,'String')) returns contents of editDataRate as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
arbConfig = loadArbConfig();
if (isscalar(value) && value >= 1e3 && value <= arbConfig.maximumSampleRate(1))
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
    autoSampleRate = get(handles.checkboxAutoSampleRate, 'Value');
    if (autoSampleRate)
        arbConfig = loadArbConfig();
        sampleRate = arbConfig.defaultSampleRate;
    end
    % if the datarate is larger than Fs/4, adjust transition time
    % to avoid excessive jitter
    ttVal = get(handles.sliderTransitionTime, 'Value');
    if (ttVal < value / sampleRate * 4)
        ttVal = min(value / sampleRate * 4, 1);
        ttVal = ceil(ttVal * 100) / 100;
        set(handles.sliderTransitionTime, 'Value', ttVal);
        sliderTransitionTime_Callback([], [], handles);
    end
    % if the symbol rate is more than 50% of sample rate,
    % suggest Raised Cosine (user can still switch back if desired)
    if (value / sampleRate > 1/2 && get(handles.popupmenuFilterType, 'Value') == 1)
        set(handles.popupmenuFilterType, 'Value', 2);
        popupmenuFilterType_Callback([], [], handles);
    end
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editDataRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



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



function editNumBits_Callback(hObject, eventdata, handles)
% hObject    handle to editNumBits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumBits as text
%        str2double(get(hObject,'String')) returns contents of editNumBits as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 2 && value <= 10e6)
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNumBits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumBits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSJpp_Callback(hObject, eventdata, handles)
% hObject    handle to editSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSJpp as text
%        str2double(get(hObject,'String')) returns contents of editSJpp as a double
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 10)
    set(handles.sliderSJpp, 'Value', min(1, value(1)));
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderRJpp_Callback(hObject, eventdata, handles)
% hObject    handle to sliderRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject, 'Value');
set(handles.editRJpp, 'String', sprintf('%.2g', value));


% --- Executes during object creation, after setting all properties.
function sliderRJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSJpp_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject, 'Value');
set(handles.editSJpp, 'String', sprintf('%.2g', value));


% --- Executes during object creation, after setting all properties.
function sliderSJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderTransitionTime_Callback(hObject, eventdata, handles)
% hObject    handle to sliderTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(handles.sliderTransitionTime, 'Value');
set(handles.editTransitionTime, 'String', sprintf('%.2g', value));
dataRate = evalin('base', get(handles.editDataRate, 'String'));
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
if (value < 1 && value < dataRate / sampleRate * 4)
    set(handles.sliderTransitionTime, 'Background', 'yellow');
else
    set(handles.sliderTransitionTime, 'Background', 'white');
end

% --- Executes during object creation, after setting all properties.
function sliderTransitionTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editUserData_Callback(hObject, eventdata, handles)
% hObject    handle to editUserData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editUserData as text
%        str2double(get(hObject,'String')) returns contents of editUserData as a double
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch
    try
        clear data;
        eval(get(hObject, 'String'));
        value = data;   % expect "data" to be assigned
    catch
        errordlg('Must specify a list of values separated by space or comma *or* a MATLAB statement that assigns a value to the variable "data"');
    end
end
if (isvector(value) && length(value) >= 2 && ...
        min(value) >= 0 && max(value) <= 1)
    set(handles.editNumBits, 'String', num2str(length(value)));
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
    errordlg('Data values must be between 0 and 1 and separated by spaces or comma. MATLAB expressions are acceptable');
end


% --- Executes during object creation, after setting all properties.
function editUserData_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editUserData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDataType.
function popupmenuDataType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDataType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDataType
setupUserDefGuiCtrls(handles);



function setupUserDefGuiCtrls(handles)
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
dataType = dataTypeList{get(handles.popupmenuDataType, 'Value')};
formatVal = get(handles.popupmenuDataFormat, 'Value');
checkM8195A = 0;
if (strcmp(dataType, 'User defined'))
    set(handles.editNumBits, 'Enable', 'Off');
    set(handles.editUserData, 'Visible', 'On');
    set(handles.editUserData, 'Enable', 'On');
    set(handles.fileBrowser, 'Visible', 'Off');
    set(handles.editFilename, 'Visible', 'Off');
    set(handles.editLevels, 'Visible', 'Off');
    set(handles.textUserData, 'String', 'User defined data');
elseif (~isempty(strfind(dataType, 'file')))
    set(handles.editNumBits, 'Enable', 'Off');
    set(handles.editUserData, 'Visible', 'Off');
    set(handles.editUserData, 'Enable', 'Off');
    set(handles.fileBrowser, 'Visible', 'On');
    set(handles.fileBrowser, 'Enable', 'On');
    set(handles.editFilename, 'Visible', 'On');
    set(handles.editFilename, 'Enable', 'On');
    set(handles.editLevels, 'Visible', 'Off');
    set(handles.textUserData, 'String', 'User pattern file');
%elseif (~isempty(strfind(dataType, 'levels')))
% elseif (isempty(strfind(dataType, 'Clock')) && formatVal == 2)
%     set(handles.editNumBits, 'Enable', 'On');
%     set(handles.editUserData, 'Visible', 'Off');
%     set(handles.editUserData, 'Enable', 'Off');
%     set(handles.fileBrowser, 'Visible', 'Off');
%     set(handles.editFilename, 'Visible', 'Off');
%     set(handles.editLevels, 'Visible', 'On');
%     set(handles.editLevels, 'Enable', 'On');
%     set(handles.textUserData, 'String', 'User defined levels');
else
    set(handles.editNumBits, 'Enable', 'On');
    set(handles.editUserData, 'Enable', 'Off');
    set(handles.editFilename, 'Enable', 'Off');
    set(handles.fileBrowser, 'Enable', 'Off');
    set(handles.editLevels, 'Enable', 'Off');
end
if (strcmp(dataType, 'PAM4'))
    dataType = 'PRBS2^11-1';
    set(handles.popupmenuDataType, 'Value', find(strcmp(dataType, dataTypeList)));
    formatVal = 2;
    set(handles.popupmenuDataFormat, 'Value', formatVal);
end
if (strncmp(dataType, 'PRBS', 4) || strcmp(dataType, 'Random'))
    set(handles.popupmenuDataFormat, 'Visible', 'On');
else
    set(handles.popupmenuDataFormat, 'Visible', 'Off');
end
if (strcmp(dataType, 'Random'))
    set(handles.editSymbolShift, 'Enable', 'Off');
else
    set(handles.editSymbolShift, 'Enable', 'On');
end
levSet = 0;
switch dataType
    case 'Random'
        levSet = -1;
    case {'MLT-3' 'PAM3'}
        levSet = 3;
    case 'PAM5'
        levSet = 5;
    case 'PAM6'
        levSet = 6;
    case 'PAM7'
        levSet = 7;
    case 'PAM8'
        levSet = 8;
    case 'PAM16'
        levSet = 16;
    case 'PRBS2^7-1'
        levSet = -1;
        set(handles.editNumBits, 'String', '64 * (2^7 - 1)');
    case 'PRBS2^9-1'
        levSet = -1;
        set(handles.editNumBits, 'String', '16 * (2^9 - 1)');
    case 'PRBS2^10-1'
        levSet = -1;
        set(handles.editNumBits, 'String', '8 * (2^10 - 1)');
    case 'PRBS2^11-1'
        levSet = -1;
        set(handles.editNumBits, 'String', '4 * (2^11 - 1)');
    case 'PRBS2^12-1'
        levSet = -1;
        set(handles.editNumBits, 'String', '2 * (2^12 - 1)');
    case 'PRBS2^13-1'
        levSet = -1;
        set(handles.editNumBits, 'String', '2 * (2^13 - 1)');
    case 'PRBS2^15-1'
        levSet = -1;
        set(handles.editNumBits, 'String', '(2^15 - 1)');
    case 'PRBS2^23-1'
        checkM8195A = 1;
        set(handles.editNumBits, 'String', '(2^23 - 1)');
    case 'PRBS2^31-1'
        checkM8195A = 1;
        set(handles.editNumBits, 'String', '(2^31 - 1)');
    case 'JP03B'
        set(handles.editNumBits, 'String', '16 * 4 * 62');
    case 'LinearityTestPattern'
        levSet = 4;
        set(handles.editNumBits, 'String', '320');
    case 'SSPRQ'
        levSet = 4;
        set(handles.editNumBits, 'String', '65535');
    otherwise
        if (strncmp(dataType, 'QPRBS13', 7))
            levSet = 4;
            set(handles.editNumBits, 'String', '2 * 15548');
        end
end
if (levSet ~= 0)
    if (levSet < 0)
        if (formatVal == 2)
            levSet = 4;
        else
            levSet = 0;
        end
    end
    if (levSet ~= 0)
        udLev = evalin('base', ['[' get(handles.editLevels, 'String') ']']);
        if (length(udLev) ~= levSet)
            %--- special case for PAM4: apply gray mapping
            if (levSet == 4)
                set(handles.editLevels, 'String', '0 1/3 1 2/3');
            else
                set(handles.editLevels, 'String', ['0 ' sprintf('%d/%d ', [(1:levSet-2); repmat(levSet-1,1,levSet-2)]) '1']);
            end
        end
        set(handles.editNumBits, 'Enable', 'On');
        set(handles.editUserData, 'Visible', 'Off');
        set(handles.editUserData, 'Enable', 'Off');
        set(handles.fileBrowser, 'Visible', 'Off');
        set(handles.editFilename, 'Visible', 'Off');
        set(handles.editLevels, 'Visible', 'On');
        set(handles.editLevels, 'Enable', 'On');
        set(handles.textUserData, 'String', 'User defined levels');
    end
end
if (checkM8195A)
    arbConfig = loadArbConfig();
    if (~strcmp(arbConfig.model, 'M8195A_1ch') && ...
        ~strcmp(arbConfig.model, 'M8195A_2ch') && ...
        ~strcmp(arbConfig.model, 'M8195A_2ch_mrk') && ...
        ~strcmp(arbConfig.model, 'M8195A_4ch') && ...
        isempty(strfind(arbConfig.model, 'M8121A')))
        warndlg('PRBSes > 2^15 are only allowed with M8121A or M8195A and large memory');
        set(handles.popupmenuDataType, 'Value', find(strcmp('PRBS2^15-1', dataTypeList)));
        set(handles.editNumBits, 'String', '(2^15 - 1)');
    end
end
if (isLargeData(handles))
    x = 'Off';
    set(handles.editSymbolShift, 'Enable', 'Off');
else
    x = 'On';
end
set(handles.sliderISI, 'Enable', x);
set(handles.editISI, 'Enable', x);
set(handles.sliderDutyCycle, 'Enable', x);
set(handles.editDutyCycle, 'Enable', x);
set(handles.sliderNoise, 'Enable', x);
set(handles.editNoise, 'Enable', x);
set(handles.editNoiseFreq, 'Enable', x);
set(handles.editSSCfreq, 'Enable', x);
set(handles.editSSCdepth, 'Enable', x);
set(handles.sliderRJpp, 'Enable', x);
set(handles.editRJpp, 'Enable', x);
set(handles.sliderSJpp, 'Enable', x);
set(handles.editSJpp, 'Enable', x);
set(handles.editSJfreq, 'Enable', x);
set(handles.editPreCursor, 'Enable', x);
set(handles.editPostCursor, 'Enable', x);
setUserDefinedData(handles, dataType);



function setUserDefinedData(handles, dataType)
switch(dataType)
    case 'PRBS2^7-1'
        prbsPoly = [7 1 0];
    case 'PRBS2^9-1'
        prbsPoly = [9 4 0];
    case 'PRBS2^10-1'
        prbsPoly = [10 3 0];
    case 'PRBS2^11-1'
        prbsPoly = [11 2 0];
    case 'PRBS2^12-1'
        prbsPoly = [12 11 8 6 0]; % alternative [12 6 4 1 0]
%    case 'PRBS2^12-1'
%        prbsPoly = [12 6 4 1 0]; % alternative [12 11 8 6 0]
    case 'PRBS2^13-1'
        prbsPoly = [13 12 11 1 0];
    case 'PRBS2^15-1'
        prbsPoly = [15 1 0];
    otherwise
        return;
end
format = get(handles.popupmenuDataFormat, 'Value');
numBits = evalin('base', get(handles.editNumBits, 'String'));
if (format == 2) % PAM4
    h = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', 2*numBits);
    data = h.generate()';
    % apply a gray mapping (00 01 11 10)
    mapping = [0 1 3 2];
    data = mapping(2 * data(1:2:end-1) + data(2:2:end) + 1);
    dataStr = strtrim(sprintf('%d ', data));
    set(handles.editUserData, 'String', sprintf('1/3 * [%s]', dataStr));
else
    h = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', numBits);
    data = h.generate()';
    set(handles.editUserData, 'String', sprintf('%d ', data));
end




% --- Executes during object creation, after setting all properties.
function popupmenuDataType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxAutoSampleRate.
function checkboxAutoSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxAutoSampleRate
autoSamples = get(handles.checkboxAutoSampleRate, 'Value');
if (autoSamples)
    set(handles.editSampleRate, 'Enable', 'off');
else
    set(handles.editSampleRate, 'Enable', 'on');
end



function editNoise_Callback(hObject, eventdata, handles)
% hObject    handle to editNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNoise as text
%        str2double(get(hObject,'String')) returns contents of editNoise as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderNoise, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNoise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNoise (see GCBO)
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
[s, fs, dataRate, numSamples] = calc_serial(handles, 'display', []);
set(handles.editNumSamples, 'String', sprintf('%d', numSamples));
if (~isempty(s))
    iqplot(s, fs);
%    isplot(s, fs, dataRate);
    try
        iqeyeplot(s, fs, fs/dataRate, 2);
    catch
    end
end


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
[s, fs, ~, numSamples, channelMapping] = calc_serial(handles, 'download', []);
set(handles.editNumSamples, 'String', sprintf('%d', numSamples));
if (~isempty(s))
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
    marker = downloadClock(handles);
    iqdownload(s, fs, 'channelMapping', channelMapping, ...
        'segmentNumber', segmentNum, 'marker', marker);
end
try close(hMsgBox); catch; end



function marker = downloadClock(handles)
% download a clock signal on unchecked channels, but don't start the generator
marker = [];
div = 1;
if (strcmp('on', get(handles.menuDataRateClock2, 'Checked')))
    div = 2;
elseif (strcmp('on', get(handles.menuDataRateClock4, 'Checked')))
    div = 4;
elseif (strcmp('on', get(handles.menuDataRateClock8, 'Checked')))
    div = 8;
elseif (strcmp('on', get(handles.menuDataRateClock16, 'Checked')))
    div = 16;
end
isCheckedOnce = (strcmp('on', get(handles.menuClockOnce, 'Checked')));
numBits = evalin('base', get(handles.editNumBits, 'String'));
if (div > 1)
    clockPat = repmat([ones(1,div/2) zeros(1,div/2)], 1, ceil(numBits/div));
    clockPat = clockPat(1:numBits);
    if (mod(numBits, div) ~= 0)
        warndlg(sprintf('Number of bits is not a multiple of %d - clock signal will not be periodic', div), 'Warning', 'replace');
    end
elseif (isCheckedOnce)
    clockPat = [ones(1, floor(numBits/2)) zeros(1, numBits - floor(numBits/2))];
else
    return;
end
% can't do clock on large data pattern (for now...)
if (isLargeData(handles))
    msgbox('Clock generation is not supported on large PRBS patterns.');
    return;
end
[s, fs, dataRate, ~, chMap] = calc_serial(handles, 'clock', clockPat);
if (~isempty(s))
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
    if (~isempty(find(chMap(1:end), 1)))
        iqdownload(s, fs, 'channelMapping', chMap, 'segmentNumber', segmentNum, 'run', 0);
    end
    if (div > 1)
        numSamples = length(s);
        % find the oversampling ratio, ignore the fractional part, since it
        % can not be realized with markers
        [overN, ~] = rat(fs / dataRate * div);
        % for 1x oversampling, set marker every other symbol
        overN = max(overN, 2);
        % cannot toggle markers faster than fs/2
        maxTrig = fs/2;
        arbConfig = loadArbConfig();
        % for M8190A, max toggle rate for markers = sequencer clock
        if (strcmp(arbConfig.model, 'M8190A_12bit'))
            maxTrig = fs / 64;
        elseif (strcmp(arbConfig.model, 'M8190A_14bit'))
            maxTrig = fs / 48;
        elseif (~isempty(strfind(arbConfig.model, 'M8190A')))
            maxTrig = fs / 24;
        end
        % for M8195A, markers can toggle at a max. rate of fs/128
        if (~isempty(strfind(arbConfig.model, 'M8195A')))
            maxTrig = fs / 128;
        end
        % 
        if (ceil(fs / maxTrig / overN) > 1)
            overN = overN * ceil(fs / maxTrig / overN);
        end
        h1 = floor(overN / 2);
        h2 = overN - h1;
        marker = repmat([15*ones(1,h1) zeros(1,h2)], 1, ceil(numSamples / overN));
        marker = marker(1:numSamples);
        if (dataRate/div ~= fs/overN && isempty(find(chMap(1:end), 1)) && ...
                (strncmpi(arbConfig.model, 'M8190A', 6) || ...
                 strncmpi(arbConfig.model, 'M8195A_2ch_mrk', 14) || ...
                 strncmpi(arbConfig.model, 'M8195A_1ch', 10) || ...
                 strncmpi(arbConfig.model, 'M8198A', 6)))
            warndlg(sprintf('Clock frequency on markers is %s GHz instead of %s GHz\ndue to marker resolution', ...
                iqengprintf(fs/overN/1e9), iqengprintf(dataRate/div/1e9)), 'Note', 'replace');
        end
    end
end


function editRJpp_Callback(hObject, eventdata, handles)
% hObject    handle to editRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRJpp as text
%        str2double(get(hObject,'String')) returns contents of editRJpp as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderRJpp, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editRJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editISI_Callback(hObject, eventdata, handles)
% hObject    handle to editISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editISI as text
%        str2double(get(hObject,'String')) returns contents of editISI as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderISI, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editISI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSJfreq_Callback(hObject, eventdata, handles)
% hObject    handle to editSJfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSJfreq as text
%        str2double(get(hObject,'String')) returns contents of editSJfreq as a double
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 64e9)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSJfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSJfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editTransitionTime_Callback(hObject, eventdata, handles)
% hObject    handle to editTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTransitionTime as text
%        str2double(get(hObject,'String')) returns contents of editTransitionTime as a double
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(handles.sliderTransitionTime, 'Value', value(1));
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editTransitionTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderNoise_Callback(hObject, eventdata, handles)
% hObject    handle to sliderNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject, 'Value');
set(handles.editNoise, 'String', sprintf('%.2g', value));


% --- Executes during object creation, after setting all properties.
function sliderNoise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function sliderISI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function sliderISI_Callback(hObject, eventdata, handles)
% hObject    handle to sliderISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
value = get(hObject, 'Value');
set(handles.editISI, 'String', sprintf('%.2g', value));


% --- Executes on slider movement.
function sliderDutyCycle_Callback(hObject, eventdata, handles)
% hObject    handle to sliderDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject, 'Value');
set(handles.editDutyCycle, 'String', sprintf('%.0f', value));


% --- Executes during object creation, after setting all properties.
function sliderDutyCycle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editDutyCycle_Callback(hObject, eventdata, handles)
% hObject    handle to editDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDutyCycle as text
%        str2double(get(hObject,'String')) returns contents of editDutyCycle as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 100)
    set(handles.sliderDutyCycle, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editDutyCycle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmplitude as text
%        str2double(get(hObject,'String')) returns contents of editAmplitude as a double


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
function preset_Callback(hObject, eventdata, handles)
% hObject    handle to preset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function clock_8gbps_Callback(hObject, eventdata, handles)
% hObject    handle to clock_8gbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '8e9');
set(handles.editSampleRate, 'String', '8e9');
set(handles.checkboxAutoSampleRate, 'Value', 0);
set(handles.popupmenuDataType, 'Value', 2);
set(handles.editNumBits, 'String', '192');
set(handles.sliderTransitionTime, 'Value', 0);
sliderTransitionTime_Callback([], [], handles);
set(handles.editSJfreq, 'String', '0');
set(handles.editSJpp, 'String', '0');
editSJpp_Callback([], [], handles);
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
editNoise_Callback([], [], handles);
set(handles.editISI, 'String', '0');
set(handles.sliderISI, 'Value', 0);


% --------------------------------------------------------------------
function mlt3_125mbps_Callback(hObject, eventdata, handles)
% hObject    handle to mlt3_125mbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '125e6');
set(handles.checkboxAutoSampleRate, 'Value', 1);
set(handles.popupmenuDataType, 'Value', 3);
set(handles.editNumBits, 'String', '192');
set(handles.sliderTransitionTime, 'Value', 0.3);
sliderTransitionTime_Callback([], [], handles);
set(handles.editSJfreq, 'String', '0');
set(handles.editSJpp, 'String', '0');
editSJpp_Callback([], [], handles);
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
editNoise_Callback([], [], handles);
set(handles.editISI, 'String', '0');
set(handles.sliderISI, 'Value', 0);
popupmenuDataType_Callback([], [], handles);


% --------------------------------------------------------------------
function random_1gbps_Callback(hObject, eventdata, handles)
% hObject    handle to random_1gbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '1e9');
set(handles.checkboxAutoSampleRate, 'Value', 1);
set(handles.popupmenuDataType, 'Value', 1);
set(handles.editNumBits, 'String', '192');
set(handles.sliderTransitionTime, 'Value', 0.3);
sliderTransitionTime_Callback([], [], handles);
set(handles.editSJfreq, 'String', '10e6');
set(handles.editSJpp, 'String', '0');
editSJpp_Callback([], [], handles);
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
editNoise_Callback([], [], handles);
set(handles.editISI, 'String', '0.7');
set(handles.sliderISI, 'Value', 0.7);
popupmenuDataType_Callback([], [], handles);


% --------------------------------------------------------------------
function menu_PAM4_nonequidistant_Callback(hObject, eventdata, handles)
% hObject    handle to random_1gbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '25e9');
set(handles.checkboxAutoSampleRate, 'Value', 1);
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
set(handles.popupmenuDataType, 'Value', length(dataTypeList));
set(handles.editUserData, 'String', 'v=[0 0.2 0.5 1]; data = v(randi(4,1,10240));');
set(handles.editNumBits, 'String', '10240');
set(handles.sliderTransitionTime, 'Value', 1);
sliderTransitionTime_Callback([], [], handles);
set(handles.editSJfreq, 'String', '10e6');
set(handles.editSJpp, 'String', '0');
editSJpp_Callback([], [], handles);
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
editNoise_Callback([], [], handles);
set(handles.editISI, 'String', '0');
set(handles.sliderISI, 'Value', 0);
set(handles.checkboxCorrection, 'Value', 1);
popupmenuDataType_Callback([], [], handles);


function [s, fs, dataRate, numSamples, channelMapping] = calc_serial(handles, fct, param)
s = [];
fs = 0;
dataRate = 0;
numSamples = 0;
dataRate = evalin('base', get(handles.editDataRate, 'String'));
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
autoSampleRate = get(handles.checkboxAutoSampleRate, 'Value');
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
dataType = dataTypeList{get(handles.popupmenuDataType, 'Value')};
formatList = cellstr(get(handles.popupmenuDataFormat, 'String'));
formatStr = formatList{get(handles.popupmenuDataFormat, 'Value')};
numBits = evalin('base', get(handles.editNumBits, 'String'));
symbolShift = evalin('base', get(handles.editSymbolShift, 'String'));
if (~isempty(strfind(dataType, 'file')))
    userData = double(ptrnfile2data(strcat(handles.DirPath, '\', get(handles.editFilename, 'String'))));
    if (isempty(userData) || isequal(userData, -1))
        return;
    end
    dataType = 'User defined';
else
    try
        % try to interpret userdata as a list of values
        userData = evalin('base', ['[' get(handles.editUserData, 'String') ']']);
        if (isempty(userData))
            return;
        end
    catch
        % if this fails, try to evaluate as a statement that assigns
        % soemthing to the variable "data"
        clear data;
        eval(get(handles.editUserData, 'String'));
        userData = data;   % expect "data" to be assigned
    end
end
preCursor = evalin('base', ['[' get(handles.editPreCursor, 'String') ']']);
postCursor = evalin('base', ['[' get(handles.editPostCursor, 'String') ']']);
filterTypeList = get(handles.popupmenuFilterType, 'String');
filterType = filterTypeList{get(handles.popupmenuFilterType, 'Value')};
filterNsym = evalin('base', get(handles.editNsym, 'String'));
filterBeta = evalin('base', get(handles.editAlpha, 'String'));
tTime = evalin('base', ['[' get(handles.editTransitionTime, 'String') ']']);
JShapeList = get(handles.popupmenuJitterShape, 'String');
JShape = JShapeList{get(handles.popupmenuJitterShape, 'Value')};
SJfreq = evalin('base', ['[' get(handles.editSJfreq, 'String') ']']);
SJpp = evalin('base', ['[' get(handles.editSJpp, 'String') ']']);
RJpp = evalin('base', get(handles.editRJpp, 'String'));
sscFreq = evalin('base', get(handles.editSSCfreq, 'String'));
sscDepth = evalin('base', get(handles.editSSCdepth, 'String'));
noiseFreq = evalin('base', get(handles.editNoiseFreq, 'String'));
noise = evalin('base', get(handles.editNoise, 'String'));
isi = evalin('base', get(handles.editISI, 'String'));
amplitude = evalin('base', get(handles.editAmplitude, 'String'));
dutyCycle = evalin('base', get(handles.editDutyCycle, 'String'));
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
useM8196RefClk = strcmp('on', get(handles.menuUseM8196RefClk, 'Checked'));
% unless we download, just look at the real part of the first channel
if (~strcmp(fct, 'download') && ~strcmp(fct, 'clock'))
    channelMapping = [1 0];
end
correction = get(handles.checkboxCorrection, 'Value');
if (strcmp(fct, 'clock'))
    % select all "unchecked" channels 
    channelMapping(:,1) = ~channelMapping(:,1) & ~channelMapping(:,2);
    channelMapping(:,2) = 0;
    % force a certain pattern - independent of user settings
    dataType = 'User defined';
    userData = param;
    % make clock without distortions
    SJpp = 0;
    RJpp = 0;
    noise = 0;
    amplitude = 1;
    dutyCycle = 50;
end
if (autoSampleRate)
    sampleRate = 0;
end
levels = evalin('base', ['[' get(handles.editLevels, 'String') ']']);
levelStr = ['[' sprintf('%g ', levels) ']'];
if (strcmp(dataType, 'User defined'))
    data = userData;
    numBits = length(data);
    set(handles.editNumBits, 'String', num2str(numBits));
    dataStr = ['[' sprintf('%g ', userData) ']'];
    levels = [];
    levelStr = '[]';
elseif (~isempty(strfind(dataType, 'levels')))
    data = dataType;
    dataStr = sprintf('''%s''', dataType);
else
    data = dataType;
    dataStr = sprintf('''%s''', dataType);
end
switch (fct)
    case 'code' % generate MATLAB code
        channelMappingStr = iqchannelsetup('arraystring', get(handles.pushbuttonChannelMapping, 'UserData'));
        segmentNum = evalin('base', get(handles.editSegment, 'String'));
        if (isLargeData(handles))
            downloadStr = '';
        else
            downloadStr = sprintf('iqdownload(s, fs, ''segmentNumber'', %g, ''channelMapping'', chMap);\n', segmentNum);
        end
        s = sprintf(['[s, fs, nSym, nSamples, chMap] = iserial(''dataRate'', %g, ''sampleRate'', %g, ...\n' ...
            '    ''numBits'', %d, ''data'', %s, ''format'', ''%s'', ''function'', ''download'', ''levels'', %s, ...\n' ...
            '    ''SJfreq'', [%s], ''SJpp'', [%s], ''RJpp'', %g, ''noiseFreq'', %g, ''noise'', %g, ''isi'', %g, ...\n' ...
            '    ''preCursor'', [%s], ''postCursor'', [%s], ''transitionTime'', %g, ...\n' ...
            '    ''filterType'', ''%s'', ''filterNsym'', %g, ''filterBeta'', %g, ...\n' ...
            '    ''jitterShape'', ''%s'', ''sscFreq'', %g, ''sscDepth'', %g, ''symbolShift'', %d, ...\n' ...
            '    ''amplitude'', %g, ''dutyCycle'', %g, ''correction'', %g, ''channelMapping'', %s, ...\n' ...
            '    ''useM8196RefClk'', %d);\n%s'], ...
            dataRate, sampleRate, numBits, dataStr, formatStr, levelStr, sprintf('%g ', SJfreq), ...
            sprintf('%g ', SJpp), RJpp, noiseFreq, noise, ...
            isi, sprintf('%g ', preCursor), sprintf('%g ', postCursor), tTime, filterType, filterNsym, filterBeta, ...
            JShape, sscFreq, sscDepth / 100, ...
            symbolShift, amplitude, dutyCycle / 100, correction, channelMappingStr, useM8196RefClk, downloadStr);
        fs = 0;
        dataRate = 0;
    case {'download' 'display' 'save' 'clock'} % generate the actual waveform
        [s, fs, numBits, numSamples, channelMapping] = iserial('dataRate', dataRate, 'sampleRate', sampleRate, ...
            'numBits', numBits, 'data', data, 'levels', levels, 'format', formatStr, 'function', fct, 'filename', param, ...
            'SJfreq', SJfreq, 'SJpp', SJpp, 'RJpp', RJpp, 'noiseFreq', noiseFreq, 'noise', noise, 'isi', isi, ...
            'preCursor', preCursor, 'postCursor', postCursor, 'transitionTime', tTime, ...
            'filterType', filterType, 'filterNsym', filterNsym, 'filterBeta', filterBeta, ...
            'jitterShape', JShape, 'sscFreq', sscFreq, 'sscDepth', sscDepth / 100, 'symbolShift', symbolShift, ...
            'amplitude', amplitude, 'dutyCycle', dutyCycle / 100, 'correction', correction, ...
            'channelMapping', channelMapping, 'useM8196RefClk', useM8196RefClk);
        set(handles.editSampleRate, 'String', iqengprintf(fs));
        set(handles.editNumBits, 'String', num2str(numBits));
        assignin('base', 'signal', s);
        assignin('base', 'sampleRate', fs);
        assignin('base', 'dataRate', dataRate);
    otherwise
        errordlg(['unexpected function' fct]);
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


% --------------------------------------------------------------------
function menuSaveWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (isLargeData(handles))
    % if it is a large data set, data must be saved inside calc_serial
    [FileName,PathName,~] = uiputfile({...
    '.bin', 'BIN file (*.bin)'; ...
    '.pbin12', '12-bit packed binary (*.pbin12)'; ...
    }, 'Save Waveform As...');
    if (FileName ~= 0)
        [~, ~, ~, numSamples] = calc_serial(handles, 'save', fullfile(PathName, FileName));
        set(handles.editNumSamples, 'String', num2str(numSamples));
    end
else
    [data, sampleRate, ~, numSamples] = calc_serial(handles, 'save', []);
    if (~isempty(data))
        iqsavewaveform(data, sampleRate);
        set(handles.editNumSamples, 'String', num2str(numSamples));
    end
end


function result = isLargeData(handles)
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
dataType = dataTypeList{get(handles.popupmenuDataType, 'Value')};
a = regexp(dataType, 'PRBS2\^(\d*)-1', 'tokens');
if (~isempty(a) && str2double(a{1}) > 15)
    result = 1;
else
    result = 0;
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
[val, str] = iqchanneldlg(get(handles.pushbuttonChannelMapping, 'UserData'), arbConfig, handles.iqtool, 'single');
%[val, str] = iqchanneldlg(get(handles.pushbuttonChannelMapping, 'UserData'), arbConfig, handles.iqtool);
if (~isempty(val))
    set(handles.pushbuttonChannelMapping, 'UserData', val);
    set(handles.pushbuttonChannelMapping, 'String', str);
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
[code, fs, dataRate, numSamples] = calc_serial(handles, 'code', []);
set(handles.editNumSamples, 'String', num2str(numSamples));
if (~isempty(code))
    iqgeneratecode(handles, code);
end


function editNumSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSamples as text
%        str2double(get(hObject,'String')) returns contents of editNumSamples as a double


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


% --------------------------------------------------------------------
function menuClock(hObject, eventdata, handles)
set(handles.menuNoClock, 'Checked', 'off');
set(handles.menuDataRateClock2, 'Checked', 'off');
set(handles.menuDataRateClock4, 'Checked', 'off');
set(handles.menuDataRateClock8, 'Checked', 'off');
set(handles.menuDataRateClock16, 'Checked', 'off');
set(handles.menuClockOnce, 'Checked', 'off');
set(handles.menuUseM8196RefClk, 'Checked', 'off');
set(hObject, 'Checked', 'on');
if (hObject ~= handles.menuNoClock && hObject ~= handles.menuUseM8196RefClk)
    chm = get(handles.pushbuttonChannelMapping, 'UserData');
    if (length(find(sum(chm'))) == size(chm,1) && size(chm,1) > 1)
        hMsgBox = msgbox(['In order to generate a clock signal, please un-check at least one channel in the "Download" window. ' ...
                          'The clock signal will be generated on the unchecked channel(s)']);
        pushbuttonChannelMapping_Callback([], [], handles);
        try
            close(hMsgBox);
        catch
        end
    end
end


% --------------------------------------------------------------------
function menuDataRateClock2_Callback(hObject, eventdata, handles)
% hObject    handle to menuDataRateClock2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
menuClock(hObject, eventdata, handles);

% --------------------------------------------------------------------
function menuClockOnce_Callback(hObject, eventdata, handles)
% hObject    handle to menuClockOnce (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
menuClock(hObject, eventdata, handles);


function menuDataRateClock4_Callback(hObject, eventdata, handles)
% hObject    handle to menuDataRateClock4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
menuClock(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menuDataRateClock8_Callback(hObject, eventdata, handles)
% hObject    handle to menuDataRateClock8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
menuClock(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menuDataRateClock16_Callback(hObject, eventdata, handles)
% hObject    handle to menuDataRateClock16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
menuClock(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menuNoClock_Callback(hObject, eventdata, handles)
% hObject    handle to menuNoClock (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
menuClock(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menuUseM8196RefClk_Callback(hObject, eventdata, handles)
% hObject    handle to menuUseM8196RefClk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
menuClock(hObject, eventdata, handles);


function editNoiseFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editNoiseFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNoiseFreq as text
%        str2double(get(hObject,'String')) returns contents of editNoiseFreq as a double


% --- Executes during object creation, after setting all properties.
function editNoiseFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNoiseFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonMTCal.
function pushbuttonMTCal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMTCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqmtcal_gui('single');


% --- Executes on button press in pushbuttonConfigScope.
function pushbuttonConfigScope_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonConfigScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox('Function not yet implemented');


% --------------------------------------------------------------------



function editPreCursor_Callback(hObject, eventdata, handles)
% hObject    handle to editPreCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPreCursor as text
%        str2double(get(hObject,'String')) returns contents of editPreCursor as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(value) || (isvector(value) && min(value) >= -10 && max(value) <= 10))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPreCursor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPreCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPostCursor_Callback(hObject, eventdata, handles)
% hObject    handle to editPostCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPostCursor as text
%        str2double(get(hObject,'String')) returns contents of editPostCursor as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(value) || (isvector(value) && min(value) >= -10 && max(value) <= 10))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPostCursor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPostCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in fileBrowser.
function fileBrowser_Callback(hObject, eventdata, handles)                  %
% hObject    handle to fileBrowser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uigetfile({'*.ptrn;*.txt'},'Select a pattern file',handles.DirPath);
if filename ~= 0
     set(handles.editFilename,'String',filename);
     handles.DirPath = pathname;
     % Update handles structure
     guidata(hObject, handles);
end


function editFilename_Callback(hObject, eventdata, handles)
data = ptrnfile2data(fullfile(handles.DirPath, get(handles.editFilename, 'String')));
if (isempty(data))
    set(handles.editFilename, 'Background', 'red');
else
    set(handles.editFilename, 'Background', 'white');
    set(handles.editNumBits, 'String', iqengprintf(length(data)));
end


% --- Executes during object creation, after setting all properties.
function editFilename_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLevels_Callback(hObject, eventdata, handles)
% hObject    handle to editLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
    errordlg('Must be a list of values in the range 0...1', 'Error', 'replace');
end


% --- Executes during object creation, after setting all properties.
function editLevels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSSCfreq_Callback(hObject, eventdata, handles)
% hObject    handle to editSSCfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSSCfreq as text
%        str2double(get(hObject,'String')) returns contents of editSSCfreq as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1e9)
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
end



function checkSSC(handles)
dataRate = evalin('base', get(handles.editDataRate, 'String'));
numBits = evalin('base', get(handles.editNumBits, 'String'));
sscDepth = evalin('base', get(handles.editSSCdepth, 'String'));
sscFreq = evalin('base', get(handles.editSSCfreq, 'String'));
if (sscDepth == 0 || dataRate / numBits <= sscFreq)
    set(handles.editSSCfreq, 'BackgroundColor', 'white');
else
    set(handles.editSSCfreq, 'BackgroundColor', 'red');
    errordlg(sprintf(['SSC frequency is too low *or* current number of symbols is too small.\n' ...
        'Please increase SSC frequency to %s *or* increase number of symbols to %d'], ...
        iqengprintf(dataRate / numBits, 3), ceil(dataRate / sscFreq)));
end


% --- Executes during object creation, after setting all properties.
function editSSCfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSSCfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSSCdepth_Callback(hObject, eventdata, handles)
% hObject    handle to editSSCdepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSSCdepth as text
%        str2double(get(hObject,'String')) returns contents of editSSCdepth as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 100)
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSSCdepth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSSCdepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDataFormat.
function popupmenuDataFormat_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDataFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
dataType = dataTypeList{get(handles.popupmenuDataType, 'Value')};
setUserDefinedData(handles, dataType);
setupUserDefGuiCtrls(handles);



% --- Executes during object creation, after setting all properties.
function popupmenuDataFormat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDataFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSymbolShift_Callback(hObject, eventdata, handles)
% hObject    handle to editSymbolShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && ~isempty(value) && value == floor(value))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSymbolShift_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSymbolShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuJitterShape.
function popupmenuJitterShape_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuJitterShape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuJitterShape contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuJitterShape


% --- Executes during object creation, after setting all properties.
function popupmenuJitterShape_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuJitterShape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuFilterType.
function popupmenuFilterType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuFilterType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filterTypeList = get(handles.popupmenuFilterType, 'String');
filterType = filterTypeList{get(handles.popupmenuFilterType, 'Value')};
if (strcmp(filterType, 'Transition Time'))
    set(handles.textNsymAlpha, 'Visible', 'off');
    set(handles.editNsym, 'Visible', 'off');
    set(handles.editAlpha, 'Visible', 'off');
    set(handles.sliderTransitionTime, 'Visible', 'on');
    set(handles.editTransitionTime, 'Visible', 'on');
    set(handles.textTransitionTime, 'Visible', 'on');
else
    set(handles.textNsymAlpha, 'Visible', 'on');
    set(handles.editNsym, 'Visible', 'on');
    set(handles.editAlpha, 'Visible', 'on');
    set(handles.sliderTransitionTime, 'Visible', 'off');
    set(handles.editTransitionTime, 'Visible', 'off');
    set(handles.textTransitionTime, 'Visible', 'off');
    if (strcmp(filterType, 'Gaussian'))
        set(handles.textNsymAlpha, 'String', 'Nsym / BT');
    else
        set(handles.textNsymAlpha, 'String', 'Nsym / Alpha');
    end
end


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



function editNsym_Callback(hObject, eventdata, handles)
% hObject    handle to editNsym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (~isempty(value) && (isscalar(value) && floor(value) == value && min(value) >= 1 && max(value) <= 500))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNsym_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNsym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAlpha_Callback(hObject, eventdata, handles)
% hObject    handle to editAlpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (~isempty(value) && (isscalar(value) && min(value) > 0 && max(value) <= 50))
    try
        filterNsym = evalin('base', get(handles.editNsym, 'String'));
        recommendedNsym = 4 * round(10 / sqrt(value));
        if (filterNsym < recommendedNsym)
            set(handles.editNsym, 'String', sprintf('%d', recommendedNsym));
        end
    catch; end;
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
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
