
# This is taken from https://github.com/python-zwoasi/python-zwoasi

import ctypes as c
from ctypes.util import find_library
import numpy as np
import os
import six
import sys
import time

from photonmover.Interfaces.Camera import Camera
from photonmover.Interfaces.Instrument import Instrument

DLL_PATH = 'C:\\Program Files\\SharpCap 4.0 (64 bit)\\ASICamera2.dll'   # If None, we try to find the DLL using ctypes find_library

# ---------------- Helper classes ----------------------


class ZWO_Error(Exception):
        """Exception class for errors returned from the :mod:`zwoasi` module."""
        def __init__(self, message):
            Exception.__init__(self, message)


class ZWO_IOError(ZWO_Error):
    """Exception class for all errors returned from the ASI SDK library."""
    def __init__(self, message, error_code=None):
        ZWO_Error.__init__(self, message)
        self.error_code = error_code


class ZWO_CaptureError(ZWO_Error):
    """Exception class for when :func:`Camera.capture()` fails."""
    def __init__(self, message, exposure_status=None):
        ZWO_Error.__init__(self, message)
        self.exposure_status = exposure_status

class _ASI_CONTROL_CAPS(c.Structure):
    _fields_ = [
        ('Name', c.c_char * 64),
        ('Description', c.c_char * 128),
        ('MaxValue', c.c_long),
        ('MinValue', c.c_long),
        ('DefaultValue', c.c_long),
        ('IsAutoSupported', c.c_int),
        ('IsWritable', c.c_int),
        ('ControlType', c.c_int),
        ('Unused', c.c_char * 32),
        ]

    def get_dict(self):
        r = {}
        for k, _ in self._fields_:
            v = getattr(self, k)
            if sys.version_info[0] >= 3 and isinstance(v, bytes):
                v = v.decode()
            r[k] = v
        del r['Unused']
        for k in ('IsAutoSupported', 'IsWritable'):
            r[k] = bool(getattr(self, k))
        return r


class _ASI_ID(c.Structure):
    _fields_ = [('id', c.c_char * 8)]

    def get_id(self):
        # return self.id
        v = self.id
        if sys.version_info[0] >= 3 and isinstance(v, bytes):
            v = v.decode()
        return v


class _ASI_SUPPORTED_MODE(c.Structure):
    _fields_ = [('SupportedCameraMode', c.c_int * 16)]

    def get_dict(self):
        base_dict = {k: getattr(self, k) for k, _ in self._fields_}
        base_dict['SupportedCameraMode'] = [int(x) for x in base_dict['SupportedCameraMode']]
        return base_dict


class _ASI_CAMERA_INFO(c.Structure):
    _fields_ = [
        ('Name', c.c_char * 64),
        ('CameraID', c.c_int),
        ('MaxHeight', c.c_long),
        ('MaxWidth', c.c_long),
        ('IsColorCam', c.c_int),
        ('BayerPattern', c.c_int),
        ('SupportedBins', c.c_int * 16),
        ('SupportedVideoFormat', c.c_int * 8),
        ('PixelSize', c.c_double),  # in um
        ('MechanicalShutter', c.c_int),
        ('ST4Port', c.c_int),
        ('IsCoolerCam', c.c_int),
        ('IsUSB3Host', c.c_int),
        ('IsUSB3Camera', c.c_int),
        ('ElecPerADU', c.c_float),
        ('BitDepth', c.c_int),
        ('IsTriggerCam', c.c_int),

        ('Unused', c.c_char * 16)
    ]
    
    def get_dict(self):
        r = {}
        for k, _ in self._fields_:
            v = getattr(self, k)
            if sys.version_info[0] >= 3 and isinstance(v, bytes):
                v = v.decode()
            r[k] = v
        del r['Unused']
        
        r['SupportedBins'] = []
        for i in range(len(self.SupportedBins)):
            if self.SupportedBins[i]:
                r['SupportedBins'].append(self.SupportedBins[i])
            else:
                break
        r['SupportedVideoFormat'] = []
        for i in range(len(self.SupportedVideoFormat)):
            if self.SupportedVideoFormat[i] == ASI_IMG_END:
                break
            r['SupportedVideoFormat'].append(self.SupportedVideoFormat[i])

        for k in ('IsColorCam', 'MechanicalShutter', 'IsCoolerCam',
                'IsUSB3Host', 'IsUSB3Camera'):
            r[k] = bool(getattr(self, k))
        return r
   

# ---------------- Relevant constants ------------------

# ASI_BAYER_PATTERN
ASI_BAYER_RG = 0
ASI_BAYER_BG = 1
ASI_BAYER_GR = 2
ASI_BAYER_RB = 3

# ASI_IMGTYPE
ASI_IMG_RAW8 = 0
ASI_IMG_RGB24 = 1
ASI_IMG_RAW16 = 2
ASI_IMG_Y8 = 3
ASI_IMG_END = -1

