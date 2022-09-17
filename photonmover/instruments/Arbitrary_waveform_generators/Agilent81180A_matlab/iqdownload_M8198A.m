function result = iqdownload_M8198A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, chMap, sequence, run)
% Download a waveform to the M8198A
% It is NOT intended that this function be called directly, only via iqdownload
%
% B.Krueger, Th.Dippon, Keysight Technologies 2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    result = [];
    if (~isempty(sequence))
        errordlg('Sorry, M8198A does not have a sequencer yet');
        return;
    end

    % open the VISA connection
    f = iqopen(arbConfig);
    f.Timeout = 3;
    if (isempty(f))
        return;
    end
    result = f;
    
    % if multi-module configurations, call slave M8198A download routines
    if (isfield(arbConfig, 'amplitude'))
        chIdx = find(arbConfig.channelMask);
        ampTmp = zeros(1, length(arbConfig.channelMask));
        ampTmp(chIdx) = fixlength(arbConfig.amplitude, length(chIdx));
    else
        ampTmp = [];
    end
    if (isfield(arbConfig, 'offset'))
        chIdx = find(arbConfig.channelMask);
        offTmp = zeros(1, length(arbConfig.channelMask));
        offTmp(chIdx) = fixlength(arbConfig.offset, length(chIdx));
    else
        offTmp = [];
    end
    cpm = 1; % channels per module
    for m = 4:-1:2
        va = sprintf('visaAddr%d', m);
        if (size(chMap, 1) > cpm*(m-1) && isfield(arbConfig, va))
            arbTmp = arbConfig;
            arbTmp.visaAddr = arbTmp.(va);
            arbTmp.setupSlave = 1;
            if (~isempty(ampTmp))
                arbTmp.amplitude = ampTmp(cpm*(m-1)+1:min(cpm*m,size(chMap,1)));
            end
            if (~isempty(offTmp))
                arbTmp.offset = offTmp(cpm*(m-1)+1:min(cpm*m,size(chMap,1)));
            end
            result = iqdownload_M8198A(arbTmp, fs, data, marker1, marker2, segmNum, keepOpen, chMap(cpm*(m-1)+1:min(cpm*m,size(chMap,1)),:), sequence, run);
        end
    end
    % don't try to download more than 2 channels in first module
    %chMap(cpm+1:end,:) = [];
    
    % direct mode waveform download
    for col = 1:size(chMap, 2) / 2
        for ch = find(chMap(1:cpm, 2*col-1))'
            gen_arb_M8198A(arbConfig, f, ch, real(data(:,col)), marker1, segmNum, run);
        end
        for ch = find(chMap(1:cpm, 2*col))'
            gen_arb_M8198A(arbConfig, f, ch, imag(data(:,col)), marker2, segmNum, run);
        end
    end
    
    if (run == 1 && sum(sum(chMap)) ~= 0)
%         fprintf(f, ':INIT:IMMediate');
    end
    
    % check alignment between DACs
    if (~isfield(arbConfig, 'setupSlave') && isfield(arbConfig, 'visaAddr2'))
        fprintf('aligment\n');
        if (isfield(arbConfig, 'visaAddrScope'))
            fscope = iqopen(arbConfig.visaAddrScope);
            fscope.Timeout = 3;
            if (~isempty(fscope))
                
                f1 = f;
                f2 = iqopen(arbConfig.visaAddr2);
                
                benny_active = 1 ; 
                if benny_active == 1
                    %% Begin BK
                    fprintf('Start with barrel shifter adjustment \n');
                    % For barrel shifter adjustment, ensure that MRK period
                    % is equal to pattern period

%                     % Stop waveform MRK playback for both DACs
%                     cmd = sprintf('DIAG:DIR:BLOC 10,#hC010C,32,0,0,0') ;  
%                     xfprintf(f1, cmd);
%                     xfprintf(f2, cmd);

                    % ensure waveform playback is stopped
                    cmd = sprintf(':diagnostic:hdtest? 1100') ; 
                    xquery(f1, cmd);
                    xquery(f2, cmd);
                    
                    % Construct pattern string for marker
                    marker_adjust = uint16(zeros(length(data),1)) ;
                    marker_adjust(1:length(marker_adjust)/2) = 3 ; 

                    patternstringmarker_adjust = formatMarkerString(marker_adjust) ; 

                    % write the marker into Sirius' waveform memory
                    cmd = sprintf('DIAG:DIR:BLOC 10,#hA0000%s', patternstringmarker_adjust);
                    xfprintf(f1, cmd);
                    xfprintf(f2, cmd);
                    fprintf('patternstringmarker_adjust  = %s\n', patternstringmarker_adjust);
                    % Setup waveform length in vectors
                    cmd = sprintf(':diagnostic:hdtest? 1101, ''%d %d'' ', size(data,1)/256, length(marker_adjust)/256) ; 
                    xquery(f1, cmd);
                    xquery(f2, cmd);
                    % Start waveform playback
                    cmd = sprintf(':diagnostic:hdtest? 1102') ;
                    xquery(f1, cmd);
                    xquery(f2, cmd);
