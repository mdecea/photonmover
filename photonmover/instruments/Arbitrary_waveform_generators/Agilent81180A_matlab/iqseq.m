function result = iqseq(cmd, sequence, varargin)
% define and run a sequence or execute sequence-related commands
% 
% 'cmd' must contain one of the following command strings:
%       'list' - shows a list of all defined segments (also returns a
%                vector with the defined segments)
%       'delete' - delete the sequence table
%       'event' - force an event signal
%       'trigger' - force a trigger signal
%       'select' - select the segment in sequence
%       'define' - define a sequence in sequence
% For the M8190A only, the following additional commands are available:
%       'amplitudeTable' - define the amplitude table
%       'frequencyTable' - define the frequency table
%       'actionDefine' - define a new action, returns the action ID
%       'actionAppend' - append a new action to a previously defined
%       'actionDelete' - delete the action in seqcmd.sequence
%       'actionDeleteAll' - delete all actions
%
% if cmd equals 'define', then
% sequence must contain a vector of structs with the following elements.
%     sequence(i).segmentNumber
%     sequence(i).segmentLoop    (Optional. Default = 1)
%     sequence(i).advanceMode    (Optional. Default = 'auto')
%     sequence(i).markerEnable   (Optional. Default = false)
% where:
% <segmentNumber> is the segment number (starting with 1)
% <segmentLoop> indicates how often the segment will be repeated (1 to 2^32)
% <advanceMode> is one of 'Auto', 'Conditional', 'Repeat', 'Stepped'
% <markerEnable> is true or false and indicated is the marker that is
%        defined in this segment will be generated on the output or not
%
% For the M8190A *ONLY*:
% The sequence struct can optionally contain 5 more elements:
%  sequence(i).sequenceInit        (0 or 1, 1=start of sequence, default: 0)
%  sequence(i).sequenceEnd         (0 or 1, 1=end of sequence, default: 0)
%  sequence(i).sequenceLoop        (1 to 2^32: sequence repeat count, default: 1)
%  sequence(i).sequenceAdvanceMode (same possible values as segmentAdvanceMode, default: 'auto')
%  sequence(i).scenarioEnd         (0 or 1, 1=end of scenario, default: 0)
%  sequence(i).amplitudeInit       (0 or 1, 1=initialize amplitude pointer. Default = 0)
%  sequence(i).amplitudeNext       (0 or 1, 1=use next amplitude value. Default = 0)
%  sequence(i).frequencyInit       (0 or 1, 1=initialize frequency pointer. Default = 0)
%  sequence(i).frequencyNext       (0 or 1, 1=use next frequency value. Default = 0)
%  sequence(i).actionID            (0 to 2^24-1, -1 = unused. Default: -1)
%
% For the M8190A *only*:
% <segmentNumber> can be zero to indicate an "idle" command. In that case,
% <segmentLoop> indicates the number of samples to pause
%
% For the M8190A *only*:
% if cmd equals 'actionDefine', then
% sequence must contain a cell array with alternating strings and values.
% The string represents the type of action and value is a vector of
% associated parameter(s). Valid action strings are:
% Action            Action String  Parameters
% Carrier Frequency CFRequency	   [ integral part of frequency in Hz, fractional part of frequency in Hz ]
% Phase Offset      POFFset        [ phase in parts of full cycle (-0.5 ... +0.5)]
% Phase Reset       PRESet         [ phase in parts of full cycle (-0.5 ... +0.5)]
% Phase Bump        PBUMp          [ phase in parts of full cycle (-0.5 ... +0.5)]
% Sweep Rate        SRATe          [ Sweep Rate integral part in Hz/us, sweep rate fractional part in Hz/us ]
% Sweep Run         SRUN           []
% Sweep Hold        SHOLd          []
% Sweep Restart     SREStart       []
% Amplitude         AMPLitude      [ Amplitude in the range 0...1 ]
% the call will return an "actionID", which can be used in a sequence entry
%
% For an example usage, see the source code of M8190A-specific examples:
% (seqtest1.m, seqtest3.m, etc.)
%
if (~exist('cmd', 'var'))
    arbConfig = loadArbConfig();
    if (~isempty(strfind(arbConfig.model, 'M8190A')))
        iqseq_M8190A_gui;
    elseif (~isempty(strfind(arbConfig.model, 'M8195A')) && isempty(strfind(arbConfig.model, 'M8195A_Rev1')))
        iqseq_M8195A_gui;
    elseif (~isempty(strfind(arbConfig.model, '81180')))
        iqseq_gui;
    else
        errordlg('Sequencer not supported for this AWG model');
    end
    return;
end
seqcmd.cmd = cmd;
if (exist('sequence', 'var'))
    seqcmd.sequence = sequence;
end
result = iqdownload([], 0, 'sequence', seqcmd, varargin{:});
end
