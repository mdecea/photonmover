# Acquires a hologram and a micrograph of the same sample by coordinating cameras, illumination sources
# and motorized stages

from photonmover.Interfaces.Experiment import Experiment

# Interfaces/instruments/experiments necessary for the experiment
# - You use an Interface if any instrument of that category can be used
# - You use a specific instrument if you can only use that specific model
from photonmover.Interfaces.SourceMeter import SourceMeter
from photonmover.Interfaces.DCPowerSource import DCPowerSource
from photonmover.Interfaces.LaserDriver import LaserDriver
from photonmover.Interfaces.Camera import Camera
from photonmover.experiments.control_stage_SMU_NIDAQ import AerotechControl
from photonmover.instruments.DAQ.NI_DAQ import NiDAQ

# For the example
from photonmover.instruments.Source_meters.KeysightB2902A import KeysightB2902A
from photonmover.instruments.Source_meters.Keithley2400 import Keithley2400
from photonmover.instruments.Source_meters.MockSourceMeter import MockSourceMeter
from photonmover.instruments.Cameras.Pixelink import Pixelink
from photonmover.instruments.Cameras.Thorlabs import ThorlabsCamera
from photonmover.instruments.Cameras.ZWO import ZWO
from photonmover.instruments.Cameras.basler import Pylon
from photonmover.instruments.DC_power_supplies.AgilentE3648A import AgilentE3648A
from photonmover.instruments.Stages.Aerotech import AerotechStage
from photonmover.instruments.Stages.KlingerCC1 import KlingerCC1

# General imports
import time
import winsound
import numpy as np
import copy


# NOTES:
# Microscopy field of view in y: ~ 0.300 mm
# Microscopy field of view in x: ~ 0.200 mm

# Holography camera dimenions: x --> 5.325 mm, y --> 6.656 mm

def gen_grid(x_vec, y_vec):
    """
    Generates the list of grid coordinates from the list of points in the x and y directions.
    It generates the path in a zig-zag way:
    ------------------------->
                             |
    <------------------------
    |
    ------------------------->
    """

    xv, yv = np.meshgrid(x_vec, y_vec)

    # NO ZIG ZAG VERSION ----------
    #xv = xv.flatten()
    #yv = yv.flatten()

    # Convert to the right format
    #coord_list = list()

    # for (a, b) in zip(xv, yv):
    #    coord_list.append((a, b))

    # ZIG ZAG VERSION ----------
    r, _ = xv.shape

    coord_list = list()

    for i in range(r):
        xs = xv[i, :]
        ys = yv[i, :]

        if i % 2 == 1:
            xs = np.flip(xs)

        for (a, b) in zip(xs, ys):
            coord_list.append((a, b))

    return coord_list


class MicroStage():
    """
    This class controls the movement of the microscopy stages. It needs to implement the method 'move'
    """

    def __init__(self, x_stage, y_stage):
        self.x_stage = x_stage
        self.y_stage = y_stage

    def move(self, pos, current_pos):

        # Move in x if necessary
        if pos[0] != current_pos[0]:
            print('moving %.2f in x' % (pos[0] - current_pos[0]))
            # input()
            self.x_stage.move(pos[0] - current_pos[0])

        # Move in y if necessary
        if pos[1] != current_pos[1]:
            print('moving %.2f in y' % (pos[1] - current_pos[1]))
            # input()
            self.y_stage.move(pos[1] - current_pos[1])

        # Movement in x is kind of brusque, so wait a bit
        # to let things settle
        time.sleep(2)

        # Return the current position
        return pos


