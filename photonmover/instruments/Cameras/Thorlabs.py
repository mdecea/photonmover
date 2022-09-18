# Copyright 2014, Thomas G. Dimiduk, Rebecca W. Perry, Aaron Goldfain
#
# Taken from https://github.com/manoharan-lab/camera-controller

"""
Higher Level interface to Thorlabs usb cameras.
This does not have the ablility to save images/videos or capture sequences of frames.
It is a basic interface to control the camera and get an image from it
So far it has only been used with Thorlabs camera DCC1545M.
"""
import numpy as np
import os.path
import matplotlib.pyplot as plt

from ctypes import *
import ctypes.wintypes as wt

from photonmover.Interfaces.Camera import Camera
from photonmover.Interfaces.Instrument import Instrument

DLL_PATH = "C:\\Program Files\\Thorlabs\\Scientific Imaging\\ThorCam\\uc480_64.dll"

# Relevant constants
IS_WAIT = 0x0001
IS_IMAGE_FILE_CMD_SAVE = 2

IS_IMG_BMP = 0
IS_IMG_JPG = 1
IS_IMG_PNG = 2
IS_IMG_RAW = 4
IS_IMG_TIF = 8


class IMAGE_FILE_PARAMS(Structure):
    """
    :var ctypes.c_wchar_p pwchFileName:
    :var UINT nFileType:
    :var UINT nQuality:
    :var ctypes.POINTER(ctypes.c_char_p) ppcImageMem:
    :var ctypes.POINTER(wt.UINT) pnImageID:
    :var BYTE[32] reserved:
    """
    _fields_ = [("pwchFileName", c_wchar_p),
                ("nFileType", wt.UINT),
                ("nQuality", wt.UINT),
                ("ppcImageMem", POINTER(c_char_p)),
                ("pnImageID", POINTER(wt.UINT)),
                ("reserved", wt.BYTE * 32)]


class CameraOpenError(Exception):
    def __init__(self, mesg):
        self.mesg = mesg

    def __str__(self):
        return self.mesg


