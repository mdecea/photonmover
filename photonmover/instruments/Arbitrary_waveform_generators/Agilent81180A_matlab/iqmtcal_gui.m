function varargout = iqmtcal_gui(varargin)
% IQMTCAL_GUI MATLAB code for iqmtcal_gui.fig
%      IQMTCAL_GUI, by itself, creates a new IQMTCAL_GUI or raises the existing
%      singleton*.
%
%      H = IQMTCAL_GUI returns the handle to a new IQMTCAL_GUI or the handle to
%      the existing singleton*.
%
%      IQMTCAL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQMTCAL_GUI.M with the given input arguments.
%
%      IQMTCAL_GUI('Property','Value',...) creates a new IQMTCAL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqmtcal_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqmtcal_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqmtcal_gui

% Last Modified by GUIDE v2.5 18-Aug-2019 15:12:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqmtcal_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqmtcal_gui_OutputFcn, ...
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


% --- Executes just before iqmtcal_gui is made visible.
function iqmtcal_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqmtcal_gui (see VARARGIN)

% Choose default command line output for iqmtcal_gui
handles.output = hObject;

% signal to in-system cal that it is being called from iqmain8070
if nargin > 3 && isreal(varargin{1})
    if (varargin{1} == 8070)
        handles.M8070Cal = 1;
    end
end
handles.result = [];
set(handles.popupmenuMemory, 'Value', 3); % 64K
set(handles.pushbuttonSave, 'Enable', 'off');  % no save without data
set(handles.pushbuttonUseAsDefault, 'Enable', 'off');
%try
    arbConfig = loadArbConfig();
    if (isempty(get(handles.editSampleRate, 'String')))
        set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
    end
    if (isempty(get(handles.editMaxFreq, 'String')))
        maxFreq = floor(0.5 * arbConfig.defaultSampleRate / 1e8) * 1e8;
        if (~isempty(strfind(arbConfig.model, 'M8194A')) && maxFreq > 55e9)   % special case for M8194A
            maxFreq = 55e9;
        end
        set(handles.editMaxFreq, 'String', iqengprintf(maxFreq));
    end
    chNums = find(arbConfig.channelMask);
    ch1List = cell(1,length(chNums));
    for i = 1:length(chNums)
        ch1List{i} = sprintf('%d', chNums(i));
    end
    ch234List = ch1List;
    ch234List{end+1} = 'unused';
    set(handles.popupmenu1AWG, 'String', ch1List);
    set(handles.popupmenu2AWG, 'String', ch234List);
    set(handles.popupmenu3AWG, 'String', ch234List);
    set(handles.popupmenu4AWG, 'String', ch234List);
    % make sure setting is valid
    set(handles.popupmenu1AWG, 'Value', min(length(ch1List), get(handles.popupmenu1AWG, 'Value')));
    set(handles.popupmenu2AWG, 'Value', min(length(ch234List), get(handles.popupmenu2AWG, 'Value')));
    set(handles.popupmenu3AWG, 'Value', min(length(ch234List), get(handles.popupmenu3AWG, 'Value')));
    set(handles.popupmenu4AWG, 'Value', min(length(ch234List), get(handles.popupmenu4AWG, 'Value')));
    if ((size(varargin, 1) >= 1) && strcmp(varargin{1}, 'single'))
        values = get(handles.popupmenu2AWG, 'String');
        set(handles.popupmenu2AWG, 'Value', length(values));
        values = get(handles.popupmenu2Scope, 'String');
        set(handles.popupmenu2Scope, 'Value', length(values));
    end
% catch ex
%     throw(ex);
% end

% Update handles structure
guidata(hObject, handles);

checkfields(hObject, [], handles);

% UIWAIT makes iqmtcal_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


function checkfields(hObject, eventdata, handles)
try
    arbConfig = loadArbConfig();
catch
    errordlg('Please set up connection to AWG and Scope in "Configure instrument connection"');
    close(handles.iqtool);
    return;
end
rtsConn = ((~isfield(arbConfig, 'isScopeConnected') || arbConfig.isScopeConnected ~= 0) && isfield(arbConfig, 'visaAddrScope'));
dcaConn = (isfield(arbConfig, 'isDCAConnected') && arbConfig.isDCAConnected ~= 0);
if (~rtsConn && ~dcaConn)
    errordlg('You must set up either a connection to a real-time scope or DCA in "Configure instrument connection"');
    close(handles.iqtool);
    return;
end
if (~rtsConn || ~dcaConn)
    set(handles.radiobuttonRTScope, 'Value', rtsConn);
    set(handles.radiobuttonDCA, 'Value', dcaConn);
    radiobuttonDCA_Callback([], [], handles);
    radiobuttonRTScope_Callback([], [], handles);
else
    radiobuttonRTScope_Callback([], [], handles);
end
% --- editSampleRate
value = -1;
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
    set(handles.editSampleRate, 'BackgroundColor', 'white');
else
    set(handles.editSampleRate, 'BackgroundColor', 'red');
end



% --- Outputs from this function are returned to the command line.
function varargout = iqmtcal_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
try
    varargout{1} = handles.output;
catch
end


% --- Executes on button press in pushbuttonRun.
function pushbuttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
doCalibrate(hObject, handles, 0);


function doCalibrate(hObject, handles, doCode)
% doCode = 0: perform an in-system calibration and update the correct file
% doCode = 1: generate MATLAB code that performs the in-system calibration
try
    maxFreq = evalin('base', ['[' get(handles.editMaxFreq, 'String') ']']);
    numTones = evalin('base', ['[' get(handles.editNumTones, 'String') ']']);
    scopeAvg = evalin('base', ['[' get(handles.editScopeAverage, 'String') ']']);
    analysisAvg = evalin('base', ['[' get(handles.editAnalysisAverages, 'String') ']']);
    amplitude = evalin('base', ['[' get(handles.editAmplitude, 'String') ']']);
    scopeBW = get(handles.editScopeBW, 'String');
    scopeSIRC = get(handles.checkboxSIRC, 'Value');
    separateTones = get(handles.checkboxSeparateTones, 'Value');
    list1 = get(handles.popupmenu1AWG, 'String');
    list2 = get(handles.popupmenu2AWG, 'String');
    list3 = get(handles.popupmenu3AWG, 'String');
    list4 = get(handles.popupmenu4AWG, 'String');
    trigList = get(handles.popupmenuTrigAWG, 'String');
    awgChannels = { list1{get(handles.popupmenu1AWG, 'Value')} ...
                    list2{get(handles.popupmenu2AWG, 'Value')} ...
                    list3{get(handles.popupmenu3AWG, 'Value')} ...
                    list4{get(handles.popupmenu4AWG, 'Value')} ...
                    trigList{get(handles.popupmenuTrigAWG, 'Value')}};
