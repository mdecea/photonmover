function iqloadsettings(handles)
    try
        h = handles.iqtool;
    catch ex
        msgbox('Incompatible IQTools utility');
        return;
    end
    if (isfield(handles, 'LastFileName'))
        lastFilename = handles.LastFileName;
    else
        lastFilename = '';
    end
    [filename, pathname] = uigetfile('*.m;*.fig', 'Load Settings...', lastFilename);
    if (filename ~= 0)
        % save the path for next time
        handles.LastFileName = pathname;
        guidata(h, handles);
        % if user selects a .fig file, assume it is in the old format
        % where simply the whole dialog was saved
        [~, ~, ext] = fileparts(filename);
        if (strcmp(ext, '.fig') || strcmp(ext, '.FIG'))
            try
                cf = gcf;
                hgload(strcat(pathname, filename));
                close(cf);
                msgbox({'You just loaded settings in an old format that is no longer supported.' ...
                    'To convert them to the current format, please save the settings again as' ...
                    'a .m file, close the utility, reopen it and load the file .m file again'});
            catch ex
                errordlg(ex.message);
            end
       else
            try
                f = fopen(strcat(pathname, filename), 'r');
            catch ex
                msgbox('Can''t open file');
                return;
            end
            a = fread(f, inf, 'uint8=>char');
            try
                eval(a);
            catch ex
                msgbox(sprintf('Invalid settings file: %s', ex.message));
                return;
            end
            if (~exist('errCnt', 'var') || ~exist('savedFigure', 'var'))
                msgbox('Invalid settings file: expected variables are not set');
                return;
            end
            [~, filename, ext] = fileparts(get(h, 'Filename'));
            if (~strcmp(savedFigure, strcat(filename, ext)))
                msgbox({'This settings file belongs to a different IQTools utility.'});
                return;
            end
            if (errCnt ~= 0)
                msgbox({'One or more GUI elements could not be loaded.' ...
                    'Please check that the settings file matches the version of the utility'});
            end
        end
    end
end


