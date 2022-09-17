% Date : 22-1-2018
function [ errortxt ] = FMCWTestAWG()
arbConfig = loadArbConfig();
awg = iqopen(arbConfig);
if ( isempty(awg) )
    errortxt=[];
else
    errortxt = query(awg,'*IDN?');
    fclose(awg);
end

