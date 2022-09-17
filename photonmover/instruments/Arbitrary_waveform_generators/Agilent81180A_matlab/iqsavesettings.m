function iqsavesettings(handles)
%
% Save the settings of an IQtools window.
% The routine pops up a "Save As" dialog, to get a filename from the user.
% It walks through the GUI elements of the window (pointed to by handles)
% and writes properties such as String, Checked, Enable, Visible to the file.
% The generated file is a text file that contains MATLAB commands.
% In the "Load Settings" routine, these commands are simply evaluated
% to set the window back to the saved state
%
    if (isfield(handles, 'iqtool'))
        h = handles.iqtool;
    elseif (isfield(handles, 'figure1'))
        h = handles.figure1;
    else
        msgbox('Incompatible IQTools utility');
        return;
    end
    if (isfield(handles, 'LastFileName'))
        lastFilename = handles.LastFileName;
    else
        lastFilename = '';
    end
    [filename, pathname] = uiputfile('*.m', 'Save Setting...', lastFilename);
    if (filename ~= 0)
        try
            f = fopen(fullfile(pathname, filename), 'w');
        catch ex
            msgbox(sprintf('Can''t open file: %s', ex.message));
            return;
        end
        % save the path for next time
        handles.LastFileName = pathname;
        guidata(h, handles);
        fprintf(f, '%%\n');
        fprintf(f, '%% Settings for: %s\n', get(h, 'Name'));
        fprintf(f, '%%\n');
        [~, filename, ext] = fileparts(get(h, 'Filename'));
        fprintf(f, 'savedFigure = ''%s%s'';\n', filename, ext);
        fprintf(f, 'errCnt = 0;\n');
        if (~isempty(f))
            % descend the tree of GUI elements recursively
            iqsave2(f, h);
            fclose(f);
        end
    end
end


