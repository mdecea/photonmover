function varargout = iqmain(varargin)
% IQMAIN M-file for iqmain.fig
%      IQMAIN, by itself, creates a new IQMAIN or raises the existing
%      singleton*.
%
%      H = IQMAIN returns the handle to a new IQMAIN or the handle to
%      the existing singleton*.
%
%      IQMAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQMAIN.M with the given input arguments.
%
%      IQMAIN('Property','Value',...) creates a new IQMAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqmain_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqmain_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqmain

% Last Modified by GUIDE v2.5 18-Aug-2019 09:55:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqmain_OpeningFcn, ...
                   'gui_OutputFcn',  @iqmain_OutputFcn, ...
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


% --- Executes just before iqmain is made visible.
function iqmain_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqmain (see VARARGIN)

% Choose default command line output for iqmain
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% compiled code seems to start up in windows\system32. That's not good...
if (isdeployed)
    [~, result] = system('path');
    cd(char(regexpi(result, 'Path=(.*?);', 'tokens', 'once')));
end
update_gui(hObject, [], handles);

% Set main window title (can also be done in GUIDE):
%set(gcf, 'Name', 'Keysight IQTools'); % gcf = get current figure handle
% Add additional text at the bottom of the main window:
set(handles.bottomText, 'String', '2019_10_24');

% UIWAIT makes iqmain wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqmain_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonSerial.
function pushbuttonSerial_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
iserial();

% --- Executes on button press in pushbuttonConfig.
function pushbuttonConfig_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqconfig();

% --- Executes on button press in pushbuttonTone.
function pushbuttonTone_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqtone();

% --- Executes on button press in pushbuttonMod.
function pushbuttonMod_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqmod();

% --- Executes on button press in pushbuttonPulse.
function pushbuttonPulse_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPulse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqpulse();

% --- Executes on button press in pushbuttonFsk.
function pushbuttonFsk_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonFsk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqfsk();


% --- Executes on button press in pushbuttonLoadFile.
function pushbuttonLoadFile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonLoadFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqloadfile();


% --- Executes on button press in pushbuttonOFDM.
function pushbuttonOFDM_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonOFDM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqofdm();


% --- Executes on button press in pushbuttonPulseGen.
function pushbuttonPulseGen_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPulseGen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqpulsegen();


% --- Executes on button press in pushbuttonSequencer.
function pushbuttonSequencer_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSequencer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqseq();


% --- Executes on button press in pushbuttonCATV.
function pushbuttonCATV_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCATV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
catv_gui();


% --- Executes on button press in pushbuttonRadarDemo.
function pushbuttonRadarDemo_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRadarDemo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
iqrsim_gui();


% --- Executes on button press in pushbuttonSeqDemo1.
function pushbuttonSeqDemo1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSeqDemo1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
seqtest1_gui();


% --- Executes on button press in pushbuttonM8190ADemos.
function pushbuttonM8190ADemos_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonM8190ADemos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if iqmain.fig is opened directly, then handles is empty and we have to
% find a workaround to access the other GUI elements
if (isfield(handles, 'AWGSpecificFunctions') && handles.AWGSpecificFunctions == 1)
    handles.AWGSpecificFunctions = 0;
else
    handles.AWGSpecificFunctions = 1;
end
guidata(hObject, handles);
update_gui(hObject, eventdata, handles);



function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
update_gui(hObject, eventdata, handles);


function update_gui(hObject, eventdata, handles)
% retrieve handles again, in case this function is called from iqconfig
handles = guidata(hObject);
if (isempty(handles))
    % if iqtools was launched by double clicking on iqmain.fig, the
    % "handles" structure is not initialized. Workaround: restart it.
    close(hObject);
    iqmain();
    return;
end
% find out if arbConfig.mat is available.  If not, don't complain ...
% it could be the first start of iqmain and arbConfig does not exist
try
    load(iqarbConfigFilename());
    arbConfig = loadArbConfig();
catch e
    arbConfig = [];
