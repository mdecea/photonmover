function IQToolsServer_Launch(varargin)
%
% This script launches an instance of the IQTools server
%
% T.Wychock, T.Dippon, Keysight Technologies 2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS.

%% Define computer-specific variables
% IP Address Local
ipAddressThisPC = '0.0.0.0';

% Ports
TCPIPPort = 30000;
UDPReceivePort = 30000;
UDPSendPort = 30001;

% Protocol
useUDP = false;

% restart server
restart = true;

% show commands
showCommands = true;

%% parse command line arguments
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'localaddress';    ipAddressThisPC = varargin{i+1};
            case 'tcpipport';       TCPIPPort = str2double(varargin{i+1});
            case 'udpreceiveport';  UDPReceivePort = str2double(varargin{i+1});
            case 'udptransmitport'; UDPSendPort = str2double(varargin{i+1});
            case 'udp';             useUDP = varargin{i+1};
            case 'restart';         restart = varargin{i+1};
            case 'showcommands';    showCommands = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

%% Launch the server
try  
    while (1)
        h = iqwaitbar('');
        % Launch the server
        disp('Launching Server...');
        if useUDP
            h.update(0, sprintf('Server waiting for connection (UDP port %d)...', UDPReceivePort));
            serverInstance = IQToolsServer(ipAddressThisPC, UDPReceivePort);
            
            if showCommands
               try
                   serverInstance.DocumentCommandDataHTMLFile()
               catch ex
                   disp(['Error documenting commands: ' getReport(ex,'extended')]);
                   errordlg(['Error: ' ex.message]);
               end
            end
            
            serverInstance.LaunchServerUDP(UDPSendPort);
        else
            h.update(0, sprintf('Server waiting for connection (TCP port %d)...', TCPIPPort));
            serverInstance = IQToolsServer(ipAddressThisPC, TCPIPPort);
            
            if showCommands
               try
                   serverInstance.DocumentCommandDataHTMLFile()
               catch ex
                   disp(['Error documenting commands: ' getReport(ex,'extended')]);
                   errordlg(['Error: ' ex.message]);
               end
            end
            
            serverInstance.LaunchServerTCPIP();
        end
                
        assignin('base', 'serverInstance', serverInstance);
        
        % exit the main loop if no re-start is required
        if (~restart)
            break;
        end
        
        cnt = 0;
        while (strcmp(serverInstance.Server.ServerInstance.Status, 'open'))
            cnt = cnt + 1;
            h.update(cnt/10-floor(cnt/10), sprintf('Sent %d, Received %d', ...
                serverInstance.Server.ServerInstance.ValuesSent, ...
                serverInstance.Server.ServerInstance.ValuesReceived));
            if (h.canceling())
                restart = false;
                if (~useUDP)
                    serverInstance.CloseServerTCPIP();
                end
                break;
            end
            pause(1);
        end
        delete(serverInstance);
        
        % don't show commands every time
        showCommands = false;
        % exit the main loop if no re-start is required
        if (~restart)
            break;
        end
        
    end
   
catch ex
    disp(['Error launching server: ' getReport(ex,'extended')]);
    errordlg(['Error: ' ex.message]);
end
end