% --old style: array
%     awgChannels = [get(handles.popupmenu1AWG, 'Value') get(handles.popupmenu2AWG, 'Value') ...
%         get(handles.popupmenu3AWG, 'Value') get(handles.popupmenu4AWG, 'Value') get(handles.popupmenuTrigAWG, 'Value')];
    trigList = get(handles.popupmenuTrigAWG, 'String');
    list1 = get(handles.popupmenu1Scope, 'String');
    list2 = get(handles.popupmenu2Scope, 'String');
    list3 = get(handles.popupmenu3Scope, 'String');
    list4 = get(handles.popupmenu4Scope, 'String');
    trigList = get(handles.popupmenuTrigScope, 'String');
    scopeChannels = { list1{get(handles.popupmenu1Scope, 'Value')} ...
                      list2{get(handles.popupmenu2Scope, 'Value')} ...
                      list3{get(handles.popupmenu3Scope, 'Value')} ...
                      list4{get(handles.popupmenu4Scope, 'Value')} ...
                      trigList{get(handles.popupmenuTrigScope, 'Value')}};
    % if we are not triggering, then don't do averaging
    if (strcmpi(trigList{get(handles.popupmenuTrigScope, 'Value')}, 'unused'))
        scopeAvg = 1;
    end
    skewIncluded = get(handles.checkboxSkewIncluded, 'Value');
    scopeRST = get(handles.checkboxScopeRST, 'Value');
    if (scopeRST && (...
            ~isempty(strfind(scopeChannels{1}, 'DIFF')) || ...
            ~isempty(strfind(scopeChannels{2}, 'DIFF')) || ...
            ~isempty(strfind(scopeChannels{3}, 'DIFF')) || ...
            ~isempty(strfind(scopeChannels{4}, 'DIFF'))))
        res = questdlg(['You are calibrating on a differential scope channel with the "Scope *RST" checkbox checked. ' ...
            'This will reset your differential skew. Do you want to continue?'], ...
            'Continue', 'Yes', 'No', 'Yes');
        if (~strcmp(res, 'Yes'))
            return
        end
    end
    if (scopeRST && (...
            ~isempty(strfind(scopeChannels{1}, 'FUNC')) || ...
            ~isempty(strfind(scopeChannels{2}, 'FUNC')) || ...
            ~isempty(strfind(scopeChannels{3}, 'FUNC')) || ...
            ~isempty(strfind(scopeChannels{4}, 'FUNC'))))
        res = questdlg(['You are using a math function with the "Scope *RST" checkbox checked. ' ...
            'This will reset your differential skew. Do you want to continue?'], ...
            'Continue', 'Yes', 'No', 'Yes');
        if (~strcmp(res, 'Yes'))
            return
        end
    end
    AWGRST = get(handles.checkboxAWGRST, 'Value');
    recalibrate = get(handles.checkboxReCalibrate, 'Value');
    sampleRate = evalin('base', ['[' get(handles.editSampleRate, 'String') ']']);
    autoScopeAmplitude = get(handles.checkboxAutoScopeAmplitude, 'Value');
    plotAxes = [handles.axesMag handles.axesPhase];
    cla(plotAxes(1));
    cla(plotAxes(2));
    removeSinc = get(handles.checkboxRemoveSinc, 'Value');
    restoreScope = get(handles.checkboxRestoreScope, 'Value');
    sim = get(handles.popupmenuSimulation, 'Value') - 1;
    debugLevel = get(handles.popupmenuDebugLevel, 'Value') - 1;
    memory = 2^(get(handles.popupmenuMemory, 'Value') + 13);
    toneDevList = get(handles.popupmenuToneDev, 'String');
    toneDev = toneDevList{get(handles.popupmenuToneDev, 'Value')};
    if (get(handles.radiobuttonRTScope, 'Value'))
        scope = 'RTScope';
    elseif (get(handles.radiobuttonDCA, 'Value'))
        scope = 'DCA';
    else
        errordlg('Please select a scope');
        return;
    end
