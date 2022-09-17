function varargout = iqfir(varargin)
% IQFIR MATLAB code for iqfir.fig
%      IQFIR, by itself, creates a new IQFIR or raises the existing
%      singleton*.
%
%      H = IQFIR returns the handle to a new IQFIR or the handle to
%      the existing singleton*.
%
%      IQFIR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQFIR.M with the given input arguments.
%
%      IQFIR('Property','Value',...) creates a new IQFIR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqfir_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqfir_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqfir

% Last Modified by GUIDE v2.5 09-Nov-2015 20:09:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqfir_OpeningFcn, ...
                   'gui_OutputFcn',  @iqfir_OutputFcn, ...
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


% --- Executes just before iqfir is made visible.
function iqfir_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqfir (see VARARGIN)

% Choose default command line output for iqfir
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
plotFilter(handles);
arbConfig = loadArbConfig();
switch (arbConfig.model)
    case {'M8195A_2ch' 'M8195A_2ch_mrk' 'M8195A_2ch_256k'}
        set(handles.radiobutton2, 'Value', 1);
        radiobutton2_Callback(handles.radiobutton2, [], handles);
    case {'M8195A_4ch'}
        set(handles.radiobutton4, 'Value', 1);
        radiobutton4_Callback(handles.radiobutton4, [], handles);
    otherwise
        set(handles.radiobutton1, 'Value', 1);
        radiobutton1_Callback(handles.radiobutton1, [], handles);
end
% f = iqopen();
% if (~isempty(f))
%     res = str2double(query(f, ':FREQ:RAST?'));
%     handles.fs = res;
%     % Update handles structure
%     guidata(hObject, handles);
%     fclose(f);
% end
handles.fs = 64e9;
guidata(hObject, handles);

set(handles.checkboxAutoDownload, 'Value', 1);

% UIWAIT makes iqfir wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqfir_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filt = plotFilter(handles);
downloadFilter(handles, filt);


function downloadFilter(handles, filt)
cmds = {'FRAT', 'HRAT', '', 'QRAT' };
channels = [get(handles.checkbox1, 'Value') get(handles.checkbox2, 'Value') get(handles.checkbox3, 'Value') get(handles.checkbox4, 'Value')]; 
f = iqopen();
if (isempty(f))
    set(handles.checkboxAutoDownload, 'Value', 0);
    return;
end
os = get(handles.radiobutton1, 'Value') + 2 * get(handles.radiobutton2, 'Value') + 4 * get(handles.radiobutton4, 'Value');
for ch = 1:4
    if (channels(ch))
        fprintf(f, [sprintf(':OUTP%d:FILT:%s %.9g', ch, cmds{os}, filt(1)) sprintf(',%.9g', filt(2:end))]);
    end
end
readClipping(f, handles);
fclose(f);


function readClipping(f, handles)
res = int16(str2double(query(f, ':STAT:QUES:VOLT:COND?')));
ch = '';
if (bitand(res, 16) ~= 0)
    ch = [ch '1, '];
end
if (bitand(res, 32) ~= 0)
    ch = [ch '2, '];
end
if (bitand(res, 64) ~= 0)
    ch = [ch '3, '];
end
if (bitand(res, 128) ~= 0)
    ch = [ch '4, '];
end
if (~strcmp(ch, ''))
    set(handles.editError, 'String', ['Clipping on channel(s): ' ch(1:end-2)]);
    set(handles.editError, 'Background', 'yellow');
else
    set(handles.editError, 'String', '');
    set(handles.editError, 'Background', 'white');
end


function filt = plotFilter(handles)
filt = calcFilter(handles);
xTime = [-length(filt)/2 length(filt)/2-1];
stem(handles.axesTime, linspace(xTime(1), xTime(2), length(filt)), filt, 'filled');
xlim(handles.axesTime, xTime);
ylim(handles.axesTime, [-1.1 1.1]);
grid(handles.axesTime, 'on');
title(handles.axesTime, 'FIR coefficients');
stem(handles.axesFreq, linspace(-0.5, (0.5-1/length(filt)), length(filt)), 23+20*log10(abs(fftshift(fft(filt/length(filt))))), 'filled', 'BaseValue', -200);
xlim(handles.axesFreq, [-0.5 0.5-1/length(filt)]);
%xlim(handles.axesFreq, [1 length(filt)]);
ylim(handles.axesFreq, [-70 10]);
grid(handles.axesFreq, 'on');
title(handles.axesFreq, 'FFT(FIR coefficients)');


