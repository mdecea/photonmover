function varargout = iqseq_M8190A_gui(varargin)
% IQSEQ_M8190A_GUI MATLAB code for iqseq_M8190A_gui.fig
%      IQSEQ_M8190A_GUI, by itself, creates a new IQSEQ_M8190A_GUI or raises the existing
%      singleton*.
%
%      H = IQSEQ_M8190A_GUI returns the handle to a new IQSEQ_M8190A_GUI or the handle to
%      the existing singleton*.
%
%      IQSEQ_M8190A_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQSEQ_M8190A_GUI.M with the given input arguments.
%
%      IQSEQ_M8190A_GUI('Property','Value',...) creates a new IQSEQ_M8190A_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqseq_M8190A_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqseq_M8190A_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqseq_M8190A_gui

% Last Modified by GUIDE v2.5 31-Jan-2014 17:16:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqseq_M8190A_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqseq_M8190A_gui_OutputFcn, ...
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


% --- Executes just before iqseq_M8190A_gui is made visible.
function iqseq_M8190A_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqseq_M8190A_gui (see VARARGIN)

% Choose default command line output for iqseq_M8190A_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

checkfields([], [], handles);
arbConfig = loadArbConfig();
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig, 'single');

% UIWAIT makes iqseq_M8190A_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqseq_M8190A_gui_OutputFcn(hObject, eventdata, handles) 
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

% check if hardware and options are available
if (~iqoptcheck([], 'M8190A', 'SEQ'))
    return;
end
hMsgBox = msgbox('Downloading Sequence. Please wait...', 'Please wait...', 'replace');
doDownload(handles, 0);
try
    close(hMsgBox);
catch e;
end;


function code = doDownload(handles, doCode)
code = '';
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
channelStr = iqchannelsetup('arraystring', channelMapping);
downloadStr = sprintf(', ''channelMapping'', %s', channelStr);
% load the amplitude table
amplitudeTable = get(handles.uitableAmplitude, 'Data');
if (size(amplitudeTable,1) > 0)
    code = sprintf('%s\n%% define the amplitude table\natab = [', code);
    atab = ones(1,size(amplitudeTable,1));
    for i=1:size(amplitudeTable,1)
        try
            atab(i) = evalin('base', ['[' amplitudeTable{i,2} ']']);
            code = sprintf('%s %g', code, atab(i));
        catch ex
            errordlg({['Syntax error in amplitude table, row ' num2str(i-1) ':'] ...
                ex.message});
            return;
        end
    end
    if (doCode)
        code = sprintf('%s ];\niqseq(''amplitudeTable'', atab%s);\n', code, downloadStr);
    else
        iqseq('amplitudeTable', atab, 'channelMapping', channelMapping);
    end
end
% load the frequency table
frequencyTable = get(handles.uitableFrequency, 'Data');
if (size(frequencyTable,1) > 0)
    code = sprintf('%s\n%% define the frequency table\nftab = [', code);
    ftab = 10e6 * ones(1,size(frequencyTable,1));
    for i=1:size(frequencyTable,1)
        try
            ftab(i) = evalin('base', ['[' frequencyTable{i,2} ']']);
            code = sprintf('%s %g', code, ftab(i));
        catch ex
            errordlg({['Syntax error in frequency table, row ' num2str(i-1) ':'] ...
                ex.message});
            return;
        end
    end
    if (doCode)
        code = sprintf('%s ];\niqseq(''frequencyTable'', ftab%s);\n', code, downloadStr);
    else
        iqseq('frequencyTable', ftab, 'channelMapping', channelMapping);
    end
end
% load new action table, store action IDs in handles.actionID and return in
% array a (this is the name that is used by the sequence table later on)
a = downloadActionTable(handles, channelMapping, 1, doCode, downloadStr);
if (doCode)
    code = [code a];
end
% load the sequence table
sequenceTable = cell2struct(get(handles.uitableSeq, 'Data'), ...
    {'idx', 'segmentNumber', 'segmentLoops', 'segmentAdvance', 'markerEnable', 'sequenceInit', ...
     'sequenceLoops', 'sequenceAdvance', 'actionStr', 'amplCmd', 'freqCmd'}, 2);