class HoloMicroGraphy(Experiment):

    def __init__(self, instrument_list, visa_lock=None):
        """
        :param instrument_list: list of available instruments. IMPORTANT: WE ASSUME THAT THE INSTRUMENTS
        HAVE BEEN INITIALIZED ALREADY!
        """
        super().__init__(visa_lock)

        # It is always good practice to initialize variables in the init

        # --------------------------------------------------------------------
        # Instruments.
        # -------- Stage -----------
        # We need a daq and a source meter to drive the stage
        self.daq = None
        self.stage_smu = None

        # -------- Micrography -----
        # We need a camera and an illumination source (a source meter to turn
        # on the LED)
        self.micro_smu = None
        self.micro_camera = None
        # We need a motorized stage to be able to acquire multiple microscope
        # images for the same sample
        self.micro_stage = None
        # to cover the same field of view as the hologram

        # -------- Holography ------
        # We need a camera and an illumination source (a source meter to turn
        # on the LED)
        self.holo_smu = None
        self.holo_camera = None

        # --------------------------------------------------------------------

        # Save the last data obtained when the experiment was performed (for
        # plotting purposes)
        self.data = None

        if not self.check_necessary_instruments(instrument_list):
            raise ValueError(
                "The necessary instruments for this experiment are not present!")

    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary to perform the experiment are present.
        The first SMU is the drive smu, the second on eis the measure SMU
        :param instrument_list: list of the available instruments
        :return: True if the necessary instruments are present, False otherwise.
        """

        for instr in instrument_list:
            if isinstance(
                instr,
                SourceMeter) or isinstance(
                instr,
                DCPowerSource) or isinstance(
                instr,
                    LaserDriver):
                if self.stage_smu is None:
                    self.stage_smu = instr
                elif self.micro_smu is None:
                    self.micro_smu = instr
                elif self.holo_smu is None:
                    self.holo_smu = instr

            if isinstance(instr, NiDAQ):
                self.daq = instr

            if isinstance(instr, MicroStage):
                self.micro_stage = instr

            if isinstance(instr, Camera):
                if self.micro_camera is None:
                    self.micro_camera = instr
                elif self.holo_camera is None:
                    self.holo_camera = instr

        if (
            self.stage_smu is not None) and (
            self.daq is not None) and (
            self.micro_smu is not None) and (
                self.holo_smu is not None) and (
                    self.micro_camera is not None) and (
                        self.holo_camera is not None):
            return True
        else:
            return False

    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        return " Acquires a hologram and a micrograph of the same sample "

    def get_name(self):
        """
        Returns a string with the experiment name
        """
        return "Holomicrography"

    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dictionary of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return:
        """

        """
        params keys:
            "holo_to_micro_prams" --> Dictionnary with the settings to transition from the holography to the microscopy setup
                "distance" --> Distance between the golography and microsopy paths in mm. Sign matters! This distance should move from the
                               holography path to the micrography paths
                "distance_to_counts" --> Conversion between distance and counts on the encoder (in counts/mm). Currentl this is 500.
                "drive_current" --> Current at which to drive the motor in Amps. We assume it has the sign that will move the motor in the positive direction.
                    It can either be a single number, in which case we will apply +drive_current and -drive_current, or
                    a two element list, in which case we will apply drive_current[0] and drive_current[1] for each direction respecitvely.
                    Currently, 0.55 seems a reasonable number
                "daq_channel" --> daq channel to which the stage feedback is connected. None if we want to use the default, which is /Dev1/PFI3
            "microscopy_params" --> Dictionnary with the settings for the microscopy step
                "v_bias" --> bias voltage for the illumination LED
                "camera_settings" --> A dictionnary with camera settings for the hologrpahy camera, or None if we want to use the currently set parameters.
                "grid_pos" --> list of tuples with the postions at which to move the stage and take a picture for the microscopy. This is meant to allow to cover
                    the same field of view as the holography image. We consider that the intial position is (0,0).
                    Example: [(0,0), (1,0), (-1, 0)] will take 3 snapshots, one at (0,0) position, then at (1 mm, 0) and then at (-1 mm, 0)
            "holography_params" --> Dictionnary with the settings for the holography step
                "v_bias" --> bias voltage for the illumination LED
                "camera_settings" --> A dcitionnary with camera settings for the hologrpahy camera, or None if we want to use the currently set parameters.
            "init_pos" --> indicates the current position. Either 'holo' (the setup is at the position for holography) or 'micro'
                           (the setup is at the position for microscopy)
            "return" --> If True, it returns the microscope to the original position (init_pos)
            "stop_before_moving" --> If True, it stops after toggling from microscopy to holography or opposite,
                waits for the 'go' from the user
        """

        params = self.check_all_params(params)

        holo_to_micro_params = params["holo_to_micro_params"]
        microscopy_params = params["microscopy_params"]
        holography_params = params["holography_params"]
        init_pos = params["init_pos"]
        ret = params["return"]
        stop_before_moving = params["stop_before_moving"]

        # Set up cameras if necessary
        if holography_params['camera_settings'] is not None:
            self.holo_camera.configure(holography_params['camera_settings'])
        if microscopy_params['camera_settings'] is not None:
            self.micro_camera.configure(microscopy_params['camera_settings'])

        # Set output voltages for illumination sources
        self.micro_smu.turn_off()  # just in case
        self.holo_smu.turn_off()  # just in case
        self.micro_smu.set_voltage(microscopy_params['v_bias'])
        self.holo_smu.set_voltage(holography_params['v_bias'])
        self.micro_smu.turn_off()  # just in case
        self.holo_smu.turn_off()  # just in case

        # Go through the drill
        if init_pos == 'holo':

            # Take the hologram
            print('Starting hologram acquisition')
            self.perform_holo_step(filename)
            print('Hologram acquired')
            print('------------------------------')

            if stop_before_moving:
                input('Press enter to move to microscopy position')

            # Move to the microscopy position
            print('Moving to microscopy position')
            self.toggle_setups(holo_to_micro_params, go_to='micro')
            print('Successfully moved to microscopy position')
            print('------------------------------')

            # Take the microscope image(s)
            print('Starting microscopy acquisition')
            self.perform_micro_step(microscopy_params, filename)
            print('Micrograph(s) acquired')
            print('------------------------------')

            if ret:
                print('Moving back to holography position')
                self.toggle_setups(holo_to_micro_params, go_to='holo')
                print('Successfully moved to holography position')
                print('------------------------------')

        elif init_pos == 'micro':

            # Take the microscope image(s)
            print('Starting microscopy acquisition')
            self.perform_micro_step(microscopy_params, filename)
            print('Micrograph(s) acquired')
            print('------------------------------')

            if stop_before_moving:
                input('Press enter to move to holography position')

            # Move to the microscopy position
            print('Moving to holography position')
            self.toggle_setups(holo_to_micro_params, go_to='holo')
            print('Successfully moved to holography position')
            print('------------------------------')

            # Take the hologram
            print('Starting hologram acquisition')
            self.perform_holo_step(filename)
            print('Hologram acquired')
            print('------------------------------')

            if ret:
                print('Moving back to microscopy position')
                self.toggle_setups(holo_to_micro_params, go_to='micro')
                print('Successfully moved to microscopy position')
                print('------------------------------')

        else:
            print(
                "Specified init pos is not 'holo' nor 'micro'. We don;t know where we are. Doing nothing.")
            return

    def toggle_setups(self, holo_to_micro_params, go_to):
        """
        Toggles between the microscopy and the holography setups.
        :param go_to: string ('holo' or 'micro') indicating if we want to go to the holography or the microscopy path.
        """

        move_stage = AerotechControl([self.stage_smu, self.daq])

        params = copy.deepcopy(holo_to_micro_params)

        if go_to == 'holo':
            # The distance in the holo_to_micro_params is the distance to go from the holography to the microscopy path.
            # If we want to go to the holography path we need to reverse it.
            params['distance'] = -1 * params['distance']

        # move
        move_stage.perform_experiment(params)
        time.sleep(1)

    def perform_holo_step(self, filename):
        """
        Turns on the holography source and acquires an image
        """

        # Turn on illumination source
        self.holo_smu.turn_on()
        # time.sleep(5)

        # Acquire image
        time_tuple = time.localtime()
        holo_filename = '%s--holo--%d#%d#%d--%d#%d#%d.png' % (filename,
                                                              time_tuple[0],
                                                              time_tuple[1],
                                                              time_tuple[2],
                                                              time_tuple[3],
                                                              time_tuple[4],
                                                              time_tuple[5])

        # holo_filename = '%s--holo.bmp' % (filename)
        self.holo_camera.get_frame(holo_filename)

        # Turn off illumination source
        self.holo_smu.turn_off()

    def perform_micro_step(self, params, filename):
        """
        performs the microscopy stage
        """

        # Turn on illumination source
        self.micro_smu.turn_on()
        time.sleep(0.2)

        current_pos = (0, 0)  # Assume we are at (0, 0)

        for pos in params['grid_pos']:

            if (pos != current_pos) and (self.micro_stage is not None):
                current_pos = self.micro_stage.move(
                    pos=pos, current_pos=current_pos)

            # Acquire image
            time_tuple = time.localtime()
            micro_filename = '%s--micro--pos=(%.2f,%.2f)--%d#%d#%d--%d#%d#%d.png' % (filename,
                                                                                     pos[0],
                                                                                     pos[1],
                                                                                     time_tuple[0],
                                                                                     time_tuple[1],
                                                                                     time_tuple[2],
                                                                                     time_tuple[3],
                                                                                     time_tuple[4],
                                                                                     time_tuple[5])
            self.micro_camera.get_frame(micro_filename)

        # Go back to (0,0)
        current_pos = self.micro_stage.move(
            pos=(0, 0), current_pos=current_pos)
        # Take pic to compare with initial pos
        time_tuple = time.localtime()
        micro_filename = '%s--micro--pos=(%.2f,%.2f)--after_scan--%d#%d#%d--%d#%d#%d.png' % (filename,
                                                                                             pos[0],
                                                                                             pos[1],
                                                                                             time_tuple[0],
                                                                                             time_tuple[1],
                                                                                             time_tuple[2],
                                                                                             time_tuple[3],
                                                                                             time_tuple[4],
                                                                                             time_tuple[5])
        self.micro_camera.get_frame(micro_filename)

        # Turn off illumination source
        self.micro_smu.turn_off()

    def required_params(self):
        """
        Returns a list with the keys that need to be specified in the params dictionary, in order for
        a measurement to be performed
        """
        return [
            "holo_to_micro_params",
            "microscopy_params",
            "holography_params"]

    def default_params(self):
        return {
            "holo_to_micro_params": {
                "distance_to_counts": 500,
                "drive_current": 0.55,
                "daq_channel": None},
            "microscopy_params": {
                "v_bias": 5,
                "camera_settings": None,
                "grid_pos": [
                    (0,
                     0)]},
            "holography_params": {
                "v_bias": 3.55,
                "camera_settings": None},
            "return": True,
            "stop_before_moving": True}

    def plot_data(self, canvas_handle, data=None):
        # Nothing to plot
        return


