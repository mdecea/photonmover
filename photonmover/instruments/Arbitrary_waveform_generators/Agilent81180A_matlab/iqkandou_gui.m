function varargout = iqkandou_gui(varargin)
% IQKANDOU_GUI MATLAB code for iqkandou_gui.fig
%      IQKANDOU_GUI, by itself, creates a new IQKANDOU_GUI or raises the existing
%      singleton*.
%
%      H = IQKANDOU_GUI returns the handle to a new IQKANDOU_GUI or the handle to
%      the existing singleton*.
%
%      IQKANDOU_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQKANDOU_GUI.M with the given input arguments.
%
%      IQKANDOU_GUI('Property','Value',...) creates a new IQKANDOU_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqkandou_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqkandou_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqkandou_gui

% Last Modified by GUIDE v2.5 06-Aug-2019 18:16:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqkandou_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqkandou_gui_OutputFcn, ...
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


% --- Executes just before iqkandou_gui is made visible.
function iqkandou_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqkandou_gui (see VARARGIN)

% Choose default command line output for iqkandou_gui
handles.output = hObject;
handles.DirPath = pwd;

% Update handles structure
guidata(hObject, handles);

% reposition some edit fields to be on top of each other
pos1 = get(handles.editFilename, 'Position');
pos2 = get(handles.editUserData, 'Position');
% pos3 = get(handles.editLevels, 'Position');
pos2(1:2) = pos1(1:2);
set(handles.editUserData, 'Position', pos2);
% pos3(1:2) = pos1(1:2);
% set(handles.editLevels, 'Position', pos3);
% put trigger divider on top of clock divider editfields
pos = get(handles.editClockDivider, 'Position');
set(handles.editTrigDivider, 'Position', pos);

% default channel mapping
arbConfig = loadArbConfig();
if (~isempty(strfind(arbConfig.model, 'M8196A')))
    set(handles.radiobuttonRefClk, 'Value', 1);
    set(handles.editDataRate, 'String', '28e9');
    set(handles.editNumBits, 'String', '5120');
    set(handles.editSampleRate, 'String', '89.6e9');
else
    set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
end
if (isempty(get(handles.pushbuttonChannelMapping, 'Userdata')))
    doChannelSetup(handles);
end
checkfields([], [], handles);


% UIWAIT makes iqkandou_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqkandou_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[sig, fs, dataRate, numSamples] = calc_serial(handles, 'display', []);
set(handles.editNumSamples, 'String', sprintf('%d', numSamples));
if (~isempty(sig))
%     iqplot(s, fs, 'nospectrum');
%     isplot(s, fs, dataRate);
%     try
%         iqeyeplot(s, fs, fs/dataRate, 2);
%     catch
%     end
    nEyes = 20;
    spb = fs/dataRate;
    factor = ceil(16 / spb);
    if (factor > 1)
        s = zeros(size(sig,1)*factor, size(sig,2));
        for i = 1:size(sig,2)
            s(:,i) = iqresample(sig(:,i), length(sig)*factor);
        end
        sig = s;
        fs = fs * factor;
        spb = spb * factor;
    end
    % limit the number of samples
    nsamples = min(size(sig,1), floor(nEyes*spb));
    sig = sig(1:nsamples, :);
    % time axis scaling
    ttime = spb/fs*nEyes;
    if (ttime < 1e-9)
        tscale = 1e12;
        tunit = 'ps';
    elseif (ttime < 1e-6)
        tscale = 1e9;
        tunit = 'ns';
    elseif (ttime < 1e-3)
        tscale = 1e6;
        tunit = 'us';
    elseif (ttime < 1)
        tscale = 1e3;
        tunit = 'ms';
    else
        tscale = 1;
        tunit = 'sec';
    end
    % amplitude of the signal (just needed for "nice" looking plot)
    amplitude = max(max(sig)) - min(min(sig));
    m1 = min(min(sig)) - 0.05 * amplitude;
    m2 = max(max(sig)) + 0.05 * amplitude;
    figure(1); clf;
    t = tscale*(0:nsamples-1)/fs;
    plot(t, sig, '-');
    ylim([m1 m2]);
    xlabel(tunit);
    title(['First ' num2str(nEyes) ' UIs of the signal']);
    leg = {};
    for i = 1:size(sig,2)
        leg{i} = sprintf('Wire %d', i);
    end
    legend(leg);
end


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
[s, fs, ~, numSamples, channelMapping] = calc_serial(handles, 'download', []);
set(handles.editNumSamples, 'String', sprintf('%d', numSamples));
if (~isempty(s))
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
    if (get(handles.radiobuttonRefClk, 'Value'))
        marker = [];
    else
        marker = downloadClock(handles);
    end
    iqdownload(s, fs, 'channelMapping', channelMapping, ...
        'segmentNumber', segmentNum, 'marker', marker);
