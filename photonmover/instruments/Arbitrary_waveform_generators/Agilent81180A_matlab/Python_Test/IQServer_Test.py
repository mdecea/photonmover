# -*- coding: utf-8 -*-
"""
@author: twychock
"""

# -*- coding: utf-8 -*-
"""
% This is a simple example for the M9195B DSR SCPI interface
%
% Version 0.5
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
# IO Parameters
import scpi_sockets
import time
debug_mode = 1
ipv4_address_server = '127.0.0.1'
socket_port_server = 30000
timeout_in_seconds_server = 5

# Run the script
is_connected = False
scpi_session_server = []

try:
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
        debug_scpi_in=True)
    scpi_session_server.connect(
        timeout_in_seconds_in=timeout_in_seconds_server)
    is_connected = True
    time.sleep(1)

    # Perform basic functions
    # Debug Mode
    scpi_session_server.write(':GEN:PULS:RESET ')

    # IDN?
    return_string = scpi_session_server.query('*IDN?')
    print('Connected to: ' + return_string)

    # Wideband Vector Mode
    scpi_session_server.write(':INST:MODE Wideband Vector')
    return_string = scpi_session_server.query(':INST:MODE?')
    print('Mode: ' + return_string)

    # Create errors
    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write('BAD MESSAGE')
    scpi_session_server.write(':SYST:DEBUG ' + str(debug_mode))

    local_path = r'C:\Temp\Test\Bad_File'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:MOD ' + 'BAD MODULATION')
    scpi_session_server.write(':GEN:PULS:FSAV ' + local_path)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')
    scpi_session_server.query(':SYST:ERR?')
    scpi_session_server.query(':SYST:ERR?')
    scpi_session_server.query(':SYST:ERR?')

    # Generate pulse, 10 us, no modulation
    print('Generating pulse generic 10 us: ' + return_string)
    input('Press enter to continue.')

    # Pulse parameters
    sample_rate_in_hz = 2E9
    width_in_seconds = 10E-6
    dwell_in_seconds = 100E-6
    modulation_type = "{'None'}"

    local_path = r'C:\Temp\Test\Pulse_10_us'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(':GEN:PULS:FSAV ' + local_path)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')
    scpi_session_server.query(':SYST:ERR?')

    # Generate pulse, 50 us, no modulation
    print('Generating pulse generic 50 us: ' + return_string)
    input('Press enter to continue.')

    # Pulse parameters
    sample_rate_in_hz = 2E9
    width_in_seconds = 50E-6
    dwell_in_seconds = 100E-6
    modulation_type = "{'None'}"

    local_path = r'C:\Temp\Test\Pulse_50_us'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(':GEN:PULS:FSAV ' + local_path)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    # Generate pulse, 50 us, chirp, 50 MHz
    print('Generating pulse 50 MHz chirp, 50 us: ' + return_string)
    input('Press enter to continue.')

    # Pulse parameters
    sample_rate_in_hz = 2E9
    width_in_seconds = 50E-6
    dwell_in_seconds = 100E-6
    modulation_type = "{'increasing'}"
    chirp_deviation = 50E6

    local_path = r'C:\Temp\Test\Chirp_50_us'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(':GEN:PULS:FSPA ' + str(chirp_deviation))
    scpi_session_server.write(':GEN:PULS:FSAV ' + local_path)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    # Generate pulse, 50 us, chirp, 50 MHz
    print('Generating pulse -50 MHz chirp, 50 us: ' + return_string)
    input('Press enter to continue.')

    # Pulse parameters
    sample_rate_in_hz = 2E9
    width_in_seconds = 50E-6
    dwell_in_seconds = 100E-6
    modulation_type = "{'increasing'}"
    chirp_deviation = -50E6

    local_path = r'C:\Temp\Test\Chirp_Negative_50_us'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(':GEN:PULS:FSPA ' + str(chirp_deviation))
    scpi_session_server.write(':GEN:PULS:FSAV ' + local_path)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    # Generate pulse, 50 us, barker 13
    print('Generating pulse Barker 13, 50 us: ' + return_string)
    input('Press enter to continue.')

    # Pulse parameters
    sample_rate_in_hz = 2E9
    width_in_seconds = 50E-6
    dwell_in_seconds = 100E-6
    modulation_type = "{'barker-13'}"

    local_path = r'C:\Temp\Test\Barker13_50_us'

    scpi_session_server.write(':GEN:PULS:RESET ')
    scpi_session_server.write(':GEN:PULS:SRAT ' + str(sample_rate_in_hz))
    scpi_session_server.write(':GEN:PULS:DWEL ' + str(dwell_in_seconds))
    scpi_session_server.write(':GEN:PULS:WIDT ' + str(width_in_seconds))
    scpi_session_server.write(':GEN:PULS:MOD ' + str(modulation_type))
    scpi_session_server.write(':GEN:PULS:FSAV ' + local_path)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    # Generate pulse phase coding
    print('Generating pulse Frequency Mix: ' + return_string)
    input('Press enter to continue.')

    # Pulse parameters
    sample_rate_in_hz = 2E9
    width_in_seconds = '[0.5,0.5,0.5,0.5]*1e-06'
    dwell_in_seconds = '[0.6,0.5,0.5,1.4]*1e-06'
    rise_time_in_seconds = '[0.1,0,0,0]*1e-06'
    fall_time_in_seconds = '[0,0,0,0.1]*1e-06'
    phase_in_degrees = '[0,0,0,0]'
    chirp_deviation_in_hz = '[50E6,-50E6,0,25E6]'
    frequency_offset_in_hz = '[0,0,-25E6,-12.5E6]'
    modulation_type = "{'increasing'}"
    phase_transition = "{'continuous'}"

    local_path = r'C:\Temp\Test\Mix'

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
    scpi_session_server.write(':GEN:PULS:FSAV ' + local_path)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')

    # Generate pulse phase coding
    print('Generating pulse Phase BPSK: ' + return_string)
    input('Press enter to continue.')

    # Pulse parameters
    sample_rate_in_hz = 2E9
    width_in_seconds = '[0.5,0.5,0.5,0.5]*1e-06'
    dwell_in_seconds = '[0.6,0.5,0.5,1.4]*1e-06'
    rise_time_in_seconds = '[0.1,0,0,0]*1e-06'
    fall_time_in_seconds = '[0,0,0,0.1]*1e-06'
    chirp_deviation_in_hz = '[0,0,0,0]'
    phase_in_degrees = '[180,0,180,0]'
    modulation_type = "{'increasing'}"
    phase_transition = "{'coherent'}"

    local_path = r'C:\Temp\Test\BPSK'

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
    scpi_session_server.write(':GEN:PULS:FSAV ' + local_path)
    scpi_session_server.write(':GEN:PULS:SAVE')
    scpi_session_server.write(':GEN:PULS:VSA')
    scpi_session_server.query('*OPC?')


except Exception as e:
    print('Error: ' + str(e))
finally:
    if is_connected:
        print('Connected, disconnecting...')
        scpi_session_server.write(':SYST:TCPIP CLOS')
        scpi_session_server.disconnect()
        print('Disconnected')
    input('Program finished.\nPress enter to end.')
