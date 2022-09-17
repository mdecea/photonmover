function varargout = duc_ctrl(varargin)
% DUC_CTRL MATLAB code for duc_ctrl.fig
%      DUC_CTRL, by itself, creates a new DUC_CTRL or raises the existing
%      singleton*.
%
%      H = DUC_CTRL returns the handle to a new DUC_CTRL or the handle to
%      the existing singleton*.
%
%      DUC_CTRL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DUC_CTRL.M with the given input arguments.
%
%      DUC_CTRL('Property','Value',...) creates a new DUC_CTRL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before duc_ctrl_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to duc_ctrl_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help duc_ctrl

% Last Modified by GUIDE v2.5 13-Jun-2015 21:23:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @duc_ctrl_OpeningFcn, ...
                   'gui_OutputFcn',  @duc_ctrl_OutputFcn, ...
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


% --- Executes just before duc_ctrl is made visible.
function duc_ctrl_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to duc_ctrl (see VARARGIN)

% Choose default command line output for duc_ctrl
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

if (~iqoptcheck([], 'DUC', 'DUC'))
    close(handles.iqtool);
    return;
end
f = iqopen();
if (isempty(f))
    close(handles.iqtool);
else
    try
        a = query(f, ':carr:freq?');
        b = eval(['[' strtrim(a) ']']);
        c = eval(query(f, ':carr:scale?'));
        set(handles.sliderFreq, 'Value', b(1));
        sliderFreq_Callback([], [], handles);
        set(handles.sliderAmpl, 'Value', c(1));
        sliderAmpl_Callback([], [], handles);
    catch ex
    end
end

% UIWAIT makes duc_ctrl wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = duc_ctrl_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;


% --- Executes on slider movement.
function sliderFreq_Callback(hObject, eventdata, handles)
% hObject    handle to sliderFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.sliderFreq, 'Value');
set(handles.editFreq, 'String', iqengprintf(val, 10));
editFreq_Callback([], eventdata, handles);

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
function sliderAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to sliderAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.sliderAmpl, 'Value');
set(handles.editAmpl, 'String', iqengprintf(val));
editAmpl_Callback([], eventdata, handles);


% --- Executes during object creation, after setting all properties.
function sliderAmpl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFreq as text
%        str2double(get(hObject,'String')) returns contents of editFreq as a double
val = [];
try
    val = eval(get(handles.editFreq, 'String'));
catch ex
    errordlg(ex.message);
end
if (isscalar(val) && isreal(val) && ...
        val >= get(handles.sliderFreq, 'Min') && val <= get(handles.sliderFreq, 'Max'))
    set(handles.sliderFreq, 'Value', val);
    set(handles.editFreq, 'Background', 'White');
    f = iqopen();
    xfprintf(f, sprintf(':carr1:freq %.0f,%g', floor(val), val - floor(val)));
    xfprintf(f, sprintf(':carr2:freq %.0f,%g', floor(val), val - floor(val)));
%    fclose(f);
else
    set(handles.editFreq, 'Background', 'Red');
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



function editAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to editAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmpl as text
%        str2double(get(hObject,'String')) returns contents of editAmpl as a double
val = [];
try
    val = eval(get(handles.editAmpl, 'String'));
catch ex
    errordlg(ex.message);
end
if (isscalar(val) && isreal(val) && ...
        val >= get(handles.sliderAmpl, 'Min') && val <= get(handles.sliderAmpl, 'Max'))
    set(handles.sliderAmpl, 'Value', val);
    set(handles.editAmpl, 'Background', 'White');
    f = iqopen();
    xfprintf(f, sprintf(':carr1:scale %g', val));
    xfprintf(f, sprintf(':carr2:scale %g', val));
%    fclose(f);
else
    set(handles.editAmpl, 'Background', 'Red');
end


% --- Executes during object creation, after setting all properties.
function editAmpl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored

