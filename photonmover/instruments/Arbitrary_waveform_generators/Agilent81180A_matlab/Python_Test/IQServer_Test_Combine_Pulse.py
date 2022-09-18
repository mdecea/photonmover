# -*- coding: utf-8 -*-
"""
@author: twychock
"""

# -*- coding: utf-8 -*-
"""
% This is a test script to test the capabilities of the
%
%   Combined Pulse Creation
%
%   set of commands with the IQ Server Toolkit
%
%   It:
%       1.Loads a variety of combined pulse examples
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
instrument_mode = 'Wideband Vector'
sample_rate_in_hz = 2E9  # Vector max is 250E6, Wideband is 2E9
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

    ##########################################################################

    # Pulse parameters
    width_in_seconds = 10E-6
    dwell_in_seconds = 15E-6
    modulation_type = "{'None'}"

    file_save_name = 'Pulse_Simple'

    # Generate pulse, no modulation
    print('\nGenerating pulse with width of ' + str(width_in_seconds) + ' s')
    input('Press enter to continue.\n')

    # Reset the pulses
    scpi_session_server.write(':GEN:PULS:COMB:RESET')
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

    # Now, generate a few
    pri_in_seconds = 20E-6
    length_in_time_in_seconds = 0.5E-3
    amplitude_in_db = 0
    amplitude_adder_in_db = -3

    file_save_name = 'Pulse_Simple_Combo'

    # Ask to continue
    print(
        '\nGenerating pulse with width of ' +
        str(width_in_seconds) +
        ' s, PRI of ' +
        str(pri_in_seconds) +
        ' s, duration of ' +
        str(length_in_time_in_seconds) +
        ' s, power slope of ' +
        str(amplitude_adder_in_db) +
        ' dB')
    input('Press enter to continue.\n')

    for time_idx in range(int(length_in_time_in_seconds / pri_in_seconds)):
        scpi_session_server.write(
            ':GEN:PULS:COMB:TSTART ' + str(time_idx * pri_in_seconds))
        scpi_session_server.write(
            ':GEN:PULS:COMB:AMP ' + str(amplitude_in_db + amplitude_adder_in_db * time_idx))
        scpi_session_server.write(':GEN:PULS:COMB:ADD')
        scpi_session_server.query('*OPC?')

    # Preview and save
    # Set the timeout a little longer
    scpi_session_server.timeout_in_seconds = 20
    scpi_session_server.write(
        ':GEN:PULS:COMB:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:COMB:SAVE')
    scpi_session_server.write(':GEN:PULS:COMB:VSA')
    scpi_session_server.query('*OPC?')
    return_string = scpi_session_server.query(':GEN:PULS:COMB:OFFSETAMP?')
    print("Modified amplitude scale: " + return_string + " dB")
    return_string = scpi_session_server.query(':GEN:PULS:COMB:OFFSETTIME?')
    print("Modified time: " + return_string + " s")

    if download_waveform:
        scpi_session_server.write(':GEN:PULS:COMB:DOWNLOAD')
        input('Press enter to continue if prompted in download.\n')
        scpi_session_server.query('*OPC?')

    ##########################################################################

    # Now, combine two pulse trains
    length_in_time_in_seconds = 0.5E-3

    width_in_seconds_1 = 10E-6
    dwell_in_seconds_1 = 15E-6
    modulation_type_1 = "{'None'}"
    pri_in_seconds_1 = 50E-6
    amplitude_in_db_1 = 0
    f_offset_hz_1 = -1E6
    time_offset_s_1 = 0

    width_in_seconds_2 = 5E-6
    dwell_in_seconds_2 = 6E-6
    modulation_type_2 = "{'None'}"
    pri_in_seconds_2 = 10E-6
    amplitude_in_db_2 = -6
    f_offset_hz_2 = 5E6
    time_offset_s_2 = 1E-6

    file_save_name = 'Pulse_Simple_Multi_Combo'

    # Ask to continue
    print('\nGenerating a combination of two pulses...')
    input('Press enter to continue.\n')

    # Reset the pulses
    scpi_session_server.write(':GEN:PULS:COMB:RESET')

    # Generate the first
    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds_1))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds_1))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type_1))
    scpi_session_server.write(':GEN:PULS:FREQOF ' + str(f_offset_hz_1))
    scpi_session_server.query('*OPC?')
    scpi_session_server.query(':SYST:ERR?')

    for time_idx in range(int(length_in_time_in_seconds / pri_in_seconds_1)):
        scpi_session_server.write(
            ':GEN:PULS:COMB:TSTART ' + str(time_offset_s_1 + time_idx * pri_in_seconds_1))
        scpi_session_server.write(
            ':GEN:PULS:COMB:AMP ' +
            str(amplitude_in_db_1))
        scpi_session_server.write(':GEN:PULS:COMB:ADD')
        scpi_session_server.query('*OPC?')

    # Now the second
    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds_2))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds_2))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type_2))
    scpi_session_server.write(':GEN:PULS:FREQOF ' + str(f_offset_hz_2))
    scpi_session_server.query('*OPC?')
    scpi_session_server.query(':SYST:ERR?')

    for time_idx in range(int(length_in_time_in_seconds / pri_in_seconds_2)):
        scpi_session_server.write(
            ':GEN:PULS:COMB:TSTART ' + str(time_offset_s_2 + time_idx * pri_in_seconds_2))
        scpi_session_server.write(
            ':GEN:PULS:COMB:AMP ' +
            str(amplitude_in_db_2))
        scpi_session_server.write(':GEN:PULS:COMB:ADD')
        scpi_session_server.query('*OPC?')

    # Preview and save
    # Set the timeout a little longer
    scpi_session_server.timeout_in_seconds = 20
    scpi_session_server.write(
        ':GEN:PULS:COMB:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:COMB:SAVE')
    scpi_session_server.write(':GEN:PULS:COMB:VSA')
    scpi_session_server.query('*OPC?')
    return_string = scpi_session_server.query(':GEN:PULS:COMB:OFFSETAMP?')
    print("Modified amplitude scale: " + return_string + " dB")
    return_string = scpi_session_server.query(':GEN:PULS:COMB:OFFSETTIME?')
    print("Modified time: " + return_string + " s")

    if download_waveform:
        scpi_session_server.write(':GEN:PULS:COMB:DOWNLOAD')
        input('Press enter to continue if prompted in download.\n')
        scpi_session_server.query('*OPC?')

    ##########################################################################

    width_in_seconds_list = [2E-6, 1E-6, 1E-6, 2E-6, 5E-6, 10E-6, 3E-6]
    dwell_in_seconds_list = [3E-6, 2E-6, 2E-6, 3E-6, 6E-6, 11E-6, 4E-6]
    modulation_type_list = [
        "{'None'}",
        "{'None'}",
        "{'None'}",
        "{'None'}",
        "{'None'}",
        "{'None'}",
        "{'None'}"]
    pri_in_seconds_list = [50E-6, 10E-6, 20E-6, 50E-6, 100E-6, 100E-6, 50E-6]
    amplitude_in_db_list = [0, -6, -3, -10, -20, 0, 0]
    f_offset_hz_list = [1E6, -5E6, 20E6, -50E6, 100E6, -25E6, 75E6]
    time_offset_s_list = [1E-6, 3E-6, 1E-6, 5E-6, 2E-6, 7E-6, 20E-6]
    length_in_time_in_seconds = 1E-3

    file_save_name = 'Pulse_Simple_Multi_Many'

    print('\nGenerating a combination of many pulses...')
    input('Press enter to continue.\n')

    # Reset the pulses
    scpi_session_server.write(':GEN:PULS:COMB:RESET')

    # For each pulse, create the pulse, then add them to the combiner
    for width_current, dwell_current, modulation_type_current, pri_current, amplitude_current, f_current, time_current \
            in zip(width_in_seconds_list, dwell_in_seconds_list, modulation_type_list, pri_in_seconds_list,
                   amplitude_in_db_list, f_offset_hz_list, time_offset_s_list):

        # Generate the single pulse
        scpi_session_server.write(':GEN:PULS:RESET ')
        scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
        scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_current))
        scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_current))
        scpi_session_server.write(
            ':GEN:PULS:MOD ' +
            str(modulation_type_current))
        scpi_session_server.write(':GEN:PULS:FREQOF ' + str(f_current))
        scpi_session_server.query('*OPC?')
        scpi_session_server.query(':SYST:ERR?')

        for time_idx in range(int(length_in_time_in_seconds / pri_current)):
            scpi_session_server.write(
                ':GEN:PULS:COMB:TSTART ' + str(time_current + time_idx * pri_current))
            scpi_session_server.write(
                ':GEN:PULS:COMB:AMP ' +
                str(amplitude_current))
            scpi_session_server.write(':GEN:PULS:COMB:ADD')
            scpi_session_server.query('*OPC?')

    # Preview and save
    # Set the timeout a little longer
    scpi_session_server.timeout_in_seconds = 100
    scpi_session_server.write(
        ':GEN:PULS:COMB:FSAV ' +
        file_save_folder +
        '\\' +
        file_save_name)
    scpi_session_server.write(':GEN:PULS:COMB:SAVE')
    scpi_session_server.write(':GEN:PULS:COMB:VSA')
    scpi_session_server.query('*OPC?')
    return_string = scpi_session_server.query(':GEN:PULS:COMB:OFFSETAMP?')
    print("Modified amplitude scale: " + return_string + " dB")
    return_string = scpi_session_server.query(':GEN:PULS:COMB:OFFSETTIME?')
    print("Modified time: " + return_string + " s")

    if download_waveform:
        scpi_session_server.write(':GEN:PULS:COMB:DOWNLOAD')
        input('Press enter to continue if prompted in download.\n')
        scpi_session_server.query('*OPC?')

    ##########################################################################

except Exception as e:
    print('Error: ' + str(e))
finally:
    if is_connected:
        print('\nConnected, disconnecting...')
        scpi_session_server.write(':SYST:TCPIP CLOS')
        scpi_session_server.disconnect()
        print('Disconnected')
    input('\nProgram finished.\nPress enter to end.')
