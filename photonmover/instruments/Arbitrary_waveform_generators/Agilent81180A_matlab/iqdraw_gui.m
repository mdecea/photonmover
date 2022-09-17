function varargout = iqdraw_gui(varargin)
% IQTOOL MATLAB code for iqtool.fig
%      IQTOOL, by itself, creates a new IQTOOL or raises the existing
%      singleton*.
%
%      H = IQTOOL returns the handle to a new IQTOOL or the handle to
%      the existing singleton*.
%
%      IQTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQTOOL.M with the given input arguments.
%
%      IQTOOL('Property','Value',...) creates a new IQTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqdraw_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqdraw_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqtool

% Last Modified by GUIDE v2.5 02-Sep-2019 13:04:41
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqdraw_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqdraw_gui_OutputFcn, ...
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

end

% --- Executes just before iqtool is made visible.
function iqdraw_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqtool (see VARARGIN)

% Choose default command line output for iqtool
handles.output = hObject;
guidata(hObject, handles);

arbConfig = loadArbConfig();

handles.posWindow = get(handles.iqtool, 'Position');
handles.posaxes1 = get(handles.axes1, 'Position');
handles.posaxes2 = get(handles.axes2, 'Position');


% Initialize the GUI handles
cla(handles.axes1);
cla(handles.axes2);

% Interaction
handles.selectedAxes = 1;           % The current axes to draw
handles.isDrawing = 0;              % Is drawing occurring
handles.wasDrawing = 0;             % Was drawing occurring
%handles.isAxes1Initialized = 0;     % Was first point drawn
%handles.isAxes2Initialized = 0;     % Was first point drawn
handles.currentKey = 'none';        % Current key

% Limits
handles.axisRangeX = [0 8E-6];                 % The range of the x axis
handles.axisRangeYAxes1 = [-120 0];         % The range of the y axis of the top
handles.axisRangeYAxes2 = [-180 180];       % The range of the y axis of the bottom

handles.xInitial = 0;               % The initial x value
handles.yInitialAxes1 = 0;          % The initial top y value
handles.yInitialAxes2 = 0;          % The initial bottom y value
handles.xIncrement = 4E-9;          % The x increment

% Draw type
handles.drawMode = 'IQ';            % The type of draw mode

i = 4;
while (i <= nargin-2)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'axisx'; handles.axisRangeX = varargin{i+1};
            case 'axisy1'; handles.axisRangeYAxes1 = varargin{i+1};
            case 'axisy2'; handles.axisRangeYAxes2 = varargin{i+1};
            case 'drawmode'; handles.drawMode = varargin{i+1};
            case 'xincrement'; handles.xIncrement = varargin{i+1};
            case 'xinitial'; handles.xInitial = varargin{i+1};
            case 'yinitial1'; handles.yInitialAxes1 = varargin{i+1};
            case 'yinitial2'; handles.yInitialAxes2 = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

% Initialize the initial points
handles.xCurrentAxes1 = handles.xInitial;
handles.xCurrentAxes2 = handles.xInitial;

handles.yCurrentAxes1 = handles.yInitialAxes1;
handles.yCurrentAxes2 = handles.yInitialAxes2;

% Limits
handles.yMaxAxes1 = handles.axisRangeYAxes1(2);
handles.yMaxAxes2 = handles.axisRangeYAxes2(2);
handles.yMinAxes1 = handles.axisRangeYAxes1(1);
handles.yMinAxes2 = handles.axisRangeYAxes2(1);

handles.xMin = handles.axisRangeX(1);
handles.xMax = handles.axisRangeX(2);
handles.xIncrement = handles.xIncrement;

handles.axes1.XLim = handles.axisRangeX * 1.1;
handles.axes1.YLim = handles.axisRangeYAxes1 * 1.1;
set(handles.axes1, 'XGrid', 'on')
set(handles.axes1, 'YGrid', 'on')
set(handles.axes1, 'XMinorGrid', 'on')
set(handles.axes1, 'YMinorGrid', 'on')
set(handles.axes1, 'Box', 'on')

handles.axes2.XLim = handles.axisRangeX * 1.1;
handles.axes2.YLim = handles.axisRangeYAxes2 * 1.1;
set(handles.axes2, 'XGrid', 'on')
set(handles.axes2, 'YGrid', 'on')
set(handles.axes2, 'XMinorGrid', 'on')
set(handles.axes2, 'YMinorGrid', 'on')
set(handles.axes2, 'Box', 'on')

% Initialize the lines to draw
handles.lineDrawAxes1 = line(handles.xInitial, handles.yInitialAxes1,...
    'tag', 'linedrawcurrentblue1', 'Parent', handles.axes1);
handles.lineNextAxes1 = line(handles.xInitial, handles.yInitialAxes1,...
    'tag', 'linedrawnextred1', 'Color', 'red', 'LineStyle', '--', 'Parent', handles.axes1);
handles.lineTrackXAxes1 = line(handles.xInitial, handles.yInitialAxes1,...
    'tag', 'linedrawtrackX1', 'Color', 'green', 'LineStyle', '--', 'Parent', handles.axes1);
handles.lineTrackYAxes1 = line(handles.xInitial, handles.yInitialAxes1,...
    'tag', 'linedrawtrackY1', 'Color', 'green', 'LineStyle', '--', 'Parent', handles.axes1);
handles.lineImportAxes1 = line(handles.xInitial, handles.yInitialAxes1,...
    'tag', 'linedrawoverlay1', 'Color', 'black', 'LineStyle', '--', 'Parent', handles.axes1);

handles.lineDrawAxes2 = line(handles.xInitial, handles.yInitialAxes2,...
    'tag', 'linedrawcurrentblue2',  'Parent', handles.axes2);
handles.lineNextAxes2 = line(handles.xInitial, handles.yInitialAxes2,...
    'tag', 'linedrawnextred2', 'Color', 'red', 'LineStyle', '--',  'Parent', handles.axes2);
handles.lineTrackXAxes2 = line(handles.xInitial, handles.yInitialAxes2,...
    'tag', 'linedrawtrackX2', 'Color', 'green', 'LineStyle', '--', 'Parent', handles.axes2);
handles.lineTrackYAxes2 = line(handles.xInitial, handles.yInitialAxes2,...
    'tag', 'linedrawtrackY2', 'Color', 'green', 'LineStyle', '--', 'Parent', handles.axes2);


% Update the defaults
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
try
   handles.xIncrement = 1 / arbConfig.defaultSampleRate;
catch
end

handles.coordinateFormat = '%4.2f\n';
switch handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value}
        case 'Magnitude (dB) and Phase'     
            labelPlots(hObject, 0, handles,...
                'Magnitude (dB)', 'Phase (degrees)',...
                'Time (sec)', 'Time (sec)',...
                'dB', 'Degrees');
            
        case 'Magnitude (dB) and Frequency'
            labelPlots(hObject, 0, handles,...
                'Magnitude (dB)', 'Frequency (Hz)',...
                'Time (sec)', 'Time (sec)',...
                'dB', 'Hz');
              handles.coordinateFormat = '%10.5e\n';           
        case 'I/Q'
            labelPlots(hObject, 0, handles,...
                'I', 'Q)',...
                'Time (sec)', 'Time (sec)',...
                '', '');
        case 'Magnitude (dB) on Custom I/Q'
            labelPlots(hObject, 0, handles,...
                'Magnitude (dB)', 'Input Signal (dB)',...
                'Time (sec)', 'Time (sec)',...
                'dB', 'dB');
end


if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.popupmenuCreationMode, 'TooltipString', sprintf([ ...
    'Use this menu item to select between the signal creation modes.\n' ...
    'Magnitude (dB) and Phase: Creates signals based on the drawn Magnitude (dB) and Phase (degrees).\n' ...
    'Magnitude (dB) and Frequency: Creates signals based on the drawn Magnitude (dB) and Frequency (Hz).\n' ...
    'Magnitude (dB) on Custom I/Q: Creates signals based on the drawn Magnitude (dB) envelope on the defined Custom I/Q formula.']));