if __name__ == '__main__':

    # Create and connect to all the necessary instruments.

    # -------- Stages -----------
    # We need a daq and a source meter to drive the stage
    daq = NiDAQ()
    # stage_smu = KeysightB2902A(channel=1, current_compliance=1)
    stage_smu = Keithley2400(current_compliance=1, voltage_compliance=10)
    stage_smu.initialize()

    # -------- Micrography -----
    # We need a camera and an illumination source (a source meter to turn on
    # the LED)
    micro_smu = AgilentE3648A()
    micro_camera = ThorlabsCamera()

    # Klinger stage
    y_micro_stage = KlingerCC1()
    # Aerotech stage for the microscopy part
    x_micro_stage = AerotechStage(
        stage_smu,
        daq,
        dist_to_counts=500,
        drive_current=0.55,
        daq_channel=None)
    y_micro_stage.initialize()
    x_micro_stage.initialize()

    # x_micro_stage.move(-70.0)
    # input()

    micro_stage = MicroStage(x_stage=x_micro_stage, y_stage=y_micro_stage)

    # -------- Holography ------
    # We need a camera and an illumination source (a source meter to turn on the LED)
    # holo_smu = KeysightB2902A(channel=2, current_compliance=1, gpib=stage_smu.gpib)
    holo_smu = MockSourceMeter()
    holo_camera = ZWO(camera_id=0)

    # Initialize all instruments

    stage_smu.initialize()
    daq.initialize()
    micro_smu.initialize()
    micro_camera.initialize()
    holo_smu.initialize()
    holo_camera.initialize()

    # Some settings

    stage_smu.set_voltage_compliance(10)

    holo_camera.set_control_value(instruments.Cameras.ZWO.ASI_GAIN, 0)
    holo_camera.set_control_value(instruments.Cameras.ZWO.ASI_EXPOSURE, 50000)
    holo_camera.set_image_type(instruments.Cameras.ZWO.ASI_IMG_RAW8)

    #############

    instr_list = [
        daq,
        stage_smu,
        micro_smu,
        micro_camera,
        holo_smu,
        holo_camera]
    if micro_stage is not None:
        instr_list.append(micro_stage)

    exp = HoloMicroGraphy(instr_list)

    # NOTES:
    # Microscopy field of view in y: ~ 0.400 mm
    # Microscopy field of view in x: ~ 0.400 mm
    # Holography camera dimensions: x --> 5.325 mm, y --> 6.656 mm

    # Most general
    x_pos = np.arange(-2.66, 2.66, 0.35)
    y_pos = np.arange(-3, 3, 0.35)

    #x_pos = np.arange(-2.66, 2.66, 0.18)
    #y_pos = np.array([-0.56, -0.28, 0, 0.28, 0.56])

    #x_pos = np.append(np.arange(-0.5, 0.5, 0.1), 0.5)
    #y_pos = np.append(np.arange(-1, 1, 0.2), 1)

    #x_pos = np.linspace(-2.66, 2.66, 5)
    #y_pos = np.linspace(-3, 3, 5)
    grid_pos = gen_grid(x_pos, y_pos)
    # print(grid_pos)
    # input()

    params = {
        "holo_to_micro_params": {
            "distance": -82.0,
            "distance_to_counts": 500,
            "drive_current": 0.55,
            "daq_channel": None},
        "microscopy_params": {
            "v_bias": 3,
            "camera_settings": None,
            "grid_pos": grid_pos},
        "holography_params": {
            "v_bias": 3.55,
            "camera_settings": None},
        "init_pos": 'micro',
        "return": True,
        "stop_before_moving": False}

    # RUN IT
    exp.perform_experiment(
        params, filename='./data/holomicro/dog_skeletal_muscle/dog_skel_mus')

    # CLOSE INSTRUMENTS
    daq.close()
    stage_smu.close()
    micro_smu.close()
    micro_camera.close()
    x_micro_stage.close()
    y_micro_stage.close()
    holo_smu.close()
    holo_camera.close()
