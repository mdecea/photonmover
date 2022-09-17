function varargout = iqcorrmgmt(varargin)
% IQTOOL MATLAB code for iqtool.fig
%      IQTOOL, by itself, creates a new IQTOOL or raises the existing
%      singleton*.
%
%      H = IQTOOL returns the handle to a new IQTOOL or the handle to
%      the existing singleton*.
%
%      IQTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQTOOL.M with the given input arguments.
%
%      IQTOOL('Property','Value',...) creates a new IQTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqcorrmgmt_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqcorrmgmt_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqtool

% Last Modified by GUIDE v2.5 08-Sep-2017 00:56:19
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqcorrmgmt_OpeningFcn, ...
                   'gui_OutputFcn',  @iqcorrmgmt_OutputFcn, ...
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


% --- Executes just before iqtool is made visible.
function iqcorrmgmt_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqtool (see VARARGIN)

% Choose default command line output for iqtool
handles.output = hObject;

handles.posWindow = get(handles.iqtool, 'Position');
handles.posCplx = get(handles.uipanelCplx, 'Position');
handles.posSParam = get(handles.uipanelSParam, 'Position');
handles.posReadAWGCal = get(handles.pushbuttonReadAWGCal, 'Position');
handles.posMTCal = get(handles.pushbuttonMTCal, 'Position');
handles.posImportPerChannel = get(handles.pushbuttonImportPerChannel, 'Position');
handles.posExportPerChannel = get(handles.pushbuttonExportPerChannel, 'Position');
handles.posClearPerChannelCorr = get(handles.pushbuttonClearPerChannelCorr, 'Position');
handles.postextCutoff = get(handles.textCutoff, 'Position');
handles.poseditSParamCutoff = get(handles.editSParamCutoff, 'Position');
handles.postextSmooth = get(handles.textSmooth, 'Position');
handles.poseditSmooth = get(handles.editSmooth, 'Position');
handles.poscheckboxAbsMagnitude = get(handles.checkboxAbsMagnitude, 'Position');
handles.postextAbsMagnitude = get(handles.textAbsMagnitude, 'Position');
handles.poseditAbsMagnitude = get(handles.editAbsMagnitude, 'Position');
handles.postextDisplay = get(handles.textDisplay, 'Position');
handles.poscheckboxMagnitude = get(handles.checkboxMagnitude, 'Position');
handles.poscheckboxPhase = get(handles.checkboxPhase, 'Position');
handles.posaxes1 = get(handles.axes1, 'Position');
handles.posaxes2 = get(handles.axes2, 'Position');

%Set handles to generation first
set(handles.sliderSPar, 'Value',0);
set(handles.sliderIF, 'Value',0);
set(handles.textIFDescriptor, 'String', 'Filename');
set(handles.textSPar, 'String', 'Generation');
set(handles.textIF, 'String', 'Generation');
set(handles.popupmenuIFNumber, 'Visible', 'off');
set(handles.editFilename, 'Visible', 'on');
set(handles.pushbuttonExportComplex, 'Enable', 'on');

% Update handles structure
guidata(hObject, handles);

% update GUI
popupmenuSParamNum_Callback([], [], handles);
try
    ampCorrFile = iqampCorrFilename();
    acs = load(ampCorrFile);
    if (isfield(acs, 'sparamRemoveSkew'))
        set(handles.checkboxRemoveSkew, 'Value', acs.sparamRemoveSkew);
    end
    if (isfield(acs, 'sparamWeight'))
        set(handles.editWeight, 'String', sprintf('%g', acs.sparamWeight));
    end
    if (isfield(acs, 'smoothing'))
        set(handles.editSmooth, 'String', sprintf('%d', acs.smoothing));
    end
    if (isfield(acs, 'absMagnitude'))
        set(handles.editAbsMagnitude, 'String', sprintf('%g', acs.absMagnitude));
        set(handles.checkboxAbsMagnitude, 'Value', 1);
    else
        set(handles.checkboxAbsMagnitude, 'Value', 0);
    end
    checkboxAbsMagnitude_Callback([], [], handles);
catch
end
% UIWAIT makes iqtool wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqcorrmgmt_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonClose.
function pushbuttonClose_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close();


