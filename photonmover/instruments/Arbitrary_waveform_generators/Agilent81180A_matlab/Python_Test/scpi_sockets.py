# -*- coding: UTF-8 -*-
"""
Keysight Technologies 2019

Authors:    Morgan Allison, Keysight RF/uW Application Engineer
            Tom Wychock, Keysight RF/uW Application Engineer

Version:    0.5

Disclaimer of Warranties:
THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS.
KEYSIGHT MAKES NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS.

Summary:
This library provides a socket interface to Keysight test equipment.
It handles sending commands, receiving query results, and reading/writing binary block data.

System Notes:
1.This software was written in Python 3.6
2.It can operate in a Windows or Linux environment

"""

__version__ = '0.6'

from socket import socket, AF_INET, SOCK_STREAM, IPPROTO_TCP, TCP_NODELAY, SHUT_RDWR, SOCK_DGRAM, IPPROTO_UDP
import time


##########################################################################

# Low level commands
# Initialize a SCPI instance
def initialize(
        ipv4_address_string_in,
        port_in=5025,
        timeout_in_seconds_in=20,
        enable_nagle_in=False,
        udp_in=False,
        udp_receive_port_in=30001):
    """
    Initializes a Standard Commands for Programmable Instruments (SCPI) session using the Sockets API

    :param ipv4_address_string_in: IPv4 Address of the "instrument" (e.g. 192.168.1.93)
    :param port_in: The sockets port of the instrument (often 5025)
    :param timeout_in_seconds_in: The read timeout for the SCPI session
    :param enable_nagle_in: Enable or disable the Nagle Algorithm
    :param udp_in: Use UDP or no
    :param udp_receive_port_in: If using UDP, the receive port
    :return scpi_instance: The current SCPI session initialized
    """

    # Create the instance
    if udp_in:
        scpi_instance = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    else:
        scpi_instance = socket(AF_INET, SOCK_STREAM)

    # Set the timeout
    if timeout_in_seconds_in > 0:
        scpi_instance.setblocking(False)
        scpi_instance.settimeout(timeout_in_seconds_in)

    else:
        scpi_instance.setblocking(True)

    # Connect
    if udp_in:
        scpi_instance.bind((ipv4_address_string_in, udp_receive_port_in))

    scpi_instance.connect((ipv4_address_string_in, port_in))

    # Enable/disable Nagle
    if not enable_nagle_in and not udp_in:
        scpi_instance.setsockopt(IPPROTO_TCP, TCP_NODELAY, 1)

    return scpi_instance


# Closes the Socket Instance
def close(scpi_session_in):
    """
    Closes a Standard Commands for Programmable Instruments (SCPI) sockets session

    :param scpi_session_in: The current SCPI session
    :return:
    """

    # Shutdown attempt
    try:
        scpi_session_in.shutdown(SHUT_RDWR)
    finally:
        scpi_session_in.close()
    return


# Sends a SCPI command
def write(
        scpi_session_in,
        scpi_command_in,
        termination_char_in='\n',
        debug_scpi_in=False):
    """
    Sends a Standard Commands for Programmable Instruments (SCPI) command to the instrument defined by the SCPI session

    :param scpi_session_in: The SCPI session to send the command to
    :param scpi_command_in: The SCPI command to send
    :param termination_char_in: The termination character used by the instrument
    :param debug_scpi_in: If True, prints the sent command
    :return:
    """

    # Print the input if debug
    if debug_scpi_in:
        print('Debug SCPI Command Sent: ' + scpi_command_in)

    # Add the newline
    scpi_session_in.send((scpi_command_in + termination_char_in).encode())
    return


# Receives a SCPI command response
def read(
        scpi_session_in,
        input_buffer_size_in_bytes_in=4096,
        termination_char_in='\n',
        debug_scpi_in=False):
    """
    Reads a Standard Commands for Programmable Instruments (SCPI) command

    from the instrument defined by the SCPI session.
    :param scpi_session_in: The SCPI session to read from
    :param input_buffer_size_in_bytes_in: The receive buffer size in bytes
    :param termination_char_in: The termination character of the instrument
    :param debug_scpi_in: If True, prints the received command
    :return response_data: The data received without its termination character
    """

    # Get the response data
    response_data = scpi_session_in.recv(input_buffer_size_in_bytes_in)

    # If our network is bad, check for '\n'
    while response_data[-1:].decode('utf-8') != termination_char_in:
        response_data += scpi_session_in.recv(input_buffer_size_in_bytes_in)

    # If debug, print
    if debug_scpi_in:
        print('Debug SCPI Response Received: ' +
              response_data.decode().split(termination_char_in)[0])

    # Return without newline
    return response_data.decode().split(termination_char_in)[0]


