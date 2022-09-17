function varargout = iqofdm_gui(varargin)
% iqofdm_gui M-file for iqmod_gui.fig
%      iqofdm_gui, by itself, creates a new iqofdm_gui or raises the existing
%      singleton*.
%
%      H = iqofdm_gui returns the handle to a new iqofdm_gui or the handle to
%      the existing singleton*.
%
%      iqofdm_gui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in iqofd,_gui.m with the given input arguments.
%
%      iqofdm_gui('Property','Value',...) creates a new iqofdm_gui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqofdm_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqofdm_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu. Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqofdm_gui

% Last Modified by GUIDE v2.5 04-May-2015 11:14:00


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqofdm_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqofdm_gui_OutputFcn, ...
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


% --- Executes just before iqmod_gui is made visible.
function iqofdm_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqmod_gui (see VARARGIN)
% Choose default command line output for iqmod_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% Load the ODFM preset
IEEEPreset (hObject, eventdata, handles);
% use default upconversion if specified
arbConfig = loadArbConfig();
if (isfield(arbConfig, 'defaultFc') && arbConfig.defaultFc ~= 0)
    set(handles.editCarrierFrequency, 'String', iqengprintf(0));
    set(handles.editFc, 'String', iqengprintf(arbConfig.defaultFc));
    set(handles.editOFDMSystemFrequency, 'String', iqengprintf(100e6));
end
% make sure all the fields are consistent
checkfields(hObject, 0, handles);
% set model-specific parameters
switch arbConfig.model
    case 'M8195A_Rev1'
        set(handles.editNumPackages, 'String', '4');
end
if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'Enter the AWG sample rate in Hertz. For simulation, the sample rate\n' ...
    'to stay within the range that is supported by the AWG.']));
set(handles.editOFDMSystemFrequency, 'TooltipString', sprintf([ ...
    'Sample Rate for the OFDM Signal in Herz, value is used by VSA software for OFDM decoding, \n' ...
    'OFDM system frequency must be smaller than AWG sample rate, \n' ...
    'Waveform generator sample rate = OFDM system frequency * oversampling factor']));
set(handles.editOversampling, 'TooltipString', sprintf([ ...
    'This field defines the ratio of sampling rate vs. OFDM system frequency.\n' ...
    'It is recommended that oversampling is used as an integer number, it is necessary that oversampling is greater than one.\n' ...
    'Normally it is not necessary to set this field since it will be automatically calculated based on\n' ...
    'sampling rate and ODFM system frequency.']));
set(handles.editResourceMap, 'TooltipString', sprintf([ ...
    'Specifies the type of each "resource" (each used subcarrier and symbol time).\n' ...
    '0=Data, 1=Pilot, 2=Unknown Pilot, 3=Preamble, 4=Null, 5=Unspecified']));
set(handles.editResourceModulation, 'TooltipString', sprintf([ ...
    'Specifies the modulation used on each "resource" (each used subcarrier and symbol time). \n' ...
    'Each value in this array is an index into the Quam Identifier array']));
set(handles.editQuamLevels, 'TooltipString', sprintf([ ...
    'Each entry specifies a type of modulation,\n' ...
    '0=Unknown (BPSK is used), 1=BPSK, 2=QPSK, 3=8-PSK, 4=16-QAM, 5=32-QAM, 6=64QAM, ... 10=1024-QAM']));
set(handles.editPilotDefinitions, 'TooltipString', sprintf([ ...
    'Specifies the values of the pilot subcarriers (real part first, then imaginary part).\n' ...
    'Each pilot should be a valid point in the constellation diagram of the modulation used for that pilot']));
set(handles.editResourceRepeatIndex, 'TooltipString', sprintf([ ...
    'Loop back to the symbol defined by Resource Repeat Index after creation of the last symbol defined by Resource Map, \n' ...
    'Value must be 0,1,...N-1, if N Symbols per Resource Map Entry are defined (0 for a loop back including first symbol).']));
set(handles.editBurstInterval, 'TooltipString', sprintf([ ...
    'Defines if there is a pause in the OFDM signal after the creation of the N symbols\n' ...
    'given by the Value in the Number of Symbols (all) control element. \n' ...
    'The length of the the pause must be defined in seconds, if 0 is selected no pause is used.']));
set(handles.checkboxCreateRandomData, 'TooltipString', sprintf([ ...
    'OFDM signal is created using random data when the value is set. \n' ...
    'If not set, the binary data pattern which is written in the Binary Data Stream text field, \n' ...
    'is modulated during the OFDM signal generation. \n' ...
    'In this case, the pattern used for OFDM signal generation can be defined by the user.  \n' ... 
    'To define a pattern, a sequence of values 0 and 1 must be written in the Binary Data Stream text field,\n' ...
    'a comma must be used between two numbers. \n' ... 
    'A user defined pattern is repeated or cutted during the OFDM signal generation if necessary.' ]));
set(handles.editBinaryData, 'TooltipString', sprintf([ ...
    'The binary data created during an OFDM signal generation is shown here after calculation,\n' ...
    'if Create Random Data is not selected, the pattern used for OFDM signal generation must be typed here before calculation \n' ... 
    '(patten repeated or cutted if necessary).']));
set(handles.editCarrierFrequency, 'TooltipString', sprintf([ ...
    'If Carrier Offset is greater than zero, the OFDM signal is created as a real time signal. \n' ...
    'If the complex OFDM signal is s(t)=s1(t)+js2(t), the real OFDM signal s(t)=s1(t)*cos(2*pi*Carrier Offset)-s2(t)j*sin(2*pi*Carrier Offset) is created. \n' ...
    'In this case only one AWG channel for the OFDM transmission can be used. \n' ...
    'If Carrier Offset is zero, the complex OFDM signal is s(t)=s1(t)+js2(t) calculated. \n' ...
    'In this case the real part of the OFDM signal is downloaded to channel 1 of the AWG and the imaginary part to channel 2 of the AWG.']));
set(handles.checkboxCorrection, 'TooltipString', sprintf([ ...
    'Correction of spectrum if selected,\n' ...
    'for correction the results of the amplitude correction done with OFDM Modulations GUI are used. \n']));
set(handles.editNumberOfSymbols, 'TooltipString', sprintf([ ...
    'Defines the number of symbols which are created when download or display is used.\n' ...
    'With Resource Map a number of N OFDM symbols is defined, with Number of Symbols (all), \n' ... 
    'the user selects how many OFDM symbols are created on the whole. \n' ...
    'If the N symbols defined via Resource Map have been created, the creation of the \n' ...
    'OFDM symbol is continued beginning from the symbol which is defined by Resource Repeat Index,\n' ...
    'this is done till all symbols defined in Number of Symbols (all) have been created.']));
set(handles.editNumPackages, 'TooltipString', sprintf([ ...
    'How many different packages of ODFM data with each having N=Number of Symbols (all) Symbols are created, \n' ...
    'between two packages a pause is used, if Signal is Bursted is selected.\n' ...
    'The value for Number of Packages must be 1,2,3,....']));
set(handles.editWindowing, 'TooltipString', sprintf([ ...
    'If Number of Window Samples is greater than zero,\n' ...
    'a filter is used on both sides of every OFDM time domain symbol.\n' ...
    'If Number of Window Samples is zero, no filter is used.\n' ...
    'The Number of Window Samples defines the length in samples (AWG sample rate)\n' ...
    'which are filtered on every side of an OFDM time domain symbol.\n' ...
    'Alternatively is also possible to define the time length of the window or the VSA Window Beta.']));
set(handles.editVSAWindowingdisplay, 'TooltipString', sprintf([ ...
    'Length of Window used by VSA (defined as a fraction of FFT Length,\n' ...
    'alternatively the number of samples or the time length in seconds can be defined, \n' ...
    'The value must be smaller or equal as 2*Guard Interval.']));
set(handles.pushbuttonCorrection, 'TooltipString', sprintf([ ...
    'Perform calibration of AWG using VSA, OFDM calibration uses the OFDM signal which is currently set in OFDM Modulations GUI.\n' ...
    'Remark, when a calibration is done, the frequency span for the measurement is smaller than the necessary range for the OFDM signal, \n' ...
    'if the OFDM Sample Rate of the signal is used. The OFDM Sample Rate might be choosen higher for calibration than for transmission, \n' ...
    'it is then possible to calibrate over the full frequency range of the transmitted OFDM signal']));
set(handles.pushbuttonChannelMapping, 'TooltipString', sprintf([ ...
    'Select into which channels the real and imaginary part of the waveform\n' ...
    'is loaded. By default, I is loaded into Channel 1, Q into channel 2, but\n' ...
    'it is also possible to load the same signal into both channels.\n' ...
    'In DUC modes, both I and Q are used for the same channel.\n' ...
    'In dual-M8190A configurations, channels 3 and 4 are on the second module.']));
end
% UIWAIT makes iqmod_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqofdm_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



%-------------------GUI Callback Functions-----------------------------------------------
%----------------------------------------------------------------------------------------


function editFFTLength_Callback(hObject, eventdata, handles)
% hObject    handle to editFFTLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFFTLength as text
%        str2double(get(hObject,'String')) returns contents of editFFTLength as a double
value = [];
   try
       value = evalin('base', get(handles.editFFTLength, 'String'));
   catch ex
      set(hObject,'BackgroundColor','red');
   end
   if (isscalar(value) && value >= 1 && value <= 120000 && ispower2(value)==true)
      set(hObject,'BackgroundColor','white');
      checkOFDMData (hObject, eventdata, handles)
   else
      set(hObject,'BackgroundColor','red');
   end

% --- Executes during object creation, after setting all properties.
function editFFTLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFFTLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editOversampling_Callback(hObject, eventdata, handles)
% hObject    handle to editOversampling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOversampling as text
%        str2double(get(hObject,'String')) returns contents of editOversampling as a double
value = [];
try
    value = evalin('base', get(hObject, 'String')); 
catch ex
    set(hObject,'BackgroundColor','red');
    return
