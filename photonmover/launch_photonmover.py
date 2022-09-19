
# Photonmover GUI with the experiment-based approach.

# Basic idea: The GUI is simply a placeholder. Each possible experiment
# we could want to do is a class implementing the Experiment interface.
# This frontend only shows the list of available experiments nicely.
import getopt
import sys
from os import path
from PyQt5.QtWidgets import QApplication
from photonmover.photonmover_GUI import photonmover_GUI
from photonmover.utils.instr_yaml_parser import parse_instr_yaml_file

DEFAULT_INSTR_FILE = path.join(path.dirname(__file__), 'mock_instr_list.yaml')


def initialize_instr_list(instr_list):
    for instr in instr_list:
        instr.initialize()

# ---------------------------------------------------------
# OLD INSTR GENERATION
# STEP 1: Create the instruments
# laser = MockLaser()
# sm = MockSourceMeter()
# pm = MockPowerMeter()
# vna = MockVNA()

# STEP 2: Now arrange them in a list and initialize them
# instr_list = [laser, sm, pm, vna]
# initialize_instr_list(instr_list)

# ---------------------------------------------------------


# Get the path to the yaml file from the argument list
instr_file = DEFAULT_INSTR_FILE

# Remove 1st argument from the list of command line arguments because it
# is just the .py file name
argument_list = sys.argv[1:]

# Possible command name options (for now, only -f for file)
options = "f:"
# Long options
long_options = ["file ="]

try:
    # Parsing argument
    arguments, values = getopt.getopt(argument_list, options, long_options)

    # checking each argument
    for current_argument, current_value in arguments:

        if current_argument in ("-f", "--file"):
            instr_file = current_value

except getopt.error as err:
    # output error, and return with an error code
    print(str(err))


print('Loading instrument list from %s' % instr_file)

# Generate instrument list from the yaml file and initialize the instruments
instr_list, vars_list = parse_instr_yaml_file(instr_file)
initialize_instr_list(instr_list)

# Create the GUI and run it
app = QApplication(sys.argv)
GUI = photonmover_GUI(instr_list, vars_list)
GUI.show()
sys.exit(app.exec())
