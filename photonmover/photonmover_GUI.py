from PyQt5 import QtWidgets, QtGui, QtCore
from PyQt5.QtWidgets import QMainWindow, QApplication, QWidget, QAction, QGridLayout, QGroupBox
from PyQt5.QtCore import QThread, QMutex
import pyqtgraph as pg
import importlib
import sys
import numpy as np
from photonmover.utils.class_parser import ClassParser
from photonmover.utils.calibrator import analyze_powers
from photonmover.Interfaces.Experiment import Experiment
from photonmover.InstrumentWorker import InstrumentWorker
import time

from functools import partial

# Folder where all the experiment classes are stored
EXPERIMENTS_FOLDER = './experiments/'

# in ms. Sets the time interval for refrsehing the GUI indicators.
REFRESHING_INTERVAL = 500
# The SMU will be interrogated every SMU_MEAS_INTERVAL executions of the
# refresh loop,
SMU_MEAS_INTERVAL = 10
# so the smu value will be refrsehed every
# SMU_MEAS_INTERVAL*REFRESHING_INTERVAL ms

# Constants affecting the plotting of coupling vs time
PLOT_PERSISTENCE = 100  # Total number of points to be shown in the trace


class photonmover_GUI(QMainWindow):

    def __init__(self, instr_list, setup_params_list=None):

        super(photonmover_GUI, self).__init__()

        self.instr_list = instr_list

        self.parse_params_list(setup_params_list)

        # plotting stuff
        self.plot_tx = True  # When true we plot tx vs time.
        self.tx_vs_time = []

        self.visa_lock = QMutex()  # Since all the extra threads deal with gpib commands,
        # have a lock that will prevent multiple
        # commands being sent at the same time

        # THREAD 1 - FOR EXECUTING EXPERIMENTS
        self.exp_thread = QThread()

        self.initialize_gui()

        # THREAD 2 - FOR SETTING INSTRUMENTS

        # Create an InstrumentWorker that will deal with all the functions in
        # which a GUI operation directly sets an instrument setting. For example,
        # turning the laser on and off, setting SMU voltage/current, TEC
        # temperature...
        self.instr_worker = InstrumentWorker(instr_list, self.visa_lock, None)
        # Have a thread exclusively for the instrument worker
        self.instr_worker_thread = QThread()
        self.instr_worker.moveToThread(self.instr_worker_thread)

        self.instr_worker.done.connect(self.instr_worker_thread.quit)
        self.instr_worker.done.connect(
            self.__disconnect_instr_thread_start_events__)

        # THREAD 3 - FOR GETTING STATS
        self.stats_worker = InstrumentWorker(instr_list, self.visa_lock, None)
        self.stats_worker_thread = QThread()
        self.stats_worker.moveToThread(self.stats_worker_thread)

        # Update the stats when we have the info
        self.stats_worker.stats_vals.connect(self.refresh_GUI_stats)
        self.stats_worker.done.connect(self.stats_worker_thread.quit)

        # Start timer for refreshing the stats in the GUI
        self.num_loop_exec = 0
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.refresh_stats)
        self.timer.start(REFRESHING_INTERVAL)  # in msec

    def parse_params_list(self, setup_params_list):
        """
        Parses the setup param list given in the instrument list yaml to see
        if there is relevant information describing the setup

        :param setup_params_list:
        :return:
        """

        # Default values

        # By default we assume we operate the SMU as a source voltage - measure
        # current
        self.smu_mode = 'meas_cur'

        # Assumes that there is no splitter after the output fiber (sometimes, we want a splitter after the output fiber
        # so we can direct the output to two different instruments. This is relevant for calculation of the
        # input power from the received power
        self.rec_splitter_ratio = 1

        # Check if some parameter is not the default
        if setup_params_list is not None:
            if 'smu_mode' in setup_params_list:
                self.smu_mode = setup_params_list["smu_mode"]
            if 'rec_splitter_ratio' in setup_params_list:
                self.rec_splitter_ratio = setup_params_list["rec_splitter_ratio"]

    def initialize_gui(self):

        self.setGeometry(100, 100, 1200, 600)
        self.setWindowTitle("Photonmover v3.0")

        # Define a top-level window and a central widget to hold everything
        self.center_widget = QWidget(self)
        self.setCentralWidget(self.center_widget)

        # Plot-related objects
        self.pen = pg.mkPen(width=5)
        self.label_styles = {'color': 'white', 'font-size': '20px'}

        self.setWindowIcon(QtGui.QIcon('./photonmover_logo.jpg'))

        # Create menu bar
        self._create_menu_bar_()

        # Create all the status indicators
        self._create_indicators_()

        # Create a status bar at the bottom
        self.statusBar()

    def _create_menu_bar_(self):

        # Creates the menu bar, which holds the basic actions AND the
        # experiments
        self.main_menu = self.menuBar()

        self.file_menu = self.main_menu.addMenu('&File')
        self.experiment_menu = self.main_menu.addMenu('&Experiments')

        self.create_and_add_action(
            "&Quit Application",
            self.file_menu,
            self.close_application,
            "Ctrl+Q",
            "Leave The App")

        self.create_and_add_action("&About", self.file_menu, self.show_about)

        self._create_experiments_menu_()

    def create_and_add_action(
            self,
            label,
            menu,
            callback,
            shortcut=None,
            status_tip=None):
        """
        This function creates an action item in the menu specified.
        :param label: Label that will appear in the menu.
        :param menu: Menu to which we want to add this item
        :param callback: function to call when the item is clicked
        :param shortcut: optional shortcut (string) for the action
        :param status_tip: optional desceription (string) that will appear when hovering over the action
        """

        action = QAction(label, self)
        if shortcut is not None:
            action.setShortcut(shortcut)
        if status_tip is not None:
            action.setStatusTip(status_tip)

        action.triggered.connect(callback)
        menu.addAction(action)

    def _create_experiments_menu_(self):
        """
        Populates the experiments menu based on the connected instruments.
        """

        # First we need to parse the experiment files
        parser = ClassParser()
        mod_list, experiment_class_list = parser.class_list(
            EXPERIMENTS_FOLDER, recursive=True)

        self.experiment_list = list()

        for i, class_name in enumerate(experiment_class_list):
            # Import the module
            instr_module = importlib.import_module(mod_list[i])
            cl = getattr(instr_module, class_name)
            # Import the class
            #cl = globals()[class_name]

            # Make sure this is an experiment
            if issubclass(cl, Experiment):
                try:
                    # If it is, check if the experiment can happen with the
                    # instruments available
                    experiment_object = cl(self.instr_list, self.visa_lock)

                    self.experiment_list.append(experiment_object)

                    # Move the experiment object to the experiment thread,
                    # which is where it will be executed.
                    experiment_object.moveToThread(self.exp_thread)
                    experiment_object.finished.connect(self.exp_thread.quit)
                    experiment_object.finished.connect(
                        self.__disconnect_exp_thread_start_events__)
                    experiment_object.experiment_results_plt.connect(
                        self.process_experiment_results)

                    # This is the function that needs to be executed when the menu item is clicked.
                    # Need to be done this way for some weird issue
                    # (see https://stackoverflow.com/questions/1464548/pyqt-qmenu-dynamically-populated-and-clicked)
                    def receiver(
                        bVal, exp_obj=experiment_object): return self.call_experiment(exp_obj)

                    # Add the menu entry
                    self.create_and_add_action(
                        experiment_object.get_name(),
                        self.experiment_menu,
                        receiver,
                        shortcut=None,
                        status_tip=experiment_object.get_description())

                except ValueError:
                    # It means that the experiment can't be done with the
                    # available instruments
                    print(
                        " The experiment %s can't be done with the instruments available. " %
                        class_name)

    def _create_indicators_(self):
        """
        Creates the different indicators in the GUI.
        The shown indicators depend on the parameters needed by the experiments that can be carried out.

        As the indicators are constructed, we are also generating a dictionnary that indicates which experiment
        variable does that specific indicator set. This will be used later to construct the param dictionnary for the experiments
        """

        # Initialize the dictionary mapping indicator and parameters
        self.indicator_param_map = {}

        # First, get the list of necessary parameters
        self.param_list = self._get_all_params_list_()

        """
        The parameters are agreed between the GUI and the experiments:
        -"voltages", -"wavs", -"use_DAQ", -"temperatures", -"calibrate"
        -"meas_current", -"powers", -"num_averages", -"currents", -"power_range", - "voltages2",

        "amplitudes", "freqs",
        "f1", "f2", "amp_comp",
        """

        self.layout = QGridLayout()
        self.center_widget.setLayout(self.layout)

        row = 0

        self.settings_group_box = QGroupBox("General settings")
        layout = QGridLayout()
        self.settings_group_box.setLayout(layout)

        layout.addWidget(QtWidgets.QLabel(
            'Tunable filter follows laser? '), 0, 0)
        self.tf_with_laser = QtWidgets.QCheckBox(self)
        self.tf_with_laser.setChecked(True)
        layout.addWidget(self.tf_with_laser, 0, 1)

        if "meas_current" in self.param_list:
            layout.addWidget(QtWidgets.QLabel(
                'Measure current in sweeps?'), 0, 2)
            self.meas_current = QtWidgets.QCheckBox(self)
            self.meas_current.setChecked(False)
            layout.addWidget(self.meas_current, 0, 3)
            self.indicator_param_map["meas_current"] = (
                [self.meas_current], 'checkbox')

        if "use_DAQ" in self.param_list:
            layout.addWidget(QtWidgets.QLabel('Use DAQ? '), 1, 0)
            self.use_daq = QtWidgets.QCheckBox(self)
            self.use_daq.setChecked(False)
            layout.addWidget(self.use_daq, 1, 1)
            self.indicator_param_map["use_DAQ"] = ([self.use_daq], 'checkbox')

        if "calibrate" in self.param_list:
            layout.addWidget(QtWidgets.QLabel('Use calibration? '), 1, 2)
            self.use_cal = QtWidgets.QCheckBox(self)
            self.use_cal.setChecked(True)
            layout.addWidget(self.use_cal, 1, 3)
            self.indicator_param_map["calibrate"] = (
                [self.use_cal], 'checkbox')

        # row, column, row span, column span
        self.layout.addWidget(self.settings_group_box, row, 0, 2, 3)

        row = row + 2

        if "wavs" in self.param_list:

            self.laser_group_box = QGroupBox("Laser On/Off controls")
            layout = QtWidgets.QHBoxLayout()
            self.laser_group_box.setLayout(layout)

            self.laser_power_button = QtWidgets.QPushButton(
                "Toggle Laser State", self)
            self.laser_power_button.clicked.connect(self.laser_on)
            layout.addWidget(self.laser_power_button)

            self.laser_state = QtWidgets.QLabel("")
            self.laser_state.setStyleSheet(
                "background-color : red; border: 1px solid black")
            layout.addWidget(self.laser_state)

            self.layout.addWidget(self.laser_group_box, row, 0, 1, 2)

            row = row + 1

            self.tx_group_box = QGroupBox("Coupling and Tx")
            layout = QGridLayout()
            self.tx_group_box.setLayout(layout)

            layout.addWidget(QtWidgets.QLabel('Set Wavelength (nm): '), 1, 0)
            self.set_wl = QtWidgets.QLineEdit('1550.00')
            self.set_wl.returnPressed.connect(self.set_laser_wav)
            layout.addWidget(self.set_wl, 1, 1)

            layout.addWidget(QtWidgets.QLabel(
                'Measured Wavelength (nm): '), 1, 2)
            self.meas_wl = QtWidgets.QLineEdit('1550.00')
            self.meas_wl.setReadOnly(1)
            layout.addWidget(self.meas_wl, 1, 3)

            layout.addWidget(QtWidgets.QLabel('Set Power (mW or mA): '), 2, 0)
            self.set_power = QtWidgets.QLineEdit('1.00')
            self.set_power.returnPressed.connect(self.set_laser_power)
            layout.addWidget(self.set_power, 2, 1)

            layout.addWidget(QtWidgets.QLabel(
                'Measured input power (W): '), 2, 2)
            self.meas_in_power = QtWidgets.QLineEdit('1.00')
            self.meas_in_power.setReadOnly(1)
            layout.addWidget(self.meas_in_power, 2, 3)

            layout.addWidget(QtWidgets.QLabel('Tap Power (W): '), 3, 0)
            self.tap_power = QtWidgets.QLineEdit('1.00')
            self.tap_power.setReadOnly(1)
            layout.addWidget(self.tap_power, 3, 1)

            layout.addWidget(QtWidgets.QLabel('Received power (W): '), 3, 2)
            self.rec_power = QtWidgets.QLineEdit('1.00')
            self.rec_power.setReadOnly(1)
            layout.addWidget(self.rec_power, 3, 3)

            layout.addWidget(QtWidgets.QLabel('In-out loss (dB): '), 4, 0)
            self.in_out_loss = QtWidgets.QLineEdit('-10.00')
            self.in_out_loss.setReadOnly(1)
            layout.addWidget(self.in_out_loss, 4, 1)

            layout.addWidget(QtWidgets.QLabel(
                'Power meter range (dBm): '), 4, 2)
            self.pm_range = QtWidgets.QLineEdit('AUTO')
            self.pm_range.returnPressed.connect(self.set_pm_range)
            layout.addWidget(self.pm_range, 4, 3)
            self.indicator_param_map["power_range"] = [
                [self.pm_range], 'textbox']

            layout.addWidget(QtWidgets.QLabel(
                'Set tunable filter Wavelength (nm): '), 5, 0)
            self.set_tf_wl = QtWidgets.QLineEdit('1550.00')
            self.set_tf_wl.returnPressed.connect(self.set_tf_wav)
            layout.addWidget(self.set_tf_wl, 5, 1)

            self.layout.addWidget(self.tx_group_box, row, 0, 4, 3)

            row = row + 4

        if "voltages" in self.param_list:

            self.smu_group_box = QtWidgets.QGroupBox("Source Meter 1 State")
            layout = QtWidgets.QHBoxLayout()
            self.smu_group_box.setLayout(layout)

            layout.addWidget(QtWidgets.QLabel('SM Channel: '))
            self.sm_channel = QtWidgets.QLineEdit('1')
            self.sm_channel.returnPressed.connect(self.set_smu_channel)
            layout.addWidget(self.sm_channel)

            layout.addWidget(QtWidgets.QLabel('SM Voltage (V): '))
            self.sm_volt = QtWidgets.QLineEdit('0.0')
            self.sm_volt.returnPressed.connect(self.set_smu_volt)
            layout.addWidget(self.sm_volt)

            layout.addWidget(QtWidgets.QLabel('SM Current (A): '))
            self.sm_current = QtWidgets.QLineEdit('0.0')
            self.sm_current.returnPressed.connect(self.set_smu_cur)
            layout.addWidget(self.sm_current)

            self.layout.addWidget(self.smu_group_box, row, 0, 1, 4)

            row = row + 1

        if "voltages2" in self.param_list:

            self.smu2_group_box = QtWidgets.QGroupBox("Source Meter 2 State")
            layout = QtWidgets.QHBoxLayout()
            self.smu2_group_box.setLayout(layout)

            layout.addWidget(QtWidgets.QLabel('SM Channel: '))
            self.sm2_channel = QtWidgets.QLineEdit('1')
            self.sm2_channel.returnPressed.connect(self.set_smu2_channel)
            layout.addWidget(self.sm2_channel)

            layout.addWidget(QtWidgets.QLabel('SM Voltage (V): '))
            self.sm2_volt = QtWidgets.QLineEdit('0.0')
            self.sm2_volt.returnPressed.connect(self.set_smu2_volt)
            layout.addWidget(self.sm2_volt)

            layout.addWidget(QtWidgets.QLabel('SM Current (A): '))
            self.sm2_current = QtWidgets.QLineEdit('0.0')
            self.sm2_current.returnPressed.connect(self.set_smu2_cur)
            layout.addWidget(self.sm2_current)

            self.layout.addWidget(self.smu2_group_box, row, 0, 1, 4)

            row = row + 1

        if "wavs" in self.param_list:

            self.wav_group_box = QtWidgets.QGroupBox("Wav sweep settings")
            layout = QtWidgets.QHBoxLayout()
            self.wav_group_box.setLayout(layout)

            layout.addWidget(QtWidgets.QLabel('Start wav (nm): '))
            self.init_wav = QtWidgets.QLineEdit('1540.00')
            layout.addWidget(self.init_wav)

            layout.addWidget(QtWidgets.QLabel('End wav (nm): '))
            self.end_wav = QtWidgets.QLineEdit('1560.00')
            layout.addWidget(self.end_wav)

            layout.addWidget(QtWidgets.QLabel('Num wavs: '))
            self.num_wav = QtWidgets.QLineEdit('15')
            layout.addWidget(self.num_wav)

            # In the case of a sweep setting, we pass the 3 values (start, end
            # and num) as a list
            self.indicator_param_map["wavs"] = (
                [self.init_wav, self.end_wav, self.num_wav], 'textbox')

            # row, column, row span, column span
            self.layout.addWidget(self.wav_group_box, row, 0, 1, 4)

            row = row + 1

        if "voltages" in self.param_list:

            self.volt_group_box = QtWidgets.QGroupBox("V sweep settings")
            layout = QtWidgets.QHBoxLayout()
            self.volt_group_box.setLayout(layout)

            layout.addWidget(QtWidgets.QLabel('Start bias (V): '))
            self.init_v = QtWidgets.QLineEdit('0.0')
            layout.addWidget(self.init_v)

            layout.addWidget(QtWidgets.QLabel('End bias (V): '))
            self.end_v = QtWidgets.QLineEdit('2.0')
            layout.addWidget(self.end_v)

            layout.addWidget(QtWidgets.QLabel('Num bias: '))
            self.num_v = QtWidgets.QLineEdit('15')
            layout.addWidget(self.num_v)

            self.v_sweep_type = QtWidgets.QComboBox()
            self.v_sweep_type.addItems(['linear', 'log', 'list'])
            layout.addWidget(self.v_sweep_type)

            self.indicator_param_map["voltages"] = (
                [self.init_v, self.end_v, self.num_v, self.v_sweep_type], 'textbox')

            # row, column, row span, column span
            self.layout.addWidget(self.volt_group_box, row, 0, 1, 4)

            row = row + 1

        if "voltages2" in self.param_list:

            self.volt2_group_box = QtWidgets.QGroupBox("V2 sweep settings")
            layout = QtWidgets.QHBoxLayout()
            self.volt2_group_box.setLayout(layout)

            layout.addWidget(QtWidgets.QLabel('Start bias (V): '))
            self.init_v2 = QtWidgets.QLineEdit('0.0')
            layout.addWidget(self.init_v2)

            layout.addWidget(QtWidgets.QLabel('End bias (V): '))
            self.end_v2 = QtWidgets.QLineEdit('2.0')
            layout.addWidget(self.end_v2)

            layout.addWidget(QtWidgets.QLabel('Num bias: '))
            self.num_v2 = QtWidgets.QLineEdit('15')
            layout.addWidget(self.num_v2)

            self.v2_sweep_type = QtWidgets.QComboBox()
            self.v2_sweep_type.addItems(['linear', 'log', 'list'])
            layout.addWidget(self.v2_sweep_type)

            self.indicator_param_map["voltages2"] = (
                [self.init_v2, self.end_v2, self.num_v2, self.v2_sweep_type], 'textbox')

            # row, column, row span, column span
            self.layout.addWidget(self.volt2_group_box, row, 0, 1, 4)

            row = row + 1

        if "powers" in self.param_list:

            self.power_group_box = QtWidgets.QGroupBox("P sweep settings")
            layout = QtWidgets.QHBoxLayout()
            self.power_group_box.setLayout(layout)

            layout.addWidget(QtWidgets.QLabel('Start power (mW): '))
            self.init_p = QtWidgets.QLineEdit('0.0')
            layout.addWidget(self.init_p)

            layout.addWidget(QtWidgets.QLabel('End power (mW): '))
            self.end_p = QtWidgets.QLineEdit('2.0')
            layout.addWidget(self.end_p)

            layout.addWidget(QtWidgets.QLabel('Num power: '))
            self.num_p = QtWidgets.QLineEdit('15')
            layout.addWidget(self.num_p)

            self.power_sweep_type = QtWidgets.QComboBox()
            self.power_sweep_type.addItems(['linear', 'log', 'list'])
            layout.addWidget(self.power_sweep_type)

            self.indicator_param_map["powers"] = (
                [self.init_p, self.end_p, self.num_p, self.power_sweep_type], 'textbox')

            # row, column, row span, column span
            self.layout.addWidget(self.power_group_box, row, 0, 1, 4)

            row = row + 1

        if "temperatures" in self.param_list:

            self.T_group_box = QtWidgets.QGroupBox("T sweep settings")
            layout = QtWidgets.QHBoxLayout()
            self.T_group_box.setLayout(layout)

            layout.addWidget(QtWidgets.QLabel('Start T (deg C): '))
            self.init_T = QtWidgets.QLineEdit('0.0')
            layout.addWidget(self.init_T)

            layout.addWidget(QtWidgets.QLabel('End T (deg C): '))
            self.end_T = QtWidgets.QLineEdit('2.0')
            layout.addWidget(self.end_T)

            layout.addWidget(QtWidgets.QLabel('Num T: '))
            self.num_T = QtWidgets.QLineEdit('15')
            layout.addWidget(self.num_T)

            self.indicator_param_map["temperatures"] = (
                [self.init_T, self.end_T, self.num_T], 'textbox')

            self.layout.addWidget(self.T_group_box, row, 0, 1, 4)

            row = row + 1

        if "currents" in self.param_list:

            self.I_group_box = QtWidgets.QGroupBox("I sweep settings")
            layout = QtWidgets.QHBoxLayout()
            self.I_group_box.setLayout(layout)

            layout.addWidget(QtWidgets.QLabel('Start I (A): '))
            self.init_cur = QtWidgets.QLineEdit('1e-9')
            layout.addWidget(self.init_cur)

            layout.addWidget(QtWidgets.QLabel('End I (A): '))
            self.end_cur = QtWidgets.QLineEdit('1e-3')
            layout.addWidget(self.end_cur)

            layout.addWidget(QtWidgets.QLabel('Num I: '))
            self.num_cur = QtWidgets.QLineEdit('120')
            layout.addWidget(self.num_cur)

            self.cur_sweep_type = QtWidgets.QComboBox()
            self.cur_sweep_type.addItems(['linear', 'log', 'list'])
            layout.addWidget(self.cur_sweep_type)

            self.indicator_param_map["currents"] = (
                [self.init_cur, self.end_cur, self.num_cur, self.cur_sweep_type], 'textbox')

            self.layout.addWidget(self.I_group_box, row, 0, 1, 4)

            row = row + 1

        # "Others" group box
        self.others_group_box = QtWidgets.QGroupBox("Other params")
        layout = QGridLayout()
        self.others_group_box.setLayout(layout)

        layout.addWidget(QtWidgets.QLabel(
            'Electrical attenuation (dB): '), 0, 0)
        self.el_att = QtWidgets.QLineEdit('0.00')
        self.el_att.returnPressed.connect(self.set_el_att)
        layout.addWidget(self.el_att, 0, 1)

        others_row_span = 1

        if "num_averages" in self.param_list:
            layout.addWidget(QtWidgets.QLabel(
                'Num averages (VNA acq): '), 0, 2)
            self.num_avgs = QtWidgets.QLineEdit('4')
            layout.addWidget(self.num_avgs, 0, 3)

            self.indicator_param_map["num_averages"] = (
                [self.num_avgs], 'textbox')

        if "temperatures" in self.param_list:
            self.layout.addWidget(QtWidgets.QLabel('TEC T (deg C): '), 1, 0)
            self.tec_T = QtWidgets.QLineEdit('25.0')
            self.tec_T.returnPressed.connect(self.set_tec_T)
            layout.addWidget(self.tec_T, 1, 1)
            others_row_span = others_row_span + 1

        self.layout.addWidget(
            self.others_group_box,
            row,
            0,
            others_row_span,
            4)
        row = row + others_row_span

        # Plotting indicators
        self.plot_button = QtWidgets.QPushButton(
            "Plot last experiment data", self)
        self.plot_button.setEnabled(False)
        self.plot_button.clicked.connect(self.toggle_plot)
        self.layout.addWidget(self.plot_button, 0, 9, 1, 3)

        self.plot_area = pg.PlotWidget()
        self.plot_area.showGrid(x=True, y=True)
        # Save a reference to the line because we will update it
        self.plot_line = self.plot_area.plot([0], [0], pen=self.pen)
        # every time when needed
        self.title = self.plot_area.setTitle('Coupling vs Time', size='20pt')
        # init wor, inti col, row span, col span
        self.layout.addWidget(self.plot_area, 1, 7, row, 7)
        self.xlabel = self.plot_area.setLabel(
            'bottom', text='Time', **self.label_styles)
        self.ylabel = self.plot_area.setLabel(
            'left', text='Transmission [dB]', **self.label_styles)
        font = QtGui.QFont()
        font.setPixelSize(20)
        self.plot_area.getAxis("bottom").setStyle(tickFont=font)
        self.plot_area.getAxis("left").setStyle(tickFont=font)

    def _get_all_params_list_(self):
        """
        Goes through the list of available experiments, asks for the necessary parameters and returns a list with the
        collection of all the parameters needed by the ensemble of experiments that can be evaluated
        """

        params_list = []

        for exp in self.experiment_list:

            req_params = exp.required_params()
            if req_params is not None:
                for p in req_params:
                    if p not in params_list:
                        params_list.append(p)

        return params_list

    def close_application(self):
        # Close connection to all instruments
        self.timer.stop()

        self.visa_lock.lock()
        for instr in self.instr_list:
            instr.close()

        self.visa_lock.unlock()
        sys.exit()

    def show_about(self):
        dlg = QtWidgets.QDialog(self)
        layout = QtWidgets.QVBoxLayout()
        dlg.setWindowTitle("About")
        layout.addWidget(QtWidgets.QLabel(
            """ This is the new version of photonmover. Written in python 3 and using
        PyQtgraph, uses the experiment-based approach. \n Mainly written by Marc de Cea, Fall 2020 (amidst a
        global pandemic). """))
        dlg.setLayout(layout)
        dlg.exec_()

    def __disconnect_instr_thread_start_events__(self):
        """
        Disconnects any signal tied to the start of the instrument thread.
        We need this so we can tie different methods to the start of the thread (depending on the
        operation we want to make)
        """
        try:
            self.instr_worker_thread.started.disconnect()
        except BaseException:
            pass

    def __disconnect_exp_thread_start_events__(self):
        """
        Disconnects any signal tied to the start of the experiment thread.
        We need this so we can tie different methods to the start of the thread (depending on the
        experiment we want to run)
        """
        try:
            self.exp_thread.started.disconnect()
        except BaseException:
            pass

    def laser_on(self):

        try:

            state_color = self.laser_state.palette().button().color().name()

            if state_color == "#008000":
                # Green, laser on --> Needs to turn off.
                op = "turn_off"
                self.laser_state.setStyleSheet(
                    "background-color : red; border: 1px solid black")

            else:
                op = "turn_on"
                self.laser_state.setStyleSheet(
                    "background-color : green; border: 1px solid black")

            # Turn laser on and off in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.laser_on, op))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            print('Could not toggle the laser state')

    def set_laser_wav(self):

        try:
            set_wav = float(self.set_wl.text())

            # Set the wavelength in another Thread
            self.instr_worker_thread.started.connect(
                partial(
                    self.instr_worker.set_laser_wav,
                    set_wav,
                    self.tf_with_laser.isChecked()))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker

            if self.tf_with_laser.isChecked():
                self.set_tf_wl.setText(str(set_wav))

        except BaseException:
            pass

    def set_tf_wav(self):

        try:
            set_wav = float(self.set_tf_wl.text())

            # Set the wavelength in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_tunable_filter_wav, set_wav))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def set_laser_power(self):

        try:
            set_power = float(self.set_power.text())

            # Set the power in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_laser_power, set_power))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def set_pm_range(self):

        try:
            set_range = self.pm_range.text()
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_pm_range, set_range))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def set_tec_T(self):

        try:
            set_T = float(self.tec_T.text())

            # Set the temperature in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_tec_T, set_T))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def set_smu_volt(self):

        try:
            set_volt = float(self.sm_volt.text())

            self.smu_mode = 'meas_cur'

            # Set the voltage in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_smu_volt, set_volt, 1))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def set_smu_cur(self):

        try:
            set_cur = float(self.sm_current.text())

            self.smu_mode = 'meas_volt'

            # Set the current in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_smu_cur, set_cur, 1))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def set_smu_channel(self):

        try:
            set_chan = int(self.sm_channel.text())

            # Set the channel in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_smu_channel, set_chan, 1))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def set_smu2_volt(self):

        try:
            set_volt = float(self.sm_volt.text())

            # Set the voltage in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_smu_volt, set_volt, 2))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def set_smu2_cur(self):

        try:
            set_cur = float(self.sm_current.text())

            # Set the current in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_smu_cur, set_cur, 2))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def set_smu2_channel(self):

        try:
            set_chan = int(self.sm_channel.text())

            # Set the channel in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_smu_channel, set_chan, 2))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def set_el_att(self):

        try:
            set_att = float(self.el_att.text())

            # Set the attenuation in another Thread
            self.instr_worker_thread.started.connect(
                partial(self.instr_worker.set_el_att, set_att))
            self.instr_worker_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

        except BaseException:
            pass

    def closeEvent(self, *args, **kwargs):
        super(QtWidgets.QMainWindow, self).closeEvent(*args, **kwargs)
        self.timer.stop()
        self.close_instruments()

    def close_instruments(self):
        self.visa_lock.lock()
        for instr in self.instr_list:
            instr.close()
        self.visa_lock.unlock()

    def _find_instr_type_(self, category):
        """
        Returns a list of the instruments with the specified category
        category is one of the instrument interfaces. Ex: Laser
        """
        lst = []

        for instr in self.instr_list:
            if isinstance(instr, category):
                lst.append(instr)

        return lst

    def call_experiment(self, experiment_object):
        """
        Executes the experiment realized by the experiment_object stored in self.experiment_list at position experiment_index.
        This function is called when an experiment is chosen in the "experiments" drop down menu.
        Why this function is necessary is because we need to construct the params dictionnary to pass to the experiment.
        """

        # Stop the refreshing execution
        self.timer.stop()

        params = self._generate_params_dict_(experiment_object)
        filename = QtWidgets.QFileDialog.getSaveFileName()
        filename = filename[0]

        self.last_experiment = experiment_object

        # Run the experiment in the experiment thread (if there is a filename
        # specified)
        if filename:
            self.exp_thread.started.connect(
                partial(
                    experiment_object.run_experiment,
                    params,
                    filename))
            self.exp_thread.start()
            time.sleep(0.0001)  # yield to the InstrumentWorker thread

    def process_experiment_results(self, exp_results):
        """
        This is the method called when an experiment is done and we receive a signal from the experiments thread.
        """

        # Plot the data
        self.plot_button.setEnabled(True)
        self.last_exp_data = exp_results
        self.plot_last_experiment_data()

        # Restart the refreshing execution for updating the stats
        self.timer.start(REFRESHING_INTERVAL)  # in msec

    def _generate_params_dict_(self, experiment_object):
        """
        This function gathers all the numbers in the controls in the GUI and generates a dictionnary with parameters
        to be passed to the experiments
        """

        """
        The parameters are agreed between the GUI and the experiments:
        -"voltages", -"wavs", -"use_DAQ", -"temperatures", -"calibrate"
        -"measure_current", -"powers", -"num_averages", -"currents", -"power_range", - "voltages2",

        "amplitudes", "freqs",
        "f1", "f2", "amp_comp",
        """

        params_dict = {}

        req_params = experiment_object.required_params()

        for key in req_params:

            if key in self.indicator_param_map:

                element = self.indicator_param_map[key]

                # This element is a tuple. The firs element is 1 or more indicators containing the relevant information
                # The second element is the type of indicator ("checkbox" or "textbox")
                # THe heuristics to sort through this element tuple are a bit
                # complicated.

                # First, see if there is only one element specifying the
                # parameter
                if len(element[0]) == 1:
                    # We just need to extract the value if the indicator. Extracting the value depends on the
                    # tuple of indicator it is.
                    if element[1] == "checkbox":
                        params_dict[key] = element[0][0].isChecked()
                    elif element[1] == "textbox":
                        try:
                            params_dict[key] = float(element[0][0].text())
                        except BaseException:
                            params_dict[key] = element[0][0].text()

                    else:
                        raise ValueError(
                            "We don't know how to treat an indicator of type %s" %
                            element[1])

                elif len(element[0]) == 3:

                    # This is the case where the first indicator sets the init value, the second the end
                    # value and the third one the number of values
                    init_val = float(element[0][0].text())
                    end_val = float(element[0][1].text())
                    num_val = int(element[0][2].text())
                    vals = np.linspace(init_val, end_val, num_val)
                    params_dict[key] = vals

                elif len(element[0]) == 4:

                    # This is the case where the first indicator sets the init value, the second the end
                    # value, the third one the number of values and the last
                    # one the type of sweep
                    sweep_type = element[0][3].currentText()
                    if sweep_type == 'linear':
                        init_val = float(element[0][0].text())
                        end_val = float(element[0][1].text())
                        num_val = int(element[0][2].text())
                        vals = np.linspace(init_val, end_val, num_val)
                    elif sweep_type == 'log':
                        init_val = float(element[0][0].text())
                        end_val = float(element[0][1].text())
                        num_val = int(element[0][2].text())
                        vals = np.logspace(
                            np.log10(init_val), np.log10(end_val), num_val)
                    elif sweep_type == 'list':
                        # In this case, the values are given in the first
                        # textbox as a list
                        val_list = element[0][0].text()
                        val_list = [float(v) for v in val_list.split(" ")]
                        vals = np.array(val_list)
                    else:
                        raise ValueError(
                            'Sweep type not recognized: %s' %
                            sweep_type)
                    params_dict[key] = vals

                else:
                    raise ValueError(
                        "We don't know how to treat %d indicators to specify a param" % len(
                            element[0]))

            else:
                # It means we don't have an indicator for the variable!

                # We can check if the parameter we lack has a default value, in
                # which case this is not a problem
                if key not in experiment_object.default_params():
                    # There is no default value and no indicator - this is a
                    # problem
                    raise ValueError(
                        "The experiment %s requires the param %s and there is no indicator or default value for it!" %
                        (experiment_object.get_name(), key))

        return params_dict

    def refresh_stats(self):

        # Launch the information gathering in another thread and tie its ending
        # to a GUI refresh operation

        meas_smu = (self.num_loop_exec == 0)

        # Get the data in another thread
        self.stats_worker_thread.started.connect(
            partial(self.stats_worker.get_stats, self.smu_mode, meas_smu))
        self.stats_worker_thread.start()
        self.num_loop_exec = (self.num_loop_exec + 1) % SMU_MEAS_INTERVAL

    def refresh_GUI_stats(self, stats_list):

        # Unpack all the data
        meas_wav, sm_val, tap_power, rec_power = stats_list

        # Measured wavelength
        self.meas_wl.setText(str(meas_wav))

        # Source meter current
        try:
            if sm_val is not None:
                if sm_val == 'NA':
                    if self.smu_mode == 'meas_volt':
                        self.sm_volt.setText(sm_val)
                    elif self.smu_mode == 'meas_cur':
                        self.sm_current.setText(sm_val)
                else:
                    if self.smu_mode == 'meas_volt':
                        self.sm_volt.setText("%.2f" % sm_val)
                    elif self.smu_mode == 'meas_cur':
                        self.sm_current.setText("%.3e" % sm_val)
        except BaseException:
            pass

        # Optical Power
        self.tap_power.setText("%.2e" % tap_power)
        self.rec_power.setText("%.2e" % rec_power)
        if self.use_cal.isChecked():
            calibrate = 1
        else:
            calibrate = 0
        wav = float(self.set_wl.text())
        [through_loss, input_power] = analyze_powers(
            tap_power, rec_power, wav, calibrate, self.rec_splitter_ratio)
        self.in_out_loss.setText("%.2f" % through_loss)
        self.meas_in_power.setText("%.2e" % input_power)

        # Refresh the tx vs time plot if necessary
        if self.plot_tx:
            if len(self.tx_vs_time) > PLOT_PERSISTENCE:
                self.tx_vs_time.pop(0)
            self.tx_vs_time.append(through_loss)
            self.plot_line.setData(self.tx_vs_time)
            QApplication.processEvents()

    def toggle_plot(self):

        if self.plot_button.text() == "Plot last experiment data":
            # Retrieve the last experiment data and plot it
            self.plot_last_experiment_data()
        else:

            self.plot_button.setText("Plot last experiment data")
            self.xlabel = self.plot_area.setLabel(
                'bottom', text='Time [au]', **self.label_styles)
            self.ylabel = self.plot_area.setLabel(
                'left', text='Transmission [dB]', **self.label_styles)
            self.plot_area.clear()
            self.plot_line = self.plot_area.plot([0], [0], pen=self.pen)
            self.title = self.plot_area.setTitle(
                'Coupling vs Time', size='20pt')
            self.plot_tx = True

    def plot_last_experiment_data(self):

        # Stop plotting the tx vs time and erase all tx vs time data
        self.plot_tx = False
        self.tx_vs_time = []

        try:
            # Plots the last experiment data in the plot area by calling the
            # plot_data method of the experiment
            self.last_experiment.plot_data(self.plot_area, self.last_exp_data)
            self.plot_button.setText("Plot in-out loss")

        except BaseException:
            print('The experiment data cannot be plotted')