catch ex
    errordlg({'Invalid parameter setting', ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    return;
end
if (doCode)
    awgChannelsString = '{ ';
    for i=1:size(awgChannels,2)
        awgChannelsString = sprintf('%s''%s'' ', awgChannelsString, awgChannels{i});
    end
    awgChannelsString = sprintf('%s}', awgChannelsString);
    scopeChannelsString = '{ ';
    for i=1:size(awgChannels,2)
        scopeChannelsString = sprintf('%s''%s'' ', scopeChannelsString, scopeChannels{i});
    end
    scopeChannelsString = sprintf('%s}', scopeChannelsString);
    if (strcmp(scopeBW, ''))
        scopeBWstring = '[]';
    else
        scopeBWstring = sprintf('''%s''', scopeBW);
    end

    code = sprintf(['result = iqmtcal(''scope'', ''%s'', ''sim'', %d, ''scopeAvg'', %d, ...\n' ...
        '    ''numTones'', %d, ''scopeRST'', %d, ''AWGRST'', %d, ...\n' ...
        '    ''sampleRate'', %s, ''recalibrate'', %d, ...\n' ...
        '    ''autoScopeAmpl'', %d, ''memory'', %d, ...\n' ...
        '    ''awgChannels'', %s, ''scopeChannels'', %s, ...\n' ...
        '    ''maxFreq'', %s, ''analysisAvg'', %d, ''toneDev'', ''%s'', ...\n' ...
        '    ''amplitude'', %g, ''axes'', [], ...\n' ...
        '    ''scopeBW'', %s, ''scopeSIRC'', %d, ''separateTones'', %d, ...\n' ...
        '    ''skewIncluded'', %d, ''removeSinc'', %d, ''debugLevel'', %d);\n'], ...
        scope, sim, scopeAvg, numTones, scopeRST, AWGRST, iqengprintf(sampleRate), recalibrate, ...
        autoScopeAmplitude, memory, awgChannelsString, scopeChannelsString, ...
        iqengprintf(maxFreq), analysisAvg, toneDev, amplitude, scopeBWstring, scopeSIRC, ...
        separateTones, skewIncluded, removeSinc, debugLevel);
    iqgeneratecode(handles, code);
else
    result = [];
    try
        result = iqmtcal('scope', scope, 'sim', sim, 'scopeAvg', scopeAvg, ...
                'numTones', numTones, 'scopeRST', scopeRST, 'AWGRST', AWGRST, ...
                'sampleRate', sampleRate, 'recalibrate', recalibrate, ...
                'autoScopeAmpl', autoScopeAmplitude, 'memory', memory, ...
                'awgChannels', awgChannels, 'scopeChannels', scopeChannels, ...
                'maxFreq', maxFreq, 'analysisAvg', analysisAvg, 'toneDev', toneDev, ...
                'amplitude', amplitude, 'axes', plotAxes, ...
                'scopeBW', scopeBW, 'scopeSIRC', scopeSIRC, 'separateTones', separateTones, ...
                'skewIncluded', skewIncluded, 'removeSinc', removeSinc, 'debugLevel', debugLevel, 'restoreScope', restoreScope);
    catch ex
        errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    end
    handles.result = result;
    guidata(hObject, handles);
    if (~isempty(result))
        set(handles.pushbuttonSave, 'Enable', 'on');
        set(handles.pushbuttonUseAsDefault, 'Enable', 'on');
        if (sim == 0)
            if (isfield(handles, 'M8070Cal') && handles.M8070Cal == 1)
                res = questdlg('Save freq/phase response?', 'Save this measurement?', 'Yes', 'No', 'Yes');
                if (strcmp(res, 'Yes'))
                    pushbuttonSave_Callback(hObject, [], handles);
                end
            else
                pushbuttonUseAsDefault_Callback(hObject, [], handles);

% don't ask if the window can be closed
%                 res = questdlg('Close the In-system correction window?', 'Close?', 'Yes', 'No', 'No');
%                 if (strcmp(res, 'Yes'))
%                     % close the window to avoid confusion
%                     close(handles.iqtool);
%                 end
            end
        end
    else
        set(handles.pushbuttonSave, 'Enable', 'off');
        set(handles.pushbuttonUseAsDefault, 'Enable', 'off');
    end
end


function editScopeAverage_Callback(hObject, eventdata, handles)
% hObject    handle to editScopeAverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val) || ~isscalar(val) || val < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editScopeAverage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScopeAverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAnalysisAverages_Callback(hObject, eventdata, handles)
% hObject    handle to editAnalysisAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val) || ~isscalar(val) || val < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editAnalysisAverages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAnalysisAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobuttonRTScope.
function radiobuttonRTScope_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonRTScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (get(handles.radiobuttonRTScope, 'Value') == 1)
    arbConfig = loadArbConfig();
    rtsConn = ((~isfield(arbConfig, 'isScopeConnected') || arbConfig.isScopeConnected ~= 0) && isfield(arbConfig, 'visaAddrScope'));
    if (rtsConn)
        % if DCA was previously selected , save the channel assignment
        if (get(handles.radiobuttonDCA, 'Value'))
            handles.oldDCA_Chan = [ ...
                get(handles.popupmenu1Scope, 'Value') ...
                get(handles.popupmenu2Scope, 'Value') ...
                get(handles.popupmenu3Scope, 'Value') ...
                get(handles.popupmenu4Scope, 'Value') ...
                get(handles.popupmenuTrigScope, 'Value')];
            guidata(handles.output, handles);
        end
        % flip the radio buttons
        set(handles.radiobuttonRTScope, 'Value', 1);
        set(handles.radiobuttonDCA, 'Value', 0);
        % set the channel selection
        chanSet1 = {'1', '2', '3', '4', 'DIFF1', 'DIFF2', 'REdge1', 'REdge3', 'DIFFREdge', ...
            'FUNC1', 'FUNC2', 'FUNC3', 'FUNC4', 'FUNC5', 'FUNC6', 'FUNC7', 'FUNC8'};
        chanSet2 = { '1', '2', '3', '4', 'DIFF1', 'DIFF2', 'REdge1', 'REdge3', ...
            'FUNC1', 'FUNC2', 'FUNC3', 'FUNC4', 'FUNC5', 'FUNC6', 'FUNC7', 'FUNC8', 'unused' };
        % make sure the setting is valid
        set(handles.popupmenu1Scope, 'Value', min(length(chanSet1), get(handles.popupmenu1Scope, 'Value')));
        set(handles.popupmenu2Scope, 'Value', min(length(chanSet2), get(handles.popupmenu2Scope, 'Value')));
        set(handles.popupmenu3Scope, 'Value', min(length(chanSet2), get(handles.popupmenu3Scope, 'Value')));
        set(handles.popupmenu4Scope, 'Value', min(length(chanSet2), get(handles.popupmenu4Scope, 'Value')));
        set(handles.popupmenu1Scope, 'String', chanSet1);
        set(handles.popupmenu2Scope, 'String', chanSet2);
        set(handles.popupmenu3Scope, 'String', chanSet2);
        set(handles.popupmenu4Scope, 'String', chanSet2);
        set(handles.popupmenuTrigScope, 'String', {'1', '2', '3', '4', 'REdge1', 'REdge3', 'AUX', 'unused'});
        if (isfield(handles, 'oldRTS_Chan'))
            chan = handles.oldRTS_Chan;
        else
            chan = [1 2 length(chanSet2) length(chanSet2) 8];
            if (strcmp(getPopupStr(handles.popupmenu2AWG), 'unused'))
                chan(2) = find(strcmp(get(handles.popupmenu2Scope, 'String'), 'unused'), 1);
            end
        end
        set(handles.popupmenu1Scope, 'Value', chan(1));
        set(handles.popupmenu2Scope, 'Value', chan(2));
        set(handles.popupmenu3Scope, 'Value', chan(3));
        set(handles.popupmenu4Scope, 'Value', chan(4));
        set(handles.popupmenuTrigScope, 'Value', chan(5));
        set(handles.checkboxSIRC, 'Enable', 'Off');
        set(handles.textSIRC, 'Enable', 'Off');
        set(handles.editScopeBW, 'String', 'AUTO');
        set(handles.editScopeAverage, 'Enable', 'On');
        set(handles.textScopeAverage, 'Enable', 'On');
    else
        set(handles.radiobuttonRTScope, 'Value', 0);
        errordlg('You must set the VISA address of the real-time scope in "Configure Instrument"');
    end