function iqsave2(f, h)
% recursively walk through he GUI elements and save the properties
    type = get(h, 'Type');
    if (strcmp(type, 'uicontrol'))
        style = get(h, 'Style');
        switch (style)
            case 'edit'
                fprintf(f, 'try\n');
                fprintf(f, '   set(handles.%s, ''String'', ''%s'');\n', get(h, 'Tag'), xquote(get(h, 'String')));
                fprintf(f, '   set(handles.%s, ''Enable'', ''%s'');\n', get(h, 'Tag'), get(h, 'Enable'));
                fprintf(f, '   set(handles.%s, ''Visible'', ''%s'');\n', get(h, 'Tag'), get(h, 'Visible'));
                fprintf(f, 'catch ex; errCnt = errCnt + 1; end\n');
            case { 'checkbox' }
                fprintf(f, 'try\n');
                fprintf(f, '   set(handles.%s, ''Value'', %d);\n', get(h, 'Tag'), get(h, 'Value'));
                fprintf(f, '   set(handles.%s, ''Enable'', ''%s'');\n', get(h, 'Tag'), get(h, 'Enable'));
                fprintf(f, 'catch ex; errCnt = errCnt + 1; end\n');
            case { 'popupmenu' }
                fprintf(f, 'try\n');
                if (strcmp(h.UserData, 'saveList'))
                    % save the whole list of entries plus the value
                    fprintf(f, '   set(handles.%s, ''String'', {', h.Tag);
                    for i=1:length(h.String)
                        if (i ~= 1)
                            fprintf(f, '; ');
                        end
                        fprintf(f, '''%s''', xquote(h.String{i}));
                    end
                    fprintf(f, '});\n');
                    fprintf(f, '   set(handles.%s, ''Value'', %d);\n', get(h, 'Tag'), get(h, 'Value'));
                elseif (strcmp(h.UserData, 'saveString'))
                    % save the string and "search" for it when loading
                    list = h.String;
                    fprintf(f, '   idx = find(strcmp(get(handles.%s, ''String''), ''%s''));\n', h.Tag, list{h.Value});
                    fprintf(f, '   if (idx > 0) set(handles.%s, ''Value'', idx); else errCnt = errCnt + 1; end\n', h.Tag);
                else
                    % save just the value (assumes that the list does not change)
                    fprintf(f, '   set(handles.%s, ''Value'', %d);\n', get(h, 'Tag'), get(h, 'Value'));
                end
                fprintf(f, '   set(handles.%s, ''Enable'', ''%s'');\n', get(h, 'Tag'), get(h, 'Enable'));
                fprintf(f, 'catch ex; errCnt = errCnt + 1; end\n');
            case { 'text' }
                % save text properties only if the tag is not "text" followed by digits
                if (isempty(regexp(get(h, 'Tag'), 'text[0-9]+$', 'ONCE')))
                    fprintf(f, 'try\n');
                    fprintf(f, '   set(handles.%s, ''Enable'', ''%s'');\n', get(h, 'Tag'), get(h, 'Enable'));
                    fprintf(f, '   set(handles.%s, ''Visible'', ''%s'');\n', get(h, 'Tag'), get(h, 'Visible'));
                    fprintf(f, 'catch ex; errCnt = errCnt + 1; end\n');
                end
            case { 'pushbutton' }
                ud = get(h, 'UserData');
                if (~isempty(ud))
                    if (strcmp(ud, 'saveString'))
                        fprintf(f, 'try\n');
                        fprintf(f, '   set(handles.%s, ''String'', ''%s'');\n', get(h, 'Tag'), xquote(get(h, 'String')));
                        fprintf(f, '   set(handles.%s, ''Enable'', ''%s'');\n', get(h, 'Tag'), get(h, 'Enable'));
                        fprintf(f, '   set(handles.%s, ''Visible'', ''%s'');\n', get(h, 'Tag'), get(h, 'Visible'));
                        fprintf(f, 'catch ex; errCnt = errCnt + 1; end\n');
                    elseif (ismatrix(ud) && isreal(ud))
                        % special case for "Channel Mapping" pushbutton:
                        % The channelMapping is stored in the UserData of
                        % this pushbutton
                        fprintf(f, 'try\n');
                        fprintf(f, '   set(handles.%s, ''String'', ''%s'');\n', get(h, 'Tag'), xquote(get(h, 'String')));
                        fprintf(f, '   set(handles.%s, ''UserData'', [', get(h, 'Tag'));
                        for row = 1:size(ud,1)
                            for col = 1:size(ud,2)
                                fprintf(f, ' %g', ud(row,col));
                            end
                            fprintf(f, ';');
                        end
                        fprintf(f, ']);\n');
                        fprintf(f, 'catch ex; errCnt = errCnt + 1; end\n');
                    end
                end
            case { 'radiobutton' }
                fprintf(f, 'try\n');
                fprintf(f, '   set(handles.%s, ''Value'', %d);\n', get(h, 'Tag'), get(h, 'Value'));
                fprintf(f, '   set(handles.%s, ''Enable'', ''%s'');\n', get(h, 'Tag'), get(h, 'Enable'));
                fprintf(f, 'catch ex; errCnt = errCnt + 1; end\n');
            otherwise
                fprintf('unknown tag: %s\n', get(h, 'Tag'));
        end
    elseif (strcmp(type, 'uitable'))
        fprintf(f, 'try\n');
        data = get(h, 'Data');
        colFmt = get(h, 'ColumnFormat');
        fprintf(f, '   data = cell(%d, %d);\n', size(data,1), size(data,2));
        for k=1:size(data,1);
            for l=1:size(data,2);
                val = data{k,l};
                c = colFmt{l};
                if (iscell(c) || strcmp(c, 'char'))
                    fprintf(f, '   data{%d,%d} = ''%s'';\n', k, l, xquote(val));
                elseif (strcmp(c, 'numeric'))
                    if (isempty(val))
                        fprintf(f, '   data{%d,%d} = [];\n', k, l);
                    else
                        fprintf(f, '   data{%d,%d} = %d;\n', k, l, val);
                    end
                elseif (strcmp(c, 'logical'))
                    if (val)
                        fprintf(f, '   data{%d,%d} = true;\n', k, l);
                    else
                        fprintf(f, '   data{%d,%d} = false;\n', k, l);
                    end
                else
                    disp(['unexpected data type in table: ' colFmt]);
                end
            end
        end
        fprintf(f, '   set(handles.%s, ''Data'', data);\n', get(h, 'Tag'));
        fprintf(f, 'catch ex; errCnt = errCnt + 1; end\n');
    elseif (strcmp(type, 'uimenu'))
        fprintf(f, 'try\n');
        fprintf(f, '   set(handles.%s, ''Checked'', ''%s'');\n', get(h, 'Tag'), get(h, 'Checked'));
        fprintf(f, 'catch ex; errCnt = errCnt + 1; end\n');
    end
    % descend to next level of children
    try
        hc = get(h, 'Children');
        for (hi=1:length(hc))
            iqsave2(f, hc(hi));
        end
    catch ex
    end
end


function result = xquote(s)
% translate single quotes to double quotes, so strings are represented correctly
% also, eliminate all non-printable characters
result = regexprep(strrep(s, '''', ''''''), '[\x00-\x1f\x80-\xff]', '');
end
