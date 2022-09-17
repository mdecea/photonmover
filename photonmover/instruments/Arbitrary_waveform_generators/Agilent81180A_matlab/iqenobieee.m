function ENOB = iqenobieee(visa_addr_awg, visa_addr_dca, tones, fsAWG, awg_channels, awg_trig, ...
    scopechannels, scopeRST, autoScopeAmpl, scopeAmpl, scopeAvg, analysisAvg, bandwidth, ...
    hMsgBox, axesHandles, oldResults, lgText)
% iqenobieee makes and ENOB measurement over frequency using
% a DCA according to IEEE 1658-2011. 
% 
% As the algorithm requires pattern lock, the DCA needs an external trigger.
% Moreover a timebase reference is used to increase jitter performance. Both
% signals are generated with the AWG along with the test signals. 
% Tested with 86118A and 84
%
% M. Schulz, Keysight Technologies, 2015
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 


    % AWG
    amplitude = 0.5;   % the single-ended output amplitude in V

    % connections
    dca_meas_channel     = scopechannels{1};   % the channel to which the AWG is connected
    awg_meas_channel     = awg_channels(1);    % the channel to output the measurement signal
    awg_timebase_channel = awg_trig;           % the channel to output the timebase signal
    awg_trigger_channel  = awg_trig;           % the channel to output the trigger signal

    % DCA
    Nshots        = 6;     % the number of shots to take, important to avoid holes caused by using the precision timebase
    Navg          = scopeAvg;     % some averaging is allowed according to the standard and this value seems to give stable results
    spb           = 24;    % the samples per bit to be acquired
    dca_mem_depth = 16384; % the DCA's available amount of memory
    % ---

    
 %% MEASUREMENT SECTION
    
    % set some variables if using the DCA's differential channel
    if ~isempty(strfind(dca_meas_channel, 'DIFF'))
        dca_diff_mode = 1;
        dca_channel_id = dca_meas_channel;
    else
        dca_diff_mode = 0;
        dca_channel_id = strcat('CHAN',dca_meas_channel);
    end
    % ---
    
    if (~isempty(hMsgBox))
        waitbar(0.01, hMsgBox, 'Trying to connect to AWG...');
    end
    % initialize the instrument connection
    awg = iqopen(visa_addr_awg);
    awg.Timeout = 30;
    if (isempty(awg) || (~isempty(hMsgBox) && getappdata(hMsgBox, 'cancel')))
        return;
    end

    dca = iqopen(visa_addr_dca);
    dca.Timeout = 240;
    if (isempty(dca) || (~isempty(hMsgBox) && getappdata(hMsgBox, 'cancel')))
        return;
    end
    % ---
    
    if (~isempty(hMsgBox))
        waitbar(0.02, hMsgBox, 'Setting up timebase...');
    end
    try
        % generate the trigger and timebase waveform
        [trig_samples,ftrig] = TriggerGenerator(fsAWG);
        % ---

        % set the AWG sample rate
        fprintf(awg, 'ABOR');
        fprintf(awg, sprintf('FREQ:RAST %e ',fsAWG));
        % ---

        % set up the timebase channel
        fprintf(awg, sprintf(':TRAC%d:DEL 1',awg_timebase_channel));
        fprintf(awg, sprintf(':TRAC%d:DEF 1,%d,0',awg_timebase_channel,length(trig_samples)));
        binblockwrite(awg,trig_samples,'int8',sprintf(':TRAC%d:DATA 1,0,',awg_timebase_channel));
        fprintf(awg, '\n'); % terminate the write operation
        fprintf(awg, sprintf('VOLT%d 0.5',awg_timebase_channel)); % use 1V amplitude
        fprintf(awg, sprintf('OUTP%d ON',awg_timebase_channel));
        % ---

