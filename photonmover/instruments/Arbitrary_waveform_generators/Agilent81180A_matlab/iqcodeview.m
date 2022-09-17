function varargout = iqcodeview(varargin)
% IQCODEVIEW MATLAB code for iqcodeview.fig
%      IQCODEVIEW, by itself, creates a new IQCODEVIEW or raises the existing
%      singleton*.
%
%      H = IQCODEVIEW returns the handle to a new IQCODEVIEW or the handle to
%      the existing singleton*.
%
%      IQCODEVIEW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQCODEVIEW.M with the given input arguments.
%
%      IQCODEVIEW('Property','Value',...) creates a new IQCODEVIEW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqcodeview_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqcodeview_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqcodeview

% Last Modified by GUIDE v2.5 13-Jun-2015 21:25:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqcodeview_OpeningFcn, ...
                   'gui_OutputFcn',  @iqcodeview_OutputFcn, ...
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


% --- Executes just before iqcodeview is made visible.
function iqcodeview_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqcodeview (see VARARGIN)

% Choose default command line output for iqcodeview
handles.output = hObject;

posWindow = get(handles.iqtool, 'Position');
posEdit = get(handles.editText, 'Position');
handles.editDiff = posWindow - posEdit;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqcodeview wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqcodeview_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editText_Callback(hObject, eventdata, handles)
% hObject    handle to editText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editText as text
%        str2double(get(hObject,'String')) returns contents of editText as a double


% --- Executes during object creation, after setting all properties.
function editText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonClose.
function pushbuttonClose_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.iqtool);


% --- Executes when iqtool is resized.
function iqtool_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to iqtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    posWindow = get(hObject, 'Position');
    posEdit = get(handles.editText, 'Position');
    posEdit(3:4) = max(posWindow(3:4) - handles.editDiff(3:4), [1 1]);
    set(handles.editText, 'Position', posEdit);
catch 
end


% --- Executes on button press in pushbuttonSave.
function pushbuttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName] = uiputfile({...
    '.m', 'MATLAB Script (*.m)'}, ...
    'Save Waveform As...');
if (FileName ~= 0)
    try
        f = fopen(strcat(PathName, FileName), 'w');
        str = get(handles.editText, 'String');
        cstr = cellstr(str);
        for i=1:length(cstr)
            fprintf(f, '%s\n', cstr{i});
        end
        fclose(f);
    catch ex
        errordlg(ex.message);
    end
end


% --- Executes on button press in pushbuttonRun.
function pushbuttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    str = get(handles.editText, 'String');
    cstr = cellstr(str);
    a = '';
    for i=1:length(cstr)
        tmp = cstr{i};
        if (~isempty(tmp) && tmp(1) ~= '%')
            p = regexp(tmp, '\.\.\.');
            if (p ~= 0)
                tmp = tmp(1:p-1);
            end
            a = [a tmp];
        end
    end
    evalin('base', a);
catch ex
    errordlg(ex.message);
end


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;