set(handles.editCustomIQ, 'TooltipString', sprintf([ ...
    'Enter a MATLAB expression with "sampleRate" being the sample rate defined in the "Sample Rate (Hz)" text entry.\n'...
    'Loading the signal via the "Load Signal" pushbutton overlays the envelopes in the drawing areas.']));
set(handles.pushbuttonChannelMapping, 'TooltipString', sprintf([ ...
    'Select into which channels the real and imaginary part of the waveform\n' ...
    'is loaded. By default, I is loaded into Channel 1, Q into channel 2, but\n' ...
    'it is also possible to load the same signal into both channels.\n' ...
    'In DUC modes, both I and Q are used for the same channel.\n' ...
    'In dual-M8190A configurations, channels 3 and 4 are on the second module.']));
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
set(handles.editOffset, 'TooltipString', sprintf([ ...
    'Set the frequency offset to 0 to generate a baseband I/Q signal.\n' ...
    'Set it to a value greater than zero to perform digital upconversion\n' ...
    'to that center frequency. (Depending on the selection in "Download",\n' ...
    'the output signal will be available on channel 1 or 2 or both.\n' ...
    'It is possible to specify a single or multiple frequency offset values.\n' ...
    'In case of a list, multiple pulses will be generated; each with its own\n' ...
    'offset.']));
set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the simulated waveform using MATLAB plots.\n' ...
    'The signal will be displayed both in the time- as well as frequency\n' ...
    'domain (spectrum). This function can be used even without any hardware\n' ...
    'connected.']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Use this button to calculate and download the signal to the configured AWG.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
set(handles.pushbuttonShowVSA, 'TooltipString', sprintf([ ...
    'Use this button to calculate and visualize the signal using the VSA software.\n' ...
    'If the VSA software is not already running, it will be started. The utility will\n' ...
    'automatically configure the VSA software for the parameters of the generated signal.\n' ...
    'VSA versions 14.0 and 14.2 are supported.']));
set(handles.pushbuttonDisplayCustom, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the custom I/Q waveform using MATLAB plots.\n' ...
    'The signal will be displayed both in the time- as well as frequency\n' ...
    'domain (spectrum). This function can be used even without any hardware\n' ...
    'connected.']));
set(handles.pushbuttonLoadCustomIQ, 'TooltipString', sprintf([ ...
    'Use this button to load the Custom I/Q signal into the setup where it will be overlaid in the drawing areas.']));
set(handles.pushbuttonShowVSACustom, 'TooltipString', sprintf([ ...
    'Use this button to calculate and visualize the custom I/Q waveform using the VSA software.\n' ...
    'If the VSA software is not already running, it will be started. The utility will\n' ...
    'automatically configure the VSA software for the parameters of the generated signal.\n' ...
    'VSA versions 14.0 and 14.2 are supported.']));
set(handles.pushbuttonClearTopPlot, 'TooltipString', sprintf([ ...
    'Clears this plot of its current drawing.']));
set(handles.pushbuttonClearBottomPlot, 'TooltipString', sprintf([ ...
    'Clears this plot of its current drawing.']));
set(handles.pushbuttonUndoTopPlot, 'TooltipString', sprintf([ ...
    'Removes the last drawn portion of this plot.']));
set(handles.pushbuttonUndoBottomPlot, 'TooltipString', sprintf([ ...
    'Removes the last drawn portion of this plot.']));
end


% Update handles structure
guidata(hObject, handles);
scalePlots(hObject, 0, handles);
clearPlots(hObject, 0, handles);
checkfields([], 0, handles);

end

% --- Outputs from this function are returned to the command line.
function varargout = iqdraw_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

end

% --- Executes on button press in pushbuttonClose.
function pushbuttonClose_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close();

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
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig, 'pulse');
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

end


%%%%%%%%%%%%%%%%%%%%%%% Creation functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% --- Executes during object creation, after setting all properties.
function popupmenuCreationMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuCreationMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

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
end

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
end

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

end

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

end

% --- Executes during object creation, after setting all properties.
function editCustomIQ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCustomIQ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%% Edit functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection

end

% --- Executes on button press in pushbuttonShowCorrection.
function pushbuttonShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqcorrmgmt();
end

