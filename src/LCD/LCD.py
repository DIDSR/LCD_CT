"""
Low Contrast Detectability (LCD)
"""
from pathlib import Path

from oct2py import octave
import pandas as pd
import numpy as np


def measure_LCD(signal_present: np.ndarray, signal_absent: np.ndarray,
                ground_truth: np.ndarray, observers: list[str] = ['LG_CHO_2D']
                ):
    """
        given a dataset calculate low contrast detectability as auc curves and
        return as a table ready for saving or plotting

        :param signal_present: image stack of signal present images
        :param signal_absent: corresponding image stack of signal absent images
        :param ground_truth: image or filename of image with no noise of MITA LCD phantom
        :returns: pd.DataFrame
    """
    curdir = Path(__file__).parent.absolute()
    print(curdir)
    octave.cd(str(curdir))
    signal_present_array = signal_present.transpose(1, 2, 0)
    signal_absent_array = signal_absent.transpose(1, 2, 0)
    octave.addpath(str(curdir / 'classes'))
    octave.addpath(str(curdir / 'functions'))
    res = octave.measure_LCD(signal_present_array, signal_absent_array,
                             ground_truth, observers)
    res = {k: v.squeeze() for k, v in res.items()}
    return pd.DataFrame(res)