end
if (isscalar(value) && value > 0 && value <= 100000)
    set(hObject,'BackgroundColor','white');
    try
      OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
      SampleRate = OFDMSystemFrequency * value;
      set(handles.editSampleRate,'String', iqengprintf(SampleRate));
      set(handles.editSampleRate,'BackgroundColor','white');
    catch ex 
    end
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editOversampling_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOversampling (see GCBO)
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


function editOFDMSystemFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to editOFDMSystemFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOFDMSystemFrequency as text
%        str2double(get(hObject,'String')) returns contents of editOFDMSystemFrequency as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));   
catch ex
    set(hObject,'BackgroundColor','red');
    return
end
if (isscalar(value) && value > 0 && value <= 64e9)
    try
      sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
      if(value<=sampleRate)
        oversampling = sampleRate/value;
        set(handles.editOversampling,'String',oversampling);
        set(hObject,'BackgroundColor','white');
        set(handles.editOversampling,'BackgroundColor','white');
        set(handles.editFrequencyspan, 'String', iqengprintf(value*1.5));
        set(handles.editFrequencyspan,'BackgroundColor','white');
        set(handles.editSampleRate,'BackgroundColor','white');
        %Calculate the VSA Window Beta 
        editWindowing_Callback(hObject, eventdata, handles)
      else
        set(hObject,'BackgroundColor','red');
      end
      catch ex
        return
    end
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editOFDMSystemFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOFDMSystemFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editResourceMap_Callback(hObject, eventdata, handles)
% hObject    handle to editResourceMap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editResourceMap as text
%        str2double(get(hObject,'String')) returns contents of editResourceMap as a double
try
    i=get(handles.editResourceMap);
    k=i.String;
    %Convert the string to double array
    ResourceMap=convertstring(k);
    
catch ex
end
if(length(ResourceMap)~=0)
  if (isnumeric(ResourceMap) && max(ResourceMap)<=4 && min(ResourceMap)>=0)
      set(hObject,'BackgroundColor','white');
      checkOFDMData (hObject, eventdata, handles);
  else
     set(hObject,'BackgroundColor','red');
  end
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editResourceMap_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editResourceMap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editResourceModulation_Callback(hObject, eventdata, handles)
% hObject    handle to editResourceModulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editResourceModulation as text
%        str2double(get(hObject,'String')) returns contents of editResourceModulation as a double
try
    i=get(handles.editResourceModulation);
    k=i.String;
    %Convert the string to double array
    ResourceModulation=convertstring(k);
    
catch ex
end
if(length(ResourceModulation)~=0)
  if (isnumeric(ResourceModulation) && min(ResourceModulation)>=0 && max(ResourceModulation)<=14)
      set(hObject,'BackgroundColor','white');
      checkOFDMData (hObject, eventdata, handles);
  else
     set(hObject,'BackgroundColor','red');
  end
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editResourceModulation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editResourceModulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editQuamIdentifier_Callback(hObject, eventdata, handles)
% hObject    handle to editQuamIdentifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editQuamIdentifier as text
%        str2double(get(hObject,'String')) returns contents of editQuamIdentifier as a double
try
    i=get(handles.editQuamIdentifier);
    k=i.String;
    %Convert the string to double array
    QuamIdentifier=convertstring(k);
    
catch ex
end
if(length(QuamIdentifier)~=0)
  if (isnumeric(QuamIdentifier) && min(QuamIdentifier)>=0 && max(QuamIdentifier)<=14)
      set(hObject,'BackgroundColor','white');
      checkOFDMData (hObject, eventdata, handles)
  else
     set(hObject,'BackgroundColor','red');
  end
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editQuamIdentifier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editQuamIdentifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editQuamLevels_Callback(hObject, eventdata, handles)
% hObject    handle to editQuamLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editQuamLevels as text
%        str2double(get(hObject,'String')) returns contents of editQuamLevels as a double
try
    i=get(handles.editQuamLevels);
    k=i.String;
    %Convert the string to double array
    QuamLevels=convertstring(k);
    
catch ex
end
if(length(QuamLevels)~=0)
  if (isnumeric(QuamLevels) && min(QuamLevels)>=0 && max(QuamLevels)<=14)
      set(hObject,'BackgroundColor','white');
      checkOFDMData (hObject, eventdata, handles)
  else
     set(hObject,'BackgroundColor','red');
  end
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editQuamLevels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editQuamLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editPilotDefinitions_Callback(hObject, eventdata, handles)
% hObject    handle to editPilotDefinitions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPilotDefinitions as text
%        str2double(get(hObject,'String')) returns contents of editPilotDefinitions as a double
try
    i=get(handles.editPilotDefinitions);
    k=i.String;
    %Convert the string to double array
    PilotDefinitions=convertstring(k);
    
catch ex
end
if(length(PilotDefinitions)~=0)
  if (isnumeric(PilotDefinitions))
      set(hObject,'BackgroundColor','white');
      checkOFDMData (hObject, eventdata, handles);
  else
      set(hObject,'BackgroundColor','red');
  end
else
    set(hObject,'BackgroundColor','red');
    checkOFDMData (hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function editPilotDefinitions_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPilotDefinitions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editPreambleValues_Callback(hObject, eventdata, handles)
% hObject    handle to editPreambleValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPreambleValues as text
%        str2double(get(hObject,'String')) returns contents of editPreambleValues as a double
try
    i=get(handles.editPreambleValues);
    k=i.String;
    %Convert the string to double array
    PreambleValues=convertstring(k);
    
catch ex
end

if(length(PreambleValues)~=0)
  if (isnumeric(PreambleValues))
      set(hObject,'BackgroundColor','white');
      checkOFDMData (hObject, eventdata, handles) 
  else
     set(hObject,'BackgroundColor','red');
  end
else
    set(hObject,'BackgroundColor','red');
    checkOFDMData (hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function editPreambleValues_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPreambleValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editnumberofguardlowerrsubcarriers_Callback(hObject, eventdata, handles)
% hObject    handle to editnumberofguardlowerrsubcarriers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editnumberofguardlowerrsubcarriers as text
%        str2double(get(hObject,'String')) returns contents of editnumberofguardlowerrsubcarriers as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 99 && (round(value) == value))
    set(hObject,'BackgroundColor','white');
    checkOFDMData (hObject, eventdata, handles)
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editnumberofguardlowerrsubcarriers_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editnumberofguardlowerrsubcarriers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editnumberofguarduppersubcarriers_Callback(hObject, eventdata, handles)
% hObject    handle to editnumberofguarduppersubcarriers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editnumberofguarduppersubcarriers as text
%        str2double(get(hObject,'String')) returns contents of editnumberofguarduppersubcarriers as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 99 && (round(value) == value))
    set(hObject,'BackgroundColor','white');
    checkOFDMData (hObject, eventdata, handles) 
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editnumberofguarduppersubcarriers_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editnumberofguarduppersubcarriers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editprefix_Callback(hObject, eventdata, handles)
% hObject    handle to editprefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editprefix as text
%        str2double(get(hObject,'String')) returns contents of editprefix as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editprefix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editprefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editResourceRepeatIndex_Callback(hObject, eventdata, handles)
% hObject    handle to editResourceRepeatIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editResourceRepeatIndex as text
%        str2double(get(hObject,'String')) returns contents of editResourceRepeatIndex as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
    numsymbols=evalin('base',get(handles.editnumsymbols, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= numsymbols  && (round(value) == value))
    set(hObject,'BackgroundColor','white');
    checkOFDMData (hObject, eventdata, handles)
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editResourceRepeatIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editResourceRepeatIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editNumberOfSymbols_Callback(hObject, eventdata, handles)
% hObject    handle to editNumberOfSymbols (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumberOfSymbols as text
%        str2double(get(hObject,'String')) returns contents of editNumberOfSymbols as a double
value = [];

try
    %Value is the number of symbols
    value = evalin('base', get(hObject, 'String')); 
catch ex
    set(hObject,'BackgroundColor','red');
end
if (isscalar(value) && value > 0 && value == round(value))
    set(hObject,'BackgroundColor','white'); 
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editNumberOfSymbols_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumberOfSymbols (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editCarrierFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to editCarrierFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCarrierFrequency as text
%        str2double(get(hObject,'String')) returns contents of editCarrierFrequency as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
     set(hObject,'BackgroundColor','red');
     return;
end
if (isscalar(value) && value >= 0)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editCarrierFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCarrierFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editBurstInterval_Callback(hObject, eventdata, handles)
% hObject    handle to editBurstInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editBurstInterval as text
%        str2double(get(hObject,'String')) returns contents of editBurstInterval as a double
value = [];

%try to read the value for sample rate
try
    value = evalin('base', get(hObject, 'String'));
   
catch ex
     set(hObject,'BackgroundColor','red');
     return
end

%check if value for sample rate is valid
if (isscalar(value) && value >=0)
    
    try
      %try to read a value for OFDMSystemFrequency 
      OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
      %try to read a value for Sample Rate
      sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
      %Round the burst time that it is a multiplier of 1/samplerate
      %(necessary to fill the right number of zeros) in the OFDM Spectrum)
      sampletime=1/sampleRate;
      N=value/sampletime;
      %round to positive inf
      N=ceil(N);
      value=N*sampletime;
      set(hObject,'String',value);
      set(hObject,'BackgroundColor','white');
    
    catch ex
        return
    end
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editBurstInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editBurstInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editNumPackages_Callback(hObject, eventdata, handles)
% hObject    handle to editNumPackages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumPackages as text
%        str2double(get(hObject,'String')) returns contents of editNumPackages as a double
value = [];
try
    %Value is the number of symbols
    value = evalin('base', get(hObject, 'String')); 
catch ex
    set(hObject,'BackgroundColor','red');
end
if (isscalar(value) && value > 0 && value == round(value))
    set(hObject,'BackgroundColor','white'); 
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editNumPackages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumPackages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editFrequencyspan_Callback(hObject, eventdata, handles)
% hObject    handle to editFrequencyspan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFrequencyspan as text
%        str2double(get(hObject,'String')) returns contents of editFrequencyspan as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));   
catch ex
    set(hObject,'BackgroundColor','red');
    return