% we use the same channel (P/N) for trigger and timebase so this is redundant
%         % setup the trigger channel
%         fprintf(awg, sprintf(':TRAC%d:DEL 1',awg_trigger_channel));
%         fprintf(awg, sprintf(':TRAC%d:DEF 1,%d,0',awg_trigger_channel,length(trig_samples)));
%         binblockwrite(awg,trig_samples,'int8',sprintf(':TRAC%d:DATA 1,0,',awg_trigger_channel));
%         fprintf(awg, '\n'); % terminate the write operation
%         fprintf(awg, sprintf('VOLT%d 0.5',awg_trigger_channel)); % use 1V amplitude
%         fprintf(awg, sprintf('OUTP%d ON',awg_trigger_channel));
%         % ---

        % generate the first test tone for initialization
        samples = SineWaveGenerator(fsAWG,tones(1),dca_mem_depth);
        % ---

        % set up the measurement channel
        fprintf(awg, sprintf(':TRAC%d:DEL 1',awg_meas_channel));
        fprintf(awg, sprintf(':TRAC%d:DEF 1,%d,0',awg_meas_channel,length(samples)));
        binblockwrite(awg,samples,'int8',sprintf(':TRAC%d:DATA 1,0,',awg_meas_channel));
        fprintf(awg, '\n'); % terminate the write operation
        fprintf(awg, sprintf('VOLT%d %f',awg_meas_channel,amplitude));
        fprintf(awg, sprintf('OUTP%d ON',awg_meas_channel));
        opc = query(awg,':INIT:IMM; *OPC?'); %#ok<*NASGU>
        % ---

        
        % initialize the DCA
        fprintf(dca, '*CLS');
        if scopeRST == 1
            opc = query(dca, '*RST; *OPC?');
        end    
        fprintf(dca, ':SYST:MODE OSC');
        % ---
        
        % get the module model
        pattern = '\w*(\d)\w?';
        slotnumber = regexp(dca_meas_channel,pattern,'tokens');
        model = query(dca, sprintf(':SYST:MOD? SLOT%s',slotnumber{1}{1}));
        % ---
               
        % use the complete acquisition memory
        fprintf(dca, ':ACQ:RLEN:MOD MAN');
        fprintf(dca, sprintf(':ACQ:RLEN %d', dca_mem_depth));

        % setting up the timebase reference
        % this has to be done prior to configuring the external trigger as it
        % will reset the trigger source to 'free run'
        opt = query(dca, '*OPT?');
        if isempty(strfind(opt, 'PTB'))
            % use the precision teimebase module which is assumed to be located
            % in slots 3+4
            fprintf(dca, ':PTIM3:RFR:AUT OFF');
            fprintf(dca, ':PTIM3:RMET OLIN');
            fprintf(dca, sprintf(':PTIM3:RFR %e',ftrig));
            opc = query(dca, ':PTIM3:STAT ON; *OPC?');
        else
            % use the internal PTB of the mainframe if available
            fprintf(dca, ':TIM:PTIM:RFR:AUT OFF');
            fprintf(dca, ':TIM:PTIM:RMET OLIN');
            fprintf(dca, sprintf(':TIM:PTIM:RFR %e',ftrig));
            opc = query(dca, ':TIM:PTIM:STAT ON; *OPC?');
        end

        % setup the trigger
        fprintf(dca, ':TRIG:SOUR FPAN');
        fprintf(dca, ':TRIG:MOD CLOC');
        fprintf(dca, ':TRIG:BRAT:AUT OFF');
        fprintf(dca, sprintf(':TRIG:BRAT %e', fsAWG));
        fprintf(dca, ':TRIG:PLEN:AUT OFF');
        fprintf(dca, sprintf(':TRIG:PLEN %d', length(samples)));
        fprintf(dca, ':TRIG:DCDR:AUT ON');
        opc = query(dca, ':TRIG:PLOC ON; *OPC?');
        % ---
        
        % we want to detect the timbase reference frequency automatically,
        % however, this only works AFTER pattern lock has been turned on
        if isempty(strfind(opt, 'PTB'))
           opc = query(dca, ':PTIM3:RFR:AUT ON; *OPC?'); 
        else
           opc = query(dca, ':TIM:PTIM:RFR:AUT ON; *OPC?');
        end
        % ---

        % select the smallest bandwidth above 46 GHz
        chan = dca_channel_id;
        if dca_diff_mode == 1 % differential
            fprintf(dca, sprintf(':%s:DMOD ON',chan));           
            chan = query(dca, sprintf('%s:FCH?',chan));            
        end
        fprintf(dca, sprintf(':%s:DISP ON',dca_channel_id)); 
        if not(isempty(strfind(model,'N1045A')))
            fprintf(dca, sprintf(':%s:BAND BAND4',chan)); % 60 GHz
        elseif not(isempty(strfind(model,'86118A')))
            fprintf(dca, sprintf(':%s:BAND BAND1',chan)); % 50 GHz
        else
            fprintf(dca, sprintf(':%s:BAND HIGH',chan));
        end
        % ---
        
        % perform automatic deskew if making a differential measurement
        if dca_diff_mode == 1 % differential
            opc = query(dca, sprintf(':%s:DESkew;*OPC?',dca_channel_id));
        end
        % ---
                
        % set up averaging if desired
        fprintf(dca, ':ACQ:STOP');
        if Navg > 1
            fprintf(dca, ':ACQ:SMO AVER');
            fprintf(dca, sprintf(':ACQ:ECO %d', Navg));
        else
            fprintf(dca, ':ACQ:SMO NONE');
        end
        % ---
        
        % set up limit testing to acquire multiple waveforms. This is required,
        % because using the precision timebase may otherwise cause holes in the 
        % output data stream.
        fprintf(dca, ':LTES:ACQ:CTYP PATT');
        fprintf(dca, sprintf(':LTES:ACQ:CTYP:PATT %d', Nshots));
        fprintf(dca, ':LTES:ACQ:STAT ON');
        % ---
        
        % make the measurements
        SINAD_dB = zeros(length(tones),1);
        ENOB     = NaN(length(tones),1);
        ft       = zeros(length(tones),1);
        FSR_set  = 0; % we want to set the FSR to the amplitude measured at the first frequency point
        for nn = 1:length(tones)

            if (~isempty(hMsgBox))
                if (getappdata(hMsgBox, 'cancel'))
                    break;
                end
                waitbar((2*nn-1)/(2*length(tones)), hMsgBox, 'Downloading waveform to AWG...');
            end
            % generate the test tone
            [samples,ft(nn)] = SineWaveGenerator(fsAWG,tones(nn),dca_mem_depth);
            % ---

            % set up the measurement channel
            fprintf(awg, 'ABOR');
            fprintf(awg, sprintf(':TRAC%d:DEL 1',awg_meas_channel));
            fprintf(awg, sprintf(':TRAC%d:DEF 1,%d,0',awg_meas_channel,length(samples)));
            binblockwrite(awg,samples,'int8',sprintf(':TRAC%d:DATA 1,0,',awg_meas_channel));
            fprintf(awg, '\n'); % terminate the write operation
            fprintf(awg, sprintf('VOLT%d %f',awg_meas_channel,amplitude));
            fprintf(awg, sprintf('OUTP%d ON',awg_meas_channel));
            opc = query(awg,':INIT:IMM; *OPC?');
            % ---

            if (~isempty(hMsgBox))
                if (getappdata(hMsgBox, 'cancel'))
                    break;
                end
                waitbar((2*nn)/(2*length(tones)), hMsgBox, 'Reading data from DCA...');
            end
            % perform autoscale
            opc = query(dca, 'SYST:AUT; *OPC?');

            % set up the measurement
            fprintf(dca, ':TIM:UNIT BIT');
            fprintf(dca, sprintf(':TIM:BRAT %e', fsAWG));
            fprintf(dca, ':TIM:MPOS 24.1E-9');
            fprintf(dca, ':TIM:POS 24.1E-9');

            opc = query(dca, ':ACQ:EPAT ON; *OPC?');
            fprintf(dca, ':ACQ:RSP SPB');
            fprintf(dca, ':ACQ:SPB:MOD MAN');
            opc = query(dca, sprintf(':ACQ:SPB %d; *OPC?',spb));  
            % ---
                      
            % measure the test signal
            dca.Timeout = 900; % this will take some time, so increase the timeout
            fprintf(dca, ':ACQ:CDIS');
            opc = query(dca, ':ACQ:RUN; *OPC?');
            % ---

            % get the waveform
            fprintf(dca, ':SYST:BORD LEND');
            fprintf(dca, sprintf(':WAV:SOUR %s',dca_channel_id));