end
checkChannels(handles);


% --- Executes on button press in radiobuttonDCA.
function radiobuttonDCA_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonDCA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (get(handles.radiobuttonDCA, 'Value') == 1)
    arbConfig = loadArbConfig();
    if (isfield(arbConfig, 'isDCAConnected') && arbConfig.isDCAConnected)
        % if RTScope was previously selected , save the channel assignment
        if (get(handles.radiobuttonRTScope, 'Value'))
            handles.oldRTS_Chan = [ ...
                get(handles.popupmenu1Scope, 'Value') ...
                get(handles.popupmenu2Scope, 'Value') ...
                get(handles.popupmenu3Scope, 'Value') ...
                get(handles.popupmenu4Scope, 'Value') ...
                get(handles.popupmenuTrigScope, 'Value')];
            guidata(handles.output, handles);
        end
        set(handles.radiobuttonDCA, 'Value', 1);
        set(handles.radiobuttonRTScope, 'Value', 0);
        chanSet1 = {'1A', '1B', 'DIFF1A', '1C', '1D', 'DIFF1C', '2A', '2B', 'DIFF2A', '2C', '2D', 'DIFF2C', '3A', '3B', 'DIFF3A', '3C', '3D', 'DIFF3C', '4A', '4B', 'DIFF4A', '4C', '4D', 'DIFF4C', '5A', '5B', 'DIFF5A', '5C', '5D', 'DIFF5C', ...
            'FUNC1', 'FUNC2', 'FUNC3', 'FUNC4', 'FUNC5', 'FUNC6', 'FUNC7', 'FUNC8', 'FUNC9', 'FUNC10', 'FUNC11', 'FUNC12'};
        chanSet2 = { chanSet1{1:end}, 'unused' };
        set(handles.popupmenu1Scope, 'String', chanSet1);
        set(handles.popupmenu2Scope, 'String', chanSet2);
        set(handles.popupmenu3Scope, 'String', chanSet2);
        set(handles.popupmenu4Scope, 'String', chanSet2);
        set(handles.popupmenuTrigScope, 'String', {'Front Panel' 'PTB+FP'});
        if (isfield(handles, 'oldDCA_Chan'))
            chan = handles.oldDCA_Chan;
        else
            chan = [1 2 length(chanSet2) length(chanSet2) 2];
            if (strcmp(getPopupStr(handles.popupmenu2AWG), 'unused'))
                chan(2) = find(strcmp(get(handles.popupmenu2Scope, 'String'), 'unused'), 1);
            end
        end
        set(handles.popupmenuTrigScope, 'Value', chan(5));
        set(handles.popupmenu1Scope, 'Value', chan(1));
        set(handles.popupmenu2Scope, 'Value', chan(2));
        set(handles.popupmenu3Scope, 'Value', chan(3));
        set(handles.popupmenu4Scope, 'Value', chan(4));
        set(handles.checkboxSIRC, 'Enable', 'On');
        set(handles.textSIRC, 'Enable', 'On');
        set(handles.editScopeBW, 'String', 'MAX');
        set(handles.editScopeAverage, 'Enable', 'Off');
        set(handles.textScopeAverage, 'Enable', 'Off');
    else
        set(handles.radiobuttonDCA, 'Value', 0);
        errordlg('You must set the VISA address of the DCA in "Configure Instrument" if you want to use a DCA for calibration');
    end
end
checkChannels(handles);


function editMaxFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editMaxFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
    fs = evalin('base', ['[' get(handles.editSampleRate, 'String'), ']']);
    if (val > fs/2)
        val = [];
    end
catch ex
end
if (isempty(val))
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end



% --- Executes during object creation, after setting all properties.
function editMaxFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMaxFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumTones_Callback(hObject, eventdata, handles)
% hObject    handle to editNumTones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val))
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editNumTones_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumTones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu1AWG.
function popupmenu1AWG_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1AWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenu1AWG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1AWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2AWG.
function popupmenu2AWG_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2AWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(getPopupStr(handles.popupmenu2AWG), 'unused'))
    setPopupStr(handles.popupmenu2Scope, 'unused');
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenu2AWG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2AWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu3AWG.
function popupmenu3AWG_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3AWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(getPopupStr(handles.popupmenu3AWG), 'unused'))
    setPopupStr(handles.popupmenu3Scope, 'unused');
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenu3AWG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3AWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu4AWG.
function popupmenu4AWG_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4AWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(getPopupStr(handles.popupmenu4AWG), 'unused'))
    setPopupStr(handles.popupmenu4Scope, 'unused');
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenu4AWG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4AWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu1Scope.
function popupmenu1Scope_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1Scope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = getPopupStr(handles.popupmenu1Scope);
if (strncmpi(val, 'REdge1', 6))
    setPopupStr(handles.popupmenu2Scope, 'REdge3');
    setPopupStr(handles.popupmenu2Scope, 'unused');
    setPopupStr(handles.popupmenu2Scope, 'unused');
    setPopupStr(handles.popupmenuTrigScope, 'unused');
    setPopupStr(handles.popupmenuTrigAWG, 'unused');
end
if (strncmpi(val, 'DIFFREdge', 9))
    setPopupStr(handles.popupmenu2AWG, 'unused');
    setPopupStr(handles.popupmenu2Scope, 'unused');
    setPopupStr(handles.popupmenuTrigScope, 'unused');
    setPopupStr(handles.popupmenuTrigAWG, 'unused');
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenu1Scope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1Scope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2Scope.
function popupmenu2Scope_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2Scope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(getPopupStr(handles.popupmenu2Scope), 'unused'))
    setPopupStr(handles.popupmenu2AWG, 'unused');
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenu2Scope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2Scope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu3Scope.
function popupmenu3Scope_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3Scope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(getPopupStr(handles.popupmenu3Scope), 'unused'))
    setPopupStr(handles.popupmenu3AWG, 'unused');
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenu3Scope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3Scope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu4Scope.
function popupmenu4Scope_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4Scope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(getPopupStr(handles.popupmenu4Scope), 'unused'))
    setPopupStr(handles.popupmenu4AWG, 'unused');
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenu4Scope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4Scope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuTrigAWG.
function popupmenuTrigAWG_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (strcmp(getPopupStr(handles.popupmenuTrigAWG), 'unused'))
    setPopupStr(handles.popupmenuTrigScope, 'unused');
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuTrigAWG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function checkChannels(handles)
h = [handles.popupmenu1AWG, handles.popupmenu2AWG, handles.popupmenu3AWG, handles.popupmenu4AWG, handles.popupmenuTrigAWG, ...
     handles.popupmenu1Scope, handles.popupmenu2Scope, handles.popupmenu3Scope, handles.popupmenu4Scope, handles.popupmenuTrigScope];