for i=1:size(sequenceTable,1)
    switch(sequenceTable(i).amplCmd)
        case 'next'; sequenceTable(i).amplitudeNext = 1;
        case 'init'; sequenceTable(i).amplitudeInit = 1;
        otherwise; sequenceTable(i).amplitudeInit = 0; sequenceTable(i).amplitudeNext = 0;
    end
    switch(sequenceTable(i).freqCmd)
        case 'next'; sequenceTable(i).frequencyNext = 1;
        case 'init'; sequenceTable(i).frequencyInit = 1;
        otherwise; sequenceTable(i).frequencyInit = 0; sequenceTable(i).frequencyNext = 0;
    end
    if (sequenceTable(i).sequenceInit && i > 1)
        sequenceTable(i-1).sequenceEnd = 1;
    end
    if (strcmp(sequenceTable(i).sequenceAdvance, 'n.a.'))
        sequenceTable(i).sequenceAdvance = 'Auto';
    end
    switch(sequenceTable(i).actionStr)
        case 'none';
            sequenceTable(i).actionID = [];
        otherwise;
            try
                tmp = eval(sequenceTable(i).actionStr);      % access the array a, which was defined above
                sequenceTable(i).actionID = tmp;
            catch ex
                errordlg({['Action ID ' sequenceTable(i).actionStr ' not defined:'] ...
                 ex.message});
                sequenceTable(i).actionID = [];
            end
    end
end
if (~isempty(sequenceTable))
    sequenceTable(size(sequenceTable,1)).sequenceEnd = 1;
    sequenceTable(size(sequenceTable,1)).scenarioEnd = 1;
    if (doCode)
        code = sprintf('%s\n%% define the sequence table\nclear seq;\n', code);
        for i=1:length(sequenceTable)
            code = sprintf('%s%% sequence ID %d\n', code, i - 1);
            code = sprintf('%sseq(%d).segmentNumber = %d;\n', code, i, sequenceTable(i).segmentNumber);
            if (sequenceTable(i).segmentLoops ~= 1)
                code = sprintf('%sseq(%d).segmentLoops = %d;\n', code, i, sequenceTable(i).segmentLoops);
            end
            if (~isempty(sequenceTable(i).segmentAdvance) && strcmp(sequenceTable(i).segmentAdvance, 'Auto') == 0)
                code = sprintf('%sseq(%d).segmentAdvance = ''%s'';\n', code, i, sequenceTable(i).segmentAdvance);
            end
            if (sequenceTable(i).sequenceLoops ~= 1)
                code = sprintf('%sseq(%d).sequenceLoops = %d;\n', code, i, sequenceTable(i).sequenceLoops);
            end
            if (~isempty(sequenceTable(i).sequenceAdvance) && ~strcmp(sequenceTable(i).sequenceAdvance, 'Auto'))
                code = sprintf('%sseq(%d).sequenceAdvance = ''%s'';\n', code, i, sequenceTable(i).sequenceAdvance);
            end
            if (~isempty(sequenceTable(i).actionID))
                code = sprintf('%sseq(%d).actionID = %s;\n', code, i, sequenceTable(i).actionStr);
            end
            for f = {'markerEnable' 'amplitudeInit' 'amplitudeNext' 'frequencyInit' 'frequencyNext' 'sequenceInit', 'sequenceEnd', 'scenarioEnd'}
                fld = f{1};
                if (~isempty(sequenceTable(i).(fld)) && sequenceTable(i).(fld) ~= 0)
                    code = sprintf('%sseq(%d).%s = %d;\n', code, i, fld, sequenceTable(i).(fld));
                end
            end
        end
        code = sprintf('%s\n%% download the sequence table and run\n', code);
        code = sprintf('%siqseq(''define'', seq%s, ''run'', 0, ''keepOpen'', 1);\n', code, downloadStr);
        code = sprintf('%siqseq(''mode'', ''STSCenario''%s);\n', code, downloadStr);
    else
        sequenceTable = rmfield(sequenceTable, {'idx', 'amplCmd', 'freqCmd', 'actionStr'});
        iqseq('define', sequenceTable, 'channelMapping', channelMapping, 'run', 0, 'keepOpen', 1);
        iqseq('mode', 'STSCenario', 'channelMapping', channelMapping);
    end