%                     % Start MRK playback
%                     cmd = sprintf('DIAG:DIR:BLOC 10,#hC010C,2,0,0,0');
%                     xfprintf(f1, cmd);
%                     xfprintf(f2, cmd);
                    
      

                    % calls which may be used sometimes...
    % % % %                 
    % % % % %                 fprintf(f, 'DIAG:DIR:BLOC 10,#hC010C,1,0,0,0');   % start data
    % % % % %                 fprintf(f, 'DIAG:DIR:BLOC 10,#hC010C,2,0,0,0');   % start marker
    % % % % %                 fprintf(f, 'DIAG:DIR:BLOC 10,#hC010C,16,0,0,0');  % stop data
    % % % % %                 fprintf(f, 'DIAG:DIR:BLOC 10,#hC010C,32,0,0,0');  % stop marker
    % % % %                 

                    % End BK
                end
                %%
                v1 = readBarrel(f1);
                v2 = readBarrel(f2);
                v1 = bitand(v1, 255);
                v2 = bitand(v2, 255);
                writeBarrel(f1, v1);
                writeBarrel(f2, v2);
                meas = measSkew(fscope);
                while (abs(meas) > 1e-9)
                    if (abs(meas) >= 7e-9)
                        cmd = sprintf(':diagnostic:hdtest? 1100') ; 
                        xquery(f, cmd);
                        cmd = sprintf(':diagnostic:hdtest? 1102') ; 
                        xquery(f, cmd);
                        fprintf('Restart memory\n') ; 
                    else
                        if (meas > 0)
                            ticks = round(meas / 2e-9);
                            v1 = v1 + 256 * ticks;
                            writeBarrel(f1, v1);
                        else
                            ticks = round(-meas / 2e-9);
                            v2 = v2 + 256 * ticks;
                            writeBarrel(f2, v2);
                        end
                    end
                    meas = measSkew(fscope);
                end
                % Set MRK output
                patternstringmarker = formatMarkerString(marker1) ;
                % Stop MRK
                cmd = sprintf('DIAG:DIR:BLOC 10,#hC010C,32,0,0,0');  % stop marker
                xfprintf(f1, cmd);
                xfprintf(f2, cmd);
                % Setup waveform length in vectors
                cmd = sprintf(':diagnostic:hdtest? 1101, ''%d %d'' ', size(data,1)/256, length(marker_adjust)/256) ; 
                xquery(f1, cmd);
                xquery(f2, cmd);
                % write the marker into Sirius' waveform memory
                cmd = sprintf('DIAG:DIR:BLOC 10,#hA0000%s', patternstringmarker);
                xfprintf(f1, cmd);
                xfprintf(f2, cmd);
                % Start MRK
                cmd = sprintf('DIAG:DIR:BLOC 10,#hC010C,2,0,0,0');
                xfprintf(f1, cmd);
                xfprintf(f2, cmd);
            end
        end
    end
    
    
    
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end
end

function meas = measSkew(fscope)    
    fprintf(fscope, ':timebase:scale 2e-9');
    fprintf(fscope, ':meas:clear');
    fprintf(fscope, ':meas:deltatime chan1,chan3');
    fprintf(fscope, sprintf(':meas:stat on'));
    pause(1);
    query(fscope, 'ader?') ; 
    measStr = query(fscope, ':meas:results?') ; 
    measList = eval(['[' measStr(12:end-1) ']']);
    meas = measList(4);   % mean
    if (abs(meas) > 1e37)
        fprintf('invalid measurement\n');
    else
        fprintf('deltatime = %g\n', meas);
    end
end


function res = readBarrel(f)
res = str2double(query(f, ':DIAG:REG? 536874917'));
end


