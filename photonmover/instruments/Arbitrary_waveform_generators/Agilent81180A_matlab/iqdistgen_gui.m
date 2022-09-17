function varargout = iqdistgen_gui(varargin)
% IQDISTGEN_GUI MATLAB code for iqdistgen_gui.fig
%      IQDISTGEN_GUI, by itself, creates a new IQDISTGEN_GUI or raises the existing
%      singleton*.
%
%      H = IQDISTGEN_GUI returns the handle to a new IQDISTGEN_GUI or the handle to
%      the existing singleton*.
%
%      IQDISTGEN_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQDISTGEN_GUI.M with the given input arguments.
%
%      IQDISTGEN_GUI('Property','Value',...) creates a new IQDISTGEN_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqdistgen_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqdistgen_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqdistgen_gui

% Last Modified by GUIDE v2.5 07-Jun-2019 13:29:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqdistgen_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqdistgen_gui_OutputFcn, ...
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


% --- Executes just before iqdistgen_gui is made visible.
function iqdistgen_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqdistgen_gui (see VARARGIN)

% Choose default command line output for iqdistgen_gui
handles.output = hObject;

arbConfig = loadArbConfig();
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
checkfields([], [], handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqdistgen_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqdistgen_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editSampleRate_Callback(hObject, eventdata, handles)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editSampleRate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonChannelMapping.
function pushbuttonChannelMapping_Callback(hObject, eventdata, handles)
arbConfig = loadArbConfig();
[val, str] = iqchanneldlg(get(hObject, 'UserData'), arbConfig, handles.iqtool, {'Positive', 'Negative'});
if (~isempty(val))
    set(hObject, 'UserData', val);
    set(hObject, 'String', str);
end


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
[sigPos, sigNeg, fs] = calcSignal(handles);
assignin('base', 'sigPos', sigPos);
assignin('base', 'sigNeg', sigNeg);
if (~isempty(sigPos) && ~isempty(sigNeg))
    figure(1);
    fmt = '.-';
    len = min(2000, length(sigPos));
    xaxis = (0:len-1)/fs;
    subplot(2,2,1); plot(xaxis, sigPos(1:len), fmt); title('Positive');
    subplot(2,2,3); plot(xaxis, sigNeg(1:len), fmt); title('Negative');
    subplot(2,2,2); plot(xaxis, sigPos(1:len) - sigNeg(1:len), fmt); title('Differential');
    subplot(2,2,4); plot(xaxis, sigPos(1:len) + sigNeg(1:len), fmt); title('Common Mode');
end

% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
[sigPos, sigNeg, fs] = calcSignal(handles);
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
[sigPos, sigNeg, fs] = calcSignal(handles);
iqdownload(complex(sigPos, sigNeg), fs, 'channelMapping', channelMapping);
try
    close(hMsgBox);
catch
end


function editNoiseMagComm_Callback(hObject, eventdata, handles)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editNoiseMagComm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNoiseFreqComm_Callback(hObject, eventdata, handles)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editNoiseFreqComm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editToneMagComm_Callback(hObject, eventdata, handles)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editToneMagComm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editToneFreqComm_Callback(hObject, eventdata, handles)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editToneFreqComm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editToneFreqDiff_Callback(hObject, eventdata, handles)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editToneFreqDiff_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editToneMagDiff_Callback(hObject, eventdata, handles)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editToneMagDiff_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNoiseFreqDiff_Callback(hObject, eventdata, handles)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editNoiseFreqDiff_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNoiseMagDiff_Callback(hObject, eventdata, handles)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editNoiseMagDiff_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPoints_Callback(hObject, eventdata, handles)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editPoints_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function [sigPos, sigNeg, fs] = calcSignal(handles)
arbConfig = loadArbConfig();
[~, fs] = iqcheckfield(handles.editSampleRate, 'scalar', arbConfig.minimumSampleRate, arbConfig.maximumSampleRate);
[~, numSamples] = iqcheckfield(handles.editPoints, 'scalar, integer', arbConfig.minimumSegmentSize, arbConfig.maximumSegmentSize);
% --- ToneFreq
[~, toneFreqDiff] = iqcheckfield(handles.editToneFreqDiff, 'vector', 0, arbConfig.maximumSampleRate(1));
[~, toneFreqComm] = iqcheckfield(handles.editToneFreqComm, 'vector', 0, arbConfig.maximumSampleRate(1));
% --- ToneMag
[~, toneMagDiff] = iqcheckfield(handles.editToneMagDiff, 'vector', [], []);
[~, toneMagComm] = iqcheckfield(handles.editToneMagComm, 'vector', [], []);
% --- NoiseFreq
[~, noiseFreqDiff] = iqcheckfield(handles.editNoiseFreqDiff, 'vector', 0, arbConfig.maximumSampleRate(1));
[~, noiseFreqComm] = iqcheckfield(handles.editNoiseFreqComm, 'vector', 0, arbConfig.maximumSampleRate(1));
% --- NoiseMag
[~, noiseMagDiff] = iqcheckfield(handles.editNoiseMagDiff, 'scalar', [], []);
[~, noiseMagComm] = iqcheckfield(handles.editNoiseMagComm, 'scalar', [], []);
sigDiff = calcSig(fs, numSamples, toneFreqDiff, toneMagDiff, noiseFreqDiff, noiseMagDiff);
sigComm = calcSig(fs, numSamples, toneFreqComm, toneMagComm, noiseFreqComm, noiseMagComm);
sigPos = (sigComm + sigDiff)/2;
sigNeg = (sigComm - sigDiff)/2;
scale = max(max(abs(sigPos)), max(abs(sigNeg)));
sigPos = sigPos / scale;
sigNeg = sigNeg / scale;


function sig = calcSig(fs, numSamples, toneFreq, toneMag, noiseFreq, noiseMag)
% calculate a signal based on tone frequencies/magnitudes and noise
% frequencies and magnitude
sig = real(iqtone('sampleRate', fs, 'numSamples', numSamples, 'tone', toneFreq, 'magnitude', toneMag, 'nowarning', 1, 'normalize', 0));
sig = reshape(sig, numSamples, 1);
if (length(noiseFreq) >= 2)
    startFreq = noiseFreq(1);
    stopFreq = noiseFreq(2);
elseif (length(noiseFreq) >= 1)
    startFreq = 0;
    stopFreq = noiseFreq(1);
else
    startFreq = 0;
    stopFreq = fs/2;
end
sig = sig + 10^(noiseMag/20) * real(iqnoise('sampleRate', fs, 'numSamples', numSamples, 'start', startFreq, 'stop', stopFreq)); 


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
arbConfig = loadArbConfig();

iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig, {'Positive', 'Negative'});
% --- editSampleRate
result = result && iqcheckfield(handles.editSampleRate, 'scalar', arbConfig.minimumSampleRate, arbConfig.maximumSampleRate);
% --- editPoints
result = result && iqcheckfield(handles.editPoints, 'scalar, integer', arbConfig.minimumSegmentSize, arbConfig.maximumSegmentSize);
% --- ToneFreq
result = result && iqcheckfield(handles.editToneFreqDiff, 'vector', 0, arbConfig.maximumSampleRate(1));
result = result && iqcheckfield(handles.editToneFreqComm, 'vector', 0, arbConfig.maximumSampleRate(1));
% --- ToneMag
result = result && iqcheckfield(handles.editToneMagDiff, 'vector', [], []);
result = result && iqcheckfield(handles.editToneMagComm, 'vector', [], []);
% --- NoiseFreq
result = result && iqcheckfield(handles.editNoiseFreqDiff, 'vector', 0, arbConfig.maximumSampleRate(1));
result = result && iqcheckfield(handles.editNoiseFreqComm, 'vector', 0, arbConfig.maximumSampleRate(1));
% --- NoiseMag
result = result && iqcheckfield(handles.editNoiseMagDiff, 'scalar', [], []);
result = result && iqcheckfield(handles.editNoiseMagComm, 'scalar', [], []);
