function varargout = iqseq_gui(varargin)
% IQSEQ_GUI MATLAB code for iqseq_gui.fig
%      IQSEQ_GUI, by itself, creates a new IQSEQ_GUI or raises the existing
%      singleton*.
%
%      H = IQSEQ_GUI returns the handle to a new IQSEQ_GUI or the handle to
%      the existing singleton*.
%
%      IQSEQ_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQSEQ_GUI.M with the given input arguments.
%
%      IQSEQ_GUI('Property','Value',...) creates a new IQSEQ_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqseq_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqseq_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqseq_gui

% Last Modified by GUIDE v2.5 24-Jun-2014 13:09:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqseq_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqseq_gui_OutputFcn, ...
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


% --- Executes just before iqseq_gui is made visible.
function iqseq_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqseq_gui (see VARARGIN)

% Choose default command line output for iqseq_gui
handles.output = hObject;
handles.arbConfig = loadArbConfig();
global currentTableSelection;
currentTableSelection = [1 1];

arbConfig = loadArbConfig();
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig, 'single');

% Update handles structure
guidata(hObject, handles);

if (~isfield(handles.arbConfig, 'tooltips') || handles.arbConfig.tooltips == 1)
set(handles.uitable1, 'TooltipString', sprintf([ ...
    'Enter the Segment Number, Loop Count, Advance mode and Marker flag\n' ...
    'for each step in the sequence.']));
set(handles.pushbuttonInsert, 'TooltipString', sprintf([ ...
    'Inserts a new row into the sequence table above the currently selected row.']));
set(handles.pushbuttonDelete, 'TooltipString', sprintf([ ...
    'Delete the selected row.']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Download the sequence that is defined in the sequence table to the AWG\n' ...
    'and run it in sequence mode.  NOTE: all of the segments in the table\n' ...
    'must be defined prior to download']));
end

% UIWAIT makes iqseq_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqseq_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitable1, 'Data');
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
channelStr = iqchannelsetup('arraystring', channelMapping);
downloadStr = sprintf(', ''channelMapping'', %s', channelStr);
clear seqtable;
for i = 1:size(data, 1)
    seqtable(i).segmentNumber = data{i,1};
    seqtable(i).segmentLoops = data{i,2};
    seqtable(i).segmentAdvance = data{i,3};
    seqtable(i).markerEnable = data{i,4};
end
assignin('base', 'seqtable', seqtable);
h = msgbox('Downloading sequence...');
iqseq('define', seqtable, 'channelMapping', channelMapping);
try
    close(h);
catch ex
end

% --- Executes when entered data in editable cell(s) in uitable1.
function uitable1_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitable1 (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitable1, 'Data');
row = eventdata.Indices(1);
col = eventdata.Indices(2);
switch (col)
    case 1
        val = eventdata.NewData;
        if (val < 0 || val > 524288 || val ~= floor(val))
            data{row,col} = eventdata.PreviousData;
            set(handles.uitable1, 'Data', data);
        end
    case 2
        val = eventdata.NewData;
        if (val < 1 || val > 1024576 || val ~= floor(val))
            data{row,col} = eventdata.PreviousData;
            set(handles.uitable1, 'Data', data);
        end
end


% --- Executes on button press in pushbuttonInsert.
function pushbuttonInsert_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelection;
data = get(handles.uitable1, 'Data');
if (~exist('currentTableSelection'))
    disp('no currentTableSelection');
    row1 = 1;
else
    row1 = currentTableSelection(1);
end
row2 = size(data,1);
% it seems that an assignment like this is not possible
% data{row1+1:row2+1,:} = data{row1:row2,:}
for i=row2:-1:row1
    for j=1:size(data,2)
        data{i+1,j} = data{i,j};
    end
end
set(handles.uitable1, 'Data', data);

% --- Executes on button press in pushbuttonDelete.
function pushbuttonDelete_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelection;
data = get(handles.uitable1, 'Data');
if (~exist('currentTableSelection'))
    disp('no currentTableSelection');
    row1 = 1;
else
    row1 = currentTableSelection(1);
end
row2 = size(data,1);
if (row2 <= 1)
    return;
end
newdata = cell(row2-1,size(data,2));
% it seems that an assignment like this is not possible
% data{row1+1:row2+1,:} = data{row1:row2,:}
for i=1:row1-1
    for j=1:size(data,2)
        newdata{i,j} = data{i,j};
    end
end
for i=row1:row2-1
    for j=1:size(data,2)
        newdata{i,j} = data{i+1,j};
    end
end
set(handles.uitable1, 'Data', newdata);


% --- Executes when selected cell(s) is changed in uitable1.
function uitable1_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitable1 (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelection;
if (~isempty(eventdata.Indices))
    currentTableSelection = eventdata.Indices;
end


% --- Executes when iqtool is resized.
function iqtool_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to iqtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonListSegments.
function pushbuttonListSegments_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonListSegments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqseq('list');


% --- Executes on button press in pushbuttonDeleteAllSegments.
function pushbuttonDeleteAllSegments_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteAllSegments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqseq('delete');


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


% --- Executes on button press in pushbuttonEvent.
function pushbuttonEvent_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqseq('event');


% --- Executes on button press in pushbuttonTrigger.
function pushbuttonTrigger_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqseq('trigger');


% --- Executes on selection change in popupmenuDownload.
function popupmenuDownload_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDownload contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDownload


% --- Executes during object creation, after setting all properties.
function popupmenuDownload_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonChannelMapping.
function pushbuttonChannelMapping_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonChannelMapping (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
[val, str] = iqchanneldlg(get(hObject, 'UserData'), arbConfig, handles.iqtool, 'single');
if (~isempty(val))
    set(hObject, 'UserData', val);
    set(hObject, 'String', str);
end