class ThorlabsCamera(Instrument, Camera):

    def __init__(self, camera_id=0, dll_path=DLL_PATH):

        if os.path.isfile(dll_path):
            self.bit_depth = None
            self.roi_shape = None
            self.camera = None
            self.handle = None
            self.meminfo = None
            self.exposure = None
            self.roi_pos = None
            self.frametime = None
            self.dll_path = dll_path
            self.camera_id = camera_id
            self.handle = None
        else:
            raise CameraOpenError("ThorCam drivers not available.")

    def initialize(self):

        # Load library
        self.thorlabs_dll = windll.LoadLibrary(self.dll_path)

        # Connect to camera
        self.connect()

    def close(self):

        if self.handle is not None:
            i = self.thorlabs_dll.is_ExitCamera(self.handle)
            if i == 0:
                print("ThorCam closed successfully.")
            else:
                print("Closing ThorCam failed with error code " + str(i))
        else:
            return

    # ---------------- PARAMETER SETTERS -----------------

    def set_bit_depth(self, set_bit_depth=8):
        if set_bit_depth != 8:
            print("only 8-bit images supported")

    def set_roi_shape(self, set_roi_shape):
        class IS_SIZE_2D(Structure):
            _fields_ = [('s32Width', c_int), ('s32Height', c_int)]
        AOI_size = IS_SIZE_2D(
            set_roi_shape[0],
            set_roi_shape[1])  # Width and Height

        is_AOI = self.thorlabs_dll.is_AOI
        is_AOI.argtypes = [c_int, c_uint, POINTER(IS_SIZE_2D), c_uint]
        # 5 for setting size, 3 for setting position
        i = is_AOI(self.handle, 5, byref(AOI_size), 8)
        # 6 for getting size, 4 for getting position
        is_AOI(self.handle, 6, byref(AOI_size), 8)
        self.roi_shape = [AOI_size.s32Width, AOI_size.s32Height]

        if i == 0:
            print("ThorCam ROI size set successfully.")
            self.initialize_memory()
        else:
            print("Set ThorCam ROI size failed with error code " + str(i))

    def set_roi_pos(self, set_roi_pos):
        class IS_POINT_2D(Structure):
            _fields_ = [('s32X', c_int), ('s32Y', c_int)]
        AOI_pos = IS_POINT_2D(
            set_roi_pos[0],
            set_roi_pos[1])  # Width and Height

        is_AOI = self.thorlabs_dll.is_AOI
        is_AOI.argtypes = [c_int, c_uint, POINTER(IS_POINT_2D), c_uint]
        # 5 for setting size, 3 for setting position
        i = is_AOI(self.handle, 3, byref(AOI_pos), 8)
        # 6 for getting size, 4 for getting position
        is_AOI(self.handle, 4, byref(AOI_pos), 8)
        self.roi_pos = [AOI_pos.s32X, AOI_pos.s32Y]

        if i == 0:
            print("ThorCam ROI position set successfully.")
        else:
            print("Set ThorCam ROI size failed with error code " + str(i))

    def set_exposure(self, exposure):
        # exposure should be given in ms
        exposure_c = c_double(exposure)
        is_Exposure = self.thorlabs_dll.is_Exposure
        is_Exposure.argtypes = [c_int, c_uint, POINTER(c_double), c_uint]
        # 12 is for setting exposure
        is_Exposure(self.handle, 12, exposure_c, 8)
        self.exposure = exposure_c.value

        # The change in exposure only 'updates' after making an acquisition, so make
        # a dummy acquisition
        self.get_frame('foo.bmp')
        os.remove("foo.bmp")

    def set_frametime(self, frametime):
        # must reset exposure after setting framerate
        # frametime should be givin in ms. Framerate = 1/frametime
        is_SetFrameRate = self.thorlabs_dll.is_SetFrameRate

        if frametime == 0:
            frametime = 0.001

        set_framerate = c_double(0)
        is_SetFrameRate.argtypes = [c_int, c_double, POINTER(c_double)]
        is_SetFrameRate(self.handle,
                        1.0 / (frametime / 1000.0),
                        byref(set_framerate))
        self.frametime = (1.0 / set_framerate.value * 1000.0)

    def configure(self, params):
        pass

    # ------------------------------ GET FRAME -----------------------

    def get_frame(self, filename):

        success_acq = self.thorlabs_dll.is_FreezeVideo(self.handle, 500)
        file_ext = os.path.splitext(filename)[-1]
        file_ext_indicator = IS_IMG_TIF
        if file_ext == '.bmp':
            file_ext_indicator = IS_IMG_BMP
        if file_ext == '.jpg' or file_ext == '.jpeg':
            file_ext_indicator = IS_IMG_JPG
        if file_ext == '.png':
            file_ext_indicator = IS_IMG_PNG
        if file_ext == '.tiff':
            file_ext_indicator = IS_IMG_TIF

        file_props = IMAGE_FILE_PARAMS(
            filename, file_ext_indicator, 0, None, None)
        success_save = self.thorlabs_dll.is_ImageFile(
            self.handle, IS_IMAGE_FILE_CMD_SAVE, byref(file_props), sizeof(file_props))

        if success_acq != 0:
            print('Error in acquisition with code %d' % success_acq)
        if success_save != 0:
            print('Error in frame save with code %d' % success_save)

    def initialize_memory(self):
        if self.meminfo is not None:
            self.thorlabs_dll.is_FreeImageMem(
                self.handle, self.meminfo[0], self.meminfo[1])

        xdim = self.roi_shape[0]
        ydim = self.roi_shape[1]
        imagesize = xdim * ydim

        memid = c_int(0)
        c_buf = (c_ubyte * imagesize)(0)
        self.thorlabs_dll.is_SetAllocatedImageMem(
            self.handle, xdim, ydim, 8, c_buf, byref(memid))
        self.thorlabs_dll.is_SetImageMem(self.handle, c_buf, memid)
        self.meminfo = [c_buf, memid]

    def connect(
        self, bit_depth=8, roi_shape=(
            1024, 1024), roi_pos=(
            0, 0), exposure=20.0, frametime=340.0):
        self.bit_depth = bit_depth
        self.roi_shape = roi_shape
        self.roi_pos = roi_pos

        is_InitCamera = self.thorlabs_dll.is_InitCamera
        is_InitCamera.argtypes = [POINTER(c_int)]
        self.handle = c_int(self.camera_id)
        i = is_InitCamera(byref(self.handle))

        if i == 0:
            print("ThorCam opened successfully.")
            pixelclock = c_uint(11)  # set pixel clock to 43 MHz (fastest)
            is_PixelClock = self.thorlabs_dll.is_PixelClock
            is_PixelClock.argtypes = [c_int, c_uint, POINTER(c_uint), c_uint]
            is_PixelClock(self.handle, 6, byref(pixelclock), sizeof(
                pixelclock))  # 6 for setting pixel clock

            # 6 is for monochrome 8 bit. See uc480.h for definitions
            self.thorlabs_dll.is_SetColorMode(self.handle, 6)
            self.set_roi_shape(self.roi_shape)
            self.set_roi_pos(self.roi_pos)
            self.set_frametime(frametime)
            self.set_exposure(exposure)
        else:
            raise CameraOpenError(
                "Opening the ThorCam failed with error code " + str(i))


if __name__ == '__main__':

    camera = ThorlabsCamera()
    camera.initialize()
    camera.get_frame("trial.bmp")
    # plt.imshow(im)
    # plt.show()
    camera.close()