end
if (~isempty(arbConfig))
    if (~isempty(strfind(arbConfig.model, 'M8190')))
        set(handles.pushbuttonM8190ADemos, 'String', regexprep(get(handles.pushbuttonM8190ADemos, 'String'), '.*specific', 'M8190A specific'));
        set(handles.pushbuttonM8190ADemos, 'Enable', 'on');
        set(handles.uipanelM8190A, 'Visible', 'on');
        set(handles.uipanelM8195A, 'Visible', 'off');
        set(handles.uipanelM8196A, 'Visible', 'off');
        set(handles.uipanelM8121A, 'Visible', 'off');
        set(handles.uipanelN5194A, 'Visible', 'off');
    elseif (~isempty(strfind(arbConfig.model, 'M8195')))
        set(handles.pushbuttonM8190ADemos, 'String', regexprep(get(handles.pushbuttonM8190ADemos, 'String'), '.*specific', 'M8195A specific'));
        set(handles.pushbuttonM8190ADemos, 'Enable', 'on');
        set(handles.uipanelM8190A, 'Visible', 'off');
        set(handles.uipanelM8196A, 'Visible', 'off');
        set(handles.uipanelN5194A, 'Visible', 'off');
        set(handles.uipanelM8121A, 'Visible', 'off');
        set(handles.uipanelM8195A, 'Visible', 'on');
        pos = get(handles.uipanelM8190A, 'Position');
        set(handles.uipanelM8195A, 'Position', pos);
    elseif (~isempty(strfind(arbConfig.model, 'M8196')) || ~isempty(strfind(arbConfig.model, 'M8194')))
        set(handles.pushbuttonM8190ADemos, 'String', regexprep(get(handles.pushbuttonM8190ADemos, 'String'), '.*specific', 'M8196A specific'));
        set(handles.pushbuttonM8190ADemos, 'Enable', 'on');
        set(handles.uipanelM8190A, 'Visible', 'off');
        set(handles.uipanelM8195A, 'Visible', 'off');
        set(handles.uipanelN5194A, 'Visible', 'off');
        set(handles.uipanelM8121A, 'Visible', 'off');
        set(handles.uipanelM8196A, 'Visible', 'on');
        pos = get(handles.uipanelM8190A, 'Position');
        set(handles.uipanelM8196A, 'Position', pos);
    elseif (~isempty(strfind(arbConfig.model, 'N5194A')))
        set(handles.pushbuttonM8190ADemos, 'String', regexprep(get(handles.pushbuttonM8190ADemos, 'String'), '.*specific', 'N5194A specific'));
        set(handles.pushbuttonM8190ADemos, 'Enable', 'on');
        set(handles.uipanelM8190A, 'Visible', 'off');
        set(handles.uipanelM8195A, 'Visible', 'off');
        set(handles.uipanelM8196A, 'Visible', 'off');
        set(handles.uipanelM8121A, 'Visible', 'off');
        set(handles.uipanelN5194A, 'Visible', 'on');
        pos = get(handles.uipanelM8190A, 'Position');
        set(handles.uipanelN5194A, 'Position', pos);
    elseif (~isempty(strfind(arbConfig.model, 'M8121A')))
        set(handles.pushbuttonM8190ADemos, 'String', regexprep(get(handles.pushbuttonM8190ADemos, 'String'), '.*specific', 'M8121A specific'));
        set(handles.pushbuttonM8190ADemos, 'Enable', 'on');
        set(handles.uipanelM8190A, 'Visible', 'off');
        set(handles.uipanelM8195A, 'Visible', 'off');
        set(handles.uipanelM8196A, 'Visible', 'off');
        set(handles.uipanelN5194A, 'Visible', 'off');
        set(handles.uipanelM8121A, 'Visible', 'on');
        pos = get(handles.uipanelM8190A, 'Position');
        set(handles.uipanelM8121A, 'Position', pos);
    else
        set(handles.pushbuttonM8190ADemos, 'Enable', 'off');
    end
end
figure = handles.iqtool;
pos = get(figure, 'Position');
if (isfield(handles, 'AWGSpecificFunctions') && handles.AWGSpecificFunctions && ~isempty(arbConfig) && ...
        (~isempty(strfind(arbConfig.model, 'M8190')) || ...
         ~isempty(strfind(arbConfig.model, 'M8195')) || ...
         ~isempty(strfind(arbConfig.model, 'M8196')) || ...
         ~isempty(strfind(arbConfig.model, 'M8194')) || ...
         ~isempty(strfind(arbConfig.model, 'N5194')) || ...
         ~isempty(strfind(arbConfig.model, 'M8121'))))
    pos(3) = 472;
    set(figure, 'Position', pos);
    set(handles.pushbuttonM8190ADemos, 'String', regexprep(get(handles.pushbuttonM8190ADemos, 'String'), '>', '<'));