function updateFilter(handles, hObject)
filt = plotFilter(handles);
if (get(handles.checkboxAutoDownload, 'Value'))
%     if (exist('hObject', 'var') && ~isempty(hObject))
%         set(hObject, 'Enable', 'off');
%         pause(0.001);
%     end
    downloadFilter(handles, filt);
%     if (exist('hObject', 'var') && ~isempty(hObject))
%         set(hObject, 'Enable', 'on');
%     end
end


function filt = calcFilter(handles)
os = get(handles.radiobutton1, 'Value') + 2 * get(handles.radiobutton2, 'Value') + 4 * get(handles.radiobutton4, 'Value');
filterTypeList = get(handles.popupmenuFilterType, 'String');
filterType = filterTypeList{get(handles.popupmenuFilterType, 'Value')};
filterParam = get(handles.sliderParam, 'Value');
delay = get(handles.sliderDelay, 'Value');
scale = get(handles.sliderScale, 'Value');
filt = calcFilter2(handles, os, filterType, filterParam, delay, scale/100);


function fNum = calcFilter2(handles, os, filterType, filterParam, delay, scale)
switch filterType
    case 'Rectangular'
        fNum = zeros(1,16);
        fNum(9) = 1;
        fNum = repmat(fNum,os,1);
        fNum = fNum(1:end)';
    case 'Raised Cosine'
        fdes = fdesign.pulseshaping(os, 'Raised Cosine', 'NSym,Beta', 16, filterParam);
        fstr = design(fdes);
        fNum = fstr.Numerator;
        m = max(abs(fNum));
        fNum = fNum / m;
    case 'Allpass'
        fNum = zeros(1,os*16);
        fNum(os*8+1) = 1;
        fNum = fNum(1:end)';
    case 'Gaussian'
        if (filterParam == 0)
            filterParam = 1e-6;
        end
        fdes = fdesign.pulseshaping(os, 'Gaussian', 'NSym,BT', 16, filterParam);
        fstr = design(fdes);
        fNum = fstr.Numerator;
        m = max(abs(fNum));
        fNum = fNum / m;
    case 'Linear'
        fNum = zeros(1,os*16);
        fNum(os*8+1) = 1;
        if (os == 2)
            fNum(os*8) = 0.5;
            fNum(os*8+2) = 0.5;
        elseif (os == 4)
            fNum(os*8) = 0.75;
            fNum(os*8-1) = 0.5;
            fNum(os*8-2) = 0.25;
            fNum(os*8+2) = 0.75;
            fNum(os*8+3) = 0.5;
            fNum(os*8+4) = 0.25;
        end
        fNum = fNum(1:end)';
    case 'Nyquist'
        if (os == 1)
            fNum = zeros(1,os*16);
            fNum(os*8+1) = 1;
            fNum = fNum(1:end)';
        else
            try
                b  = firnyquist(os*16, os, filterParam, 0, 'Normal');
                Hd = dfilt.dffir(b);
                fNum = Hd.Numerator(1:end-1);
                m = max(abs(fNum));
                fNum = fNum / m;
            catch ex
                errordlg(ex.message);
            end
        end
    case 'Lowpass'
        Fpass = 0.8; %filterParam;  % Passband Frequency
        Fstop = 1;    % Stopband Frequency
        Wpass = 1;    % Passband Weight
        Wstop = 1;    % Stopband Weight
        dens  = 16;   % Density Factor
        % Calculate the coefficients using the FIRPM function.
        b  = firpm(16*os, [0 Fpass Fstop 1], [1 1 0 0], [Wpass Wstop], {dens});
        Hd = dfilt.dffir(b);
        fNum = Hd.Numerator;
        m = max(abs(fNum));
        fNum = fNum / m;
    otherwise
        error(['unknown filter type [' filterType ']']);