end
try close(hMsgBox); catch; end



function [s, fs, dataRate, numSamples, channelMapping] = calc_serial(handles, fct, param)
s = [];
fs = 0;
numSamples = 0;
dataRate = evalin('base', get(handles.editDataRate, 'String'));
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
autoSampleRate = get(handles.checkboxAutoSampleRate, 'Value');
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
dataType = dataTypeList{get(handles.popupmenuDataType, 'Value')};
formatStr = 'NRZ';
numBits = evalin('base', get(handles.editNumBits, 'String'));
symbolShift = 0; %evalin('base', get(handles.editSymbolShift, 'String'));
useM8196RefClk = get(handles.radiobuttonRefClk, 'Value');
if (get(handles.radiobuttonCNRZ5, 'Value'))
    codeType = 'CNRZ5';
elseif (get(handles.radiobuttonDB, 'Value'))
    codeType = 'DuoBinary';
else
    codeType = 'ENRZ';
end
if (~isempty(strfind(dataType, 'file')))
    userData = double(ptrnfile2data(fullfile(handles.DirPath, get(handles.editFilename, 'String'))));
    if (isempty(userData) || isequal(userData, -1))
        return;
    end
    dataType = 'User defined';
else
    try
        % try to interpret userdata as a list of values
        userData = evalin('base', ['[' get(handles.editUserData, 'String') ']']);
        if (isempty(userData))
            return;
        end
    catch
        % if this fails, try to evaluate as a statement that assigns
        % something to the variable "data"
        clear data;
        eval(get(handles.editUserData, 'String'));
        userData = data;   % expect "data" to be assigned
    end
end
preCursor = evalin('base', ['[' get(handles.editPreCursor, 'String') ']']);
postCursor = evalin('base', ['[' get(handles.editPostCursor, 'String') ']']);
filterTypeList = get(handles.popupmenuFilterType, 'String');
filterType = filterTypeList{get(handles.popupmenuFilterType, 'Value')};
filterNsym = evalin('base', get(handles.editNsym, 'String'));
filterBeta = evalin('base', get(handles.editAlpha, 'String'));
tTime = evalin('base', ['[' get(handles.editTransitionTime, 'String') ']']);
JShapeList = get(handles.popupmenuJitterShape, 'String');
JShape = JShapeList{get(handles.popupmenuJitterShape, 'Value')};
SJfreq = evalin('base', ['[' get(handles.editSJfreq, 'String') ']']);
SJpp = evalin('base', ['[' get(handles.editSJpp, 'String') ']']);
RJpp = evalin('base', get(handles.editRJpp, 'String'));
sscFreq = evalin('base', get(handles.editSSCfreq, 'String'));
sscDepth = evalin('base', get(handles.editSSCdepth, 'String'));
noiseFreq = evalin('base', get(handles.editNoiseFreq, 'String'));
noise = evalin('base', get(handles.editNoise, 'String'));
isi = 0; %evalin('base', get(handles.editISI, 'String'));
amplitude = 1; %evalin('base', get(handles.editAmplitude, 'String'));
dutyCycle = evalin('base', get(handles.editDutyCycle, 'String'));
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
% unless we download, just look at the real part of the first channel
if (~strcmp(fct, 'download') && ~strcmp(fct, 'clock'))
    channelMapping = [1 0];
end
correction = get(handles.checkboxCorrection, 'Value');
if (strcmp(fct, 'clock'))
    codeType = 'clock';
    % set the channel mapping for the clock only
    channelMapping = channelMapping(:,end-1:end);
    % force a certain pattern - independent of user settings
    dataType = 'User defined';
    userData = param;
    % make clock without distortions
    SJpp = 0;
    RJpp = 0;
    noise = 0;
    amplitude = 1;
    dutyCycle = 50;
end
if (autoSampleRate)
    sampleRate = 0;
end
levels = evalin('base', ['[' get(handles.editLevels, 'String') ']']);
levelStr = ['[' sprintf('%g ', levels) ']'];
if (strcmp(dataType, 'User defined'))
    data = userData;
    numBits = length(data);
    set(handles.editNumBits, 'String', num2str(numBits));
    dataStr = ['[' sprintf('%g ', userData) ']'];
    levels = [];
    levelStr = '[]';
elseif (~isempty(strfind(dataType, 'levels')))
    data = dataType;
    dataStr = sprintf('''%s''', dataType);
else
    data = dataType;
    dataStr = sprintf('''%s''', dataType);
