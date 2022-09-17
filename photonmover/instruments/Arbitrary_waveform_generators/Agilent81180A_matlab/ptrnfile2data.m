%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   v0.5
%   Read PTRN/TXT file and return binary data
%
%   [fileCharData] = ptrnfile2data('fileName')
%   input parameter:    string file name (Optional)
%   output parameter:   bits in the file
%
%   Author: Muhammad Butt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fileCharData] = ptrnfile2data(fileName)

Formatting = {'Version='        ...     % Parameters used in PTRN format
    'Format='         ...
    'Description='    ...
    'Count='          ...
    'Length='         ...
    'Use='            ...
    'Pack='           ...
    'Data='           ...
    };
checkFormattingDATA = cell(8,1);        % to store parameter values

expn = 0;
badfile = 0;      % bad file format check
txtfile = 0;
%fileName = 'CEIstress.ptrn';    %
%fileName = 'CRPAT.ptrn';
if (nargin == 0)
    [filename, pathname] = uigetfile({'*.ptrn;*.txt'},'Select a *.ptrn file');
    if filename ~= 0
        fileName = strcat(pathname, filename);
    else
        badfile = 1;
    end
end

k = strfind(fileName,'.');
if isempty(k)
    errordlg('No file extension found',...
        'Error Message PTRNfile');
    badfile = 1;
end
ext = fileName(k:end);

if ~badfile
    if strcmp(ext,'.txt')
        txtfile = 1;
    end
    fid = fopen(fileName, 'r');             % open to read file
    if fid == -1
        errordlg(sprintf('Can''t open %s', fileName),...
            'Error Message PTRNfile');
        badfile = 1;
    end
    dis = sprintf('File name is %s\n',fileName);
    %    disp(dis);
    
    if ~badfile
        if ~txtfile
            found = 0;
            while found ~= 2
                str = fgetl(fid);
                if (~ischar(str))   % end of file
                    break;
                end
                found = 0;
                for i=1:length(Formatting)
                    lengF = length(Formatting{i});   % length of each format string
                    if strncmp(str, Formatting{i}, lengF)    % compare if we aligned with the format
                        checkFormattingDATA{i} = str(lengF+1:end);
                        if (i == length(Formatting))
                            found = 2;  % Data keyword
                        else
                            found = 1;  % other keyword
                        end
                        break;
                    end
                end
                if (~found)
                    % errordlg(sprintf('unexpected keyword (%s)', str), 'Error Message PTRNfile');
                    % badfile = 1;
                end
                if (found == 2)
                    break;
                end
            end
            if (found ~= 2)
                badfile = 1;
            end
        end
    end

    if (~isempty(checkFormattingDATA{7}))
        switch str2double(checkFormattingDATA{7})
            case 1; checkFormattingDATA{2} = 'Dual';
            case 4; checkFormattingDATA{2} = 'Hex';
            case 8; checkFormattingDATA{2} = 'Bin';
            otherwise
                errordlg(sprintf('unknown packing format: %s', checkFormattingDATA{7}));
                badfile = 1;
        end
    end
    if ~badfile         % don't go further if there is some error in format
        if ~txtfile
            dataChar = fread(fid, inf)';        % read rest of the data from the file
            fclose(fid);                        % close the file

            if checkFormattingDATA{4} == '2'        % if count parameter is 2
                if expn
                    adjs = 2;
                else
                    adjs = 1;
                end
                k = strfind(dataChar,Formatting{end});  % then we have duplicate data in file
                dataChar=dataChar(1:k-adjs);
            end
            
            switch char(checkFormattingDATA{2})
                case 'Bin'
                    byteCurrection = mod(str2double(checkFormattingDATA{5}),8);
                    if byteCurrection ~= 0
                        byteCurrection = 8 - byteCurrection;
                    end
                    
                    if checkFormattingDATA{5} == num2str( (length(dataChar)*8) - byteCurrection)
                        % just check if the length of
                        % data read from file is
                    else           % equal as stated in the file parameter
                        errordlg(dis, 'Error Message PTRNfile');
                    end
                    
                    fileCharData = [];              % this will convert all the characters and place
                    dtemp = dec2bin(dataChar,8)';
                    fileCharData=dtemp(:)'-'0';
                    fileCharData = fileCharData(1:end-byteCurrection);
                    %%%%%%%%%% end of case 'Bin'
                    
                case 'Dual'
                    fileCharData = zeros(1, length(dataChar));
                    count = 0;
                    for j=1:length(dataChar)        % in a variable 'data' as bit pattren
                        switch dataChar(j)
                            case '1'
                                count = count+1;
                                fileCharData(count) = 1;
                            case '0'
                                count = count+1;
                                fileCharData(count) = 0;
                            case { 10, 13 }
                                % ignore CRLF
                            otherwise
                                dis = sprintf('unexpected character in file at bit position %d', count);
                                errordlg(dis, 'Error Message PTRNfile');
                                break;
                        end
                    end
                    if (~isempty(checkFormattingDATA{5}) && str2double(checkFormattingDATA{5}) ~= count)
                        errordlg(sprintf('Length mismatch: header %d vs. data %d', str2double(checkFormattingDATA{5}), count), 'Error Message PTRNfile');
                    end
                    %%%%% end of case 'Dual'
                    
                case {'Hex','Text'}
                    tempData = dataChar;     % remove white spaces
                    dataChar = [];
                    for i=1:length(tempData)
                        if tempData(i) == ' ' || tempData(i) == 10 || tempData(i) == 13
                        else
                            dataChar = [dataChar,tempData(i)];
                        end
                    end
                    
                    byteCurrection = mod(str2double(checkFormattingDATA{5}),4);
                    if byteCurrection ~= 0
                        byteCurrection = 4 - byteCurrection;
                    end
                    if checkFormattingDATA{5} == num2str( (length(dataChar)*4) - byteCurrection)
                    else
                        errordlg(dis, 'Error Message PTRNfile');
                    end
                    fileCharData = [];                                  % this will convert all the characters and place
                    fileCharData = hexToBinaryVector(char(dataChar));   % every bit in separately
                    fileCharData = fileCharData(1:end-byteCurrection);  %
                    %%%%% end of case 'Hex','Text'
                    
                case 'Symbol'
                otherwise
                    errordlg('other format', 'Error Message PTRNfile');
                    %%%%%%%%%%%%%  for other formats
            end
            %%%%% end of Switch statement for different formates
            
        else        %%% for txt file 0s and 1s with white space separation
                    %%% also accept decimal values between 0 and 1 to
                    %%% support PAM-n signals
            fileCharData = fscanf(fid, '%f');
            fclose(fid);
            % if max value is > 1, scale to 0...1 range
            if (max(fileCharData) > 1)
                fileCharData = fileCharData ./ max(fileCharData);
            end
            if (min(fileCharData) < 0)
                errordlg('Expect data file to contain values between 0 and N');
            end
        end     %%% end of txt file
        
        
        %%%%% if bad formate detected
    else            % if any bad file format error occur then come here
        fileCharData = [];
        if fid ~= -1
            fclose(fid);
        end
    end
else                % if no file selected
    fileCharData = [];
end


fclose('all');


end