end
len = os*16;
fNum = reshape(fNum, length(fNum), 1);
fNum = [fNum; zeros(len,1)];
fNum = fNum(1:len);
if (get(handles.checkboxApplyCorrections, 'Value'))
    fs = 64e9;
    xTime = fs * [-len/2 len/2-1];
    H = fftshift(fft(fNum/length(fNum)));
    [~, perChannelCorr] = iqcorrection([]);
    if (~isempty(perChannelCorr))
        freq = perChannelCorr(:,1);
        cplxCorr = perChannelCorr(:,2);
        if (max(freq) < fs/2)
            freq(end+1) = fs/2;
            cplxCorr(end+1) = cplxCorr(end);
        end
        if (min(freq) >= 0)    % if we don't have negative frequencies, mirror them
            if (freq(1) ~= 0)  % don't duplicate zero-frequency
                freq = [0; freq];
                cplxCorr = [0; cplxCorr];
            end
        end
        freq = [-1 * flipud(freq); freq(2:end)];
        cplxCorr = [conj(flipud(cplxCorr)); cplxCorr(2:end,:)]; % negative side must use complex conjugate

        %cplxCorr = smooth(cplxCorr, 100);
        %figure(10); plot(freq/1e9, [20*log10(abs(cplxCorr)) 20*log10(abs(cplxSmooth))], '.-');
        points = 16*os;
        newFreq = linspace(-0.5, 0.5-1/points, points) * fs;
        % interpolate the correction curve to match the data
        corrLin = interp1(freq, cplxCorr, newFreq, 'pchip', 1);
        %corrLin = fftshift(corrLin);
        % plot
        newH = H .* corrLin.';
        fNum = real((ifft(fftshift(newH))));
        fNum = fNum / max(abs(fNum));
        %figure(11); plot(newFreq/1e9, [20*log10(abs(fftshift(H))) 20*log10(abs(corrLin.')) 20*log10(abs(fftshift(newH)))], '.-');
        xlabel('Freq (GHz)');
        legend({'old', 'corr', 'new'});
    end
end
% scale and delay
fNum = fNum * scale;
fNum = iqdelay([zeros(len,1); fNum; zeros(len,1)], 1, delay);
fNum = fNum(len+1:2*len);


% --- Executes on selection change in popupmenuFilterType.
function popupmenuFilterType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuFilterType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filterTypeList = get(handles.popupmenuFilterType, 'String');
filterType = filterTypeList{get(handles.popupmenuFilterType, 'Value')};
switch strtrim(filterType)
    case 'Rectangular'
        set(handles.editParam, 'Enable', 'off');
        set(handles.sliderParam, 'Enable', 'off');
        set(handles.textFilterParam, 'String', 'Filter Parameter');
    case 'Raised Cosine'
        set(handles.editParam, 'Enable', 'on');
        set(handles.sliderParam, 'Enable', 'on');
        set(handles.textFilterParam, 'String', 'Alpha');
    case 'Gaussian'
        set(handles.editParam, 'Enable', 'on');
        set(handles.sliderParam, 'Enable', 'on');
        set(handles.textFilterParam, 'String', 'BT');
    case 'Linear'
        set(handles.editParam, 'Enable', 'off');
        set(handles.sliderParam, 'Enable', 'off');
        set(handles.textFilterParam, 'String', 'Filter Parameter');
    case 'Allpass'
        set(handles.editParam, 'Enable', 'off');
        set(handles.sliderParam, 'Enable', 'off');
        set(handles.textFilterParam, 'String', 'Filter Parameter');
    case 'Nyquist'
        set(handles.editParam, 'Enable', 'on');
        set(handles.sliderParam, 'Enable', 'on');
        set(handles.textFilterParam, 'String', 'Roll-off');
    case 'Lowpass'
        set(handles.editParam, 'Enable', 'on');
        set(handles.sliderParam, 'Enable', 'on');
        set(handles.textFilterParam, 'String', 'Cut-off');
    otherwise
        error(['unknown filter type ' filterType]);
end
updateFilter(handles, hObject);


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



function editParam_Callback(hObject, eventdata, handles)
% hObject    handle to editParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(handles.editParam, 'String'));
catch
end
if (~isempty(value))
    set(handles.sliderParam, 'Value', value);
    updateFilter(handles, hObject);
    set(handles.editParam, 'Background', 'white');
else
    set(handles.editParam, 'Background', 'red');
end


% --- Executes during object creation, after setting all properties.
function editParam_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.sliderDelay, 'Value', min(max(get(handles.sliderDelay, 'Value'), -5), 5));
set(handles.sliderDelay, 'Min', -5);
set(handles.sliderDelay, 'Max', 5);
sliderDelay_Callback(handles.sliderDelay, [], handles);
updateFilter(handles, hObject);


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.sliderDelay, 'Value', min(max(get(handles.sliderDelay, 'Value'), -10), 10));
set(handles.sliderDelay, 'Min', -10);
set(handles.sliderDelay, 'Max', 10);
sliderDelay_Callback(handles.sliderDelay, [], handles);
updateFilter(handles, hObject);


% --- Executes on button press in radiobutton4.
function radiobutton4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.sliderDelay, 'Min', -20);
set(handles.sliderDelay, 'Max', 20);
sliderDelay_Callback(handles.sliderDelay, [], handles);
updateFilter(handles, hObject);