end
if (isscalar(value) && value > 0)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editFrequencyspan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFrequencyspan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editVsaMeasInterval_Callback(hObject, eventdata, handles)
% hObject    handle to editVsaMeasInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVsaMeasInterval as text
%        str2double(get(hObject,'String')) returns contents of editVsaMeasInterval as a double
value = [];

try
    %Value is the number of symbols
    value = evalin('base', get(hObject, 'String')); 
catch ex
    set(hObject,'BackgroundColor','red');
end
if (isscalar(value) && value > 0 && value == round(value))
    set(hObject,'BackgroundColor','white'); 
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editVsaMeasInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVsaMeasInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
 
function editWindowing_Callback(hObject, eventdata, handles)
% hObject    handle to editWindowing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWindowing as text
%        str2double(get(hObject,'String')) returns contents of editWindowing as a double
value = [];
try
      %Value is the number of Sample points of the IFFT Signal which are
      %used for windowing
      value=evalin('base',get(handles.editWindowing, 'String'));
catch ex
      set(handles.editWindowing,'BackgroundColor','red');
      set(handles.editVSAWindowingdisplay,'BackgroundColor','red');
      set(handles.editVSAWindowingdisplay,'String',' ');
      return;
end

sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
FFTLength = evalin('base',get(handles.editFFTLength, 'String'));

if (isscalar(value) && value >= 0 && value==round(value))
      set(handles.editWindowing,'BackgroundColor','white'); 
else
      set(handles.editWindowing,'BackgroundColor','red'); 
      set(handles.editVSAWindowingdisplay,'BackgroundColor','red');
      set(handles.editVSAWindowingdisplay,'String',' ');
      return;
end

   %to avod error when zero division
   try
       %time length of windowing
       Windowtime=value/sampleRate;
       %Value used by VSA to set windowing
       VSAwindow=value*OFDMSystemFrequency/(FFTLength*sampleRate);
    catch ex
    
    end
    %Value used by VSA must be smaller or equal as prefix/2
    prefix= evalin('base',get(handles.editprefix, 'String'));
    
   
if(2*VSAwindow>prefix)
    set(handles.editVSAWindowingdisplay,'BackgroundColor','red');
else
    set(handles.editVSAWindowingdisplay,'BackgroundColor','white');
end

set(handles.editVSAWindowingdisplay,'String',VSAwindow);

% --- Executes during object creation, after setting all properties.
function editWindowing_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWindowing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editVSAWindowingdisplay_Callback(hObject, eventdata, handles)
% hObject    handle to editVSAWindowingdisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVSAWindowingdisplay as text
%        str2double(get(hObject,'String')) returns contents of editVSAWindowingdisplay as a double
value = [];
try
      %Value is the number of Sample points of the IFFT Signal which are
      %used for windowing
      value = evalin('base', get(hObject, 'String')); 
catch ex
      set(hObject,'BackgroundColor','red');
      set(handles.editWindowing,'BackgroundColor','red');
      set(handles.editWindowing,'String',' ');
      return;
end

sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
FFTLength = evalin('base',get(handles.editFFTLength, 'String'));
prefix= evalin('base',get(handles.editprefix, 'String'));

if (isscalar(value) && value >= 0)
      set(hObject,'BackgroundColor','white'); 
else
      set(hObject,'BackgroundColor','red');
      set(handles.editWindowing,'BackgroundColor','red');
      set(handles.editWindowing,'String',' ');
      return;
end

N=floor((value*FFTLength*sampleRate)/OFDMSystemFrequency);
time=N/sampleRate;
vsabeta=OFDMSystemFrequency*N/(FFTLength*sampleRate);

set(handles.editWindowing,'String',N);
set(handles.editVSAWindowingdisplay,'String',vsabeta);

set(handles.editWindowing,'BackgroundColor','white');

if(2*vsabeta<=prefix)
  set(hObject,'BackgroundColor','white');
else
  set(hObject,'BackgroundColor','red');
end
% --- Executes during object creation, after setting all properties.
function editVSAWindowingdisplay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVSAWindowingdisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------GUI Pushbuttons Callbacks------------------------------------------------
%--------------------------------------------------------------------------------------------

% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global iqdataglobal;

oversampling = evalin('base',get(handles.editOversampling, 'String'));
OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
simulate=true;
%Function Calculate OFDM Data 
%(simulate true only calculation, false download)
hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...', 'replace');
     CalculateOFDMData(hObject, eventdata, handles,simulate)
close(hMsgBox);
%Plot the calculated IQ Data
iqplot(iqdataglobal, oversampling*OFDMSystemFrequency);

% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
simulate=false;
%Function Calculate OFDM Data (simulate true only display, false including
%download)
try
hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...', 'replace');    
        CalculateOFDMData(hObject, eventdata, handles,simulate)
close(hMsgBox);
catch ex
    return;
end;

% --- Executes on button press in pushbuttonVisualizeInMatlab.
function pushbuttonVisualizeInMatlab_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonVisualizeInMatlab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
simulate=true;
%Function Calculate OFDM Data (simulate true only display, false including
%download)
hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...', 'replace');    
     CalculateOFDMData(hObject, eventdata, handles,simulate)
close(hMsgBox);   
[vsaApp,OFDMSettings,OFDMMeasHandle]=controlVSA (hObject, eventdata, handles, simulate);

% --- Executes during object creation, after setting all properties.
function pushbuttonVisualizeInMatlab_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbuttonVisualizeInMatlab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in pushbuttonVSArealWaveform.
function pushbuttonVSArealWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonVSArealWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
simulate=false;
hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...', 'replace');        
CalculateOFDMData(hObject, eventdata, handles,simulate)
try
close(hMsgBox);
catch ex;
end;
%open the VSA and make adjustments
[vsaApp,OFDMSettings,OFDMMeasHandle]=controlVSA (hObject, eventdata, handles, simulate);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbuttonVSArealWaveform.
function pushbuttonVSArealWaveform_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbuttonVSArealWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonCorrection.
function pushbuttonCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Baseband Correction
%Download a Waveform
simulate=false;

%Turn off the Apply Correction field to calculate a waveform without a
%correction
set(handles.checkboxCorrection,'Value',0);

hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...', 'replace');        
CalculateOFDMData(hObject, eventdata, handles,simulate);
try
      close(hMsgBox);
catch ex;
end;
measureequalizer(hObject, eventdata, handles, simulate);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbuttonCorrection.
function pushbuttonCorrection_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbuttonCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonshowcalresult.
function pushbuttonshowcalresult_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonshowcalresult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 iqcorrmgmt();

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbuttonshowcalresult.
function pushbuttonshowcalresult_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbuttonshowcalresult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




%--------File save and load functions-------------------------------------------
%--------------------------------------------------------------------------

% --------------------------------------------------------------------
function File_Callback(hObject, eventdata, handles)
% hObject    handle to File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function SaveMatlabSettings_Callback(hObject, eventdata, handles)
% hObject    handle to SaveMatlabSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
[FileName,PathName] = uiputfile('.mat');
if(FileName~=0)
    
clear OFDMSettings;

OFDMSettings.sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
OFDMSettings.oversampling = evalin('base',get(handles.editOversampling, 'String'));
OFDMSettings.OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
OFDMSettings.fshift = evalin('base',get(handles.editCarrierFrequency, 'String'));
OFDMSettings.Fc = evalin('base',get(handles.editFc, 'String'));
OFDMSettings.NumWindowSamples= evalin('base',get(handles.editWindowing, 'String'));
OFDMSettings.Windowbeta=evalin('base',get(handles.editVSAWindowingdisplay, 'String'));
OFDMSettings.MeasInterval=evalin('base',get(handles.editVsaMeasInterval, 'String'));
OFDMSettings.Span=evalin('base',get(handles.editFrequencyspan, 'String'));
contents = cellstr(get(handles.popupmenuvsapoints,'String'));
OFDMSettings.vsapoints=sscanf((contents{get(handles.popupmenuvsapoints, 'Value')}),'%d');

OFDMSettings.Correction=get(handles.checkboxCorrection,'Value');
OFDMSettings.FFTLength = evalin('base',get(handles.editFFTLength, 'String'));
OFDMSettings.numGuardLowerSubcarriers = evalin('base',get(handles.editnumberofguardlowerrsubcarriers, 'String'));     
OFDMSettings.numGuardHigherSubcarriers = evalin('base',get(handles.editnumberofguarduppersubcarriers, 'String')) ;
OFDMSettings.prefix= evalin('base',get(handles.editprefix, 'String')) ;
OFDMSettings.ResourceRepeatIndex = evalin('base',get(handles.editResourceRepeatIndex, 'String')) ;
OFDMSettings.NumSymbols=evalin('base',get(handles.editNumberOfSymbols, 'String'));
OFDMSettings.BurstInterval= evalin('base',get(handles.editBurstInterval, 'String'));
OFDMSettings.NumPackages=evalin('base',get(handles.editNumPackages, 'String'));

i=get(handles.editResourceMap);
k=i.String;
OFDMSettings.ResourceMap=convertstring(k);

i=get(handles.editResourceModulation);
k=i.String;
OFDMSettings.ResourceModulation=convertstring(k);

i=get(handles.editQuamIdentifier);
k=i.String;
OFDMSettings.QuamIdentifier=convertstring(k);

i=get(handles.editQuamLevels);
k=i.String;
OFDMSettings.QuamLevels=convertstring(k);

i=get(handles.editPilotDefinitions);
k=i.String;
OFDMSettings.PilotDefinitions=convertstring(k);

i=get(handles.editPreambleValues);
k=i.String;
OFDMSettings.PreambleValues=convertstring(k);


FileName=strcat(PathName,FileName);

save(FileName,'OFDMSettings')

end
catch ex
    msgbox('Failure file not saved','Message')
end


