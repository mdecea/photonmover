import sys
sys.path.insert(0,'../..')

import numpy as np
import matplotlib.pyplot as plt
from ctypes import *
from Interfaces.Camera import Camera
from Interfaces.Instrument import Instrument
import time
from PIL import Image

DLL_PATH = "C:\\Program Files\\Common Files\\XenICs\\Runtime\\xeneth64.dll"
#CAL_PATH = "C:\\Program Files\\Xeneth\\Calibrations\\Xeva1785_20000uS_High_gain_RT_1785.xca"
CAL_PATH = "C:\\Program Files\\Xeneth\\Calibrations\\xenics_cal_1785.xca"
SETTINGS_PATH = "C:\\Users\\POE\\Desktop\\Marc\\photonmover-exp\\photonmover-master\\instruments\\Cameras\\xenics_settings_0degC_max_int_time.xcf"

class Xenics(Instrument, Camera):

    def __init__(self, camera_path ='cam://0', dll_path=DLL_PATH, calibration_file=CAL_PATH, settings_file=SETTINGS_PATH):
        super().__init__()

        # It is good practice to initialize variables in the init
        self.xenicsdll = None
        self.xenics_handle = None
        self.dll_path = dll_path
        self.camera_path = camera_path
        self.calibration_file = calibration_file  # Calibration file is a path to a .xca calibration file
        self.settings_file = settings_file

    def initialize(self):
        """
        Initializes the instrument
        :return:
        """
        print('Opening connnection to Xenics Camera')

        # Load the dll
        self.load_dll()

        # Connect to the camera
        self.connect()

        # Start capturing
        self.start_capture(self.xenics_handle)
        if not self.is_capturing(self.xenics_handle):
            raise Exception('Xenics initialization for capture failed.')

    def connect(self):
        '''
        Opens connection to the camera and closes it in controlled fashion when
        exiting the context.
        '''

        # Open connection
        self.xenics_handle = self.open_camera(self.camera_path.encode('utf-8'), 0, 0)
        print('Xenics handle:', self.xenics_handle)

        if self.xenics_handle == 0:
            raise Exception('Xenics handle is NULL')

        if not self.is_initialised(self.xenics_handle):
            raise Exception('Xenics initialization failed.')

        # Load calibration
        if self.calibration_file is not None:
            flag = 1 # Use software correction
            error = self.load_calibration(self.xenics_handle,
                                          self.calibration_file.encode('utf-8'),
                                          flag)
            if error != 0:
                msg = 'Could\'t load' + \
                    ' calibration file ' + \
                    str(self.calibration_file) + \
                    '. Error code: ' + str(error)
                raise Exception(msg)

        property = "SETTLE"
        val = c_ulong(1)
        err = self.get_property_value(self.xenics_handle, property.encode('utf-8'), val)
        print(property + "is " + str(val))

        # Load settings
        if self.settings_file is not None:
            flag = 1 # Ignore settings that do not affect the image
            error = self.load_settings(self.xenics_handle, 
                                       self.settings_file.encode('utf-8'), 
                                       flag)

            if error != 0:
                msg = 'Could\'t load' + \
                    ' settings file ' + \
                    str(self.settings_file) + \
                    '. Error code: ' + str(error)
                raise Exception(msg)

        val = c_ulong(1)
        self.get_property_value(self.xenics_handle, property.encode('utf-8'), val)
        print(property + "is " + str(val))

        return self

    def close(self):
        '''
        Stops capturing, closes connection.
        '''
        try:
            if self.is_capturing(self.xenics_handle):
                print('Stop Xenics capturing')
                error = self.stop_capture(self.xenics_handle)
                if error != 0:
                    raise Exception('Could not stop capturing')
        except:
            print('Something went wrong closing the camera.')
            raise
        finally:
            if self.is_initialised(self.xenics_handle):
                print('Closing connection.')
                self.close_camera(self.xenics_handle)

    def load_dll(self):

        # Load the DLL
        self.xenicsdll = CDLL(self.dll_path)

        # Declare all useful functions contained in the DLL

        self.open_camera = self.xenicsdll.XC_OpenCamera
        self.open_camera.restype = c_int32  # XCHANDLE

        self.error_to_string = self.xenicsdll.XC_ErrorToString
        self.error_to_string.restype = c_int32
        self.error_to_string.argtypes = (c_int32, c_char_p, c_int32)

        self.is_initialised = self.xenicsdll.XC_IsInitialised
        self.is_initialised.restype = c_int32
        self.is_initialised.argtypes = (c_int32,)

        self.start_capture = self.xenicsdll.XC_StartCapture
        self.start_capture.restype = c_ulong  # ErrCode
        self.start_capture.argtypes = (c_int32,)

        self.is_capturing = self.xenicsdll.XC_IsCapturing
        self.is_capturing.restype = c_bool
        self.is_capturing.argtypes = (c_int32,)

        self.get_frame_size_dll = self.xenicsdll.XC_GetFrameSize
        self.get_frame_size_dll.restype = c_ulong
        self.get_frame_size_dll.argtypes = (c_int32,)  # Handle

        self.get_frame_type_dll = self.xenicsdll.XC_GetFrameType
        self.get_frame_type_dll.restype = c_ulong  # Returns enum
        self.get_frame_type_dll.argtypes = (c_int32,)  # Handle

        self.get_frame_width = self.xenicsdll.XC_GetWidth
        self.get_frame_width.restype = c_ulong
        self.get_frame_width.argtypes = (c_int32,)  # Handle

        self.get_frame_height = self.xenicsdll.XC_GetHeight
        self.get_frame_height.restype = c_ulong
        self.get_frame_height.argtypes = (c_int32,)  # Handle

        self.get_max_val = self.xenicsdll.XC_GetMaxValue
        self.get_max_val.restype = c_ulong  
        self.get_max_val.argtypes = (c_int32,)  # Handle

        self.get_frame_dll = self.xenicsdll.XC_GetFrame
        self.get_frame_dll.restype = c_ulong  # ErrCode
        self.get_frame_dll.argtypes = (c_int32, c_ulong, c_ulong, c_void_p, c_uint)

        self.stop_capture = self.xenicsdll.XC_StopCapture
        self.stop_capture.restype = c_ulong  # ErrCode
        self.stop_capture.argtypes = (c_int32,)

        self.save_data = self.xenicsdll.XC_SaveData
        self.save_data.restype = c_ulong  # ErrCode
        self.save_data.argtypes = (c_int32, c_char_p, c_ulong)

        self.enumerate_devices = self.xenicsdll.XCD_EnumerateDevices
        self.enumerate_devices.restype = c_ulong  # ErrCode
        self.enumerate_devices.argtypes = (c_int32, c_uint, c_ulong)

        self.close_camera = self.xenicsdll.XC_CloseCamera
        # Returns void
        self.close_camera.argtypes = (c_int32, )  # Handle

        # Calibration
        self.load_calibration = self.xenicsdll.XC_LoadCalibration
        self.load_calibration.restype = c_ulong  # ErrCode
        # load_calibration.argtypes = (c_int32, c_char_p, c_ulong)

        self.load_settings = self.xenicsdll.XC_LoadSettings
        self.load_settings.restype = c_ulong  # ErrCode
        #self.load_settings.argtypes = (c_int32, c_char_p, c_ulong)

        # ColourProfile
        self.load_colour_profile = self.xenicsdll.XC_LoadColourProfile
        self.load_colour_profile.restype = c_ulong
        self.load_colour_profile.argtypes = (c_char_p,)

        # FileAccessCorrectionFile
        self.set_property_value = self.xenicsdll.XC_SetPropertyValue
        self.set_property_value.restype = c_ulong  # ErrCode
        # set_property_value.argtypes = (c_int32, c_char_p, c_char_p, c_char_p)

        self.get_property_value = self.xenicsdll.XC_GetPropertyValueL
        self.get_property_value.restype = c_ulong  # ErrCode
        self.get_property_value.argtypes = (c_int32, c_char_p, POINTER(c_ulong))

    def get_frame_size(self):
        '''
        Asks the camera what is the frame size in bytes.
        @return: c_ulong
        '''
        frame_size = self.get_frame_size_dll(self.xenics_handle)  # Size in bytes
        return frame_size

    def get_frame_dims(self):
        '''
        Returns frame dimensions in tuple(height, width).
        @return: tuple (c_ulong, c_ulong)
        '''
        frame_width = self.get_frame_width(self.xenics_handle)
        frame_height = self.get_frame_height(self.xenics_handle)
        print('width:', frame_width, 'height:', frame_height)
        return frame_height, frame_width

    def get_frame_type(self):
        '''
        Returns enumeration of camera's frame type.
        @return: c_ulong
        '''
        return self.get_frame_type_dll(self.xenics_handle)

    def get_pixel_dtype(self):
        '''
        Returns numpy dtype of the camera's configured data type for frame
        @return: Numpy dtype (np.uint8, np.uint16 or np.uint32)
        '''
        bytes_in_pixel = self.get_pixel_size()
        conversions = (None, np.uint8, np.uint16, None, np.uint32)
        try:
            pixel_dtype = conversions[bytes_in_pixel]
        except:
            raise Exception('Unsupported pixel size %s' % str(bytes_in_pixel))
        if conversions is None:
            raise Exception('Unsupported pixel size %s' % str(bytes_in_pixel))
        return pixel_dtype

    def get_pixel_size(self):
        '''
        Returns a frame pixel's size in bytes.
        @return: int
        '''
        frame_t = self.get_frame_type_dll(self.xenics_handle)

        FT_UNKNOWN = -1
        FT_NATIVE = 0
        FT_8_BPP_GRAY = 1
        FT_16_BPP_GRAY = 2
        FT_32_BPP_GRAY = 3
        FT_32_BPP_RGBA = 4
        FT_32_BPP_RGB = 5
        FT_32_BPP_BGRA = 6
        FT_32_BPP_BGR = 7

        pixel_sizes = {FT_UNKNOWN: 0,  # Unknown
                   FT_NATIVE: 0,  # Unknown, ask with get_frame_type
                   FT_8_BPP_GRAY: 1,
                   FT_16_BPP_GRAY: 2,
                   FT_32_BPP_GRAY: 4,
                   FT_32_BPP_RGBA: 4,
                   FT_32_BPP_RGB: 4,
                   FT_32_BPP_BGRA: 4,
                   FT_32_BPP_BGR: 4}

        return pixel_sizes[frame_t]

    def configure(self, params):
        pass

    def get_frame(self, filename):

        size = self.get_frame_size()
        dims = self.get_frame_dims()
        frame_t = self.get_frame_type()
        pixel_dtype = self.get_pixel_dtype()
        pixel_size_bytes = self.get_pixel_size()
        print('Size:', size, 'Dims:', dims, 'Frame type:', frame_t)
        frame_buffer = bytes(size)

        while True:

            error = self.get_frame_dll(self.xenics_handle,
                                    frame_t,
                                    1, # Blocking
                                    frame_buffer,
                                    size)

            if error == 0:
                frame = frame_buffer
                break

        else:
            raise Exception('Camera is not capturing.')

        # Convert the bytes buffer into an image
        im = np.frombuffer(frame,
                           dtype=pixel_dtype,
                           count=int(size/pixel_size_bytes))
        im = np.reshape(im, dims)

        # Save as png
        img = Image.fromarray(im)
        img.save(filename)


        return im


if __name__ == '__main__':

    xenics = Xenics()
    xenics.initialize()
    time.sleep(1)
    im = xenics.get_frame("trial_w_settings.png")
    plt.imshow(im)
    plt.show()
    xenics.close()