# ASI_GUIDE_DIRECTION
ASI_GUIDE_NORTH = 0
ASI_GUIDE_SOUTH = 1
ASI_GUIDE_EAST = 2
ASI_GUIDE_WEST = 3

ASI_GAIN = 0
ASI_EXPOSURE = 1
ASI_GAMMA = 2
ASI_WB_R = 3
ASI_WB_B = 4
ASI_BRIGHTNESS = 5
ASI_OFFSET = 5
ASI_BANDWIDTHOVERLOAD = 6
ASI_OVERCLOCK = 7
ASI_TEMPERATURE = 8  # return 10*temperature
ASI_FLIP = 9
ASI_AUTO_MAX_GAIN = 10
ASI_AUTO_MAX_EXP = 11
ASI_AUTO_MAX_BRIGHTNESS = 12
ASI_HARDWARE_BIN = 13
ASI_HIGH_SPEED_MODE = 14
ASI_COOLER_POWER_PERC = 15
ASI_TARGET_TEMP = 16  # not need *10
ASI_COOLER_ON = 17
ASI_MONO_BIN = 18  # lead to less grid at software bin mode for color camera
ASI_FAN_ON = 19
ASI_PATTERN_ADJUST = 20

# ASI_CAMERA_MODE
ASI_MODE_NORMAL = 0 
ASI_MODE_TRIG_SOFT_EDGE = 1
ASI_MODE_TRIG_RISE_EDGE = 2
ASI_MODE_TRIG_FALL_EDGE = 3
ASI_MODE_TRIG_SOFT_LEVEL = 4
ASI_MODE_TRIG_HIGH_LEVEL = 5
ASI_MODE_TRIG_LOW_LEVEL = 6
ASI_MODE_END = -1

# ASI_TRIG_OUTPUT
ASI_FALSE = 0
ASI_TRUE = 1
ASI_TRIG_OUTPUT_PINA = 0
ASI_TRIG_OUTPUT_PINB = 1
ASI_TRIG_OUTPUT_NONE = -1

# ASI_EXPOSURE_STATUS
ASI_EXP_IDLE = 0
ASI_EXP_WORKING = 1
ASI_EXP_SUCCESS = 2
ASI_EXP_FAILED = 3

# Mapping of error numbers to exceptions. Zero is used for success.
zwo_errors = [None,
            ZWO_IOError('Invalid index', 1),
            ZWO_IOError('Invalid ID', 2),
            ZWO_IOError('Invalid control type', 3),
            ZWO_IOError('Camera closed', 4),
            ZWO_IOError('Camera removed', 5),
            ZWO_IOError('Invalid path', 6),
            ZWO_IOError('Invalid file format', 7),
            ZWO_IOError('Invalid size', 8),
            ZWO_IOError('Invalid image type', 9),
            ZWO_IOError('Outside of boundary', 10),
            ZWO_IOError('Timeout', 11),
            ZWO_IOError('Invalid sequence', 12),
            ZWO_IOError('Buffer too small', 13),
            ZWO_IOError('Video mode active', 14),
            ZWO_IOError('Exposure in progress', 15),
            ZWO_IOError('General error', 16),
            ZWO_IOError('Invalid mode', 17)
            ]


# ------------- THIS IS THE CLASS ------------------------

