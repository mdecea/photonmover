# This is an interface that any experiment has to implement.

from abc import ABC, abstractmethod
# ABC means Abstract Base Class and is basically an interface.

from PyQt5.QtCore import QObject, pyqtSignal


class FinalMeta(type(ABC), type(QObject)):
    pass


class Experiment(QObject, ABC, metaclass=FinalMeta):

    # The signal needs to be created this way for some reason. This is used
    # for threading.
    finished = pyqtSignal()
    experiment_results_plt = pyqtSignal(object)

    def __init__(self, visa_lock):
        ABC.__init__(self)
        QObject.__init__(self)
        self.visa_lock = visa_lock

    @abstractmethod
    def check_necessary_instruments(self, instrument_list):
        """
        Checks if the instruments necessary for the experiment are present.
        :param instrument_list: list of the available instruments
        :return: True if the instruments are present, False otherwise.
        """
        pass

    @abstractmethod
    def get_description(self):
        """
        Returns a string with a brief summary of the experiment.
        """
        pass

    @abstractmethod
    def get_name(self):
        """
        Returns a string with the experiment name
        """
        pass

    def run_experiment(self, params, filename=None):
        """
        Calls self.perform_experiment and takes care of the threading stuff.
        """

        self.visa_lock.lock()

        # Perform the experiment
        exp_data = self.perform_experiment(params, filename)

        # Emit the plot results to the GUI thread
        self.experiment_results_plt.emit(exp_data)
        # Signal that the experiment is over
        self.finished.emit()

        self.visa_lock.unlock()

    @abstractmethod
    def perform_experiment(self, params, filename=None):
        """
        Performs the experiment, and saves the relevant data (if there is any)
        to the specified file (if given)
        :param params: dict of the parameters necessary for the experiment.
        :param filename: if specified, the data is saved in the specified file.
        :return: All the relevant data to higher level experiments that call
                a lower level experiment. For example, a "Tx vs V" sweep uses
                the simple "Tx" sweep. The "Tx" sweep returns in the first
                element all the data sent to the Tx vs V.
        """
        pass

    @abstractmethod
    def required_params(self):
        """
        Returns a list with the keys that need to be specified in
        the params dictionary in order for the measurement to be
        performed.
        """
        pass

    def default_params(self):
        """
        This function returns a dictionnary with default parameters
        for the experiment. Not all parameters need to have a default value.
        If a parameter is not given in the list of parameters,
        we will check if there are default parameters and use them if provided.
        If there are not default parameters at all, just return an empty
        dictionary.
        """
        return {}

    def check_all_params(self, params):
        """
        This function checks that all required parameters are present.
        If a given parameter is not present, it checks if it is given as a
        defaullt param, and if not it raises an error.
        """

        req_params = self.required_params()

        for p in req_params:

            if p not in params:
                # Required parameter not provided - check if there is a default
                if p in self.default_params():
                    params[p] = self.default_params()[p]
                else:
                    raise ValueError(
                        'Param %s missing in list of provided parameter, and there is no default provided.' %
                        p)

            # THIS IS EXPERIMENTAL. Is meant to handle parameters that are
            # dictionnaries. In this case, we might have specified some of
            # the keys but left some other unspecified. With this, we are
            # trying to fill this missing keys if they are specified in the
            # default params.
            if isinstance(params[p], dict):
                if p in self.default_params():
                    def_params_dict = self.default_params()[p]
                    for key in def_params_dict:
                        if key not in params[p]:
                            params[p][key] = def_params_dict[key]

        return params

    @abstractmethod
    def plot_data(self, canvas_handle, data=None):
        """
        This method plots the data gathered by the experiment in the canvas
        given as a parameter.
        :param canvas_handle: where to plot the data.
        :param data: the data to plot. This can be None, in which case what
            is plotted is the last result of the experiment (which is saved
            internally). Of course, this will throw an error if plot_data is
            called before having called perform_experiment
            (unless data is not None).
        """
        pass