% --------------------------------------------------------------------
function SaveRecording_Callback(hObject, eventdata, handles)
% hObject    handle to SaveRecording (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global iqdataglobal;
%minimum length of waveform
waveformminlength=90000;
if(length(iqdataglobal)==0)
    hMsgBox = msgbox('No data calculated, a new simulated waveform will be calculated automatically before saving to file', 'Empty waveform'); 
    return;
end
OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
oversampling = evalin('base',get(handles.editOversampling, 'String'));
fs = OFDMSystemFrequency * oversampling;

%% Repeat waveform when too short for VSA recording
if(length(iqdataglobal)<waveformminlength)
    N=ceil(waveformminlength/length(iqdataglobal));
    Y=repmat(iqdataglobal,1,N);
else
     Y=iqdataglobal;
end
iqsavewaveform(Y, fs);


% --------------------------------------------------------------------
function LoadMatlabSettings_Callback(hObject, eventdata, handles)
% hObject    handle to LoadMatlabSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
[FileName,PathName] = uigetfile('.mat');
if(FileName~=0);
   FileName=strcat(PathName,FileName);
   load(FileName);
    if (exist('OFDMSettings'))
   
   set(handles.editSampleRate,'String',OFDMSettings.sampleRate);
   set(handles.editOversampling,'String',OFDMSettings.oversampling);
   set(handles.editOFDMSystemFrequency,'String',OFDMSettings.OFDMSystemFrequency);
   set(handles.editCarrierFrequency,'String',OFDMSettings.fshift);
   if (isfield(OFDMSettings, 'Fc'))
       set(handles.editFc,'String',OFDMSettings.Fc);
   end
   set(handles.editWindowing,'String',OFDMSettings.NumWindowSamples);
   set(handles.editVSAWindowingdisplay,'String',OFDMSettings.Windowbeta); 
   set(handles.editVsaMeasInterval,'String',OFDMSettings.MeasInterval); 
   set(handles.editFrequencyspan,'String',OFDMSettings.Span);
   types = get(handles.popupmenuvsapoints, 'String');
   point = find(strcmp(types,mat2str(OFDMSettings.vsapoints)));
   if(point>0)
   set(handles.popupmenuvsapoints, 'Value', point);
   end
   set(handles.checkboxCorrection,'Value',OFDMSettings.Correction);
   set(handles.editFFTLength,'String',OFDMSettings.FFTLength);
   set(handles.editnumberofguardlowerrsubcarriers,'String',OFDMSettings.numGuardLowerSubcarriers);
   set(handles.editnumberofguarduppersubcarriers,'String',OFDMSettings.numGuardHigherSubcarriers); 
   set(handles.editprefix,'String',OFDMSettings.prefix);
   set(handles.editResourceRepeatIndex,'String',OFDMSettings.ResourceRepeatIndex); 
   set(handles.editNumberOfSymbols,'String',OFDMSettings.NumSymbols);
   set(handles.editBurstInterval,'String',OFDMSettings.BurstInterval);
   set(handles.editNumPackages,'String',OFDMSettings.NumPackages);

   str=convtosting(OFDMSettings.ResourceMap);
   set(handles.editResourceMap,'String',str);
   str=convtosting(OFDMSettings.ResourceModulation);
   set(handles.editResourceModulation,'String',str);
   
   str=convtosting(OFDMSettings.QuamIdentifier);
   set(handles.editQuamIdentifier,'String',str);
   str=convtosting(OFDMSettings.QuamLevels);
   set(handles.editQuamLevels,'String',str);
   
   str=convtosting(OFDMSettings.PilotDefinitions);
   set(handles.editPilotDefinitions,'String',str);
   str=convtosting(OFDMSettings.PreambleValues);
   set(handles.editPreambleValues,'String',str);
   checkloadeddata(hObject, eventdata, handles);
   else
      msgbox('Failure during loading of file','Message');   
    end
end   
catch ex
    msgbox('Failure during loading of file','Message');
end

%-----------------Presets--------------------------------------------------
%--------------------------------------------------------------------------

% --------------------------------------------------------------------
function Preset_Callback(hObject, eventdata, handles)
% hObject    handle to Preset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function IEEE_Callback(hObject, eventdata, handles)
% hObject    handle to IEEE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
IEEEPreset(hObject, eventdata, handles)


% --------------------------------------------------------------------
function stdtwo_Callback(hObject, eventdata, handles)
% hObject    handle to stdtwo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
StdSignaltwopreset (hObject, eventdata, handles)


% --------------------------------------------------------------------
function OFDM_1024_Callback(hObject, eventdata, handles)
% hObject    handle to OFDM_1024 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
OFDM1024Preset(hObject, eventdata, handles);

% --------------------------------------------------------------------
function OFDM_4096_Callback(hObject, eventdata, handles)
% hObject    handle to OFDM_4096 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
OFDM4096Preset(hObject, eventdata, handles);



function IEEEPreset (hObject, eventdata, handles)

arbConfig = loadArbConfig();
switch upper(arbConfig.model)
    case {'M8190A_12BIT' 'M8190A_14BIT'}
        oversampling = 8;
        offset = 2e9;
    otherwise
        oversampling = 4;
        offset = 0;
end
sampleRate=arbConfig.defaultSampleRate;
OFDMSystemFrequency=sampleRate/oversampling;
set(handles.editSampleRate, 'String', iqengprintf(sampleRate ));
set(handles.editOFDMSystemFrequency, 'String', iqengprintf(OFDMSystemFrequency));
set(handles.editCarrierFrequency, 'String', iqengprintf(offset));
sampletime=1/OFDMSystemFrequency;
pausetime=sampletime*1000;
set(handles.editBurstInterval, 'String', iqengprintf(pausetime));
set(handles.editFrequencyspan, 'String', iqengprintf(OFDMSystemFrequency*1.5));
    
 set(handles.editFFTLength,'String','64');
 str='4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,4,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,4,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0';
 set(handles.editResourceMap,'String',str);
 str='0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0';
 set(handles.editResourceModulation,'String',str);
 str='0,1,2,3,4,5';
 set(handles.editQuamIdentifier,'String',str);
 str='4,1,2,4,6,8';
 set(handles.editQuamLevels,'String',str);
 str='1,0,1,0,1,0,-1,0,1,0,1,0,1,0,-1,0';
 set(handles.editPilotDefinitions,'String',str);
 str='1.47196,1.47196,-1.47196,-1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1,0,0,1,-1,0,0,1,-1,0,0,1,-1,0,0,-1,1,0,0,1,1,0,0,-1,-1,0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,-1,0,0,-1,1,0,0,-1,-1,0,0,1,0,-1,1,0,0,-1,1,0,0,-1,1,0,0,1,-1,0,0,-1,1,0,0,-1,-1,0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,-1,0,0,-1,1,0,0,1,1,0,0,-1,-1,0,1,0,1,0,-1,0,-1,0,1,0,1,0,-1,0,1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,1,0,1,0,-1,0,1,0,-1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,1,0,1,0,-1,0,1,0,-1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,-1,0,-1,0,1,0,-1,0,1,0,-1,0,1,0,1,0,1,0,1,0';
 set(handles.editPreambleValues,'String',str);
 set(handles.editnumberofguardlowerrsubcarriers,'String','6');
 set(handles.editnumberofguarduppersubcarriers,'String','5'); 
 set(handles.editprefix,'String','0.25');
 set(handles.editResourceRepeatIndex,'String','5'); 
 set(handles.editNumberOfSymbols,'String','30');
 set(handles.editNumPackages,'String','5');
 set(handles.checkboxCreateRandomData,'Value',1);  
 set(handles.checkboxCorrection,'Value',0);  
 
 set(handles.editVsaMeasInterval,'String','20');
 set(handles.popupmenuvsapoints,'Value',9);

 set(handles.editWindowing,'String','0');
 set(handles.editVSAWindowingdisplay,'String','0');
 
 checkloadeddata(hObject, eventdata, handles) 
 
 
function OFDM1024Preset (hObject, eventdata, handles)

arbConfig = loadArbConfig();
switch upper(arbConfig.model)
    case {'M8190A_12BIT' 'M8190A_14BIT'}
        oversampling = 8;
        offset = 2e9;
    otherwise
        oversampling = 4;
        offset = 0;
end
sampleRate=arbConfig.defaultSampleRate;
OFDMSystemFrequency=sampleRate/oversampling;
set(handles.editSampleRate, 'String', iqengprintf(sampleRate ));
set(handles.editOFDMSystemFrequency, 'String', iqengprintf(OFDMSystemFrequency));
set(handles.editCarrierFrequency, 'String', iqengprintf(offset));
sampletime=1/OFDMSystemFrequency;
pausetime=sampletime*1000;
set(handles.editBurstInterval, 'String', iqengprintf(pausetime));
set(handles.editFrequencyspan, 'String', iqengprintf(OFDMSystemFrequency*1.5));
    
 set(handles.editFFTLength,'String','1024');
 str='4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,4,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,4,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0';
 set(handles.editResourceMap,'String',str);
 str='0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0';
 set(handles.editResourceModulation,'String',str);
 str='0,1,2,3,4,5';
 set(handles.editQuamIdentifier,'String',str);
 str='6,1,2,4,6,8';
 set(handles.editQuamLevels,'String',str);
 str='1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0';
 set(handles.editPilotDefinitions,'String',str);
 str='1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0';
 set(handles.editPreambleValues,'String',str);
 set(handles.editnumberofguardlowerrsubcarriers,'String','96');
 set(handles.editnumberofguarduppersubcarriers,'String','95'); 
 set(handles.editprefix,'String','0.25');
 set(handles.editResourceRepeatIndex,'String','5'); 
 set(handles.editNumberOfSymbols,'String','30');
 set(handles.editNumPackages,'String','5');
 set(handles.checkboxCreateRandomData,'Value',1);  
 set(handles.checkboxCorrection,'Value',0);  
 
 set(handles.editVsaMeasInterval,'String','20');
 set(handles.popupmenuvsapoints,'Value',9);

 set(handles.editWindowing,'String','0');
 set(handles.editVSAWindowingdisplay,'String','0');
 
 checkloadeddata(hObject, eventdata, handles) 
 
 
function OFDM4096Preset (hObject, eventdata, handles)

arbConfig = loadArbConfig();
switch upper(arbConfig.model)
    case {'M8190A_12BIT' 'M8190A_14BIT'}
        oversampling = 8;
        offset = 2e9;
    otherwise
        oversampling = 4;
        offset = 0;
end
sampleRate=arbConfig.defaultSampleRate;
OFDMSystemFrequency=sampleRate/oversampling;
set(handles.editSampleRate, 'String', iqengprintf(sampleRate ));
set(handles.editOFDMSystemFrequency, 'String', iqengprintf(OFDMSystemFrequency));
set(handles.editCarrierFrequency, 'String', iqengprintf(offset));
sampletime=1/OFDMSystemFrequency;
pausetime=sampletime*1000;
set(handles.editBurstInterval, 'String', iqengprintf(pausetime));
set(handles.editFrequencyspan, 'String', iqengprintf(OFDMSystemFrequency*1.5));
    
 set(handles.editFFTLength,'String','1024');
 str='4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,4,3,4,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,4,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,4,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0';
 set(handles.editResourceMap,'String',str);
 str='0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0';
 set(handles.editResourceModulation,'String',str);
 str='0,1,2,3,4,5';
 set(handles.editQuamIdentifier,'String',str);
 str='6,1,2,4,6,8';
 set(handles.editQuamLevels,'String',str);
 str='1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0';
 set(handles.editPilotDefinitions,'String',str);
 str='1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,-1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,1.47196,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0';
 set(handles.editPreambleValues,'String',str);
 set(handles.editnumberofguardlowerrsubcarriers,'String','96');
 set(handles.editnumberofguarduppersubcarriers,'String','95'); 
 set(handles.editprefix,'String','0.25');
 set(handles.editResourceRepeatIndex,'String','5'); 
 set(handles.editNumberOfSymbols,'String','30');
 set(handles.editNumPackages,'String','5');
 set(handles.checkboxCreateRandomData,'Value',1);  
 set(handles.checkboxCorrection,'Value',0);  
 
 set(handles.editVsaMeasInterval,'String','20');
 set(handles.popupmenuvsapoints,'Value',9);

 set(handles.editWindowing,'String','0');
 set(handles.editVSAWindowingdisplay,'String','0');
 
 checkloadeddata(hObject, eventdata, handles) 
 
 


 
function StdSignaltwopreset (hObject, eventdata, handles)

arbConfig = loadArbConfig();
switch upper(arbConfig.model)
    case {'M8190A_12BIT' 'M8190A_14BIT'}
        oversampling = 8;
        offset = 2e9;
    otherwise
        oversampling = 4;
        offset = 0;
end
sampleRate=arbConfig.defaultSampleRate;
OFDMSystemFrequency=sampleRate/oversampling;
set(handles.editSampleRate, 'String', iqengprintf(sampleRate ));
set(handles.editOFDMSystemFrequency, 'String', iqengprintf(OFDMSystemFrequency));
set(handles.editCarrierFrequency, 'String', iqengprintf(offset));
sampletime=1/OFDMSystemFrequency;
pausetime=sampletime*0;
set(handles.editBurstInterval, 'String', iqengprintf(pausetime));
set(handles.editFrequencyspan, 'String', iqengprintf(OFDMSystemFrequency*1.5));
    
 set(handles.editFFTLength,'String','8');
 str='1,1,0,4,1,0,1';
 set(handles.editResourceMap,'String',str);
 str='1,3,1,1,1,3,1';
 set(handles.editResourceModulation,'String',str);
 str='0,1,2,3,4,5';
 set(handles.editQuamIdentifier,'String',str);
 str='0,1,2,4,6,8';
 set(handles.editQuamLevels,'String',str);
 str='1,0,-1,1,-1,0,-1,0';
 set(handles.editPilotDefinitions,'String',str);
 str='';
 set(handles.editPreambleValues,'String',str);
 set(handles.editnumberofguardlowerrsubcarriers,'String','1');
 set(handles.editnumberofguarduppersubcarriers,'String','0'); 
 set(handles.editprefix,'String','0.25');
 set(handles.editResourceRepeatIndex,'String','0'); 
 set(handles.editNumberOfSymbols,'String','100');
 set(handles.editNumPackages,'String','1');
 set(handles.checkboxCreateRandomData,'Value',1);  
 set(handles.checkboxCorrection,'Value',0);  
 
 set(handles.editVsaMeasInterval,'String','20');
 set(handles.popupmenuvsapoints,'Value',9);
 
 set(handles.editWindowing,'String','0');
 set(handles.editVSAWindowingdisplay,'String','0');
 
 checkloadeddata(hObject, eventdata, handles) 
 

 
%-----------Function called to calculate OFDM data-------------------------
%--------------------------------------------------------------------------

function CalculateOFDMData(hObject, eventdata, handles,simulate)

%global variable to store the iqdata
global iqdataglobal
%if waveform is shorter than waveformminlength, increase length 
%before saving to default recording (only for the saved data)
waveformminlength=90000;

% handles structure with handles and user data
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
oversampling = evalin('base',get(handles.editOversampling, 'String'));
FFTLength = evalin('base',get(handles.editFFTLength, 'String'));
numGuardLowerSubcarriers = evalin('base',get(handles.editnumberofguardlowerrsubcarriers, 'String'));     
numGuardHigherSubcarriers = evalin('base',get(handles.editnumberofguarduppersubcarriers, 'String')) ;
ResourceRepeatIndex = evalin('base',get(handles.editResourceRepeatIndex, 'String')) ;
prefix= evalin('base',get(handles.editprefix, 'String')) ;
correction = get(handles.checkboxCorrection,'Value');
fshift = evalin('base',get(handles.editCarrierFrequency, 'String'));
Fc = evalin('base',get(handles.editFc, 'String'));
BurstInterval= evalin('base',get(handles.editBurstInterval, 'String'));
NumSymbols = evalin('base',get(handles.editNumberOfSymbols, 'String'));
IsRandata=get(handles.checkboxCreateRandomData,'Value');
NumPackages= evalin('base',get(handles.editNumPackages, 'String'));
NumWindow= evalin('base',get(handles.editWindowing, 'String'));

i=get(handles.editResourceMap);
k=i.String;
ResourceMap=convertstring(k);

i=get(handles.editResourceModulation);
k=i.String;
ResourceModulation=convertstring(k);

i=get(handles.editQuamIdentifier);
k=i.String;
QuamIdentifier=convertstring(k);

i=get(handles.editQuamLevels);
k=i.String;
QuamLevels=convertstring(k);

i=get(handles.editPilotDefinitions);
k=i.String;
PilotDefinitions=convertstring(k);

i=get(handles.editPreambleValues);
k=i.String;
PreambleValues=convertstring(k);

try
i=get(handles.editBinaryData);
k=i.String;
data=convertstring(k);
catch ex
    data=[];
end

channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');

[iqdata, data, channelMapping] = iqofdm('correction',correction, ...
    'FFTLength', FFTLength, ...
    'oversampling',oversampling, ... 
    'resourcemap', ResourceMap, ...
    'resourcemodulation', ResourceModulation, ...
    'quamidentifier', QuamIdentifier, ...
    'quamlevels', QuamLevels, ...
    'pilotdefinitions', PilotDefinitions, ...
    'preambleiqvalues', PreambleValues, ...
    'numguardlowersubcarriers', numGuardLowerSubcarriers, ...
    'numguardhighersubcarriers', numGuardHigherSubcarriers, ...
    'resourcerepeatindex', ResourceRepeatIndex, ...
    'prefix', prefix, ...
    'ofdmsamplefrequency', OFDMSystemFrequency,...
    'fshift', fshift, ...
    'burstinterval', BurstInterval, ...
    'numsymbols',    NumSymbols, ...
    'isranddata',   IsRandata, ...
    'data',data, ...
    'numpackages', NumPackages, ...
    'numwindow', NumWindow, ...
    'channelMapping', channelMapping);

iqdataglobal=iqdata;
str=convtosting(data);
set(handles.editBinaryData,'String',str);
   
                 
%% Repeat waveform when too short for VSA recording
if(size(iqdata,1)<waveformminlength)
      N=ceil(waveformminlength/size(iqdata,1));
      Y=repmat(iqdata,N,1);  
else
       Y=iqdata;
end
   
try   
   %%if not simulated increase because of granularity
   if(simulate~=true)
      arbConfig = loadArbConfig(); 
      multiplier=arbConfig.segmentGranularity;
      N=lcm(size(Y,1), multiplier)/size(Y,1);
      Y=repmat(Y,N,1);
      %control= length(Y)/ multiplier; %only for testing
      hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
      iqdownload(Y, oversampling*OFDMSystemFrequency, 'channelMapping', channelMapping);
      close(hMsgBox); 
   end
   
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
   
%file data in default file, to be able to read recording with VSA 
FileName = fullfile(iqScratchDir(), 'defaultofdmrecording.mat');
%get the current path (where iqofdm_gui is located)
OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
oversampling = evalin('base',get(handles.editOversampling, 'String'));
XStart=0;
XDelta=1/(OFDMSystemFrequency*oversampling);
InputZoom=1; 
%Y = complex(real(Y), zeros(1, length(Y)));        % testing only
try
  save(FileName,'Y','XStart','XDelta','InputZoom');
catch ex 
  msgbox('Waveform was not saved to default recording, the data shown in VSA simulations might not be right','Message')  
end

%---Function to check the data format when a setting is loaded from file---
%---this function calls checkOFDMData but is checking also data ranges----- 
%---of input data and format of strings, numbers---------------------------
   
function checkloadeddata(hObject, eventdata, handles) 

    %controlFFT field
    try
       value = evalin('base', get(handles.editFFTLength, 'String'));
    catch ex
      set(handles.editFFTLength,'BackgroundColor','red');
    end
    if (isscalar(value) && value >= 1 && value <= 120000 && ispower2(value)==true)
      set(handles.editFFTLength,'BackgroundColor','white');
    else
      set(handles.editFFTLength,'BackgroundColor','red');
    end
    
    %check if value for sample rate, oversampling, ofdmsystfreq is valid
    try
      value = evalin('base', get(handles.editSampleRate, 'String'));
      arbConfig = loadArbConfig();
      if (isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
        try
        %try to read a value for OFDMSystemFrequency 
        OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
          if(value>=OFDMSystemFrequency)
              oversampling = value/OFDMSystemFrequency;
              set(handles.editOversampling,'String',oversampling);
              set(handles.editOversampling,'BackgroundColor','white');
              set(handles.editSampleRate,'BackgroundColor','white');
              set(handles.editOFDMSystemFrequency,'BackgroundColor','white');
          else
              set(handles.editSampleRate,'BackgroundColor','red');
          end
        catch ex
         set(handles.editOversampling,'BackgroundColor','red');  
         set(handles.editOFDMSystemFrequency,'BackgroundColor','red');
        end
      else
         set(handles.editSampleRate,'BackgroundColor','red');
      end
   catch ex
        set(handles.editSampleRate,'BackgroundColor','red');
        set(handles.editOversampling,'BackgroundColor','red');  
        set(handles.editOFDMSystemFrequency,'BackgroundColor','red');
   end
    

%Control num symbols field
  try
    value = evalin('base', get(handles.editNumberOfSymbols, 'String'));
    if(isscalar(value)&&value>0&&value==round(value))
      set(handles.editNumberOfSymbols,'BackgroundColor','white');
    end
  catch ex
     set(handles.editNumberOfSymbols,'BackgroundColor','red');
     return
  end
  

%control guard interval
  try
    value = evalin('base', get(handles.editprefix, 'String'));
    if(isscalar(value)&&value>=0)
       set(handles.editprefix,'BackgroundColor','white');
    end
  catch ex
       set(handles.editprefix,'BackgroundColor','red');
       return
  end
    
  try
    i=get(handles.editQuamIdentifier);
    k=i.String;
    %Convert the string to double array
    QuamIdentifier=convertstring(k);
    
  catch ex
  end
  
  if(length(QuamIdentifier)~=0)
       if (isnumeric(QuamIdentifier) && min(QuamIdentifier)>=0 && max(QuamIdentifier)<=14)
          set(handles.editQuamIdentifier,'BackgroundColor','white');
       else
          set(handles.editQuamIdentifier,'BackgroundColor','red');
       end
  else
          set(handles.editQuamIdentifier,'BackgroundColor','red');
  end
    
  try
    i=get(handles.editQuamLevels);
    k=i.String;
    %Convert the string to double array
    QuamLevels=convertstring(k);
    
  catch ex
  end
  
  if(length(QuamLevels)~=0)
     if (isnumeric(QuamLevels) && min(QuamLevels)>=0 && max(QuamLevels)<=14)
       set(handles.editQuamLevels,'BackgroundColor','white');
     else
       set(handles.editQuamLevels,'BackgroundColor','red');
     end
  else
       set(handles.editQuamLevels,'BackgroundColor','red');
  end
    
%Control fshift
 try
      value = evalin('base', get(handles.editCarrierFrequency, 'String'));
    catch ex
      set(handles.editCarrierFrequency,'BackgroundColor','red');
    end
    if (isscalar(value) && value >= 0)
      set(handles.editCarrierFrequency,'BackgroundColor','white');
    else
      set(hObject,'BackgroundColor','red');
    end
    
%Control Span
 try
      value = evalin('base', get(handles.editFrequencyspan, 'String'));
    catch ex
      set(handles.editFrequencyspan,'BackgroundColor','red');
    end
    if (isscalar(value) && value >= 0)
      set(handles.editFrequencyspan,'BackgroundColor','white');
    else
      set(hObject,'BackgroundColor','red');
    end

%control burst interval

try
      value = evalin('base', get(handles.editBurstInterval, 'String'));
    catch ex
      set(handles.editBurstInterval,'BackgroundColor','red');
    end
    if (isscalar(value) && value >= 0)
      set(handles.editBurstInterval,'BackgroundColor','white');
    else
      set(hObject,'BackgroundColor','red');
    end

 %Control num packages 
 
 try
      value = evalin('base', get(handles.editNumPackages, 'String'));
    catch ex
      set(handles.editNumPackages,'BackgroundColor','red');
    end
    if (isscalar(value) && value > 0 && value==round(value))
      set(handles.editNumPackages,'BackgroundColor','white');
    else
      set(hObject,'BackgroundColor','red');
    end   
    
%Control Measurement Interval 
  try
    value = evalin('base', get(handles.editVsaMeasInterval, 'String'));
    if(isscalar(value)&&value>0&&value==round(value))
      set(handles.editVsaMeasInterval,'BackgroundColor','white');
    end
  catch ex
     set(handles.editVsaMeasInterval,'BackgroundColor','red');
     return
  end
        
 %Control Num Window Samples 
  try
    value = evalin('base', get(handles.editWindowing, 'String'));
    if(isscalar(value)&&value>=0 &&value==round(value))
      set(handles.editWindowing,'BackgroundColor','white');
    end
  catch ex
     set(handles.editWindowing,'BackgroundColor','red');
     return
  end 
  
  
 %Control VSA Window beta
  try
    value = evalin('base', get(handles.editVSAWindowingdisplay, 'String'));
    if(isscalar(value)&&value>=0)
      set(handles.editVSAWindowingdisplay,'BackgroundColor','white');
    end
  catch ex
     set(handles.editVSAWindowingdisplay,'BackgroundColor','red');
     return
  end   
  
  
checkOFDMData (handles.editprefix, eventdata, handles)


%---------------Check OFDM data format-------------------------------------
%--------------------------------------------------------------------------

    
function checkOFDMData (hObject, eventdata, handles)

%In this function it is controlled, if the strings have the right format to create an 
%OFDM signal 

%It is not controlled if the user inputs have the right ranges
%and formats (numbers are numbers, letters are letters), 
%this is done directly in the callback function of every component

try
  sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
  
catch ex
  set(handles.editSampleRate,'BackgroundColor','red');
  return
end

try
OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
catch ex
  set(handles.editOFDMSystemFrequency,'BackgroundColor','red');
  return
end

try
oversampling = evalin('base',get(handles.editOversampling, 'String'));
catch ex
  set(handles.editOversampling,'BackgroundColor','red');
  return
end

try
FFTLength = evalin('base',get(handles.editFFTLength, 'String'));
catch ex
  set(handles.editFFTLength,'BackgroundColor','red');
  return
end

try
numGuardLowerSubcarriers = evalin('base',get(handles.editnumberofguardlowerrsubcarriers, 'String')); 
catch ex
  set(handles.editnumberofguardlowerrsubcarriers,'BackgroundColor','red');
  return
end

try
numGuardHigherSubcarriers = evalin('base',get(handles.editnumberofguarduppersubcarriers, 'String')) ;
catch ex
  set(handles.editnumberofguarduppersubcarriers,'BackgroundColor','red'); 
  return
end

try
ResourceRepeatIndex = evalin('base',get(handles.editResourceRepeatIndex, 'String')) ;
catch ex
   set(handles.ResourceRepeatIndex,'BackgroundColor','red');  
   return
end
  
try    
prefix= evalin('base',get(handles.editprefix, 'String')) ;
catch ex
   set(handles.editprefix,'BackgroundColor','red');  
   return
end

try
numSymbols=evalin('base',get(handles.editNumberOfSymbols, 'String')) ;
catch ex
   set(handles.editNumberOfSymbols,'BackgroundColor','red');  
   return
end

i=get(handles.editResourceMap);
k=i.String;
ResourceMap=convertstring(k);

i=get(handles.editResourceModulation);
k=i.String;
ResourceModulation=convertstring(k);

i=get(handles.editQuamIdentifier);
k=i.String;
QuamIdentifier=convertstring(k);

i=get(handles.editQuamLevels);
k=i.String;
QuamLevels=convertstring(k);

i=get(handles.editPilotDefinitions);
k=i.String;
PilotDefinitions=convertstring(k);

i=get(handles.editPreambleValues);
k=i.String;
PreambleValues=convertstring(k);

%Check if the settings are convenient for the creation of the OFDM Signal

%Control if number of guards is not too big
if(FFTLength-numGuardHigherSubcarriers-numGuardLowerSubcarriers<0)
set(handles.editnumberofguarduppersubcarriers,'BackgroundColor','red'); 
set(handles.editnumberofguardlowerrsubcarriers,'BackgroundColor','red'); 
else
set(handles.editnumberofguarduppersubcarriers,'BackgroundColor','white'); 
set(handles.editnumberofguardlowerrsubcarriers,'BackgroundColor','white');    
end

%Calculate if the number of symbols coded in one resource map entry is an integer 
%(otherwise the resource map, the number of carriers or the fft length must be changed)
%If the number of symbols is an integer, also the number of resource map
%entries is convenient for OFDM Signal generation
[value N]=calculateN(FFTLength,ResourceMap,numGuardHigherSubcarriers,numGuardLowerSubcarriers);
if(value==false)
set(handles.editnumsymbols,'String',N);     
set(handles.editnumsymbols,'BackgroundColor','red');
set(handles.editResourceMap,'BackgroundColor','red');
else
set(handles.editnumsymbols,'String',N); 
set(handles.editnumsymbols,'BackgroundColor','white');
set(handles.editResourceMap,'BackgroundColor','white');
end

%Control if length of resource map is the same as resource modulation
value=lengthResourceMapResourceMod(ResourceMap,ResourceModulation);
if(value==0)     
set(handles.editResourceModulation,'BackgroundColor','red');
else
set(handles.editResourceModulation,'BackgroundColor','white');
end

%Control if the number of pilots is right
value=controlnumpilorpre(ResourceMap,PilotDefinitions,1);
if(value==0)     
set(handles.editPilotDefinitions,'BackgroundColor','red');
else
set(handles.editPilotDefinitions,'BackgroundColor','white');
end

%Control if the nuber of preamble values is right
value=controlnumpilorpre(ResourceMap,PreambleValues,3);
if(value==0)     
set(handles.editPreambleValues,'BackgroundColor','red');
else
set(handles.editPreambleValues,'BackgroundColor','white');
end

%Control if resource repeat index is smaller than number of symbols
if(ResourceRepeatIndex >= N)
set(handles.editResourceRepeatIndex,'BackgroundColor','red');   
else
set(handles.editResourceRepeatIndex,'BackgroundColor','white');      
end


%---------------Function to control VSA Analyzer---------------------------
% -------------------------------------------------------------------------

function [vsaApp,OFDMSettings,OFDMMeasHandle]=controlVSA (hObject, eventdata, handles, simulate)
    
    vsaApp = [];
    OFDMMeasHandle = [];
    %get handles and user data 
    OFDMSettings.sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
    OFDMSettings.OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
    OFDMSettings.oversampling = evalin('base',get(handles.editOversampling, 'String'));
    OFDMSettings.FFTLength = evalin('base',get(handles.editFFTLength, 'String'));
    OFDMSettings.numGuardLowerSubcarriers = evalin('base',get(handles.editnumberofguardlowerrsubcarriers, 'String'));     
    OFDMSettings.numGuardHigherSubcarriers = evalin('base',get(handles.editnumberofguarduppersubcarriers, 'String')) ;
    OFDMSettings.ResourceRepeatIndex = evalin('base',get(handles.editResourceRepeatIndex, 'String')) ;
    OFDMSettings.prefix= evalin('base',get(handles.editprefix, 'String')) ;
    OFDMSettings.fshift = evalin('base',get(handles.editCarrierFrequency, 'String'));
    OFDMSettings.Fc = evalin('base',get(handles.editFc, 'String'));
    OFDMSettings.BurstInterval= evalin('base',get(handles.editBurstInterval, 'String'));
    OFDMSettings.NumSymbols = evalin('base',get(handles.editNumberOfSymbols, 'String'));
    OFDMSettings.vsafreqspan=evalin('base',get(handles.editFrequencyspan, 'String')) ;
    OFDMSettings.vsameasinterval=evalin('base',get(handles.editVsaMeasInterval, 'String'));
    contents = cellstr(get(handles.popupmenuvsapoints,'String'));
    OFDMSettings.vsapoints=sscanf((contents{get(handles.popupmenuvsapoints, 'Value')}),'%d');

    i=get(handles.editResourceMap);
    k=i.String;
    OFDMSettings.ResourceMap=convertstring(k);

    i=get(handles.editResourceModulation);
    k=i.String;
    OFDMSettings.ResourceModulation=convertstring(k);

    i=get(handles.editQuamIdentifier);
    k=i.String;
    OFDMSettings.QuamIdentifier=convertstring(k);

    i=get(handles.editQuamLevels);
    k=i.String;
    OFDMSettings.QuamLevels=convertstring(k);

    i=get(handles.editPilotDefinitions);
    k=i.String;
    OFDMSettings.PilotDefinitions=convertstring(k);

    i=get(handles.editPreambleValues);
    k=i.String;
    OFDMSettings.PreambleValues=convertstring(k);

     %open and run VSA application 
     vsaApp = vsafunc([], 'open');
     if (isempty(vsaApp))
       return;
     end
     if (~isa(vsaApp, 'Agilent.SA.Vsa.Application'))
         errordlg({'The OFDM utility is not yet re-written to use VSA via SCPI.' ...
                   'Please uncheck the "Remote VSA" checkbox in the instrument' ...
                   'configuration window and use VSA locally'});
         vsaApp = [];
         return;
     end
     import Agilent.SA.Vsa.*;


    % Make VSA visible
    vsaApp.IsVisible = true;

    % Create
    vsaMeas = vsaApp.Measurements.SelectedItem;
    vsaDisp = vsaApp.Display;
    vsaInput = vsaMeas.Input;
    vsaHW = vsaApp.Hardware;
    %DataRegisters=vsaApp.DataRegisters;

    % Preset
     vsaDisp.Preset;
     vsaMeas.Preset;
     %vsaMeas.Reset;

     %Important VSA must be in Vector measurement mode to use the function below
     VectorMeasurementtype=vsaMeas.MeasurementExtensionType;

     %Select if data from hardware or recording
     %Use try-catch for every VSA command to check if command is possible for selected VSA analyzer

%case simulation 
if(simulate==true)
    
         vsaInput.DataFrom = DataSource.Recording;  
         logicalChTypes = NET.createArray('Agilent.SA.Vsa.LogicalChannelType', 1);
         logicalChTypes(1) = Agilent.SA.Vsa.LogicalChannelType.Baseband;
         %to set the channels is only possible when a hardware analyzer is
         %avaliable, if not VSA is automatically in Baseband, catch can be
         %ignored in this case
         try
            vsaInput.ChangeLogicalChannels(logicalChTypes);
         catch ex 
         end
          % case hardware
else
          %set VSA to hardware case 
          vsaInput.DataFrom = DataSource.Hardware;     
          %Select the channels if Hardware is used, I to Channel 1 and Q to Channel 2 or download only to channel 1  
          if(OFDMSettings.fshift == 0 && OFDMSettings.Fc == 0)
            logicalChTypes = NET.createArray('Agilent.SA.Vsa.LogicalChannelType', 1);
            logicalChTypes(1) = Agilent.SA.Vsa.LogicalChannelType.IQ;
            %use try catch to check if it is possible to Change Channel Types with selected hardware
            try
               vsaInput.ChangeLogicalChannels(logicalChTypes);
            catch ex
               errordlg('Can not set the analyzer channels to IQ mode. Check if VSA is connected to desired analyzer and try again','Error')  
               return;
            end
          else
            logicalChTypes = NET.createArray('Agilent.SA.Vsa.LogicalChannelType', 1); 
            logicalChTypes(1) = Agilent.SA.Vsa.LogicalChannelType.Baseband;
            %use try catch to check if it is possible to Change Channel Types with selected hardware
             try
                 vsaInput.ChangeLogicalChannels(logicalChTypes);
             catch ex
%                 errordlg('Can not set input channel, check in VSA software if is currently selected hardware analyzer is convenient for measurement and try again','Error')  
             end
         end
end


%VSA adjustments
%use try catch to check if it is possible to Change Channel Types with selected hardware
try
    
   %Important VSA must be in Vector measurement mode to use the function below
   vsaMeas.SetMeasurementExtension(VectorMeasurementtype);
   vsaMeas.SetMeasurementExtension(VectorMeasurementtype);  

   % Set center frequency and span
   vsaFreq=vsaMeas.Frequency;

   if(OFDMSettings.fshift>0)
     vsaFreq.Center=OFDMSettings.fshift + OFDMSettings.Fc;
   else
     vsaFreq.Center = OFDMSettings.Fc;  
   end

   vsaFreq.Span=OFDMSettings.vsafreqspan;
   vsaFreq.IsPointsAuto=false;
   vsaFreq.Points=OFDMSettings.vsapoints;
   %vsaFreq.ResBW=30e+6;

   %Perform Auto Range of Channels
   vsaMeas.Input.Analog.AutoRange;
   vsaMeas.Reset;
   %switch to VSA Measurement (this code is working, the extension has to be set two times, this is an internal matlab error)
   OFDMMeasurementtype=Agilent.SA.Vsa.CustomOfdm.MeasurementExtension.ExtensionType;
   OFDMmeasExt=vsaMeas.SetMeasurementExtension(OFDMMeasurementtype);
   OFDMMeasHandle = Agilent.SA.Vsa.CustomOfdm.MeasurementExtension.CastToExtensionType(OFDMmeasExt);
   OFDMMeasHandle.delete;
   OFDMMeasExt=vsaMeas.SetMeasurementExtension(OFDMMeasurementtype);
   OFDMMeasHandle = Agilent.SA.Vsa.CustomOfdm.MeasurementExtension.CastToExtensionType(OFDMMeasExt);

   %Set Properties
   OFDMMeasHandle.FftLength=OFDMSettings.FFTLength;
   OFDMMeasHandle.GuardInterval=OFDMSettings.prefix;
   OFDMMeasHandle.GuardLowerSubcarriers=OFDMSettings.numGuardLowerSubcarriers;
   OFDMMeasHandle.GuardUpperSubcarriers=OFDMSettings.numGuardHigherSubcarriers;
   OFDMMeasHandle.ResourceRepeatIndex=OFDMSettings.ResourceRepeatIndex;
   OFDMMeasHandle.OfdmSystemSampleFrequency=OFDMSettings.OFDMSystemFrequency;
   if(OFDMSettings.BurstInterval>0)
     OFDMMeasHandle.IsPulsedSignal=true;
   else
     OFDMMeasHandle.IsPulsedSignal=false;  
   end

   OFDMMeasHandle.ResourceMap=NET.convertArray(OFDMSettings.ResourceMap, 'System.Int32');
   OFDMMeasHandle.ResourceModulation=NET.convertArray(OFDMSettings.ResourceModulation, 'System.Int32');
   OFDMMeasHandle.PilotValues=NET.convertArray(OFDMSettings.PilotDefinitions, 'System.Single');
   OFDMMeasHandle.PreambleValues=NET.convertArray(OFDMSettings.PreambleValues, 'System.Single');
   OFDMMeasHandle.QamLevels=NET.convertArray(OFDMSettings.QuamLevels, 'System.Int32');
   OFDMMeasHandle.QamIdentifiers=NET.convertArray(OFDMSettings.QuamIdentifier, 'System.Int32');

   OFDMMeasHandle.SynchronizationMode=Agilent.SA.Vsa.CustomOfdm.SynchronizationMode.CyclicPrefix;
   OFDMMeasHandle.IsExtendedFrequencyLockRange=false;
   OFDMMeasHandle.IsEvmNormalizeByReference=false;


   OFDMMeasHandle.SymbolTimeAdjustment=-12.5;
   OFDMMeasHandle.IsEqualizerUseDCPilot=false;
   OFDMMeasHandle.IsEqualizerUseData=false;
   OFDMMeasHandle.IsEqualizerUsePilots=false;
   OFDMMeasHandle.IsEqualizerUsePreamble=false;
   OFDMMeasHandle.IsEvmNormalizeByReference=false;
   OFDMMeasHandle.IsExtendedFrequencyLockRange=false;


catch ex
    errordlg('Can not set all VSA parameters, please try again','Error')      
   return;
end

%If simulated data load the last recording

if(simulate==true)
  %if already used in VSA, the file can be opened, 
  %the file name strings need to be exately as below, with .mat in name
  FileName = fullfile(iqScratchDir(), 'defaultofdmrecording.mat');
  
  try
     vsaInput.Recording.RecallFile(FileName,'mat');
     %set frequency again when data is available
     OFDMMeasHandle.OfdmSystemSampleFrequency=OFDMSettings.OFDMSystemFrequency;
     if(OFDMSettings.fshift>0)
       vsaFreq.Center=OFDMSettings.fshift;
     else
       vsaFreq.Center=0;  
     end
  catch ex
       hMsgBox = msgbox('Can not open recording, press Display or Display simulated Waveform with VSA to create','Message');
      return;
  end
end
%must be set again here
vsaFreq.Span=OFDMSettings.vsafreqspan;

%Set measurement interval, result length, offset, search length
try 
   
  OFDMMeasHandle.ResultLength=OFDMSettings.vsameasinterval;  
  OFDMMeasHandle.MeasurementInterval=OFDMSettings.vsameasinterval;
  OFDMMeasHandle.MeasurementOffset=0;
  OFDMMeasHandle.IsPulseSearchEnabled=true;
  %If the calculated value for the search length is too small, the value is
  %set to the minimum by VSA, the minimum value for search length decreases
  %when the Result Length and the Measurement Interval ard decreased
  OFDMMeasHandle.SearchLength=((1/OFDMSettings.OFDMSystemFrequency)*OFDMSettings.FFTLength*OFDMSettings.NumSymbols*(1+OFDMSettings.prefix)+OFDMSettings.BurstInterval)*2.5;    

catch ex
     msgbox('Can not set Measurement Interval and/or Result Length','Message');
end

%Set traces to default setting
vsaDisp.Traces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.HorizontalOrientation,2,2);
vsaDisp.Traces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.FillAll,2,2);