class ZWO(Instrument, Camera):

    """Interface to ZWO ASI range of USB cameras.
    Calls to the `zwoasi` module may raise :class:`TypeError` or :class:`ValueError` exceptions if an input argument
    is incorrect. Failure conditions from within the module may raise exceptions of type :class:`ZWO_Error`. Errors from
    conditions specifically from the SDK C library are indicated by errors of type :class:`ZWO_IOError`; certain
    :func:`Camera.capture()` errors are signalled by :class:`ZWO_CaptureError`."""

    def __init__(self, camera_id, dll_path=DLL_PATH):
        """
        camera_id can either be an integer or a string with the camera name
        """

        super().__init__()

        # It is good practice to initialize variables in the init
        self.zwo_dll = None
        self.zwo_handle = None
        self.dll_path = dll_path
        self.camera_id = camera_id

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
    
    def close(self):
        """Close the camera in the ASI library.
        The destructor will automatically close the camera if it has not already been closed."""
        try:
            self.close_camera()
        finally:
            self.closed = True
    
    def get_num_cameras(self):
        """Retrieves the number of ZWO ASI cameras that are connected. Type :class:`int`."""
        return self.zwo_dll.ASIGetNumOfConnectedCameras()
    
    def list_cameras(self):
        """Retrieves model names of all connected ZWO ASI cameras. Type :class:`list` of :class:`str`."""
        r = []
        for id_ in range(self.get_num_cameras()):
            r.append(self.get_camera_property(id_)['Name'])
        return r
    
    def connect(self):

        if isinstance(self.camera_id, int):
            if self.camera_id >= self.get_num_cameras() or self.camera_id < 0:
                raise IndexError('Invalid id')

        elif isinstance(self.camera_id, six.string_types):
            # Find first matching camera model
            found = False
            for n in range(self.get_num_cameras()):
                model = self.get_camera_property(n)['Name']
                if model in (self.camera_id, 'ZWO ' + self.camera_id):
                    found = True
                    self.camera_id = n
                    break
            if not found:
                raise ValueError('Could not find camera model %s' % id_)

        else:
            raise TypeError('Unknown type for id')

        self.default_timeout = -1

        try:
            self.open_camera()
            self.closed = False
            self.init_camera()

        except Exception:
            self.closed = True
            self.close_camera()
            print('could not open camera ' + str(self.camera_id))

    def get_camera_property(self, id=None):
        prop = _ASI_CAMERA_INFO()
        if id is None:
            r = self.zwo_dll.ASIGetCameraProperty(prop, self.camera_id)
        else:
            r = self.zwo_dll.ASIGetCameraProperty(prop, id)
        if r:
            raise zwo_errors[r]
        return prop.get_dict()

    def open_camera(self):
        r = self.zwo_dll.ASIOpenCamera(self.camera_id)
        if r:
            raise zwo_errors[r]
        return

    def init_camera(self):
        r = self.zwo_dll.ASIInitCamera(self.camera_id)
        if r:
            raise zwo_errors[r]
        return
    
    def close_camera(self):
        r = self.zwo_dll.ASICloseCamera(self.camera_id)
        if r:
            raise zwo_errors[r]
        return

    def get_num_controls(self):
        num = c.c_int()
        r = self.zwo_dll.ASIGetNumOfControls(self.camera_id, num)
        if r:
            raise zwo_errors[r]
        return num.value

    def get_control_caps(self, control_index):
        caps = _ASI_CONTROL_CAPS()
        r = self.zwo_dll.ASIGetControlCaps(self.camera_id, control_index, caps)
        if r:
            raise zwo_errors[r]
        return caps.get_dict()

    def get_control_value(self, control_type):
        value = c.c_long()
        auto = c.c_int()
        r = self.zwo_dll.ASIGetControlValue(self.camera_id, control_type, value, auto)
        if r:
            raise zwo_errors[r]
        return [value.value, bool(auto.value)]

    def set_control_value(self, control_type, value, auto=ASI_FALSE):
        r = self.zwo_dll.ASISetControlValue(self.camera_id, control_type, value, auto)
        if r:
            raise zwo_errors[r]
        return

    def get_roi_format(self):
        roi_width = c.c_int()
        roi_height = c.c_int()
        bins = c.c_int()
        image_type = c.c_int()
        r = self.zwo_dll.ASIGetROIFormat(self.camera_id, roi_width, roi_height, bins, image_type)
        if r:
            raise zwo_errors[r]
        return [roi_width.value, roi_height.value, bins.value, image_type.value]

    def set_roi_format(self, width, height, bins, image_type):
        cam_info = self.get_camera_property()

        if width < 8:
            raise ValueError('ROI width too small')
        elif width > int(cam_info['MaxWidth'] / bins):
            raise ValueError('ROI width larger than binned sensor width')
        elif width % 8 != 0:
            raise ValueError('ROI width must be multiple of 8')

        if height < 2:
            raise ValueError('ROI height too small')
        elif height > int(cam_info['MaxHeight'] / bins):
            raise ValueError('ROI width larger than binned sensor height')
        elif height % 2 != 0:
            raise ValueError('ROI height must be multiple of 2')

        if cam_info['Name'] in ['ZWO ASI120MM', 'ZWO ASI120MC'] and (width * height) % 1024 != 0:
            raise ValueError('ROI width * height must be multiple of 1024 for ' +
                            cam_info['Name'])
        r = self.zwo_dll.ASISetROIFormat(self.camera_id, width, height, bins, image_type)
        if r:
            raise zwo_errors[r]
        return

    def get_start_position(self):
        start_x = c.c_int()
        start_y = c.c_int()
        r = self.zwo_dll.ASIGetStartPos(self.camera_id, start_x, start_y)
        if r:
            raise zwo_errors[r]
        return [start_x.value, start_y.value]

    def set_start_position(self, start_x, start_y):
        if start_x < 0:
            raise ValueError('X start position too small')
        if start_y < 0:
            raise ValueError('Y start position too small')

        r = self.zwo_dll.ASISetStartPos(self.camera_id, start_x, start_y)
        if r:
            raise zwo_errors[r]
        return

    def get_dropped_frames(self):
        dropped_frames = c.c_int()
        r = self.zwo_dll.ASIGetDroppedFrames(self.camera_id, dropped_frames)
        if r:
            raise zwo_errors[r]
        return dropped_frames.value

    def enable_dark_subtract(self, filename):
        r = self.zwo_dll.ASIEnableDarkSubtract(self.camera_id, filename)
        if r:
            raise zwo_errors[r]
        return

    def disable_dark_subtract(self):
        r = self.zwo_dll.ASIDisableDarkSubtract(self.camera_id)
        if r:
            raise zwo_errors[r]
        return
        
    def start_video_capture(self):
        """Enable video capture mode.
        Retrieve video frames with :func:`capture_video_frame()`."""
        r = self.zwo_dll.ASIStartVideoCapture(self.camera_id)
        if r:
            raise zwo_errors[r]
        return
        
    def stop_video_capture(self):
        """Leave video capture mode."""
        r = self.zwo_dll.ASIStopVideoCapture(self.camera_id)
        if r:
            raise zwo_errors[r]
        return

    def get_video_data(self, timeout, buffer_=None):
        """Retrieve a single video frame. Type :class:`bytearray`.
        Low-level function to retrieve data. See :func:`capture_video_frame()` for a more convenient method to
        acquire an image (and optionally save it)."""   
        if timeout is None:
            timeout = self.default_timeout
        if buffer_ is None:
            whbi = self.get_roi_format(self.camera_id)
            sz = whbi[0] * whbi[1]
            if whbi[3] == ASI_IMG_RGB24:
                sz *= 3
            elif whbi[3] == ASI_IMG_RAW16:
                sz *= 2
            buffer_ = bytearray(sz)
        else:
            if not isinstance(buffer_, bytearray):
                raise TypeError('Supplied buffer must be a bytearray')
            sz = len(buffer_)
        
        cbuf_type = c.c_char * len(buffer_)
        cbuf = cbuf_type.from_buffer(buffer_)
        r = self.zwo_dll.ASIGetVideoData(self.camera_id, cbuf, sz, int(timeout))
        
        if r:
            raise zwo_errors[r]
        return buffer_

    def pulse_guide_on(self, direction):
        r = self.zwo_dll.ASIPulseGuideOn(self.camera_id, direction)
        if r:
            raise zwo_errors[r]
        return

    def pulse_guide_off(self, direction):
        r = self.zwo_dll.ASIPulseGuideOff(self.camera_id, direction)
        if r:
            raise zwo_errors[r]
        return

    def start_exposure(self, is_dark):
        r = self.zwo_dll.ASIStartExposure(self.camera_id, is_dark)
        if r:
            raise zwo_errors[r]
        return

    def stop_exposure(self):
        r = self.zwo_dll.ASIStopExposure(self.camera_id)
        if r:
            raise zwo_errors[r]
        return

    def get_exposure_status(self):
        status = c.c_int()
        r = self.zwo_dll.ASIGetExpStatus(self.camera_id, status)
        if r:
            raise zwo_errors[r]
        return status.value

    def get_data_after_exposure(self, buffer_=None):
        if buffer_ is None:
            whbi = self.get_roi_format()
            sz = whbi[0] * whbi[1]
            if whbi[3] == ASI_IMG_RGB24:
                sz *= 3
            elif whbi[3] == ASI_IMG_RAW16:
                sz *= 2
            buffer_ = bytearray(sz)
        else:
            if not isinstance(buffer_, bytearray):
                raise TypeError('Supplied buffer must be a bytearray')
            sz = len(buffer_)
        
        cbuf_type = c.c_char * len(buffer_)
        cbuf = cbuf_type.from_buffer(buffer_)
        r = self.zwo_dll.ASIGetDataAfterExp(self.camera_id, cbuf, sz)
        
        if r:
            raise zwo_errors[r]
        return buffer_

    def get_id(self):
        id2 = _ASI_ID()
        r = self.zwo_dll.ASIGetID(self.camera_id, id2)
        if r:
            raise zwo_errors[r]
        return id2.get_id()

    def set_id(self, new_id):
        id2 = _ASI_ID(new_id.encode())
        r = self.zwo_dll.ASISetID(self.camera_id, id2)
        if r:
            raise zwo_errors[r]

    def get_gain_offset(self):
        offset_highest_DR = c.c_int()
        offset_unity_gain = c.c_int()
        gain_lowest_RN = c.c_int()
        offset_lowest_RN = c.c_int()
        r = self.zwo_dll.ASIGetGainOffset(self.camera_id, offset_highest_DR, offset_unity_gain,
                                    gain_lowest_RN, offset_lowest_RN)
        if r:
            raise zwo_errors[r]
        return [offset_highest_DR.value, offset_unity_gain.value,
                gain_lowest_RN.value, offset_lowest_RN.value]

    def get_trigger_output_io_conf(self, pin):
        bPinHigh = c.c_int()
        lDelay = c.c_long()
        lDuration = c.c_long()
        r = self.zwo_dll.ASIGetTriggerOutputIOConf(self.camera_id, pin, bPinHigh, lDelay, lDuration)

        if r:
            raise zwo_errors[r]
        return [bPinHigh.value, lDelay.value, lDuration.value]

    def set_trigger_output_io_conf(self, pin, bPinHigh, lDelay, lDuration):
        r = self.zwo_dll.ASISetTriggerOutputIOConf(self.camera_id, pin, bPinHigh, lDelay, lDuration)

        if r:
            raise zwo_errors[r]
        return

    def get_camera_support_mode(self):
        mode = _ASI_SUPPORTED_MODE()

        r = self.zwo_dll.ASIGetCameraSupportMode(self.camera_id, mode)
        if r:
            raise zwo_errors[r]
        return mode.get_dict()

    def get_camera_mode(self):
        mode = c.c_int()
        r = self.zwo_dll.ASIGetCameraMode(self.camera_id, mode)
        if r:
            raise zwo_errors[r]
        return mode.value

    def set_camera_mode(self, mode):
        r = self.zwo_dll.ASISetCameraMode(self.camera_id, mode)
        if r:
            raise zwo_errors[r]
        return

    def send_soft_trigger(self, bStart):
        r = self.zwo_dll.ASISendSoftTrigger(self.camera_id, bStart)
        if r:
            raise zwo_errors[r]
        return
    
    def get_roi(self):
        """Retrieves the region of interest (ROI).
        Returns a :class:`tuple` containing ``(start_x, start_y, width, height)``."""
        xywh = self.get_roi_start_position()
        whbi = self.get_roi_format()
        xywh.extend(whbi[0:2])
        return xywh

    def set_roi(self, start_x=None, start_y=None, width=None, height=None, bins=None, image_type=None):
        """Set the region of interest (ROI).
        If ``bins`` is not given then the current pixel binning value will be used. The ROI coordinates are considered
        after binning has been taken into account, ie if ``bins=2`` then the maximum possible height is reduced by a
        factor of two.
        If ``width=None`` or ``height=None`` then the maximum respective value will be used. The ASI SDK
        library requires that width is a multiple of 8 and height is a multiple of 2; a ValueError will be raised
        if this is not the case.
        If ``start_x=None`` then the ROI will be horizontally centred. If ``start_y=None`` then the ROI will be
        vertically centred."""
        cam_info = self.get_camera_property()
        whbi = self.get_roi_format()

        if bins is None:
            bins = whbi[2]
        elif 'SupportedBins' in cam_info and bins not in cam_info['SupportedBins']:
            raise ValueError('Illegal value for bins')

        if image_type is None:
            image_type = whbi[3]
            
        if width is None:
            width = int(cam_info['MaxWidth'] / bins)
            width -= width % 8  # Must be a multiple of 8

        if height is None:
            height = int(cam_info['MaxHeight'] / bins)
            height -= height % 2  # Must be a multiple of 2

        if start_x is None:
            start_x = int((int(cam_info['MaxWidth'] / bins) - width) / 2)
        if start_x + width > int(cam_info['MaxWidth'] / bins):
            raise ValueError('ROI and start position larger than binned sensor width')
        if start_y is None:
            start_y = int((int(cam_info['MaxHeight'] / bins) - height) / 2)
        if start_y + height > int(cam_info['MaxHeight'] / bins):
            raise ValueError('ROI and start position larger than binned sensor height')

        self.set_roi_format(width, height, bins, image_type)
        self.set_roi_start_position(start_x, start_y)
    
    def get_bin(self):
        """Retrieves the pixel binning. Type :class:`int`.
        A pixel binning of one means no binning is active, a value of 2 indicates two pixels horizontally and two
        pixels vertically are binned."""
        return self.get_roi_format()[2]
    
    def get_image_type(self):
        return self.get_roi_format()[3]

    def set_image_type(self, image_type):
        whbi = self.get_roi_format()
        whbi[3] = image_type
        self.set_roi_format(*whbi)

    def get_frame(self, filename):
        self.capture(filename=filename)

    def capture(self, initial_sleep=0.01, poll=0.01, buffer_=None, filename=None, save_settings=True):
        """Capture a still image. Type :class:`numpy.ndarray`.
        Filename has to include the file format (.tiff, .jpg...)
        If save_settings is True and filename is not None, we also save a .txt with the camera settings
        """

        self.start_exposure(0)
        if initial_sleep:
            time.sleep(initial_sleep)
        while self.get_exposure_status() == ASI_EXP_WORKING:
            if poll:
                time.sleep(poll)
            pass

        status = self.get_exposure_status()
        if status != ASI_EXP_SUCCESS:
            raise ZWO_CaptureError('Could not capture image', status)
        
        data = self.get_data_after_exposure(buffer_)
        whbi = self.get_roi_format()
        shape = [whbi[1], whbi[0]]
        if whbi[3] == ASI_IMG_RAW8 or whbi[3] == ASI_IMG_Y8:
            img = np.frombuffer(data, dtype=np.uint8)
        elif whbi[3] == ASI_IMG_RAW16:
            img = np.frombuffer(data, dtype=np.uint16)
        elif whbi[3] == ASI_IMG_RGB24:
            img = np.frombuffer(data, dtype=np.uint8)
            shape.append(3)
        else:
            raise ValueError('Unsupported image type')
        img = img.reshape(shape)

        if filename is not None:
            from PIL import Image
            mode = None
            if len(img.shape) == 3:
                img = img[:, :, ::-1]  # Convert BGR to RGB
            if whbi[3] == ASI_IMG_RAW16:
                mode = 'I;16'
            image = Image.fromarray(img, mode=mode)
            image.save(filename)
            print('Image saved in %s' % filename)

            if save_settings:
                settings = self.get_control_values()
                filename = os.path.splitext(filename)[0] + '.txt'
                with open(filename, 'w') as f:
                    for k in sorted(settings.keys()):
                        f.write('%s: %s\n' % (k, str(settings[k])))
                print('Camera settings saved to %s' % filename)

        return img

    def capture_video_frame(self, buffer_=None, filename=None, timeout=None, save_settings=True):
        """Capture a single frame from video. Type :class:`numpy.ndarray`.
        Video mode must have been started previously otherwise a :class:`ZWO_Error` will be raised. A new buffer
        will be used to store the image unless one has been supplied with the `buffer` keyword argument.
        If `filename` is not ``None`` the image is saved using :py:meth:`PIL.Image.Image.save()`.
        :func:`capture_video_frame()` will wait indefinitely unless a `timeout` has been given.
        The SDK suggests that the `timeout` value, in milliseconds, should be twice the exposure plus 500 ms."""

        data = self.get_video_data(buffer_=buffer_, timeout=timeout)
        whbi = self.get_roi_format()
        shape = [whbi[1], whbi[0]]
        if whbi[3] == ASI_IMG_RAW8 or whbi[3] == ASI_IMG_Y8:
            img = np.frombuffer(data, dtype=np.uint8)
        elif whbi[3] == ASI_IMG_RAW16:
            img = np.frombuffer(data, dtype=np.uint16)
        elif whbi[3] == ASI_IMG_RGB24:
            img = np.frombuffer(data, dtype=np.uint8)
            shape.append(3)
        else:
            raise ValueError('Unsupported image type')
        img = img.reshape(shape)

        if filename is not None:
            from PIL import Image
            mode = None
            if len(img.shape) == 3:
                img = img[:, :, ::-1]  # Convert BGR to RGB
            if whbi[3] == ASI_IMG_RAW16:
                mode = 'I;16'
            image = Image.fromarray(img, mode=mode)
            image.save(filename)
            print('Video frame saved in %s' % filename)

            if save_settings:
                settings = self.get_control_values()
                filename = os.path.splitext(filename)[0] + '.txt'
                with open(filename, 'w') as f:
                    for k in sorted(settings.keys()):
                        f.write('%s: %s\n' % (k, str(settings[k])))
                print('Camera settings saved to %s' % filename)

        return img

    def get_control_values(self):
        controls = self.get_controls()
        r = {}
        for k in controls:
            r[k] = self.get_control_value(controls[k]['ControlType'])[0]
        return r

    def auto_exposure(self, auto=('Exposure', 'Gain')):
        controls = self.get_controls()
        r = []
        for ctrl in auto:
            if ctrl == 'BandWidth':
                continue  # auto setting is supported but is not an exposure setting
            if ctrl in controls and controls[ctrl]['IsAutoSupported']:
                self.set_control_value(controls[ctrl]['ControlType'],
                                    controls[ctrl]['DefaultValue'],
                                    auto=True)
                r.append(ctrl)
        return r

    def auto_wb(self, wb=('WB_B', 'WB_R')):
        return self.auto_exposure(auto=wb)
    
    def get_controls(self):
        r = {}
        for i in range(self.get_num_controls()):
            d = self.get_control_caps(i)
            r[d['Name']] = d
        return r

    def configure(self, params):
        pass

    def load_dll(self):

        if self.dll_path is None:
            self.dll_path = find_library('ASICamera2')

        if self.dll_path is None:
            raise ZWO_Error('ASI SDK library not found')

        self.zwo_dll = c.cdll.LoadLibrary(self.dll_path)

        # Now we just need to "declare" all the functions from the dll.

        self.zwo_dll.ASIGetNumOfConnectedCameras.argtypes = []
        self.zwo_dll.ASIGetNumOfConnectedCameras.restype = c.c_int

        self.zwo_dll.ASIGetCameraProperty.argtypes = [c.POINTER(_ASI_CAMERA_INFO), c.c_int]
        self.zwo_dll.ASIGetCameraProperty.restype = c.c_int

        self.zwo_dll.ASIOpenCamera.argtypes = [c.c_int]
        self.zwo_dll.ASIOpenCamera.restype = c.c_int

        self.zwo_dll.ASIInitCamera.argtypes = [c.c_int]
        self.zwo_dll.ASIInitCamera.restype = c.c_int

        self.zwo_dll.ASICloseCamera.argtypes = [c.c_int]
        self.zwo_dll.ASICloseCamera.restype = c.c_int

        self.zwo_dll.ASIGetNumOfControls.argtypes = [c.c_int, c.POINTER(c.c_int)]
        self.zwo_dll.ASIGetNumOfControls.restype = c.c_int

        self.zwo_dll.ASIGetControlCaps.argtypes = [c.c_int, c.c_int,
                                            c.POINTER(_ASI_CONTROL_CAPS)]
        self.zwo_dll.ASIGetControlCaps.restype = c.c_int

        self.zwo_dll.ASIGetControlValue.argtypes = [c.c_int,
                                            c.c_int,
                                            c.POINTER(c.c_long),
                                            c.POINTER(c.c_int)]
        self.zwo_dll.ASIGetControlValue.restype = c.c_int

        self.zwo_dll.ASISetControlValue.argtypes = [c.c_int, c.c_int, c.c_long, c.c_int]
        self.zwo_dll.ASISetControlValue.restype = c.c_int

        self.zwo_dll.ASIGetROIFormat.argtypes = [c.c_int,
                                        c.POINTER(c.c_int),
                                        c.POINTER(c.c_int),
                                        c.POINTER(c.c_int),
                                        c.POINTER(c.c_int)]
        self.zwo_dll.ASIGetROIFormat.restype = c.c_int

        self.zwo_dll.ASISetROIFormat.argtypes = [c.c_int, c.c_int, c.c_int, c.c_int, c.c_int]
        self.zwo_dll.ASISetROIFormat.restype = c.c_int

        self.zwo_dll.ASIGetStartPos.argtypes = [c.c_int,
                                        c.POINTER(c.c_int),
                                        c.POINTER(c.c_int)]
        self.zwo_dll.ASIGetStartPos.restype = c.c_int

        self.zwo_dll.ASISetStartPos.argtypes = [c.c_int, c.c_int, c.c_int]
        self.zwo_dll.ASISetStartPos.restype = c.c_int

        self.zwo_dll.ASIGetDroppedFrames.argtypes = [c.c_int, c.POINTER(c.c_int)]
        self.zwo_dll.ASIGetDroppedFrames.restype = c.c_int

        self.zwo_dll.ASIEnableDarkSubtract.argtypes = [c.c_int, c.POINTER(c.c_char)]
        self.zwo_dll.ASIEnableDarkSubtract.restype = c.c_int

        self.zwo_dll.ASIDisableDarkSubtract.argtypes = [c.c_int]
        self.zwo_dll.ASIDisableDarkSubtract.restype = c.c_int

        self.zwo_dll.ASIStartVideoCapture.argtypes = [c.c_int]
        self.zwo_dll.ASIStartVideoCapture.restype = c.c_int

        self.zwo_dll.ASIStopVideoCapture.argtypes = [c.c_int]
        self.zwo_dll.ASIStopVideoCapture.restype = c.c_int

        self.zwo_dll.ASIGetVideoData.argtypes = [c.c_int,
                                        c.POINTER(c.c_char),
                                        c.c_long,
                                        c.c_int]
        self.zwo_dll.ASIGetVideoData.restype = c.c_int

        self.zwo_dll.ASIPulseGuideOn.argtypes = [c.c_int, c.c_int]
        self.zwo_dll.ASIPulseGuideOn.restype = c.c_int

        self.zwo_dll.ASIPulseGuideOff.argtypes = [c.c_int, c.c_int]
        self.zwo_dll.ASIPulseGuideOff.restype = c.c_int

        self.zwo_dll.ASIStartExposure.argtypes = [c.c_int, c.c_int]
        self.zwo_dll.ASIStartExposure.restype = c.c_int

        self.zwo_dll.ASIStopExposure.argtypes = [c.c_int]
        self.zwo_dll.ASIStopExposure.restype = c.c_int

        self.zwo_dll.ASIGetExpStatus.argtypes = [c.c_int, c.POINTER(c.c_int)]
        self.zwo_dll.ASIGetExpStatus.restype = c.c_int

        self.zwo_dll.ASIGetDataAfterExp.argtypes = [c.c_int, c.POINTER(c.c_char), c.c_long]
        self.zwo_dll.ASIGetDataAfterExp.restype = c.c_int

        self.zwo_dll.ASIGetID.argtypes = [c.c_int, c.POINTER(_ASI_ID)]
        self.zwo_dll.ASIGetID.restype = c.c_int

        self.zwo_dll.ASISetID.argtypes = [c.c_int, _ASI_ID]
        self.zwo_dll.ASISetID.restype = c.c_int


        self.zwo_dll.ASIGetGainOffset.argtypes = [c.c_int,
                                            c.POINTER(c.c_int),
                                            c.POINTER(c.c_int),
                                            c.POINTER(c.c_int),
                                            c.POINTER(c.c_int)]
        self.zwo_dll.ASIGetGainOffset.restype = c.c_int

        self.zwo_dll.ASISetCameraMode.argtypes = [c.c_int, c.c_int]
        self.zwo_dll.ASISetCameraMode.restype = c.c_int

        self.zwo_dll.ASIGetCameraMode.argtypes = [c.c_int, c.POINTER(c.c_int)]
        self.zwo_dll.ASIGetCameraMode.restype = c.c_int

        self.zwo_dll.ASIGetCameraSupportMode.argtypes = [c.c_int, c.POINTER(_ASI_SUPPORTED_MODE)]
        self.zwo_dll.ASIGetCameraSupportMode.restype = c.c_int

        self.zwo_dll.ASISendSoftTrigger.argtypes = [c.c_int, c.c_int]
        self.zwo_dll.ASISendSoftTrigger.restype = c.c_int

        self.zwo_dll.ASISetTriggerOutputIOConf.argtypes = [c.c_int,
                                                    c.c_int,
                                                    c.c_int,
                                                    c.c_long,
                                                    c.c_long]
        self.zwo_dll.ASISetTriggerOutputIOConf.restype = c.c_int

        self.zwo_dll.ASIGetTriggerOutputIOConf.argtypes = [c.c_int,
                                                    c.c_int,
                                                    c.POINTER(c.c_int),
                                                    c.POINTER(c.c_long),
                                                    c.POINTER(c.c_long)]
        self.zwo_dll.ASIGetTriggerOutputIOConf.restype = c.c_int


