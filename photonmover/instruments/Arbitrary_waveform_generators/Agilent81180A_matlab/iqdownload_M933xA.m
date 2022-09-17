function driver = iqdownload_M933xA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)
% download an IQ waveform to the M933xA
% This routine is NOT intended to be called directly from a user script
% It should only be called via iqdownload()
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    driver = [];
    if (~isempty(sequence))
        errordlg('Sequence mode is not yet implemented for the M933xA');
        return;
    end
    try
        driver = instrument.driver.AgM933x();
    catch e
        errordlg({'Can''t open N933xA device driver (AgM933x):' e.message});
        return;
    end
    % initOptions = 'QueryInstrStatus=true, simulate=false, DriverSetup= DDS=false, Trace=false';
    initOptions = 'QueryInstrStatus=true, simulate=false, DriverSetup= DDS=false, Model=M9330A , Trace=false';  % Changed by Ray C
    idquery = true;
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        reset = true;
    else
        reset = false;
    end
    driver.Initialize(arbConfig.visaAddr, idquery, reset, initOptions); 
    driver.AbortGeneration();
    driver.DeviceSpecific.Arbitrary.Waveform.ClearAll();
    for ch = find(channelMapping(:,1))'
        gen_arb_M933xA(arbConfig, driver, ch, real(data), marker1, fs, segmNum);
    end
    for ch = find(channelMapping(:,2))'
        gen_arb_M933xA(arbConfig, driver, ch, imag(data), marker2, fs, segmNum);
    end
    driver.DeviceSpecific.InitiateGeneration();   % Commented out by Ray C
    if (~exist('keepOpen') || keepOpen == 0)
        driver.Close();
    end;
end



function gen_arb_M933xA(arbConfig, driver, chan, data, marker, fs, segm_num)
    if (isfield(arbConfig, 'ampType'))
        switch arbConfig.ampType
% 1 = differential, 0 = single ended, 2 = amplified  % Modified by Ray C
            case 'DC'   % Added by Ray C 
                driver.DeviceSpecific.Output.Configuration(num2str(chan), 0);
            case 'DAC'  % Added by Ray C
                driver.DeviceSpecific.Output.Configuration(num2str(chan), 1);
            case 'AC'
                driver.DeviceSpecific.Output.Configuration(num2str(chan), 2);
        end
    end
    if (isfield(arbConfig,'amplitude'))
        driver.DeviceSpecific.Arbitrary.Gain(num2str(chan), arbConfig.amplitude(chan));    
    end
	driver.DeviceSpecific.Arbitrary.Waveform.Predistortion.Enabled = false;
    waveformHandle = driver.DeviceSpecific.Arbitrary.Waveform.Create(data);
   	driver.DeviceSpecific.Arbitrary.Waveform.Handle(num2str(chan), waveformHandle);
	driver.DeviceSpecific.Output.Enabled(num2str(chan), true);
 end


