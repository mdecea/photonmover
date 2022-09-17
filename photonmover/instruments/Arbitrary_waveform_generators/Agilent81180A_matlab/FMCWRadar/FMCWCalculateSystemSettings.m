% Date : 22-1-2018
function[errormsg] = FMCWCalculateSystemSettings(handles)
% Calculates the instrument settings required to generate the required FMCW signal
%       This function does not have explicit input or output parameters. 
%       All required and calculated parameters are obtained and passed back to the main dialog gui elements.

errormsg=[];
set(handles.editlo_Frequency,'String','?');
set(handles.editwave_centerFreq,'String','?');

% get the fmcw requirements
fmcwparam.centerFreq = str2double(get(handles.editfmcw_CenterFreq, 'String'));
fmcwparam.bandwidth = str2double(get(handles.editfmcw_BW, 'String'));
min_imageseparation= str2double(get(handles.editfmcw_minImageSeparation, 'String'));
fmcwparam.imageseparation = min_imageseparation ;
% get the selected mixer specifications
mixers = get(handles.popupmenuUpConverter,'UserData');
selection = get(handles.popupmenuUpConverter,'Value');
selectedmixer=mixers(selection);
mixerparam.lomin = selectedmixer.LoFreqMinHz ;
mixerparam.lomax = selectedmixer.LoFreqMaxHz ;
mixerparam.ifmin = selectedmixer.IfFreqMinHz ;
mixerparam.ifmax = selectedmixer.IfFreqMaxHz ;
% calculate mixer port frequencies
[ errortxt,mixersettings ] = FMCWCalculateMixerSettings( fmcwparam, mixerparam );
% abort if mixer cannot support requested fmcw parameters
if  mixersettings.error == 1 
    errormsg=errortxt;
    return;
end

% check LO signal source specifications(stored as user data in source
% uipanel)
losource = get(handles.uipanellosource,'UserData');
required_loFreq = mixersettings.LOportFreq/selectedmixer.LoMulFactor ;
% try increasing the image separation frequency if LO source have problem meeting initial requirements. 
if  required_loFreq > losource.maxFrequency_Hz 
   fmcwlowFreq = fmcwparam.centerFreq - fmcwparam.bandwidth/2 ;
   fmcwparam.imageseparation = 2*(fmcwlowFreq-losource.maxFrequency_Hz);
   [ ~ , mixersettings ] = FMCWCalculateMixerSettings( fmcwparam, mixerparam );
   if ( mixersettings.error == 1 )
       errormsg='Source Instrument unable to generate the required LO frequency.';
       return;
   else
       required_loFreq = mixersettings.LOportFreq/selectedmixer.LoMulFactor ;
   end    
end
% calculate required LO source amplitude setting
set(handles.editlo_Frequency,'String',iqengprintf(required_loFreq));
cableloss = str2double(get(handles.editlocable_Loss,'String'));
requiredlopower = selectedmixer.LoPowerdBm + cableloss ;
set(handles.editlo_Amplitude,'String',requiredlopower);

waveCenterFreq = (mixersettings.IFportstartFreq + mixersettings.IFportstopFreq)/2 ;
set(handles.editwave_centerFreq,'String',iqengprintf(waveCenterFreq));

% if image separation was increased from minimun, change the color of the edit box to yellow
% as a warning
set(handles.editfmcw_minImageSeparation, 'String', iqengprintf(mixersettings.imageseparation));
if mixersettings.imageseparation > min_imageseparation
    set(handles.editfmcw_minImageSeparation,'BackgroundColor','Yellow');
else
    set(handles.editfmcw_minImageSeparation,'BackgroundColor','White');
end

fmcwparam.pulsewidth = str2double(get(handles.editfmcw_PulseWidth, 'String'));
% fmcw pulse width might need to be adjusted due to M8195A granulity
% if changed, indicate by changing the pulse width editbox to yellow.
fs=64e9;
arbConfig = loadArbConfig();
[pri,numsamples ] = checkAWGGranularity(fmcwparam.pulsewidth, 0,fmcwparam.pulsewidth , 0, 0, fs, arbConfig);
if pri ~= fmcwparam.pulsewidth
   set(handles.editfmcw_PulseWidth,'String',iqengprintf(pri));
   set(handles.editfmcw_PulseWidth,'BackgroundColor','Yellow');
else
   set(handles.editfmcw_PulseWidth,'BackgroundColor','White');
end    


end

% NOTE:: This function is copied from iqtools since it is not available as a public function
function [pri, numSamples] = checkAWGGranularity(pri, delay, pw, riseTime, fallTime, sampleRate, arbConfig)
% check that the total length matches the required segment granularity.
% if necessary adjust PRI's by stretching them equally
% In a real application, this has to be solved changing the delay of
% subsequent pulses - but this is not possible here
    offTime = pri - delay - pw - riseTime - fallTime;
    if (min(offTime) < 0)
        if (pri(1) ~= 0)
            errordlg('delay + pulse width + risetime + falltime > repeat interval');
        end
        % set PRI to at least the sum of delay+pw+rise+fall
        tmp = delay + pw + riseTime + fallTime;
        pri(offTime < 0) = tmp(offTime < 0);
    end
    % round pri to full ps to reduce the chance of floating point rounding errors
    spri = round(sum(pri) * 1e12);
    numSamples = ceil(spri * sampleRate / 1e12);
    % round PRI's to match the segment granularity
    % always round UP, to avoid negativ off-times
    modval = mod(numSamples, arbConfig.segmentGranularity);
    if (modval ~= 0)
        corr = arbConfig.segmentGranularity - modval;
        pri = pri .* (corr + numSamples) / numSamples;
        % note the use of round() here to avoid a "jump" to the next integer
        numSamples = round(sum(pri) * sampleRate / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
    end
end