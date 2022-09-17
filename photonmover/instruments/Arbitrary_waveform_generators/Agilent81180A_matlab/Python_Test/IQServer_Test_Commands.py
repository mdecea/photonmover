# -*- coding: utf-8 -*-
"""
@author: twychock
"""

# -*- coding: utf-8 -*-
"""
% This is a test script to test the capabilities of the
%
%   Scripting commands
%
%   set of commands with the IQ Server Toolkit
%
%   It:
%       1.Shows a few examples of single commands to execute
%       2.Shows a few examples of batches of commands to execute
%
%
%
%   Notes:
%       1.Make sure the server is running to connect to it
%
%   Version 1.0
%
% T.Wychock, Keysight Technologies 2018
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 
"""

import scpi_sockets
import time
import os

# Example code
# Test Parameters
debug_mode = 1  # Use debugging?

# IO Parameters
ipv4_address_server = '127.0.0.1'  # IPv4 Address of the server
socket_port_server = 30000  # Socket Port of the server
socket_port_udp_receive = 30001  # UDP port to receive from (if using UDP)
timeout_in_seconds_server = 5  # Initial timeout of the server
udp_communication = False

# Run the script
is_connected = False
scpi_session_server = []

try:

    # Connect
    print('\n#####################')
    print('Connecting to address "' + ipv4_address_server + '" and port "' + str(socket_port_server) + '"...')

    scpi_session_server = scpi_sockets.SCPISession(ipv4_address_string_in=ipv4_address_server,
                                                   port_in=socket_port_server,
                                                   enable_nagle_in=True,
                                                   connect_in=False,
                                                   debug_scpi_in=debug_mode,
                                                   udp_in=udp_communication,
                                                   udp_receive_port_in=socket_port_udp_receive)

    scpi_session_server.connect(timeout_in_seconds_in=timeout_in_seconds_server)
    is_connected = True
    time.sleep(1)

    ####################################################################################################################

    # Perform basic functions
    # IDN?
    return_string = scpi_session_server.query('*IDN?')
    print('Connected to: ' + return_string)
    # Debug Mode
    scpi_session_server.write(':SYST:DEBUG ' + str(debug_mode))
    # Reset
    scpi_session_server.write('*RST')

    ####################################################################################################################

    # Command example, plotting a new figure with a few commands
    command_one = "'figure'"
    command_two = "'plot(1:10, 2:2:20)'"
    command_three = "'grid on'"

    # Execute commands
    print('\nPlotting a basic graph with two commands')
    input('Press enter to continue.\n')

    # Send the commands
    scpi_session_server.write(':SCRIPT:EVAL ' + command_one)  # Eval one command at a time
    scpi_session_server.write(':SCRIPT:EVAL ' + command_two)
    scpi_session_server.write(':SCRIPT:EVAL ' + command_three)
    scpi_session_server.query('*OPC?')
    scpi_session_server.query(':SYST:ERR?')

    ####################################################################################################################

    # Command example, plotting a new figure with a batch of commands
    command_one = "'figure'"
    command_two = "'plot(1:10, 2:2:20)'"
    command_three = "'grid on'"

    # Execute commands
    print('\nPlotting a basic graph with a batch of commands')
    input('Press enter to continue.\n')

    # Send the commands
    scpi_session_server.write(':SCRIPT:LIST:ADD ' + command_one)  # Add each command
    scpi_session_server.write(':SCRIPT:LIST:ADD ' + command_two)
    scpi_session_server.write(':SCRIPT:LIST:ADD ' + command_three)
    scpi_session_server.write(':SCRIPT:LIST:EXE')  # Eval the list
    scpi_session_server.query('*OPC?')
    scpi_session_server.query(':SYST:ERR?')

    ####################################################################################################################

except Exception as e:
    print('Error: ' + str(e))
finally:
    if is_connected:
        print('\nConnected, disconnecting...')
        scpi_session_server.write(':SYST:TCPIP CLOS')
        scpi_session_server.disconnect()
        print('Disconnected')
    input('\nProgram finished.\nPress enter to end.')
