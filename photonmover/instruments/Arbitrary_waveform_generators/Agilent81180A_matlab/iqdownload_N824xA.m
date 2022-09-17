function driver = iqdownload_N824xA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)
% download an IQ waveform to the N824x
% v1.0 - Vinod Cherian, MathWorks
    driver = [];
    if (~isempty(sequence))
        errordlg('Sequence mode is not yet implemented for the N824xA');
        return;
    end
    initOptions = 'QueryInstrStatus=true, simulate=false';
    try
        driver = icdevice('AGN6030A.mdd',arbConfig.visaAddr,'optionstring',initOptions);
    catch e
        errordlg({'Can''t open N824xA device driver (AGN6030A.mdd):' e.message});
        return;
    end
    connect(driver);
    invoke(driver.Actionstatus,'abortgeneration');
    AGN6030A_VAL_OUTPUT_ARB = 1; % From the driver documentation
    set(driver.Basicoperation,'Output_Mode',AGN6030A_VAL_OUTPUT_ARB);
    set(driver.Arbitrarywaveformoutput,'Enables_predistortion_of_waveforms_during_download_to_improve_signal_quality',false);
    %invoke(driver.Configurationfunctionsarbitraryoutputarbitrarysequence,'cleararbmemory')
    for ch = find(channelMapping(:,1))'
        gen_arb_N824x(arbConfig, driver, ch, real(data), marker1, fs, segmNum);
    end
    for ch = find(channelMapping(:,2))'
        gen_arb_N824x(arbConfig, driver, ch, imag(data), marker2, fs, segmNum);
    end
    set(driver,'RepCapIdentifier','')
    set(driver.Arbitrarywaveformoutput,'Sample_Rate',fs);    
    invoke(driver.Actionstatus,'initiategeneration');
    if (~exist('keepOpen') || keepOpen == 0)
        disconnect(driver); delete(driver);
    end;
end

function gen_arb_N824x(arbConfig, driver, chan, data, marker, fs, segm_num)
    set(driver,'RepCapIdentifier',num2str(chan));
    if (isfield(arbConfig, 'ampType'))
        switch arbConfig.ampType
            % 1 = differential, 0 = single ended, 2 = amplified  
            case 'DC'   
                set(driver.Basicoperation,'Output_Configuration',0);
            case 'DAC' 
                set(driver.Basicoperation,'Output_Configuration',1);
            case 'AC'
                set(driver.Basicoperation,'Output_Configuration',2);
        end
    end
    if (isfield(arbConfig,'amplitude'))
        set(driver.Arbitrarywaveformoutput,'Arbitrary_Waveform_Gain',arbConfig.amplitude(chan));
    end
    waveformHandle = invoke(driver.Configurationfunctionsarbitraryoutputarbitrarywaveform,'createarbwaveform',length(data), data);
    arbGain = 0.25; arbOffset = 0;
    invoke(driver.Configurationfunctionsarbitraryoutputarbitrarywaveform,'configurearbwaveform', num2str(chan),waveformHandle,arbGain,arbOffset);
    set(driver.Basicoperation,'Output_Enabled',true);
end