# Sends and receives a SCPI command response
def query(
        scpi_session_in,
        scpi_command_in,
        input_buffer_size_in_bytes_in=4096,
        termination_char_in='\n',
        debug_scpi_in=False):
    """
    Sends, then Reads a Standard Commands for Programmable Instruments (SCPI) command
    to and from the instrument defined by the SCPI session

    :param scpi_session_in: The SCPI session to send and read from
    :param scpi_command_in: The SCPI command to send
    :param input_buffer_size_in_bytes_in: The receive buffer size in bytes
    :param termination_char_in: The termination character of the instrument
    :param debug_scpi_in: If True, prints the sent and received commands
    :return response_data: The data received without its termination character
    """

    # Send command
    write(
        scpi_session_in,
        scpi_command_in,
        termination_char_in=termination_char_in,
        debug_scpi_in=debug_scpi_in)

    # Return the query
    return read(
        scpi_session_in,
        input_buffer_size_in_bytes_in,
        termination_char_in=termination_char_in,
        debug_scpi_in=debug_scpi_in)


# Turns Nagle on or off (faster short writes)
def set_nagle(scpi_session_in, enable_nagle_in):
    """
    Turns the Nagle Algorithm on or off for the specified Standard Commands for Programmable Instruments (SCPI) session

    :param scpi_session_in: The SCPI session to configure
    :param enable_nagle_in: Enable or disable
    :return:
    """

    if enable_nagle_in:
        scpi_session_in.setsockopt(IPPROTO_TCP, TCP_NODELAY, 0)

    else:
        scpi_session_in.setsockopt(IPPROTO_TCP, TCP_NODELAY, 1)


# Sets timeout
def set_timeout(scpi_session_in, timeout_in_seconds_in):
    """
    Sets the receive timeout for the specified Standard Commands for Programmable Instruments (SCPI) session

    :param scpi_session_in: The SCPI session to
    :param timeout_in_seconds_in: The timeout in seconds
    :return:
    """

    # Set the timeout
    if timeout_in_seconds_in > 0:
        scpi_session_in.setblocking(False)
        scpi_session_in.settimeout(timeout_in_seconds_in)

    else:
        scpi_session_in.setblocking(True)


# Sends data and returns the amount sent
def send_buffer_check(
        scpi_session_in,
        send_data_in,
        send_timeout_in_seconds_in=5):
    """
    Sends a buffer of bytes and returns the amount of bytes sent

    :param scpi_session_in: The SCPI session to send the data to
    :param send_data_in: The data (in bytes) to send to the instrument
    :param send_timeout_in_seconds_in: The amount of time to wait for data to send before throwing a timeout exception
    :return data_sent: The amount of data sent
    """

    # Data sent total
    data_sent = 0

    # Keep sending until timeout or data sent
    sending_data = True

    # Timeout tracking
    time_start = time.time()

    while sending_data:

        data_sent = scpi_session_in.send(send_data_in)

        if data_sent > 0:
            sending_data = False
        elif time.time() - time_start > send_timeout_in_seconds_in:
            raise RuntimeError("Socket connection broken")

    return data_sent