function editFilename_Callback(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFilename as text
%        str2double(get(hObject,'String')) returns contents of editFilename as a double


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


% --- Executes on button press in pushbuttonImportComplex.
function pushbuttonImportComplex_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonImportComplex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% process the following types of files:
%  .csv  VSA exported trace
%  .mat  VSA exported trace
%  .mat  M8195A Calibration file
%
[filename, pathname, filterindex] = uigetfile({ ...
    '*.mat', 'MATLAB file'; ...
    '*.csv', 'CSV file (VSA style)'; ...
    '*.csv', 'CSV file (Signal Optimizer)'; ...
    });
if (filename ~= 0)
    hMsgbox = msgbox('Importing file...', 'Importing file...', 'replace');
    try
        switch (filterindex)
            case 2  % CSV, VSA style
                % VSA equalizer trace file with header
                % expect to get values for XStart, XDelta and Y
                f = fopen(fullfile(pathname, filename), 'r');
                a = fgetl(f);
                cnt = 0;
                clear Y;
                XStart = 0;
                XDelta = 0;
                while (a ~= -1)
%                    fprintf('%s\n', a);
                    % process pairs
                    if (cnt > 0)
                        [val, readCnt] = sscanf(a, '%g,%g'); % US style
                        if (readCnt < 2)
                            [val, readCnt] = sscanf(regexprep(a, ',', '.'), '%g;%g'); % German style
                            if (readCnt < 2)
                                errordlg({'unexpected number format in CSV file: ' a});
                                return;
                            end
                        end
                        Y(cnt,1) = complex(val(1), val(2));
                        cnt = cnt + 1;
                    else
                        [tok, remain] = strtok(a, ',;');
                        switch (tok)
                            case 'Y'
                                cnt = 1;
                            case 'XDelta'
                                XDelta = sscanf(regexprep(remain(2:end), ',', '.'), '%g');
                            case 'XStart'
                                XStart = sscanf(regexprep(remain(2:end), ',', '.'), '%g');
                        end
                    end
                    a = fgetl(f);
                end
                fclose(f);
                numPts = cnt - 1;
                % frequency vector
                freq = linspace(XStart, XStart + (numPts - 1) * XDelta, numPts);
                % allow frequency shift
                result = inputdlg('Shift Frequency (use negative values to shift from RF to baseband)', 'Shift Frequency', 1, {'0'});
                if (~isempty(result))
                    freq = freq + eval(result{1});

                    %Load to instrument correction or VSA
                    iFMenuState = get(handles.sliderIF, 'Value');

                    switch iFMenuState
                        case 0 %IQ Precorrection
                            updateAmpCorr(handles, freq, Y);


                        case 1 %VSA Correction
                            %Get the channel
                            correctionChannel = round(get(handles.popupmenuIFNumber, 'Value'));

                            %Get the correction
                            cplxCorr = updateAmpCorrVSALoad(handles, freq, Y);

                            %Load it to VSA
                            loadToVSA(correctionChannel, 'IF', 1, cplxCorr);
                    end
                end
            case 1
                % process .MAT file - could be either VSA equalizer trace or
                % M8195A calibration file
                eq = load(strcat(pathname, filename));
                if (isfield(eq, 'Cal')) % M8195A Calibration file
                    % ask user to select a channel
                    result = inputdlg('Please select a channel', 'Please select a channel', 1, {'1'});
                    if (~isempty(result))
                        ch = eval(result{1});
                        freq = 1e9 * eq.Cal.Frequency_MT;
                        amp = 10 .^ (eq.Cal.AmplitudeResponse_MT(:,ch) / 20);
                        filler = zeros(size(eq.Cal.AmplitudeResponse_MT, 1) - size(eq.Cal.AbsPhaseResponse_MT, 1), 1);
                        phi = [filler; eq.Cal.AbsPhaseResponse_MT(:,ch)] * pi / 180;                    

                        %Load to instrument correction or VSA
                        iFMenuState = get(handles.sliderIF, 'Value');

                        switch iFMenuState
                            case 0 %IQ Precorrection
                                updateAmpCorr(handles, freq, amp .* exp(j * phi));


                            case 1 %VSA Correction
                                %Get the channel
                                correctionChannel = round(get(handles.popupmenuIFNumber, 'Value'));

                                %Get the correction
                                cplxCorr = updateAmpCorrVSALoad(handles, freq, amp .* exp(j * phi));

                                %Load it to VSA
                                loadToVSA(correctionChannel, 'IF', 1, cplxCorr);
                        end
                    end
                elseif (isfield(eq,'ampCorr'))  % Load an ampcorr file directly
                    try
                        copyfile(strcat(pathname, filename), iqampCorrFilename());
                        updateAxes(handles);
                    catch ex
                        errordlg(['Could not load correction file: ' ex.message]);
                    end
                elseif (~isfield(eq, 'Y') || ~isfield(eq, 'XStart') || ~isfield(eq, 'XDelta')) % VSA trace file
                    errordlg('Invalid correction file format. Expected variables "Y", "XStart" and "XDelta" in the file');
                else
                    %Load to instrument correction or VSA
                        iFMenuState = get(handles.sliderIF, 'Value');

                        switch iFMenuState
                            case 0 %IQ Precorrection
                                loadVSAcorr(handles, eq, @updateAmpCorr);


                            case 1 %VSA Correction
                                %Get the channel
                                correctionChannel = round(get(handles.popupmenuIFNumber, 'Value'));

                                %Get the correction
                                cplxCorr = loadVSAcorrVSALoad(handles, eq, @updateAmpCorrVSALoad);

                                %Load it to VSA
                                loadToVSA(correctionChannel, 'IF', 1, cplxCorr);
                        end
                end
            case 3 % CSV Signal Optimizer style
                a = csvread(fullfile(pathname, filename));
                % first emtry is sample rate (in Hz)
                fs = a(1,1);
                % second line is quadrature error correction (in degrees)
                qe = a(2,1);
                a = a(3:end, :);
                % remaining rows are impulse responses of G and H filters
                gfilt = flipud(complex(a(:,1), a(:,2)));
                hfilt = flipud(complex(a(:,3), a(:,4)));
                % make sure it is even length
                if (mod(length(hfilt), 2) ~= 0)
                    hfilt = [0; hfilt];
                    gfilt = [0; gfilt];
                end
                % avoid divide by zero errors
                gfilt(gfilt == 0) = 1e-9;
                hfilt(hfilt == 0) = 1e-9;
                % in the Signal Optimizer code, the signal is shifted
                % here, I shift the filter instead
                gfilt = circshift(gfilt,1);
                % internally, we store the correction in frequency domain
                % 1 ./ x to convert from response to correction
                Y = 1./fftshift(fft(fftshift(hfilt)));
                G = 1./fftshift(fft(fftshift(gfilt)));
                len = length(Y);
                % frequency vector
                freq = (-len/2:len/2-1)'/len*fs;
                % ask, if linear phase should be removed
%                 res = questdlg('Remove linear phase?', 'Remove linear phase?', 'Yes', 'No', 'Cancel', 'No');
%                 if (~isempty(res))
%                     if (strcmp(res, 'Yes'))
%                         % remove phase of H filter.  Phase of G filter must
%                         % be retained - it is used to generate delay
%                         ph = unwrap(angle(Y));
%                         i1 = round(len/2+1);      % just look at the positive side
%                         i2 = round(3*len/4);
%                         pf = polyfit(freq(i1:i2), ph(i1:i2), 1);
%                         linph = polyval(pf, freq);
%                         Y = abs(Y) .* exp(1i * (ph - linph));
%                     end

                    % the 'G' filter is applied to Q only, so we need to
                    % know the AWG channels the user wants to use
                    defaultVal = {'1 2'};
                    res = inputdlg('Select the AWG channels that are used to generate the I resp. Q signal', 'Select AWG channel assignment', 1, defaultVal);
                    if (isempty(res))
                        return;
                    end
                    AWGChannels = sscanf(res{1}, '%d', inf);
                    if (length(AWGChannels) ~= 2)
                        errordlg('Error: Expected 2 channel numbers');
                        return
                    end
                    res = inputdlg('Enter the center frequency for this correction (use 0 for IQ BB)', 'Enter center frequency', 1, {'0'});
                    if (isempty(res))
                        return;
                    end
                    fc = sscanf(res{1}, '%g');
                    freq = freq + fc;
                    perChCorr = [ones(len,1), G];
                    % save only the positive frequencies for G filter
                    freq2 = freq(freq>=0);
                    perChCorr2 = perChCorr((freq>=0),:);
                    
                    % Load to instrument correction or VSA
                    iFMenuState = get(handles.sliderIF, 'Value');

                    switch iFMenuState
                        case 0 %IQ Precorrection
                            % clear the file
                            ampCorrFile = iqampCorrFilename();
                            acs = struct();
                            save(ampCorrFile, '-struct', 'acs');
                            updateAmpCorr(handles, freq, Y);
                            updatePerChannelCorr(handles, freq2, perChCorr2, AWGChannels);
                        case 1 %VSA Correction
                            %Get the channel
                            correctionChannel = round(get(handles.popupmenuIFNumber, 'Value'));
                            %Get the correction
                            cplxCorr = updateAmpCorrVSALoad(handles, freq, Y);
                            %Load it to VSA
                            loadToVSA(correctionChannel, 'IF', 1, cplxCorr);
                    end
%             end
        end
    catch ex
        errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    end
    try
        close(hMsgbox);
    catch
    end
end


function loadVSAcorr(handles, eq, updateFct)
cancel = 0;
if (isfield(eq, 'InputCenter') && eq.InputCenter ~= 0)
    res = questdlg(sprintf('The equalizer data in this file is centered at %s Hz.\nDo you want to shift the data to baseband?', iqengprintf(eq.InputCenter)));
    switch (res)
        case 'Yes'; eq.XStart = eq.XStart - eq.InputCenter; eq.InputCenter = 0;
        case 'Cancel'; cancel = 1;
    end
end
% ask for frequency shift
%                 if (eq.InputCenter ~= 0)
%                     result = inputdlg('Shift Frequency (use negative values to shift from RF to baseband)', 'Shift Frequency', 1, {'0'});
%                     if (isempty(result))
%                         cancel = 1;
%                     else
%                         eq.XStart = eq.XStart + eval(result{1});
%                     end
%                 end
if (~cancel)
    % calculate frequency vector
    freq = linspace(eq.XStart, eq.XStart + (length(eq.Y) - 1) * eq.XDelta, length(eq.Y));
    % update ampCorr file
    updateFct(handles, freq, eq.Y);
end


function updateAmpCorr(handles, freq, Y)
% VSA seems to sometimes return multiple columns with the same value...
if (size(Y,1) > 1 && size(Y,2) > 1)
    Y = Y(:,1);
end
% calculate response in dB
Ydb = 20*log10(abs(Y));
% set up ampCorr structure
clear ampCorr;
ampCorr(:,1) = freq(1:end);
ampCorr(:,2) = -Ydb;
ampCorr(:,3) = 1 ./ Y;
% get the filename
ampCorrFile = iqampCorrFilename();
clear acs;
% try to load ampCorr file - be graceful if it does not exist
try
    acs = load(ampCorrFile);
catch
end
acs.ampCorr = ampCorr;
% and save
save(ampCorrFile, '-struct', 'acs');
updateAxes(handles);


function updatePerChannelCorr(handles, freq, Y, AWGChannels)
% set up perChannelCorr structure
clear perChannelCorr;
perChannelCorr(:,1) = freq(1:end);
perChannelCorr(:,2:size(Y,2)+1) = 1 ./ Y;
% get new AWG channel assignment if desired
if (~exist('AWGChannels', 'var') || isempty(AWGChannels))
    defaultVal = {strtrim(sprintf('%d ', (1:(size(perChannelCorr,2)-1))))};
    found = 0;
    while (~found)
        result = inputdlg('Select AWG channel(s) to assign this correction to', 'Select AWG channel assignment', 1, defaultVal);
        if (isempty(result))
            return;
        end
        result = result{1};         % result is returned as a cell array of length 1
        AWGChannels = sscanf(result, '%d', inf);
        if (isempty(result))
            % empty string means no channel assignment (use legacy mode)
            AWGChannels = [];
            found = 1;
        elseif (length(AWGChannels) == size(perChannelCorr,2) - 1)
            found = 1;
        else
            hMsgBox = errordlg(sprintf('expected %d channel numbers or an empty input', size(perChannelCorr,2)-1));
            pause(2);
            try close(hMsgBox); catch; end
        end
    end
end
written = checkMergeOverwrite(perChannelCorr, AWGChannels, 0);
if (written)
    updateAxes(handles);
end


function written = checkMergeOverwrite(perChannelCorr, AWGChannels, alwaysAsk)
% NOTE: same function as in iqmtcal_gui.m
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
                res = inputdlg('Select AWG channel(s) merge', 'Select AWG channel(s) to merge', 1, defaultVal);
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


% --- Executes on button press in pushbuttonExportComplex.
function pushbuttonExportComplex_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonExportComplex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    corrfilename = iqampCorrFilename();
catch
    errordlg('No correction file available yet');
    return;
end
try
    load(corrfilename);
    size(ampCorr,2);
catch
    errordlg('No complex corrections available');
    return;
end
[filename, pathname, filterindex] = uiputfile({...
    '.mat', 'MATLAB file (*.mat)'; ...
    '.csv', 'CSV file (*.csv)'}, ...
    'Save Frequency Response As...');
if (filename ~= 0)
    try
        if (size(ampCorr,2) <= 2)  % no complex correction available
            ampCorr(:,3) = 10.^(ampCorr(:,2)/20);
        end
        % store frequency response = inverse correction
        Y = 1 ./ ampCorr(:,3);
        switch (filterindex)
            case 1
                XStart = ampCorr(1,1);
                XDelta = ampCorr(2,1) - ampCorr(1,1);
                save(strcat(pathname, filename), 'XStart', 'XDelta', 'Y');
            case 2
                f = fopen(strcat(pathname, filename), 'w');
                fprintf(f, sprintf('XStart;%g\n', ampCorr(1,1)));
                fprintf(f, sprintf('XDelta;%g\n', ampCorr(2,1) - ampCorr(1,1)));
                fprintf(f, sprintf('Y\n'));
                for i=1:size(ampCorr,1)
                    fprintf(f, sprintf('%g;%g\n', real(Y(i)), imag(Y(i))));
                end
                fclose(f);
        end
    catch ex
        errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    end
end


function updateAxes(handles)
% read the correction file and update the two axes as well as the "cut off"
% and "smoothing" fields according to the data in the file
try
    [ampCorr, perChannelCorr, acs] = iqcorrection([]);
    % update popupmenuStdMode 
    if (isfield(acs, 'ampCorrMode'))
        ampCorrMode = acs.ampCorrMode;
    else
        ampCorrMode = -1;   % old style: de-embed
    end
    idx = [1 3 2];
    set(handles.popupmenuStdMode, 'Value', idx(ampCorrMode+2));
    % check if we use an S-Parameter file and update editSParamFile
    % accordingly
    spNum = get(handles.popupmenuSParamNum, 'Value');
    if (isfield(acs, 'sparamFile') && (~iscell(acs.sparamFile) || iscell(acs.sparamFile) && spNum <= size(acs.sparamFile, 2)))
        if (iscell(acs.sparamFile))
            spFile = acs.sparamFile{spNum};
        elseif ischar(acs.sparamFile)
            spFile = acs.sparamFile;    % old style - only one filename
        else
            spFile = [];
        end
        if (~isempty(spFile))
            [~, name, ext] = fileparts(spFile);
            set(handles.editSParamFile, 'String', strcat(name, ext));
        else
            set(handles.editSParamFile, 'String', '');
        end
        if (isfield(acs, 'sparamMode'))
            sparamMode = acs.sparamMode;
        else
            sparamMode = -1;    % old style - de-embedding
        end
    else
        set(handles.editSParamFile, 'String', '');
        sparamMode = 0;
    end
    idx = [1 3 2];
    set(handles.popupmenuSParamMode, 'Value', idx(sparamMode + 2));
    % update editSParamCutoff
    if (isfield(acs, 'sparamCutoff'))
        cutoff = acs.sparamCutoff;
        set(handles.editSParamCutoff, 'String', iqengprintf(cutoff));
    else
        set(handles.editSParamCutoff, 'String', '');
    end
    % update smoothing
    if (isfield(acs, 'smoothing') && isreal(acs.smoothing))
        set(handles.editSmooth, 'String', sprintf('%d', acs.smoothing));
    else
        set(handles.editSmooth, 'String', '0');
    end
    
    %----- update complex correction axes
    if (isempty(ampCorr))
        ampCorr = [0 0 1; 1e9 0 1];
    end
    phase = -1 * 180 / pi * unwrap(angle(ampCorr(:,3)));
    % if phase is *very* small, plot it as zero to avoid confusion...
    if (max(abs(phase)) < 1e-10)
        phase = zeros(size(phase));
    end
    showMag = get(handles.checkboxMagnitude, 'Value');
    showPhase = get(handles.checkboxPhase, 'Value');
    axes(handles.axes1);
    if (~showPhase)
        plot(ampCorr(:,1)/1e9, -1*ampCorr(:,2), 'LineWidth', 2);
        legend({'Magnitude'});
        ylabel('Loss (dB)');
    elseif (~showMag)
        plot(ampCorr(:,1)/1e9, phase, 'LineWidth', 2);
        legend({'Phase'});
        ylabel('Phase (degrees)');
    else
        func1 = @(x,y) plot(x,y,'Linewidth',2);
        [ax, ~, ~] = plotyy(ampCorr(:,1)/1e9, -1*ampCorr(:,2), ampCorr(:,1)/1e9, phase, func1);
        legend({'Magnitude', 'Phase'});
        xlabel('Frequency (GHz)');
        ylabel('Loss (dB)');
        axes(ax(2));
        ylabel('Phase (degrees)');
    end
    xlabel('Frequency (GHz)');
    title = get(gca(), 'Title');
    set(title, 'String', 'Complex Frequency/Phase Response');
    set(title, 'FontWeight', 'bold');
    grid on;
    
    %----- update per channel axes
    axes(handles.axes2);
    if (isempty(perChannelCorr))
        perChannelCorr = [0 1; 1e9 1];
    end
    y1 = -20.*log10(abs(perChannelCorr(:,2:end)));
    y2 = -180 / pi * unwrap(angle(perChannelCorr(:,2:end)));
    if (~showPhase)
        plot(perChannelCorr(:,1)/1e9, y1, 'Linewidth', 2);
        if (isfield(acs, 'AWGChannels') && ~isempty(acs.AWGChannels))
            switch (size(perChannelCorr,2))
                case 2; legend({sprintf('Magn./Ch%d', acs.AWGChannels(1))});
                case 3; legend({sprintf('Magn./Ch%d', acs.AWGChannels(1)) sprintf('Magn./Ch%d', acs.AWGChannels(2))});
                case 4; legend({sprintf('Magn./Ch%d', acs.AWGChannels(1)) sprintf('Magn./Ch%d', acs.AWGChannels(2)) sprintf('Magn./Ch%d', acs.AWGChannels(3))});
                case 5; legend({sprintf('Magn./Ch%d', acs.AWGChannels(1)) sprintf('Magn./Ch%d', acs.AWGChannels(2)) sprintf('Magn./Ch%d', acs.AWGChannels(3)) sprintf('Magn./Ch%d', acs.AWGChannels(4))});
            end
        else
            switch (size(perChannelCorr,2))
                case 2; legend({'Magnitude'});
                case 3; legend({'Magn./I' 'Magn./Q'});
                case 4; legend({'Magn./I' 'Magn./Q' 'Magn./3rd'});
                case 5; legend({'Magn./I' 'Magn./Q' 'Magn./3rd' 'Magn./4th'});
            end
        end
        ylabel('Loss (dB)');
    elseif (~showMag)
        plot(perChannelCorr(:,1)/1e9, y2, 'Linewidth', 2);
        if (isfield(acs, 'AWGChannels') &&  ~isempty(acs.AWGChannels))
            switch (size(perChannelCorr,2))
                case 2; legend({sprintf('Phase/Ch%d', acs.AWGChannels(1))});
                case 3; legend({sprintf('Phase/Ch%d', acs.AWGChannels(1)) sprintf('Phase/Ch%d', acs.AWGChannels(2))});
                case 4; legend({sprintf('Phase/Ch%d', acs.AWGChannels(1)) sprintf('Phase/Ch%d', acs.AWGChannels(2)) sprintf('Phase/Ch%d', acs.AWGChannels(3))});
                case 5; legend({sprintf('Phase/Ch%d', acs.AWGChannels(1)) sprintf('Phase/Ch%d', acs.AWGChannels(2)) sprintf('Phase/Ch%d', acs.AWGChannels(3)) sprintf('Phase/Ch%d', acs.AWGChannels(4))});
            end
        else
            switch (size(perChannelCorr,2))
                case 2; legend({'Phase'});
                case 3; legend({'Phase/I' 'Phase/Q'});
                case 4; legend({'Phase/I' 'Phase/Q' 'Phase/3rd'});
                case 5; legend({'Phase/I' 'Phase/Q' 'Phase/3rd' 'Phase/4th'});
            end
        end
        ylabel('Phase (degrees)');
    else
        func1 = @(x,y) plot(x,y,'Linewidth',2);
        [ax, ~, ~] = plotyy(perChannelCorr(:,1)/1e9, y1, perChannelCorr(:,1)/1e9, y2, func1);
        if (isfield(acs, 'AWGChannels') &&  ~isempty(acs.AWGChannels))
            switch (size(perChannelCorr,2))
                case 2; legend({sprintf('Magn./Ch%d', acs.AWGChannels(1)) sprintf('Phase/Ch%d', acs.AWGChannels(1))});
                case 3; legend({sprintf('Magn./Ch%d', acs.AWGChannels(1)) sprintf('Magn./Ch%d', acs.AWGChannels(2)) sprintf('Phase/Ch%d', acs.AWGChannels(1)) sprintf('Phase/Ch%d', acs.AWGChannels(2))});
                case 4; legend({sprintf('Magn./Ch%d', acs.AWGChannels(1)) sprintf('Magn./Ch%d', acs.AWGChannels(2)) sprintf('Magn./Ch%d', acs.AWGChannels(3)) sprintf('Phase/Ch%d', acs.AWGChannels(1)) sprintf('Phase/Ch%d', acs.AWGChannels(2)) sprintf('Phase/Ch%d', acs.AWGChannels(3))});
                case 5; legend({sprintf('Magn./Ch%d', acs.AWGChannels(1)) sprintf('Magn./Ch%d', acs.AWGChannels(2)) sprintf('Magn./Ch%d', acs.AWGChannels(3)) sprintf('Magn./Ch%d', acs.AWGChannels(4)) sprintf('Phase/Ch%d', acs.AWGChannels(1)) sprintf('Phase/Ch%d', acs.AWGChannels(2)) sprintf('Phase/Ch%d', acs.AWGChannels(3)) sprintf('Phase/Ch%d', acs.AWGChannels(4))});
            end
        else
            switch (size(perChannelCorr,2))
                case 2; legend({'Magnitude' 'Phase'});
                case 3; legend({'Magn./I' 'Magn./Q' 'Phase/I' 'Phase/Q'});
                case 4; legend({'Magn./I' 'Magn./Q' 'Magn./3rd' 'Phase/I' 'Phase/Q' 'Phase/3rd'});
                case 5; legend({'Magn./I' 'Magn./Q' 'Magn./3rd' 'Magn./4th' 'Phase/I' 'Phase/Q' 'Phase/3rd' 'Phase/4th'});
            end
        end
        xlabel('Frequency (GHz)');
        ylabel('Loss (dB)');
        axes(ax(2));
        ylabel('Phase (degrees)');
    end
    xlabel('Frequency (GHz)');
    title = get(gca(), 'Title');
    set(title, 'String', 'Per Channel Frequency/Phase Response');
    set(title, 'FontWeight', 'bold');
    grid on;
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end



% --- Executes on button press in pushbuttonDisplaySum.
function pushbuttonDisplaySum_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplaySum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonDisplaySParam.
function pushbuttonDisplaySParam_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplaySParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenuSParamMode.
function popupmenuSParamMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSParamMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSParamMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSParamMode
val = get(handles.popupmenuSParamMode, 'Value');
idx = [-1 1 0];  % de-embed, embed, do nothing

%Menu state of S-Parameters
sPMenuState = get(handles.sliderSPar, 'Value');

switch sPMenuState
    case 0 %Precorrect waveform
        ampCorrFile = iqampCorrFilename();
        acs = load(ampCorrFile);
        acs.sparamMode = idx(val);
        save(ampCorrFile, '-struct', 'acs');
        updateAxes(handles);
        
    case 1 %Correct VSA
        %Get the file name, if it is not valid, prompt for it
        fileName = get(handles.editSParamFile, 'String');
        try
            if(~isempty(fileName) && isempty(strfind(fileName, 'ampCorr.mat')));
                %Get the channel
                correctionChannel = round(get(handles.popupmenuSParamNum, 'Value'));

                %Get the correction
                cplxCorr = readSParamFile(handles);
                %Load it to VSA
                loadToVSA(correctionChannel, 'RF', 1, cplxCorr);
            else
                pushbuttonLoadSParamFile_Callback(hObject, eventdata, handles);
            end
        catch ex
            msgbox(ex.message);            
        end        
end


% --- Executes during object creation, after setting all properties.
function popupmenuSParamMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSParamMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSParamFile_Callback(hObject, eventdata, handles)
% hObject    handle to editSParamFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSParamFile as text
%        str2double(get(hObject,'String')) returns contents of editSParamFile as a double
msgbox('Please use the "..." button to select a file');



% --- Executes during object creation, after setting all properties.
function editSParamFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSParamFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonLoadSParamFile.
function pushbuttonLoadSParamFile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonLoadSParamFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    ampCorrFile = iqampCorrFilename();
    try
        acs = load(ampCorrFile);
    catch
    end
    % change to the directory where the previous S-parameter file was located
    spNum = get(handles.popupmenuSParamNum, 'Value');
    if (exist('acs', 'var') && ...
          (isfield(acs, 'sparamFile') && (~iscell(acs.sparamFile) || ...
          iscell(acs.sparamFile) && spNum <= size(acs.sparamFile, 2))))
        if (iscell(acs.sparamFile))
            spFile = acs.sparamFile{spNum};
        else
            spFile = acs.sparamFile;
        end
        oldWD = cd();
        try
            [path file ext] = fileparts(spFile);
            cd(path);
        catch   % if the directory does not exist, simply ignore the error
        end
    else
        oldWD = [];
    end
    % get the filename
    [filename pathname] = uigetfile('*.s2p;*.s4p;*.s6p');
    % and change dir back to where we were before
    if (~isempty(oldWD))
        cd(oldWD);
    end
    if (filename ~= 0)
        try
            % check if the file can be read
            [rows, cols] = setupSelectedSParam(handles, strcat(pathname, filename));
            % select a default SParameter: S21, S31, S21 for 2/4/6 port file
            if (rows ~= 0)
                defVal = [1 1; 2 1; 2 1; 2 1; 2 1; 2 1];
                set(handles.popupmenuSParamSelect, 'Value', (defVal(rows,1)-1)*cols + defVal(rows,2));
                
                %Menu state of S-Parameters
                sPMenuState = get(handles.sliderSPar, 'Value');

                switch sPMenuState
                    case 0 %Precorrect waveform                
                        acs.selectedSParam(spNum, :) = [defVal(rows,1) defVal(rows,2)];
                        acs.sparamFile{spNum} = strcat(pathname, filename);

                        % if it was unused, set to de-embed to avoid confusion
                        if (~isfield(acs, 'sparamMode') || acs.sparamMode == 0)
                            acs.sparamMode = -1;
                        end
                        save(ampCorrFile, '-struct', 'acs');
                        updateAxes(handles);

                    case 1 %Load to VSA
                        %Get the pathname
                        handles.VSAPathname = pathname;
                        set(handles.editSParamFile, 'String', filename);
                                                
                        %Update the handles
                        guidata(hObject, handles);
                        
                        %Get the channel
                        correctionChannel = round(get(handles.popupmenuSParamNum, 'Value'));
                        
                        %Get the correction
                        cplxCorr = readSParamFile(handles);
                        
                        %Load it to VSA
                        loadToVSA(correctionChannel, 'RF', 1, cplxCorr);
                end
            end
        catch ex
            msgbox(ex.message);
        end

end



function [rows, cols] = setupSelectedSParam(handles, filename)
rows = 0;
cols = 0;
if (~isempty(filename))
    try
        sp = rfdata.data;
    catch
        errordlg('Can not create "rfdata" structure. Are you missing the "RF Toolbox" in your MATLAB installation?');
        return;
    end
    sp = read(sp, filename);
%    sp = reads4p(filename);
    if (~isempty(sp))
        rows = size(sp.S_Parameters, 1);
        cols = size(sp.S_Parameters, 2);
        pList = cell(rows*cols, 1);
        for i = 1:rows
            for j = 1:cols
                pList{(i-1)*cols+j} = sprintf('S%d%d', i, j);
            end
        end
        set(handles.popupmenuSParamSelect, 'Value', 1);
        set(handles.popupmenuSParamSelect, 'String', pList);
    end
end


% --- Executes on selection change in popupmenuStdMode.
function popupmenuStdMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuStdMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuStdMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuStdMode

%Load to instrument correction or VSA
iFMenuState = get(handles.sliderIF, 'Value');

switch iFMenuState
    case 0 %IQ Precorrection
        val = get(handles.popupmenuStdMode, 'Value');
        idx = [-1 1 0];  % de-embed, embed, do nothing
        ampCorrFile = iqampCorrFilename();
        acs = load(ampCorrFile);
        acs.ampCorrMode = idx(val);
        save(ampCorrFile, '-struct', 'acs');
        updateAxes(handles);


    case 1 %VSA Correction
        pushbuttonImportComplex_Callback(hObject, eventdata, handles)
end



% --- Executes during object creation, after setting all properties.
function popupmenuStdMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuStdMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editSParamCutoff_Callback(hObject, eventdata, handles)
% hObject    handle to editSParamCutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSParamCutoff as text
%        str2double(get(hObject,'String')) returns contents of editSParamCutoff as a double
ampCorrFile = iqampCorrFilename();
acs = [];
try
    acs = load(ampCorrFile);
catch
end
try
    acs.sparamCutoff = evalin('base', get(handles.editSParamCutoff, 'String'));
catch
    acs.sparamCutoff = 0;
end
save(ampCorrFile, '-struct', 'acs');
updateAxes(handles);


% --- Executes during object creation, after setting all properties.
function editSParamCutoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSParamCutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on selection change in popupmenuSParamSelect.
function popupmenuSParamSelect_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSParamSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSParamSelect contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSParamSelect

%Menu state of S-Parameters
sPMenuState = get(handles.sliderSPar, 'Value');

switch sPMenuState
    case 0 %Precorrect waveform
        vals = cellstr(get(handles.popupmenuSParamSelect, 'String'));
        val = vals{get(handles.popupmenuSParamSelect, 'Value')};
        spNum = get(handles.popupmenuSParamNum, 'Value');
        sp = sscanf(val, 'S%d');
        row = floor(sp/10);
        col = sp - 10*row;
        
        ampCorrFile = iqampCorrFilename();
        acs = load(ampCorrFile);
        acs.selectedSParam(spNum, 1:2) = [row col];
        save(ampCorrFile, '-struct', 'acs');
        updateAxes(handles);
    case 1 %Correct VSA
        %Get the file name, if it is not valid, prompt for it
        fileName = get(handles.editSParamFile, 'String');
        try
            if(~isempty(fileName) && isempty(strfind(fileName, 'ampCorr.mat')));
                %Get the channel
                correctionChannel = round(get(handles.popupmenuSParamNum, 'Value'));

                %Get the correction
                cplxCorr = readSParamFile(handles);

                %Load it to VSA
                loadToVSA(correctionChannel, 'RF', 1, cplxCorr);
            else
                pushbuttonLoadSParamFile_Callback(hObject, eventdata, handles);
            end
        catch ex
            msgbox(ex.message);
        end
end



% --- Executes during object creation, after setting all properties.
function popupmenuSParamSelect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSParamSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonStoreAsStd.
function pushbuttonStoreAsStd_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStoreAsStd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
corr = iqcorrection([]);
% get the filename
ampCorrFile = iqampCorrFilename();
% and save
acs = load(ampCorrFile);
acs.ampCorr = corr;
acs.sparamMode = 0;     % don't double embed/deembed
save(ampCorrFile, '-struct', 'acs');
updateAxes(handles);


% --- Executes on button press in pushbuttonReadAWGCal.
function pushbuttonReadAWGCal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonReadAWGCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
if (~isempty(arbConfig) && (~isempty(strfind(arbConfig.model, 'M8195A')) || ~isempty(strfind(arbConfig.model, 'M8196A')) || ~isempty(strfind(arbConfig.model, 'M8194A'))))
    if (isfield(arbConfig, 'M8195Acorrection') && arbConfig.M8195Acorrection ~= 0)
        errordlg('Please turn off "M8195A/96A built-in corrections" in the configuration window if you want to use the corrections here. Otherwise you will apply the corrections twice');
        return;
    end
    h = msgbox('Reading cal data from instrument. Please wait...', 'Please wait', 'replace');
    f = iqopen(arbConfig);
    if (~isempty(f))
        try
            clear cplxCorr;
            for i=1:4
                a = query(f, sprintf('CHAR%d?', i));
                v = sscanf(strrep(strrep(a, '"', ''), ',', ' '), '%g');
                v = reshape(v, 3, length(v)/3)';
                freq = v(:,1);
                cplxCorr(:,i) = v(:,2) .* exp(1j * v(:,3));
            end
            updatePerChannelCorr(handles, freq, cplxCorr, [1;2;3;4]);
        catch ex
            errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
        end
    end
    try close(h); catch; end
else
    errordlg({'Only the M8195A/96A supports built-in correction data'});
end


% --- Executes on button press in pushbuttonClearPerChannelCorr.
function pushbuttonClearPerChannelCorr_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClearPerChannelCorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ampCorrFile = iqampCorrFilename();
clear acs;
% try to load ampCorr file - be graceful if it does not exist
try
    acs = load(ampCorrFile);
catch
end
if (isfield(acs, 'perChannelCorr') && size(acs.perChannelCorr, 2) > 2)
    % if more than one channel, ask which one to clear
    if (isfield(acs, 'AWGChannels') && ~isempty(acs.AWGChannels))
        chanList = acs.AWGChannels;
    else
        chanList = 1:(size(acs.perChannelCorr, 2) - 1);
    end
    chanStr = {strtrim(sprintf('%d ', chanList))};
    res = inputdlg('Select the channels the clear', 'Select the channels to clear', 1, chanStr);
    if (isempty(res))
        return;
    end
    clearList = sscanf(res{1}, '%d', inf);
    if (isempty(clearList))
        return;
    end
    clearList = sort(clearList, 'descend');
    for i = 1:length(clearList)
        idx = find(chanList == clearList(i), 1);
        if (~isempty(idx))
            acs.perChannelCorr(:,idx+1) = [];
            chanList(idx) = [];
        end
    end
    if (isempty(chanList))
        acs = rmfield(acs, 'perChannelCorr');
    end
    if (isfield(acs, 'AWGChannels'))
        acs.AWGChannels = chanList;
    end
else
    acs.perChannelCorr = [];
    acs = rmfield(acs, 'perChannelCorr');
    acs.AWGChannels = [];
    acs = rmfield(acs, 'AWGChannels');
end
% and save
save(ampCorrFile, '-struct', 'acs');
updateAxes(handles);           




% --- Executes on button press in pushbuttonClearCplx.
function pushbuttonClearCplx_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClearCplx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
answer = questdlg('Do you really want to delete the complex correction?', 'Delete complex correction', 'Yes', 'No', 'No');
if (strcmp(answer, 'Yes'))
    
    %Load to instrument correction or VSA
    iFMenuState = get(handles.sliderIF, 'Value');

    switch iFMenuState
        case 0 %IQ Precorrection
            ampCorrFile = iqampCorrFilename();
            clear acs;
            % try to load ampCorr file - be graceful if it does not exist
            try
                acs = load(ampCorrFile);
            catch
            end
            acs.ampCorr = [];
            acs = rmfield(acs, 'ampCorr');
            % and save
            save(ampCorrFile, '-struct', 'acs');
            updateAxes(handles);


        case 1 %VSA Correction
            %Get the channel
            correctionChannel = round(get(handles.popupmenuIFNumber, 'Value'));

            %Load it to VSA
            loadToVSA(correctionChannel, 'IF', 0, []);
    end
    
    
    
end


% --- Executes on button press in checkboxMagnitude.
function checkboxMagnitude_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxMagnitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ((get(handles.checkboxMagnitude, 'Value') == 0) && ...
    (get(handles.checkboxPhase, 'Value') == 0))
  set(handles.checkboxMagnitude, 'Value', 1);
end
updateAxes(handles);


% --- Executes on button press in checkboxPhase.
function checkboxPhase_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ((get(handles.checkboxMagnitude, 'Value') == 0) && ...
    (get(handles.checkboxPhase, 'Value') == 0))
  set(handles.checkboxMagnitude, 'Value', 1);
end
updateAxes(handles);


% --- Executes on button press in pushbuttonImportPerChannel.
function pushbuttonImportPerChannel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonImportPerChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname, filterindex] = uigetfile({
    '*.s2p;*.s4p;*.s6p;*.s8p', 'Touchstone file'; ...
    '*.mat', 'MATLAB file'; ...
    '*.csv', 'CSV file'});
