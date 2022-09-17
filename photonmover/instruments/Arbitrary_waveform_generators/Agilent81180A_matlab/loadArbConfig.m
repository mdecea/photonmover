function varargout = loadArbConfig(arbConfig)
% Returns a struct with the AWG-specific parameters:
%  - 
% If loadArbConfig is called with no arguments, it will load the AWG
% configuration from the file "arbConfig.mat", otherwise, it expects a
% struct with at least the following members:
%   model - AWG model (see switch statements below)
%
% T.Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 


    saConfig.connected = 0;
    if (~exist('arbConfig', 'var') || isempty(arbConfig))
        arbConfig.model = 'unknown';
        try
            arbCfgFile = iqarbConfigFilename();
        catch
            arbCfgFile = 'arbConfig.mat';
        end
        try
            load(arbCfgFile);
        catch e
            errordlg({sprintf('Can''t load configuration file (%s)', arbCfgFile) ...
                'Please use "Configure Instrument Connection" to create it.'}, 'Error');
            error('Can''t load configuration file. Please use "Configure Instrument Connection" to create it.');
        end
    end
    arbConfig.numChannels = 2;
    switch arbConfig.model
        case { 'M933xA' 'M9330A/M9331A' 'N824xA' 'N603xA' }
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 1.25e9;
            arbConfig.maximumSampleRate = 1.25e9;
            arbConfig.minimumSampleRate = 1.25e9;
            arbConfig.minimumSegmentSize = 128;
            arbConfig.maximumSegmentSize = 32*1024*1024;
            arbConfig.segmentGranularity = 32;
            arbConfig.maxSegmentNumber = 65536;
        case { 'M9336A' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 1.28e9;
            arbConfig.maximumSampleRate = 1.28e9;
            arbConfig.minimumSampleRate = 0.01;
            arbConfig.minimumSegmentSize = 512;
            arbConfig.maximumSegmentSize = 4*1024*1024*1024;
            arbConfig.segmentGranularity = 4;
            arbConfig.numChannels = 3;
            arbConfig.maxSegmentNumber = 16384;
        case { 'M3201A_CLF' 'M3201A' 'M3300A' 'M3302A' }
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 500e6;
            arbConfig.maximumSampleRate = 500e6;
            arbConfig.minimumSampleRate = 500e6;
            arbConfig.minimumSegmentSize = 40;
            arbConfig.maximumSegmentSize = 32*1024*1024;
            arbConfig.segmentGranularity = 40;
            arbConfig.numChannels = 4;
            arbConfig.maxSegmentNumber = 1;
        case { 'M3201A_CLV' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 500e6;
            arbConfig.maximumSampleRate = 500e6;
            arbConfig.minimumSampleRate = 100e6/(4095*5);
            arbConfig.minimumSegmentSize = 40;
            arbConfig.maximumSegmentSize = 32*1024*1024;
            arbConfig.segmentGranularity = 40;
            arbConfig.numChannels = 4;
            arbConfig.maxSegmentNumber = 1;
        case { 'M3202A_CLF' 'M3202A' }
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 1.00e9;
            arbConfig.maximumSampleRate = 1.00e9;
            arbConfig.minimumSampleRate = 1.00e9;
            arbConfig.minimumSegmentSize = 40;
            arbConfig.maximumSegmentSize = 32*1024*1024;
            arbConfig.segmentGranularity = 40;
            arbConfig.numChannels = 4;
            arbConfig.maxSegmentNumber = 1;
        case { 'M3202A_CLV' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 1.00e9;
            arbConfig.maximumSampleRate = 1.00e9;
            arbConfig.minimumSampleRate = 400e6; %/(4095*5); FUTURE
            arbConfig.minimumSegmentSize = 40;
            arbConfig.maximumSegmentSize = 32*1024*1024;
            arbConfig.segmentGranularity = 40;
            arbConfig.numChannels = 4;
            arbConfig.maxSegmentNumber = 1;
        case { '81180A' '81180B' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 4e9;
            arbConfig.maximumSampleRate = 4.2e9;
            if (strcmp(arbConfig.model, '81180B'))
                arbConfig.maximumSampleRate = 4.6e9;
            end
            arbConfig.minimumSampleRate = 10e6;
            arbConfig.minimumSegmentSize = 384;
            arbConfig.maximumSegmentSize = 64*1024*1024;
            arbConfig.segmentGranularity = 32;
            arbConfig.maxSegmentNumber = 16384;
        case { 'M8190A' 'M8190A_base' }     % Rev. 1 version of M8190A
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 8e9;
            arbConfig.maximumSampleRate = 8e9;
            arbConfig.minimumSampleRate = 6.5e9;
            arbConfig.minimumSegmentSize = 4*48;
            arbConfig.maximumSegmentSize = 2*1024*1024*1024;
            arbConfig.segmentGranularity = 48;
            arbConfig.maxSegmentNumber = 1;
        case 'M8190A_14bit'                 % Rev. 2 of M8190A, 14 bit mode
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 8e9;
            arbConfig.maximumSampleRate = 8e9;
            arbConfig.minimumSampleRate = 125e6;
            arbConfig.minimumSegmentSize = 5*48;
            arbConfig.maximumSegmentSize = 2*1024*1024*1024;
            arbConfig.segmentGranularity = 48;
            arbConfig.maxSegmentNumber = 512*1024;
            arbConfig.maximumModules = 4;
        case 'M8190A_12bit'                 % Rev. 2 of M8190A, 12 bit mode
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 12e9;
            arbConfig.maximumSampleRate = 12e9;
            arbConfig.minimumSampleRate = 125e6;
            arbConfig.minimumSegmentSize = 5*64;
            arbConfig.maximumSegmentSize = 3*512*1024*1024;
            arbConfig.segmentGranularity = 64;
            arbConfig.maxSegmentNumber = 512*1024;
            arbConfig.maximumModules = 4;
        case { 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }  % M8190A with digital upconversion
            arbConfig.interpolationFactor = eval(arbConfig.model(13:end));
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 7.2e9 / arbConfig.interpolationFactor;
            arbConfig.maximumSampleRate = 7.2e9 / arbConfig.interpolationFactor;
            arbConfig.minimumSampleRate = 1e9 / arbConfig.interpolationFactor;
            arbConfig.minimumSegmentSize = 240;
            arbConfig.maximumSegmentSize = 3*512*1024*1024;
            arbConfig.segmentGranularity = 24;
            arbConfig.maxSegmentNumber = 512*1024;
            arbConfig.maximumModules = 4;
        case 'M8121A_14bit'                 % M8121A, 14 bit mode
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 8e9;
            arbConfig.maximumSampleRate = 8e9;
            arbConfig.minimumSampleRate = 125e6;
            arbConfig.minimumSegmentSize = 320;
            arbConfig.maximumSegmentSize = 1024*1024;
            arbConfig.segmentGranularity = 320;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.maximumModules = 4;
        case 'M8121A_12bit'                 % M8121A, 12 bit mode
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 12e9;
            arbConfig.maximumSampleRate = 12e9;
            arbConfig.minimumSampleRate = 1e9;
            arbConfig.minimumSegmentSize = 768;
            arbConfig.maximumSegmentSize = 1024*1024;
            arbConfig.segmentGranularity = 768;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.maximumModules = 4;
        case { 'M8121A_DUC_x3' 'M8121A_DUC_x12' 'M8121A_DUC_x24' 'M8121A_DUC_x48' }  % M8121A with digital upconversion
            arbConfig.interpolationFactor = eval(arbConfig.model(13:end));
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 7.2e9 / arbConfig.interpolationFactor;
            arbConfig.maximumSampleRate = 7.2e9 / arbConfig.interpolationFactor;
            arbConfig.minimumSampleRate = 1e9 / arbConfig.interpolationFactor;
            arbConfig.minimumSegmentSize = 2560;
            arbConfig.maximumSegmentSize = 512*1024;
            arbConfig.segmentGranularity = 256;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.maximumModules = 4;
        case { 'M8195A_Rev0' 'M8195A_Rev1' 'M8195A_4ch_256k'}
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 64e9;
            arbConfig.maximumSampleRate = 65e9;
            arbConfig.minimumSampleRate = 54e9;
            arbConfig.minimumSegmentSize = 128;
            arbConfig.maximumSegmentSize = 256*1024;
            arbConfig.segmentGranularity = 128;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.numChannels = 4;
            arbConfig.maximumModules = 4;
        case { 'M8195A_2ch_256k' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 64e9;
            arbConfig.maximumSampleRate = 65e9;
            arbConfig.minimumSampleRate = 54e9;
            arbConfig.minimumSegmentSize = 128;
            arbConfig.maximumSegmentSize = 256*1024;
            arbConfig.segmentGranularity = 128;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.numChannels = 2;
            arbConfig.channelMask = [1 0 0 1];
            arbConfig.maximumModules = 4;
        case { 'M8195A_1ch', 'M8195A_1ch_mrk' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 64e9;
            arbConfig.maximumSampleRate = 65e9;
            arbConfig.minimumSampleRate = 54e9;
            arbConfig.minimumSegmentSize = 5*512;
            arbConfig.maximumSegmentSize = 16*1024*1024*1024;
            % due to a sequencer bug, use double the specified granularity
            % Once that bug is fixed, we can go back to 256
            arbConfig.segmentGranularity = 512;
            arbConfig.maxSegmentNumber = 512*1024;
            arbConfig.numChannels = 1;
            arbConfig.channelMask = [1 0 0 0];
            arbConfig.maximumModules = 4;
        case { 'M8195A_2ch' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 32e9;
            arbConfig.maximumSampleRate = 32.5e9;
            arbConfig.minimumSampleRate = 27e9;
            arbConfig.minimumSegmentSize = 5*256;
            arbConfig.maximumSegmentSize = 8*1024*1024*1024;
            % due to a sequencer bug, use double the specified granularity
            % Once that bug is fixed, we can go back to 128
            arbConfig.segmentGranularity = 256;
            arbConfig.maxSegmentNumber = 512*1024;
            arbConfig.numChannels = 2;
            arbConfig.channelMask = [1 0 0 1];
            arbConfig.maximumModules = 4;
        case { 'M8195A_2ch_mrk' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 32e9;
            arbConfig.maximumSampleRate = 32.5e9;
            arbConfig.minimumSampleRate = 27e9;
            arbConfig.minimumSegmentSize = 5*256;
            arbConfig.maximumSegmentSize = 8*1024*1024*1024;
            % due to a sequencer bug, use double the specified granularity
            % Once that bug is fixed, we can go back to 128
            arbConfig.segmentGranularity = 256;
            arbConfig.maxSegmentNumber = 512*1024;
            arbConfig.numChannels = 2;
            arbConfig.channelMask = [1 1 0 0];
            arbConfig.maximumModules = 4;
        case { 'M8195A_4ch' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 16e9;
            arbConfig.maximumSampleRate = 16.25e9;
            arbConfig.minimumSampleRate = 13.5e9;
            arbConfig.minimumSegmentSize = 5*128;
            arbConfig.maximumSegmentSize = 4*1024*1024*1024;
            % due to a sequencer bug, use double the specified granularity
            % Once that bug is fixed, we can go back to 64
            arbConfig.segmentGranularity = 128;
            arbConfig.maxSegmentNumber = 512*1024;
            arbConfig.numChannels = 4;
            arbConfig.maximumModules = 4;
        case { 'M8196A' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 92e9;
            arbConfig.maximumSampleRate = 93.4e9;
            arbConfig.minimumSampleRate = 82.24e9;
            arbConfig.minimumSegmentSize = 128;
            arbConfig.maximumSegmentSize = 512*1024;
            arbConfig.segmentGranularity = 128;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.numChannels = 4;
            if (isfield(arbConfig, 'clockSource') && isfield(arbConfig, 'clockFreq') && ....
                strcmpi(arbConfig.clockSource, 'ExtRef') && ...
                arbConfig.clockFreq >= 2.32e9 && arbConfig.clockFreq <= 3.0e9)
                    arbConfig.fixedSampleRate = 1;
                    arbConfig.defaultSampleRate = 32 * arbConfig.clockFreq;
                    arbConfig.maximumSampleRate = arbConfig.defaultSampleRate;
                    arbConfig.minimumSampleRate = arbConfig.defaultSampleRate;
            end
        case { 'M8194A' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 120e9;
            arbConfig.maximumSampleRate = [120.2e9 112.2e9 100.2e9];
            arbConfig.minimumSampleRate = [115.2e9 107.2e9 95.6e9];
            arbConfig.minimumSegmentSize = 128;
            arbConfig.maximumSegmentSize = 512*1024;
            arbConfig.segmentGranularity = 128;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.numChannels = 4;
            arbConfig.maximumModules = 4;
        case { 'M8198A_Rev0' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 128e9;
            arbConfig.maximumSampleRate = 128e9;
            arbConfig.minimumSampleRate = 1e9;
            arbConfig.minimumSegmentSize = 256;
            arbConfig.maximumSegmentSize = 512*1024;
            arbConfig.segmentGranularity = 256;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.numChannels = 1;
            arbConfig.maximumModules = 4;
        case '81150A'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 2e9;
            % sample rate is not used in DDS instruments
            arbConfig.maximumSampleRate = 16*2e9;
            arbConfig.minimumSampleRate = 1e3;
            arbConfig.minimumSegmentSize = 512;
            arbConfig.maximumSegmentSize = 512*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.usePowerOfTwoSamples = 1;
        case '81160A'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 2.5e9;
            % sample rate is not used in DDS instruments
            arbConfig.maximumSampleRate = 16*2.5e9;
            arbConfig.minimumSampleRate = 1e3;
            arbConfig.minimumSegmentSize = 512;
            arbConfig.maximumSegmentSize = 4*1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.usePowerOfTwoSamples = 1;
         case 'AWG7xxx'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 12e9;
            arbConfig.maximumSampleRate = 24e9;
            arbConfig.minimumSampleRate = 10e6;
            arbConfig.minimumSegmentSize = 4;
            arbConfig.maximumSegmentSize = 64*1024*1024;
            arbConfig.segmentGranularity = 4;
            arbConfig.maxSegmentNumber = 16384;
         case 'AWG7xxxx'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 50e9;
            arbConfig.maximumSampleRate = 50e9;
            arbConfig.minimumSampleRate = 1e6;
            arbConfig.minimumSegmentSize = 4800;
            arbConfig.maximumSegmentSize = 16*1024*1024*1024;
            arbConfig.segmentGranularity = 2;
            arbConfig.maxSegmentNumber = 16384;
        case {'N5182A' 'N51xxA (MXG)'}
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 125e6;
            arbConfig.maximumSampleRate = 125e6;
            arbConfig.minimumSampleRate = 1e6;
            arbConfig.minimumSegmentSize = 60;
            arbConfig.maximumSegmentSize = 16*1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;
        case {'N5182B'}
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 200e6;
            arbConfig.maximumSampleRate = 200e6;
            arbConfig.minimumSampleRate = 1e6;
            arbConfig.minimumSegmentSize = 60;
            arbConfig.maximumSegmentSize = 16*1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;
         case {'N5172B'}
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 150e6;
            arbConfig.maximumSampleRate = 150e6;
            arbConfig.minimumSampleRate = 1e6;
            arbConfig.minimumSegmentSize = 60;
            arbConfig.maximumSegmentSize = 16*1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;
        case {'E4438C'}
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 100e6;
            arbConfig.maximumSampleRate = 100e6;
            arbConfig.minimumSampleRate = 1e6;
            arbConfig.minimumSegmentSize = 60;
            arbConfig.maximumSegmentSize = 16*1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;
        case {'E8267D'}
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 100e6;
            arbConfig.maximumSampleRate = 100e6;
            arbConfig.minimumSampleRate = 1e6;
            arbConfig.minimumSegmentSize = 60;
            arbConfig.maximumSegmentSize = 16*1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;
         case {'M9381A' 'M938xA'}
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 200e6;
            arbConfig.maximumSampleRate = 200e6;
            arbConfig.minimumSampleRate = 1e6;
            arbConfig.minimumSegmentSize = 60;
            arbConfig.maximumSegmentSize = 16*1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;  
        case {'M9383A'}
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 1.28E9;
            arbConfig.maximumSampleRate = 1.28E9;
            arbConfig.minimumSampleRate = 1;
            arbConfig.minimumSegmentSize = 1;
            arbConfig.maximumSegmentSize = 4E9;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;
        case {'M9384B' 'M9384B_1Ch', 'M9384B_2Ch_COH', 'M9383B'}
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 2.56E9;
            arbConfig.maximumSampleRate = 2.56E9;
            arbConfig.minimumSampleRate = 1;
            arbConfig.minimumSegmentSize = 1;
            arbConfig.maximumSegmentSize = 4E9;
            arbConfig.segmentGranularity = 8;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.numChannels = 1;
         case 'M9384B_2Ch_IND'
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 2.56E9;
            arbConfig.maximumSampleRate = 2.56E9;
            arbConfig.minimumSampleRate = 1;
            arbConfig.minimumSegmentSize = 1;
            arbConfig.maximumSegmentSize = 4E9;
            arbConfig.segmentGranularity = 8;
            arbConfig.maxSegmentNumber = 1;
            arbConfig.numChannels = 2;
         case '3351x'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 160e6;
            arbConfig.maximumSampleRate = 160e6;
            arbConfig.minimumSampleRate = 1e3;
            arbConfig.minimumSegmentSize = 64;
            arbConfig.maximumSegmentSize = 1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;     
         case '3352x'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 250e6;
            arbConfig.maximumSampleRate = 250e6;
            arbConfig.minimumSampleRate = 1e3;
            arbConfig.minimumSegmentSize = 64;
            arbConfig.maximumSegmentSize = 1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;     
         case '3361x'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 660e6;
            arbConfig.maximumSampleRate = 660e6;
            arbConfig.minimumSampleRate = 1e3;
            arbConfig.minimumSegmentSize = 64;
            arbConfig.maximumSegmentSize = 1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;     
         case '3362x'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 1000e6;
            arbConfig.maximumSampleRate = 1000e6;
            arbConfig.minimumSampleRate = 1e3;
            arbConfig.minimumSegmentSize = 64;
            arbConfig.maximumSegmentSize = 1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;     
         case 'DSO90000'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 80e9;
            arbConfig.maximumSampleRate = 80e9;
            arbConfig.minimumSampleRate = 80e9;
            arbConfig.minimumSegmentSize = 1;
            arbConfig.maximumSegmentSize = 30*1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;     
         case 'N5194A_2GHz'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 2e9;
            arbConfig.maximumSampleRate = 2e9;
            arbConfig.minimumSampleRate = 2e9;
            arbConfig.minimumSegmentSize = 64;
            arbConfig.maximumSegmentSize = 2e9;
            arbConfig.segmentGranularity = 32;
            arbConfig.maxSegmentNumber = 65536;
        case 'N5194A_250MHz'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 250e6;
            arbConfig.maximumSampleRate = 250e6;
            arbConfig.minimumSampleRate = 100;
            arbConfig.minimumSegmentSize = 512;
            arbConfig.maximumSegmentSize = 4e9;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 65536; 
        case 'N5194A_250MHz_In'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 250e6;
            arbConfig.maximumSampleRate = 250e6;
            arbConfig.minimumSampleRate = 100;
            arbConfig.minimumSegmentSize = 512;
            arbConfig.maximumSegmentSize = 4e9;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 65536; 
% 		 case 'MUXDAC'  % temporary hack for MUXDAC experiments
%             try
%                 load('muxdac_setup');
%             catch
%                 error('muxdac_setup not found');
%             end
%             arbConfig.fixedSampleRate = 1;
%             arbConfig.defaultSampleRate = 2*fclk;
%             arbConfig.maximumSampleRate = 2*fclk;
%             arbConfig.minimumSampleRate = 2*fclk;
%             arbConfig.minimumSegmentSize = 1024;
%             arbConfig.maximumSegmentSize = floor(512*1024/90e9*2*fclk);
%             arbConfig.segmentGranularity = 1024;
%             arbConfig.maxSegmentNumber = 1;
%             arbConfig.numChannels = 2;
        case 'generic'  % generic AWG with minimum restrictions - for calculation purposes only
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 1e9;
            arbConfig.maximumSampleRate = 1e20;
            arbConfig.minimumSampleRate = 1e-20;
            arbConfig.minimumSegmentSize = 1;
            arbConfig.maximumSegmentSize = 1024*1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;
        otherwise
            errordlg('Unknown instrument model. Please use "Configure Instrument Connection" to set it.', 'Error');
    end
    % if an external sample clock is used, set the default/min/max sample
    % rates to that value and mark it as fixed
    if (isfield(arbConfig, 'clockSource') && strcmp(arbConfig.clockSource, 'ExtClk'))
        arbConfig.defaultSampleRate = arbConfig.clockFreq;
        arbConfig.maximumSampleRate = arbConfig.clockFreq;
        arbConfig.minimumSampleRate = arbConfig.clockFreq;
        arbConfig.fixedSampleRate = 1;
    end
    % if the channelMask field is not set to anything special yet,
    % set it to a reasonable default value
    if (~isfield(arbConfig, 'channelMask'))
        arbConfig.channelMask = ones(1, arbConfig.numChannels);
    end
    % update numChannels and channelMask in multi-module systems
    if (~isfield(arbConfig, 'maximumModules'))
        arbConfig.maximumModules = 1;
    elseif (arbConfig.maximumModules >= 4 && isfield(arbConfig, 'visaAddr4'))
        arbConfig.numChannels = arbConfig.numChannels * 4;
        arbConfig.channelMask = repmat(arbConfig.channelMask, 1, 4);
    elseif (arbConfig.maximumModules >= 3 && isfield(arbConfig, 'visaAddr3'))
        arbConfig.numChannels = arbConfig.numChannels * 3;
        arbConfig.channelMask = repmat(arbConfig.channelMask, 1, 3);
    elseif (arbConfig.maximumModules >= 2 && isfield(arbConfig, 'visaAddr2'))
        arbConfig.numChannels = arbConfig.numChannels * 2;
        arbConfig.channelMask = repmat(arbConfig.channelMask, 1, 2);
    end
    % for interleaving, the waveform granularity doubles, because we will
    % split even and odd samples later on.
    % Also, the sampling rate range doubles, because one channel is
    % delayed by half a period
    if (isfield(arbConfig, 'interleaving') && arbConfig.interleaving)
        arbConfig.defaultSampleRate = 2 * arbConfig.defaultSampleRate;
        arbConfig.maximumSampleRate = 2 * arbConfig.maximumSampleRate;
        arbConfig.minimumSampleRate = 2 * arbConfig.minimumSampleRate;
        arbConfig.minimumSegmentSize = 2 * arbConfig.minimumSegmentSize;
        arbConfig.maximumSegmentSize = 2 * arbConfig.maximumSegmentSize;
        arbConfig.segmentGranularity = 2 * arbConfig.segmentGranularity;
    end
    % if output arguments are available, return arbConfig (and saConfig)
    % otherwise, set arbConfig and saConfig variables in caller's space
    if (nargout >= 2)
        varargout{1} = arbConfig;
        varargout{2} = saConfig;
    elseif (nargout >= 1)
        varargout{1} = arbConfig;
    else
        assignin('caller', 'arbConfig', arbConfig);
        assignin('caller', 'saConfig', saConfig);
    end
end
