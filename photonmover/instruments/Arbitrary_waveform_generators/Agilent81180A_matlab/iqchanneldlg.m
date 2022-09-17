function [val, str] = iqchanneldlg(chMap, arbConfig, parent, style)
%
% open a dialog window where the user can select which AWG channels should
% be used to download the waveform
%
% chMap is a two-dimensional array (rows = channels, cols = I/Q)
% arbConfig is the arbConfig structure
% parent is a handle to the parent window
% style can be 'IQ' or 'single' or a cell array of signal names
%
val = [];
str = [];
xp = 10; % padding
xc = 80; % distance of first checkbox from left of window
xd = 35; % distance between checkboxes
xe = 10; % extra distance between blocks of 4 checkboxes
xf = 9;  % shift of channel label
yp = 10; % padding
yb = 50; % distance of first row of checkboxes from top of window
yd = 25; % distance between checkboxes
yl = 30; % distance of channel label from top of window
yw = 70; % window height without any checkboxes
txth = 17; % height of text controls
buttonw = 70; % botton width
buttonh = 22; % button height
chkboxw = 20; % checkbox width
chkboxh = 20; % checkbox height
if (~exist('chMap', 'var') || isempty(chMap))
    chMap = [1 0; 0 1; 0 0; 0 0];
end
if (~exist('arbConfig', 'var'))
    arbConfig = [];
end
if (~exist('parent', 'var'))
    parent = [];
end
if (~exist('style', 'var'))
    style = 'IQ';
end

% try to position the dialog's OK button on top of the calling button
if (~isempty(parent))
    mypos = get(parent, 'Position');
    p = findPushbuttonChannelMapping(parent);
    if (~isempty(p))
        % put center of OK button on center of channelMapping button
        p(1) = p(1) + floor(p(3)/2) - xp - floor(buttonw/2);
        p(2) = p(2) + floor(p(4)/2) - yp - floor(buttonh/2);
        mypos = mypos + p;
    end
else
    mypos = [300 300, 0, 0];
end

arbConfig = loadArbConfig(arbConfig);
ducMode = ~isempty(strfind(arbConfig.model, 'DUC'));
% make sure that in DUC mode, I&Q are identical
if (ducMode)
    chMap(:,2) = chMap(:,1);
end
% uncheck masked channels
chMap(arbConfig.channelMask == 0) = 0;
% number of checkboxes in each row is determined by the number of channels (= #rows in channelmap)
nChkbox = size(chMap, 1);
% determine the number of rows of checkboxes
if (iscell(style))
    rowLabels = style;
    nRows = length(style);
    colIdx = 1:2:2*nRows;
elseif (strcmp(style, 'IQ'))
    rowLabels = {'Real (I)', 'Imag (Q)'};
    nRows = 2;
    colIdx = [1 2];
else
    rowLabels = {'Download to'};
    nRows = 1;
    colIdx = 1;
end
% make sure that channel map array is large enough
if (size(chMap, 2) < 2*nRows)
    chMap(:,2*nRows) = zeros(size(chMap,1),1);
end
% uncheck channels that don't exist
chMap(arbConfig.channelMask == 0, :) = 0;
% calculate the width and height of the window
mypos(3) = max(xc + (nChkbox-1)*xd + chkboxw + xp + floor((nChkbox-1)/4)*xe, ...
               3*xp + 2*buttonw);
mypos(4) = yw + nRows * yd;
% create the dialog
d = dialog('Position', mypos, 'Name', 'Channel Mapping');
% create the row labels
for j = 1:nRows
    uicontrol('Parent', d, 'Style', 'text', ...
        'HorizontalAlignment', 'left', 'FontUnits', 'pixels', ...
        'Position', [xp yw-yb+(nRows-j+1)*yd xc-xp txth], 'String', rowLabels{j});
end
chkbox = zeros(nChkbox, nRows);
for i = 1:nChkbox
    if (i <= length(arbConfig.channelMask) && arbConfig.channelMask(i) ~= 0)
        cqEnable = 'on';
    else
        cqEnable = 'off';
    end
    % create the checkboxes
    for j = 1:nRows
        chkbox(i,j) = uicontrol('Parent', d, 'Style', 'checkbox', 'FontUnits', 'pixels', ...
            'Position', [xc + (i-1)*xd + floor((i-1)/4)*xe, yw-yb+(nRows-j+1)*yd, chkboxw, chkboxh], 'String', '', ...
            'Value', chMap(i,colIdx(j)), 'UserData', [i, j], 'Enable', cqEnable, 'Callback', @chkbox_Callback);
    end
    % create the channel labels
    uicontrol('Parent', d, 'Style', 'text', ...
        'HorizontalAlignment', 'center', 'FontUnits', 'pixels', ...
        'Position', [xc + (i-1)*xd + floor((i-1)/4)*xe - xf, yw + nRows*yd - yl, xd, txth], ...
        'String', sprintf('Ch%d', i));
end
% create the OK and Cancel buttons
uicontrol('Parent', d, ...
    'Position',[xp yp buttonw buttonh], 'String', 'Ok', ...
    'FontUnits', 'pixels', 'Callback', @btnOk_Callback);
uicontrol('Parent', d, ...
    'Position',[2*xp+buttonw yp buttonw buttonh], 'String', 'Cancel', ...
    'FontUnits', 'pixels', 'Callback', 'delete(gcf())');
% Wait for d to close before running to completion
uiwait(d);


function btnOk_Callback(~, ~)
    if (strcmp(style, 'IQ'))
        val = zeros(size(chMap,1), 2);
    else
        val = zeros(size(chMap));
    end
    for k = 1:nChkbox
        for r = 1:nRows
            val(k,colIdx(r)) = get(chkbox(k,r), 'Value');
        end
    end
    str = iqchannelsetup('mkstring', val, [], style);
    delete(gcf());
end



function chkbox_Callback(hObject, ~)
    idx = get(hObject, 'UserData');
    if (ducMode)
        % make sure that I & Q are both check or both unchecked
        set(chkbox(idx(1), 3-idx(2)), 'Value', get(hObject, 'Value'));
    else
        % don't allow multiple boxes checked in the same column
        if (get(hObject, 'Value'))
            for m = 1:nRows
                if (m ~= idx(2))
                    set(chkbox(idx(1), m), 'Value', 0);
                end
            end
        end
    end
end

end



function pos = findPushbuttonChannelMapping(parent)
% find the position of the pushbuttonChannelMapping relative to the lower
% left corner of the window
ch = get(parent, 'Children');
for i1 = 1:length(ch)
    h = ch(i1);
    type = get(h, 'Type');
    % find inside containers
    if (strcmp(type, 'uibuttongroup') || strcmp(type, 'uipanel'))
        pos = findPushbuttonChannelMapping(h);
        if (~isempty(pos))
            px = get(h, 'Position');
            % add x/y offset of container to get position relative to window
            % pass width and height of pushbutton unchanged
            pos(1:2) = pos(1:2) + px(1:2);
            return;
        end
    else
        tag = get(h, 'Tag');
        if (strcmp(tag, 'pushbuttonChannelMapping'))
            pos = get(h, 'Position');
            return;
        end
    end
end
pos = [];
end