function editSegment_Callback(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSegment as text
%        str2double(get(hObject,'String')) returns contents of editSegment as a double

end

% --- Executes on button press in pushbuttonChannelMapping.
function pushbuttonChannelMapping_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonChannelMapping (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    arbConfig = loadArbConfig();
    [val, str] = iqchanneldlg(get(hObject, 'UserData'), arbConfig, handles.iqtool, 'pulse');
    if (~isempty(val))
        set(hObject, 'UserData', val);
        set(hObject, 'String', str);
    end

end

function editOffset_Callback(hObject, eventdata, handles)
% hObject    handle to editOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOffset as text
%        str2double(get(hObject,'String')) returns contents of editOffset as a double

    value = [];
    try
        value = evalin('base', ['[' get(hObject, 'String') ']']);
    catch ex
        msgbox(ex.message);
    end
    if (isvector(value) && min(value) >= -100e9 && max(value) <= 100e9)
        set(hObject,'BackgroundColor','white');
    else
        set(hObject,'BackgroundColor','red');
    end
end

function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editSampleRate as a double

isValid = checkfields([], 0, handles);

% Set the granularity accordingly
if isValid
    handles.xIncrement = 1 / str2num(get(handles.editSampleRate, 'String'));
    guidata(hObject, handles);
end

end

function editPRI_Callback(hObject, eventdata, handles)
% hObject    handle to editPRI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPRI as text
%        str2double(get(hObject,'String')) returns contents of editPRI as a double

    priTest = [];
    try
        priTest = evalin('base', ['[' get(hObject, 'String') ']']);
    catch ex
        msgbox(ex.message);
    end
    if (isvector(priTest) && min(priTest) >= 0 && max(priTest) <= 1)
        set(hObject,'BackgroundColor','white');
        
        handles.axisRangeX(2) = priTest;
        
        handles.xMin = handles.axisRangeX(1);
        handles.xMax = handles.axisRangeX(2);

        handles.axes1.XLim = handles.axisRangeX * 1.1;
        handles.axes2.XLim = handles.axisRangeX * 1.1;
        
        guidata(hObject, handles);

    else
        set(hObject,'BackgroundColor','red');
    end    
end


function editCustomIQ_Callback(hObject, eventdata, handles)
% hObject    handle to editCustomIQ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCustomIQ as text
%        str2double(get(hObject,'String')) returns contents of editCustomIQ as a double
end

% --- Executes on button press in pushbuttonLoadCustomIQ.
function pushbuttonLoadCustomIQ_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonLoadCustomIQ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % Calculate the IQ
    customIQ = strtrim(get(handles.editCustomIQ, 'String'));   
    sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
    assignin('base', 'sampleRate', sampleRate);         % allow the formula use current sampleRate
    iqdataCalc = evalin('base', ['[' customIQ ']']);
    iqdatapow = 20*log10(abs(iqdataCalc));
    
    iqdatapow(find(iqdatapow < -120)) = -120;    
    timeArray = (0:(length(iqdataCalc)-1)) / sampleRate;
    
    clearPlots(hObject, 1, handles);
    
    % Set the line accordingly
    set(handles.lineDrawAxes2,...
    'xdata', timeArray,...
    'ydata', iqdatapow)

    set(handles.lineImportAxes1,...
    'xdata', timeArray,...
    'ydata', iqdatapow)

    % Update the time fields
    set(handles.editPRI, 'String', num2str(timeArray(end) + 1/ sampleRate));
    handles.axisRangeX(2) = timeArray(end);
        
    handles.xMin = handles.axisRangeX(1);
    handles.xMax = handles.axisRangeX(2);

    handles.axes1.XLim = handles.axisRangeX * 1.1;
    handles.axes2.XLim = handles.axisRangeX * 1.1;    
       
    guidata(hObject, handles);


end

% --- Executes on button press in pushbuttonDisplayCustom.
function pushbuttonDisplayCustom_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplayCustom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Calculate the IQ
customIQ = strtrim(get(handles.editCustomIQ, 'String'));   
sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
assignin('base', 'sampleRate', sampleRate);         % allow the formula use current sampleRate
iqdata = evalin('base', ['[' customIQ ']']);
iqplot(iqdata, sampleRate, 'spectrogram');

end

% --- Executes on button press in pushbuttonShowVSACustom.
function pushbuttonShowVSACustom_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowVSACustom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    customIQ = strtrim(get(handles.editCustomIQ, 'String'));   
    sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
    assignin('base', 'sampleRate', sampleRate);         % allow the formula use current sampleRate
    iqdata = evalin('base', ['[' customIQ ']']);

    vsaApp = vsafunc([], 'open');
    if (~isempty(vsaApp))
        hMsgBox = msgbox('Configuring VSA software. Please wait...', 'Please wait...', 'replace');
%         vsafunc(vsaApp, 'preset', 'vector');
%         vsafunc(vsaApp, 'input', 1);
%         if(isreal(iqdata))
%             iqdata = complex(iqdata); %Added if no mod
%         end
        vsafunc(vsaApp, 'load', iqdata, sampleRate);
        vsafunc(vsaApp, 'start', 1);

        try
            close(hMsgBox);
        catch ex
        end
    end
end


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[iqdata, ~, sampleRate, ~] = calculate_draw(handles, 0);
iqplot(iqdata, sampleRate, 'spectrogram');

end

% --- Executes on button press in pushbuttonShowVSA.
function pushbuttonShowVSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [iqdata, marker, sampleRate, channelMapping] = calculate_draw(handles, 0);

    vsaApp = vsafunc([], 'open');
    if (~isempty(vsaApp))
        hMsgBox = msgbox('Configuring VSA software. Please wait...', 'Please wait...', 'replace');
%         vsafunc(vsaApp, 'preset', 'vector');
%         vsafunc(vsaApp, 'input', 1);
%         if(isreal(iqdata))
%             iqdata = complex(iqdata); %Added if no mod
%         end
        vsafunc(vsaApp, 'load', iqdata, sampleRate);
        vsafunc(vsaApp, 'start', 1);
        vsafunc(vsaApp, 'trace', 4, 'Chirp');
        vsafunc(vsaApp, 'autoscale');
        try
            close(hMsgBox);
        catch ex
        end
    end
end

% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
    [iqdata, marker, sampleRate, channelMapping] = calculate_draw(handles, 0);
    segmentNum = evalin('base', get(handles.editSegment, 'String'));    
    % For M8195A_Rev1, switch to 2-channel mode for pulsed waveforms
    % arbConfig = loadArbConfig();
    % if (~isempty(strfind(arbConfig.model, 'M8195A_Rev1')))
    %     f = iqopen();
    %     if (isempty(f))
    %         return;
    %     end
    %     dacMode = query(f, ':INST:DACM?');
    %     if (~isempty(strfind(dacMode, 'FOUR')))
    %         msgbox('Switching M8195A to dual-channel mode. Please use the Soft Front Panel to switch back to 4-channel mode if required');
    %         fprintf(f, ':ABOR; :INST:DACM DUAL');
    %     end
    % end
    iqdownload(iqdata, sampleRate, 'channelMapping', channelMapping, ...
        'segmentNumber', segmentNum, 'marker', marker);
    try close(hMsgBox); catch ex; end;
end

function [iqdata, marker, sampleRate, channelMapping] = calculate_draw(handles, doCode)
% handles    structure with handles and user data (see GUIDATA)

% First force the lines to be same time length and remove overlaps

% Get the line data
ampData = [];
freqData = [];
phaseData = [];
timeDataAmp = handles.lineDrawAxes1.XData;
timeDataFreq = [];
timeDataPhase = [];
customIQ = [];

switch handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value}
    case 'Magnitude (dB) and Phase'     
        ampData = handles.lineDrawAxes1.YData;
        phaseData = handles.lineDrawAxes2.YData;
        timeDataPhase = handles.lineDrawAxes2.XData;
        
        if isempty(phaseData)
            phaseData = [0, 0];
            timeDataPhase = [0 handles.xMax];  
        elseif length(phaseData) == 1
            phaseData = [phaseData phaseData(1)];
            timeDataPhase = [timeDataPhase handles.xMax];
        end

    case 'Magnitude (dB) and Frequency'
        ampData = handles.lineDrawAxes1.YData;
        freqData = handles.lineDrawAxes2.YData;
        timeDataFreq = handles.lineDrawAxes2.XData;
        
        if isempty(freqData)
            freqData = [0, 0];
            timeDataFreq = [0 handles.xMax];  
        elseif length(freqData) == 1
            freqData = [freqData freqData(1)];
            timeDataPhase = [timeDataFreq handles.xMax];
        end

    case 'Magnitude (dB) on Custom I/Q'
        ampData = handles.lineDrawAxes1.YData;
        customIQ = strtrim(get(handles.editCustomIQ, 'String'));
end

if isempty(ampData)
    ampData = [0, 0];
    timeDataAmp = [0 handles.xMax];  
elseif length(ampData) == 1
    ampData = [ampData ampData(1)];
    timeDataAmp = [timeDataAmp handles.xMax];
end

sampleRate = evalin('base',get(handles.editSampleRate, 'String'));
pri = evalin('base', ['[' get(handles.editPRI, 'String') ']']);
offset_f = evalin('base', ['[' get(handles.editOffset, 'String') ']']);
correctFlag = get(handles.checkboxCorrection, 'Value');
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');


hMsgBox = msgbox('Calculating Waveform. Please wait...', 'Please wait...', 'replace');
try
[iqdata, marker, ~, channelMapping] = iqdraw(...
    'timedrawamp', timeDataAmp, 'ampdraw', ampData,...
    'timedrawfreq', timeDataFreq, 'freqdraw', freqData,...
    'timedrawphase', timeDataPhase, 'phasedraw', phaseData, ...
    'offset', offset_f, ...
    'sampleRate', sampleRate, ...
    'customiqpulse', customIQ,...
    'correction', correctFlag, 'channelMapping', channelMapping);
catch ex
   errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
   iqdata = [];
   marker = [];
end
try close(hMsgBox); catch; end
assignin('base', 'iqdata', iqdata);

end


%%%%%%%%%%%%%%%%%%%%%%% Window manipulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Update the current axes
    % handles.selectedAxes = 1;
    guidata(hObject, handles);

end

% --- Executes on mouse press over axes background.
function axes2_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Update the current axes
    % handles.selectedAxes = 2;
    guidata(hObject, handles);

end

% --- Executes on mouse motion over figure - except title and menu.
function iqtool_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to iqtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % See which is selected
    handles.selectedAxes = 0;
    
    pointCheckAxes1 = get(handles.axes1,'currentpoint');
    if pointCheckAxes1(1,3) <= 1 && pointCheckAxes1(1,1) <= handles.axes1.XLim(2)
        handles.selectedAxes = 1;
    end
    
    pointCheckAxes2 = get(handles.axes2,'currentpoint');
    if pointCheckAxes2(1,3) <= 1 && pointCheckAxes2(1,1) <= handles.axes2.XLim(2)
        handles.selectedAxes = 2;
    end
    
    % Link to the selected axes
    axesCurrent = handles.axes1;
    lineDrawCurrent = handles.lineDrawAxes1;            
    xDataCurrent = handles.xCurrentAxes1;    
    yDataMinCurrent = handles.yMinAxes1;
    yDataMaxCurrent = handles.yMaxAxes1;
    
    switch handles.selectedAxes
        case 1                 
            % Limit the y next to the limits of the plot
            yNext = pointCheckAxes1(1,2);
            if yNext > yDataMaxCurrent
                yNext = yDataMaxCurrent;
            elseif yNext < yDataMinCurrent
                yNext = yDataMinCurrent;
            end
            
            % Set the pointer to track
            set(handles.iqtool, 'Pointer', 'crosshair');
            set(handles.textTopPlotXText, 'String', num2str(pointCheckAxes1(1,1), '%10.5e\n'))
            set(handles.textBottomPlotXText, 'String', num2str(pointCheckAxes1(1,1), '%10.5e\n'))
            set(handles.textTopPlotYText, 'String', num2str(yNext, '%4.2f\n'))
        case 2                        
            axesCurrent = handles.axes2;
            lineDrawCurrent = handles.lineDrawAxes2;
            xDataCurrent = handles.xCurrentAxes2;
            yDataMinCurrent = handles.yMinAxes2;
            yDataMaxCurrent = handles.yMaxAxes2;
            
            % Limit the y next to the limits of the plot
            yNext = pointCheckAxes2(1,2);
            if yNext > yDataMaxCurrent
                yNext = yDataMaxCurrent;
            elseif yNext < yDataMinCurrent
                yNext = yDataMinCurrent;
            end
            
            % Set the pointer to track
            set(handles.iqtool, 'Pointer', 'crosshair');
            set(handles.textTopPlotXText, 'String', num2str(pointCheckAxes2(1,1), '%10.5e\n'))
            set(handles.textBottomPlotXText, 'String', num2str(pointCheckAxes2(1,1), '%10.5e\n'))
            set(handles.textBottomPlotYText, 'String', num2str(yNext, handles.coordinateFormat))
        otherwise
            set(handles.iqtool, 'Pointer', 'arrow');
            return
    end

    % Get the currentline
    xLineCurrent = get(lineDrawCurrent,'xdata');
    yLineCurrent = get(lineDrawCurrent,'ydata');
    
    % And the currentpoint
    pointCursorCurrent = get(axesCurrent,'currentpoint');
    pointRounded = floor(pointCursorCurrent) + ceil((pointCursorCurrent-floor(pointCursorCurrent))/handles.xIncrement) * handles.xIncrement;
    pointCursorCurrent = pointRounded;
                      
    % If the selected axes is something, continue
    if handles.selectedAxes > 0 &&...
            (strcmp(get(handles.iqtool,'selectiontype'),'normal') || ...
            strcmp(get(handles.iqtool,'selectiontype'),'alt') || ...
            strcmp(get(handles.iqtool,'selectiontype'),'open'))

        % Track the movements of the x tracker
        set(handles.lineTrackXAxes1,...
            'xdata', [pointCursorCurrent(1,1), pointCursorCurrent(1,1)],...
            'ydata', [handles.yMinAxes1, handles.yMaxAxes1]);
        
        if strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
            set(handles.lineTrackYAxes1,...
                'xdata', [handles.xMin, handles.xMax],...
                'ydata', [pointCursorCurrent(1,2), pointCursorCurrent(1,2)]);
        end
                            
        set(handles.lineTrackXAxes2,...
            'xdata', [pointCursorCurrent(1,1), pointCursorCurrent(1,1)],...
            'ydata', [handles.yMinAxes2, handles.yMaxAxes2]);
        
        if strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
            set(handles.lineTrackYAxes2,...
                'xdata', [handles.xMin, handles.xMax],...
                'ydata', [pointCursorCurrent(1,2), pointCursorCurrent(1,2)]);
        end
        
        % Decided if CTRL is pressed and maintain level
        yValueCurrent = pointCursorCurrent(1,2);
        switch handles.currentKey
            case 'control'
                yValueCurrent = yLineCurrent(end);
            otherwise
                yValueCurrent = pointCursorCurrent(1,2);
        end
        
        % Don't draw if the plot is maxed out
        if ~any(xLineCurrent >= handles.xMax)        
            % If the cursor is moving, and the mouse is down, and the x value
            % is incrementing, draw on the current line
            if handles.isDrawing &&...
                    pointCursorCurrent(1,1) > xDataCurrent && ...
                    pointCursorCurrent(1,1) <= handles.xMax && ...
                    pointCursorCurrent(1,2) <= yDataMaxCurrent && ...
                    pointCursorCurrent(1,2) >= yDataMinCurrent && ...
                    ~any(pointCursorCurrent(1,1) <= xLineCurrent)
                switch handles.selectedAxes
                    case 1                       
                        % Draw on the draw line
                        set(handles.lineDrawAxes1,...
                            'xdata', [xLineCurrent, pointCursorCurrent(1,1)],...
                            'ydata', [yLineCurrent, yValueCurrent]);

                        % Trace the preview line
                        set(handles.lineNextAxes1,...
                                'xdata', handles.lineDrawAxes1.XData,...
                                'ydata', handles.lineDrawAxes1.YData);

                        handles.xCurrentAxes1 = pointCursorCurrent(1,1);

                        % Trace the reference if importing IQ
                        if strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                            set(handles.lineNextAxes2,...
                                'xdata', handles.lineDrawAxes1.XData,...
                                'ydata', handles.lineDrawAxes1.YData);
                        end

                        % Update the GUI
                        guidata(hObject, handles);
                        drawnow;
                    case 2
                        % If not overlaying on the custom trace, draw on axes 2
                        if ~strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                            set(handles.lineDrawAxes2,...
                                'xdata', [xLineCurrent, pointCursorCurrent(1,1)],...
                                'ydata', [yLineCurrent, yValueCurrent]);

                            set(handles.lineNextAxes2,...
                                'xdata', handles.lineDrawAxes2.XData,...
                                'ydata', handles.lineDrawAxes2.YData);

                            handles.xCurrentAxes2 = pointCursorCurrent(1,1);
                            guidata(hObject, handles);
                            drawnow;
                        end
                end        

            % If not drawing, (preview)   
            else    %~any(pointCursorCurrent(1,1) <= xLineCurrent) &&...
                    %pointCursorCurrent(1,1) <= handles.xMax % && pointCursor(1,2) <= yDataMax && pointCursor(1,2) >= yDataMin            

                % Limit the X values to the drawing limits
                xValueCurrent = pointCursorCurrent(1,1);
                if any(xValueCurrent <= xLineCurrent)
                    xValueCurrent = max(xLineCurrent) + handles.xIncrement;
                elseif xValueCurrent >= handles.xMax 
                    xValueCurrent = handles.xMax;
                end

                % Limit the Y values to the drawing limits
                if yValueCurrent > yDataMaxCurrent
                    yValueCurrent = yDataMaxCurrent;
                elseif yValueCurrent < yDataMinCurrent
                    yValueCurrent = yDataMinCurrent;
                end

                switch handles.selectedAxes
                    case 1   
                            if ~isempty(lineDrawCurrent.XData)% handles.isAxes1Initialized
                                set(handles.lineNextAxes1,...
                                    'xdata',[xLineCurrent, xValueCurrent],...
                                    'ydata',[yLineCurrent, yValueCurrent]);    
                            else
                                set(handles.lineNextAxes1,...
                                    'xdata',[0, handles.xMax],...
                                    'ydata',[yNext, yNext]);
                                handles.xCurrentAxes1 = 0;
                                handles.yCurrentAxes1 = yValueCurrent;
                                guidata(hObject, handles);
                            end                        
                            drawnow;
                    case 2
                        if ~strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                            if ~isempty(lineDrawCurrent.XData) %handles.isAxes2Initialized
                                set(handles.lineNextAxes2,...
                                    'xdata',[xLineCurrent, xValueCurrent],...
                                    'ydata',[yLineCurrent, yValueCurrent]);
                            else
                                set(handles.lineNextAxes2,...
                                    'xdata',[0, handles.xMax],...
                                    'ydata',[yNext, yNext]);
                                handles.xCurrentAxes2 = 0;
                                handles.yCurrentAxes2 = yValueCurrent;
                                guidata(hObject, handles);
                            end                        
                            drawnow;    
                        end
                end
            end
        end
    end    
end

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function iqtool_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to iqtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % See which is selected
    axesCurrent = handles.axes1;        
    lineDrawCurrent = handles.lineDrawAxes1;            
    xDataCurrent = handles.xCurrentAxes1;
    yDataMin = handles.yMinAxes1;
    yDataMax = handles.yMaxAxes1;
    
    switch handles.selectedAxes
        case 1
        case 2
            axesCurrent = handles.axes2;
            lineDrawCurrent = handles.lineDrawAxes2;
            xDataCurrent = handles.xCurrentAxes2;
            yDataMin = handles.yMinAxes2;
            yDataMax = handles.yMaxAxes2;            
        otherwise
            return
    end
    
    % Update handles structure
    handles.isDrawing = 1;
    guidata(hObject, handles);

    % Link to the current line
    xLineCurrent = get(lineDrawCurrent,'xdata');
    yLineCurrent = get(lineDrawCurrent,'ydata');
    
    % Link to the current cursor
    pointCursor = get(axesCurrent,'currentpoint');
    pointRounded = floor(pointCursor) + ceil((pointCursor-floor(pointCursor))/handles.xIncrement) * handles.xIncrement;
    pointCursor = pointRounded;
    
    yValueCurrent = pointCursor(1,2);
    switch handles.currentKey
        case 'control'
            yValueCurrent = yLineCurrent(end);
        otherwise
            yValueCurrent = pointCursor(1,2);
    end
    
    % Limit the Y values to their extents
    yNext = pointCursor(1,2);
    if yNext > yDataMax
        yNext = yDataMax;
    elseif yNext < yDataMin
        yNext = yDataMin;
    end

    if yValueCurrent > yDataMax
        yValueCurrent = yDataMax;
    elseif yValueCurrent < yDataMin
        yValueCurrent = yDataMin;
    end
    
    % Don't draw if the plot is maxed out
    if ~any(xLineCurrent >= handles.xMax)     
        % Only update if x value greater than the previous
        % If not drawing and within range, draw
        if pointCursor(1,1) > xDataCurrent &&...
                pointCursor(1,1) <= handles.xMax % && pointCursor(1,2) <= yDataMax && pointCursor(1,2) >= yDataMin
            if handles.wasDrawing
        %         set(lineDraw,'xdata',[tmpx,tmpx(1)],'ydata',[tmpy,tmpy(1)]);
        %         setappdata(gcf,'linedraw',lineDraw);
        %         setappdata(gcf,'currentxdata',a(1,1));
        %         setappdata(gcf,'currentydata',a(1,2));
        %         drawnow;
            else         
                % Draw depending on the axes...if initialized draw a line,
                % otherwise draw the first point
                switch handles.selectedAxes
                    case 1   
                        if ~isempty(lineDrawCurrent.XData) %handles.isAxes1Initialized
                            if pointCursor(1,1) + handles.xIncrement > max(handles.lineDrawAxes1.XData)
                                set(handles.lineDrawAxes1,...
                                    'xdata', [xLineCurrent, pointCursor(1,1)],...
                                    'ydata', [yLineCurrent, yValueCurrent]);
                                handles.xCurrentAxes1 = pointCursor(1,1);
                                handles.yCurrentAxes1 = yValueCurrent;
                            end
                        else
                            set(handles.lineDrawAxes1,...
                                'xdata', 0,...
                                'ydata', yNext);
                            handles.xCurrentAxes1 = 0;
                            handles.yCurrentAxes1 = yNext;
                            %handles.isAxes1Initialized = 1;
                        end

                        % If overlaying over the reference plot, draw on
                        % axes 2
                        if strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                            set(handles.lineNextAxes2,...
                                'xdata', handles.lineDrawAxes1.XData,...
                                'ydata', handles.lineDrawAxes1.YData);
                        end

                    case 2
                        % If not using the reference, draw
                        if ~strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                            if ~isempty(lineDrawCurrent.XData) %handles.isAxes2Initialized
                                if pointCursor(1,1) + handles.xIncrement > max(handles.lineDrawAxes2.XData)
                                    set(handles.lineDrawAxes2,...
                                        'xdata', [xLineCurrent, pointCursor(1,1)],...
                                        'ydata', [yLineCurrent, yValueCurrent]);
                                    handles.xCurrentAxes2 = pointCursor(1,1);
                                    handles.yCurrentAxes12 = yValueCurrent;
                                end
                            else
                                set(handles.lineDrawAxes2,...
                                    'xdata', 0,...
                                    'ydata', yNext);
                                handles.xCurrentAxes2 = 0;
                                handles.yCurrentAxes2 = yNext;
                                %handles.isAxes2Initialized = 1;
                            end
                        end
                end
                
                % Update the GUI
                drawnow;            
                handles.wasDrawing = 1; 
                guidata(hObject, handles);
            end
            
        % If want to add next step so it's the next x value...
        elseif pointCursor(1,1) <= xDataCurrent &&...
               (isempty(xLineCurrent) || (xDataCurrent + handles.xIncrement > xLineCurrent(end)))
                switch handles.selectedAxes
                    case 1   
                        set(handles.lineDrawAxes1,...
                            'xdata', [xLineCurrent, xDataCurrent + handles.xIncrement],...
                            'ydata', [yLineCurrent, yValueCurrent]);                    
                        handles.xCurrentAxes1 = pointCursor(1,1);
                        handles.yCurrentAxes1 = yValueCurrent;
                        %handles.isAxes1Initialized = 1;

                        if strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                            set(handles.lineNextAxes2,...
                                'xdata', handles.lineDrawAxes1.XData,...
                                'ydata', handles.lineDrawAxes1.YData);
                        end
                    case 2
                        if ~strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                            set(handles.lineDrawAxes2,...
                                'xdata', [xLineCurrent, xDataCurrent + handles.xIncrement],...
                                'ydata', [yLineCurrent, yValueCurrent]);
                            handles.xCurrentAxes2 = pointCursor(1,1);
                            handles.yCurrentAxes2 = yValueCurrent;
                            %handles.isAxes2Initialized = 1;
                        end
                end

                % Update the GUI
                drawnow;
                handles.wasDrawing = 0;
                guidata(hObject, handles);
        end  
    end
end

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function iqtool_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to iqtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % If there was a line, and was clicked beyond the bounds, add the last
    % piece
    if handles.isDrawing     
        try
            switch handles.selectedAxes
                case 1                       
                    pointCursor = get(handles.axes1,'currentpoint');
                    pointRounded = floor(pointCursor) + ceil((pointCursor-floor(pointCursor))/handles.xIncrement) * handles.xIncrement;
                    pointCursor = pointRounded;

                    if pointCursor(1,1) >= handles.xMax && max(handles.lineDrawAxes1.XData) < handles.xMax
                        set(handles.lineDrawAxes1,...
                            'xdata', handles.lineNextAxes1.XData,...
                            'ydata', handles.lineNextAxes1.YData);                                              
                        handles.xCurrentAxes1 = max(handles.lineNextAxes1.XData);
                        handles.yCurrentAxes1 = max(handles.lineNextAxes1.YData);
                        %handles.isAxes1Initialized = 1;
                        drawnow;  
                        guidata(hObject, handles);

                        if strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                            set(handles.lineNextAxes2,...
                                'xdata', handles.lineDrawAxes1.XData,...
                                'ydata', handles.lineDrawAxes1.YData);
                        end
                    end
                case 2
                    if ~strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                        pointCursor = get(handles.axes2,'currentpoint');
                        pointRounded = floor(pointCursor) + ceil((pointCursor-floor(pointCursor))/handles.xIncrement) * handles.xIncrement;
                        pointCursor = pointRounded;

                        if pointCursor(1,1) >= handles.xMax && max(handles.lineDrawAxes2.XData) < handles.xMax
                            set(handles.lineDrawAxes2,...
                                'xdata', handles.lineNextAxes2.XData,...
                                'ydata', handles.lineNextAxes2.YData);
                            handles.xCurrentAxes2 = max(handles.lineNextAxes2.XData);
                            handles.yCurrentAxes2 = max(handles.lineNextAxes2.YData);
                            %handles.isAxes2Initialized = 1;
                            drawnow;   
                            guidata(hObject, handles);
                        end
                    end
            end
        catch
        end
    end

    % Then update the line
    handles.isDrawing = 0;
    handles.wasDrawing = 0;
    guidata(hObject, handles);
end

% --- Executes on key release with focus on iqtool or any of its controls.
function iqtool_WindowKeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to iqtool (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)

    handles.currentKey = 'none';
    guidata(hObject, handles);
end

% --- Executes on key press with focus on iqtool or any of its controls.
function iqtool_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to iqtool (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

    if strcmp(eventdata.Key, 'x')
        handles.currentKey = 'none';
        handlePlotEntry(hObject, eventdata, handles);        
    else
        handles.currentKey = eventdata.Key;
        guidata(hObject, handles);
    end
end

function handlePlotEntry(hObject, eventdata, handles)

    % First make sure there is an axis selected
    
    % See which is selected
    handles.selectedAxes = 0;
    
    pointCheckAxes1 = get(handles.axes1,'currentpoint');
    if pointCheckAxes1(1,3) <= 1 && pointCheckAxes1(1,1) <= handles.axes1.XLim(2)
        handles.selectedAxes = 1;
    end
    
    pointCheckAxes2 = get(handles.axes2,'currentpoint');
    if pointCheckAxes2(1,3) <= 1 && pointCheckAxes2(1,1) <= handles.axes2.XLim(2)
        handles.selectedAxes = 2;
    end
    
    % Link to the selected axes
    axesCurrent = handles.axes1;
    lineDrawCurrent = handles.lineDrawAxes1;            
    xDataCurrent = handles.xCurrentAxes1;    
    yDataMinCurrent = handles.yMinAxes1;
    yDataMaxCurrent = handles.yMaxAxes1;
    ylabel = get(handles.textTopPlot, 'String');
    
    switch handles.selectedAxes
        case 1                 
            % Limit the y next to the limits of the plot
            yNext = pointCheckAxes1(1,2);
            if yNext > yDataMaxCurrent
                yNext = yDataMaxCurrent;
            elseif yNext < yDataMinCurrent
                yNext = yDataMinCurrent;
            end
            
            % Set the pointer to track
            set(handles.iqtool, 'Pointer', 'crosshair');
            set(handles.textTopPlotXText, 'String', num2str(pointCheckAxes1(1,1), '%10.5e\n'))
            set(handles.textBottomPlotXText, 'String', num2str(pointCheckAxes1(1,1), '%10.5e\n'))
            set(handles.textTopPlotYText, 'String', num2str(yNext, '%4.2f\n'))
        case 2                        
            axesCurrent = handles.axes2;
            lineDrawCurrent = handles.lineDrawAxes2;
            xDataCurrent = handles.xCurrentAxes2;
            yDataMinCurrent = handles.yMinAxes2;
            yDataMaxCurrent = handles.yMaxAxes2;
            ylabel = get(handles.textBottomPlot, 'String');
            
            % Limit the y next to the limits of the plot
            yNext = pointCheckAxes2(1,2);
            if yNext > yDataMaxCurrent
                yNext = yDataMaxCurrent;
            elseif yNext < yDataMinCurrent
                yNext = yDataMinCurrent;
            end
            
            % Set the pointer to track
            set(handles.iqtool, 'Pointer', 'crosshair');
            set(handles.textTopPlotXText, 'String', num2str(pointCheckAxes2(1,1), '%10.5e\n'))
            set(handles.textBottomPlotXText, 'String', num2str(pointCheckAxes2(1,1), '%10.5e\n'))
            set(handles.textBottomPlotYText, 'String', num2str(yNext, handles.coordinateFormat))
        otherwise
            set(handles.iqtool, 'Pointer', 'arrow');
            return
    end

    % Get the currentline
    xLineCurrent = get(lineDrawCurrent,'xdata');
    yLineCurrent = get(lineDrawCurrent,'ydata');
    
    % And the currentpoint
    pointCursorCurrent = get(axesCurrent,'currentpoint');
    pointRounded = floor(pointCursorCurrent) + ceil((pointCursorCurrent-floor(pointCursorCurrent))/handles.xIncrement) * handles.xIncrement;
    pointCursorCurrent = pointRounded;

    % If there is a point to add, prompt for it
    if ~any(xLineCurrent >= handles.xMax) 
        
        % Limit the X values to the drawing limits
        xValueCurrent = pointCursorCurrent(1,1);
        if any(xValueCurrent <= xLineCurrent)
            xValueCurrent = max(xLineCurrent) + handles.xIncrement;
        elseif xValueCurrent >= handles.xMax 
            xValueCurrent = handles.xMax;
        end
        
        % Limit the Y values to the drawing limits
        yValueCurrent = pointCursorCurrent(1,2);
        if yValueCurrent > yDataMaxCurrent
            yValueCurrent = yDataMaxCurrent;
        elseif yValueCurrent < yDataMinCurrent
            yValueCurrent = yDataMinCurrent;
        end
        
        if ~isempty(lineDrawCurrent.XData)
            prompt = {'Enter Time (sec):',['Enter ' ylabel ':']};
            dlgtitle = 'Manual Data Entry';
            dims = [1 100];
            definput = {num2str(xValueCurrent), num2str(yValueCurrent)};
            response = inputdlg(prompt,dlgtitle,dims,definput);
            
            % Act on the data entry to see if it can be added
            if ~isempty(response)
                xResponse = str2double(response{1});
                yResponse = str2double(response{2});
            else
                return
            end
        else
            prompt = {['Enter ' ylabel ':']};
            dlgtitle = 'Manual Data Entry';
            dims = [1 100];
            definput = {num2str(yValueCurrent)};
            response = inputdlg(prompt,dlgtitle,dims,definput);
            
            if ~isempty(response)
                xResponse = 0;
                yResponse = str2double(response{1});
            else
                return
            end
        end
                    
        if (xResponse > xDataCurrent || xDataCurrent == 0) &&...
                xResponse <= handles.xMax &&...
                yResponse <= yDataMaxCurrent &&...
                yResponse >= yDataMinCurrent
            switch handles.selectedAxes
            case 1   
                    if ~isempty(lineDrawCurrent.XData) %handles.isAxes1Initialized
                        if xResponse + handles.xIncrement > max(handles.lineDrawAxes1.XData)
                            set(handles.lineDrawAxes1,...
                                'xdata', [xLineCurrent, xResponse],...
                                'ydata', [yLineCurrent, yResponse]);
                            handles.xCurrentAxes1 = xResponse;
                            handles.yCurrentAxes1 = yResponse;
                        end
                    else
                        set(handles.lineDrawAxes1,...
                            'xdata', [xLineCurrent, 0],...
                            'ydata', [yLineCurrent, yResponse]);
                        handles.xCurrentAxes1 = 0;
                        handles.yCurrentAxes1 = yResponse;
                        % handles.isAxes1Initialized = 1;
                    end
                    
                    % Trace the preview line
                    set(handles.lineNextAxes1,...
                            'xdata', handles.lineDrawAxes1.XData,...
                            'ydata', handles.lineDrawAxes1.YData);

                    % If overlaying over the reference plot, draw on
                    % axes 2
                    if strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                        set(handles.lineNextAxes2,...
                            'xdata', handles.lineDrawAxes1.XData,...
                            'ydata', handles.lineDrawAxes1.YData);
                    end

                case 2
                    % If not using the reference, draw
                    if ~strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
                        if ~isempty(lineDrawCurrent.XData) %handles.isAxes2Initialized
                            if xResponse + handles.xIncrement > max(handles.lineDrawAxes2.XData)
                                set(handles.lineDrawAxes2,...
                                    'xdata', [xLineCurrent, xResponse],...
                                    'ydata', [yLineCurrent, yResponse]);
                                handles.xCurrentAxes2 = xResponse;
                                handles.yCurrentAxes12 = yResponse;
                            end
                        else
                            set(handles.lineDrawAxes2,...
                                'xdata', 0,...
                                'ydata', yResponse);
                            handles.xCurrentAxes2 = 0;
                            handles.yCurrentAxes2 = yResponse;
                            %handles.isAxes2Initialized = 1;
                        end
                        
                        % Trace the preview line
                        set(handles.lineNextAxes2,...
                                'xdata', handles.lineDrawAxes2.XData,...
                                'ydata', handles.lineDrawAxes2.YData);
                    end                                        
            end            
            guidata(hObject, handles);
            drawnow;
        end       
    end
end


% --- Executes on button press in pushbuttonClearTopPlot.
function pushbuttonClearTopPlot_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClearTopPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    clearPlots(hObject, 1, handles);
end

% --- Executes on button press in pushbuttonClearBottomPlot.
function pushbuttonClearBottomPlot_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClearBottomPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    clearPlots(hObject, 2, handles);
end

% --- Executes on button press in pushbuttonUndoTopPlot.
function pushbuttonUndoTopPlot_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUndoTopPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    xArray = get(handles.lineDrawAxes1, 'xdata');
    yArray = get(handles.lineDrawAxes1, 'ydata');

    if length(xArray) > 1
        set(handles.lineDrawAxes1,...
            'xdata', xArray(1:(end-1)),...
            'ydata', yArray(1:(end-1)));

        set(handles.lineNextAxes1,...
            'xdata', xArray(1:(end-1)),...
            'ydata', yArray(1:(end-1)));
        
        handles.xCurrentAxes1 = xArray(end-1);
        handles.yCurrentAxes1 = yArray(end-1);
        
        if strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})           
            set(handles.lineNextAxes2,...
                'xdata', handles.lineDrawAxes1.XData,...
                'ydata', handles.lineDrawAxes1.YData);
        end
    else
        set(handles.lineDrawAxes1,...
            'xdata', [],...
            'ydata', []);

        set(handles.lineNextAxes1,...
            'xdata', [],...
            'ydata', []);
        
        handles.isDrawing = 0;              % Is drawing occurring
        handles.wasDrawing = 0;             % Was drawing occurring
        %handles.isAxes1Initialized = 0;     % Was first point drawn

        handles.xCurrentAxes1 = handles.xInitial;
        handles.yCurrentAxes1 = handles.yInitialAxes1;
    end
    
    guidata(hObject, handles);
