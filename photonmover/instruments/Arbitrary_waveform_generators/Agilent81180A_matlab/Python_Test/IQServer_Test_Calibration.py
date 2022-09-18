# -*- coding: utf-8 -*-
"""
@author: twychock
"""

# -*- coding: utf-8 -*-
"""
% This is a test script to test the capabilities of the
%
%   Calibration
%
%   set of commands with the IQ Server Toolkit
%
%   It:
%       1.Performs a batch calibration for a defined set of amplitudes and phases
%
%
%   Notes:
%       1.VSA can run locally or remotely
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
import datetime
debug_mode = 1  # Use debugging?
file_save_folder = r'C:\Temp'
# Also can select 'Vector' or 'Wideband Vector', 'M8190A_12bit', M8190A_14bit'
instrument_mode = 'Vector Internal'
sample_rate_in_hz = 250E6  # Vector max is 250E6, Wideband is 2E9

cal_frequency_span = 200E6  # The calibration span for each point
cal_frequency_spacing = 1E6  # The calibration spacing for each point

cal_power_start_dbm = -20  # The starting power for each frequency point in dBm
cal_power_stop_dbm = 0  # The stop power for each frequency point in dBm
cal_power_increment_db = 10  # The cal increment

cal_frequency_start_hz = 1E9  # The starting frequency
cal_frequency_stop_hz = 20E9  # The stop frequency
cal_frequency_increment_hz = 1E9  # The frequency increment

cal_settling_time_s = 0.1  # Cal settling time

# IO Parameters
ipv4_address_server = '127.0.0.1'  # IPv4 Address of the server
socket_port_server = 30000  # Socket Port of the server
socket_port_udp_receive = 30001  # UDP port to receive from (if using UDP)
timeout_in_seconds_server = 30  # Initial timeout of the server
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

    # Configure the calibration parameters for the single point
    scpi_session_server.write(':CAL:FSPAN ' + str(cal_frequency_span))
    scpi_session_server.write(':CAL:FSPAC ' + str(cal_frequency_spacing))

    # Perform a calibration at each frequency and power level
    # First do an initialize
    print('Performing a calibration with the following parameters:')
    print('Frequency start: ' + str(cal_frequency_start_hz) + ' Hz')
    print('Frequency stop: ' + str(cal_frequency_stop_hz) + ' Hz')
    print('Frequency step: ' + str(cal_frequency_increment_hz) + ' Hz')
    print('Power start: ' + str(cal_power_start_dbm) + ' dBm')
    print('Power stop: ' + str(cal_power_stop_dbm) + ' dBm')
    print('Power step: ' + str(cal_power_increment_db) + 'dB')
    print('Calibration span: ' + str(cal_frequency_span) + ' Hz')
    print('Calibration spacing: ' + str(cal_frequency_spacing) + ' Hz')
    print('\n')

    print('Initializing calibration...')
    scpi_session_server.write(':CAL:INIT ' + str(1))
    scpi_session_server.write(':CAL:ARANG ' + str(1))
    scpi_session_server.write(':CAL:TSETT ' + str(cal_settling_time_s))
    scpi_session_server.write(':CAL:FCENT ' + str(cal_frequency_start_hz))

    # Set the carrier frequency to the first point
    scpi_session_server.write(':INST:RFFREQ ' + str(cal_frequency_start_hz))
    scpi_session_server.write(':INST:RFPOW ' + str(cal_power_start_dbm))
    scpi_session_server.write(':INST:RFON ' + str(1))

    # Run the first calibration
    print('Running first calibration...')
    scpi_session_server.write(':CAL:EXE')
    scpi_session_server.query('*OPC?')
    print('Calibration initialized and complete.')

    # Batch calibration
    scpi_session_server.write(':CAL:INIT ' + str(0))
    scpi_session_server.write(':CAL:ARANG ' + str(0))

    # Step through each point
    frequency_current = cal_frequency_start_hz
    amplitude_current = cal_power_start_dbm

    time_start = datetime.datetime.now()

    # Power
    while amplitude_current <= cal_power_stop_dbm:
        # Range
        scpi_session_server.write(':INST:RFPOW ' + str(amplitude_current))
        scpi_session_server.write(':CAL:RANG ' + str(amplitude_current))

        frequency_current = cal_frequency_start_hz
        while frequency_current <= cal_frequency_stop_hz:
            # Tune
            scpi_session_server.write(':INST:RFFREQ ' + str(frequency_current))
            scpi_session_server.write(':CAL:FCENT ' + str(frequency_current))

            print('Calibrate Frequency: ' + str(frequency_current) + ' Hz')
            print('Calibrate Power: ' + str(amplitude_current) + ' dBm')
            print('Calibrating...')

            file_save_current = 'Corrections_' + \
                str(int(frequency_current)) + '_' + str(int(amplitude_current)) + '.mat'
            scpi_session_server.write(
                ':CAL:FSAV ' +
                file_save_folder +
                '\\' +
                file_save_current)

            # Calibrate and save
            scpi_session_server.write(':CAL:EXE')
            scpi_session_server.query('*OPC?')
            scpi_session_server.write(':CAL:SAVE')
            scpi_session_server.query('*OPC?')
            print('Calibration complete!\n')

            frequency_current = frequency_current + cal_frequency_increment_hz

        amplitude_current = amplitude_current + cal_power_increment_db

        time_stop = datetime.datetime.now()
        time_delta = time_stop - time_start

        print('Calibration complete.')
        print('Calibration time: ' + str(time_delta.seconds) + ' seconds.')

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