% --- Executes on button press in checkboxAutoDownload.
function checkboxAutoDownload_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on slider movement.
function sliderParam_Callback(hObject, eventdata, handles)
% hObject    handle to sliderParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(handles.sliderParam, 'Value');
set(handles.editParam, 'String', sprintf('%.2f', value));
set(handles.editParam, 'Background', 'white');
updateFilter(handles, hObject);


% --- Executes during object creation, after setting all properties.
function sliderParam_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editDelay_Callback(hObject, eventdata, handles)
% hObject    handle to editDelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(handles.editDelay, 'String'));
catch
end
if (~isempty(value) && isscalar(value) && isreal(value) && value >= get(handles.sliderDelay, 'Min') && value <= get(handles.sliderDelay, 'Max'))
    set(handles.sliderDelay, 'Value', value);
    updateFilter(handles, hObject);
    set(handles.editDelay, 'Background', 'white');
    try
        fs = handles.fs;
        value = value / fs * 1e12;
        set(handles.editDelayTime, 'String', sprintf('%.2f', value));
        set(handles.editDelayTime, 'Background', 'white');
    catch
    end
else
    set(handles.editDelay, 'Background', 'red');
end


% --- Executes during object creation, after setting all properties.
function editDelay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editDelayTime_Callback(hObject, eventdata, handles)
% hObject    handle to editDelayTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(handles.editDelayTime, 'String'));
catch
end
try
    fs = handles.fs;
    value = value / 1e12 * fs;
    if (~isempty(value) && isscalar(value) && isreal(value) && ...
            value >= get(handles.sliderDelay, 'Min') && value <= get(handles.sliderDelay, 'Max'))
        set(handles.sliderDelay, 'Value', value);
        set(handles.editDelay, 'String', sprintf('%.2f', value)); 
        updateFilter(handles, hObject);
        set(handles.editDelayTime, 'Background', 'white');
    else
        set(handles.editDelayTime, 'Background', 'red');
    end
catch
end


% --- Executes during object creation, after setting all properties.
function editDelayTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDelayTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderDelay_Callback(hObject, eventdata, handles)
% hObject    handle to sliderDelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(handles.sliderDelay, 'Value');
set(handles.editDelay, 'String', sprintf('%.2f', value));
set(handles.editDelay, 'Background', 'white');
try
    fs = handles.fs;
    value = value / fs * 1e12;
    set(handles.editDelayTime, 'String', sprintf('%.2f', value));
    set(handles.editDelayTime, 'Background', 'white');
catch
end
updateFilter(handles, hObject);


% --- Executes during object creation, after setting all properties.
function sliderDelay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderDelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editScale_Callback(hObject, eventdata, handles)
% hObject    handle to editScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', get(handles.editScale, 'String'));
catch
end
if (~isempty(value) && isscalar(value) && isreal(value) && value >= get(handles.sliderScale, 'Min') && value <= get(handles.sliderScale, 'Max'))
    set(handles.sliderScale, 'Value', value);
    updateFilter(handles, hObject);
    set(handles.editScale, 'Background', 'white');
else
    set(handles.editScale, 'Background', 'red');
end


% --- Executes during object creation, after setting all properties.
function editScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderScale_Callback(hObject, eventdata, handles)
% hObject    handle to sliderScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(handles.sliderScale, 'Value');
set(handles.editScale, 'String', sprintf('%g', value));
set(handles.editScale, 'Background', 'white');
updateFilter(handles, hObject);


% --- Executes during object creation, after setting all properties.
function sliderScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in checkboxAutoScale.
function checkboxAutoScale_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAutoScale



function editError_Callback(hObject, eventdata, handles)
% hObject    handle to editError (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editError as text
%        str2double(get(hObject,'String')) returns contents of editError as a double


% --- Executes during object creation, after setting all properties.
function editError_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editError (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonClearClipping.
function pushbuttonClearClipping_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClearClipping (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
f = iqopen();
fprintf(f, ':ABOR');
fprintf(f, ':INIT:IMM');
pause(1.5);
readClipping(f, handles);
fclose(f);


% --- Executes on button press in pushbuttonAutoScale.
function pushbuttonAutoScale_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAutoScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkboxApplyCorrections.
function checkboxApplyCorrections_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxApplyCorrections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plotFilter(handles);