end


function a = downloadActionTable(handles, channelMapping, newTable, doCode, downloadStr)
code = '';
atab = get(handles.uitableAction, 'Data');
if (isempty(atab))
    actionTable = [];
else
    actionTable = cell2struct(atab, {'idx', 'new', 'act', 'param'}, 2);
end
actCount = 0;
a = [];
if (newTable)
    if (doCode)
        code = sprintf('%s\n%% define the action table\nclear a;\n', code);
        code = sprintf('%siqseq(''actionDeleteAll'', []%s);\n', code, downloadStr);
    else
        iqseq('actionDeleteAll', [], 'channelMapping', channelMapping);
    end
else
    a = handles.actionID;
end
if (size(actionTable,1) > 0)
    for i=1:size(actionTable,1)
        if (actionTable(i).new)
            actCount = actCount + 1;
            if (newTable)
                if (doCode)
                    code = sprintf('%sa(%d) = iqseq(''actionDefine'', []%s);\n', code, actCount, downloadStr);
                else
                    a(actCount) = iqseq('actionDefine', [], 'channelMapping', channelMapping);
                end
            else
                if (actCount > length(a))
                    errordlg({'Can not change the size of the action table at runtime.' ...
                              'Only parameter changes are allowed at runtime'});
                    return;
                end
            end
        end
        switch(actionTable(i).act)
            case 'Phase Offset'; acode = 'POFFset';
            case 'Phase Bump'; acode = 'PBUMp';
            case 'Phase Reset'; acode = 'PRESet';
            case 'Carrier Frequency'; acode = 'CFRequency';
            case 'Amplitude Scale'; acode = 'AMPLitude';
            case 'Sweep Rate'; acode = 'SRATe';
            case 'Sweep Run'; acode = 'SRUN';
            case 'Sweep Hold'; acode = 'SHOLd';
            case 'Sweep Restart'; acode = 'SREStart';
            otherwise; error(['unknown action: ' actionTable(i).act]);
        end
        try
            param = eval(['[' actionTable(i).param ']']);
        catch ex
            errordlg({['Syntax error in action parameter, row ' num2str(i) ':'] ...
                ex.message});
        end
        if (doCode)
            code = sprintf('%siqseq(''actionAppend'', { a(%d), ''%s'', %g }%s);\n', code, actCount, acode, param, downloadStr);
        else
            iqseq('actionAppend', { a(actCount), acode, param }, 'channelMapping', channelMapping);
        end
    end
    handles.actionID = a;
    guidata(handles.iqtool, handles);
    set(handles.pushbuttonUpdateActions, 'Enable', 'on');
    if (doCode)
        a = code;
    end
end


% --- Executes on button press in pushbuttonInsertSeq.
function pushbuttonInsertSeq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
insertRow(handles, 'Seq', { 0, 1, 1, 'Auto', true, true, 1, 'Auto', 'none', 'none', 'none'});


function data = insertRow(handles, name, default)
eval(['global currentTableSelection' name]);
eval(['data = get(handles.uitable' name ', ''Data'');']);
eval(['if (exist(''currentTableSelection' name ''', ''var'') && length(currentTableSelection' name ') >= 2); row1 = currentTableSelection' name '(1); else; row1 = 1; end']);
eval(['set(handles.text' name 'Empty, ''Visible'', ''off'');']);
row2 = size(data,1);
if (row1 > row2)
    row1 = row2;
end
% it seems that an assignment like this is not possible
% data{row1+1:row2+1,:} = data{row1:row2,:}
if (row2 < 1)    % empty
    for j=1:size(default,2)
        data{1,j} = default{j};
    end
else
    for i=row2:-1:row1
        for j=1:size(data,2)
            data{i+1,j} = data{i,j};
        end
    end
    if (~isempty(default))
        for j=1:size(default,2)
            data{row1,j} = default{j};
        end
    end
end
if (~strcmp(name, 'Action'))
    % set ID column
    for i = 1:size(data,1)
        data{i,1} = i - 1;
    end
    eval(['set(handles.uitable' name ', ''Data'', data);']);
end


% --- Executes on button press in pushbuttonDeleteSeq.
function pushbuttonDeleteSeq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteRow(handles, 'Seq', 0);


function newdata = deleteRow(handles, name, minimum)
eval(['global currentTableSelection' name]);
eval(['data = get(handles.uitable' name ', ''Data'');']);
eval(['if (exist(''currentTableSelection' name ''', ''var'') && length(currentTableSelection' name ') >= 2); row1 = currentTableSelection' name '(1); else; row1 = 1; end']);
row2 = size(data,1);
newdata = data;
if (row2 <= minimum)
    return;