vsaMeas.Restart;

vsaMeas.WaitForMeasurementDone;

trace0=vsaDisp.Traces.Item(0);
%trace0.DataName='IQ Meas1';
trace0.YScaleAuto;

trace1=vsaDisp.Traces.Item(1);
%trace1.DataName='Spectrum1';
trace1.YScaleAuto;

trace2=vsaDisp.Traces.Item(2);
%trace2.DataName='RMS Error Vector Spectrum1';
trace2.YScaleAuto;

trace3=vsaDisp.Traces.Item(3);
%trace3.DataName='OFDM Error Summary1';
trace3.YScaleAuto;

vsaMeas.Input.Analog.AutoRange;

%Enable Show Cumulative History (later versions)
%spec=trace0.Spectrogram;


function measureequalizer(hObject, eventdata, handles, simulate)

  [vsaApp,OFDMSettings,OFDMMeasHandle]=controlVSA (hObject, eventdata, handles, simulate);

  if (isempty(vsaApp))
      return;
  end
  vsaMeas = vsaApp.Measurements.SelectedItem;
  vsaMeas.Restart; 
  vsafunc(vsaApp, 'trace', 6, 'CustomOFDM');
  OFDMMeasHandle.IsEqualizerUseDCPilot=false;
  OFDMMeasHandle.IsEqualizerUseData=true;
  OFDMMeasHandle.IsEqualizerUsePilots=true;
  OFDMMeasHandle.IsEqualizerUsePreamble=true;
  vsaMeas.Input.Analog.AutoRange; 
  pause(2);
  vsafunc(vsaApp, 'autoscale');
 
  %The range here will be ignored by VSA and causes problems
  %vsaMeas.Input.Analog.AutoRange;
  res = questdlg('VSA measurement running. Please press OK when Equalizer has stabilized. (Don''t forget to check input range...)','VSA Calibration','OK','Cancel','OK');
    if (~strcmp(res, 'OK'))
        return;
    end
  vsaMeas.Pause;
  vsafunc(vsaApp, 'readEqData');
  acs = load(iqampCorrFilename());
  % convert X-axis from symbol# to frequency
  if (acs.ampCorr(2,1) - acs.ampCorr(1,1) == 1)  % incr of 1 --> symbols
    sysFreq = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
    fftSize = evalin('base',get(handles.editFFTLength, 'String'));
    fshift = evalin('base',get(handles.editCarrierFrequency, 'String'));
    acs.ampCorr(:,1) = acs.ampCorr(:,1) * sysFreq / fftSize + fshift;
  end
  % extend the frequency range (with same corrections)
  % otherwise we get bad data at the end of the spectrum
  % add frequency points with same distance
  for i = 1:5
    acs.ampCorr(2:end+1,:) = acs.ampCorr(1:end,:);
    acs.ampCorr(end+1,:) = acs.ampCorr(end,:);
    acs.ampCorr(1,1) = 2 * acs.ampCorr(2,1) - acs.ampCorr(3,1);
    acs.ampCorr(end,1) = 2 * acs.ampCorr(end-1,1) - acs.ampCorr(end-2,1);
  end
  save(iqampCorrFilename(), '-struct', 'acs');
  iqshowcorr();
  % ---
  OFDMMeasHandle.IsEqualizerUseDCPilot=false;
  OFDMMeasHandle.IsEqualizerUseData=false;
  OFDMMeasHandle.IsEqualizerUsePilots=false;
  OFDMMeasHandle.IsEqualizerUsePreamble=false;
  set(handles.checkboxCorrection,'Value',1);
  vsaMeas.Restart;
  try
       hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...', 'replace');    
        CalculateOFDMData(hObject, eventdata, handles,simulate)
        close(hMsgBox);
  catch
  end
  try
      close(10);
  catch
  end



