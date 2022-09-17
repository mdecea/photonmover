function varargout = FMCWRadarGui(varargin)
% FMCWRADARGUI MATLAB code for FMCWRadarGui.fig
%      FMCWRADARGUI, by itself, creates a new FMCWRADARGUI or raises the existing
%      singleton*.
%
%      H = FMCWRADARGUI returns the handle to a new FMCWRADARGUI or the handle to
%      the existing singleton*.
%
%      FMCWRADARGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FMCWRADARGUI.M with the given input arguments.
%
%      FMCWRADARGUI('Property','Value',...) creates a new FMCWRADARGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FMCWRadarGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FMCWRadarGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FMCWRadarGui

% Last Modified by GUIDE v2.5 02-Oct-2017 08:41:05

% Begin initialization code - DO NOT EDIT
% File Date : 22-1-2018
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FMCWRadarGui_OpeningFcn, ...
                   'gui_OutputFcn',  @FMCWRadarGui_OutputFcn, ...
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


% --- Executes just before FMCWRadarGui is made visible.
function FMCWRadarGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FMCWRadarGui (see VARARGIN)

% display background image
handles.output = hObject;
axes(handles.axesBackGnd);
icon=imread('background.png');
image(icon);
axis off;
axis image;

% initialize AWG
%check whether M8195A set in correct mode
if AWGConfig(handles) 
    %set(handles.textAWG_Warning,'String',''); 
    set(handles.pushbuttonsys_ConfigureSystem,'Enable','off');
    set(handles.pushbuttonsys_GenerateWaveform,'Enable','off');
    set(handles.pushbuttonsys_Calibrate,'Enable','off');
    set(handles.pushbuttonsys_Stop,'Enable','off');
else
    set(handles.textAWG_Warning,'String',' ');
    set(handles.pushbuttonsys_ConfigureSystem,'Enable','on');
    set(handles.pushbuttonsys_GenerateWaveform,'Enable','on');
    set(handles.pushbuttonsys_Calibrate,'Enable','on');
    set(handles.pushbuttonsys_Stop,'Enable','on');
end

%check lo source
set(handles.checkboxlo_Output,'Value',get(handles.checkboxlo_Output,'Max'));
if exist('LoConfig.mat', 'file') == 2
   load('LoConfig.mat');
   % display source model, works only with Keysight format
   idn=strsplit(loConfig.idn,',');
   inst_name=strtrim(idn(2));
   set(handles.textlo_ErrorMsg,'ForegroundColor','black');
   set(handles.textlo_ErrorMsg,'String',inst_name);
   set(handles.editlo_Address, 'String', loConfig.visaAddr);
   set(handles.editlo_Amplitude,'String',loConfig.minPower_dBm);
else
   set(handles.textlo_ErrorMsg,'ForegroundColor','red');
   set(handles.textlo_ErrorMsg,'String','??');
   set(handles.editlo_Amplitude,'String',-200);
   set(handles.editlo_Address, 'String', ' ');
   % create dummy source
   loConfig.idn='dummy';
   loConfig.visaAddr='???';
   loConfig.maxFrequency_Hz = 100;
   loConfig.minFrequency_Hz = 1;
   loConfig.maxPower_dBm = -40;
   loConfig.minPower_dBm = -100;
end

% store important lo param into userdata for access
set(handles.uipanellosource,'UserData',loConfig);
guidata(hObject, handles);

% UIWAIT makes FMCWRadarGui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);

% --- Outputs from this function are returned to the command line.
function varargout = FMCWRadarGui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function editawg_Amplitude_Callback(hObject, eventdata, handles)
% hObject    handle to editawg_Amplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editawg_Amplitude as text
%        str2double(get(hObject,'String')) returns contents of editawg_Amplitude as a double
minAmplitude = 0.075;
maxAmplitude = 1.0 ;
userAmplitude = str2double(get(hObject,'String'));
if userAmplitude > maxAmplitude
    userAmplitude=maxAmplitude;