%             fprintf(dca, ':WAV:SOUR FUNC1');
            
            fprintf(dca, ':WAV:XYF:DOUB:YDAT?');
            ydata_raw = binblockread(dca, 'double'); % in Volts
            fgets(dca);

            fprintf(dca, ':WAV:XYF:DOUB:XDAT?');
            xdata_raw = binblockread(dca, 'double'); % in Volts
            fgets(dca);
            dca.Timeout = 240;
            % ---

            % remove NaNs that may be caused by using the precision timebase
            xdata = xdata_raw(isfinite(ydata_raw));
            ydata = ydata_raw(isfinite(ydata_raw));
            % ---
            
            % remove frequency content above the Nyquist frequency
            if ft(nn)>bandwidth % make sure that we do not cut off our tone
                bw_limit = ft(nn); % if the last tone is above the bandwidth, slightly increase the bw
            else
                bw_limit = bandwidth;
            end
            
            Ndca = length(ydata);
            Nawg = length(samples);
            
            fsDCA = 1/(10*(Nawg/(10*fsAWG))/(Nawg*spb));
            faxis = fsDCA*(-Ndca/2:Ndca/2-1)/Ndca;
            
            spectrum = fftshift(fft(ydata)/Ndca);
            spectrum(abs(faxis)>bw_limit) = 1e-15;
            ydata = ifft(fftshift(spectrum))*length(spectrum);
            % ---
            
            
            % fit the measured data to a sine curve according to IEEE 1658-2011 pp. 34
            % using plain MATLAB. On p.98 the standard recommends using a
            % four-parameter fit. For this purpose, the standard suggests on p. 96 
            % to do a three-parameter pre-fit first and then use the results as
            % an initial guess to the four-parameter fit.
            options.TolX        = 1e-9;
            options.TolFun      = 1e-6;
            options.MaxFunEvals = 1500;
            options.MaxIter     = 1000;
            
            % do the three parameter fit
            pguess = [0.5,0.5,1e-3]; % initial guess
            fun = @(p) sum((ydata - (p(1)*cos(2*pi*ft(nn)*xdata)+p(2)*sin(2*pi*ft(nn)*xdata)+p(3))).^2);
            [p,fminres,exitflag(1)] = fminsearch(fun,pguess,options); %#ok<*ASGLU>
            
            % do the four-parameter fit
            qguess = [p ft(nn)]; % use the three-parameter fit result and the computed frequency as the initial guess
            fun2 = @(q) sum((ydata - (q(1)*cos(2*pi*q(4)*xdata)+q(2)*sin(2*pi*q(4)*xdata)+q(3))).^2);
            [p,fminres,exitflag(2)] = fminsearch(fun2,qguess,options); %#ok<*ASGLU>
            % ---

            % make sure that the fminsearch did not terminate prematurely
            if sum(exitflag) == 2
                
                % compute amplitude and phase according to IEEE 1658-2011 p. 35 eq. (15)
                A   = sqrt(p(1)^2+p(2)^2);
    %             phi = atan2(p(1),p(2));
                % ---

                % plot measured and fitted data for verification
                cla(axesHandles(1), 'reset');
                hold(axesHandles(1), 'on');
                plot(axesHandles(1), (xdata-xdata(1))*1e9,ydata,'r','Linewidth',2);
                plot(axesHandles(1), (xdata-xdata(1))*1e9,p(1)*cos(2*pi*p(4)*xdata)+p(2)*sin(2*pi*p(4)*xdata)+p(3),'b:','Linewidth',2);
                t = xdata(xdata <= xdata(1)+2/ft(nn))-xdata(1);
                xlim(axesHandles(1), [t(1) t(end)]*1e9);
                grid(axesHandles(1), 'on');
                legend(axesHandles(1), 'Measured Data', 'Fitted Curve', 'Location', 'NorthEast');
                xlabel(axesHandles(1), 'Time [ ns ] ')
                ylabel(axesHandles(1), 'Amplitude [ V ]')
                title(axesHandles(1), sprintf('Captured waveform @ %g GHz', ft(nn)*1e-9));
                % ---


                % set the the FSR to the amplitude that we measured at the first
                % frequency point (lowest frequency) to remove any constant
                % attentuation from our measurement
                if FSR_set == 0
                    FSR = 2*A;
                    FSR_set = 1;
                end
                %---

                % compute the ENOB according to IEEE 1658-2011 p. 57 eq. (41),
                % using (30) on p. 52 to calculate the rms noise and distortion
                ENOB(nn) = log2(FSR./( sqrt(12)*sqrt(1/length(ydata)*fun2(p)) ));

                cla(axesHandles(2), 'reset');
                hold(axesHandles(2), 'all');
                leg = {};
                if (~isempty(oldResults))
                    for k = 1:length(oldResults)
                        plot(axesHandles(2), oldResults(k).freqs/1e9, oldResults(k).enobs, '.-', 'linewidth', 2, 'Marker', 'd');
                        leg{end+1} = oldResults(k).legend;
                    end
                end
                plot(axesHandles(2), tones/1e9, ENOB, '.-', 'linewidth', 2, 'Marker', 'd');
                leg{end+1} = lgText;
                legend(axesHandles(2), leg);
                grid(axesHandles(2), 'on');
                xlabel(axesHandles(2), 'Frequency (GHz)');
                ylabel(axesHandles(2), 'ENOB');
                title(axesHandles(2), sprintf('ENOB %g GSa/s, %g V Amplitude, IEEE 1658-2011', fsAWG/1e9, amplitude));
                
            else
                ENOB(nn) = NaN;
                warning('Curve fitting failed: Ignoring the ENOB result');
            end
            % ---
            
        end
        ft   = ft(not(isnan(ENOB)));
        ENOB = ENOB(not(isnan(ENOB)));
        % ---

    catch err
        display(err.message);
        display(err.stack);
    end

    % disconnect from the instruments
    fclose(awg); % close connection
    delete(awg); % delete VISA object
    fclose(dca); % close connection
    delete(dca); % delete VISA object
    % ---

    % assign main result variables to base workspace
    assignin('base','ENOB',ENOB);
    assignin('base','ft',ft);
    % --
    