end
switch (fct)
    case 'code' % generate MATLAB code
        channelMappingStr = iqchannelsetup('arraystring', get(handles.pushbuttonChannelMapping, 'UserData'));
        segmentNum = evalin('base', get(handles.editSegment, 'String'));
        if (isLargeData(handles))
            downloadStr = '';
        else
            downloadStr = sprintf('iqdownload(s, fs, ''segmentNumber'', %g, ''channelMapping'', chMap);\n', segmentNum);
        end
        s = sprintf(['kdata = iqkandoupattern(data, numBits, codeType, levels);\n' ...
            'if (~isempty(kdata))\n' ...
            '    res = [];\n' ...
            '    for i = 1:size(kdata,2)\n' ...
            '        data = kdata(:,i);\n' ...
            '        chMap = channelMapping(:,2*i-1:2*i);\n' ...
            '        [s, fs, nSym, nSamples, chMap] = iserial(''dataRate'', %g, ''sampleRate'', %g, ...\n' ...
            '            ''numBits'', %d, ''data'', %s, ''format'', ''%s'', ''function'', ''download'', ''levels'', %s, ...\n' ...
            '            ''SJfreq'', [%s], ''SJpp'', [%s], ''RJpp'', %g, ''noiseFreq'', %g, ''noise'', %g, ''isi'', %g, ...\n' ...
            '            ''preCursor'', [%s], ''postCursor'', [%s], ''transitionTime'', %g, ...\n' ...
            '            ''filterType'', ''%s'', ''filterNsym'', %g, ''filterBeta'', %g, ...\n' ...
            '            ''jitterShape'', ''%s'', ''sscFreq'', %g, ''sscDepth'', %g, ''symbolShift'', %d, ...\n' ...
            '            ''amplitude'', %g, ''dutyCycle'', %g, ''correction'', %g, ''channelMapping'', %s, ...\n' ...
            '            ''normalize'', 0, ''useM8196RefClk'', %d);' ...
            '        res(:,i) = s;\n' ...
            '\n%s'], ...
            dataRate, sampleRate, numBits, dataStr, formatStr, levelStr, sprintf('%g ', SJfreq), ...
            sprintf('%g ', SJpp), RJpp, noiseFreq, noise, ...
            isi, sprintf('%g ', preCursor), sprintf('%g ', postCursor), tTime, filterType, filterNsym, filterBeta, ...
            JShape, sscFreq, sscDepth / 100, ...
            symbolShift, amplitude, dutyCycle / 100, correction, channelMappingStr, useM8196RefClk, downloadStr);
        fs = 0;
        dataRate = 0;
    case {'download' 'display' 'save' 'clock'} % generate the actual waveform
        kdata = iqkandoupattern(data, numBits, codeType, levels);
        if (~isempty(kdata))
            res = [];
            chMapRes = [];
            for i = 1:size(kdata,2)
                data = kdata(:,i);
                ch = min(size(channelMapping,2), 2*i);
                chMap = channelMapping(:,ch-1:ch);
                if (sum(sum(chMap)) ~= 0)
                    [s, fs, numBits, numSamples, chMapNew] = iserial('dataRate', dataRate, 'sampleRate', sampleRate, ...
                        'numBits', numBits, 'data', data, 'levels', [], 'format', formatStr, 'function', fct, 'filename', param, ...
                        'SJfreq', SJfreq, 'SJpp', SJpp, 'RJpp', RJpp, 'noiseFreq', noiseFreq, 'noise', noise, 'isi', isi, ...
                        'preCursor', preCursor, 'postCursor', postCursor, 'transitionTime', tTime, ...
                        'filterType', filterType, 'filterNsym', filterNsym, 'filterBeta', filterBeta, ...
                        'jitterShape', JShape, 'sscFreq', sscFreq, 'sscDepth', sscDepth / 100, 'symbolShift', symbolShift, ...
                        'amplitude', amplitude, 'dutyCycle', dutyCycle / 100, 'correction', correction, 'channelMapping', chMap, ...
                        'normalize', 0, 'useM8196RefClk', useM8196RefClk);
                    % ignore any imaginary part - just in case...
                    s = real(s);
                    % make sure the data is in the correct format (column vector)
                    if (size(s,1) < size(s,2))
                        s = s.';
                    end
                    res = [res s];
                    chMapRes = [chMapRes chMapNew];
                end
            end
            s = res;
            channelMapping = chMapRes;
            sc = max(max(abs(s)));
            if (sc > 1)
                s = s / sc;
            end
            set(handles.editSampleRate, 'String', iqengprintf(fs));
            set(handles.editNumBits, 'String', num2str(numBits));
            assignin('base', 'signal', s);
            assignin('base', 'sampleRate', fs);
            assignin('base', 'dataRate', dataRate);
            assignin('base', 'chMap', channelMapping);
            % update clock divider fields
            checkfields([], [], handles);
        end
    otherwise
        errordlg(['unexpected function' fct]);
end



