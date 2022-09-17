# There is a package provided by pixelink that provides a python wrapper
# of the DLL. 
# See https://github.com/pixelink-support/pixelinkPythonWrapper
# We can just directly use that package to talk to the pixelink.
# 
# To install the package: pip install pixelinkWrapper
# For it to work you need the pixelink capture app or the pixelink SDK. 

import sys
sys.path.insert(0,'../..')

try:    
    from pixelinkWrapper import*
except:
    print('No pixelink drivers found.')
    
from ctypes import*
import os

from Interfaces.Camera import Camera
from Interfaces.Instrument import Instrument

SUCCESS = 0
FAILURE = 1

class Pixelink(Instrument, Camera):

    def __init__(self, camera_id=0, image_format='TIFF'):
        """
        camera_id is an integer with the camera number. If there is only one pixelink camera, camera_id=0 will connect to it.
        image_format specifies which fromat we want to save captured images. This can be set on runtime. 
        """

        super().__init__()

        # It is good practice to initialize variables in the init
        self.camera_id = camera_id
        self.camera_handle = None
        self.image_format = None

        self.set_image_format(image_format)

    def initialize(self):
        """
        Connect to the camera
        """

        num_cameras = self.list_cameras()

        if self.camera_id >= num_cameras or self.camera_id < 0:
            raise Exception('Camera id is not there or invalid!')
        
        # Tell the camera we want to start using it.
        ret = PxLApi.initialize(self.camera_id)
        if not PxLApi.apiSuccess(ret[0]):
            raise Exception('Could not connect to Pixelink camera')

        self.camera_handle = ret[1]
    
    def set_image_format(self, image_format):
        """
        Sets the image format when images are saved.
        One of 'jpeg', 'bmp', 'tiff', 'psd', 'raw_bgr24', 'raw_bgr24_non_dib', 'raw_rgb48', 'raw_mono8'
        """

        image_format = image_format.lower()

        if image_format not in ['jpeg', 'bmp', 'tiff', 'psd', 'raw_bgr24', 'raw_bgr24_non_dib', 'raw_rgb48', 'raw_mono8']:
            Exception('Specified image format %s not supported' % image_format)
        
        if image_format == 'jpeg':
            self.image_format = PxLApi.ImageFormat.JPEG
        elif image_format == 'bmp':
            self.image_format = PxLApi.ImageFormat.BMP
        elif image_format == 'tiff':
            self.image_format = PxLApi.ImageFormat.TIFF
        elif image_format == 'psd':
            self.image_format = PxLApi.ImageFormat.PSD
        elif image_format == 'raw_bgr24':
            self.image_format = PxLApi.ImageFormat.RAW_BGR24
        elif image_format == 'raw_bgr24_non_dib':
            self.image_format = PxLApi.ImageFormat.RAW_BGR24_NON_DIB
        elif image_format == 'raw_rgb48':
            self.image_format = PxLApi.ImageFormat.RAW_RGB48
        elif image_format == 'raw_mono8':
            self.image_format = PxLApi.ImageFormat.RAW_MONO8
    
    def list_cameras(self):

        ret = PxLApi.getNumberCameras()

        if PxLApi.apiSuccess(ret[0]):
            # The list of cameras found is actually a list of PxLApi._CameraIdInfo(s). See the
            # Pixelink API documentation for details on each of the fields in the CAMERA_ID_INFO
            cameras = ret[1]
            print ("Found %d Cameras:" % len(cameras))
            for i in range(len(cameras)):
                print("  Serial number - %d" % cameras[i].CameraSerialNum)
            else:
                print ("getNumberCameras return code: %d" % ret[0])
        
        return len(cameras)
    
    def close(self):

        print('Disconnecting pixelink camera')
        PxLApi.uninitialize(self.camera_handle)

    def determine_raw_image_size(self):
        """
        Query the camera for region of interest (ROI), decimation, and pixel format
        Using this information, we can calculate the size of a raw image
        Returns 0 on failure
        """

        # Get region of interest (ROI)
        ret = PxLApi.getFeature(self.camera_handle, PxLApi.FeatureId.ROI)
        params = ret[2]
        roiWidth = params[PxLApi.RoiParams.WIDTH]
        roiHeight = params[PxLApi.RoiParams.HEIGHT]

        # Query pixel addressing
            # assume no pixel addressing (in case it is not supported)
        pixelAddressingValueX = 1
        pixelAddressingValueY = 1

        ret = PxLApi.getFeature(self.camera_handle, PxLApi.FeatureId.PIXEL_ADDRESSING)
        if PxLApi.apiSuccess(ret[0]):
            params = ret[2]
            if PxLApi.PixelAddressingParams.NUM_PARAMS == len(params):
                # Camera supports symmetric and asymmetric pixel addressing
                pixelAddressingValueX = params[PxLApi.PixelAddressingParams.X_VALUE]
                pixelAddressingValueY = params[PxLApi.PixelAddressingParams.Y_VALUE]
            else:
                # Camera supports only symmetric pixel addressing
                pixelAddressingValueX = params[PxLApi.PixelAddressingParams.VALUE]
                pixelAddressingValueY = params[PxLApi.PixelAddressingParams.VALUE]

        # We can calulate the number of pixels now.
        numPixels = (roiWidth / pixelAddressingValueX) * (roiHeight / pixelAddressingValueY)
        ret = PxLApi.getFeature(self.camera_handle, PxLApi.FeatureId.PIXEL_FORMAT)

        # Knowing pixel format means we can determine how many bytes per pixel.
        params = ret[2]
        pixelFormat = int(params[0])

        # And now the size of the frame
        pixelSize = PxLApi.getBytesPerPixel(pixelFormat)

        return int(numPixels * pixelSize)

    def get_frame(self, filename):
        """
        Get a snapshot from the camera, and save to a file.
        """

        # Determine the size of buffer we'll need to hold an image from the camera
        raw_image_size = self.determine_raw_image_size()

        if 0 == raw_image_size:
            Exception('Could not get a frame from Pixelink')

        # Create a buffer to hold the raw image
        raw_image = create_string_buffer(raw_image_size)

        if 0 != len(raw_image):
            # Capture a raw image. The raw image buffer will contain image data on success. 
            ret = self.get_raw_image(raw_image)
            if PxLApi.apiSuccess(ret[0]):
                frame_descriptor = ret[1]
                
                assert 0 != len(raw_image)
                assert frame_descriptor
                
                # Encode the raw image into something displayable
                ret = PxLApi.formatImage(raw_image, frame_descriptor, self.image_format)
                if SUCCESS == ret[0]:
                    formated_image = ret[1]
                    # Save formated image into a file
                    if self.save_image_to_file(filename, formated_image) == SUCCESS:
                        return SUCCESS
                
        return FAILURE
    
    def save_image_to_file(self, filename, formated_image):
        """
        Save the encoded image buffer to a file
        This overwrites any existing file
        Returns SUCCESS or FAILURE
        """
        
        # Open a file for binary write
        file = open(filename, "wb")
        if None == file:
            Exception('File %s could not be created' % filename)
        numBytesWritten = file.write(formated_image)
        file.close()

        if numBytesWritten == len(formated_image):
            return SUCCESS

        return FAILURE
    
    def get_raw_image(self, image_buffer):

        """
        Capture a raw image from the camera.
        
        NOTE: PxLApi.getNextFrame is a blocking call. 
        i.e. PxLApi.getNextFrame won't return until an image is captured.
        So, if you're using hardware triggering, it won't return until the camera is triggered.
        Returns a return code with success and frame descriptor information or API error

        image_buffer is a buffer to hold the raw image
        """

        MAX_NUM_TRIES = 4

        # Put camera into streaming state so we can capture an image
        ret = PxLApi.setStreamState(self.camera_handle, PxLApi.StreamState.START)
        if not PxLApi.apiSuccess(ret[0]):
            Exception('Could not capture raw image from Pixelink.')
        
        # Get an image
        # NOTE: PxLApi.getNextFrame can return ApiCameraTimeoutError on occasion.
        # How you handle this depends on your situation and how you use your camera. 
        # For this sample app, we'll just retry a few times.
        ret = (PxLApi.ReturnCode.ApiUnknownError,)

        for i in range(MAX_NUM_TRIES):
            ret = PxLApi.getNextFrame(self.camera_handle, image_buffer)
            if PxLApi.apiSuccess(ret[0]):
                break

        # Done capturing, so no longer need the camera streaming images.
        # Note: If ret is used for this call, it will lose frame descriptor information.
        PxLApi.setStreamState(self.camera_handle, PxLApi.StreamState.STOP)

        return ret

    def configure(self, params):
        pass

if __name__ == '__main__':

    camera = Pixelink()
    camera.initialize()
    camera.get_frame('trial.tiff')
    camera.close()