% un-comment the following line to see a trace of commands
%    fprintf('cmd = %s\n', s);
    fprintf(f, s);
    result = query(f, ':syst:err?');
    if (isempty(result))
        fclose(f);
        errordlg('Instrument did not respond to :SYST:ERR query. Check the instrument.', 'Error');
        error(':syst:err query failed');
    end
    if (~exist('ignoreError', 'var'))
        if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
            errordlg({'Instrument returns an error on command:' s 'Error Message:' result});
        end
    end
    



function editAmplFormula_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmplFormula as text
%        str2double(get(hObject,'String')) returns contents of editAmplFormula as a double


% --- Executes during object creation, after setting all properties.
function editAmplFormula_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFreqFormula_Callback(hObject, eventdata, handles)
% hObject    handle to editFreqFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFreqFormula as text
%        str2double(get(hObject,'String')) returns contents of editFreqFormula as a double
if (strcmp(get(handles.editFreqFormula, 'String'), ''))
    set(handles.editFreq, 'Enable', 'off');
    set(handles.sliderFreq, 'Enable', 'off');
else
    set(handles.editFreq, 'Enable', 'on');
    set(handles.sliderFreq, 'Enable', 'on');
end

% --- Executes during object creation, after setting all properties.
function editFreqFormula_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFreqFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCycleTime_Callback(hObject, eventdata, handles)
% hObject    handle to editCycleTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCycleTime as text
%        str2double(get(hObject,'String')) returns contents of editCycleTime as a double


% --- Executes during object creation, after setting all properties.
function editCycleTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCycleTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxAmpl.
function checkboxAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAmpl
val = get(handles.checkboxAmpl, 'Value');
if (val)
    set(handles.editAmplFormula, 'Enable', 'On');
else
    set(handles.editAmplFormula, 'Enable', 'Off');
end

% --- Executes on button press in checkboxFreq.
function checkboxFreq_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxFreq
val = get(handles.checkboxFreq, 'Value');
if (val)
    set(handles.editFreqFormula, 'Enable', 'On');
    set(handles.editFreq, 'Enable', 'Off');
    set(handles.sliderFreq, 'Enable', 'Off');
else
    set(handles.editFreqFormula, 'Enable', 'Off');
    set(handles.editFreq, 'Enable', 'On');
    set(handles.sliderFreq, 'Enable', 'On');
end




function editPhaseFormula_Callback(hObject, eventdata, handles)
% hObject    handle to editPhaseFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPhaseFormula as text
%        str2double(get(hObject,'String')) returns contents of editPhaseFormula as a double