function marker = downloadClock(handles)
% download a clock signal on unchecked channels, but don't start the generator
marker = [];
div = round(evalin('base', get(handles.editClockDivider, 'String')));
isCheckedOnce = 0;
numBits = evalin('base', get(handles.editNumBits, 'String'));
if (div > 1)
    clockPat = repmat([ones(1,floor(div/2)) zeros(1,div - floor(div/2))], 1, ceil(numBits/div));
    clockPat = clockPat(1:numBits)';
    if (mod(numBits, div) ~= 0)
        warndlg(sprintf('Number of bits is not a multiple of %d - clock signal will not be periodic', div), 'Warning', 'replace');
    end
elseif (isCheckedOnce)
    clockPat = [ones(1, floor(numBits/2)) zeros(1, numBits - floor(numBits/2))]';
else
    return;
end
[s, fs, dataRate, ~, chMap] = calc_serial(handles, 'clock', clockPat);
if (~isempty(s))
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
    if (~isempty(find(chMap(1:end), 1)))
        iqdownload(s, fs, 'channelMapping', chMap, 'segmentNumber', segmentNum, 'run', 0);
    end
    if (div > 1)
        numSamples = length(s);
        % find the oversampling ratio, ignore the fractional part, since it
        % can not be realized with markers
        [overN overD] = rat(fs / dataRate * div);
        % for 1x oversampling, set marker every other symbol
        overN = max(overN, 2);
        % don't send markers faster than 10 GHz (DCA)
        maxTrig = 5e9;
        % for M8190A, max toggle rate for markers = sequencer clock
        if (fs <= 12e9) 
            maxTrig = fs / 64;
        end
        % for M8195A, markers can toggle at a max. rate of fs/128
        if (fs > 50e9 && fs < 70e9)
            maxTrig = fs / 128;
        end
        if (ceil(fs / maxTrig / overN) > 1)
            overN = overN * ceil(fs / maxTrig / overN);
        end
        h1 = floor(overN / 2);
        h2 = overN - h1;
        marker = repmat([15*ones(1,h1) zeros(1,h2)], 1, ceil(numSamples / overN));
        marker = marker(1:numSamples);
    end
end


% --- Executes on button press in pushbuttonConfigScope.
function pushbuttonConfigScope_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonConfigScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
fs = evalin('base', get(handles.editSampleRate, 'String'));
dr = evalin('base', get(handles.editDataRate, 'String'));
numBits = evalin('base', get(handles.editNumBits, 'String'));
refclk = get(handles.radiobuttonRefClk, 'Value');
if (refclk)
    clkdiv = round(dr * 32 / fs);
    clkFreq = fs / 32;
else
    clkdiv = evalin('base', get(handles.editClockDivider, 'String'));
    clkFreq = dr / clkdiv;
end
if (arbConfig.isDCAConnected)
    f = iqopen(arbConfig.visaAddrDCA);
    if (~isempty(f))
        fprintf(f, ':TRIG:PLOC OFF');
        query(f, '*OPC?');
        fprintf(f, ':TIM:PTIM:RFR %g', clkFreq);
        fprintf(f, ':TIM:PTIM:RTR');
        fprintf(f, ':TRIG:SOUR FPAN');
        fprintf(f, ':TRIG:MODE CLOCK');
        fprintf(f, ':TRIG:SRAT:AUTO OFF');
        fprintf(f, ':TRIG:SRAT %g', dr);
        fprintf(f, ':TRIG:PLEN:AUTO OFF');
        fprintf(f, ':TRIG:PLEN %d', numBits);
        fprintf(f, ':TRIG:DCDR:AUTO OFF');
        fprintf(f, ':TRIG:DCDR SUB%d', clkdiv);
        fprintf(f, ':TRIG:PLOC ON');
        query(f, '*OPC?');
    end
else
    msgbox('Please configure the connection to the DCA in the "Instrument Configuration Window"');
end


% --- Executes on button press in pushbuttonMTCal.
function pushbuttonMTCal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMTCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqmtcal_gui();


function editDataRate_Callback(hObject, eventdata, handles)
% hObject    handle to editDataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
arbConfig = loadArbConfig();
if (isscalar(value) && value >= 1e3 && value <= arbConfig.maximumSampleRate(1))
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
    autoSampleRate = get(handles.checkboxAutoSampleRate, 'Value');
    if (autoSampleRate)
        arbConfig = loadArbConfig();
        sampleRate = arbConfig.defaultSampleRate;
    end
    % if the datarate is larger than Fs/4, adjust transition time
    % to avoid excessive jitter
    ttVal = get(handles.sliderTransitionTime, 'Value');
    if (ttVal < value / sampleRate * 4)
        ttVal = min(value / sampleRate * 4, 1);
        ttVal = ceil(ttVal * 100) / 100;
        set(handles.sliderTransitionTime, 'Value', ttVal);
        sliderTransitionTime_Callback([], [], handles);
    end
    % if the symbol rate is more than 50% of sample rate,
    % suggest Raised Cosine (user can still switch back if desired)
    if (value / sampleRate > 1/2 && get(handles.popupmenuFilterType, 'Value') == 1)
        set(handles.popupmenuFilterType, 'Value', 2);
        popupmenuFilterType_Callback([], [], handles);
    end
    checkfields([], [], handles);
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editDataRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkfields([], [], handles);


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


