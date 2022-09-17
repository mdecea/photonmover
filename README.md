# Photonmover

`Photonmover` is a framework for developing control interfaces for scientific instruments commonly found in electronics, optics and photonics laboratories. 

The main goal of `photonmover` is to provide a simple but flexible and powerful set of templates for scientific instrument control which allows easy interchange of similar instruments through the use of object oriented programming (OOP) tools in general, and interfaces in particular. 

`Photonmover` is built in a hierarchical fashion:

1. The most basic element is an `Instrument`, which is a driver for a specific instrument (or set of instruments if they share the same functionality and communication commands). Over the years we have built a significant library of such drivers (some more exhaustive than others), which you can find under `instruments`. Notice how the different instruments are organized by functionality (oscilloscopes, Source Meters, Vector Network Analyzers...).

2. `Experiments` constitute the next hierarchy level. They use one or more `Instrument` to perform a given measurement, such as taking an IV curve or a wavelength sweep of a laser. As explained more in detail below, all experiments have a common set of methods they need to implement (enforced by the need of implementing the `Experiment` interface). This ensures that all experiments can be executed in a similar fashion.

3. Finally, at the top of the hierarchy there is a GUI that lists the available experiments and attempts to generate a set of controllers to set the different parameters for the available experiments. Full disclosure, the GUI generation is not very flexible and right now is heavily tailored to the needs of the Physical Optics and Electronics group at MIT. Help with making such GUI generation a bit more flexible is greatly appreciated.

# Instruments

The code that controls a specific instrument is self-contained in a .py file. An instrument file should never import another instrument file.

Each instrument is a class, and each class ALWAYS implemements 2 or more interfaces. Interfaces are empty classes that enforce the implementation of the methods listed in it. For example, the interface `Instrument` (`Interfaces/Instrument.py`) requires the implementation of the methods `initialize()` and `close()`.

The first interface that any instrument in photonmover needs to implement is precisely `Instrument`, which enforces methods to open and close connections to the instrument. The second interface depends on the purpose of the instrument. For example a temperature controller should implement the interface `TempController`, a source meter the interface `SourceMeter` and so on and so forth. Note: a given instrument can implement more than one iterface. For example, the HP laser mainframe is both a laser and a power meter, so it implements both interfaces `Laser` and `PowerMeter`.

All the exisitng interfaces can be found under `Interfaces`. If you have an instrument that does not belong to any of the already exisitng interfaces you should create a new one.

The main purpose of implementing interfaces is to allows for easy interchanging iof instruments. For example, let's say you are taking IV curves with a Keysight B2902A source meter. You go away for the weekend and when you come back you find out one of your coworkers *borrowed* it. There is a Keithley 2400 source meter free. If you have drivers for both instruments and both implement the `SourceMeter` interface, the only line of code you will need to change is the creation of the instrument, from `sm = KeysightB29092A()` to `sm = Keithley2400()`. Everything else won't need to change because all the methods have the same name and do the same functionality.

# Experiments

Experiments are classes that use one or more `Instrument` to perform a given measurement. All experiments in photonmover implement the interface `Experiment`, which enforces a series of methods necessary to run the GUI (for example to know required parameters, a name for the experiment and its description).

Note that a perfectly fine use of `photonmover` is to execute experiments from the command line and visualize the results later (for example in matlab). This is easy and flexible, but requires manually changing the parameters of the experiments every time in the `.py` file. In an effort to make this easier we have developed a GUI that tries to integrate all the experiments and allows for executing them (and plotting results) in the same GUI.

# GUI

The GUI implementation, which as disclosed is not very flexible, can be found in `photonmover_GUI.py` and is based on `pyqtgraph` and `PyQt5`. The basic idea is that based on the list of connected instruments, the software figures out which experiments can be done (for example, if we only have a `SourceMeter` connected we won't show experiments that require a `Laser`). Once we have figured that out, we *ask* each experiment which parameters are required (thanks to the interface we know all experiments can tell us that if we call its `required_params()` method) and then we create controls (textbox, buttons...) for each of the parameters. 

Anyone who has worked with GUIs before (but is not a software developer) knows that making flexible GUIs is really hard, so it's unclear how well the automatic GUI generation will work for setups that look very different from ours.

To launch the GUI we need to provide a list of the available instruments in the current setup. We do that through `.yaml` files. You can check examples of how to write such files in `mock_instr_list.yaml` or `cryo_instr_list.yaml`. Basically you just indicate which classes each instrument belongs to, and can specify some initialization parameters if necessary. If you have different setups, the idea is that you have a different yaml file for each. 

To launch the GUI you execute the command `python launch_photonmover.py -f <instr_file.yaml>`. If you just want to test the functinoality without being connected to real instruments, we provide a few mock instruments that simulate what real instruments would do (`mock_instr_list.yaml` file).

------
Some advanced technical notes: the GUI code is multithreaded. 

There are 3 existing threads:
1. The GUI thread, which deals with the plotting of the GUI and the update of any metrics shown there.
2. The "instrument worker" thread, which deals with operations on instruments directly controlled from the GUI, such as turning a laser on/off or changing the voltage applied from a source meter.
3. The experiments thread, which carries out any desired experiment.

# Initial test

The easiest way to test the installation of the package worked is to launch the GUI with mock instruments `python launch_photonmover.py -f mock_instr_list.yaml`.


## Contributors

- Marc de Cea Falco (maintainer)
- Gavin West
- Jaehwan Kim