end

% --- Executes on button press in pushbuttonUndoBottomPlot.
function pushbuttonUndoBottomPlot_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUndoBottomPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    xArray = get(handles.lineDrawAxes2, 'xdata');
    yArray = get(handles.lineDrawAxes2, 'ydata');

    if length(xArray) > 1
        set(handles.lineDrawAxes2,...
            'xdata', xArray(1:(end-1)),...
            'ydata', yArray(1:(end-1)));

        set(handles.lineNextAxes2,...
            'xdata', xArray(1:(end-1)),...
            'ydata', yArray(1:(end-1)));
        
        handles.xCurrentAxes2 = xArray(end-1);
        handles.yCurrentAxes2 = yArray(end-1);
    else
        set(handles.lineDrawAxes2,...
            'xdata', [],...
            'ydata', []);

        set(handles.lineNextAxes2,...
            'xdata', [],...
            'ydata', []);
        
        handles.isDrawing = 0;              % Is drawing occurring
        handles.wasDrawing = 0;             % Was drawing occurring
        %handles.isAxes2Initialized = 0;     % Was first point drawn

        handles.xCurrentAxes2 = handles.xInitial;
        handles.yCurrentAxes2 = handles.yInitialAxes2;
    end
    
    guidata(hObject, handles);
end

% --- Executes on selection change in popupmenuCreationMode.
function popupmenuCreationMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuCreationMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuCreationMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuCreationMode

    set(handles.lineImportAxes1,...
        'xdata', [],...
        'ydata', []);
    
    set(handles.lineTrackYAxes2,...
        'xdata', [],...
        'ydata', []);
    
    set(handles.lineTrackYAxes1,...
        'xdata', [],...
        'ydata', []);

    switch handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value}
        case 'Magnitude (dB) and Phase'
            
            if ~strcmp(handles.axes1.YLabel.String, 'dB')
                clearPlots(hObject, 1, handles);
            end
            
            clearPlots(hObject, 2, handles);
                        
            labelPlots(hObject, 0, handles,...
                'Magnitude (dB)', 'Phase (degrees)',...
                'Time (sec)', 'Time (sec)',...
                'dB', 'Degrees');
            handles.coordinateFormat = '%4.2f\n';

            set(handles.editCustomIQ, 'Enable', 'off');
            set(handles.pushbuttonLoadCustomIQ, 'Enable', 'off');
            set(handles.editPRI, 'Enable', 'on');
            set(handles.editOffset, 'Enable', 'on');
            set(handles.pushbuttonDisplayCustom, 'Enable', 'off');
            set(handles.pushbuttonLoadCustomIQ, 'Enable', 'off');
            set(handles.pushbuttonShowVSACustom, 'Enable', 'off');
            set(handles.pushbuttonClearBottomPlot, 'Enable', 'on');
            set(handles.pushbuttonUndoBottomPlot, 'Enable', 'on');
            
            %handles.isAxes2Initialized = 0;     % Was first point drawn
            handles.xCurrentAxes2 = handles.xInitial;
            handles.yCurrentAxes2 = handles.yInitialAxes2; 
        case 'Magnitude (dB) and Frequency'
            
            if ~strcmp(handles.axes1.YLabel.String, 'dB')
                clearPlots(hObject, 1, handles);
            end
            
            clearPlots(hObject, 2, handles);
            
            labelPlots(hObject, 0, handles,...
                'Magnitude (dB)', 'Frequency (Hz)',...
                'Time (sec)', 'Time (sec)',...
                'dB', 'Hz');
            handles.coordinateFormat = '%10.5e\n';
            
            set(handles.editCustomIQ, 'Enable', 'off');
            set(handles.pushbuttonLoadCustomIQ, 'Enable', 'off');
            set(handles.editPRI, 'Enable', 'on');
            set(handles.editOffset, 'Enable', 'on');
            set(handles.pushbuttonLoadCustomIQ, 'Enable', 'off');
            set(handles.pushbuttonDisplayCustom, 'Enable', 'off');
            set(handles.pushbuttonShowVSACustom, 'Enable', 'off');
            set(handles.pushbuttonClearBottomPlot, 'Enable', 'on');
            set(handles.pushbuttonUndoBottomPlot, 'Enable', 'on');
            
            %handles.isAxes2Initialized = 0;     % Was first point drawn
            handles.xCurrentAxes2 = handles.xInitial;
            handles.yCurrentAxes2 = handles.yInitialAxes2; 
        case 'I/Q'
            clearPlots(hObject, 0, handles);
            
            labelPlots(hObject, 0, handles,...
                'I', 'Q',...
                'Time (sec)', 'Time (sec)',...
                '', '');
            handles.coordinateFormat = '%4.2f\n';
            set(handles.editCustomIQ, 'Enable', 'off');
            set(handles.editOffset, 'Enable', 'on');
            set(handles.pushbuttonLoadCustomIQ, 'Enable', 'off');
            set(handles.pushbuttonDisplayCustom, 'Enable', 'off');
            set(handles.pushbuttonShowVSACustom, 'Enable', 'off');
            set(handles.editPRI, 'Enable', 'on');
        case 'Magnitude (dB) on Custom I/Q'
            clearPlots(hObject, 0, handles);
            
            labelPlots(hObject, 0, handles,...
                'Magnitude (dB)', 'Input Signal (dB)',...
                'Time (sec)', 'Time (sec)',...
                'dB', 'dB');
            handles.coordinateFormat = '%4.2f\n';
            set(handles.editCustomIQ, 'Enable', 'on');
            set(handles.pushbuttonLoadCustomIQ, 'Enable', 'on'); 
            set(handles.pushbuttonDisplayCustom, 'Enable', 'on');
            set(handles.pushbuttonShowVSACustom, 'Enable', 'on');
            set(handles.editPRI, 'Enable', 'off');
            set(handles.editOffset, 'Enable', 'off');
            set(handles.pushbuttonClearBottomPlot, 'Enable', 'off');
            set(handles.pushbuttonUndoBottomPlot, 'Enable', 'off');            
            
            %handles.isAxes1Initialized = 0;     % Was first point drawn
            handles.xCurrentAxes1 = handles.xInitial;
            handles.yCurrentAxes1 = handles.yInitialAxes1;   
    end
    
    scalePlots(hObject, 0, handles);       
