function varargout = multiCarrierControl_GUI(varargin)
% MULTICARRIERCONTROL_GUI MATLAB code for multiCarrierControl_GUI.fig
%      MULTICARRIERCONTROL_GUI, by itself, creates a new MULTICARRIERCONTROL_GUI or raises the existing
%      singleton*.
%
%      H = MULTICARRIERCONTROL_GUI returns the handle to a new MULTICARRIERCONTROL_GUI or the handle to
%      the existing singleton*.
%
%      MULTICARRIERCONTROL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTICARRIERCONTROL_GUI.M with the given input arguments.
%
%      MULTICARRIERCONTROL_GUI('Property','Value',...) creates a new MULTICARRIERCONTROL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before multiCarrierControl_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to multiCarrierControl_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help multiCarrierControl_GUI

% Last Modified by GUIDE v2.5 26-Jan-2018 16:32:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @multiCarrierControl_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @multiCarrierControl_GUI_OutputFcn, ...
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


% --- Executes just before multiCarrierControl_GUI is made visible.
function multiCarrierControl_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to multiCarrierControl_GUI (see VARARGIN)

% Choose default command line output for multiCarrierControl_GUI
handles.output = -1;

 
    %% Load up variables from multicarrier spec
    numCarriers =  getappdata(0,'numOfCarriers');
    channelCenters = getappdata(0, 'chCenterFreq');
    channelBand = getappdata(0, 'chBand');
    
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
        newData{i,6} = 'Normal';
        newData{i,7} = '';
    end
    
    set(handles.uitable, 'data', newData);


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes multiCarrierControl_GUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = multiCarrierControl_GUI_OutputFcn(hObject, eventdata, handles) 
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

indices = eventdata.Indices;
row = indices(:,1);

if (~(isempty(row)))
    
    multiCParams = get(handles.uitable, 'data');
    fc = cell2mat(multiCParams(row,2));
    span = cell2mat(multiCParams(row,3));
    range = cell2mat(multiCParams(row,5));
    mixerMode = char(multiCParams(row,6));
    customFilterFile = char(multiCParams(row,7));
    
    try
        % For a particular line that is selected
        vsaApp = vsafunc([], 'open');
        
        % Tune to the FC in VSA
        vsafunc(vsaApp, 'freq', fc, span, 102401, 'flattop', 3);
        
        % Set the range
        vsafunc(vsaApp, 'autorange', range);
        
        % Apply the mixer mode
        vsafunc(vsaApp, 'xSeriesMixerMode', mixerMode);
        
        % Apply any custom Filter
        vsafunc(vsaApp, 'loadIFCorrectionFile', customFilterFile);
    catch
        msgbox('No connection to VSA');
    end
end

 
% --- Executes during object creation, after setting all properties.
function uitable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uitable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: delete(hObject) closes the figure
%setappdata(0, 'multiCalParameters', get(handles.uitable, 'data'));
uiresume(handles.figure1);

% --- Executes on button press in pushbuttonCancel.
function pushbuttonCancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);


% --- Executes on button press in recallCalTableValues.
function recallCalTableValues_Callback(hObject, eventdata, handles)
% hObject    handle to recallCalTableValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    multiCalParams = getappdata(0,'multiCalParameters');
    set(handles.uitable, 'data', multiCalParams);
    % Update handles structure
    guidata(hObject, handles);
    
catch
    msgbox('Carrier Parameters not specified forsignal');
end



% --- Executes on button press in defaultButton.
function defaultButton_Callback(hObject, eventdata, handles)
% hObject    handle to defaultButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%% Load up variables from multicarrier spec
numCarriers =  getappdata(0,'numOfCarriers');
channelCenters = getappdata(0, 'chCenterFreq');
channelBand = getappdata(0, 'chBand');

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
    newData{i,6} = 'Normal';
    newData{i,7} = '';
end

set(handles.uitable, 'data', newData);

% Update handles structure
guidata(hObject, handles);