hx = zeros(1, 10);       % flag for error
hv = get(h, 'Value');    % values
hs = cell(1, 10);        % strings
seperateTones = get(handles.checkboxSeparateTones, 'Value');
for i=1:10
    list = get(h(i), 'String');
    hs{i} = list{hv{i}};
end
% check for AWG double use of channels
for i=1:4
    for j=i+1:5
        if (strcmp(hs{i}, hs{j}) && ~strcmp(hs{i}, 'unused'))
            hx(i) = 1;
            hx(j) = 1;
        end
    end
end
% check for scope double use of channels
for i=6:9
    if (seperateTones)
        cmpStart = 10;
    else
        cmpStart = i+1;
    end
    for j=cmpStart:10
        if (strcmp(hs{i}, hs{j}) && ~strcmp(hs{i}, 'unused'))
            hx(i) = 1;
            hx(j) = 1;
        end
    end
end
% [c,b] = sort([hv{6} hv{7} hv{8} hv{9}]);
% hsx = hs(6:9);
% p = find(diff(c) == 0);   % find index of duplicates
% p(strcmp(hsx(p), 'unused')) = [];        % don't tread "unused" as duplicates
% if (~isempty(p))
%     hx(b(p)+5) = 1;         % p and p+1 point to a duplicate
%     hx(b(p+1)+5) = 1;       % flag both of them red
% end
% % check scope same channel as trigger
% if (~strcmp(hs{10}, 'Front Panel') && ~strcmp(hs{10}, 'PTB+FP') && ~strcmp(hs{10}, 'AUX') && ~strcmp(hs{10}, 'unused'))
%     if (strcmpi(hs{6}, hs{10})); hx(6) = 1; hx(10) = 1; end
%     if (strcmpi(hs{7}, hs{10})); hx(7) = 1; hx(10) = 1; end
%     if (strcmpi(hs{8}, hs{10})); hx(8) = 1; hx(10) = 1; end
%     if (strcmpi(hs{9}, hs{10})); hx(9) = 1; hx(10) = 1; end
% end
% check for unused connected to not unused
if (strcmp(hs{1}, 'unused') && ~strcmp(hs{6}, 'unused')); hx(1) = 1; end
if (~strcmp(hs{1}, 'unused') && strcmp(hs{6}, 'unused')); hx(6) = 1; end
if (strcmp(hs{2}, 'unused') && ~strcmp(hs{7}, 'unused')); hx(2) = 1; end
if (~strcmp(hs{2}, 'unused') && strcmp(hs{7}, 'unused')); hx(7) = 1; end
if (strcmp(hs{3}, 'unused') && ~strcmp(hs{8}, 'unused')); hx(3) = 1; end
if (~strcmp(hs{3}, 'unused') && strcmp(hs{8}, 'unused')); hx(8) = 1; end
if (strcmp(hs{4}, 'unused') && ~strcmp(hs{9}, 'unused')); hx(4) = 1; end
if (~strcmp(hs{4}, 'unused') && strcmp(hs{9}, 'unused')); hx(9) = 1; end
% check for unused trigger connected to not unused trigger
if (strcmp(hs{5}, 'unused') && ~strcmp(hs{10}, 'unused')); hx(5) = 1; end
if (~strcmp(hs{5}, 'unused') && strcmp(hs{10}, 'unused')); hx(10) = 1; end
% if one channel is real edge, both of them have to be
if (strncmpi(hs{6}, 'REdge', 7) && ~(strncmpi(hs{7}, 'REdge', 5) || strcmp(hs{7}, 'unused'))); hx(7) = 1; end
if (strncmpi(hs{7}, 'REdge', 5) && ~strncmpi(hs{6}, 'REdge', 5)); hx(6) = 1; end
% if using real edge, the trigger has to be AUX or unused
if ((strncmpi(hs{6}, 'REdge', 5) || strncmpi(hs{7}, 'REdge', 5) || strncmpi(hs{8}, 'REdge', 5) || strncmpi(hs{9}, 'REdge', 5)) && ...
        ~(strcmp(hs{10}, 'AUX') || strncmpi(hs{10}, 'REdge', 5) || strcmp(hs{10}, 'unused')))
    hx(10) = 1;
