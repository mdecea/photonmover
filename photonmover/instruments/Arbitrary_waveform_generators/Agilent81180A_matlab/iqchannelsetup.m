function str = iqchannelsetup(cmd, pbcm, arbConfig, type)
% helper function for channel mapping dialog
% cmd - one of 'setup', 'mkstring', 'arraystring' (see comments below)
% pbcm - pushbutton handle (when cmd = 'setup')
%        channelMapping (when cmd = 'mkstring' or 'arraystring')
% arbConfig - the current arbConfig struct
% type - 'single' or 'IQ' or cellarray that contains the names of signals
%
% The "UserData" property of the channel mapping pushbutton is used to
% store the current channel mapping array
%
% Depending on the 'cmd' argument, this following function is performed:
% cmd = 'setup':
%   initilizes the "UserData" property of the pushbutton with a default
%   channelMapping array and sets the "String" property of the pushbutton
%   to a textual description of the channelMapping
% cmd = 'mkstring':
%   converts channelMapping array into a human readable string (this is 
%   used as the "String" property of the pushbutton
% cmd = 'arraystring'
%   converts the channelMapping array into a string representation that
%   can be used in "Generate MATLAB code"
%
if (~exist('type', 'var'))
    type = 'IQ';
end
switch (cmd)
    % set up the UserData with channelMapping array and String fields of the pushbutton
    % according to the selected AWG model and operation mode
    case 'setup'
        ud = get(pbcm, 'UserData');
        if (isempty(ud))
            % channel mapping is not defined at all yet -> set default values
            if (length(arbConfig.channelMask) > 4)
                ud = [arbConfig.channelMask; zeros(size(arbConfig.channelMask))]';
            elseif (iscell(type))
                ud = zeros(length(arbConfig.channelMask), 2*length(type));
                for i = 1:length(type)
                    if (i <= length(arbConfig.channelMask))
                        ud(i, 2*i-1) = 1;
                    end
                end
            elseif (arbConfig.numChannels >= 4 || ...
                (~isempty(strfind(arbConfig.model, 'M8190A')) && isfield(arbConfig, 'visaAddr2')))
                ud = [1 0; 1 0; 0 1; 0 1];
            elseif (arbConfig.numChannels >= 3)
                ud = [1 0; 0 1; 0 0];
            elseif (arbConfig.numChannels >= 2)
                if (strcmp(arbConfig.model, 'M8195A_2ch') || strcmp(arbConfig.model, 'M8195A_2ch_256k'))
                    ud = [1 0; 0 0; 0 0; 0 1];
                elseif (strcmp(arbConfig.model, 'M8195A_2ch_mrk'))
                    ud = [1 0; 0 1; 0 0; 0 0];
                elseif (~isempty(strfind(arbConfig.model, 'M8121A')))
                    ud = [1 0; 0 0];
                else
                    ud = [1 0; 0 1];
                end
            else
                ud = [1 0];
            end
        else
            % channel mapping is already defined,
            % make sure the length matches the current channelMask
            if (size(ud,1) > length(arbConfig.channelMask))
                ud(length(arbConfig.channelMask)+1:end, :) = [];
            end
            if (size(ud,1) < length(arbConfig.channelMask))
                ud(length(arbConfig.channelMask), :) = 0;
            end
            if (iscell(type))
                width = 2*length(type);
            else
                width  = 2;
            end
            if (size(ud,2) > width)
                ud(:, width+1:end) = [];
            end
            if (size(ud,2) < width)
                ud(:, width) = 0;
            end
            % uncheck channels that don't exist
            ud(arbConfig.channelMask == 0, :) = 0;
        end
        % don't do pulses on all channels...
%         if (strcmp(type, 'pulse') && length(ud) == 4)
%             ud = [1 0; 0 0; 0 0; 0 1];
%         end
        duc = (~isempty(strfind(arbConfig.model, 'DUC')));
        if (duc)
            ud(:,1) = (ud(:,1) + ud(:,2)) ~= 0;
            ud(:,2) = ud(:,1);
        else
            idx = find(ud(:,1) .* ud(:,2));
            idx1 = idx;
            idx1(mod(idx,2)~=0) = [];
            ud(idx1,1) = 0;
            idx2 = idx;
            idx2(mod(idx,2)==0) = [];
            ud(idx2,2) = 0;
        end
        if (ischar(type) && strcmp(type, 'single'))
            ud(:,1) = (ud(:,1) + ud(:,2) > 0);
            ud(:,2) = 0;
        end
        set(pbcm, 'UserData', ud);
        set(pbcm, 'String', iqchannelsetup('mkstring', ud, arbConfig, type));
    % convert channelMapping into a string that is displayed on the download pushbutton
    case 'mkstring'
        if (~isempty(pbcm))
            if (iscell(type))
                rowLabels = type;
                pad2 = '=';
                nRows = length(type);
                colIdx = 1:2:2*nRows;
            elseif (strcmp(type, 'IQ'))
                rowLabels = {'I', 'Q'};
                pad2 = '=';
                nRows = 2;
                colIdx = [1 2];
            else % 'single'
                rowLabels = {''};
                pad2 = '';
                nRows = 1;
                colIdx = 1;
            end
            % make sure that pbcm contains at least max(colIdx) columns
            if (size(pbcm, 2) < max(colIdx))
                pbcm(:,max(colIdx)) = zeros(size(pbcm,1), 1);
            end
            str = '';
            pad1 = '';
            for i = 1:nRows
                chs1 = find(pbcm(:,colIdx(i)));
                if (~isempty(chs1))
                    str = sprintf('%s%s%s%sCh', str, pad1, rowLabels{i}, pad2);
                    pad1 = '; ';
                    if (length(chs1) > 1)
                        str = sprintf('%s%s', str, sprintf('%d,', chs1(1:end-1)));
                    end
                    str = sprintf('%s%s', str, sprintf('%d', chs1(end)));
                end
            end
            str = sprintf('%s...', str);    % indicate that a dialog will pop up when clicked
        else
            str = '...';
        end
    % convert channelMapping into a string for the "Generate MATLAB code" function
    case 'arraystring'
        str = '[';
        for i=1:size(pbcm,1)
            str = sprintf('%s%s', str, sprintf('%d ', pbcm(i,:)));
            str(end) = [];
            if (i ~= size(pbcm,1))
                str = sprintf('%s; ', str);
            end
        end
        str = sprintf('%s]', str);
end