elseif userAmplitude < minAmplitude
    userAmplitude=minAmplitude;
end
set(hObject, 'String', userAmplitude); 
arbConfig = loadArbConfig();
awg = iqopen(arbConfig);
fprintf(awg,[':VOLT1 ',iqengprintf(userAmplitude)]);
fclose(awg);


% --- Executes during object creation, after setting all properties.
function editawg_Amplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editawg_Amplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonwave_ViewWaveform.
function pushbuttonwave_ViewWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonwave_ViewWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% calculateparameters 
fs = 64e9;
pri = str2double(get(handles.editfmcw_PulseWidth,'String'));
span = str2double(get(handles.editfmcw_BW,'String'));
offset = str2double(get(handles.editfmcw_minImageSeparation,'String'))/2 + span/2 ;
correction = get(handles.checkboxwave_ApplyCorrection,'Value');

symmchirp = get(handles.checkboxfmcw_symmchirp,'Value');
if symmchirp
   risetime = pri/2;  
   falltime = risetime ; 
else
   risetime = pri; 
   falltime = 0; 
end

[iqdata, marker] = iqpulse('sampleRate', fs, ...
    'PRI', pri, 'PW', 0, ...
    'riseTime', risetime, 'fallTime', falltime, ...
    'pulseShape', 'Trapezodial', 'span', span, 'offset', offset, ...
    'amplitude', 0, 'fmFormula', 'sin(2*pi*x)', 'pmFormula', '360*floor(x*4)/4', ...
    'modulationType', 'FMCW', 'correction', correction, 'delay', 0, 'phase', 0);
iqplot(iqdata, fs, 'spectrogram');

% --- Executes on button press in checkboxwave_ApplyCorrection.
function checkboxwave_ApplyCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxwave_ApplyCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxwave_ApplyCorrection


% --- Executes on button press in checkboxawg_Output.
function checkboxawg_Output_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxawg_Output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxawg_Output
arbConfig = loadArbConfig();
awg = iqopen(arbConfig);
if ( ~isempty(awg) )
    if ( get(hObject,'Value'))
        fprintf(awg,':OUTP1 ON');
     else
        fprintf(awg,':OUTP1 OFF');
    end
    fclose(awg);
end

% --- Executes on button press in checkboxawg_Marker.
function checkboxawg_Marker_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxawg_Marker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxawg_Marker
arbConfig = loadArbConfig();
awg = iqopen(arbConfig);
if ( ~isempty(awg) )
    if ( get(hObject,'Value'))
        fprintf(awg,':OUTP4 ON');
     else
        fprintf(awg,':OUTP4 OFF');
    end
    fclose(awg);
end

% --- Executes on selection change in popupmenuUpConverter.
function popupmenuUpConverter_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuUpConverter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuUpConverter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuUpConverter


% --- Executes during object creation, after setting all properties.
function popupmenuUpConverter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuUpConverter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% Create Mixer Data List for pop up menu
% Please don't change.
mixer1 = struct('mfg','HXI','model','HBUC1206-79','GaindB',-8.5,'Pin1dB',10,'LoPowerdBm',10 , ...
                'LoFreqMaxHz',75.0e9,'LoFreqMinHz',75.0e9,'IfFreqMaxHz',6.0e9,'IfFreqMinHz',2.0e9, ...
                'LoMulFactor',4 );
mixer2 = struct('mfg','HXI','model','HBUC1206-76','GaindB',-8.5,'Pin1dB',10,'LoPowerdBm',10 , ...
                'LoFreqMaxHz',71.4e9,'LoFreqMinHz',71.4e9,'IfFreqMaxHz',5.6e9,'IfFreqMinHz',4.6e9, ...
                'LoMulFactor',4 );
            