end
arbConfig = loadArbConfig();
% switch arbConfig.model
%     case {'M8195A_1ch' 'M8195A_1ch_mrk'}    % can only use channel 1
%         if (hv{1} > 1 && ~strcmp(hs{1}, 'unused')); hx(1) = 1; end
%         if (hv{2} > 1 && ~strcmp(hs{2}, 'unused')); hx(2) = 1; end
%         if (hv{3} > 1 && ~strcmp(hs{3}, 'unused')); hx(3) = 1; end
%         if (hv{4} > 1 && ~strcmp(hs{4}, 'unused')); hx(4) = 1; end
%         if (~strcmp(hs{5}, 'Marker') && ~strcmp(hs{5}, 'unused')); hx(5) = 1; end
%     case {'M8195A_2ch' }    % can only use two channels
%         if ((hv{1} ~= 1 && hv{1} ~= 4) && ~strcmp(hs{1}, 'unused')); hx(1) = 1; end
%         if ((hv{2} ~= 1 && hv{2} ~= 4) && ~strcmp(hs{2}, 'unused')); hx(2) = 1; end
%         if ((hv{3} ~= 1 && hv{3} ~= 4) && ~strcmp(hs{3}, 'unused')); hx(3) = 1; end
%         if ((hv{4} ~= 1 && hv{4} ~= 4) && ~strcmp(hs{4}, 'unused')); hx(4) = 1; end
%         if (~strcmp(hs{5}, 'Marker') && ~strcmp(hs{5}, 'unused') && hv{5} ~= 1 && hv{5} ~= 4); hx(5) = 1; end
%     case {'M8195A_2ch_mrk' }   % can only use two channels
%         if ((hv{1} ~= 1 && hv{1} ~= 2) && ~strcmp(hs{1}, 'unused')); hx(1) = 1; end
%         if ((hv{2} ~= 1 && hv{2} ~= 2) && ~strcmp(hs{2}, 'unused')); hx(2) = 1; end
%         if ((hv{3} ~= 1 && hv{3} ~= 2) && ~strcmp(hs{3}, 'unused')); hx(1) = 1; end
%         if ((hv{4} ~= 1 && hv{4} ~= 2) && ~strcmp(hs{4}, 'unused')); hx(2) = 1; end
%         if (~strcmp(hs{5}, 'Marker') && ~strcmp(hs{5}, 'unused') && hv{5} ~= 1 && hv{5} ~= 2); hx(5) = 1; end
% end
% turn the background to red for those that violate a rule
for i = 1:10
    if (hx(i))
        set(h(i), 'Background', 'red');
    else
        set(h(i), 'Background', 'white');
    end
end


function res = getPopupStr(handle)
% get the string in a given popupmenu
list = get(handle, 'String');
res = list{get(handle, 'Value')};


function setPopupStr(handle, str)
% set the string in a given popupmenu if it exists
list = get(handle, 'String');
p = find(strcmp(list, str), 1);
if (~isempty(p))
    set(handle, 'Value', p);
else
%    error(sprintf('can''t set %s in %s', str, handle.Tag));
end


% --- Executes on selection change in popupmenuTrigScope.
function popupmenuTrigScope_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
list = get(handles.popupmenuTrigScope, 'String');
if (strcmp(list{get(handles.popupmenuTrigScope, 'Value')}, 'unused'))
    list = get(handles.popupmenuTrigAWG, 'String');
    p = find(strcmp(list, 'unused'), 1);
    if (~isempty(p))
        set(handles.popupmenuTrigAWG, 'Value', p);
    end
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuTrigScope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val) || ~isscalar(val) || val < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editAmplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuSimulation.
function popupmenuSimulation_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSimulation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSimulation


% --- Executes during object creation, after setting all properties.
function popupmenuSimulation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDebugLevel.
function popupmenuDebugLevel_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDebugLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDebugLevel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDebugLevel


% --- Executes during object creation, after setting all properties.
function popupmenuDebugLevel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDebugLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSkewIncluded.
function checkboxSkewIncluded_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSkewIncluded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSkewIncluded


