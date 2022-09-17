function varargout = iqrecordinglist(varargin)
% IQRECORDINGLIST MATLAB code for iqrecordinglist.fig
%      IQRECORDINGLIST, by itself, creates a new IQRECORDINGLIST or raises the existing
%      singleton*.
%
%      H = IQRECORDINGLIST returns the handle to a new IQRECORDINGLIST or the handle to
%      the existing singleton*.
%
%      IQRECORDINGLIST('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQRECORDINGLIST.M with the given input arguments.
%
%      IQRECORDINGLIST('Property','Value',...) creates a new IQRECORDINGLIST or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqrecordinglist_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqrecordinglist_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqrecordinglist

% Last Modified by GUIDE v2.5 21-May-2019 00:02:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqrecordinglist_OpeningFcn, ...
                   'gui_OutputFcn',  @iqrecordinglist_OutputFcn, ...
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


% --- Executes just before iqrecordinglist is made visible.
function iqrecordinglist_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqrecordinglist (see VARARGIN)

% Choose default command line output for iqrecordinglist
handles.output = [];

if (nargin >= 1)
    set(handles.listbox1, 'String', varargin{1});
    set(handles.listbox1, 'Value', length(varargin{1}));
end
if (nargin >= 2)
    set(handles.textTitle, 'String', varargin{2});
end
if (nargin >= 3)
    set(handles.pushbuttonOK, 'String', varargin{3});
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqrecordinglist wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iqrecordinglist_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if (~isempty(handles))
    varargout{1} = handles.output;
    close(handles.figure1);
else
    varargout{1} = [];
end


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonOK.
function pushbuttonOK_Callback(hObject, eventdata, handles)
handles.output = get(handles.listbox1, 'Value');
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes on button press in pushbuttonCancel.
function pushbuttonCancel_Callback(hObject, eventdata, handles)
handles.output = 0;
guidata(hObject, handles);
uiresume(handles.figure1);
