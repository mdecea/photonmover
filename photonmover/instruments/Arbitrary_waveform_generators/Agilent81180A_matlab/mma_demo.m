function varargout = mma_demo(varargin)
% MMA_DEMO MATLAB code for mma_demo.fig
%      MMA_DEMO, by itself, creates a new MMA_DEMO or raises the existing
%      singleton*.
%
%      H = MMA_DEMO returns the handle to a new MMA_DEMO or the handle to
%      the existing singleton*.
%
%      MMA_DEMO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MMA_DEMO.M with the given input arguments.
%
%      MMA_DEMO('Property','Value',...) creates a new MMA_DEMO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mma_demo_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mma_demo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mma_demo

% Last Modified by GUIDE v2.5 24-Feb-2016 09:25:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mma_demo_OpeningFcn, ...
                   'gui_OutputFcn',  @mma_demo_OutputFcn, ...
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


% --- Executes just before mma_demo is made visible.
function mma_demo_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mma_demo (see VARARGIN)

% Choose default command line output for mma_demo
offset = 34;
handles.output = hObject;
res = parse_descr(1, 1);
if (~isempty(res))
    set(handles.pushbuttonDemo1, 'String', res.name);
end
res = parse_descr(2, 1);
if (~isempty(res))
    set(handles.pushbuttonDemo2, 'String', res.name);
    set(handles.pushbuttonDemo2, 'Visible', 'on');
    moveButtons(handles, offset);
end
res = parse_descr(3, 1);
if (~isempty(res))
    set(handles.pushbuttonDemo3, 'String', res.name);
    set(handles.pushbuttonDemo3, 'Visible', 'on');
    moveButtons(handles, offset);
end
res = parse_descr(4, 1);
if (~isempty(res))
    set(handles.pushbuttonDemo4, 'String', res.name);
    set(handles.pushbuttonDemo4, 'Visible', 'on');
    moveButtons(handles, offset);
end
posWindow = get(handles.figure1, 'Position');
posWindow(1:2) = [0 0];
set(handles.figure1, 'Position', posWindow);
posEdit = get(handles.editDescr, 'Position');
posGroup = get(handles.uibuttongroup1, 'Position');
handles.editDiff = posWindow - posEdit;
handles.groupDiff = posWindow(4) - posGroup(2);
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes mma_demo wait for user response (see UIRESUME)
% uiwait(handles.figure1);


function moveButtons(handles, offset)
pos = get(handles.uibuttongroup1, 'Position');
pos(2) = pos(2) - offset;
pos(4) = pos(4) + offset;
set(handles.uibuttongroup1, 'Position', pos);
pos = get(handles.pushbuttonDemo1, 'Position');
pos(2) = pos(2) + offset;
set(handles.pushbuttonDemo1, 'Position', pos);
pos = get(handles.pushbuttonDemo2, 'Position');
pos(2) = pos(2) + offset;
set(handles.pushbuttonDemo2, 'Position', pos);
pos = get(handles.pushbuttonDemo3, 'Position');
pos(2) = pos(2) + offset;
set(handles.pushbuttonDemo3, 'Position', pos);
pos = get(handles.pushbuttonDemo4, 'Position');
pos(2) = pos(2) + offset;
set(handles.pushbuttonDemo4, 'Position', pos);
pos = get(handles.editDescr, 'Position');
pos(4) = pos(4) - offset;
set(handles.editDescr, 'Position', pos);


% --- Outputs from this function are returned to the command line.
function varargout = mma_demo_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonDemo1.
function pushbuttonDemo1_Callback(hObject, eventdata, handles)
startDemo(hObject, 1, handles);
% --- Executes on button press in pushbuttonDemo2.
function pushbuttonDemo2_Callback(hObject, eventdata, handles)
startDemo(hObject, 2, handles);
% --- Executes on button press in pushbuttonDemo3.
function pushbuttonDemo3_Callback(hObject, eventdata, handles)
startDemo(hObject, 3, handles);
% --- Executes on button press in pushbuttonDemo4.
function pushbuttonDemo4_Callback(hObject, eventdata, handles)
startDemo(hObject, 4, handles);


function startDemo(hObject, demoNum, handles)
handles.demoNum = demoNum;
handles.nextNum = 1;
guidata(hObject, handles);
res = parse_descr(handles.demoNum, handles.nextNum);
if (~isempty(res))
    hMsgBox = msgbox('Loading setup - please wait...', 'Please wait...', 'modal');
    executeCmd(res.commands, handles);
    set(handles.editDescr, 'FontSize', 14);
    set(handles.editDescr, 'String', cellstr(res.description));
    set(handles.pushbuttonNext, 'Enable', 'on');
    set(handles.pushbuttonCancel, 'Enable', 'on');
    try close(hMsgBox); catch; end
end

   
% --- Executes on button press in pushbuttonNext.
function pushbuttonNext_Callback(hObject, eventdata, handles)
handles.nextNum = handles.nextNum + 1;
guidata(hObject, handles);
res = parse_descr(handles.demoNum, handles.nextNum);
if (~isempty(res))
    hMsgBox = msgbox('Loading setup - please wait...', 'Please wait...', 'modal');
    executeCmd(res.commands, handles);
    set(handles.editDescr, 'FontSize', 14);
    set(handles.editDescr, 'String', cellstr(res.description));
    try close(hMsgBox); catch; end
else
    pushbuttonCancel_Callback(hObject, eventdata, handles);
end