if (filename ~= 0)
    switch filterindex
        case 2 % *.mat
            try
                % process .MAT file - could be either VSA equalizer trace or M8195A calibration file
                eq = load(fullfile(pathname, filename));
                if (isfield(eq, 'Cal')) % M8195A Calibration file
                    freq = 1e9 * eq.Cal.Frequency_MT;
                    amp = 10 .^ (eq.Cal.AmplitudeResponse_MT(:,:) / 20);
                    filler = zeros(size(eq.Cal.AmplitudeResponse_MT, 1) - size(eq.Cal.AbsPhaseResponse_MT, 1), size(eq.Cal.AmplitudeResponse_MT, 2));
                    phi = [filler; eq.Cal.AbsPhaseResponse_MT(:,:)] * pi / 180;
                    if (isfield(eq.Cal, 'AWGChannels'))
                        AWGChannels = eq.Cal.AWGChannels;
                    else
                        AWGChannels = [];
                    end
                    updatePerChannelCorr(handles, freq, amp .* exp(1i * phi), AWGChannels);
                elseif (~isfield(eq, 'Y') || ~isfield(eq, 'XStart') || ~isfield(eq, 'XDelta')) % VSA trace file
                    errordlg('Invalid correction file format. Expected variables "Y", "XStart" and "XStart" in the file');
                else
                    loadVSAcorr(handles, eq, @updatePerChannelCorr);
                end
            catch ex
                errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
            end
        case 3 % *.csv
            try
                val = csvread(fullfile(pathname, filename));
                switch (size(val,2))
                    case 3
                        freq = val(:,1);
                        corr = 10.^(val(:,2)./20) .* exp(1j * val(:,3)*pi/180);
                        updatePerChannelCorr(handles, freq, 1 ./ corr);
                    case 5
                        freq = val(:,1);
                        corr = [10.^(val(:,2)./20) .* exp(1j * val(:,3)*pi/180), ...
                                10.^(val(:,4)./20) .* exp(1j * val(:,5)*pi/180)];
                        updatePerChannelCorr(handles, freq, 1 ./ corr);
                    otherwise
                        errordlg('expected CSV with 3 or 5 columns');
                end
            catch ex
                errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
            end
        case 1 % S-parameter file
            try
                sp = rfdata.data;
            catch
                errordlg('Can not create "rfdata" structure. Are you missing the "RF Toolbox" in your MATLAB installation?');
                return;
            end
            try
                sp = read(sp, fullfile(pathname, filename));
                freq = sp.Freq;
                defaultVal = {'2 1'};
                if (size(sp.S_Parameters, 1) > 2)
                    defaultVal = {'2 1  4 3'};
                end
                result = [];
                while isempty(result)
                    result = inputdlg('Select S-parameter (e.g. "2 1" for S21)', 'Select S-parameter', 1, defaultVal);
                    if (isempty(result))
                        return;
                    end
                    result = sscanf(result{1}, '%d', inf);
                    if (~isvector(result) || length(result) < 2 || mod(length(result),2) ~= 0 || ...
                              min(result) < 1 || max(result) > size(sp.S_Parameters, 1) || ~isequal(floor(result), result))
                        h = errordlg('Please enter 2 or 4 numbers separated by spaces');
                        pause(1);
                        try close(h); catch; end;
                        result = '';
                    end
                end
                numCol = length(result) / 2;
                corr = zeros(size(freq,1), numCol);
                for i = 1:numCol
                    corr(:,i) = squeeze(sp.S_Parameters(result(2*i-1), result(2*i), :));
                end
                updatePerChannelCorr(handles, freq, corr);
            catch ex
                errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
            end
    end % switch