% --- Executes on button press in checkboxScopeRST.
function checkboxScopeRST_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxScopeRST (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxScopeRST


% --- Executes on button press in pushbuttonSave.
function pushbuttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (isfield(handles, 'result') && ~isempty(handles.result))
    Cal = handles.result;
    freq = Cal.Frequency_MT * 1e9;
    mag = Cal.AmplitudeResponse_MT;
    phase = Cal.AbsPhaseResponse_MT;
    cplxCorr = (10 .^ (mag/20)) .* exp(1i * phase/180*pi);
    % set up perChannelCorr structure
    clear perChannelCorr;
    perChannelCorr(:,1) = freq(1:end);
    perChannelCorr(:,2:size(cplxCorr,2)+1) = 1 ./ cplxCorr;
    savePerChannelCorr(perChannelCorr, Cal.AWGChannels);
else
    msgbox('no valid measurement available');
end
    

function savePerChannelCorr(perChannelCorr, AWGChannels)
% prompt user for a filename and save frequency response in desired format
% note: same function as in iqcorrmgmt.m --> should be unified
numChan = size(perChannelCorr, 2) - 1;
sp1 = sprintf('.s%dp', 2*numChan);
sp2 = sprintf('Touchstone %d-port file (*.s%dp)', 2*numChan, 2*numChan);
[filename, pathname, filterindex] = uiputfile({...
    sp1, sp2; ...
    '.mat', 'MATLAB file (*.mat)'; ...
    '.csv', 'CSV file (*.csv)'; ...
    '.csv', 'CSV (VSA style) (*.csv)'}, ...
    'Save Frequency Response As...');
if (filename ~= 0)
    switch filterindex
        case 2 % .mat
            try
                clear Cal;
                Cal.Frequency_MT = perChannelCorr(:,1) / 1e9;
                Cal.AmplitudeResponse_MT = -20 * log10(abs(perChannelCorr(:,2:end)));
                Cal.AbsPhaseResponse_MT = unwrap(angle(perChannelCorr(:,2:end))) * -180 / pi;
                Cal.AWGChannels = AWGChannels;
                save(fullfile(pathname, filename), 'Cal');
            catch ex
                errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
            end
        case 3 % .csv
            cal = zeros(size(perChannelCorr,1), 2*(size(perChannelCorr,2)-1)+1);
            cal(:,1) = perChannelCorr(:,1);
            for i = 1:numChan
               cal(:,2*i) = 20 * log10(abs(perChannelCorr(:,i+1)));
               cal(:,2*i+1) = unwrap(angle(perChannelCorr(:,i+1))) * 180 / pi;
            end
            csvwrite(fullfile(pathname, filename), cal);
        case 4 % .csv (VSA style)
            try
                ch = 1;
                if (size(perChannelCorr, 2) > 2)
                    list = cellstr(char(AWGChannels));
                    [ch,~] = listdlg('PromptString', 'Select Channel', 'SelectionMode', 'single', 'ListString', list(1:size(perChannelCorr,2)-1), 'ListSize', [100 60]);
                end
                if (~isempty(ch))
                    f = fopen(fullfile(pathname, filename), 'wt');
                    % if positive frequencies only, mirror to negative side
                    nPts = size(perChannelCorr, 1);
                    pf = polyfit((0:nPts-1)', perChannelCorr(:,1), 1);
                    fprintf(f, sprintf('FileFormat UserCal-1.0\n'));    % new tag - Nizar Messaoudi
                    fprintf(f, sprintf('Trace Data\n'));                % new tag - Nizar Messaoudi
                    fprintf(f, sprintf('YComplex1\n'));                 % new tag - Nizar Messaoudi
                    fprintf(f, sprintf('YFormat RI\n'));                % new tag - Nizar Messaoudi
                    fprintf(f, sprintf('InputBlockSize, %d\n', nPts));
                    fprintf(f, sprintf('XStart, %g\n', pf(2)));
                    fprintf(f, sprintf('XDelta, %g\n', pf(1)));
                    %fprintf(f, sprintf('YUnit, lin\n'));               % removed tag - Nizar Messaoudi
                    fprintf(f, sprintf('Y\n'));
                    for i = 1:nPts
                        fprintf(f, sprintf('%g,%g\n', real(1/perChannelCorr(i,ch+1)), imag(1/perChannelCorr(i,ch+1))));
                        %fprintf(f, sprintf('%g,%g\n', abs(1/perChannelCorr(i,ch+1)), -angle(perChannelCorr(i,ch+1))));
                        %fprintf(f, sprintf('%g,%g\n', -20*log10(abs(perChannelCorr(i,ch+1))), unwrap(angle(perChannelCorr(i,ch+1))) * -180 / pi));
                    end
                    fclose(f);
                end
            catch ex
                errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
            end
        case 1 % .sNp
            try
                freq = perChannelCorr(:,1);
                sparam = zeros(2*numChan, 2*numChan, size(freq,1));
                for i = 1:numChan
                    tmp = 1./perChannelCorr(:,i+1);
                    sparam(2*i-1,2*i,:) = tmp;
                    sparam(2*i,2*i-1,:) = tmp;
                end
                sp = rfdata.data('Freq', freq, 'S_Parameters', sparam);
                sp.write(fullfile(pathname, filename));
            catch ex
                errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
            end
    end
end


% --- Executes on button press in pushbuttonUseAsDefault.
function pushbuttonUseAsDefault_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUseAsDefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (isfield(handles, 'result') && ~isempty(handles.result))
    recalibrate = get(handles.checkboxReCalibrate, 'Value');
    Cal = handles.result;
    written = updatePerChannelCorr(hObject, handles, Cal.Frequency_MT * 1e9, Cal.AmplitudeResponse_MT, Cal.AbsPhaseResponse_MT, Cal.AWGChannels, recalibrate);
    % if the corr mgmt window is open, update the graphs
    if (written)
        updateCorrWindow();
    end
    % adjust DC offset in AWG if we are not using a differential channel
    % and not on M320xA and M9336A
    arbConfig = loadArbConfig();
    if (isempty(find(strcmp(arbConfig.model, { 'M8198A_Rev0' 'M9336A' 'N824xA' 'M3201A' 'M3202A' 'M3201A_CLF', 'M3202A_CLF' 'M3201A_CLV', 'M3202A_CLV'}), 1)))
        iList = get(handles.popupmenu1Scope, 'String');
        if (~strncmpi(iList{get(handles.popupmenu1Scope, 'Value')}, 'DIFF', 4))
            if (~isempty(strfind(arbConfig.model, 'M8190A')))
                n = 2;
            else % M8195A, ...
                n = 4;
            end
            chans = Cal.AWGChannels;
            for m = 4:-1:1  % up to 4 modules
                if (m == 1)
                    va = 'visaAddr';
                else
                    va = sprintf('visaAddr%d', m);
                end
                idx = chans >= n*(m-1)+1 & chans <= n*m;
                chs = chans(idx) - n*(m-1);
                if (~isempty(chs) && isfield(arbConfig, va))
                    adjustOffset(arbConfig.(va), chs, Cal.DCOffset(idx));
                end
            end
        end
    end
else
    msgbox('no valid measurement available');
end


% adjust the amplifier offset after calibration
function adjustOffset(visaAddr, chans, offsets)
try
    f = iqopen(visaAddr);
    if (isempty(f))
        return;
    end
    for i = 1:length(chans)
        offOld = str2double(query(f, sprintf(':VOLT%d:OFFS?', chans(i))));
        offNew = offOld - offsets(i);
        fprintf(f, sprintf(':VOLT%d:OFFS %g', chans(i), offNew));
%        fprintf('%s - chan %d  %g  (%g --> %g)\n', visaAddr, chans(i), offsets(i), offOld, offNew);
    end
    fclose(f);
catch
end


function updateCorrWindow()
% If Correction Mgmt Window is open, refresh it
try
    TempHide = get(0, 'ShowHiddenHandles');
    set(0, 'ShowHiddenHandles', 'on');
    figs = findobj(0, 'Type', 'figure', 'Name', 'Correction Management');
    set(0, 'ShowHiddenHandles', TempHide);
    if (~isempty(figs))
        iqcorrmgmt();
    end
catch
end



function written = updatePerChannelCorr(hObject, handles, freq, mag, phase, AWGChannels, recalibrate)
% update the PerChannel correction file
written = 0;
cplxCorr = (10 .^ (mag/20)) .* exp(1i * phase/180*pi);
% set up perChannelCorr structure
clear perChannelCorr;
perChannelCorr(:,1) = freq(1:end);
perChannelCorr(:,2:size(cplxCorr,2)+1) = 1 ./ cplxCorr;
if (recalibrate)
    % get the filename
    ampCorrFile = iqampCorrFilename();
    clear acs;
    % try to load ampCorr file - be graceful if it does not exist
    try
        acs = load(ampCorrFile);
    catch
        errordlg('existing correction file can not be loaded');
        return;
    end
    if (isfield(acs, 'perChannelCorr') && ~isempty(acs.perChannelCorr))
        % make sure we have the same frequency points and same number of channels
        if (~isequal(perChannelCorr(:,1), acs.perChannelCorr(:,1)) || size(perChannelCorr,2) ~= size(acs.perChannelCorr, 2))
            errordlg('Number of frequency points or number of channels does not match with original calibration');
            return;
        end
        % new correction is the product of old and new
        acs.perChannelCorr(:,2:end) = acs.perChannelCorr(:,2:end) .* perChannelCorr(:,2:end);
        % once additive correction has been applied it must not be added again!
        set(handles.pushbuttonSave, 'Enable', 'off');
        set(handles.pushbuttonUseAsDefault, 'Enable', 'off');
        handles.result = [];
        guidata(hObject, handles);
        % and save
        written = 1;
        try
            save(ampCorrFile, '-struct', 'acs');
        catch ex
            errordlg(sprintf('Can''t save correction file: %s. Please check if it write-protected.', ex.message));
        end
    end
else
    written = checkMergeOverwrite(perChannelCorr, AWGChannels, 1);
end


function written = checkMergeOverwrite(perChannelCorr, AWGChannels, alwaysAsk)
% NOTE: same function as in iqcorrmgmt.m
% check, if new perChannelCorr should overwrite existing file
% of if the user should be asked
written = 0;
ampCorrFile = iqampCorrFilename();
clear acs;
oldPcc = [];
oldAWGChannels = [];
% try to load ampCorr file - be graceful if it does not exist
try
    acs = load(ampCorrFile);
    if (isfield(acs, 'perChannelCorr'))
        oldPcc = acs.perChannelCorr;
    end
    if (isfield(acs, 'AWGChannels'))
        oldAWGChannels = acs.AWGChannels;
    end
catch
end
if (~alwaysAsk && ...
    (isempty(oldAWGChannels) || ...    % if no channel assignment in the file --> overwrite
     isempty(AWGChannels) || ...       % if no new channel assignment --> overwrite
     (length(AWGChannels) == length(oldAWGChannels) && isequal(sort(AWGChannels), sort(oldAWGChannels))))) % all channels matching --> overwrite
        acs.perChannelCorr = perChannelCorr;
        acs.AWGChannels = AWGChannels;
        written = 1;
else
    % partial overlap --> ask what to do
    res = questdlg('Do you want to overwrite the existing correction or merge only certain channels?', 'Overwrite or Merge', 'Overwrite', 'Merge', 'Cancel', 'Overwrite');
    switch (res)
        case 'Merge'
            % ok, this is the complicated one...
            if (length(AWGChannels) == 1)
                % if there is only one channel being loaded, then don't ask
                mergeCh = AWGChannels;
            else
                % otherwise ask, which channels to merge
                defaultVal = {strtrim(sprintf('%d ', AWGChannels))};
                res = inputdlg('Select AWG channel(s) to merge', 'Select AWG channel(s) to merge', 1, defaultVal);
                if (isempty(res))
                    return;
                end
                mergeCh = sscanf(res{1}, '%d', inf);
                if (isempty(mergeCh))
                    return
                end
                if (isempty(intersect(mergeCh, AWGChannels)))
                    errordlg('please select at least one channel from the given set');
                    return;
                end
            end
            % merge the frequency points
            [newFreq, oldCorr, newCorr] = iqmergecorr(oldPcc(:,1), oldPcc(:,2:end), perChannelCorr(:,1), perChannelCorr(:,2:end));
            % create new perChannelCorr structure
            newChan = union(oldAWGChannels, mergeCh);
            newPcc = zeros(length(newFreq), length(newChan)+1);
            newPcc(:,1) = newFreq;
            for i = 1:length(newChan)
                ch = newChan(i);
                p = find(mergeCh == ch, 1);
                if (~isempty(p))
                    idx = find(AWGChannels == ch, 1);
                    newPcc(:,i+1) = newCorr(:,idx);
                else
                    idx = find(oldAWGChannels == ch, 1);
                    newPcc(:,i+1) = oldCorr(:,idx);
                end
            end
            acs.AWGChannels = newChan;
            acs.perChannelCorr = newPcc;
            written = 1;
        case 'Overwrite'
            acs.perChannelCorr = perChannelCorr;
            acs.AWGChannels = AWGChannels;
            written = 1;
        case 'Cancel'
            return
    end
end 
% save
if (written)
    try
        save(ampCorrFile, '-struct', 'acs');
    catch ex
        errordlg(sprintf('Can''t save correction file: %s. Please check if it write-protected.', ex.message));
    end
end


% --- Executes on selection change in popupmenuMemory.
function popupmenuMemory_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuMemory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuMemory contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuMemory


% --- Executes during object creation, after setting all properties.
function popupmenuMemory_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuMemory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuToneDev.
function popupmenuToneDev_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuToneDev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuToneDev contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuToneDev


% --- Executes during object creation, after setting all properties.
function popupmenuToneDev_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuToneDev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxAWGRST.
function checkboxAWGRST_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAWGRST (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAWGRST


% --- Executes on button press in checkboxAutoScopeAmplitude.
function checkboxAutoScopeAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoScopeAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject, 'Value');
if (val)
    set(handles.editAmplitude, 'Enable', 'off');
else
    set(handles.editAmplitude, 'Enable', 'on');
end
% Hint: get(hObject,'Value') returns toggle state of checkboxAutoScopeAmplitude



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkfields(hObject, 0, handles);


% --- Executes during object creation, after setting all properties.
function editSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxReCalibrate.
function checkboxReCalibrate_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxReCalibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.pushbuttonSave, 'Enable', 'off');
set(handles.pushbuttonUseAsDefault, 'Enable', 'off');
handles.result = [];
guidata(hObject, handles);


% --- Executes on button press in checkboxRemoveSinc.
function checkboxRemoveSinc_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxRemoveSinc (see GCBO)
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


% --------------------------------------------------------------------
function menuGenerateCode_Callback(hObject, eventdata, handles)
% hObject    handle to menuGenerateCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
doCalibrate(hObject, handles, 1);


% --- Executes on button press in checkboxRestoreScope.
function checkboxRestoreScope_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxRestoreScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxRestoreScope


% --------------------------------------------------------------------
function menuShowDebug_Callback(hObject, eventdata, handles)
% hObject    handle to menuShowDebug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject, 'Checked');
if (strcmp(val, 'on'))
    val = 'off';
else
    val = 'on';
end
set(hObject, 'Checked', val);
set(handles.uipanelDebug, 'Visible', val);


% --- Executes on button press in checkboxSIRC.
function checkboxSIRC_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSIRC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSIRC



function editScopeBW_Callback(hObject, eventdata, handles)
% hObject    handle to editScopeBW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScopeBW as text
%        str2double(get(hObject,'String')) returns contents of editScopeBW as a double


% --- Executes during object creation, after setting all properties.
function editScopeBW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScopeBW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSeparateTones.
function checkboxSeparateTones_Callback(hObject, eventdata, handles)
checkChannels(handles);