% --- Executes on button press in pushbuttonCancel.
function pushbuttonCancel_Callback(hObject, eventdata, handles)
set(handles.editDescr, 'FontSize', 24);
set(handles.editDescr, 'String', cellstr(sprintf('\n\n\n\n\n\nPlease click on one of the buttons to start a demo')));
set(handles.pushbuttonNext, 'Enable', 'off');
set(handles.pushbuttonCancel, 'Enable', 'off');


function executeCmd(cmd, handles)
set(handles.editDescr, 'String', '');
drawnow update;
arbConfig = loadArbConfig();
fawg = iqopen();
if (isempty(fawg))
    return;
end
if ((isfield(arbConfig, 'isScopeConnected') && arbConfig.isScopeConnected == 0) || ~isfield(arbConfig, 'visaAddrScope'))
    errordlg('Scope address is not configured, please use "Instrument Configuration" to set it up');
end
fscope = iqopen(arbConfig.visaAddrScope);
if (isempty(fscope))
    return;
end
if (~arbConfig.isVSAConnected)
    errordlg('VSA address is not configured, please use "Instrument Configuration" to set it up');
    return;
end
fvsa = iqopen(arbConfig.visaAddrVSA);
if (isempty(fvsa))
    return;
end
try
    eval(cmd);
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
fclose(fawg);
fclose(fscope);
fclose(fvsa);


function result = parse_descr(numDemo, numNext)
lineNum = 0;
result = [];
state = [];
demoCnt = 0;
nextCnt = 0;
if (isdeployed)
    [~, result] = system('path');
    path = fullfile(char(regexpi(result, 'Path=(.*?);', 'tokens', 'once')), 'mma_demo', 'mma_demo.txt');
else
    path = fullfile(fileparts(which('mma_demo.m')), 'mma_demo', 'mma_demo.txt');
end
f = fopen(path, 'r');
if (isempty(f))
    errordlg(sprintf('Can''t open %s', path));
    return;
end
while (true)
    l = fgetl(f);
    lineNum = lineNum + 1;
%    fprintf('%d %s - %s\n', lineNum, state, l);
    if (l < 0)
        nextCnt = nextCnt + 1;
        break;
    end
    if (~isempty(l) && l(1) == '#')
        continue;
    end
    if (strncmpi(l, '[name]', 6))
        nextCnt = nextCnt + 1;
%        fprintf('demo %d - %d, next %d - %d\n', numDemo, demoCnt, numNext, nextCnt);
        if (demoCnt > numDemo || (demoCnt == numDemo && nextCnt == numNext))
            break;
        end
        demoCnt = demoCnt + 1;
        nextCnt = 0;
        result = [];
        result.name = [];
        result.description = '';
        result.commands = [];
        state = l;
        continue;
    elseif (strncmpi(l, '[description]', 13))
        state = l;
        continue;
    elseif (strncmpi(l, '[commands]', 9))
        state = l;
        continue;
    elseif (strncmpi(l, '[next]', 6))
        nextCnt = nextCnt + 1;
%        fprintf('demo %d - %d, next %d - %d\n', numDemo, demoCnt, numNext, nextCnt);
        if (demoCnt == numDemo && nextCnt == numNext)
            break;
        end
        result.description = '';
        result.commands = [];
        state = [];
    elseif (strncmpi(l, '[', 1))
        errordlg(sprintf('unknown tag: %s in line %d', l, lineNum));
        state = [];
    end
    % --- process data depending on the current state
    if (strncmpi(state, '[name]', 6))
        result.name = l;
        state = [];
    elseif (strncmpi(state, '[description]', 13))
        result.description = sprintf('%s%s\n', result.description, l);
    elseif (strncmpi(state, '[commands]', 9))
        result.commands = sprintf('%s%s\n', result.commands, l);
    end
end
fclose(f);
if (demoCnt ~= numDemo || nextCnt ~= numNext)
    result = [];
end


function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, -1 for errors

retVal = 0;
% set debugScpi=1 in MATLAB workspace to log SCPI commands
if (evalin('base', 'exist(''debugScpi'', ''var'')'))
    fprintf('cmd = %s\n', s);
end
fprintf(f, s);
result = query(f, ':syst:err?');
if (isempty(result))
    fclose(f);
    errordlg({'The M8195A firmware did not respond to a :SYST:ERRor query.' ...
        'Please check that the firmware is running and responding to commands.'}, 'Error');
    retVal = -1;
    return;
end
if (~exist('ignoreError', 'var') || ignoreError == 0)
    while (~strncmp(result, '0', 1) && ~strncmp(result, '+0', 2))
        errordlg({'M8195A firmware returns an error on command:' s 'Error Message:' result});
        result = query(f, ':syst:err?');
        retVal = -1;
    end
end



function editDescr_Callback(hObject, eventdata, handles)
% hObject    handle to editDescr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDescr as text
%        str2double(get(hObject,'String')) returns contents of editDescr as a double


% --- Executes during object creation, after setting all properties.
function editDescr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDescr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
try
    posWindow = get(handles.figure1, 'Position');
    posEdit = get(handles.editDescr, 'Position');
    posEdit(3:4) = max(posWindow(3:4) - handles.editDiff(3:4), [1 1]);
    set(handles.editDescr, 'Position', posEdit);
    posGroup = get(handles.uibuttongroup1, 'Position');
    posGroup(2) = max(posWindow(4) - handles.groupDiff, 1);
    set(handles.uibuttongroup1, 'Position', posGroup);
catch 
end