end


% --- Executes on button press in pushbuttonMTCal.
function pushbuttonMTCal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMTCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqmtcal;


% --- Executes on selection change in popupmenuSParamNum.
function popupmenuSParamNum_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSParamNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSParamNum contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSParamNum
% try to load ampCorr file - be graceful if it does not exist
%Menu state of S-Parameters
sPMenuState = get(handles.sliderSPar, 'Value');

switch sPMenuState
    case 0 %Precorrect waveform
        ampCorrFile = iqampCorrFilename();
        try
            acs = load(ampCorrFile);
            if (isfield(acs, 'sparamFile') && ischar(acs.sparamFile))
                acs.sparamFile = { acs.sparamFile };
                save(ampCorrFile, '-struct', 'acs');
            end
            spNum = get(handles.popupmenuSParamNum, 'Value');
            if (isfield(acs, 'sparamFile') && spNum <= size(acs.sparamFile, 2))
                [rows, cols] = setupSelectedSParam(handles, acs.sparamFile{spNum});
                if (rows ~= 0)
                    sel = acs.selectedSParam(spNum, :);
                    set(handles.popupmenuSParamSelect, 'Value', (sel(1)-1)*cols + sel(2));
                end
            end
        catch
        end
        updateAxes(handles);
        
    case 1 %Correct VSA
        %Get the file name, if it is not valid, prompt for it
        fileName = get(handles.editSParamFile, 'String');
        try
            pushbuttonLoadSParamFile_Callback(hObject, eventdata, handles);
        catch ex
            msgbox(ex.message);
        end