mixer3 = struct('mfg','VDI','model','N9029ACST-U12','GaindB',-10,'Pin1dB',-15,'LoPowerdBm',5 , ...
                'LoFreqMaxHz',90.0e9,'LoFreqMinHz',60.0e9,'IfFreqMaxHz',12.0e9,'IfFreqMinHz',0.0, ...
                'LoMulFactor',2 );
mixer4 = struct('mfg','Sage','model','SFU-12-N1','GaindB',-9,'Pin1dB',0,'LoPowerdBm',10 , ...
                'LoFreqMaxHz',90.0e9,'LoFreqMinHz',60.0e9,'IfFreqMaxHz',30.0e9,'IfFreqMinHz',0.0, ...
                'LoMulFactor',4 );
mixers = [ mixer3, mixer1, mixer2, mixer4];

set(hObject,'UserData',mixers);
set(hObject,'String',{ mixers(1).model; mixers(2).model; mixers(3).model;mixers(4).model });


function editlocable_Loss_Callback(hObject, eventdata, handles)
% hObject    handle to editlocable_Loss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editlocable_Loss as text
%        str2double(get(hObject,'String')) returns contents of editlocable_Loss as a double


% --- Executes during object creation, after setting all properties.
function editlocable_Loss_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editlocable_Loss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editlo_Amplitude_Callback(hObject, eventdata, handles)
% hObject    handle to editlo_Amplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editlo_Amplitude as text
%        str2double(get(hObject,'String')) returns contents of editlo_Amplitude as a double

loSource=get(handles.uipanellosource,'UserData');
minPower = loSource.minPower_dBm;
maxPower = loSource.maxPower_dBm ;
userPower = str2double(get(hObject,'String'));
if userPower > maxPower
    userPower=maxPower;
elseif userPower < minPower
    userPower=minPower;
end
 set(hObject, 'String', iqengprintf(userPower)); 
 SetLoPower(handles);


% --- Executes during object creation, after setting all properties.
function editlo_Amplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editlo_Amplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in checkboxlo_Output.
function checkboxlo_Output_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxlo_Output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxlo_Output
SetLoOutput(handles);
 

% --- Executes on button press in pushbuttonsys_ConfigureSystem.
function pushbuttonsys_ConfigureSystem_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonsys_ConfigureSystem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~checkfmcwViolation(handles)
    errordlg('Frequency not within automative band 76 to 81 GHz');
    return;
end
error= FMCWCalculateSystemSettings(handles);
if ~isempty(error)
    errordlg(error);
end

% --- Executes on button press in pushbuttonsys_Calibrate.
function pushbuttonsys_Calibrate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonsys_Calibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~checkfmcwViolation(handles)
    errordlg('Frequency not within automative band 76 to 81 GHz');
    return;
end
calmsg = sprintf('To proceed with calibration make sure that\n(1) Output of upconversion system is connected to a smart mixer&SA.\n(2) SA has already been set up with IQtools config.'); 
resp=questdlg(calmsg,'Calibration','Proceed','Cancel','Cancel');
if ~strcmp(resp,'Proceed')
   return; 
end
arbConfig = loadArbConfig();
awg = iqopen(arbConfig);
fprintf(awg,':ABOR'); 
set(handles.pushbuttonsys_GenerateWaveform,'BackgroundColor','default');
fclose(awg);