%------------Functions used for formating and check------------------------
%--------------------------------------------------------------------------

% Function to convert numerical array to formated string
function str=convtosting(num)
    k=num;
    k=transpose(k);
    a=mat2str(k);
    a=regexprep(a, ';', ','); %replace the ; with a , seperator
    str=a(2:1:length(a)-1);   %remove brackets
    
% Function to convert string to numerical data array
function numdata=convertstring(stringinput)
    k=stringinput;
    numdata=transpose(sscanf(k,'%f ,'));
    

% Function to check if numerical value is power of 2
function ispow=ispower2(numinput)

    if(log2(numinput)>=1 && log2(numinput)==round(log2(numinput)))
        ispow=true;
    else
        ispow=false;
    end
   
% Function to check if number of symbols given via resource map is N=1,2,3,....
function [value N]=calculateN(FFTLength,ResourceMap,uppercarrier,lowercarrier)
       
        if(FFTLength-uppercarrier-lowercarrier>0)
        N=length(ResourceMap)/(FFTLength-uppercarrier-lowercarrier); 
        else
        N=0;
        end
        if(round(N)==N&& N>=1)
        value=true; %Value is ok., Resource Map+Carriers longer than FFTLenght
        return;
        end
        value=false; %Value false

        
%Check if resource modulation array is as long as resource map
function value=lengthResourceMapResourceMod(ResourceMap,ResourceModulation) 
         if(length(ResourceMap)==length(ResourceModulation))
             value=1;
             return
         end
            value=0;
            
            
