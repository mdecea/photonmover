function varargout = multiCalDialog_GUI(varargin)
% MULTICALDIALOG_GUI MATLAB code for multiCalDialog_GUI.fig
%      MULTICALDIALOG_GUI, by itself, creates a new MULTICALDIALOG_GUI or raises the existing
%      singleton*.
%
%      H = MULTICALDIALOG_GUI returns the handle to a new MULTICALDIALOG_GUI or the handle to
%      the existing singleton*.
%
%      MULTICALDIALOG_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTICALDIALOG_GUI.M with the given input arguments.
%
%      MULTICALDIALOG_GUI('Property','Value',...) creates a new MULTICALDIALOG_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before multiCalDialog_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to multiCalDialog_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help multiCalDialog_GUI

% Last Modified by GUIDE v2.5 04-Dec-2017 09:44:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @multiCalDialog_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @multiCalDialog_GUI_OutputFcn, ...
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


% --- Executes just before multiCalDialog_GUI is made visible.
function multiCalDialog_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to multiCalDialog_GUI (see VARARGIN)

% Choose default command line output for multiCalDialog_GUI
handles.output = -1;

%% Load up variables from multicarrier spec
numCarriers =  getappdata(0,'numOfCarriers');
carrierSpacing = getappdata(0,'carrierSpacing');
carrierOffsetText = getappdata(0,'carrierOffsetText');
channelCenters = getappdata(0, 'chCenterFreq');
channelBand = getappdata(0, 'chBand');
fc = getappdata(0,'vsaFc');
filterLength = getappdata(0,'vsaFilterLength');
convergence = getappdata(0,'vsaConvergence');
resultLength = getappdata(0,'vsaResultLength');
oldAdjustment = getappdata(0,'oldAdjustment');

%% Update texts  
set(handles.numberOfCarriersText, 'String', numCarriers);
set(handles.carrierSpacingText, 'String', carrierSpacing);
set(handles.carrierOffsetText, 'String', carrierOffsetText);
set(handles.vsaFcText, 'String', fc);
set(handles.vsaFilterLengthText, 'String', filterLength);
set(handles.vsaResultLengthText, 'String', resultLength);
set(handles.vsaConvergenceText, 'String', convergence);

%% Update Table
currentData = get(handles.uitable, 'data');
currLength = size(currentData,1); % check the number of entries
ccNum = numCarriers; 
newData = currentData; % copy the data
if ccNum < currLength % reduce size if needed
    newData((ccNum+1):currLength,:) =[];
end

for i = 1:ccNum
    newData{i,1} = i; % cc
    newData{i,2} = channelCenters(i); % Centre frequency
    newData{i,3} = channelBand;  %str2double(carrierSpacing); %width
    newData{i,4} = '-'; %measured channel power
    newData{i,5} = -20; % default
    newData{i,6} = 'Scope'; % default
    newData{i,7} = '';    
end

set(handles.uitable, 'data', newData);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes multiCalDialog_GUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = multiCalDialog_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1);


% --- Executes when selected cell(s) is changed in uitable.
function uitable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
% get cell

persistent lastPath;

if isempty(lastPath) 
    lastPath = 0;
end

indices = eventdata.Indices;
row = indices(:,1);
col = indices(:,2);

if col == 7 % File entry
    %% open file dialog fetch path to csv file, or leave empty
    if lastPath == 0
        [fileName,pathName, filterIndex] = uigetfile('*.cal','Select the filter cal file');
    else
        [fileName,pathName, filterIndex] = uigetfile([lastPath, '*.cal'],'Select the filter cal file');
    end
    
    if  filterIndex == 0 % dialog closed or cancelled
        entry = '';
    else
        entry = strcat(pathName,fileName);
        lastPath = pathName;
    end
    % Get current table contents
    b = hObject.Data;
    % Update the selected cellwith the filepath and name
    b{row,col} = entry;
    set(hObject,'data', b);
end
    


% --- Executes on button press in pushbuttonLoadPoints.
function pushbuttonLoadPoints_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonLoadPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%% open file mat file
[fileName,pathName, filterIndex] = uigetfile('*.mat','Open Calibration Points from File');
if  filterIndex ~= 0 
    fullPath = strcat(pathName,fileName);
    try
    load(fullPath,'calPoints');
    
    %load the table with the saved data
    set(handles.uitable, 'data', calPoints);
    catch ex
        msgbox(ex.message);
    end

end



% --- Executes on button press in pushbuttonSavePoints.
function pushbuttonSavePoints_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSavePoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
formatOut = 'mm_dd_yy';
d = datestr(now,formatOut);
defaultFileName = strcat('calPoints_', d, '.mat');
[fileName,pathName, filterIndex] = uiputfile(defaultFileName,'Save Calibration Points to File');

if filterIndex ~= 0
    fullPath = strcat(pathName,fileName);
    calPoints = get(handles.uitable, 'data');
    save(fullPath, 'calPoints');
