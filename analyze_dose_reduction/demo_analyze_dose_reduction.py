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
# The LCD results contain AUCs of FBP and DL for detecting low-contrast inserts across five
# dose levels. 

dose_percent = np.array([15, 25, 50, 75, 100])

aucmean_fbp = np.array([
    [0.6370625,  0.68797917, 0.67753125, 0.66755208],
    [0.7605,     0.67461458, 0.67908333, 0.75840625],
    [0.81413542, 0.81104167, 0.83634375, 0.8549375 ],
    [0.85983333, 0.87264583, 0.93214583, 0.884     ],
    [0.91745833, 0.89578125, 0.94895833, 0.93      ],
])

aucmean_dl = np.array([
    [0.64559375, 0.68722917, 0.69690625, 0.68819792],
    [0.78220833, 0.7016875,  0.71538542, 0.76479167],
    [0.83541667, 0.83336458, 0.85035417, 0.86278125],
    [0.87554167, 0.8889375,  0.94682292, 0.90322917],
    [0.92642708, 0.91865625, 0.9548125,  0.94683333],
])

aucse_fbp = np.array([
    [0.0053917,  0.00953933, 0.01011987, 0.0081829 ],
    [0.00898646, 0.00885929, 0.00634692, 0.00891705],
    [0.00561863, 0.00545022, 0.0073522,  0.00731439],
    [0.00606354, 0.00533509, 0.00494582, 0.00518072],
    [0.00484016, 0.00474462, 0.00313004, 0.00457824],
])

aucse_dl = np.array([
    [0.00505973, 0.01190345, 0.00895275, 0.00781886],
    [0.00978245, 0.00788022, 0.00639719, 0.00860457],
    [0.00581343, 0.00464549, 0.00672433, 0.00639726],
    [0.00647267, 0.0048021,  0.00395201, 0.00473507],
    [0.00451204, 0.00420773, 0.00310837, 0.00392781],
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
