# There is a package provided by basler that provides a python
# package to talk to the camera
# See https://github.com/basler/pypylon
# We can just directly use that package to talk to the pixelink.
# 
# To install the package: pip install pypylon
from pypylon import pylon

from photonmover.Interfaces.Camera import Camera
from photonmover.Interfaces.Instrument import Instrument

class Pylon(Instrument, Camera):

    def __init__(self, image_format='TIFF'):

        super().__init__()
        self.image_format = image_format

        self.set_image_format(self.image_format)

    def initialize(self):

        # Create an instant camera object with the camera device found first.
        self.camera = pylon.InstantCamera(pylon.TlFactory.GetInstance().CreateFirstDevice())
        self.camera.Open()

        # Print the model name of the camera.
        print("Using basler camera: ", self.camera.GetDeviceInfo().GetModelName())

    def set_image_format(self, image_format):
        """
        Sets the image format when images are saved.
        One of 'jpeg', 'bmp', 'tiff', 'psd', 'raw_bgr24', 'raw_bgr24_non_dib', 'raw_rgb48', 'raw_mono8'
        """

        image_format = image_format.lower()

        if image_format not in ['jpeg', 'bmp', 'tiff', 'png', 'raw']:
            Exception('Specified image format %s not supported' % image_format)
        
        if image_format == 'jpeg':
            self.image_format = pylon.ImageFileFormat_Jpeg
        elif image_format == 'bmp':
            self.image_format = pylon.ImageFileFormat_Bmp
        elif image_format == 'tiff':
            self.image_format = pylon.ImageFileFormat_Tiff
        elif image_format == 'png':
            self.image_format = pylon.ImageFileFormat_Png 
        elif image_format == 'raw':
            self.image_format = pylon.ImageFileFormat_Raw

    def close(self):

        print('Disconnecting basler camera')
        self.camera.StopGrabbing()
        self.camera.Close()

    def get_frame(self, filename):

        self.camera.StartGrabbing()
        img = pylon.PylonImage()

        with self.camera.RetrieveResult(2000) as result:

            # Calling AttachGrabResultBuffer creates another reference to the
            # grab result buffer. This prevents the buffer's reuse for grabbing.
            img.AttachGrabResultBuffer(result)


            ## The JPEG format that is used here supports adjusting the image
            ## quality (100 -> best quality, 0 -> poor quality).
            #ipo = pylon.ImagePersistenceOptions()
            #quality = 90 - i * 10
            #ipo.SetQuality(quality)
            #filename = "saved_pypylon_img_%d.jpeg" % quality
            #img.Save(self.image_format, filename, ipo)

            img.Save(self.image_format, filename)
            # In order to make it possible to reuse the grab result for grabbing
            # again, we have to release the image (effectively emptying the
            # image object).
            img.Release()

        self.camera.StopGrabbing()

    def configure(self, params):
        pass

    def set_exposure(self, exposure):
        # exposure is in us
        self.camera.ExposureTime = exposure

    def set_gain(self, gain):
        self.camera.Gain = gain

if __name__ == '__main__':

    camera = Pylon()
    camera.initialize()
    camera.get_frame('trial.tiff')
    camera.close()