end


% --- Executes during object creation, after setting all properties.
function popupmenuSParamNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSParamNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonSParamClear.
function pushbuttonSParamClear_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSParamClear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Menu state of S-Parameters
sPMenuState = get(handles.sliderSPar, 'Value');

switch sPMenuState
    case 0 %Precorrect waveform
        ampCorrFile = iqampCorrFilename();
        try
            set(handles.popupmenuSParamNum, 'Value', 1);
            acs = load(ampCorrFile);
            if (isfield(acs, 'sparamFile'))
                acs = rmfield(acs, 'sparamFile');
            end
            if (isfield(acs, 'sparamMode'))
                acs = rmfield(acs, 'sparamMode');
            end
            if (isfield(acs, 'selectedSParam'))
                acs = rmfield(acs, 'selectedSParam');
            end
            if (isfield(acs, 'sparamRemoveSkew'))
                acs = rmfield(acs, 'sparamRemoveSkew');
            end
            save(ampCorrFile, '-struct', 'acs');
        catch
        end
        updateAxes(handles);
    case 1 %Correct VSA
        %Get the channel
        correctionChannel = round(get(handles.popupmenuSParamNum, 'Value'));

        %Load it to VSA
        loadToVSA(correctionChannel, 'RF', 0, []);
        
        %Clear the pathname
        handles.VSAPathname = [];
        set(handles.editSParamFile, 'String', []);