# Sends all of the data in the given chunk size to avoid Linux overflow
# send issues
def send_data_bytes(
        scpi_session_in,
        send_data_in_bytes_in,
        send_data_length_in_bytes_in,
        send_data_chunk_size_in_bytes_in=4096,
        send_timeout_in_seconds_in=5):
    """
    Sends a buffer of bytes in the specified chunk size and returns the amount of bytes sent

    :param scpi_session_in: The SCPI session to send the data to
    :param send_data_in_bytes_in: The data (in bytes) to send to the instrument
    :param send_data_length_in_bytes_in: The length of the data to send
    :param send_data_chunk_size_in_bytes_in: The amount of data chunks to send per chunk send
    :param send_timeout_in_seconds_in: The amount of time to wait for data to send before throwing a timeout exception.
    :return:
    """

    # Track the total stream
    total_stream_sent = 0
    stream_data_length_chunk_limit = send_data_length_in_bytes_in - \
        send_data_chunk_size_in_bytes_in

    # Send the whole stream in chunks first
    while total_stream_sent < stream_data_length_chunk_limit:

        # Send and track the current chunk
        total_chunk_subset_sent = 0

        while total_chunk_subset_sent < send_data_chunk_size_in_bytes_in:
            current_chunk_subset_sent =\
                send_buffer_check(scpi_session_in,
                                  send_data_in_bytes_in[(total_stream_sent + total_chunk_subset_sent):
                                                        (total_stream_sent + send_data_chunk_size_in_bytes_in)],
                                  send_timeout_in_seconds_in=send_timeout_in_seconds_in)

            # Add to the current chunk sent
            total_chunk_subset_sent = total_chunk_subset_sent + current_chunk_subset_sent

        # Go to the next chunk
        total_stream_sent = total_stream_sent + total_chunk_subset_sent

    # Send the last chunk
    while total_stream_sent < send_data_length_in_bytes_in:
        current_stream_sent = send_buffer_check(
            scpi_session_in, send_data_in_bytes_in[total_stream_sent:])

        total_stream_sent = total_stream_sent + current_stream_sent

    return

##########################################################################

# Higher level commands


# Sends a binary block write command
def binary_block_write(
        scpi_session_in,
        scpi_command_in,
        binary_data_in,
        data_is_in_bytes=False,
        send_data_chunk_size_in_bytes_in=4096,
        send_timeout_in_seconds_in=5,
        termination_char_in='\n',
        debug_scpi_in=False,
        debug_binary_in=False):
    """
    Send data with IEEE 488.2 binary block format

    The data is formatted as:
    #<x><yyy><data><newline>, where:
    <x> is the number of y bytes. For example, if <yyy>=500, then <x>=3.
    NOTE: <x> is a hexadecimal number.
    <yyy> is the number of bytes to transfer. Care must be taken
    when selecting the data type used to interpret the data.
    The dtype argument used to read the data must match the data
    type used by the instrument that sends the data.
    <data> is the curve data in binary format.
    <newline> is a single byte new line character at the end of the data.

    :param scpi_session_in: The SCPI session to send the command and binary block data to
    :param scpi_command_in: The SCPI command to send in the binary block write
    :param binary_data_in: The binary data in
    :param data_is_in_bytes: Is the data in bytes form?
    :param send_data_chunk_size_in_bytes_in: The chunk size to send the binary block data with in bytes
    :param send_timeout_in_seconds_in: The amount of time to wait for data to send before throwing a timeout exception.
    :param termination_char_in: The termination character of the instrument
    :param debug_scpi_in: If True, prints the sent command
    :param debug_binary_in: If True, prints the binary data sent
    :return:
    """

    # BinBlockWrite in form
    # [num of length chars][length of chars]
    # dataIn = data[0:5].decode('ascii') #The hash (for reference)
    # dataHash = str(chr(data[0]))

    # Convert the data if necessary
    if not data_is_in_bytes:
        binary_data_in = bytes(binary_data_in)

    # Get the size of the data
    length_message = len(binary_data_in)
    length_message_digits = len(str(length_message))

    # Create the header
    header_string = '#' + str(length_message_digits) + str(length_message)

    # Print the input if debug
    if debug_scpi_in:
        print('Debug SCPI Command Sent: ' + scpi_command_in + header_string)

    # Send the command
    scpi_session_in.send(scpi_command_in.encode())

    # Send the header
    scpi_session_in.send(header_string.encode())

    if debug_binary_in:
        print('Debug Binary Block Sent: ' + str(binary_data_in))

    # Send the data
    send_data_bytes(
        scpi_session_in,
        binary_data_in,
        length_message,
        send_data_chunk_size_in_bytes_in=send_data_chunk_size_in_bytes_in,
        send_timeout_in_seconds_in=send_timeout_in_seconds_in)

    # Send the termination character
    scpi_session_in.send(termination_char_in.encode())


