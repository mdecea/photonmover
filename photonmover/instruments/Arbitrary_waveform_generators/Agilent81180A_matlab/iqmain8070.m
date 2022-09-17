function varargout = iqmain8070(varargin)
% IQMAIN8070 MATLAB code for iqmain8070.fig
%      IQMAIN8070, by itself, creates a new IQMAIN8070 or raises the existing
%      singleton*.
%
%      H = IQMAIN8070 returns the handle to a new IQMAIN8070 or the handle to
%      the existing singleton*.
%
%      IQMAIN8070('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQMAIN8070.M with the given input arguments.
%
%      IQMAIN8070('Property','Value',...) creates a new IQMAIN8070 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqmain8070_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqmain8070_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqmain8070

% Last Modified by GUIDE v2.5 21-Jun-2017 15:00:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqmain8070_OpeningFcn, ...
                   'gui_OutputFcn',  @iqmain8070_OutputFcn, ...
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


% --- Executes just before iqmain8070 is made visible.
function iqmain8070_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqmain8070 (see VARARGIN)

% Choose default command line output for iqmain8070
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqmain8070 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iqmain8070_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonConfig.
function pushbuttonConfig_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqconfig();


% --- Executes on button press in pushbuttonCalibrate.
function pushbuttonCalibrate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCalibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqmtcal(8070);


% --- Executes on button press in pushbuttonHelp.
function pushbuttonHelp_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonHelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
system('start C:\Users\tdippon\Downloads\TCA955.pdf');
