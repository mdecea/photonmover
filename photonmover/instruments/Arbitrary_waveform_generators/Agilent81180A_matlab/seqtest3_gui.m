function varargout = seqtest3_gui(varargin)
% SEQTEST3_GUI MATLAB code for seqtest3_gui.fig
%      SEQTEST3_GUI, by itself, creates a new SEQTEST3_GUI or raises the existing
%      singleton*.
%
%      H = SEQTEST3_GUI returns the handle to a new SEQTEST3_GUI or the handle to
%      the existing singleton*.
%
%      SEQTEST3_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SEQTEST3_GUI.M with the given input arguments.
%
%      SEQTEST3_GUI('Property','Value',...) creates a new SEQTEST3_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before seqtest3_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to seqtest3_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help seqtest3_gui

% Last Modified by GUIDE v2.5 13-Jun-2015 21:22:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @seqtest3_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @seqtest3_gui_OutputFcn, ...
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


% --- Executes just before seqtest3_gui is made visible.
function seqtest3_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to seqtest3_gui (see VARARGIN)

% Choose default command line output for seqtest3_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes seqtest3_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = seqtest3_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonRun.
function pushbuttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading waveforms. Please wait...', 'Please wait...', 'replace');
try
    seqtest3;
catch ex;
    errordlg(ex.message);
end
try
    close(hMsgBox);
catch ex;
end

% --- Executes on button press in pushbuttonEdit.
function pushbuttonEdit_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
edit seqtest3


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