end

% --- Executes during object creation, after setting all properties.
function uitable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uitable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

function numberOfCarriersText_Callback(hObject, eventdata, handles)
% hObject    handle to numberOfCarriersText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numberOfCarriersText as text
%        str2double(get(hObject,'String')) returns contents of numberOfCarriersText as a double

% --- Executes during object creation, after setting all properties.
function numberOfCarriersText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numberOfCarriersText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function carrierSpacingText_Callback(hObject, eventdata, handles)
% hObject    handle to carrierSpacingText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of carrierSpacingText as text
%        str2double(get(hObject,'String')) returns contents of carrierSpacingText as a double


% --- Executes during object creation, after setting all properties.
function carrierSpacingText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to carrierSpacingText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function carrierOffsetText_Callback(hObject, eventdata, handles)
% hObject    handle to carrierOffsetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of carrierOffsetText as text
%        str2double(get(hObject,'String')) returns contents of carrierOffsetText as a double


% --- Executes during object creation, after setting all properties.
function carrierOffsetText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to carrierOffsetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function vsaFcText_Callback(hObject, eventdata, handles)
% hObject    handle to vsaFcText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vsaFcText as text
%        str2double(get(hObject,'String')) returns contents of vsaFcText as a double


% --- Executes during object creation, after setting all properties.
function vsaFcText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vsaFcText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function vsaFilterLengthText_Callback(hObject, eventdata, handles)
% hObject    handle to vsaFilterLengthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vsaFilterLengthText as text
%        str2double(get(hObject,'String')) returns contents of vsaFilterLengthText as a double


% --- Executes during object creation, after setting all properties.
function vsaFilterLengthText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vsaFilterLengthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function vsaResultLengthText_Callback(hObject, eventdata, handles)
% hObject    handle to vsaResultLengthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vsaResultLengthText as text
%        str2double(get(hObject,'String')) returns contents of vsaResultLengthText as a double


% --- Executes during object creation, after setting all properties.
function vsaResultLengthText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vsaResultLengthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function vsaConvergenceText_Callback(hObject, eventdata, handles)
% hObject    handle to vsaConvergenceText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vsaConvergenceText as text
%        str2double(get(hObject,'String')) returns contents of vsaConvergenceText as a double


% --- Executes during object creation, after setting all properties.
function vsaConvergenceText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vsaConvergenceText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when entered data in editable cell(s) in uitable.
function uitable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkboxChanEqualize.
function checkboxChanEqualize_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxChanEqualize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxChanEqualize


% --- Executes on button press in pushbuttonChanPower.
function pushbuttonChanPower_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonChanPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
symbolRate = getappdata(0,'symRate');
modTypeList = getappdata(0,'modTypeList');
modTypeIdx = getappdata(0,'modTypeIdx');
filterList = getappdata(0,'filterList');
filterIdx = getappdata(0,'filterIdx');
filterBeta = getappdata(0,'filterBeta');
numCarriers = evalin('base', get(handles.numberOfCarriersText, 'String'));
resultLength = evalin('base', get(handles.vsaResultLengthText, 'String'));
tableData = get(handles.uitable, 'Data');
useHW = 1;

for i = 1:numCarriers;
    
    %set up VSA
    fc = cell2mat(tableData(i,2));
    range = cell2mat(tableData(i,5));
    mixerMode = char(tableData(i,6));
    customFilterFile = char(tableData(i,7));
    
    result = iqvsabandpower('symbolRate', symbolRate, ...
        'modType', modTypeList{modTypeIdx}, ...
        'filterType', filterList{filterIdx}, ...
        'filterBeta', filterBeta, ...
        'fc', fc , ...
        'resultLength', resultLength, ...
        'useHW', useHW, ...
        'mixerMode', mixerMode, ...
        'customFilterFile', customFilterFile, ...
        'range', range, ...
        'doOBP', 1);
    
    if (result ~= 0)
        tableData{i,4} = result;
        set(handles.uitable,'data', tableData);
        
    end
end

set(handles.checkboxChanEqualize, 'Value', 1);



% --- Executes on button press in pushbuttonUseParams.
function pushbuttonUseParams_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUseParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(0, 'multiCalParameters', get(handles.uitable, 'data'));
setappdata(0, 'chPowerCorrection', get(handles.checkboxChanEqualize, 'value'));
handles.output = 0;
guidata(hObject, handles);
uiresume(handles.figure1);
%close('Multicarrier Precorrection');
%delete(handles.figure1);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: delete(hObject) closes the figure
%setappdata(0, 'multiCalParameters', get(handles.uitable, 'data'));
uiresume(handles.figure1);
%delete(hObject);


% --- Executes on button press in pushbuttonCancel.
function pushbuttonCancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);
%close('Multicarrier Precorrection');
%delete(handles.figure1);