if __name__ == '__main__':

    camera = ZWO(camera_id=0)  # Connect to the first camera
    camera.initialize()
    camera_info = camera.get_camera_property()

    # Get all of the camera controls
    print('')
    print('Camera controls:')
    controls = camera.get_controls()
    for cn in sorted(controls.keys()):
        print('    %s:' % cn)
        for k in sorted(controls[cn].keys()):
            print('        %s: %s' % (k, repr(controls[cn][k])))

    # Use minimum USB bandwidth permitted
    #camera.set_control_value(ASI_BANDWIDTHOVERLOAD, camera.get_controls()['BandWidth']['MinValue'])

    # Set some sensible defaults. They will need adjusting depending upon
    # the sensitivity, lens and lighting conditions used.
    camera.disable_dark_subtract()
    camera.set_control_value(ASI_GAIN, 150, ASI_FALSE)  # False is to indicate the parameter is not auto set
    camera.set_control_value(ASI_EXPOSURE, 30000, ASI_FALSE)
    camera.set_control_value(ASI_WB_B, 99, ASI_FALSE)
    camera.set_control_value(ASI_WB_R, 75, ASI_FALSE)
    camera.set_control_value(ASI_GAMMA, 50, ASI_FALSE)
    camera.set_control_value(ASI_BRIGHTNESS, 50, ASI_FALSE)
    camera.set_control_value(ASI_FLIP, 0, ASI_FALSE)

    print('Enabling stills mode')
    try:
        # Force any single exposure to be halted
        camera.stop_video_capture()
        camera.stop_exposure()
    except (KeyboardInterrupt, SystemExit):
        raise
    except:
        pass

    print('Capturing a single 8-bit mono image')
    filename = 'image_mono.jpg'
    camera.set_image_type(ASI_IMG_RAW8)
    camera.capture(filename=filename)
    print('Saved to %s' % filename)

    print('Capturing a single 16-bit mono image')
    filename = 'image_mono16.tiff'
    camera.set_image_type(ASI_IMG_RAW16)
    camera.capture(filename=filename)
    print('Saved to %s' % filename)

    if camera_info['IsColorCam']:
        filename = 'image_color.jpg'
        camera.set_image_type(ASI_IMG_RGB24)
        print('Capturing a single, color image')
        camera.capture(filename=filename)
        print('Saved to %s' % filename)
    else:
        print('Color image not available with this camera')
        
    # Enable video mode
    try:
        # Force any single exposure to be halted
        camera.stop_exposure()
    except (KeyboardInterrupt, SystemExit):
        raise
    except:
        pass