% --- Executes on button press in checkboxAutoSampleRate.
function checkboxAutoSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
autoSamples = get(handles.checkboxAutoSampleRate, 'Value');
if (autoSamples)
    set(handles.editSampleRate, 'Enable', 'off');
else
    set(handles.editSampleRate, 'Enable', 'on');
end



function editNumSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSamples as text
%        str2double(get(hObject,'String')) returns contents of editNumSamples as a double


% --- Executes during object creation, after setting all properties.
function editNumSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDataType.
function popupmenuDataType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setupUserDefGuiCtrls(handles);



function setupUserDefGuiCtrls(handles)
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
dataType = dataTypeList{get(handles.popupmenuDataType, 'Value')};
checkM8195A = 0;
if (strcmp(dataType, 'User defined'))
    set(handles.editNumBits, 'Enable', 'Off');
    set(handles.editUserData, 'Visible', 'On');
    set(handles.editUserData, 'Enable', 'On');
    set(handles.fileBrowser, 'Visible', 'Off');
    set(handles.editFilename, 'Visible', 'Off');
%     set(handles.editLevels, 'Visible', 'Off');
    set(handles.textUserData, 'String', 'User defined data');
elseif (~isempty(strfind(dataType, 'file')))
    set(handles.editNumBits, 'Enable', 'Off');
    set(handles.editUserData, 'Visible', 'Off');
    set(handles.editUserData, 'Enable', 'Off');
    set(handles.fileBrowser, 'Visible', 'On');
    set(handles.fileBrowser, 'Enable', 'On');
    set(handles.editFilename, 'Visible', 'On');
    set(handles.editFilename, 'Enable', 'On');
%     set(handles.editLevels, 'Visible', 'Off');
    set(handles.textUserData, 'String', 'User pattern file');
else
    set(handles.editNumBits, 'Enable', 'On');
    set(handles.editUserData, 'Enable', 'Off');
    set(handles.editFilename, 'Enable', 'Off');
    set(handles.fileBrowser, 'Enable', 'Off');
%     set(handles.editLevels, 'Enable', 'Off');
end
switch dataType
    case 'PRBS2^7-1'
        set(handles.editNumBits, 'String', '10 * (2^7 - 1)');
    case 'PRBS2^9-1'
        set(handles.editNumBits, 'String', '10 * (2^9 - 1)');
    case 'PRBS2^10-1'
        set(handles.editNumBits, 'String', '6 * (2^10 - 1)');
    case 'PRBS2^11-1'
        set(handles.editNumBits, 'String', '2 * (2^11 - 1)');
    case 'PRBS2^12-1'
        set(handles.editNumBits, 'String', '2 * (2^12 - 1)');
    case 'PRBS2^13-1'
        set(handles.editNumBits, 'String', '2 * (2^13 - 1)');
    case 'PRBS2^15-1'
        set(handles.editNumBits, 'String', '2 * (2^15 - 1)');
end


% --- Executes during object creation, after setting all properties.
function popupmenuDataType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumBits_Callback(hObject, eventdata, handles)
% hObject    handle to editNumBits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 2 && value <= 10e6)
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
end


function checkSSC(handles)
dataRate = evalin('base', get(handles.editDataRate, 'String'));
numBits = evalin('base', get(handles.editNumBits, 'String'));
sscDepth = evalin('base', get(handles.editSSCdepth, 'String'));
sscFreq = evalin('base', get(handles.editSSCfreq, 'String'));
if (sscDepth == 0 || dataRate / numBits <= sscFreq)
    set(handles.editSSCfreq, 'BackgroundColor', 'white');
else
    set(handles.editSSCfreq, 'BackgroundColor', 'red');
    errordlg(sprintf(['SSC frequency is too low *or* current number of symbols is too small.\n' ...
        'Please increase SSC frequency to %s *or* increase number of symbols to %d'], ...
        iqengprintf(dataRate / numBits, 3), ceil(dataRate / sscFreq)));
end



% --- Executes during object creation, after setting all properties.
function editNumBits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumBits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLevels_Callback(hObject, eventdata, handles)
% hObject    handle to editLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
    errordlg('Must be a list of values in the range 0...1', 'Error', 'replace');
end
checkfields([], [], handles);