end

function labelPlots(hObject, eventdata, handles,...
    titleTopPlot, titleBottomPlot, xlabelTopPlot, xlabelBottomPlot, ylabelTopPlot, ylabelBottomPlot)
% This function labels the plots in the setup
    
    set(handles.textTopPlot, 'String', titleTopPlot)
    set(handles.textBottomPlot, 'String', titleBottomPlot)
    set(handles.axes1.XLabel, 'String', xlabelTopPlot)
    set(handles.axes2.XLabel, 'String', xlabelBottomPlot)
    set(handles.axes1.YLabel, 'String', ylabelTopPlot)
    set(handles.axes2.YLabel, 'String', ylabelBottomPlot) 

    guidata(hObject, handles);
end

function clearPlots(hObject, eventdata, handles)
% This function clears the plots in the setup

clearPlotTop = false;
clearPlotBottom = false;

    switch eventdata
        case 0
            clearPlotTop = true;
            clearPlotBottom = true;
        case 1
            clearPlotTop = true;
        case 2
            clearPlotBottom = true;
    end

    if clearPlotTop
        set(handles.lineDrawAxes1,...
            'xdata', [],...
            'ydata', []);

        set(handles.lineNextAxes1,...
            'xdata', [],...
            'ydata', []);

        %handles.isAxes1Initialized = 0;     % Was first point drawn

        handles.xCurrentAxes1 = handles.xInitial;
        handles.yCurrentAxes1 = handles.yInitialAxes1;   

        if strcmp('Magnitude (dB) on Custom I/Q', handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value})
            set(handles.lineNextAxes2,...
            'xdata', [],...
            'ydata', []);
        end

        guidata(hObject, handles);
    end

    if clearPlotBottom
        set(handles.lineDrawAxes2,...
            'xdata', [],...
            'ydata', []);

        set(handles.lineNextAxes2,...
            'xdata', [],...
            'ydata', []);

        set(handles.lineImportAxes1,...
            'xdata', [],...
            'ydata', []);

        %handles.isAxes2Initialized = 0;     % Was first point drawn

        handles.xCurrentAxes2 = handles.xInitial;
        handles.yCurrentAxes2 = handles.yInitialAxes2;
        guidata(hObject, handles);
    end

    handles.isDrawing = 0;              % Is drawing occurring
    handles.wasDrawing = 0;             % Was drawing occurring
    
    guidata(hObject, handles);
