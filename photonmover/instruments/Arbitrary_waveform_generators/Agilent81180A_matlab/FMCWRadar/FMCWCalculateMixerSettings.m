% Date : 22-1-2018
function [ errormsg , settings ] = FMCWCalculateMixerSettings( fmcw, mixer )
% Calculates the IF and LO settings of upconverter. 
%   The calculations are based on fmcw signal requirements and mixer specifications
%   The recomended frequency settings for the mixer are returned in settings
%   input param :-
%   fmcw = requested RF chirp signal frequencies
%   mixer = mixer specifications

settings=[];
% radar signal requirements
fmcw_centerFreq = fmcw.centerFreq ;
fmcw_bandwidth =  fmcw.bandwidth;
fmcw_imageseparation = fmcw.imageseparation;
% mixer specifications
mixer_lo_min = mixer.lomin ;
mixer_lo_max = mixer.lomax ;
mixer_if_min = mixer.ifmin ;
mixer_if_max = mixer.ifmax ;

% calculation begins here
% Can mixer support required fmcw bandwidth and minimun IF separation?
mixer_bandwidth = mixer_if_max - mixer_if_min ;
if mixer_bandwidth < fmcw_bandwidth
   errormsg = 'Mixer cannot support required fmcw signal bandwidth';
   settings.error = 1;
   return;
end

fmcw_lowFreq = fmcw_centerFreq - fmcw_bandwidth/2 ;
max_imageseparation = 2*(fmcw_lowFreq - mixer_lo_min) ; 
% checking if minimun requested image separation can be met
if max_imageseparation < fmcw_imageseparation
    errormsg='mixer LO Port cannot support required minimun image separation';
    settings.error = 1;
    return;
end

% calculate initial lo_freq based on image separation
LO_Freq = fmcw_lowFreq - fmcw_imageseparation/2 ;

% increase image separation until LO freq is within mixer lo range
if LO_Freq > mixer_lo_max
   LO_Freq = mixer_lo_max ; 
end
% now check whether mixer can support the calculated IF band
if_lowFreq = fmcw_lowFreq - LO_Freq ;
if_highFreq = if_lowFreq + fmcw_bandwidth ;
if if_lowFreq < mixer_if_min || if_highFreq > mixer_if_max
    errormsg='Mixer IF port cannot support fmcw requirements';
    settings.error = 1;
    return;
end

settings.imageseparation = 2*if_lowFreq ; 
settings.LOportFreq = LO_Freq ;
settings.IFportstartFreq = if_lowFreq ;
settings.IFportstopFreq = if_highFreq ;

if settings.imageseparation > fmcw.imageseparation
   % warn that image separation has been changed from minimum
   errormsg='Image separation increased to accomodate LO port'; 
   settings.error = 2;
else
    errormsg='Recomended mixer settings successfully calculated.';
    settings.error = 0;
end

