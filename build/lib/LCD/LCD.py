"""
Low Contrast Detectability (LCD)
"""
from pathlib import Path

from oct2py import octave
import pandas as pd

def measure_LCD(sp_vol, sa_vol, sp_gt_vol, observers=None):
    curdir = Path(__file__).parent.absolute()
    # octave.cd('../../LCD_CT/src/LCD')
    signal_present_array = sp_vol.transpose(1, 2, 0)
    signal_absent_array = sa_vol.transpose(1, 2, 0)
    print(curdir)
    octave.pwd()
    octave.addpath(curdir / 'classes')
    octave.addpath(curdir / 'functions')
    res = octave.measure_LCD(signal_present_array, signal_absent_array, sp_gt_vol)
    res = {k: v.squeeze() for k, v in res.items()}
    return pd.DataFrame(res)
