from PyQt5 import QtGui, QtCore
from PyQt5.QtCore import QThread
import pyqtgraph as pg
import importlib
import sys
import numpy as np
from photonmover.utils.class_parser import ClassParser
from photonmover.Interfaces.Experiment import Experiment
from photonmover.InstrumentWorker import InstrumentWorker

# Folder where all the experiment classes are stored
EXPERIMENTS_FOLDER = './experiments/'

REFRESHING_INTERVAL = 500  # in ms. Sets the time interval for
# refreshing the GUI indicators.

# Constants affecting the plotting of coupling vs time
PLOT_PERSISTENCE = 100  # Total number of points to be shown in the trace

DAQ_PLOT_CHANNEL = "cDAQ1Mod1/ai0"  # DAQ channel that we want
# to plot over time


class ramanmover_GUI(QtGui.QMainWindow):

    def __init__(self, instr_list):

        super(ramanmover_GUI, self).__init__()

        self.instr_list = instr_list

        # Create a thread for executing experiments
        self.exp_thread = QThread()

        # plotting stuff
        self.plot_power = True  # When true we plot power vs time.
        self.power_vs_time = []

        self.initialize_gui()

        self.show()

        # Start timer for refreshing the stats in the GUI
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.refresh_stats)
        self.timer.start(REFRESHING_INTERVAL)  # in msec

        # THREADING RELATED STUFF

        # Create an InstrumentWorker that will deal with all the functions in
        # which a GUI operation directly sets an instrument setting. For
        # example, turning the laser on and off, setting SMU voltage/current,
        # TEC temperature...
        self.instr_worker = InstrumentWorker(instr_list, self.statusBar())
        # Have a thread exclusively for the instrument worker
        self.instr_worker_thread = QThread()
        self.instr_worker.moveToThread(self.instr_worker_thread)
        self.instr_worker.finished.connect(self.instr_worker_thread.quit)
        self.instr_worker.finished.connect(
            self.__disconnect_instr_thread_start_events__)
        # Update the stats when we have the info
        self.instr_worker.stats_vals.connect(self.refresh_GUI_stats)

    def initialize_gui(self):

        self.setGeometry(100, 100, 1200, 600)
        self.setWindowTitle("Ramannmover v1.0")

        # Define a top-level window and a central widget to hold everything
        self.center_widget = QtGui.QWidget(self)
        self.setCentralWidget(self.center_widget)

        # Plot-related objects
        self.pen = pg.mkPen(width=5)
        self.label_styles = {'color': 'white', 'font-size': '20px'}

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
        :param status_tip: optional description (string) that will
            appear when hovering over the action
        """

        action = QtGui.QAction(label, self)
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

            # We only care about 'raman experiments
            if 'raman' in class_name or 'RAMAN' in class_name:
                # Import the module
                instr_module = importlib.import_module(mod_list[i])
                cl = getattr(instr_module, class_name)
                # Import the class
                # cl = globals()[class_name]

                # Make sure this is an experiment
                if issubclass(cl, Experiment):
                    try:
                        # If it is, check if the experiment can happen with the
                        # instruments available
                        experiment_object = cl(self.instr_list)

                        self.experiment_list.append(experiment_object)

                        # Move the experiment object to the experiment thread,
                        # which is where it will be executed.
                        experiment_object.moveToThread(self.exp_thread)
                        experiment_object.finished.connect(
                            self.exp_thread.quit)
                        experiment_object.finished.connect(
                            self.__disconnect_exp_thread_start_events__)
                        experiment_object.experiment_results_plt.connect(
                            self.process_experiment_results)

                        # This is the function that needs to be executed when
                        #  the menu item is clicked.
                        # Need to be done this way for some weird issue
                        # (see https://stackoverflow.com/questions/1464548/pyqt-qmenu-dynamically-populated-and-clicked)
                        def receiver(
                            bVal, exp_obj=experiment_object): \
                            return self.call_experiment(exp_obj)

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
        The shown indicators depend on the parameters needed by
        the experiments that can be carried out.

        As the indicators are constructed, we are also generating a
        dictionnary that indicates which experiment
        variable does that specific indicator set. This will be used
        later to construct the param dictionnary for the experiments
        """

        # Initialize the dictionary mapping indicator and parameters
        self.indicator_param_map = {}

        # First, get the list of necessary parameters
        self.param_list = self._get_all_params_list_()

        """
        The parameters are agreed between the GUI and the experiments:
        -"voltages", -"wavs", -"use_DAQ", -"temperatures", -"calibrate"
        -"meas_current", -"powers", -"num_averages", -"currents",
        -"power_range", - "voltages2",

        "amplitudes", "freqs",
        "f1", "f2", "amp_comp",
        """

        self.layout = QtGui.QGridLayout()
        self.center_widget.setLayout(self.layout)

        row = 0

        self.settings_group_box = QtGui.QGroupBox("General settings")
        layout = QtGui.QGridLayout()
        self.settings_group_box.setLayout(layout)

        layout.addWidget(QtGui.QLabel('Lock-in? '), 0, 0)
        self.lock_in = QtGui.QCheckBox(self)
        self.lock_in.setChecked(False)
        layout.addWidget(self.lock_in, 0, 1)
        self.indicator_param_map["lock-in"] = ([self.lock_in], 'checkbox')

        # row, column, row span, column span
        self.layout.addWidget(self.settings_group_box, row, 0, 2, 3)

        row = row + 2

        if "wavs" in self.param_list:

            self.laser_group_box = QtGui.QGroupBox("Laser On/Off controls")
            layout = QtGui.QHBoxLayout()
            self.laser_group_box.setLayout(layout)

            self.laser_power_button = QtGui.QPushButton(
                "Toggle Laser State", self)
            self.laser_power_button.clicked.connect(self.laser_on)
            layout.addWidget(self.laser_power_button)

            self.laser_state = QtGui.QLabel("")
            self.laser_state.setStyleSheet(
                "background-color : red; border: 1px solid black")
            layout.addWidget(self.laser_state)

            self.layout.addWidget(self.laser_group_box, row, 0, 1, 2)

            row = row + 1

            self.tx_group_box = QtGui.QGroupBox("Coupling and Tx")
            layout = QtGui.QGridLayout()
            self.tx_group_box.setLayout(layout)

            layout.addWidget(QtGui.QLabel('Set Wavelength (nm): '), 1, 0)
            self.set_wl = QtGui.QLineEdit('1550.00')
            self.set_wl.returnPressed.connect(self.set_laser_wav)
            layout.addWidget(self.set_wl, 1, 1)

            layout.addWidget(QtGui.QLabel('Measured Wavelength (nm): '), 1, 2)
            self.meas_wl = QtGui.QLineEdit('1550.00')
            self.meas_wl.setReadOnly(1)
            layout.addWidget(self.meas_wl, 1, 3)

            layout.addWidget(QtGui.QLabel('Set Power (mW or mA): '), 2, 0)
            self.set_power = QtGui.QLineEdit('1.00')
            self.set_power.returnPressed.connect(self.set_laser_power)
            layout.addWidget(self.set_power, 2, 1)

            layout.addWidget(QtGui.QLabel('Measured power (W): '), 2, 2)
            self.meas_power = QtGui.QLineEdit('1.00')
            self.meas_power.setReadOnly(1)
            layout.addWidget(self.meas_power, 2, 3)

            layout.addWidget(QtGui.QLabel('Power meter range (dBm): '), 4, 2)
            self.pm_range = QtGui.QLineEdit('AUTO')
            self.pm_range.returnPressed.connect(self.set_pm_range)
            layout.addWidget(self.pm_range, 4, 3)
            self.indicator_param_map["power_range"] = [
                [self.pm_range], 'textbox']

            self.layout.addWidget(self.tx_group_box, row, 0, 4, 3)

            row = row + 4

        if "wavs" in self.param_list:

            self.wav_group_box = QtGui.QGroupBox("Wav sweep settings")
            layout = QtGui.QHBoxLayout()
            self.wav_group_box.setLayout(layout)

            layout.addWidget(QtGui.QLabel('Start wav (nm): '))
            self.init_wav = QtGui.QLineEdit('1540.00')
            layout.addWidget(self.init_wav)

            layout.addWidget(QtGui.QLabel('End wav (nm): '))
            self.end_wav = QtGui.QLineEdit('1560.00')
            layout.addWidget(self.end_wav)

            layout.addWidget(QtGui.QLabel('Num wavs: '))
            self.num_wav = QtGui.QLineEdit('15')
            layout.addWidget(self.num_wav)

            # In the case of a sweep setting, we pass the 3 values (start, end
            # and num) as a list
            self.indicator_param_map["wavs"] = (
                [self.init_wav, self.end_wav, self.num_wav], 'textbox')

            # row, column, row span, column span
            self.layout.addWidget(self.wav_group_box, row, 0, 1, 4)

            row = row + 1

        if "powers" in self.param_list:

            self.power_group_box = QtGui.QGroupBox("P sweep settings")
            layout = QtGui.QHBoxLayout()
            self.power_group_box.setLayout(layout)

            layout.addWidget(QtGui.QLabel('Start power (mW): '))
            self.init_p = QtGui.QLineEdit('0.0')
            layout.addWidget(self.init_p)

            layout.addWidget(QtGui.QLabel('End power (mW): '))
            self.end_p = QtGui.QLineEdit('2.0')
            layout.addWidget(self.end_p)

            layout.addWidget(QtGui.QLabel('Num power: '))
            self.num_p = QtGui.QLineEdit('15')
            layout.addWidget(self.num_p)

            self.indicator_param_map["powers"] = (
                [self.init_p, self.end_p, self.num_p], 'textbox')

            # row, column, row span, column span
            self.layout.addWidget(self.power_group_box, row, 0, 1, 4)

            row = row + 1

        # "Others" group box
        self.others_group_box = QtGui.QGroupBox("Other params")
        layout = QtGui.QGridLayout()
        self.others_group_box.setLayout(layout)

        others_row_span = 1

        if "int_time" in self.param_list:
            layout.addWidget(QtGui.QLabel('Integration time (S): '), 0, 2)
            self.int_time = QtGui.QLineEdit('1')
            layout.addWidget(self.int_time, 0, 3)

            self.indicator_param_map["int_time"] = ([self.int_time], 'textbox')

        self.layout.addWidget(
            self.others_group_box,
            row,
            0,
            others_row_span,
            4)
        row = row + others_row_span

        if "num_reps" in self.param_list:
            layout.addWidget(QtGui.QLabel('Num meas per wav: '), 0, 2)
            self.num_avgs = QtGui.QLineEdit('1')
            layout.addWidget(self.num_avgs, 0, 3)

            self.indicator_param_map["num_reps"] = ([self.num_avgs], 'textbox')

        self.layout.addWidget(
            self.others_group_box,
            row,
            0,
            others_row_span,
            4)
        row = row + others_row_span

        if "sampling_freq" in self.param_list:
            layout.addWidget(QtGui.QLabel('Sampling freq (samp/s): '), 0, 2)
            self.sampling_freq = QtGui.QLineEdit('1000')
            layout.addWidget(self.sampling_freq, 0, 3)

            self.indicator_param_map["sampling_freq"] = (
                [self.sampling_freq], 'textbox')

        self.layout.addWidget(
            self.others_group_box,
            row,
            0,
            others_row_span,
            4)
        row = row + others_row_span

        # Plotting indicators
        self.plot_button = QtGui.QPushButton("Plot last experiment data", self)
        self.plot_button.setEnabled(False)
        self.plot_button.clicked.connect(self.toggle_plot)
        self.layout.addWidget(self.plot_button, 0, 9, 1, 3)

        self.plot_area = pg.PlotWidget()
        self.plot_area.showGrid(x=True, y=True)
        # Save a reference to the line because we will update it
        self.plot_line = self.plot_area.plot([0], [0], pen=self.pen)
        # every time when needed
        self.title = self.plot_area.setTitle(
            'Power (DAQ) vs Time', size='20pt')
        # init wor, inti col, row span, col span
        self.layout.addWidget(self.plot_area, 1, 7, row, 7)
        self.xlabel = self.plot_area.setLabel(
            'bottom', text='Time', **self.label_styles)
        self.ylabel = self.plot_area.setLabel(
            'left', text='Voltage (V)', **self.label_styles)
        font = QtGui.QFont()
        font.setPixelSize(20)
        self.plot_area.getAxis("bottom").setStyle(tickFont=font)
        self.plot_area.getAxis("left").setStyle(tickFont=font)

    def _get_all_params_list_(self):
        """
        Goes through the list of available experiments, asks for
        the necessary parameters and returns a list with the
        collection of all the parameters needed by the ensemble
        of experiments that can be evaluated
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
        for instr in self.instr_list:
            instr.close()
        sys.exit()

    def show_about(self):
        dlg = QtGui.QDialog(self)
        layout = QtGui.QVBoxLayout()
        dlg.setWindowTitle("About")
        layout.addWidget(QtGui.QLabel(
            """ This is ramanmover. GUI for Raman-related experiments. Written
             in python 3 and using PyQtgraph, uses the experiment-based
             approach. \n Written by Marc de Cea, Summer 2021 (amidst
             the end of a global pandemic). """))
        dlg.setLayout(layout)
        dlg.exec_()

    def __disconnect_instr_thread_start_events__(self):
        """
        Disconnects any signal tied to the start of the instrument thread.
        We need this so we can tie different methods to the start of the thred
        (depending on the
        operation we want to make)
        """
        try:
            self.instr_worker_thread.started.disconnect()
        except BaseException:
            pass

    def __disconnect_exp_thread_start_events__(self):
        """
        Disconnects any signal tied to the start of the experiment thread.
        We need this so we can tie different methods to the start of
        the thread (depending on the experiment we want to run)
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
                lambda: self.instr_worker.laser_on(op))
            self.instr_worker_thread.start()

        except BaseException:
            pass

    def set_laser_wav(self):

        try:
            set_wav = float(self.set_wl.text())

            # Set the wavelength in another Thread
            self.instr_worker_thread.started.connect(
                lambda: self.instr_worker.set_laser_wav(
                    set_wav, self.tf_with_laser.isChecked()))
            self.instr_worker_thread.start()

        except BaseException:
            pass

    def set_laser_power(self):

        try:
            set_power = float(self.set_power.text())

            # Set the power in another Thread
            self.instr_worker_thread.started.connect(
                lambda: self.instr_worker.set_laser_power(set_power))
            self.instr_worker_thread.start()

        except BaseException:
            pass

    def set_pm_range(self):

        try:
            set_range = self.pm_range.text()
            self.instr_worker_thread.started.connect(
                lambda: self.instr_worker.set_pm_range(set_range))
            self.instr_worker_thread.start()

        except BaseException:
            pass

    def closeEvent(self, *args, **kwargs):
        super(QtGui.QMainWindow, self).closeEvent(*args, **kwargs)
        self.close_instruments()

    def close_instruments(self):
        for instr in self.instr_list:
            instr.close()

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
        Executes the experiment realized by the experiment_object stored
        din self.experiment_list at position experiment_index.
        This function is called when an experiment is chosen in
        the "experiments" drop down menu.
        Why this function is necessary is because we need to
        construct the params dictionnary to pass to the experiment.
        """

        # Stop the refreshing execution
        self.timer.stop()

        params = self._generate_params_dict_(experiment_object)
        filename = QtGui.QFileDialog.getSaveFileName()
        filename = filename[0]

        self.last_experiment = experiment_object

        # Run the experiment in the experiment thread (if there is a filename
        # specified)
        if filename:
            self.exp_thread.started.connect(
                lambda: experiment_object.run_experiment(
                    params, filename))
            self.exp_thread.start()

    def process_experiment_results(self, exp_results):
        """
        This is the method called when an experiment is done
        and we receive a signal from the experiments thread.
        """

        # Plot the data
        self.plot_button.setEnabled(True)
        self.last_exp_data = exp_results
        self.plot_last_experiment_data()

        # Restart the refreshing execution for updating the stats
        self.timer.start(REFRESHING_INTERVAL)  # in msec

    def _generate_params_dict_(self, experiment_object):
        """
        This function gathers all the numbers in the controls in the GUI
        and generates a dictionnary with parameters
        to be passed to the experiments
        """
        params_dict = {}

        req_params = experiment_object.required_params()

        for key in req_params:

            if key in self.indicator_param_map:

                element = self.indicator_param_map[key]

                # This element is a tuple. The firs element is 1 or more
                # indicators containing the relevant information
                # The second element is the type of indicator ("checkbox"
                #  or "textbox")
                # THe heuristics to sort through this element tuple are a bit
                # complicated.

                # First, see if there is only one element specifying the
                # parameter
                if len(element[0]) == 1:
                    # We just need to extract the value if the indicator.
                    # Extracting the value depends on the
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

                    # This is the case where the first indicator sets the
                    # init value, the second the end
                    # value and the third one the number of values
                    init_val = float(element[0][0].text())
                    end_val = float(element[0][1].text())
                    num_val = int(element[0][2].text())
                    # TODO: Add indicators for linear or log sweep!
                    vals = np.linspace(init_val, end_val, num_val)
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

        # Get the data in another thread
        self.instr_worker_thread.started.connect(
            lambda: self.instr_worker.get_raman_stats(DAQ_PLOT_CHANNEL))
        self.instr_worker_thread.start()

    def refresh_GUI_stats(self, stats_list):

        # Unpack all the data
        meas_wav, power, v_daq = stats_list

        # Measured wavelength
        self.meas_wl.setText(str(meas_wav))

        # Optical Power
        self.meas_power.setText("%.2e" % power)

        # Refresh the power vs time plot if necessary
        if self.plot_power:
            if len(self.power_vs_time) > PLOT_PERSISTENCE:
                self.power_vs_time.pop(0)
            self.power_vs_time.append(v_daq)
            self.plot_line.setData(self.power_vs_time)

    def toggle_plot(self):

        if self.plot_button.text() == "Plot last experiment data":
            # Retrieve the last experiment data and plot it
            self.plot_last_experiment_data()
        else:

            self.plot_button.setText("Plot last experiment data")
            self.xlabel = self.plot_area.setLabel(
                'bottom', text='Time [au]', **self.label_styles)
            self.ylabel = self.plot_area.setLabel(
                'left', text='Voltage [V]', **self.label_styles)
            self.plot_area.clear()
            self.plot_line = self.plot_area.plot([0], [0], pen=self.pen)
            self.title = self.plot_area.setTitle(
                'Power (DAQ) vs Time', size='20pt')
            self.plot_power = True

    def plot_last_experiment_data(self):

        # Stop plotting the tx vs time and erase all tx vs time data
        self.plot_power = False
        self.power_vs_time = []

        try:
            # Plots the last experiment data in the plot area by calling the
            # plot_data method of the experiment
            self.last_experiment.plot_data(self.plot_area, self.last_exp_data)
            self.plot_button.setText("Plot coupled power")

        except BaseException:
            print('The experiment data cannot be plotted')
