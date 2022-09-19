import pickle
import numpy as np
from os import path

CALIBRATION_FILENAME = \
    path.join(path.dirname(__file__), 'current_calibration.pickle')


def get_calibration_factor(wav):
    """
    Returns the calibration factor for the current wavelength based on the
    pickle calibration file. This calibration factor is the real splitting
    in the splitter used for the tap.

    :return: The calibration factor
    """

    with open(CALIBRATION_FILENAME, 'rb') as pickle_file:
        # Load the calibration file
        cal_data = pickle.load(pickle_file)

        cal_wavs = cal_data[0]
        cal_factors = cal_data[1]

    ind = min(range(len(cal_wavs)), key=lambda i: abs(cal_wavs[i] - wav))

    return cal_factors[ind]


def analyze_powers(tap_power, rec_power, wav, calibrate, rec_splitter_ratio=1):
    """
    Gets the measured powers from the power meter and  applies calibration
    if indicated.
    :param rec_splitter_ratio: if there is a splitter after the output fiber,
        indicate here the tap to which the
        receive power meter is connected
    :return: A list containing through_loss, measured_input_power,
         measured_received_power, tap_power
    """

    # Account for tap_power being None (not measured)
    if tap_power is None:
        return 0, 0

    if calibrate:
        through_cal_factor = get_calibration_factor(wav)
        through_loss = 10 * np.log10((rec_power + 1.0e-15) /
                                     (tap_power / through_cal_factor
                                      + 1.0e-15))

        if rec_splitter_ratio == 1:
            measured_input_power = tap_power / through_cal_factor + 1.0e-15
        else:
            measured_input_power = \
                ((1 - rec_splitter_ratio) / rec_splitter_ratio) * \
                tap_power / through_cal_factor + 1.0e-15

    else:
        through_loss = 10 * np.log10((rec_power + 1.0e-15)
                                     / (tap_power + 1.0e-15))
        measured_input_power = tap_power + 1.0e-15

    return through_loss, measured_input_power
