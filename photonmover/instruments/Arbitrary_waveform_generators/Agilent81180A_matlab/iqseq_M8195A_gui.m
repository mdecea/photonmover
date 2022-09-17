function varargout = iqseq_M8195A_gui(varargin)
% IQSEQ_M8195A_GUI MATLAB code for iqseq_M8195A_gui.fig
%      iqseq_M8195A_gui, by itself, creates a new iqseq_M8195A_gui or raises the existing
%      singleton*.
%
%      H = iqseq_M8195A_gui returns the handle to a new iqseq_M8195A_gui or the handle to
%      the existing singleton*.
%
%      iqseq_M8195A_gui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in iqseq_M8195A_gui.M with the given input arguments.
%
%      iqseq_M8195A_gui('Property','Value',...) creates a new iqseq_M8195A_gui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqseq_M8195A_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqseq_M8195A_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqseq_M8195A_gui

% Last Modified by GUIDE v2.5 31-Jan-2014 17:16:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqseq_M8195A_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqseq_M8195A_gui_OutputFcn, ...
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


% --- Executes just before iqseq_M8195A_gui is made visible.
function iqseq_M8195A_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqseq_M8195A_gui (see VARARGIN)

% Choose default command line output for iqseq_M8195A_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

checkfields([], [], handles);
arbConfig = loadArbConfig();

% UIWAIT makes iqseq_M8195A_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqseq_M8195A_gui_OutputFcn(hObject, eventdata, handles) 
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
if (~iqoptcheck([], 'M8195A', 'SEQ'))
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
% load the sequence table
sequenceTable = cell2struct(get(handles.uitableSeq, 'Data'), ...
    {'idx', 'segmentNumber', 'segmentLoops', 'segmentAdvance', 'markerEnable', 'sequenceInit', ...
     'sequenceLoops', 'sequenceAdvance'}, 2);
for i=1:size(sequenceTable,1)
    if (sequenceTable(i).sequenceInit && i > 1)
        sequenceTable(i-1).sequenceEnd = 1;
    end
    if (strcmp(sequenceTable(i).sequenceAdvance, 'n.a.'))
        sequenceTable(i).sequenceAdvance = 'Auto';
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
            for f = {'markerEnable' 'sequenceInit', 'sequenceEnd', 'scenarioEnd'}
                fld = f{1};
                if (~isempty(sequenceTable(i).(fld)) && sequenceTable(i).(fld) ~= 0)
                    code = sprintf('%sseq(%d).%s = %d;\n', code, i, fld, sequenceTable(i).(fld));
                end
            end
        end
        code = sprintf('%s\n%% download the sequence table and run\n', code);
        code = sprintf('%siqseq(''define'', seq, ''run'', 0, ''keepOpen'', 1);\n', code);
        code = sprintf('%siqseq(''mode'', ''STSCenario'');\n', code);
    else
        sequenceTable = rmfield(sequenceTable, {'idx'});
        iqseq('define', sequenceTable, 'run', 0, 'keepOpen', 1);
        iqseq('mode', 'STSCenario');
    end
end


% --- Executes on button press in pushbuttonInsertSeq.
function pushbuttonInsertSeq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInsertSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
insertRow(handles, 'Seq', { 0, 1, 1, 'Auto', true, true, 1, 'Auto'});


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
iqseq('list', []);


% --- Executes on button press in pushbuttonDeleteAllSegments.
function pushbuttonDeleteAllSegments_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDeleteAllSegments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqseq('delete', []);


% --- Executes on button press in pushbuttonEvent.
function pushbuttonEvent_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqseq('event', []);


% --- Executes on button press in pushbuttonTrigger.
function pushbuttonTrigger_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqseq('trigger', []);


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
msgbox({'Use this utility to create a sequence for the M8195A' ...
    ''});


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
    if (isempty(data{i,3}) || strcmp(data{i,3}, ''))
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
function menuPreset_Callback(hObject, eventdata, handles)
% hObject    handle to menuPreset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuDemoSeq_Callback(hObject, eventdata, handles)
% hObject    handle to menuTwoAlternatingActionExample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = [{ 0, 1,      1, 'Auto', false,  true, 1, 'Auto'};
        { 1, 1, 100000, 'Auto',  true, false, 1, 'Auto'};
        { 2, 1,      1, 'Auto', false,  true, 1, 'Conditional'};
        { 3, 1, 100000, 'Auto',  true, false, 1, 'Auto'};
        { 4, 1,      1, 'Auto', false, false, 1, 'Auto'};
        { 5, 1, 100000, 'Auto',  true, false, 1, 'Auto'}];
set(handles.uitableSeq, 'Data', data);
set(handles.textSeqEmpty, 'Visible', 'off');
checkSequenceTable(handles, data, 1);


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
arbConfig = loadArbConfig();


% --------------------------------------------------------------------
function menuGenerateCode_Callback(hObject, eventdata, handles)
% hObject    handle to menuGenerateCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
code = doDownload(handles, 1);
iqgeneratecode(handles, code);


% --- Executes on button press in pushbuttonReadSeq.
function pushbuttonReadSeq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonReadSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Reading Sequence Table...', 'Please wait...', 'replace');
stab = iqseq('readSequence', []);
for i = 1:length(stab)
    if (stab(i).sequenceInit == 0)
        stab(i).sequenceAdvance = 'n.a.';
        stab(i).sequenceLoops = [];
    end
end
if isa(stab,'struct')
    stab = rmfield(stab, {'sequenceEnd', 'scenarioEnd'});
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
    posSeqTab(4) = posWindow(4) - 55;
    set(handles.uitableSeq, 'Position', posSeqTab);
    posSeqEmpty = get(handles.textSeqEmpty, 'Position');
    posSeqEmpty(2) = (posWindow(4) - 100)/2;
    set(handles.textSeqEmpty, 'Position', posSeqEmpty);
catch 
end