end

function [samples, ft] = ...
    SineWaveGenerator(fupdate,ftone,dca_mem_depth)

	% This function generates a sine wave vector in Offset binary format
	% (-128...127) according to the IEEE Std 1658-2011
	% - fupdate       = DAC Sample Rate
	% - ftone         = Requested DAC output frequency
    % - dca_mem_depth = DCA memory depth
    %
    % - samples = Test signal vector
    % - ft      = Actual frequency of the test signal

    % Set the back-off decrement. This value is used to make sure that the
    % generated frequencies do not exceed the AWG's Nyquist frequency.
    backOffDecrement = 100e6;
    
	% Set the DAC resolution in bits
	N = 8;

	% Set the pattern length. According to the standard, the pattern length
    % needs to be at least M = pi * 2^N samples. Moreover, we need it to be a
    % multiple of 128. Thus we use 1/4 of the DCA's memory.
    M = dca_mem_depth/4;

	% Calculate the number of cycles of ftone which will fit into the
	% number of samples selected
    % J MUST be > 5 according to the standard or we might encounter measurement
    % errors!
	J = round((ftone/fupdate)*M);

	% Calculate a prime number of cycles to ensure the sinewave selected 
	% uses the full DAC code range, and report the actual frequency.
	J  = Closest_Prime(J);
	ft = fupdate*J/M;
    
    % Make sure that the calculated frequency does not exceed the DAC's Nyquist
    % frequency.
    while ft > fupdate/2
       ftone = ftone-backOffDecrement;
       J     = round((ftone/fupdate)*M);
       J     = Closest_Prime(J);
       ft    = fupdate*J/M;
    end

	% Generate the sinewave according to eq. (28) of the standard document
	n       = 0:M-1;
	samples = round((2^(N-1)-0.35)*cos(2*pi*J*n/M)-0.5);

