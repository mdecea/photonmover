from photonmover.Interfaces.Instrument import Instrument
import serial
import re
import time

COM_ADDRESS = 'COM5'


class KJLKPDR900(Instrument):

    def __init__(self):
        super().__init__()

    def initialize(self):
        """
        Initializes the instrument.
        :return:
        """
        print("Initializing connection to Pressure gauge")
        self.ser = serial.Serial(COM_ADDRESS, timeout=3)

        # FLush the logged data since we don't care about it
        self.flush()

    def close(self):
        """
        Closes the instrument.
        :return:
        """
        print("Closing connection to Pressure gauge")
        self.ser.close()

    def get_pressure(self):
        """
        Queries the pressure.
        :return:
        """
        message = '@001DL?;FF'
        self.ser.write(message.encode('ascii'))
        self.ser.flush()

        # Get the last data point, and restart the data logger (so it does not get full)
        pressure_data_prev = 'AA'.encode('ascii')
        pressure_data = 'AA'.encode('ascii')

        # We do this to flush all the data logged. This way we can restart the
        # acquisition and avoid the buffer from getting full
        while pressure_data[-2:].decode('ascii') != 'FF':
            pressure_data_prev = pressure_data
            pressure_data = self.ser.read(60)  # .decode('ascii')

        # --------------
        # OLD METHOD
        # Now parse the response to get the actual pressure value.
        # Since it is always the same format, we know the bytes we care about

        #if len(pressure_data) > 12:
        #    last_point = pressure_data[-12:-5].decode('ascii')
        #else:
        #    part2 = pressure_data[-12:-5].decode('ascii')
        #    part1 = pressure_data_prev[-(12-len(pressure_data)):].decode('ascii')
        #    last_point = part1 + part2
        # ---------------

        pressure_data = pressure_data.decode('ascii')
        pressure_data_prev = pressure_data_prev.decode('ascii')
        all_pressure_data = pressure_data_prev + pressure_data

        match = re.search( ';-?[\d.]+(?:E-?\d+)?\r\x03;FF', all_pressure_data)
        pressure = match.group()
        pressure = pressure[1:-5]
        #print(pressure)
        #input()
        self.flush()

        try:
            pressure = float(pressure)
        except:
            pressure = 1e10
            print('Error reading pressure: %s, %s' % (pressure_data, pressure_data_prev))

        return pressure

    def flush(self):

        # Restarts the data acquisition to free the buffer
        message = '@001DLC!STOP;FF'
        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        self.ser.read(15)
        #print(self.ser.read(15))

        message = '@001DLC!START;FF'
        self.ser.write(message.encode('ascii'))
        self.ser.flush()
        self.ser.read(15)
        #print(self.ser.read(15))


if __name__ == '__main__':
    ps = KJLKPDR900()
    ps.initialize()
    while True:
        print(ps.get_pressure())
    ps.close()