# Does a binary block read command
def binary_block_read(
        scpi_session_in,
        scpi_command_in,
        receive_buffer_size_in_bytes_in=4096,
        full_buffer_read_in=False,
        termination_char_in='\n',
        debug_scpi_in=False,
        debug_binary_in=False):
    """
    Receive data with IEEE 488.2 binary block format

    The data is formatted as:
    #<x><yyy><data><newline>, where:
    <x> is the number of y bytes. For example, if <yyy>=500, then <x>=3.
    NOTE: <x> is a hexadecimal number.
    <yyy> is the number of bytes to transfer. Care must be taken
    when selecting the data type used to interpret the data.
    The dtype argument used to read the data must match the data
    type used by the instrument that sends the data.
    <data> is the curve data in binary format.
    <newline> is a single byte new line character at the end of the data.

    :param scpi_session_in: The SCPI session to send the command and binary block data to
    :param scpi_command_in: The SCPI command to send in the binary block write
    :param receive_buffer_size_in_bytes_in: The size of the buffer in block reads in bytes
    :param full_buffer_read_in: Read the buffer in pieces or in large chunks?
    :param termination_char_in: The termination character of the instrument
    :param debug_scpi_in: If True, prints the sent command
    :param debug_binary_in: If True, prints the binary data sent
    :return data_raw: Data in bytes
    """

    # BinBlockRead in form
    # "#[num of length chars][length of chars]"
    # dataIn = data[0:5].decode('ascii') #The hash (for reference)
    # dataHash = str(chr(data[0]))

    # Send the command
    write(
        scpi_session_in,
        scpi_command_in,
        termination_char_in=termination_char_in,
        debug_scpi_in=debug_scpi_in)

    # If reading a block of data
    if full_buffer_read_in:

        # Read the response
        data_with_header = scpi_session_in.socket.recv(
            receive_buffer_size_in_bytes_in)

        # Take apart the header
        # The "#"
        if data_with_header[0] != b'#':
            raise ValueError('Data in buffer is not in Binary Block format.')

        # The character length of the length term
        header_length = int(data_with_header[1].decode('latin_1'), 16)
        num_bytes = int(
            data_with_header[2:(2 + header_length)].decode('latin_1'))

        # Initialize the data array
        data_raw = bytearray(num_bytes)

        # Get the rest of the data in the current read
        # See how much data is received
        data_rec_len_bytes = len(data_with_header) - 2 - header_length

        # If everything is in the read, index and return it
        if data_rec_len_bytes >= num_bytes + len(termination_char_in):

            # Index the data
            data_raw = data_with_header[(
                2 + header_length):(2 + header_length + num_bytes)]

            # Index the termination character
            term = data_with_header[(2 + header_length + num_bytes)]

            # If term char is incorrect or not present, raise exception.
            if term != termination_char_in:
                print('Term char: {}, data_raw Length: {}'.format(
                    term, len(data_raw)))
                raise ValueError('Data not terminated correctly.')

        # Otherwise, keep receiving until done
        else:

            # Index the initial data
            data_raw[0:data_rec_len_bytes] = data_with_header[(
                2 + header_length):(2 + header_length + data_rec_len_bytes)]

            # Initialize the buffer
            buffer_data_raw = memoryview(data_raw)

            # Slice the buffer
            buffer_data_raw = buffer_data_raw[data_rec_len_bytes:]
            num_bytes -= data_rec_len_bytes

            # Read while data is left to read
            while num_bytes:

                # Read data from instrument into buffer.
                bytes_recv = scpi_session_in.socket.recv_into(
                    buffer_data_raw, num_bytes)

                # Slice buffer to preserve data already written to it.
                buffer_data_raw = buffer_data_raw[bytes_recv:]

                # Subtract bytes received from total bytes.
                num_bytes -= bytes_recv

            # Receive termination character.
            term = scpi_session_in.socket.recv(1)

            # If term char is incorrect or not present, raise exception.
            if term != termination_char_in:
                print('Term char: {}, data_raw Length: {}'.format(
                    term, len(data_raw)))
                raise ValueError('Data not terminated correctly.')

        if debug_binary_in:
            print('Debug Binary Block Received: ' + str(data_raw))

        # Return the raw data
        return data_raw

    # If reading a piece at a time
    else:

        # Read the response
        if scpi_session_in.socket.recv(1) != b'#':
            raise ValueError('Data in buffer is not in Binary Block format.')

        # Extract header length and number of bytes in binblock.
        header_length = int(
            scpi_session_in.socket.recv(1).decode('latin_1'), 16)
        num_bytes = int(scpi_session_in.socket.recv(
            header_length).decode('latin_1'))

        data_raw = bytearray(num_bytes)
        buffer_data_raw = memoryview(data_raw)

        # While there is data left to read...
        while num_bytes:

            # Read data from instrument into buffer.
            bytes_recv = scpi_session_in.socket.recv_into(
                buffer_data_raw, num_bytes)

            # Slice buffer to preserve data already written to it.
            buffer_data_raw = buffer_data_raw[bytes_recv:]

            # Subtract bytes received from total bytes.
            num_bytes -= bytes_recv

        # Receive termination character.
        term = scpi_session_in.socket.recv(1)

        # If term char is incorrect or not present, raise exception.
        if term != '\n':
            print('Term char: {}, data_raw Length: {}'.format(
                term, len(data_raw)))
            raise ValueError('Data not terminated correctly.')

        if debug_binary_in:
            print('Debug Binary Block Received: ' + str(data_raw))

        # Return the raw data
        return data_raw