end
if (row2 == 1)
    eval(['set(handles.text' name 'Empty, ''Visible'', ''on'');']);
end
if (row1 > row2)
    row1 = row2;
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
if (~strcmp(name, 'Action'))
    % set ID column
    for i = 1:size(newdata,1)
        newdata{i,1} = i - 1;
    end
    if (strcmp(name, 'Seq'))
        checkSequenceTable(handles, newdata, 0);
    else
        eval(['set(handles.uitable' name ', ''Data'', newdata);']);
    end
end


% --- Executes on button press in pushbuttonListSegments.
function pushbuttonListSegments_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonListSegments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
iqseq('list', [], 'channelMapping', channelMapping);


% --- Executes on button press in pushbuttonDeleteAllSegments.
function pushbuttonDeleteAllSegments_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteAllSegments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
iqseq('delete', [], 'channelMapping', channelMapping);


% --- Executes on button press in pushbuttonEvent.
function pushbuttonEvent_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
iqseq('event', [], 'channelMapping', channelMapping);


% --- Executes on button press in pushbuttonTrigger.
function pushbuttonTrigger_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
iqseq('trigger', [], 'channelMapping', channelMapping);


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


% --- Executes on button press in pushbuttonHelp.
function pushbuttonHelp_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonHelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox({'Use this utility to create a sequence for the M8190A. The "Sequence Table"' ...
    'is used in all modes; the "Action Table", "Frequency Table" and "Amplitude' ...
    'Table" are only used in digital up-conversion modes.' ...
    ''});


% --- Executes when entered data in editable cell(s) in uitableAction.
function uitableAction_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableAction (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableAction, 'Data');
checkActionTable(handles, data, 1);


function checkActionTable(handles, data, showError)
% Check all the "new" fields and assign action IDs
% Update the Act.ID column choices in the sequence table
idx = 0;
cfmt = {'none'};
if (size(data,1) >= 1 && ~data{1,2})
    if (showError)
        errordlg({'The first entry in the action table must be a new action'});
    end
    data{1,2} = true;
end
for i = 1:size(data,1)
    if (data{i,2})
        idx = idx + 1;
        data{i,1} = sprintf('  a(%d)', idx);
        cfmt{idx+1} = sprintf('a(%d)', idx);
    else
        data{i,1} = '';
    end
    % remove parameters for sweep run and sweep hold
    if (strcmp(data{i,3}, 'Sweep Run') || ...
        strcmp(data{i,3}, 'Sweep Hold'))
        data{i,4} = [];
    elseif (isempty(data{i,4}))
        data{i,4} = '0';
    end
end
set(handles.uitableAction, 'Data', data);
% update the Action ID column
seqTab = handles.uitableSeq;
fmt = get(seqTab, 'ColumnFormat');
fmt{9} = cfmt;
set(seqTab, 'ColumnFormat', fmt);


% --- Executes when selected cell(s) is changed in uitableSeq.
function uitableSeq_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitableSeq (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelectionSeq;
if (~isempty(eventdata.Indices))
    currentTableSelectionSeq = eventdata.Indices;
end


% --- Executes on button press in pushbuttonInsertAction.
function pushbuttonInsertAction_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.pushbuttonUpdateActions, 'Enable', 'off');
data = insertRow(handles, 'Action', {'  a(1)' true 'Phase Offset' '0'});
checkActionTable(handles, data, 0);