end

function [trig_samples, ftrig] = TriggerGenerator(fupdate)

    % Use exactly one segment, i.e 128 bit
    M = 128;
    % Set the dac resolution
    N = 8;
    % We want to use double the DAC Ref CLK frequency for triggering, which
    % corresponds to eight full cycles.
    J = 8;
    
    % Compute the trigger waveform
    n = 0:M-1;
    trig_samples = round((2^(N-1)-0.35)*cos(2*pi*J*n/M)-0.5);
    
    % Compute the reference frequency to be used as the timebase reference
    ftrig = fupdate*J/M;

end


function Ncycles = Closest_Prime(Ncyc)

	Ncycles = Ncyc;
	if ~isprime(Ncycles)
		
        if Ncycles < 2
            % 2 is the smallest prime number
            Ncycles = 2;
        else
            
            Ncyc_Upper = Ncyc;
            Ncyc_Lower = Ncyc;
            while 1

                % we prefer smaller numbers so try these first
                Ncyc_Lower=Ncyc_Lower-1;
                if isprime(Ncyc_Lower)
                    Ncycles=Ncyc_Lower;
                    break
                end

                Ncyc_Upper=Ncyc_Upper+1;
                if isprime(Ncyc_Upper)
                    Ncycles=Ncyc_Upper;
                    break
                end

            end
            
        end
		
	end

end
