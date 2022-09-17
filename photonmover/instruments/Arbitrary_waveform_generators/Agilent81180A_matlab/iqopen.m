function f = iqopen(cfg)
% open an instrument connection
% argument is expected to be a struct or a string.
% If it is a struct, the following members are expected:
%  connectionType - 'tcpip' or 'visa', 'visa-tcpip', 'visa-gpib'
%  visaAddr - VISA resource string for all visa-... types
%  ip_address - for tcpip only
%  port - for tcpip only
% If it is a string, it should contain the visa address
% If no argument is given, the configuration from iqconfig is used
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    f = [];

% if no argument is supplied, use the default configuration file
    if (~exist('cfg', 'var'))
        cfg = loadArbConfig();
    end
% if a string is supplied, assume that it is a visa address
    if (~isstruct(cfg))
        newCfg.visaAddr = cfg;
        newCfg.connectionType = 'visa';
        cfg = newCfg;
    end
% for M8195A_Rev0, there is no TCPIP connection - just return a non-empty
% value to keep the rest of the code happy...
    if (isfield(cfg, 'model') && ~isempty(strfind(cfg.model, 'M8195A_Rev0')))
        f = 42;
        return;
    end
% if visa address is of the format TCPIPx::ip_address::port::SOCKET,
% treat it as a tcpip connection (MATLAB visa can't use them)
    if (strcmp(cfg.connectionType, 'visa') && ~isempty(strfind(cfg.visaAddr, '::SOCKET')))
        cfg.connectionType = 'tcpip';
        try
            [dummy parts] = regexp(cfg.visaAddr, '::', 'match', 'split');
            cfg.ip_address = parts{2};
            cfg.port = str2double(parts{3});
        catch
            errordlg('incorrectly formed VISA address');
        end
    end

    switch lower(cfg.connectionType)
        case { 'visa', 'visa-tcpip', 'visa-gpib', 'visa-usb', 'visa-pxi' } %  Robin Adds Visa-pxi type
            addr = cfg.visaAddr;
            i_list = instrfind('Alias', cfg.visaAddr);
            if isempty(i_list)
                i_list = instrfind('RsrcName', cfg.visaAddr);
            end
            % if no previous connection is available, open a new one
            if isempty(i_list)
                try
                    f = visa('agilent', cfg.visaAddr);
                catch e
                    if (~isempty(strfind(e.message, 'Invalid RSRCNAME')))
                        errordlg(sprintf(['Can''t connect to "%s".\n' ...
                            'Please verify that you specified a valid VISA address.\n\n' ...
                            'Error message:\n%s'], cfg.visaAddr, e.message), 'Error', 'replace');
                    else
                        errordlg({'Error calling visa(). Please verify that' ...
                            'you have the "Instrument Control Toolbox" installed' ...
                            'MATLAB error message:' e.message}, 'Error', 'replace');
                    end
                    f = [];
                end
            else
                f = i_list(1);
            end
        case 'tcpip'
            addr = cfg.ip_address;
            i_list = instrfind('Type', 'tcpip', 'RemoteHost', cfg.ip_address, 'RemotePort', cfg.port);
            if isempty(i_list)
                try
                    f = tcpip(cfg.ip_address, cfg.port);
                catch e
                    errordlg({'Error calling tcpip(). Please verify that' ...
                        'you have the "Instrument Control Toolbox" installed' ...
                        'MATLAB error message:' e.message}, 'Error');
                    f = [];
                end
            else
                f = i_list(1);
            end
        otherwise
            error('usage: invalid connection type');
    end

    if (~isempty(f) && strcmp(f.Status, 'closed'))
        f.OutputBufferSize = 20000000;
        f.InputBufferSize = 12800000;
        f.Timeout = 35;
        try
            fopen(f);
        catch e
            errordlg({'Could not open connection to ' addr ...
                      'Please verify that you specified the correct address' ...
                      'in the "Configure Instrument Connection" dialog.' ...
                      'Verify that you can communicate with the' ...
                      'instrument using the Keysight Connection Expert'}, 'Error');
            f = [];
        end
    end
end