% --- Executes on button press in pushbuttonDeleteAction.
function pushbuttonDeleteAction_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.pushbuttonUpdateActions, 'Enable', 'off');
data = deleteRow(handles, 'Action', 0);
checkActionTable(handles, data, 0);


% --- Executes on button press in pushbuttonInsertFreq.
function pushbuttonInsertFreq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
insertRow(handles, 'Frequency', { 0, '100e6' });


% --- Executes on button press in pushbuttonDeleteFreq.
function pushbuttonDeleteFreq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteRow(handles, 'Frequency', 0);


% --- Executes on button press in pushbuttonInsertAmpl.
function pushbuttonInsertAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
insertRow(handles, 'Amplitude', { 0, '1' });


% --- Executes on button press in pushbuttonDeleteAmpl.
function pushbuttonDeleteAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
deleteRow(handles, 'Amplitude', 0);


% --- Executes when selected cell(s) is changed in uitableAction.
function uitableAction_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitableAction (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelectionAction;
if (~isempty(eventdata.Indices))
    currentTableSelectionAction = eventdata.Indices;
end


% --- Executes when selected cell(s) is changed in uitableFrequency.
function uitableFrequency_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitableFrequency (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelectionFrequency;
if (~isempty(eventdata.Indices))
    currentTableSelectionFrequency = eventdata.Indices;
end


% --- Executes when selected cell(s) is changed in uitableAmplitude.
function uitableAmplitude_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitableAmplitude (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global currentTableSelectionAmplitude;
if (~isempty(eventdata.Indices))
    currentTableSelectionAmplitude = eventdata.Indices;
end


% --- Executes when entered data in editable cell(s) in uitableSeq.
function uitableSeq_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitableSeq (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.uitableSeq, 'Data');
checkSequenceTable(handles, data, 1);


function checkSequenceTable(handles, data, showError)
% Check the consistency of the sequence table.
% Modify the Seq.Loops and Seq.Adv. fields to depending on the state of the
% "new Seq" checkbox. SeqLoops and SeqAdv are only relevant in the first
% entry of a sequence
if (~isempty(data) && ~data{1,6})
    if (showError)
        errordlg({'The first entry in the sequence table must be a start of a new sequence.'});
    end
    data{1,6} = true;
end
for i=1:size(data,1)
    if (data{i,6})
        if (strcmp(data{i,8}, 'n.a.'))
            data{i,8} = 'Auto';
        end
        if (isempty(data{i,7}) || strcmp(data{i,7}, ''))
            data{i,7} = 1;
        end
    else
        data{i,8} = 'n.a.';
        data{i,7} = [];
    end
    if (~strcmp(data{i,9}, 'none'))
        data{i,3} = [];
    elseif (isempty(data{i,3}) || strcmp(data{i,3}, ''))
        data{i,3} = 1;
    end
end
set(handles.uitableSeq, 'Data', data);


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


% --- Executes on button press in pushbuttonUpdateActions.
function pushbuttonUpdateActions_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUpdateActions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structu2re with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading Action Table. Please wait...', 'Please wait...', 'replace');
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
downloadActionTable(handles, channelMapping, 0, 0);
try
    close(hMsgBox);
catch e;
end;


function data = doImport(handles, title, columns)
[FileName,PathName] = uigetfile('.csv');
data = [];
if (FileName ~= 0)
    try
        data = csvread(strcat(PathName,FileName));
    catch ex
        errordlg({'Error reading ' FileName ...
            ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
        return;
    end
    if (size(data,2) ~= columns)
        errordlg({'expected input with ' num2str(columns) ' column(s)'});
        data = [];
        return;
    end
end   


function doExport(handles, data)
[FileName,PathName] = uiputfile('.csv');
if (FileName ~= 0)
    try
        csvwrite(strcat(PathName,FileName), data);
    catch ex
        errordlg({'Error writing ' FileName ...
            ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    end
end   



% --------------------------------------------------------------------
function menuImportAction_Callback(hObject, eventdata, handles)
% hObject    handle to menuImportAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName] = uigetfile('.csv');
clear atable;
if (FileName ~= 0)
    try
        f = fopen(strcat(PathName,FileName), 'r');
    catch ex
        errordlg({'Error reading ' FileName ...
            ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
        return;
    end
    i = 1;
    while (i < 10)
        line = fgetl(f);
        if (~ischar(line))
            break;
        end
        a = regexp(line, '(?<act>[^,]+),(?<type>[^,]+),(?<val>.*)', 'names');
        atable{i,1} = '';
        if (str2num(a.act))
            atable{i,2} = true;
        else
            atable{i,2} = false;
        end
        param = a.type;
        param(strfind(param, '_')) = ' ';
        atable{i,3} = param;
        atable{i,4} = a.val;
        i = i + 1;
    end
    fclose(f);
    checkActionTable(handles, atable, 1);
end   

% --------------------------------------------------------------------
function menuExportAction_Callback(hObject, eventdata, handles)
% hObject    handle to menuExportAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName] = uiputfile('.csv');
if (FileName ~= 0)
    try
        f = fopen(strcat(PathName,FileName), 'w');
        actionTable = get(handles.uitableAction, 'Data');
        for i=1:size(actionTable,1)
            try
                val = evalin('base', ['[' actionTable{i,4} ']']);
                param = actionTable{i,3};
                param(strfind(param, ' ')) = '_';
                fprintf(f, '%d,%s,%g\n', actionTable{i,2}, param, val);
            catch ex
                errordlg({['Syntax error in action table, row ' num2str(i-1) ':'] ...
                    ex.message});
                break;
            end
        end
        fclose(f);
    catch ex
        errordlg({'Error writing ' FileName ...
            ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    end
end   

% --------------------------------------------------------------------
function menuImportAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to menuImportAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = doImport(handles, 'Amplitude Table', 1);
if (isempty(data))
    return;
end
atable = cell(length(data), 2);
for i=1:length(data)
    atable{i,1} = i - 1;
    atable{i,2} = iqengprintf(data(i));
end
set(handles.textAmplitudeEmpty, 'Visible', 'off');
set(handles.uitableAmplitude, 'Data', atable);


% --------------------------------------------------------------------
function menuExportAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to menuExportAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
amplitudeTable = get(handles.uitableAmplitude, 'Data');
atab = ones(size(amplitudeTable,1), 1);
for i=1:size(amplitudeTable,1)
    try
        atab(i) = evalin('base', ['[' amplitudeTable{i,2} ']']);
    catch ex
        errordlg({['Syntax error in amplitude table, row ' num2str(i-1) ':'] ...
            ex.message});
        return;
    end
end
doExport(handles, atab);


% --------------------------------------------------------------------
function menuImportFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to menuImportFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = doImport(handles, 'Frequency Table', 1);
if (isempty(data))
    return;
end
ftable = cell(length(data), 2);
for i=1:length(data)
    ftable{i,1} = i - 1;
    ftable{i,2} = iqengprintf(data(i));
end
set(handles.textFrequencyEmpty, 'Visible', 'off');
set(handles.uitableFrequency, 'Data', ftable);


% --------------------------------------------------------------------
function menuExportFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to menuExportFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
frequencyTable = get(handles.uitableFrequency, 'Data');
ftab = ones(size(frequencyTable,1), 1);
for i=1:size(frequencyTable,1)
    try
        ftab(i) = evalin('base', ['[' frequencyTable{i,2} ']']);
    catch ex
        errordlg({['Syntax error in frequency table, row ' num2str(i-1) ':'] ...
            ex.message});
        return;
    end
end
doExport(handles, ftab);


% --------------------------------------------------------------------
function menuPreset_Callback(hObject, eventdata, handles)
% hObject    handle to menuPreset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuFreqAmpTableExample_Callback(hObject, eventdata, handles)
% hObject    handle to menuFreqAmpTableExample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.uitableSeq, 'Data', []);
insertRow(handles, 'Seq', { 0, 1, 20000, 'Auto', true, true, 1, 'Auto', 'none', 'next', 'next'});
insertRow(handles, 'Seq', { 0, 1, 20000, 'Auto', true, true, 1, 'Auto', 'none', 'init', 'init'});
set(handles.uitableFrequency, 'Data', []);
insertRow(handles, 'Frequency', { 0, '200e6' });
insertRow(handles, 'Frequency', { 0, '100e6' });
set(handles.uitableAmplitude, 'Data', []);
insertRow(handles, 'Amplitude', { 0, '1.0' });
insertRow(handles, 'Amplitude', { 0, '0.5' });
set(handles.uitableAction, 'Data', []);
set(handles.textActionEmpty, 'Visible', 'on');
checkActionTable(handles, [], 1);


% --------------------------------------------------------------------
function menuTwoAlternatingActionExample_Callback(hObject, eventdata, handles)
% hObject    handle to menuTwoAlternatingActionExample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = [{ 0, 1,      1, 'Auto', false,  true, 1, 'Auto', 'a(1)', 'none', 'none'};
        { 1, 1, 100000, 'Auto',  true, false, 1, 'Auto', 'none', 'none', 'none'};
        { 2, 1,      1, 'Auto', false,  true, 1, 'Conditional', 'a(2)', 'none', 'none'};
        { 3, 1, 100000, 'Auto',  true, false, 1, 'Auto', 'none', 'none', 'none'};
        { 4, 1,      1, 'Auto', false, false, 1, 'Auto', 'a(3)', 'none', 'none'};
        { 5, 1, 100000, 'Auto',  true, false, 1, 'Auto', 'none', 'none', 'none'}];
set(handles.uitableSeq, 'Data', data);
set(handles.textSeqEmpty, 'Visible', 'off');
checkSequenceTable(handles, data, 1);
set(handles.uitableFrequency, 'Data', []);
set(handles.textFrequencyEmpty, 'Visible', 'on');
set(handles.uitableAmplitude, 'Data', []);
set(handles.textAmplitudeEmpty, 'Visible', 'on');
data = [{ 1, true,  'Carrier Frequency', '100e6' }; ...
        { 1, false, 'Phase Reset', '0' }; ...
        { 2, true,  'Phase Offset', '0' }; ...
        { 3, true,  'Phase Offset', '90' }];
set(handles.textActionEmpty, 'Visible', 'off');
checkActionTable(handles, data, 1);


% --------------------------------------------------------------------
function menuRepeatedActions_Callback(hObject, eventdata, handles)
% hObject    handle to menuRepeatedActions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = [{ 0, 1, 1, 'Auto', false,  true,      1, 'Auto', 'a(1)', 'none', 'none'};
        { 1, 1, 1, 'Auto',  true, false,      1, 'Auto', 'none', 'none', 'none'};
        { 2, 1, 1, 'Auto', false,  true, 100000, 'Auto', 'a(2)', 'none', 'none'};
        { 3, 1, 1, 'Auto',  true, false,      1, 'Auto', 'none', 'none', 'none'};
        { 4, 1, 1, 'Auto', false,  true, 100000, 'Auto', 'a(3)', 'none', 'none'};
        { 5, 1, 1, 'Auto',  true, false,      1, 'Auto', 'none', 'none', 'none'}];
set(handles.uitableSeq, 'Data', data);
set(handles.textSeqEmpty, 'Visible', 'off');
checkSequenceTable(handles, data, 1);
set(handles.uitableFrequency, 'Data', []);
set(handles.textFrequencyEmpty, 'Visible', 'on');
set(handles.uitableAmplitude, 'Data', []);
set(handles.textAmplitudeEmpty, 'Visible', 'on');
data = [{ 1, true,  'Carrier Frequency', '100e6' }; ...
        { 1, false, 'Phase Reset', '0' }; ...
        { 2, true,  'Phase Bump', '360/1e5' }; ...
        { 3, true,  'Phase Bump', '-360/1e5' }];
set(handles.textActionEmpty, 'Visible', 'off');
checkActionTable(handles, data, 1);


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
arbConfig = loadArbConfig();
if (isempty(strfind(arbConfig.model, 'DUC')))
    set(handles.uitableAction, 'Enable', 'Off');
    set(handles.uitableFrequency, 'Enable', 'Off');
    set(handles.uitableAmplitude, 'Enable', 'Off');
    set(handles.textActionTable, 'Enable', 'Off');
    set(handles.textFrequencyTable, 'Enable', 'Off');
    set(handles.textAmplitudeTable, 'Enable', 'Off');
    set(handles.pushbuttonInsertAction, 'Enable', 'Off');
    set(handles.pushbuttonDeleteAction, 'Enable', 'Off');
    set(handles.pushbuttonInsertFreq, 'Enable', 'Off');
    set(handles.pushbuttonDeleteFreq, 'Enable', 'Off');
    set(handles.pushbuttonInsertAmpl, 'Enable', 'Off');
    set(handles.pushbuttonDeleteAmpl, 'Enable', 'Off');
    set(handles.textActionEmpty, 'String', 'Action table is only available in DUC mode');
    set(handles.textFrequencyEmpty, 'String', 'Frequency table is only available in DUC mode');
    set(handles.textAmplitudeEmpty, 'String', 'Amplitude table is only available in DUC mode');
else
    set(handles.uitableAction, 'Enable', 'On');
    set(handles.uitableFrequency, 'Enable', 'On');
    set(handles.uitableAmplitude, 'Enable', 'On');
    set(handles.textActionTable, 'Enable', 'On');
    set(handles.textFrequencyTable, 'Enable', 'On');
    set(handles.textAmplitudeTable, 'Enable', 'On');
    set(handles.pushbuttonInsertAction, 'Enable', 'On');
    set(handles.pushbuttonDeleteAction, 'Enable', 'On');
    set(handles.pushbuttonInsertFreq, 'Enable', 'On');
    set(handles.pushbuttonDeleteFreq, 'Enable', 'On');
    set(handles.pushbuttonInsertAmpl, 'Enable', 'On');
    set(handles.pushbuttonDeleteAmpl, 'Enable', 'On');
    set(handles.textActionEmpty, 'String', sprintf('No actions defined.\nClick "+" to add an entry.'));
    set(handles.textFrequencyEmpty, 'String', sprintf('No frequency defined.\nClick "+" to add an entry.'));
    set(handles.textAmplitudeEmpty, 'String', sprintf('No amplitude defined.\nClick "+" to add an entry.'));
end


% --------------------------------------------------------------------
function menuGenerateCode_Callback(hObject, eventdata, handles)
% hObject    handle to menuGenerateCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
code = doDownload(handles, 1);
iqgeneratecode(handles, code);


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


% --- Executes on button press in pushbuttonReadSeq.
function pushbuttonReadSeq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonReadSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Reading Sequence Table...', 'Please wait...', 'replace');
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
stab = iqseq('readSequence', [], 'channelMapping', channelMapping);
for i = 1:length(stab)
    if (isfield(stab, 'actionID') && stab(i).actionID ~= -1)
        stab(i).actionStr = sprintf('a(%d)', stab(i).actionID);
    else
        stab(i).actionStr = 'none';
    end
    if (stab(i).sequenceInit == 0)
        stab(i).sequenceAdvance = 'n.a.';
        stab(i).sequenceLoops = [];
    end
end
if isa(stab,'struct')
    stab = rmfield(stab, {'actionID', 'sequenceEnd', 'scenarioEnd', 'amplitudeInit', 'amplitudeNext', 'frequencyInit', 'frequencyNext'});
    sequenceTable = struct2cell(stab')';
    set(handles.uitableSeq, 'Data', sequenceTable);
    set(handles.textSeqEmpty, 'Visible', 'off');
end
try
    close(hMsgBox);
catch ex
end

% --- Executes when iqtool is resized.
function iqtool_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to iqtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    posWindow = get(hObject, 'Position');
    posTextSeq = get(handles.textSeqTable, 'Position');
    posTextSeq(2) = posWindow(4) - 25;
    set(handles.textSeqTable, 'Position', posTextSeq);
    posSeqTab = get(handles.uitableSeq, 'Position');
    posSeqTab(4) = posWindow(4) - 240;
    set(handles.uitableSeq, 'Position', posSeqTab);
    posSeqEmpty = get(handles.textSeqEmpty, 'Position');
    posSeqEmpty(2) = 100 + (posWindow(4) - 100)/2;
    set(handles.textSeqEmpty, 'Position', posSeqEmpty);
catch 
end