%Check if the number of pilots or preamble values is right (b=1 for pilot to
%be contolled, b=3 for preamble)
function value=controlnumpilorpre(ResourceMap,contarray,b)
         a=0;
         for i=1:length(ResourceMap)
             if ResourceMap(i)==b
                 a=a+1;
             end
         end
         if(length(contarray)==2*a)
             value=1;
             return
         end
         value=0;  

 
 %------------Callback functions with no code------------------------------
 %-------------------------------------------------------------------------
 
 % --- Executes on selection change in popupmenuvsapoints.
function popupmenuvsapoints_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuvsapoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuvsapoints contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuvsapoints


% --- Executes during object creation, after setting all properties.
function popupmenuvsapoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuvsapoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
 
% --- Executes on button press in checkboxCreateRandomData.
function checkboxCreateRandomData_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCreateRandomData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCreateRandomData

% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection

% --- Executes on button press in checkboxSignalIsBursted.
function checkboxSignalIsBursted_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSignalIsBursted (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSignalIsBursted


%-------not implemented now VSA res bandwidth migth be set in--------------
%-------later versions-----------------------------------------------------

function editvsaresbandwidth_Callback(hObject, eventdata, handles)
% hObject    handle to editvsaresbandwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editvsaresbandwidth as text
%        str2double(get(hObject,'String')) returns contents of editvsaresbandwidth as a double


% --- Executes during object creation, after setting all properties.
function editvsaresbandwidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editvsaresbandwidth (see GCBO)
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

% --- channel mapping
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig);
% --- editSampleRate
value = [];
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    errordlg(ex.message);
    result = 0;
end
%check if value for sample rate is valid
if (isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
    try
      %try to read a value for OFDMSystemFrequency 
      OFDMSystemFrequency = evalin('base',get(handles.editOFDMSystemFrequency, 'String'));
      if(value>=OFDMSystemFrequency)
        oversampling = value/OFDMSystemFrequency;
        set(handles.editOversampling,'String',oversampling);
        set(handles.editOversampling,'BackgroundColor','white');
        set(handles.editSampleRate,'BackgroundColor','white');
        set(handles.editOFDMSystemFrequency,'BackgroundColor','white');
        set(handles.editFrequencyspan, 'String', iqengprintf(OFDMSystemFrequency*1.5));
        set(handles.editFrequencyspan,'BackgroundColor','white');
      else
        set(handles.editSampleRate,'BackgroundColor','red');
        result = 0;
      end
    catch ex
       return
    end
else
      set(handles.editSampleRate,'BackgroundColor','red');
      result = 0;
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



function editFc_Callback(hObject, eventdata, handles)
% hObject    handle to editFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFc as text
%        str2double(get(hObject,'String')) returns contents of editFc as a double


% --- Executes during object creation, after setting all properties.
function editFc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