# Monitors the state and waits to continue
def set_and_wait(
        scpi_session_in,
        query_command_in,
        desired_state_in,
        set_command_in,
        wait_cycle_in_ms_in=50,
        wait_count_in=-1,
        termination_char_in='\n',
        debug_scpi_in=False):
    """
    Sends a Standard Commands for Programmable Instruments (SCPI)
    command and constantly waits for the returned state to be reached

    :param scpi_session_in: The SCPI session to monitor
    :param query_command_in: The SCPI command to query the instrument state
    :param desired_state_in: The SCPI command that indicates the state is achieved
    :param set_command_in: The SCPI command to set the instrument with
    :param wait_cycle_in_ms_in: The time to wait between queries
    :param wait_count_in: The amount of times to wait
    :param termination_char_in: The termination character in sends and reads
    :param debug_scpi_in: If True, prints the sent and received commands
    :return:
    """

    # Get length of string to receive
    # desired_result_length = len(desired_state_in)

    # Do an initial query
    current_state = query(
        scpi_session_in,
        query_command_in,
        termination_char_in=termination_char_in,
        debug_scpi_in=debug_scpi_in)

    # Check if it matches
    if desired_state_in in current_state:
        return True

    # If not, wait
    else:
        # If not set and wait
        write(scpi_session_in, set_command_in)

        # Keep waiting for the state
        query_matched = False

        # Initialize parameters
        wait_cycle_in_s = wait_cycle_in_ms_in / 1000
        wait_counter = 0

        while not query_matched:

            # Wait
            time.sleep(wait_cycle_in_s)

            # Query the current state
            query_matched = desired_state_in in query(
                scpi_session_in, query_command_in)

            # If count exceeded break with false
            if wait_count_in >= 0:

                if wait_counter >= wait_count_in:
                    return False
                else:
                    wait_counter = wait_counter + 1

    return True


# Does a very rough estimate of latency in SCPI sends
def scpi_latency_check(
        scpi_session_in,
        query_command_in="*IDN?",
        termination_char_in='\n',
        debug_scpi_in=False):
    """
    Gets a rough estimated of the Standard Commands for Programmable Instruments (SCPI) session's latency by sending
    and receiving a command and measuring the time it takes to do so

    :param scpi_session_in: The SCPI session to test
    :param query_command_in: The SCPI command to send in the query
    :param termination_char_in: The termination character of the instrument
    :param debug_scpi_in: If True, prints the received command
    :return: The rough latency in seconds
    """

    # Get the initial time
    # TODO more time send options
    time_initial = time.time()

    # Send the command
    query(
        scpi_session_in,
        query_command_in,
        termination_char_in=termination_char_in,
        debug_scpi_in=debug_scpi_in)

    # Get the new time
    time_delta = time.time() - time_initial

    return time_delta


##########################################################################

# Standard SCPI Commands

# Resets the instrument
def reset(scpi_session_in, termination_char_in='\n', debug_scpi_in=False):
    """
    Sends a Reset (*RST)
    Standard Commands for Programmable Instruments (SCPI) command to the instrument defined by the SCPI session

    :param scpi_session_in: The SCPI session to send the command to
    :param termination_char_in: The termination character used by the instrument
    :param debug_scpi_in: If True, prints the sent command
    :return:
    """

    write(scpi_session_in=scpi_session_in,
          scpi_command_in="*RST",
          termination_char_in=termination_char_in,
          debug_scpi_in=debug_scpi_in)