end

function scalePlots(hObject, eventdata, handles)
% This function scales the plots

    switch handles.popupmenuCreationMode.String{handles.popupmenuCreationMode.Value}
        case 'Magnitude (dB) and Phase'
            
            handles.axisRangeYAxes1 = [-120 0];         % The range of the y axis of the top
            handles.axisRangeYAxes2 = [-180 180];       % The range of the y axis of the bottom
            
        case 'Magnitude (dB) and Frequency'
            
            handles.axisRangeYAxes1 = [-120 0];         % The range of the y axis of the top
            
            sampleRate = str2num(get(handles.editSampleRate, 'String'));            
            handles.axisRangeYAxes2 = [-sampleRate/2, sampleRate/2];       % The range of the y axis of the bottom
                        
        case 'I/Q'

            handles.axisRangeYAxes1 = [-1 1];         % The range of the y axis of the top
            handles.axisRangeYAxes2 = [-1 1];       % The range of the y axis of the bottom
        
        case 'Magnitude (dB) on Custom I/Q'

            handles.axisRangeYAxes1 = [-120 0];         % The range of the y axis of the top
            handles.axisRangeYAxes2 = [-120 0];         % The range of the y axis of the bottom
    end
    
    
    % Limits
    handles.yMaxAxes1 = handles.axisRangeYAxes1(2);
    handles.yMaxAxes2 = handles.axisRangeYAxes2(2);
    handles.yMinAxes1 = handles.axisRangeYAxes1(1);
    handles.yMinAxes2 = handles.axisRangeYAxes2(1);

    handles.xMin = handles.axisRangeX(1);
    handles.xMax = handles.axisRangeX(2);
    handles.xIncrement = handles.xIncrement;

    
    timeExtend = abs(handles.axisRangeX(2) - handles.axisRangeX(1)) * 0.1;
    axes1Extend = abs(handles.axisRangeYAxes1(2) - handles.axisRangeYAxes1(1)) * 0.1;
    axes2Extend = abs(handles.axisRangeYAxes2(2) - handles.axisRangeYAxes2(1)) * 0.1;
    
    handles.axes1.XLim = [handles.axisRangeX(1), handles.axisRangeX(2) + timeExtend];
    handles.axes1.YLim = [handles.axisRangeYAxes1(1) - axes1Extend, handles.axisRangeYAxes1(2) + axes1Extend];
    set(handles.axes1, 'XGrid', 'on')
    set(handles.axes1, 'YGrid', 'on')
    set(handles.axes1, 'XMinorGrid', 'on')
    set(handles.axes1, 'YMinorGrid', 'on')
    set(handles.axes1, 'Box', 'on')

    handles.axes2.XLim = [handles.axisRangeX(1) handles.axisRangeX(2) + timeExtend];
    handles.axes2.YLim = [handles.axisRangeYAxes2(1) - axes2Extend, handles.axisRangeYAxes2(2) + axes2Extend];
    set(handles.axes2, 'XGrid', 'on')
    set(handles.axes2, 'YGrid', 'on')
    set(handles.axes2, 'XMinorGrid', 'on')
    set(handles.axes2, 'YMinorGrid', 'on')
    set(handles.axes2, 'Box', 'on')
    
    guidata(hObject, handles);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% File %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)
% hObject    handle to menuFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menuSaveWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[Y, marker, sampleRate, ~] = calculate_draw(handles, 0);
iqsavewaveform(Y, sampleRate, 'marker', marker);
end

% --------------------------------------------------------------------
function menuLoadSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menuLoadSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqloadsettings(handles);

end

% --------------------------------------------------------------------
function menuSaveSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqsavesettings(handles);

end