end


% --- Executes on button press in checkboxRemoveSkew.
function checkboxRemoveSkew_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxRemoveSkew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject, 'Value');
try
    %Menu state of S-Parameters
    sPMenuState = get(handles.sliderSPar, 'Value');

    switch sPMenuState
        case 0 %Precorrect waveform
            ampCorrFile = iqampCorrFilename();
            acs = load(ampCorrFile);
            acs.sparamRemoveSkew = val;
            save(ampCorrFile, '-struct', 'acs');
            updateAxes(handles);
        
        case 1 %Correct VSA
            %Get the file name, if it is not valid, prompt for it
            fileName = get(handles.editSParamFile, 'String');
            if(~isempty(fileName) && isempty(strfind(fileName, 'ampCorr.mat')));
                %Get the channel
                correctionChannel = round(get(handles.popupmenuSParamNum, 'Value'));

                %Get the correction
                cplxCorr = readSParamFile(handles);

                %Load it to VSA
                loadToVSA(correctionChannel, 'RF', 1, cplxCorr);
            else
                pushbuttonLoadSParamFile_Callback(hObject, eventdata, handles);
            end
    end
catch ex
    errordlg(ex.message);
end


function editWeight_Callback(hObject, eventdata, handles)
% hObject    handle to editWeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isreal(value))
    set(hObject,'BackgroundColor','white');
    try
        %Menu state of S-Parameters
        sPMenuState = get(handles.sliderSPar, 'Value');

        switch sPMenuState
            case 0 %Precorrect waveform
                ampCorrFile = iqampCorrFilename();
                acs = load(ampCorrFile);
                acs.sparamWeight = value;
                save(ampCorrFile, '-struct', 'acs');
                updateAxes(handles);
                
            case 1 %Correct VSA
                %Get the file name, if it is not valid, prompt for it
                fileName = get(handles.editSParamFile, 'String');
                if(~isempty(fileName) && isempty(strfind(fileName, 'ampCorr.mat')));
                    %Get the channel
                    correctionChannel = round(get(handles.popupmenuSParamNum, 'Value'));

                    %Get the correction
                    cplxCorr = readSParamFile(handles);

                    %Load it to VSA
                    loadToVSA(correctionChannel, 'RF', 1, cplxCorr);
                else
                    pushbuttonLoadSParamFile_Callback(hObject, eventdata, handles);
                end   
        end
    catch ex
        errordlg(ex.message);
    end
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editWeight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonExportPerChannel.
function pushbuttonExportPerChannel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonExportPerChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[ampCorr, perChannelCorr, acs, ~] = iqcorrection([]);
if (isempty(perChannelCorr))
    errordlg('No per-channel correction available');
    return;
