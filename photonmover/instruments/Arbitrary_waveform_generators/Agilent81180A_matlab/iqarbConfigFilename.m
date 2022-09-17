function filename = iqarbConfigFilename()
% returns the name of the file in which the IQtools configuration is stored

global arbConfigFilename;

basename = 'arbConfig.mat';
% first, check if we already have a location
if (exist('arbConfigFilename', 'var') && ~isempty(arbConfigFilename))
    filename = arbConfigFilename;
else
    filename = ['c:\' basename];
    try
        user = getenv('username');
        tmpDir = fullfile('C:\Users', user, 'AppData', 'Local', 'Keysight');
        if (exist(tmpDir, 'dir') == 0)
            mkdir(tmpDir);
        end
        tmpDir = fullfile(tmpDir, 'iqtools');
        if (exist(tmpDir, 'dir') == 0)
            mkdir(tmpDir);
        end
        filename = fullfile(tmpDir, basename);
    catch ex
        errordlg(sprintf('Error accessing configuration file path: %s\n', ex.message));
        error(sprintf('Error accessing configuration file path: %s\n', ex.message));
    end
    % save in global variable
    arbConfigFilename = filename;
end