% --- Executes during object creation, after setting all properties.
function editLevels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFilename_Callback(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = ptrnfile2data(fullfile(handles.DirPath, get(handles.editFilename, 'String')));
if (isempty(data))
    set(handles.editFilename, 'Background', 'red');
else
    set(handles.editFilename, 'Background', 'white');
    set(handles.editNumBits, 'String', iqengprintf(length(data)));
end


% --- Executes during object creation, after setting all properties.
function editFilename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in fileBrowser.
function fileBrowser_Callback(hObject, eventdata, handles)
% hObject    handle to fileBrowser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uigetfile({'*.ptrn;*.txt'},'Select a pattern file', handles.DirPath);
if filename ~= 0
     set(handles.editFilename,'String',filename);
     handles.DirPath = pathname;
     % Update handles structure
     guidata(hObject, handles);
end



function editPreCursor_Callback(hObject, eventdata, handles)
% hObject    handle to editPreCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(value) || (isvector(value) && min(value) >= -10 && max(value) <= 10))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPreCursor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPreCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPostCursor_Callback(hObject, eventdata, handles)
% hObject    handle to editPostCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(value) || (isvector(value) && min(value) >= -10 && max(value) <= 10))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPostCursor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPostCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderTransitionTime_Callback(hObject, eventdata, handles)
% hObject    handle to sliderTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(handles.sliderTransitionTime, 'Value');
set(handles.editTransitionTime, 'String', sprintf('%.2g', value));
dataRate = evalin('base', get(handles.editDataRate, 'String'));
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
if (value < 1 && value < dataRate / sampleRate * 4)
    set(handles.sliderTransitionTime, 'Background', 'yellow');
else
    set(handles.sliderTransitionTime, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function sliderTransitionTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editTransitionTime_Callback(hObject, eventdata, handles)
% hObject    handle to editTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(handles.sliderTransitionTime, 'Value', value(1));
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end



% --- Executes during object creation, after setting all properties.
function editTransitionTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNsym_Callback(hObject, eventdata, handles)
% hObject    handle to editNsym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (~isempty(value) && (isscalar(value) && floor(value) == value && min(value) >= 1 && max(value) <= 500))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNsym_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNsym (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAlpha_Callback(hObject, eventdata, handles)
% hObject    handle to editAlpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (~isempty(value) && (isscalar(value) && min(value) > 0 && max(value) <= 50))
    try
        filterNsym = evalin('base', get(handles.editNsym, 'String'));
        recommendedNsym = 4 * round(10 / sqrt(value));
        if (filterNsym < recommendedNsym)
            set(handles.editNsym, 'String', sprintf('%d', recommendedNsym));
        end
    catch; end;
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editAlpha_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAlpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editUserData_Callback(hObject, eventdata, handles)
% hObject    handle to editUserData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch
    try
        clear data;
        eval(get(hObject, 'String'));
        value = data;   % expect "data" to be assigned
    catch
        errordlg('Must specify a list of values separated by space or comma *or* a MATLAB statement that assigns a value to the variable "data"');
    end
end
if (isvector(value) && length(value) >= 2 && ...
        min(value) >= 0 && max(value) <= 1)
    set(handles.editNumBits, 'String', num2str(length(value)));
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
    errordlg('Data values must be between 0 and 1 and separated by spaces or comma. MATLAB expressions are acceptable');
end


% --- Executes during object creation, after setting all properties.
function editUserData_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editUserData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuFilterType.
function popupmenuFilterType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuFilterType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filterTypeList = get(handles.popupmenuFilterType, 'String');
filterType = filterTypeList{get(handles.popupmenuFilterType, 'Value')};
if (strcmp(filterType, 'Transition Time'))
    set(handles.textNsymAlpha, 'Visible', 'off');
    set(handles.editNsym, 'Visible', 'off');
    set(handles.editAlpha, 'Visible', 'off');
    set(handles.sliderTransitionTime, 'Visible', 'on');
    set(handles.editTransitionTime, 'Visible', 'on');
    set(handles.textTransitionTime, 'Visible', 'on');
else
    set(handles.textNsymAlpha, 'Visible', 'on');
    set(handles.editNsym, 'Visible', 'on');
    set(handles.editAlpha, 'Visible', 'on');
    set(handles.sliderTransitionTime, 'Visible', 'off');
    set(handles.editTransitionTime, 'Visible', 'off');
    set(handles.textTransitionTime, 'Visible', 'off');
    if (strcmp(filterType, 'Gaussian'))
        set(handles.textNsymAlpha, 'String', 'Nsym / BT');
    else
        set(handles.textNsymAlpha, 'String', 'Nsym / Alpha');
    end
end


% --- Executes during object creation, after setting all properties.
function popupmenuFilterType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuFilterType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSJfreq_Callback(hObject, eventdata, handles)
% hObject    handle to editSJfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 64e9)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSJfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSJfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderSJpp_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(hObject, 'Value');
set(handles.editSJpp, 'String', sprintf('%.2g', value));


% --- Executes during object creation, after setting all properties.
function sliderSJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editSJpp_Callback(hObject, eventdata, handles)
% hObject    handle to editSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(handles.sliderSJpp, 'Value', value(1));
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderRJpp_Callback(hObject, eventdata, handles)
% hObject    handle to sliderRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(hObject, 'Value');
set(handles.editRJpp, 'String', sprintf('%.2g', value));


% --- Executes during object creation, after setting all properties.
function sliderRJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editRJpp_Callback(hObject, eventdata, handles)
% hObject    handle to editRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderRJpp, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editRJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNoiseFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editNoiseFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNoiseFreq as text
%        str2double(get(hObject,'String')) returns contents of editNoiseFreq as a double


% --- Executes during object creation, after setting all properties.
function editNoiseFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNoiseFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderNoise_Callback(hObject, eventdata, handles)
% hObject    handle to sliderNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(hObject, 'Value');
set(handles.editNoise, 'String', sprintf('%.2g', value));


% --- Executes during object creation, after setting all properties.
function sliderNoise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editNoise_Callback(hObject, eventdata, handles)
% hObject    handle to editNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderNoise, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNoise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderDutyCycle_Callback(hObject, eventdata, handles)
% hObject    handle to sliderDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(hObject, 'Value');
set(handles.editDutyCycle, 'String', sprintf('%.0f', value));


% --- Executes during object creation, after setting all properties.
function sliderDutyCycle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editDutyCycle_Callback(hObject, eventdata, handles)
% hObject    handle to editDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 100)
    set(handles.sliderDutyCycle, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editDutyCycle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection


% --- Executes on button press in pushbuttonShowCorrection.
function pushbuttonShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqcorrmgmt();


function editSegment_Callback(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkfields([], [], handles);


% --- Executes during object creation, after setting all properties.
function editSegment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSSCfreq_Callback(hObject, eventdata, handles)
% hObject    handle to editSSCfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1e9)
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSSCfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSSCfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSSCdepth_Callback(hObject, eventdata, handles)
% hObject    handle to editSSCdepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 100)
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
end