else
    pos(3) = 241;
    set(figure, 'Position', pos);
    set(handles.pushbuttonM8190ADemos, 'String', regexprep(get(handles.pushbuttonM8190ADemos, 'String'), '<', '>'));
    set(handles.uipanelM8190A, 'Visible', 'off');
    set(handles.uipanelM8195A, 'Visible', 'off');
    set(handles.uipanelM8196A, 'Visible', 'off');
    set(handles.uipanelN5194A, 'Visible', 'off');
    set(handles.uipanelM8121A, 'Visible', 'off');
end


% --- Executes on button press in pushbuttonMultiChannel.
function pushbuttonMultiChannel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMultiChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
multi_channel_sync_gui


% --- Executes on button press in pushbuttonDUCDemo.
function pushbuttonDUCDemo_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDUCDemo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
duc_ctrl();


% --- Executes on button press in pushbuttonMultiPulse.
function pushbuttonMultiPulse_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMultiPulse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
multi_pulse_gui();


% --- Executes on button press in pushbuttonCPHY.
function pushbuttonCPHY_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCPHY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
dphy();


% --- Executes on button press in pushbuttonKeysight.
function pushbuttonKeysight_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonKeysight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
keysight_gui();


% --- Executes on button press in pushbuttonKeysightM8195A.
function pushbuttonKeysightM8195A_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonKeysightM8195A (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
keysight_gui();


% --- Executes on button press in pushbutton16chanSync.
function pushbutton16chanSync_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton16chanSync (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();    % make sure arbConfig exists
multi_16channel_sync_gui


% --- Executes on button press in pushbuttonPulseDemo.
function pushbuttonPulseDemo_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPulseDemo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mpulse_demo();


% --- Executes on button press in pushbuttonFIR.
function pushbuttonFIR_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonFIR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();    % make sure arbConfig exists
if (strcmp(arbConfig.model, 'M8195A_Rev1'))
    errordlg('FIR filters are not available in M8195A Rev. 1');
    return;
end
iqfir();


% --- Executes on button press in pushbuttonENOB
function pushbuttonENOB_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonENOB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqenob();


% --- Executes on button press in pushbuttonMMA_demo.
function pushbuttonMMA_demo_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMMA_demo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mma_demo();


% --- Executes on button press in pushbuttonCalTone.
function pushbuttonCalTone_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCalTone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqcaltone();


% --- Executes on button press in pushbuttonAoA.
function pushbuttonAoA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAoA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
iqaoademo();


% --- Executes on button press in pushbuttonNoiseSeq.
function pushbuttonNoiseSeq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonNoiseSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
iqnoiseseq();


% --- Executes on button press in pushbuttonInSystemCal.
function pushbuttonInSystemCal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonInSystemCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
iqmtcal();


% --- Executes on button press in pushbuttonFMCWRadar.
function pushbuttonFMCWRadar_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonFMCWRadar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
if (~isdeployed)
    mypath = fullfile(fileparts(which('iqmain')), 'FMCWRadar');
    addpath(mypath);
end
FMCWRadarGui


% --- Executes on button press in pushbuttonRadarDemoM8195A.
function pushbuttonRadarDemoM8195A_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRadarDemoM8195A (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
iqrsim();


% --- Executes on button press in pushbuttonMultiPulse.
function pushbuttonMultiPulseN5194A_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMultiPulse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
multi_pulse();


% --- Executes on button press in pushbuttonMultiPulse.
function pushbuttonMultiPulseM8121A_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMultiPulse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
multi_pulse();


% --- Executes on button press in pushbuttonKandou.
function pushbuttonKandou_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonKandou (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
iqkandou_gui();


% --- Executes on button press in pushbuttonStreamtool.
function pushbuttonStreamtool_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStreamtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
iqstreamtool();


% --- Executes on button press in pushbuttonDistortion.
function pushbuttonDistortion_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDistortion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadArbConfig();
iqdistgen_gui();


% --------------------------------------------------------------------
function menuShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to menuShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqcorrmgmt();