end
if (isfield(acs, 'AWGChannels') && ~isempty(acs.AWGChannels))
    AWGChannels = acs.AWGChannels;
else
    AWGChannels = [];
end
savePerChannelCorr(perChannelCorr, AWGChannels);


function savePerChannelCorr(perChannelCorr, AWGChannels)
% prompt user for a filename and save frequency response in desired format
% note: same function as in iqmtcal_gui.m --> should be unified
numChan = size(perChannelCorr, 2) - 1;
sp1 = sprintf('.s%dp', 2*numChan);
sp2 = sprintf('Touchstone %d-port file (*.s%dp)', 2*numChan, 2*numChan);
[filename, pathname, filterindex] = uiputfile({...
    sp1, sp2; ...
    '.mat', 'MATLAB file (*.mat)'; ...
    '.csv', 'CSV file (*.csv)'; ...
    '.csv', 'CSV (VSA style) (*.csv)'; ...
    '.cal', 'VSA User Correction (*.cal)'}, ...
    'Save Frequency Response As...');
if (filename ~= 0)
    switch filterindex
        case 2 % .mat
            try
                clear Cal;
                Cal.Frequency_MT = perChannelCorr(:,1) / 1e9;
                Cal.AmplitudeResponse_MT = -20 * log10(abs(perChannelCorr(:,2:end)));
                Cal.AbsPhaseResponse_MT = unwrap(angle(perChannelCorr(:,2:end))) * -180 / pi;
                if (~isempty(AWGChannels))
                    Cal.AWGChannels = AWGChannels;
                end
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
                    list = {'Primary / I', 'Secondary / Q', '3rd', '4th'};
                    [ch,~] = listdlg('PromptString', 'Select Channel', 'SelectionMode', 'single', 'ListString', list(1:size(perChannelCorr,2)-1), 'ListSize', [100 60]);
                end
                if (~isempty(ch))
                    f = fopen(fullfile(pathname, filename), 'wt');
                    pf = polyfit((0:size(perChannelCorr, 1)-1)', perChannelCorr(:,1), 1);
                    fprintf(f, sprintf('InputBlockSize, %d\n', size(perChannelCorr(:,1), 1)));
                    fprintf(f, sprintf('XStart, %g\n', pf(2)));
                    fprintf(f, sprintf('XDelta, %g\n', pf(1)));
                    fprintf(f, sprintf('YUnit, lin\n'));
                    fprintf(f, sprintf('Y\n'));
                    for i = 1:size(perChannelCorr, 1)
                        fprintf(f, sprintf('%g,%g\n', real(1/perChannelCorr(i,ch+1)), imag(1/perChannelCorr(i,ch+1))));
                        %fprintf(f, sprintf('%g,%g\n', abs(1/perChannelCorr(i,ch+1)), -angle(perChannelCorr(i,ch+1))));
                        %fprintf(f, sprintf('%g,%g\n', -20*log10(abs(perChannelCorr(i,ch+1))), unwrap(angle(perChannelCorr(i,ch+1))) * -180 / pi));
                    end
                    fclose(f);
                end
            catch ex
                errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
            end
        case 5 % .cal (VSA User Correction)
            try
                ch = 1;
                if (size(perChannelCorr, 2) > 2)
                    list = {'Primary / I', 'Secondary / Q', '3rd', '4th'};
                    [ch,~] = listdlg('PromptString', 'Select Channel', 'SelectionMode', 'single', 'ListString', list(1:size(perChannelCorr,2)-1), 'ListSize', [100 60]);
                end
                if (~isempty(ch))
                    f = fopen(fullfile(pathname, filename), 'wt');
                    pf = polyfit((0:size(perChannelCorr, 1)-1)', perChannelCorr(:,1), 1);
                    fprintf(f, sprintf('FileFormat UserCal-1.0\n'));
                    fprintf(f, sprintf('Trace Data\n'));
                    fprintf(f, sprintf('YComplex 1\n'));
                    fprintf(f, sprintf('YFormat RI\n'));
                    fprintf(f, sprintf('XStart %g\n', pf(2)));
                    fprintf(f, sprintf('XDelta %g\n', pf(1)));
                    fprintf(f, sprintf('Y\n'));
                    for i = 1:size(perChannelCorr, 1)
                        fprintf(f, sprintf('%g %g\n', real(1/perChannelCorr(i,ch+1)), imag(1/perChannelCorr(i,ch+1))));
                        %fprintf(f, sprintf('%g %g\n', abs(1/perChannelCorr(i,ch+1)), -angle(perChannelCorr(i,ch+1))));
                        %fprintf(f, sprintf('%g %g\n', -20*log10(abs(perChannelCorr(i,ch+1))), unwrap(angle(perChannelCorr(i,ch+1))) * -180 / pi));
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


% --- Executes when iqtool is resized.
function iqtool_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to iqtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    posWindow = get(handles.iqtool, 'Position');
    tmp = handles.uipanelCplx.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.posCplx(1));
    handles.uipanelCplx.Position = tmp;
    tmp = handles.uipanelSParam.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.posSParam(1));
    handles.uipanelSParam.Position = tmp;
    tmp = handles.pushbuttonReadAWGCal.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.posReadAWGCal(1));
    handles.pushbuttonReadAWGCal.Position = tmp;
    tmp = handles.pushbuttonMTCal.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.posMTCal(1));
    handles.pushbuttonMTCal.Position = tmp;
    tmp = handles.pushbuttonImportPerChannel.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.posImportPerChannel(1));
    handles.pushbuttonImportPerChannel.Position = tmp;
    tmp = handles.pushbuttonExportPerChannel.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.posExportPerChannel(1));
    handles.pushbuttonExportPerChannel.Position = tmp;
    tmp = handles.pushbuttonClearPerChannelCorr.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.posClearPerChannelCorr(1));
    handles.pushbuttonClearPerChannelCorr.Position = tmp;
    tmp = handles.textCutoff.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.postextCutoff(1));
    handles.textCutoff.Position = tmp;
    tmp = handles.editSParamCutoff.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.poseditSParamCutoff(1));
    handles.editSParamCutoff.Position = tmp;

    tmp = handles.textSmooth.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.postextSmooth(1));
    handles.textSmooth.Position = tmp;
    tmp = handles.editSmooth.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.poseditSmooth(1));
    handles.editSmooth.Position = tmp;

    tmp = handles.checkboxAbsMagnitude.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.poscheckboxAbsMagnitude(1));
    handles.checkboxAbsMagnitude.Position = tmp;
    tmp = handles.textAbsMagnitude.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.postextAbsMagnitude(1));
    handles.textAbsMagnitude.Position = tmp;
    tmp = handles.editAbsMagnitude.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.poseditAbsMagnitude(1));
    handles.editAbsMagnitude.Position = tmp;
    
    tmp = handles.textDisplay.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.postextDisplay(1));
    handles.textDisplay.Position = tmp;
    tmp = handles.checkboxMagnitude.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.poscheckboxMagnitude(1));
    handles.checkboxMagnitude.Position = tmp;
    tmp = handles.checkboxPhase.Position;
    tmp(1) = posWindow(3) - (handles.posWindow(3) - handles.poscheckboxPhase(1));
    handles.checkboxPhase.Position = tmp;

    r = handles.posaxes1(2) / handles.posWindow(4);
    tmp = handles.axes1.Position;
    tmp(3) = posWindow(3) - (handles.posWindow(3) - handles.posaxes1(3));
    tmp(2) = 0.5 * posWindow(4) + 50;
    tmp(4) = 0.5 * posWindow(4) - 80;
    handles.axes1.Position = tmp;
    tmp = handles.axes2.Position;
    tmp(3) = posWindow(3) - (handles.posWindow(3) - handles.posaxes2(3));
    tmp(2) = 50;
    tmp(4) = 0.5 * posWindow(4) - 80;
    handles.axes2.Position = tmp;
catch; end;

function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;



function editSmooth_Callback(hObject, eventdata, handles)
% hObject    handle to editSmooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isreal(value) && value >= 0)
    set(hObject,'BackgroundColor','white');
    ampCorrFile = iqampCorrFilename();
    acs = load(ampCorrFile);
    acs.smoothing = round(value);
    save(ampCorrFile, '-struct', 'acs');
    updateAxes(handles);
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSmooth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSmooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editAbsMagnitude_Callback(hObject, eventdata, handles)
% hObject    handle to editAbsMagnitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = evalin('base', ['[' get(handles.editAbsMagnitude, 'String') ']']);
catch ex
    msgbox(ex.message);