centerFreq = str2double(get(handles.editwave_centerFreq,'String'));
span = str2double(get(handles.editfmcw_BW,'String'));
% get mixer mulfactor
mixers = get(handles.popupmenuUpConverter,'UserData');
selection = get(handles.popupmenuUpConverter,'Value');
selectedmixer=mixers(selection);
freqoffset=str2double(get(handles.editlo_Frequency,'String'))*selectedmixer.LoMulFactor;
startFreq = centerFreq - span/2;
stopFreq = startFreq + span;
numTones = 101;
fs=64e9;
tone =  linspace(startFreq,stopFreq,numTones)';
magnitude = zeros(1,numTones) ;
set(handles.checkboxlo_Output,'Value',1);
SetLoOutput(handles);
iqdata=iqtone('sampleRate',fs,'numSamples',0,'tone',tone,'phase','Random','magnitude',magnitude,'correction',0);
iqdownload(iqdata,fs,'channelMapping',[1,0],'segmentNumber',1);
set(handles.checkboxawg_Output,'Value',1);
set(handles.checkboxawg_Marker,'Value',1);
hMsgBox = msgbox('Performing Calibration. Please wait...', 'Please wait...', 'replace');
res = iqcal('tone', tone, 'offset',freqoffset , 'recalibrate', 0 , 'method', 'zero span','msgbox', hMsgBox);


% --- Executes on button press in pushbuttonsys_GenerateWaveform.
function pushbuttonsys_GenerateWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonsys_GenerateWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~checkfmcwViolation(handles)
    errordlg('Frequency not within automative band 76 to 81 GHz');
    return;
end
% check instruments are connected
resp=FMCWTestAWG();
if isempty(resp)
    return;
end

resp = FMCWTestSource(handles);
if isempty(resp)
    return;
end

error= FMCWCalculateSystemSettings(handles);
if ~isempty(error)
    errordlg(error);
    return;
end
% set the LO source power
set(handles.checkboxlo_Output,'Value',1);
SetLoFrequency(handles);
SetLoPower(handles);
SetLoOutput(handles);
% generate waveform
fs = 64e9;
pri = str2double(get(handles.editfmcw_PulseWidth,'String'));
span = str2double(get(handles.editfmcw_BW,'String'));
offset = str2double(get(handles.editfmcw_minImageSeparation,'String'))/2 + span/2 ;
correction = get(handles.checkboxwave_ApplyCorrection,'Value');
symmchirp = get(handles.checkboxfmcw_symmchirp,'Value');
if symmchirp
   risetime = pri/2;  
   falltime = risetime ; 
else
   risetime = pri; 
   falltime = 0; 
end

[iqdata, marker] = iqpulse('sampleRate', fs, ...
    'PRI', pri, 'PW', 0, ...
    'riseTime', risetime, 'fallTime', falltime, ...
    'pulseShape', 'Trapezodial', 'span', span, 'offset', offset, ...
    'amplitude', 0, 'fmFormula', 'sin(2*pi*x)', 'pmFormula', '360*floor(x*4)/4', ...
    'modulationType', 'FMCW', 'correction', correction, 'delay', 0, 'phase', 0);


arbConfig = loadArbConfig();
awg = iqopen(arbConfig);

fprintf(awg,':ARM:TRIG:SOUR INT'); 
fprintf(awg,':TRIG:SOUR:ADV EVEN');
fprintf(awg,':TRIG:SOUR:ENAB TRIG' );
userAmplitude = str2double(get(handles.editawg_Amplitude,'String'));
fprintf(awg,[':VOLT1 ',iqengprintf(userAmplitude)]);
fprintf(awg,':INIT:IMM');
fclose(awg);

% if burst mode enabled need to program M8195a sequencer
enableburst = get(handles.checkboxfmcw_EnableBurst,'Value');
if enableburst
    iqdownload(iqdata, fs, 'channelMapping', [1 0], ...
    'segmentNumber', 1,'run',0, 'marker',[]);
    burst_period = str2double(get(handles.editfmcw_BurstPeriod,'String'));
    Npulse = str2double(get(handles.editfmcw_NumPulseperBurst,'String'));
    strburst_freq=num2str(1/burst_period);
    freqcomm=[':ARM:TRIG:FREQ ',strburst_freq];
    arbConfig = loadArbConfig();
    awg2 = iqopen(arbConfig);
    fprintf(awg2,freqcomm ); 
    fprintf(awg2,':INIT:CONT OFF'); % triggered with internal M8195 clock
    fclose(awg2); % note: need to close else issues with iqseq function
    % sequence ID 0
    seq(1).segmentNumber = 1;
    seq(1).sequenceLoops = Npulse;
    seq(1).markerEnable = 1;
    seq(1).sequenceInit = 1;
    seq(1).sequenceEnd = 1;
    seq(1).scenarioEnd = 1;
   
    % download the sequence table and run
    iqseq('define', seq, 'run', 0, 'keepOpen', 0);
    iqseq('mode', 'STSequence');