# Clears the status buffer
def clear_status_register(
        scpi_session_in,
        termination_char_in='\n',
        debug_scpi_in=False):
    """
    Sends a Clear Status Register (*CLS)
    Standard Commands for Programmable Instruments (SCPI) command to the instrument defined by the SCPI session

    :param scpi_session_in: The SCPI session to send the command to
    :param termination_char_in: The termination character used by the instrument
    :param debug_scpi_in: If True, prints the sent command
    :return:
    """

    write(scpi_session_in=scpi_session_in,
          scpi_command_in="*CLS",
          termination_char_in=termination_char_in,
          debug_scpi_in=debug_scpi_in)


# Sends a bus trigger
def send_bus_trigger(
        scpi_session_in,
        termination_char_in='\n',
        debug_scpi_in=False):
    """
    Sends a Bus Trigger (*TRG)
    Standard Commands for Programmable Instruments (SCPI) command to the instrument defined by the SCPI session

    :param scpi_session_in: The SCPI session to send the command to
    :param termination_char_in: The termination character used by the instrument
    :param debug_scpi_in: If True, prints the sent command
    :return:
    """

    write(
        scpi_session_in,
        "*TRG",
        termination_char_in=termination_char_in,
        debug_scpi_in=debug_scpi_in)


##########################################################################


