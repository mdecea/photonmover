# -*- coding: utf-8 -*-
"""
@author: twychock
"""

# -*- coding: utf-8 -*-
"""
% This is a test script to test the capabilities of the
%
%   Single Pulse Creation
%
%   set of commands with the IQ Server Toolkit
%
%   It:
%       1.Loads a variety of single pulse examples
%       2.Saves those pulses to a file
%       3.Previews those pulses in 89601B VSA (make sure to have VSA local to this controller)
%
%
%   Notes:
%       1.Make sure to have VSA local to this controller
%       2.Make sure the server is running to connect to it
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


# Example code
# Test Parameters
import scpi_sockets
import time
import os
debug_mode = 1  # Use debugging?
file_save_folder = r'C:\Temp'
# Also can select 'Vector' or 'Wideband Vector', 'M8190A_12bit', M8190A_14bit'
instrument_mode = 'Vector'
sample_rate_in_hz = 250E6  # Vector max is 250E6, Wideband is 2E9
download_waveform = True  # If instrument is set up in IQTools, downloads

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
    # Create the directory if it doesn't exist
    if not os.path.exists(file_save_folder):
        os.makedirs(file_save_folder)

    # Connect
    print('\n#####################')
    print(
        'Connecting to address "' +
        ipv4_address_server +
        '" and port "' +
        str(socket_port_server) +
        '"...')

    scpi_session_server = scpi_sockets.SCPISession(
        ipv4_address_string_in=ipv4_address_server,
        port_in=socket_port_server,
        enable_nagle_in=True,
        connect_in=False,
        debug_scpi_in=debug_mode,
        udp_in=udp_communication,
        udp_receive_port_in=socket_port_udp_receive)

    scpi_session_server.connect(
        timeout_in_seconds_in=timeout_in_seconds_server)
    is_connected = True
    time.sleep(1)

    ##########################################################################

    # Perform basic functions
    # IDN?
    return_string = scpi_session_server.query('*IDN?')
    print('Connected to: ' + return_string)
    # Debug Mode
    scpi_session_server.write(':SYST:DEBUG ' + str(debug_mode))
    # Reset
    scpi_session_server.write('*RST')

    # Set the Mode
    scpi_session_server.write(':INST:MODE ' + instrument_mode)
    return_string = scpi_session_server.query(':INST:MODE?')
    print('Mode: ' + return_string)

    # Create errors
    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write('BAD MESSAGE')

    file_save_name = r'Test_Bad_File'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:MOD ' + 'BAD MODULATION')
    scpi_session_server.write(
        ':GEN:PULS:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')
    scpi_session_server.query(':SYST:ERR?')
    scpi_session_server.query(':SYST:ERR?')
    scpi_session_server.query(':SYST:ERR?')

    ##########################################################################

    # Generate pulse, 10 us, no modulation
    print('\nGenerating pulse generic 10 us: ' + instrument_mode)
    input('Press enter to continue.\n')

    # Pulse parameters
    width_in_seconds = 10E-6
    dwell_in_seconds = 100E-6
    modulation_type = "{'None'}"

    file_save_name = 'Pulse_10_us'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(
        ':GEN:PULS:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')
    scpi_session_server.query(':SYST:ERR?')

    if download_waveform:
        scpi_session_server.write(':GEN:PULS:DOWNLOAD')
        input('Press enter to continue if prompted in download.\n')
        scpi_session_server.query('*OPC?')

    ##########################################################################

    # Generate pulse, 50 us, no modulation
    print('\nGenerating pulse generic 50 us: ' + instrument_mode)
    input('Press enter to continue.\n')

    # Pulse parameters
    width_in_seconds = 50E-6
    dwell_in_seconds = 100E-6
    modulation_type = "{'None'}"

    file_save_name = 'Pulse_50_us'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(
        ':GEN:PULS:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    if download_waveform:
        scpi_session_server.write(':GEN:PULS:DOWNLOAD')
        input('Press enter to continue if prompted in download.\n')
        scpi_session_server.query('*OPC?')

    ##########################################################################

    # Generate pulse, 50 us, chirp, 50 MHz
    print('\nGenerating pulse 50 MHz chirp, 50 us: ' + instrument_mode)
    input('Press enter to continue.\n')

    # Pulse parameters
    width_in_seconds = 50E-6
    dwell_in_seconds = 100E-6
    modulation_type = "{'increasing'}"
    chirp_deviation = 50E6

    file_save_name = 'Chirp_50_us'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(':GEN:PULS:FSPA ' + str(chirp_deviation))
    scpi_session_server.write(
        ':GEN:PULS:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    if download_waveform:
        scpi_session_server.write(':GEN:PULS:DOWNLOAD')
        input('Press enter to continue if prompted in download.\n')
        scpi_session_server.query('*OPC?')

    ##########################################################################

    # Generate pulse, 50 us, chirp, -50 MHz
    print('\nGenerating pulse -50 MHz chirp, 50 us: ' + instrument_mode)
    input('Press enter to continue.\n')

    # Pulse parameters
    width_in_seconds = 50E-6
    dwell_in_seconds = 100E-6
    modulation_type = "{'increasing'}"
    chirp_deviation = -50E6

    file_save_name = 'Chirp_Negative_50_us'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(':GEN:PULS:FSPA ' + str(chirp_deviation))
    scpi_session_server.write(
        ':GEN:PULS:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    if download_waveform:
        scpi_session_server.write(':GEN:PULS:DOWNLOAD')
        input('Press enter to continue if prompted in download.\n')
        scpi_session_server.query('*OPC?')

    ##########################################################################

    # Generate pulse, 50 us, barker 13
    print('\nGenerating pulse Barker 13, 50 us: ' + instrument_mode)
    input('Press enter to continue.\n')

    # Pulse parameters
    width_in_seconds = 50E-6
    dwell_in_seconds = 100E-6
    modulation_type = "{'barker-13'}"

    file_save_name = 'Barker13_50_us'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(
        ':GEN:PULS:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    if download_waveform:
        scpi_session_server.write(':GEN:PULS:DOWNLOAD')
        input('Press enter to continue if prompted in download.\n')
        scpi_session_server.query('*OPC?')

    ##########################################################################

    # Generate pulse phase coding
    print('\nGenerating pulse Frequency Mix: ' + instrument_mode)
    input('Press enter to continue.\n')

    # Pulse parameters
    width_in_seconds = '[0.5,0.5,0.5,0.5]*1e-06'
    dwell_in_seconds = '[0.6,0.5,0.5,1.4]*1e-06'
    rise_time_in_seconds = '[0.1,0,0,0]*1e-06'
    fall_time_in_seconds = '[0,0,0,0.1]*1e-06'
    phase_in_degrees = '[0,0,0,0]'
    chirp_deviation_in_hz = '[50E6,-50E6,0,25E6]'
    frequency_offset_in_hz = '[0,0,-25E6,-12.5E6]'
    modulation_type = "{'increasing'}"
    phase_transition = "{'continuous'}"

    file_save_name = 'Mix'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:RISE ' + str(rise_time_in_seconds))
    scpi_session_server.write(':GEN:PULS:FALL ' + str(fall_time_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(':GEN:PULS:FSPA ' + str(chirp_deviation_in_hz))
    scpi_session_server.write(
        ':GEN:PULS:FREQOF ' +
        str(frequency_offset_in_hz))
    scpi_session_server.write(':GEN:PULS:PTRAN ' + str(phase_transition))
    scpi_session_server.write(
        ':GEN:PULS:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    if download_waveform:
        scpi_session_server.write(':GEN:PULS:DOWNLOAD')
        input('Press enter to continue if prompted in download.\n')
        scpi_session_server.query('*OPC?')

    ##########################################################################

    # Generate pulse phase coding
    print('\nGenerating pulse Phase BPSK: ' + instrument_mode)
    input('Press enter to continue.\n')

    # Pulse parameters
    width_in_seconds = '[0.5,0.5,0.5,0.5]*1e-06'
    dwell_in_seconds = '[0.6,0.5,0.5,1.4]*1e-06'
    rise_time_in_seconds = '[0.1,0,0,0]*1e-06'
    fall_time_in_seconds = '[0,0,0,0.1]*1e-06'
    chirp_deviation_in_hz = '[0,0,0,0]'
    phase_in_degrees = '[170,90,45,90]'
    modulation_type = "{'increasing'}"
    phase_transition = "{'coherent'}"

    file_save_name = 'BPSK'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:RISE ' + str(rise_time_in_seconds))
    scpi_session_server.write(':GEN:PULS:FALL ' + str(fall_time_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(':GEN:PULS:FSPA ' + str(chirp_deviation_in_hz))
    scpi_session_server.write(':GEN:PULS:PHAS ' + str(phase_in_degrees))
    scpi_session_server.write(':GEN:PULS:PTRAN ' + str(phase_transition))
    scpi_session_server.write(
        ':GEN:PULS:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    if download_waveform:
        scpi_session_server.write(':GEN:PULS:DOWNLOAD')
        input('Press enter to continue if prompted in download.\n')
        scpi_session_server.query('*OPC?')

    ##########################################################################

except Exception as e:
    print('Error: ' + str(e))
finally:
    if is_connected:
        print('Connected, disconnecting...')
        scpi_session_server.write(':SYST:TCPIP CLOS')
        scpi_session_server.disconnect()
        print('Disconnected')
    input('\nProgram finished.\nPress enter to end.')