% --- Executes during object creation, after setting all properties.
function editSSCdepth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSSCdepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuJitterShape.
function popupmenuJitterShape_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuJitterShape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuJitterShape contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuJitterShape


% --- Executes during object creation, after setting all properties.
function popupmenuJitterShape_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuJitterShape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editClockDivider_Callback(hObject, eventdata, handles)
checkfields([], [], handles);


% --- Executes during object creation, after setting all properties.
function editClockDivider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editClockDivider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobuttonCNRZ5.
function radiobuttonCNRZ5_Callback(hObject, eventdata, handles)
doChannelSetup(handles);
checkfields([], [], handles);


% --- Executes on button press in radiobuttonENRZ.
function radiobuttonENRZ_Callback(hObject, eventdata, handles)
doChannelSetup(handles);
checkfields([], [], handles);


% --- Executes on button press in radiobuttonDB.
function radiobuttonDB_Callback(hObject, eventdata, handles)
doChannelSetup(handles);
checkfields([], [], handles);


function result = checkfields(~, ~, handles)
result = 1;
arbConfig = loadArbConfig();

% --- generic checks
if (arbConfig.maxSegmentNumber <= 1)
    set(handles.editSegment, 'Enable', 'off');
    set(handles.textSegment, 'Enable', 'off');
else
    set(handles.editSegment, 'Enable', 'on');
    set(handles.textSegment, 'Enable', 'on');
end
% --- editSampleRate
value = -1;
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
    set(handles.editSampleRate, 'BackgroundColor', 'white');
else
    set(handles.editSampleRate, 'BackgroundColor', 'red');
    result = 0;