else
    %download and run staright away
    iqdownload(iqdata, fs, 'channelMapping', [1 0], ...
    'segmentNumber', 1,'run',1, 'marker',[]);
end
set(handles.checkboxawg_Output,'Value',1);
set(handles.checkboxawg_Marker,'Value',1);
set(handles.pushbuttonsys_GenerateWaveform,'BackgroundColor','green');


% --- Executes on button press in pushbuttonsys_Stop.
function pushbuttonsys_Stop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonsys_Stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resp=FMCWTestAWG();
if isempty(resp)
    return;
end

resp = FMCWTestSource(handles);
if isempty(resp)
    return;
end
arbConfig = loadArbConfig();
awg = iqopen(arbConfig);
fprintf(awg,':ABOR');
fprintf(awg,'*RST');
% good practice to turn of IF before LO
set(handles.checkboxlo_Output,'Value',0);
SetLoOutput(handles);
set(handles.pushbuttonsys_GenerateWaveform,'BackgroundColor','default');
fclose(awg);

function editfmcw_CenterFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editfmcw_CenterFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editfmcw_CenterFreq as text
%        str2double(get(hObject,'String')) returns contents of editfmcw_CenterFreq as a double
% store current value
centerFreq = str2double(get(hObject,'String'));
set(hObject, 'String', iqengprintf(centerFreq));
checkfmcwViolation(handles);

% --- Executes during object creation, after setting all properties.
function editfmcw_CenterFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editfmcw_CenterFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editfmcw_BW_Callback(hObject, eventdata, handles)
% hObject    handle to editfmcw_BW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editfmcw_BW as text
%        str2double(get(hObject,'String')) returns contents of editfmcw_BW as a double
minbandwidth = 50e6;
maxbandwidth = 5e9 ;
bandwidth = str2double(get(hObject,'String'));
if bandwidth < minbandwidth
    set(hObject, 'String', iqengprintf(minbandwidth));
elseif bandwidth > maxbandwidth
    set(hObject, 'String', iqengprintf(maxbandwidth));  
else
    set(hObject, 'String', iqengprintf(bandwidth)); 
end
checkfmcwViolation(handles);

% --- Executes during object creation, after setting all properties.
function editfmcw_BW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editfmcw_BW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editfmcw_PulseWidth_Callback(hObject, eventdata, handles)
% hObject    handle to editfmcw_PulseWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editfmcw_PulseWidth as text
%        str2double(get(hObject,'String')) returns contents of editfmcw_PulseWidth as a double
minlength = 6e-8; % determined by M8195A internal trigger max frequency, in case of burst mode
maxlength = 100e-6 ;
userlength = str2double(get(hObject,'String'));
if userlength > maxlength
    userlength=maxlength;
elseif userlength < minlength
    userlength=minlength;
end
 set(hObject, 'String', iqengprintf(userlength)); 