% --- Executes during object creation, after setting all properties.
function editPhaseFormula_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPhaseFormula (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxPhase.
function checkboxPhase_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxPhase


% --- Executes on button press in pushbuttonCoherentPulses.
function pushbuttonCoherentPulses_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCoherentPulses (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (iqoptcheck([], 'DUC', 'DUC'))
    arbConfig = loadArbConfig();
    arbConfig.model = 'M8190A_DUC_x3';
    arbConfig = loadArbConfig(arbConfig);   % call loadArbConfig again to update all the parameters
    fs = arbConfig.defaultSampleRate;
    iqdata = iqpulse('arbConfig', arbConfig, 'sampleRate', fs, ...
        'PRI', 50e-6, 'PW', 300e-9, 'risetime', 50e-9, 'falltime', 50e-9, ...
        'offset', 0, 'span', 40e6);
    iqdownload(iqdata, fs, 'run', 0, 'keepOpen', 1, 'arbConfig', arbConfig);
    f = iqopen();
    val = 2;
    xfprintf(f, sprintf(':carr1:scale %g', 2));
    xfprintf(f, sprintf(':carr2:scale %g', 2));
    
    % overall time for the loop
    loopTime = 8;
    % delete action table
    iqseq('actionDeleteAll', 'arbConfig', arbConfig);
    % define actions
    dp = 180 / round(loopTime/2 * fs / length(iqdata) / arbConfig.interpolationFactor);
    a1 = iqseq('actionDefine', { 'CFR', 20e6, 'PRES', 0, 'AMPL', 1.0 });
    a2 = iqseq('actionDefine', { 'PBUM', -dp });
    a3 = iqseq('actionDefine', { 'PBUM', dp });

    a2x = iqseq('actionAppend', { a2, 'PBUM', 0 }, 'channelMapping', [0 0; 1 1]);
    a3x = iqseq('actionAppend', { a3, 'PBUM', 0 }, 'channelMapping', [0 0; 1 1]);
    clear seq;
    i = 1;
    seq(i).segmentNumber = 1;
    seq(i).actionID = a1;
    seq(i).markerEnable = 0;
    seq(i).sequenceInit = 1;
    i = i + 1;
    seq(i).segmentNumber = 1;
    seq(i).markerEnable = 1;
    seq(i).segmentLoops = 1;
    seq(i).sequenceEnd = 1;
    i = i + 1;
    seq(i).segmentNumber = 1;
    seq(i).actionID = a2;
    seq(i).markerEnable = 0;
    seq(i).sequenceInit = 1;
    seq(i).sequenceLoops = round(loopTime/2 * fs / length(iqdata) / arbConfig.interpolationFactor);
    seq(i).sequenceAdvance = 'Auto';
    i = i + 1;
    seq(i).segmentNumber = 1;
    seq(i).markerEnable = 1;
    seq(i).sequenceEnd = 1;
    i = i + 1;
    seq(i).segmentNumber = 1;
    seq(i).actionID = a3;
    seq(i).markerEnable = 0;
    seq(i).sequenceLoops = round(loopTime/2 * fs / length(iqdata) / arbConfig.interpolationFactor);
    seq(i).sequenceInit = 1;
    i = i + 1;
    seq(i).segmentNumber = 1;
    seq(i).markerEnable = 1;
    seq(i).segmentLoops = 1;
    seq(i).sequenceEnd = 1;
    seq(i).scenarioEnd = 1;
    % load the sequence and run in Scenario mode
    iqseq('define', seq, 'run', 0, 'arbConfig', arbConfig);
    iqseq('mode', 'STSC', 'arbConfig', arbConfig);
    setupScope();
end


% --- Executes on button press in pushbuttonCW.
function pushbuttonCW_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (iqoptcheck([], 'DUC', 'DUC'))
    arbConfig = loadArbConfig();
    fs = arbConfig.defaultSampleRate;
    iqdata = iqtone('sampleRate', fs, 'tone', linspace(-10e6, 10e6, 5));
    iqdownload(iqdata, fs, 'run', 0, 'keepOpen', 1);
    fcFormula = '1e9 + 50e6 * sin(2*pi*x)';
    ampFormula = '10.^(sin(2*2*pi*x)-1)';
    cycleTime = 4;
    doPreset(handles, fcFormula, ampFormula, cycleTime);
    setupSpectrum(1e9, 200e6, 1e6, []);
end

% --- Executes on button press in pushbuttonPulsedCW.
function pushbuttonPulsedCW_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPulsedCW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (iqoptcheck([], 'DUC', 'DUC'))
    arbConfig = loadArbConfig();
    iqdata = iqpulse('sampleRate', arbConfig.defaultSampleRate, ...
        'PRI', 1000e-9, 'PW', 40e-9, 'risetime', 0, 'falltime', 0, 'span', 0);
    iqdownload(iqdata, arbConfig.defaultSampleRate, 'run', 0, 'keepOpen', 1);
    fcFormula = '1e9';
    ampFormula = '(-1./2.1+0.5)./(cos(2*pi*x)./2.1+0.5)';
    cycleTime = 4;
    doPreset(handles, fcFormula, ampFormula, cycleTime);
    setupSpectrum(1e9, 0, 3e6, 8);
end


% --- Executes on button press in pushbuttonPulsedLFM.
function pushbuttonPulsedLFM_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPulsedLFM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (iqoptcheck([], 'DUC', 'DUC'))
    arbConfig = loadArbConfig();
    iqdata = iqpulse('sampleRate', arbConfig.defaultSampleRate, ...
        'PRI', 4000e-9, 'PW', 1000e-9, 'risetime', 0, 'falltime', 0, 'span', 50e6);
    iqdownload(iqdata, arbConfig.defaultSampleRate, 'run', 0, 'keepOpen', 1);
    fcFormula = '1e9 - 50e6 * cos(2*pi*x)';
    ampFormula = '(-1./2.1+0.5)./(cos(2*pi*x)./2.1+0.5)';
    cycleTime = 4;
    doPreset(handles, fcFormula, ampFormula, cycleTime);
    setupSpectrum(1e9, 200e6, 300e3, []);
end


function doPreset(handles, fcFormula, ampFormula, cycleTime)
if (~isempty(fcFormula))
    set(handles.editFreqFormula, 'String', fcFormula);
    set(handles.checkboxFreq, 'Value', 1);
else
    set(handles.checkboxFreq, 'Value', 0);
end
if (~isempty(ampFormula))
    set(handles.editAmplFormula, 'String', ampFormula);
    set(handles.checkboxAmpl, 'Value', 1);
else
    set(handles.checkboxAmpl, 'Value', 0);
end
if (~isempty(cycleTime))
    set(handles.editCycleTime, 'String', iqengprintf(cycleTime));
end
checkboxFreq_Callback([], [], handles);
pushbuttonApply_Callback([], [], handles);


% --- Executes on button press in pushbuttonApply.
function pushbuttonApply_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonApply (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (iqoptcheck([], 'DUC', 'DUC'))
    cycleTime = evalin('base', get(handles.editCycleTime, 'String'));
    varyFc = get(handles.checkboxFreq, 'Value');
    varyAmpl = get(handles.checkboxAmpl, 'Value');
    fcFormula = get(handles.editFreqFormula, 'String');
    ampFormula = get(handles.editAmplFormula, 'String');
    if (~varyFc)
        fcFormula = [];
    end
    if (~varyAmpl)
        ampFormula = [];
    end
    setupSequence(handles, fcFormula, ampFormula, cycleTime);
end


function setupSequence(handles, fcFormula, ampFormula, cycleTime)
% number of entries in the amplitude & frequency table
n = 10000;
arbConfig = loadArbConfig();
try
    if (~isempty(fcFormula))
        eval(['fc_fct = @(x) ' fcFormula ';']);
    end
    if (~isempty(ampFormula))
        eval(['amp_fct = @(x) ' ampFormula ';']);
    end
catch ex
    errordlg(ex.message);
    return;
end
x = (1:n)/n;
try
    if (~isempty(fcFormula))
        fTable = fixlength(fc_fct(x),n);
    end
    if (~isempty(ampFormula))
        aTable = fixlength(amp_fct(x),n);
    end
catch ex
    errordlg(ex.message);
    return;
end
if (~isempty(ampFormula))
    if (min(aTable) < 0)
        errordlg(sprintf('Amplitude formula results in a value less than 0 (%g)', min(aTable)));
        return;
    end
    if (max(aTable) > 1)
        errordlg(sprintf('Amplitude formula results in a value larger than 1 (%g)', max(aTable)));
        return;
    end
end
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
if (~isempty(ampFormula))
    iqseq('amplitudeTable', aTable, 'arbConfig', arbConfig, 'keepopen', 1);
end
if (~isempty(fcFormula))
    fTable = round(fTable);
    iqseq('frequencyTable', fTable, 'arbConfig', arbConfig, 'keepopen', 1);
end
% find out how long segment #1 is
len = arbConfig.minimumSegmentSize;
try
f = iqopen(arbConfig);
s = sscanf(query(f, sprintf(':TRACe%d:CATalog?', 1)), '%d,');
s = reshape(s,2,length(s)/2);
if (s(1,1) ~= 0)
    len = s(2,1);
end
catch (ex)
    disp(s);
end
clear seq;
segLoop = round(cycleTime * arbConfig.defaultSampleRate / n / len);
i = 1;
seq(i).segmentNumber = 1;
seq(i).segmentLoops = segLoop;
seq(i).markerEnable = true;
seq(i).segmentAdvance = 'Auto';
seq(i).amplitudeInit = ~isempty(ampFormula);
seq(i).frequencyInit = ~isempty(fcFormula);
seq(i).sequenceInit = 1;
seq(i).sequenceEnd = 1;
i = i + 1;
seq(i).segmentNumber = 1;
seq(i).segmentLoops = floor(segLoop / 2);
seq(i).markerEnable = false;
seq(i).segmentAdvance = 'Auto';
seq(i).amplitudeNext = ~isempty(ampFormula);
seq(i).frequencyNext = ~isempty(fcFormula);
seq(i).sequenceInit = 1;
seq(i).sequenceLoops = n - 1;
i = i + 1;
seq(i).segmentNumber = 1;
seq(i).segmentLoops = floor(segLoop / 2);
seq(i).markerEnable = false;
seq(i).segmentAdvance = 'Auto';
seq(i).sequenceEnd = 1;
seq(i).scenarioEnd = 1;
iqseq('define', seq, 'arbConfig', arbConfig, 'keepopen', 1, 'run', 0);
iqseq('dynamic', 0, 'arbConfig', arbConfig, 'keepopen', 1);
iqseq('mode', 'STSCenario', 'arbConfig', arbConfig);
try
    close(hMsgBox)
catch ex
end

function x = fixlength(x, len)
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);


function setupSpectrum(fc, span, resbw, sweeptime)
[arbConfig saConfig] = loadArbConfig();
if (saConfig.connected)
    f = iqopen(saConfig);
    if (~isempty(f))
        fprintf(f, sprintf(':FREQuency:CENTer %g', fc));
        fprintf(f, sprintf(':FREQuency:SPAN %g', span));
        fprintf(f, sprintf(':BWID %g', resbw));
        fprintf(f, sprintf(':BWID:VID:AUTO ON'));
        if (sweeptime ~= 0)
            fprintf(f, sprintf(':SWEep:TIME %g', sweeptime));
        else
            fprintf(f, sprintf(':SWEep:TIME:AUTO ON'));
        end
        fprintf(f, sprintf(':INIT:RESTart'));
        fclose(f);
    else
        msgbox('Please observe AWG channel 1 on a spectrum analyzer');
    end
else
    msgbox('Please observe AWG channel 1 on a spectrum analyzer');
end


function setupScope()
arbConfig = loadArbConfig();
if ((~isfield(arbConfig, 'isScopeConnected') || (isfield(arbConfig, 'isScopeConnected') && arbConfig.isScopeConnected ~= 0)) && isfield(arbConfig, 'visaAddrScope'))
    scopeCfg.visaAddr = arbConfig.visaAddrScope;
    scopeCfg.connectionType = 'visa';
    f = iqopen(scopeCfg);
    if (~isempty(f))
        fprintf(f, ':meas:clear');
        offs = 0;
        scale = 100e-3;
        for i = [1 2]
            fprintf(f, sprintf(':chan%d:disp on', i));
            fprintf(f, sprintf(':chan%d:offs %g', i, offs));
            fprintf(f, sprintf(':chan%d:scale %g', i, scale));
        end
        fprintf(f, sprintf(':timebase:scal %g', 50e-9));
        fprintf(f, sprintf(':trig:mode edge'));
        fprintf(f, sprintf(':trig:edge:slope positive'));
        fprintf(f, sprintf(':trig:hold 30e-6'));
        trigLev = 100e-3;
        fprintf(f, sprintf(':trig:edge:source chan2'));
        fprintf(f, sprintf(':trig:lev chan2,%g', trigLev));
        fprintf(f, sprintf(':timebase:del %g', 175e-9));
        fprintf(f, ':run');
        res = query(f, ':syst:err?');
        disp(res);
        fclose(f);
    end
end
msgbox('Please observe AWG channel 1 and 2 on an oscilloscope');


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
