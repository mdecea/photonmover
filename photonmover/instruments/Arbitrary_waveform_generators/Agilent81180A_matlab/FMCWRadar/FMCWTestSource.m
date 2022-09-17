% Date: 22-1-2018
function [ loConfig ] = FMCWTestSource(handles)
% Test the LO Source for connectivity and check its capabilities.
% The results are stored in LoConfig.mat and the source uipanel userdata is updated. 
lo_addr = get(handles.editlo_Address,'String'); 
loConfig=[];

try
    lo = visa('agilent', lo_addr );
catch e
    errordlg('Invalid addr' );
    lo=[]; 
    set(handles.pushbuttonlo_TestAddress,'BackgroundColor','red');
    return;
end

try
    fopen(lo);
catch e
      errordlg('Please connect source to AWG system controller' );
      set(handles.pushbuttonlo_TestAddress,'BackgroundColor','red');
      lo = [];
      return;
end
loConfig.idn = query(lo,'*IDN?');
loConfig.visaAddr = lo_addr;
loConfig.maxFrequency_Hz = str2double(query(lo,':SOUR:FREQ? MAX'));
loConfig.minFrequency_Hz = str2double(query(lo,':SOUR:FREQ? MIN'));
loConfig.maxPower_dBm = str2double(query(lo,':SOUR:POW? MAX'));
loConfig.minPower_dBm = str2double(query(lo,':SOUR:POW? MIN'));
set(handles.pushbuttonlo_TestAddress,'BackgroundColor','green');
fclose(lo);
delete(lo);
lo=[];
set(handles.uipanellosource,'UserData',loConfig);
save('LoConfig.mat','loConfig');

end

