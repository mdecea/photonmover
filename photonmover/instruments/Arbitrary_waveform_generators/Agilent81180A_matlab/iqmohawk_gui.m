function varargout = iqmohawk_gui(varargin)
% IQMOHAWK_GUI MATLAB code for iqmohawk_gui.fig
%      IQMOHAWK_GUI, by itself, creates a new IQMOHAWK_GUI or raises the existing
%      singleton*.
%
%      H = IQMOHAWK_GUI returns the handle to a new IQMOHAWK_GUI or the handle to
%      the existing singleton*.
%
%      IQMOHAWK_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQMOHAWK_GUI.M with the given input arguments.
%
%      IQMOHAWK_GUI('Property','Value',...) creates a new IQMOHAWK_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqmohawk_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqmohawk_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqmohawk_gui

% Last Modified by GUIDE v2.5 15-Mar-2019 09:54:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqmohawk_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqmohawk_gui_OutputFcn, ...
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


% --- Executes just before iqmohawk_gui is made visible.
function iqmohawk_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqmohawk_gui (see VARARGIN)

% Choose default command line output for iqmohawk_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqmohawk_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iqmohawk_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editVisaAddr_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddr as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddr as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTest.
function pushbuttonTest_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
visaAddr = get(handles.editVisaAddr, 'String');
f = iqopen(visaAddr);
if (~isempty(f))
    set(handles.pushbuttonTest, 'Background', 'green');
else
    set(handles.pushbuttonTest, 'Background', 'red');
end

% --- Executes on button press in pushbuttonRun.
function pushbuttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
visaAddr = get(handles.editVisaAddr, 'String');
iqmohawk(visaAddr);