end
% --- editSegment
value = -1;
try
    value = evalin('base', get(handles.editSegment, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && value >= 1 && value <= arbConfig.maxSegmentNumber)
    set(handles.editSegment,'BackgroundColor','white');
else
    set(handles.editSegment,'BackgroundColor','red');
    result = 0;
end
% --- CNRZ5  5 bits/6 wires --> 17 possible voltage levels
if (get(handles.radiobuttonCNRZ5, 'Value'))
    levSet = 17;
elseif (get(handles.radiobuttonDB, 'Value'))
% --- DuoBinary 3 bits/4 wires --> 7 possible voltage levels
    levSet = 7;
else
% --- ENRZ 3 bits/4 wires --> 4 possible voltage levels
    levSet = 4;
end
if (levSet ~= 0)
    udLev = evalin('base', ['[' get(handles.editLevels, 'String') ']']);
    if (length(udLev) ~= levSet)
        set(handles.editLevels, 'String', ['[0' sprintf(' %d', (1:levSet-1)) '] / ' sprintf('%d', levSet-1)]);
    end
    set(handles.editNumBits, 'Enable', 'On');
%     set(handles.editUserData, 'Visible', 'Off');
    set(handles.editUserData, 'Enable', 'Off');
    set(handles.fileBrowser, 'Visible', 'Off');
    set(handles.editFilename, 'Visible', 'Off');
    set(handles.editLevels, 'Visible', 'On');
    set(handles.editLevels, 'Enable', 'On');
%    set(handles.textUserData, 'String', 'User defined levels');
end
% --- clock radiobuttons
if (get(handles.radiobuttonChannel, 'Value'))
    set(handles.textClockDivider, 'Enable', 'on');
    set(handles.textClockFreq, 'Enable', 'on');
    set(handles.editTrigDivider, 'Visible', 'off');
    try
        fs = 0;
        dr = 0;
        clkdiv = 1;
        fs = evalin('base', get(handles.editSampleRate, 'String'));
        dr = evalin('base', get(handles.editDataRate, 'String'));
        clkdiv = evalin('base', get(handles.editClockDivider, 'String'));
        set(handles.editClockFreq, 'String', iqengprintf(dr / clkdiv));
        set(handles.editTrigDivider, 'String', iqengprintf(clkdiv));
    catch
        set(handles.editClockFreq, 'String', '?');
        set(handles.editTrigDivider, 'String', '?');
    end
end
if (get(handles.radiobuttonRefClk, 'Value'))
    set(handles.textClockDivider, 'Enable', 'on');
    set(handles.textClockFreq, 'Enable', 'on');
    set(handles.editTrigDivider, 'Visible', 'on');
    try
        fs = 0;
        fs = evalin('base', get(handles.editSampleRate, 'String'));
        dr = evalin('base', get(handles.editDataRate, 'String'));
        set(handles.editClockFreq, 'String', iqengprintf(fs / 32));
        set(handles.editTrigDivider, 'String', iqengprintf(dr * 32 / fs));
    catch
        set(handles.editClockFreq, 'String', '?');
        set(handles.editTrigDivider, 'String', '?');
    end
end
if (get(handles.radiobuttonNoClock, 'Value'))
    set(handles.textClockDivider, 'Enable', 'off');
    set(handles.textClockFreq, 'Enable', 'off');
    set(handles.editClockFreq, 'String', '');
    set(handles.editTrigDivider, 'Visible', 'on');
    set(handles.editTrigDivider, 'String', '');
end


% --- Executes on button press in pushbuttonChannelMapping.
function pushbuttonChannelMapping_Callback(hObject, eventdata, handles)
arbConfig = loadArbConfig();
% workaround to save channel names: UserData of pushbuttonDownload
cNames = get(handles.pushbuttonDownload, 'UserData');
[val, str] = iqchanneldlg(get(hObject, 'UserData'), arbConfig, handles.iqtool, cNames);
if (~isempty(val))
    set(hObject, 'UserData', val);
    set(hObject, 'String', str);
end


function editClockFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editClockFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editClockFreq as text
%        str2double(get(hObject,'String')) returns contents of editClockFreq as a double


% --- Executes during object creation, after setting all properties.
function editClockFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editClockFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editTrigDivider_Callback(hObject, eventdata, handles)
% hObject    handle to editTrigDivider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTrigDivider as text
%        str2double(get(hObject,'String')) returns contents of editTrigDivider as a double


% --- Executes during object creation, after setting all properties.
function editTrigDivider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTrigDivider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobuttonChannel.
function radiobuttonChannel_Callback(hObject, eventdata, handles)
doChannelSetup(handles);
checkfields([], [], handles);


% --- Executes on button press in radiobuttonRefClk.
function radiobuttonRefClk_Callback(hObject, eventdata, handles)
doChannelSetup(handles);
checkfields([], [], handles);


% --- Executes on button press in radiobuttonNoClock.
function radiobuttonNoClock_Callback(hObject, eventdata, handles)
doChannelSetup(handles);
checkfields([], [], handles);


function doChannelSetup(handles)
arbConfig = loadArbConfig();
if (get(handles.radiobuttonCNRZ5, 'Value'))
    if (get(handles.radiobuttonChannel, 'Value'))
        cNames = {'Wire1', 'Wire2', 'Wire3', 'Wire4', 'Wire5', 'Wire6', 'Clock'};
    else
        cNames = {'Wire1', 'Wire2', 'Wire3', 'Wire4', 'Wire5', 'Wire6'};
    end
else  % ENRZ or DuoBinary
    if (get(handles.radiobuttonChannel, 'Value'))
        cNames = {'Wire1', 'Wire2', 'Wire3', 'Wire4', 'Clock'};
    else
        cNames = {'Wire1', 'Wire2', 'Wire3', 'Wire4'};
    end
end
set(handles.pushbuttonDownload, 'UserData', cNames);
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig, cNames);