% --- Executes during object creation, after setting all properties.
function editfmcw_PulseWidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editfmcw_PulseWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editfmcw_NumPulseperBurst_Callback(hObject, eventdata, handles)
% hObject    handle to editfmcw_NumPulseperBurst (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editfmcw_NumPulseperBurst as text
%        str2double(get(hObject,'String')) returns contents of editfmcw_NumPulseperBurst as a double

fmcw_period = str2double(get(handles.editfmcw_PulseWidth,'String'));
burst_period = str2double(get(handles.editfmcw_BurstPeriod,'String'));
min_pulseN =1;
max_pulseN = floor(burst_period/fmcw_period);
% make sure that burst period exceeds total burst
N = round(str2double(get(hObject,'String')));
if N < min_pulseN
    N= min_pulseN;
end
if N > max_pulseN
    N = max_pulseN;
end
set(hObject,'String',N);

% --- Executes during object creation, after setting all properties.
function editfmcw_NumPulseperBurst_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editfmcw_NumPulseperBurst (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxfmcw_EnableBurst.
function checkboxfmcw_EnableBurst_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxfmcw_EnableBurst (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxfmcw_EnableBurst
if get(hObject,'Value')
   % make boxes related to burst mode editable 
   set( handles.editfmcw_NumPulseperBurst,'enable','on' );
   set( handles.editfmcw_BurstPeriod,'enable','on' );
else
    set( handles.editfmcw_NumPulseperBurst,'enable','off' );
   set( handles.editfmcw_BurstPeriod,'enable','off' ); 
end


function editfmcw_BurstPeriod_Callback(hObject, eventdata, handles)
% hObject    handle to editfmcw_BurstPeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editfmcw_BurstPeriod as text
%        str2double(get(hObject,'String')) returns contents of editfmcw_BurstPeriod as a double
burst_period = str2double(get(hObject,'String'));
fmcwpulsewidth = str2double(get(handles.editfmcw_PulseWidth,'String'));
Npulse = str2double(get(handles.editfmcw_NumPulseperBurst,'String'));

if (burst_period < Npulse*fmcwpulsewidth)
    burst_period = Npulse*fmcwpulsewidth ;
end
set(hObject,'String',iqengprintf(burst_period));
%burstperiod > N*fmcwperiod


% --- Executes during object creation, after setting all properties.
function editfmcw_BurstPeriod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editfmcw_BurstPeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editlo_Address_Callback(hObject, eventdata, handles)
% hObject    handle to editlo_Address (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editlo_Address as text
%        str2double(get(hObject,'String')) returns contents of editlo_Address as a double


% --- Executes during object creation, after setting all properties.
function editlo_Address_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editlo_Address (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbuttonlo_TestAddress.
function pushbuttonlo_TestAddress_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonlo_TestAddress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
FMCWTestSource(handles);

% helper function to determine M8195A , single channel mode is selected.
function error = AWGConfig(handles)

arbConfig = loadArbConfig();

if strcmpi(arbConfig.model(1:6),'M8195A') && arbConfig.numChannels == 1
   error=0;
   set(handles.pushbuttonawg_Config,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
else
   error=1;
   set(handles.pushbuttonawg_Config,'BackgroundColor','red');
end

 
function editfmcw_minImageSeparation_Callback(hObject, eventdata, handles)
% hObject    handle to editfmcw_minImageSeparation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editfmcw_minImageSeparation as text
%        str2double(get(hObject,'String')) returns contents of editfmcw_minImageSeparation as a double
min_allowableImageSeparation = 1.0e9;
value = str2double(get(hObject,'String'));
if value < min_allowableImageSeparation % min allowable image separation
    set(hObject,'String', iqengprintf(min_allowableImageSeparation));
    errordlg('Minimun allowable image separation is 1 GHz');
end
set(hObject,'BackgroundColor','White');

% --- Executes during object creation, after setting all properties.
function editfmcw_minImageSeparation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editfmcw_minImageSeparation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Checks whether requested fmcw signal is within the European 76 to 81 GHz band
function error = checkfmcwViolation(handles)
fmcwcenterFreq = str2double(get(handles.editfmcw_CenterFreq,'String'));
fmcwbandwidth = str2double(get(handles.editfmcw_BW,'String'));
lowfmcwFreq  = fmcwcenterFreq - fmcwbandwidth/2 ;
highfmcwFreq = fmcwcenterFreq + fmcwbandwidth/2 ;
if lowfmcwFreq < 76e9 || highfmcwFreq > 81e9 
    set( handles.editfmcw_CenterFreq,'BackgroundColor','red');
    error=0;
else
    set( handles.editfmcw_CenterFreq,'BackgroundColor','white');
    error=1;
end

function editlo_Frequency_Callback(hObject, eventdata, handles)
% hObject    handle to editlo_Frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editlo_Frequency as text
%        str2double(get(hObject,'String')) returns contents of editlo_Frequency as a double


% --- Executes during object creation, after setting all properties.
function editlo_Frequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editlo_Frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editwave_centerFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editwave_centerFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editwave_centerFreq as text
%        str2double(get(hObject,'String')) returns contents of editwave_centerFreq as a double


% --- Executes during object creation, after setting all properties.
function editwave_centerFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editwave_centerFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonUpConverter_Info.
function pushbuttonUpConverter_Info_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUpConverter_Info (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mixers = get(handles.popupmenuUpConverter,'UserData');
selection = get(handles.popupmenuUpConverter,'Value');
selectedmixer=mixers(selection);
line0 = strcat(['Mixer Manufacturer: ',selectedmixer.mfg] );
line1 = strcat(['LO port Minimum Frequency : ',iqengprintf(selectedmixer.LoFreqMinHz),' Hz'] );
line2 = strcat(['LO port Maximun Frequency : ',iqengprintf(selectedmixer.LoFreqMaxHz),' Hz'] );
line3 = strcat(['LO port multiplication factor : ',iqengprintf(selectedmixer.LoMulFactor)] );
line4 = strcat(['IF port Minimum Frequency : ',iqengprintf(selectedmixer.IfFreqMinHz),' Hz'] );
line5 = strcat(['IF port Maximun Frequency : ',iqengprintf(selectedmixer.IfFreqMaxHz),' Hz'] );
msgbox({line0,line1,line2,line3,line4,line5});


% --- Executes on button press in pushbuttonawg_Config.
function pushbuttonawg_Config_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonawg_Config (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqconfig;

% Miscelleneous internal helper functions

function status = SetLoPower(handles)
lo = GetSourceHandle(handles);
if isempty(lo)
    status=0;
    return;
end
strpower = get(handles.editlo_Amplitude,'String');
comstr = [':SOUR:POW ',strpower];
fprintf(lo,comstr);
fclose(lo);
status=1;

function status = SetLoFrequency(handles)
lo = GetSourceHandle(handles);
if isempty(lo)
    status=0;
    return;
end
strpower = get(handles.editlo_Frequency,'String');
comstr = [':SOUR:FREQ ',strpower];
fprintf(lo,comstr);
fclose(lo);
status=1;


function status =SetLoOutput(handles)
lo = GetSourceHandle(handles);
if isempty(lo)
    status=0;
    return;
end
if get(handles.checkboxlo_Output,'Value')
    fprintf(lo,':OUTP ON');
else
    fprintf(lo,':OUTP OFF');
    
end
fclose(lo);
status=1;
    

function sourceh = GetSourceHandle(handles)
lo_addr = get(handles.editlo_Address,'String'); 
try
    sourceh = visa('agilent', lo_addr );
catch e
    errordlg('Source Invalid addr' );
    sourceh=[];
    return;
end

try
    fopen(sourceh);
catch e
      errordlg('Please connect source to AWG system controller' );
      set(handles.pushbuttonlo_TestAddress,'BackgroundColor','red');
      sourceh=[];
      return;
end


% --- Executes on button press in pushbuttonwave_ViewCorrection.
function pushbuttonwave_ViewCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonwave_ViewCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqcorrmgmt();


% --- Executes during object creation, after setting all properties.
function textfmcw_NumPulseperBurst_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textfmcw_NumPulseperBurst (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in checkboxfmcw_symmchirp.
function checkboxfmcw_symmchirp_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxfmcw_symmchirp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxfmcw_symmchirp