function writeBarrel(f, val)
if (val >= 0 && val <= 1023)
    fprintf(f, ':DIAG:REG 536874917,%d\n', val);
    fprintf(f, ':DIAG:REG 536874916,%d\n', val);
else
    errordlg('Barrel shifter val out of range');
    error('Barrel shifter val out of range');
end
end



function gen_arb_M8198A(arbConfig, f, chan, data, marker, segm_num, run)
% download an arbitrary waveform signal to a given channel and segment
    if (isempty(chan) || ~chan)
        return;
    end
    segm_len = length(data);
    if (segm_len > 0)        
        % ensure waveform playback is stopped
        cmd = sprintf(':diagnostic:hdtest? 1100') ; 
        xquery(f, cmd);
        
        
        % scale to DAC values and shift negative values (data is assumed to
        % be -1 ... +1)
        data = round(127 * real(data));
        data(data<0) = data(data<0)+256 ; 
        
%          figure ; hold all ; 
%          plot(data) ; 
%          plot(marker) ; 
        
        % Construct pattern string for waveform
        patternString = sprintf(',%d',data) ; 
        
        % Construct pattern string for marker
        patternstringmarker = '' ; 
        marker = bitand(marker, 1);
        % AND with '1' (MARKER BIT for two markers)
        for i = 1:length(marker)/8
           curr_byte = 0 ; 
           for bitPos = 1:8
               curr_byte = curr_byte + 2^(bitPos-1)*marker(8*(i-1)+bitPos);
           end
            patternstringmarker = strcat(patternstringmarker, sprintf(',%d', curr_byte)) ; 
        end
        
        fprintf('patternString = %s\n', patternString);
        fprintf('patternstringmarker  = %s\n', patternstringmarker);
                 
        % write the pattern into Sirius' waveform memory
        cmd = sprintf('DIAG:DIR:BLOC 10,#h80000%s', patternString) ; 
        xfprintf(f, cmd);
        % write the marker into Sirius' waveform memory
        cmd = sprintf('DIAG:DIR:BLOC 10,#hA0000%s', patternstringmarker);
        xfprintf(f, cmd);
        
        % Setup waveform length in vectors
        %cmd = sprintf(':diagnostic:hdtest? 1101 '%d %d' ', length(data)/arbConfig.segmentGranularity, length(marker)/arbConfig.segmentGranularity) ; 
        cmd = sprintf(':diagnostic:hdtest? 1101, ''%d %d'' ', length(data)/256, length(marker)/256) ; 
        xquery(f, cmd);
        
        % Start waveform playback
        cmd = sprintf(':diagnostic:hdtest? 1102') ; 
        xquery(f, cmd);
    end
end



function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, numel(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
end



function xbinblockwrite(f, data, format, cmd)
% set debugScpi=1 in MATLAB workspace to log SCPI commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s %s, %d elements\n', cmd, format, length(data));
    end
    binblockwrite(f, data, format, cmd);
    fprintf(f, '');
end


function retVal = xquery(f, s)
% send a query to the instrument object f
    retVal = query(f, s);
% set debugScpi=1 in MATLAB workspace to log SCPI commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        if (length(retVal) > 60)
            rstr = sprintf('%s... (total %d chars)', retVal(1:60), length(retVal));
        else
            rstr = retVal;
        end
        fprintf('qry = %s -> %s\n', s, strtrim(rstr));
    end
end


function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, -1 for errors

    retVal = 0;
% set debugScpi=1 in MATLAB workspace to log SCPI commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s\n', s);
    end
    fprintf(f, s);
    result = query(f, ':syst:err?');
    if (isempty(result))
        fclose(f);
        errordlg({'The M8198A firmware did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'}, 'Error');
        retVal = -1;
        return;
    end
    if (~exist('ignoreError', 'var') || ignoreError == 0)
        while (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
            errordlg({'M8198A firmware returns an error on command:' s 'Error Message:' result});
            result = query(f, ':syst:err?');
            retVal = -1;
        end
    end
end


function patternString = formatMarkerString(marker)
    patternString = '' ; 
    marker = bitand(marker, 1);
    % AND with '1' (MARKER BIT for two markers)
    for i = 1:length(marker)/8
       curr_byte = 0 ; 
       for bitPos = 1:8
           curr_byte = curr_byte + 2^(bitPos-1)*marker(8*(i-1)+bitPos);
       end
        patternString = strcat(patternString, sprintf(',%d', curr_byte)) ; 
    end

end
