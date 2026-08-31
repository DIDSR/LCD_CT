# -*- coding: utf-8 -*-
"""
Created on Tue Aug 25 15:21:34 2026

@author: RXZ4
"""
import numpy as np

from analyze_dose_reduction import analyze_dose_reduction

# -----------------------------------------------------------------------
    # Input data
    # To load from a .mat file instead, uncomment and adapt the block below:
    #
    #   import scipy.io
    #   mat_data     = scipy.io.loadmat("your_file.mat")
    #   dose_percent = mat_data['dose'].flatten()
    #   aucmean_fbp  = mat_data['aucmean_fbp']
    #   aucmean_dl   = mat_data['aucmean_dl']
    #   aucse_fbp    = mat_data['aucse_fbp']
    #   aucse_dl     = mat_data['aucse_dl']
    # -----------------------------------------------------------------------

# The data below are example results from a LCD test to demo the dose reduction analysis code
# The LCD results contain AUCs of FBP and DL for detecting four low-contrast inserts across five
# dose levels. 

dose_percent = np.array([15, 25, 50, 75, 100])

aucmean_fbp = np.array([
    [0.665198, 0.675104, 0.695594, 0.697781],
    [0.716094, 0.70549,	 0.768948, 0.728844],
    [0.773458, 0.821927, 0.85574, 0.835792],
    [0.860427, 0.883781, 0.886552, 0.929031],
    [0.905729, 0.912927, 0.953,	0.957177],
])

aucmean_dl =  np.array([
    [0.666646, 0.68325, 0.691604, 0.701073],
    [0.72775, 0.719354, 0.776333, 0.747208],
    [0.799479, 0.841562, 0.876135, 0.849521],
    [0.88475, 0.915302,	0.901448, 0.939469],
    [0.918281, 0.92276, 0.962396, 0.965813],
])

aucse_fbp = np.array([
    [0.0110644, 0.00934245,	0.00711911,	0.00984369],
    [0.00726477, 0.0060572,	0.00815042,	0.00599643],
    [0.00558676, 0.00386949, 0.00360365, 0.00815162],
    [0.00562842, 0.00642962, 0.00552308, 0.00333962],
    [0.00449075, 0.00327772, 0.00338928, 0.00309312],
])

aucse_dl = np.array([
    [0.00973683, 0.00890148, 0.00699635, 0.0110806],
    [0.00638443, 0.00645843, 0.00780949, 0.00664373],
    [0.00722708, 0.00410795, 0.00337042, 0.00725207],
    [0.00533884, 0.00630808, 0.00453444, 0.00327171],
    [0.00397092, 0.00319968, 0.00326686, 0.00289947],
])

# Optional overrides (uncomment to customize)
# insert_labels = ['3mm-14HU', '5mm-7HU', '7mm-5HU', '10mm-3HU']
# colors        = ['blue', 'red', 'green', 'orange']

results = analyze_dose_reduction(
    dose_percent,
    aucmean_fbp,
    aucmean_dl,
    aucse_fbp,
    aucse_dl,
    # insert_labels=insert_labels,   # uncomment to override defaults
    # colors=colors,                 # uncomment to override defaults
    n_mc=30,
    rng_seed=12345,
)