# SCPI Class Object
class SCPISession:

    # Constructor
    def __init__(
            self,
            ipv4_address_string_in,
            port_in=5025,
            timeout_in_seconds_in=20,
            enable_nagle_in=False,
            connect_in=True,
            debug_scpi_in=False,
            debug_binary_in=False,
            termination_char_in='\n',
            udp_in=False,
            udp_receive_port_in=30001):
        """
        Instantiates a Standard Commands for Programmable Instruments (SCPI) session using the Sockets API

        :param ipv4_address_string_in: IPv4 Address of the "instrument" (e.g. 192.168.1.93)
        :param port_in: The sockets port of the instrument (often 5025)
        :param timeout_in_seconds_in: The read timeout for the SCPI session
        :param enable_nagle_in: Enable or disable the Nagle Algorithm
        :param connect_in: Connect to the instrument?
        :param debug_scpi_in: If True, prints the sent and received commands for the object's SCPI session
        :param debug_binary_in: If True, prints the binary data sent
        :param udp_in: Use UDP or no
        :param udp_receive_port_in: If using UDP, the receive port
        """

        # Start a session
        self.__is_connected = False
        self.__ipv4_address = ipv4_address_string_in
        self.__port = port_in
        self.__enable_nagle = enable_nagle_in
        self.__timeout_in_seconds = timeout_in_seconds_in
        self.__debug_mode_scpi = debug_scpi_in
        self.__debug_mode_binary = debug_binary_in
        self.__termination_char = termination_char_in
        self.__udp = udp_in
        self.__udp_receive_port = udp_receive_port_in

        # Choose to connect or not
        if connect_in:
            self.__scpi_session = initialize(
                ipv4_address_string_in=ipv4_address_string_in,
                timeout_in_seconds_in=timeout_in_seconds_in,
                port_in=port_in,
                enable_nagle_in=enable_nagle_in,
                udp_in=udp_in,
                udp_receive_port_in=udp_receive_port_in)
            self.__is_connected = True

    # Properties
    # SCPI Session
    @property
    def scpi_session(self):
        return self.__scpi_session

    # IPV4 Address
    @property
    def ipv4_address(self):
        return self.__ipv4_address

    # port
    @property
    def port(self):
        return self.__port

    # Nagle on or off
    @property
    def enable_nagle(self):
        return self.__enable_nagle

    @enable_nagle.setter
    def enable_nagle(self, value):
        self.__enable_nagle = value

        if self.__is_connected:
            set_nagle(scpi_session_in=self.__scpi_session,
                      enable_nagle_in=self.__enable_nagle)

    # Timeout
    @property
    def timeout_in_seconds(self):
        return self.__timeout_in_seconds

    @timeout_in_seconds.setter
    def timeout_in_seconds(self, value):
        self.__timeout_in_seconds = value

        if self.__is_connected:
            set_timeout(scpi_session_in=self.__scpi_session,
                        timeout_in_seconds_in=self.__timeout_in_seconds)

    # Termination Character
    @property
    def termination_char(self):
        return self.__termination_char

    @termination_char.setter
    def termination_char(self, value):
        self.__termination_char = value

    # UDP
    @property
    def udp(self):
        return self.__udp

    @udp.setter
    def udp(self, value):
        self.__udp = value

    # UDP port
    @property
    def udp_receive_port(self):
        return self.__udp_receive_port

    @udp_receive_port.setter
    def udp_receive_port(self, value):
        self.__udp_receive_port = value

    # Is Connected
    @property
    def is_connected(self):
        return self.__is_connected

    # Debug SCPI
    @property
    def debug_mode_scpi(self):
        return self.__debug_mode_scpi

    @debug_mode_scpi.setter
    def debug_mode_scpi(self, value):
        self.__debug_mode_scpi = value

    # Debug Binary
    @property
    def debug_mode_binary(self):
        return self.__debug_mode_binary

    @debug_mode_binary.setter
    def debug_mode_binary(self, value):
        self.__debug_mode_binary = value

    # Methods
    # Connect if not/dis_connected
    def connect(self, timeout_in_seconds_in=None, enable_nagle_in=None):
        """
        Connect to the instrument

        :param timeout_in_seconds_in: The read timeout for the SCPI session
        :param enable_nagle_in: Enable or disable the Nagle Algorithm
        :return:
        """
        # Disconnect if connected
        if self.__is_connected:
            try:
                close(scpi_session_in=self.__scpi_session)

            finally:
                self.__is_connected = False

        # Reconnect
        # Start a session
        if timeout_in_seconds_in is not None:
            self.__timeout_in_seconds = timeout_in_seconds_in

        if enable_nagle_in is not None:
            self.__enable_nagle = enable_nagle_in

        self.__scpi_session = initialize(
            ipv4_address_string_in=self.__ipv4_address,
            timeout_in_seconds_in=self.__timeout_in_seconds,
            port_in=self.__port,
            enable_nagle_in=self.__enable_nagle,
            udp_in=self.__udp,
            udp_receive_port_in=self.__udp_receive_port)
        self.__is_connected = True

    # Disconnect
    def disconnect(self):
        """
        Disconnect from the instrument

        :return:
        """
        # Disconnect if connected
        if self.__is_connected:
            try:
                close(scpi_session_in=self.__scpi_session)

            finally:
                self.__is_connected = False

    # Sends a SCPI command
    def write(self, scpi_command_in):
        """
        Sends a Standard Commands for Programmable Instruments (SCPI) command to the instrument
        defined by the SCPI session

        :param scpi_command_in: The SCPI command to send
        :return:
        """

        # Send the command
        write(
            self.__scpi_session,
            scpi_command_in=scpi_command_in,
            termination_char_in=self.__termination_char,
            debug_scpi_in=self.__debug_mode_scpi)
        return

    # Receives a SCPI command response
    def read(self, input_buffer_size_in_bytes_in=4096):
        """
        Reads a Standard Commands for Programmable Instruments (SCPI) command

        from the instrument defined by the SCPI session.
        :param input_buffer_size_in_bytes_in: The receive buffer size in bytes
        :return response_data: The data received without its termination character
        """

        # Return without newline
        return read(
            self.__scpi_session,
            input_buffer_size_in_bytes_in=input_buffer_size_in_bytes_in,
            termination_char_in=self.__termination_char,
            debug_scpi_in=self.__debug_mode_scpi)

    # Sends and receives a SCPI command response
    def query(self, scpi_command_in, input_buffer_size_in_bytes_in=4096):
        """
        Sends, then Reads a Standard Commands for Programmable Instruments (SCPI) command
        to and from the instrument defined by the SCPI session

        :param scpi_command_in: The SCPI command to send
        :param input_buffer_size_in_bytes_in: The receive buffer size in bytes
        :return response_data: The data received without its termination character
        """

        # Return the query
        return query(
            self.__scpi_session,
            scpi_command_in=scpi_command_in,
            input_buffer_size_in_bytes_in=input_buffer_size_in_bytes_in,
            termination_char_in=self.__termination_char,
            debug_scpi_in=self.__debug_mode_scpi)

    # Sends a binary block write command
    def binary_block_write(
            self,
            scpi_command_in,
            binary_data_in,
            data_is_in_bytes=False,
            send_data_chunk_size_in_bytes_in=4096,
            send_timeout_in_seconds_in=5):
        """
        Send data with IEEE 488.2 binary block format

        The data is formatted as:
        #<x><yyy><data><newline>, where:
        <x> is the number of y bytes. For example, if <yyy>=500, then <x>=3.
        NOTE: <x> is a hexadecimal number.
        <yyy> is the number of bytes to transfer. Care must be taken
        when selecting the data type used to interpret the data.
        The dtype argument used to read the data must match the data
        type used by the instrument that sends the data.
        <data> is the curve data in binary format.
        <newline> is a single byte new line character at the end of the data.

        :param scpi_command_in: The SCPI command to send in the binary block write
        :param binary_data_in: The binary data in
        :param data_is_in_bytes: Is the data in bytes form?
        :param send_data_chunk_size_in_bytes_in: The chunk size to send the binary block data with in bytes
        :param send_timeout_in_seconds_in: The amount of time to wait for data to send before
               throwing a timeout exception.
        :return:
        """

        # BinBlockWrite in form
        # [num of length chars][length of chars]
        # dataIn = data[0:5].decode('ascii') #The hash (for reference)
        # dataHash = str(chr(data[0]))

        binary_block_write(
            self.__scpi_session,
            scpi_command_in=scpi_command_in,
            binary_data_in=binary_data_in,
            data_is_in_bytes=data_is_in_bytes,
            send_data_chunk_size_in_bytes_in=send_data_chunk_size_in_bytes_in,
            send_timeout_in_seconds_in=send_timeout_in_seconds_in)

    # Does a binary block read command
    def binary_block_read(
            self,
            scpi_command_in,
            receive_buffer_size_in_bytes_in=4096,
            full_buffer_read_in=False):
        """
        Receive data with IEEE 488.2 binary block format

        The data is formatted as:
        #<x><yyy><data><newline>, where:
        <x> is the number of y bytes. For example, if <yyy>=500, then <x>=3.
        NOTE: <x> is a hexadecimal number.
        <yyy> is the number of bytes to transfer. Care must be taken
        when selecting the data type used to interpret the data.
        The dtype argument used to read the data must match the data
        type used by the instrument that sends the data.
        <data> is the curve data in binary format.
        <newline> is a single byte new line character at the end of the data.

        :param scpi_command_in: The SCPI command to send in the binary block write
        :param receive_buffer_size_in_bytes_in: The size of the buffer in block reads in bytes
        :param full_buffer_read_in: Read the buffer in pieces or in large chunks?
        :return data_raw: Data in bytes
        """

        # BinBlockRead in form
        # "#[num of length chars][length of chars]"
        # dataIn = data[0:5].decode('ascii') #The hash (for reference)
        # dataHash = str(chr(data[0]))

        return binary_block_read(
            self.__scpi_session,
            scpi_command_in=scpi_command_in,
            receive_buffer_size_in_bytes_in=receive_buffer_size_in_bytes_in,
            full_buffer_read_in=full_buffer_read_in,
            termination_char_in=self.__termination_char,
            debug_scpi_in=self.__debug_mode_scpi,
            debug_binary_in=self.__debug_mode_binary)

    # Does a very rough estimate of latency in SCPI sends
    def scpi_latency_check(self, query_command_in="*IDN?"):
        """
        Gets a rough estimated of the Standard Commands for Programmable Instruments (SCPI) session's latency by sending
        and receiving a command and measuring the time it takes to do so

        :param query_command_in: The SCPI command to send in the query
        :return: The rough latency in seconds
        """

        # Get the time
        time_delta = scpi_latency_check(
            scpi_session_in=self.__scpi_session,
            query_command_in=query_command_in,
            debug_scpi_in=self.__debug_mode_scpi)
        return time_delta

    # Resets the instrument
    def reset(self):
        """
        Resets the instrument to its default state

        :return:
        """

        reset(
            scpi_session_in=self.__scpi_session,
            debug_scpi_in=self.__debug_mode_scpi,
            termination_char_in=self.__termination_char)

    # Sends a bus trigger
    def send_bus_trigger(self):
        """
        Sends a bus trigger (*TRG)

        :return:
        """

        send_bus_trigger(
            scpi_session_in=self.__scpi_session,
            debug_scpi_in=self.__debug_mode_scpi,
            termination_char_in=self.__termination_char)

    # Clears the status buffer
    def clear_status_register(self):
        """
        Clears the status register of the instrument

        :return:
        """
        clear_status_register(
            scpi_session_in=self.__scpi_session,
            debug_scpi_in=self.__debug_mode_scpi,
            termination_char_in=self.__termination_char)

##########################################################################