end
if (~isempty(value) && isreal(value) && isscalar(value))
    set(hObject,'BackgroundColor','white');
    try
        ampCorrFile = iqampCorrFilename();
        acs = load(ampCorrFile);
        acs.absMagnitude = value;
        if (~get(handles.checkboxAbsMagnitude, 'Value'))
            acs = rmfield(acs, 'absMagnitude');
        end
        save(ampCorrFile, '-struct', 'acs');
        updateAxes(handles);
    catch ex
        errordlg(ex.message);
    end
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editAbsMagnitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAbsMagnitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxAbsMagnitude.
function checkboxAbsMagnitude_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAbsMagnitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(handles.checkboxAbsMagnitude,'Value');
if (val)
    set(handles.textAbsMagnitude, 'Enable', 'on');
    set(handles.editAbsMagnitude, 'Enable', 'on');
%     try
%         value = evalin('base', ['[' get(handles.editAbsMagnitude, 'String') ']']);
%         if (value == 0)
%             minVal = 0;
%             [ampCorr, perChannelCorr] = iqcorrection([]);
%             if (~isempty(ampCorr))
%                 minVal = max(ampCorr(:,2));
%             end
%             if (~isempty(perChannelCorr))
%                 minVal = max(max(20*log10(abs(perChannelCorr(:, 2:end)))));
%             end
%             minVal = ceil(minVal * 10) / 10;
%             set(handles.editAbsMagnitude, 'String', sprintf('%.1f', minVal));
%         end
%     catch ex
%     end
else
    set(handles.textAbsMagnitude, 'Enable', 'off');
    set(handles.editAbsMagnitude, 'Enable', 'off');
end
editAbsMagnitude_Callback([], [], handles);


% --- Executes on slider movement.
function sliderSPar_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSPar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sPMenuState = get(handles.sliderSPar, 'Value');

switch sPMenuState
    case 0
        set(handles.textSPar, 'String', 'Generation');
        updateAxes(handles);
    case 1
        set(handles.textSPar, 'String', 'VSA Analysis');
        
        %Clear the pathname
        handles.VSAPathname = [];
        set(handles.editSParamFile, 'String', []);
end




% --- Executes during object creation, after setting all properties.
function sliderSPar_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSPar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end





% --- Executes on slider movement.
function sliderIF_Callback(hObject, eventdata, handles)
% hObject    handle to sliderIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
iFMenuState = get(handles.sliderIF, 'Value');

switch iFMenuState
    case 0
        set(handles.textIF, 'String', 'Generation');
        set(handles.pushbuttonExportComplex, 'Enable', 'on');
        set(handles.textIFDescriptor, 'String', 'Filename');
        set(handles.popupmenuIFNumber, 'Visible', 'off');
        set(handles.editFilename, 'Visible', 'on');

    case 1
        set(handles.textIF, 'String', 'VSA Analysis');
        set(handles.pushbuttonExportComplex, 'Enable', 'off')
        set(handles.textIFDescriptor, 'String', 'Channel/Port');
        set(handles.popupmenuIFNumber, 'Visible', 'on');
        set(handles.editFilename, 'Visible', 'off');

end


% --- Executes during object creation, after setting all properties.
function sliderIF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function cplxCorr = readSParamFile(handles)

try
    sparamFile = [handles.VSAPathname get(handles.editSParamFile, 'String')];
    sparamMode = get(handles.popupmenuSParamMode, 'Value');

    vals = cellstr(get(handles.popupmenuSParamSelect, 'String'));
    val = vals{get(handles.popupmenuSParamSelect, 'Value')};
    spNum = get(handles.popupmenuSParamNum, 'Value');
    sp = sscanf(val, 'S%d');
    row = floor(sp/10);
    col = sp - 10*row;
    selectedSParam = [row, col];

    removeSkew = get(handles.checkboxRemoveSkew, 'Value');
    weight = evalin('base', ['[' get(handles.editWeight, 'String') ']']);
    
    mirror = false;
    
catch ex
    msgbox(ex.message);
    
end

cplxCorr = [];
if (isempty(sparamFile))
    return;
end
try
    %sp = reads4p(sparamFile);
    sp = rfdata.data;
    sp = read(sp, sparamFile);
catch ex
    errordlg({'Error reading ' sparamFile ' ' ex.message});
    return;
end
freq = sp.Freq;
corr = squeeze(sp.S_Parameters(selectedSParam(1), selectedSParam(2), :));
if (removeSkew)
    mag = abs(corr);
    phi = unwrap(angle(corr));
    % fit a straight line
    pf = polyfit(freq/1e6, phi, 1);
    % do not shift it - just change the angle
    pf(2) = 0;
    phi = phi - polyval(pf, freq/1e6);
    corr = mag .* exp(1i * phi);
end
if (weight ~= 1)
    % apply weight separately to magnitude & phase
    % (log magnitude is multiplied by weight, hence linear magnitude must
    % be raised to the power of weight)
    mag = abs(corr) .^ weight;
    phi = unwrap(angle(corr)) .* weight;
    corr = mag .* exp(1i * phi);
end
if (mirror)
    % assume the same behaviour for positive & negative frequencies
    if (freq(1) == 0)            % don't duplicate zero-frequency
        startIdx = 2;
    else
        startIdx = 1;
    end
    freq = [-1 * flipud(freq); freq(startIdx:end)];
    corr = [conj(flipud(corr)); corr(startIdx:end)]; % negative side must use complex conjugate
end
cplxCorr = zeros(length(freq), 2);
cplxCorr(:,1) = freq;
switch sparamMode
    case 1
        cplxCorr(:,2) = corr;
    case 2
        cplxCorr(:,2) = 1 ./ corr;
    case 3
        cplxCorr(:,2) = ones(size(corr));
    otherwise
        error('unexpected embedding mode');
end

function loadToVSA(measurementChannel, correctionMode, correctionState, complexCorrectionData)
    vsaApp = vsafunc([], 'open');
    if (~isempty(vsaApp))
        hMsgBox = msgbox('Loading correction file. Please wait...');
        
        switch correctionMode
            case 'IF'
                vsafunc(vsaApp,'loadIFCorrection', measurementChannel, correctionState, complexCorrectionData);
            case 'RF'
                vsafunc(vsaApp,'loadRFCorrection', measurementChannel, correctionState, complexCorrectionData);                
        end
        
        try
            close(hMsgBox);
        catch
        end    
        
    end
    
    
function cplxCorr = updateAmpCorrVSALoad(handles, freq, Y)
% VSA seems to sometimes return multiple columns with the same value...
if (size(Y,1) > 1 && size(Y,2) > 1)
    Y = Y(:,1);
end

cplxCorr(:,1) = freq(1:end);

ifCorrMode = get(handles.popupmenuStdMode, 'Value');

switch ifCorrMode
    case 1
        cplxCorr(:,2) = Y;
    case 2
        cplxCorr(:,2) = 1 ./ Y;
    case 3
        cplxCorr(:,2) = ones(size(Y));
    otherwise
        error('unexpected embedding mode');
end

function cplxCorr = loadVSAcorrVSALoad(handles, eq, updateFct)
cancel = 0;
if (isfield(eq, 'InputCenter') && eq.InputCenter ~= 0)
    res = questdlg(sprintf('The equalizer data in this file is centered at %s Hz.\nDo you want to shift the data to baseband?', iqengprintf(eq.InputCenter)));
    switch (res)
        case 'Yes'; eq.XStart = eq.XStart - eq.InputCenter; eq.InputCenter = 0;
        case 'Cancel'; cancel = 1;
    end
end
% ask for frequency shift
%                 if (eq.InputCenter ~= 0)
%                     result = inputdlg('Shift Frequency (use negative values to shift from RF to baseband)', 'Shift Frequency', 1, {'0'});
%                     if (isempty(result))
%                         cancel = 1;
%                     else
%                         eq.XStart = eq.XStart + eval(result{1});
%                     end
%                 end
if (~cancel)
    % calculate frequency vector
    freq = linspace(eq.XStart, eq.XStart + (length(eq.Y) - 1) * eq.XDelta, length(eq.Y));
    % update ampCorr file
    cplxCorr = updateFct(handles, freq, eq.Y);
end


% --- Executes on selection change in popupmenuIFNumber.
function popupmenuIFNumber_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuIFNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuIFNumber contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuIFNumber


% --- Executes during object creation, after setting all properties.
function popupmenuIFNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuIFNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
