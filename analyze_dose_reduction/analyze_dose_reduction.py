# -*- coding: utf-8 -*-
"""
Created on Tue Aug 25 11:07:37 2026

@author: RXZ4 & FDA-ELSA

This pyton code analyzes the dose reduction percentages of the DL method relative 
to the reference FBP for maintaining low-contrast detectability. The inputs are 
the AUC results of a deep-learning and a baseline FBP reconstruction method across
multiple dose levels obtained from a LCD test. 

Before the main analysis runs, an interactive window displays the FBP dose-AUC
data points for all four inserts to allow users to select the reference dose level.
Recommended selection criterion (shown as a reminder in the plot):
    "All four insert AUCs should fall in the range [0.75, 0.85]."
Click on or near any measured dose level to select it as the reference dose. The
selection snaps to the nearest measured dose point. The annotation box shows
the measured AUC value at that dose for every insert.
Press Confirm to proceed with the selected dose level.

The code will output the estimated dose reduction percentages (mean, STD and
95% CI) for each insert. It will also display the AUC-dose curves for both
reconstruction methods in one plot.

Usage
-----
Run directly:
    python demo_analyze_dose_reduction.py

Import and call programmatically:
    from demo_analyze_dose_reduction import analyze_dose_reduction
    results = analyze_dose_reduction(
        dose_percent, aucmean_fbp, aucmean_dl, aucse_fbp, aucse_dl
    )
"""

import numpy as np
from scipy.optimize import curve_fit
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.widgets import Button


# ===========================================================================
# Helper functions
# ===========================================================================

def weibull_psychometric(x, alpha, beta, gamma, lam):
    return gamma + (1 - gamma - lam) * (1 - np.exp(-((x / alpha) ** beta)))


def weibull_psychometric_inverse(y, alpha, beta, gamma, lam):
    y = np.clip(y, gamma + 1e-10, 1 - lam - 1e-10)
    normalized_y = (y - gamma) / (1 - gamma - lam)
    normalized_y = np.clip(normalized_y, 1e-10, 1 - 1e-10)
    log_term = -np.log(1 - normalized_y)
    x = alpha * (log_term ** (1 / beta))
    return x


def fit_weibull_and_interpolate(dose_data, auc_data, target_auc_values):
    initial_guess = [np.median(dose_data), 1.0, 0.5, 0.01]
    bounds = ([1e-6, 0.5, 0.5, 0], [np.inf, 2, 0.55, 0.05])
    try:
        popt, _ = curve_fit(weibull_psychometric, dose_data, auc_data,
                            p0=initial_guess, bounds=bounds, maxfev=5000)
        interpolated_doses = weibull_psychometric_inverse(target_auc_values, *popt)
        return interpolated_doses, popt
    except Exception as e:
        print(f"Warning: Weibull fitting failed ({e}), using linear interpolation")
        interpolated_doses = np.interp(target_auc_values, auc_data, dose_data)
        return interpolated_doses, None


def snap_to_measured(dose_val, dose_percent):
    """Snap a continuous dose value to the nearest measured dose level."""
    idx = int(np.argmin(np.abs(dose_percent - dose_val)))
    return dose_percent[idx], idx


def get_fbp_auc_at_measured(dose_idx, aucmean):
    """Return the actual measured FBP AUC values at a given dose index."""
    return [float(aucmean[dose_idx, i_ins]) for i_ins in range(4)]


def build_annot_text(dose_val, auc_list, labels, lo, hi):
    """Build the annotation string shown in the interactive selector."""
    lines = [f"Reference dose: {dose_val:.1f}%", ""]
    all_ok = True
    for lbl, auc in zip(labels, auc_list):
        ok = lo <= auc <= hi
        flag = "  OK" if ok else "  !!"
        if not ok:
            all_ok = False
        lines.append(f"  {lbl:<14s}: AUC = {auc:.3f}{flag}")
    lines.append("")
    if all_ok:
        lines.append("All AUCs in range -- good to confirm!")
    else:
        lines.append(" Aim for AUCs in [0.75, 0.85]")
    return "\n".join(lines)


# ===========================================================================
# Interactive Reference Dose Selector
# ===========================================================================

def select_reference_dose(dose_percent, aucmean_fbp, insert_labels, colors,
                           auc_lo=0.75, auc_hi=0.85):
    """
    Launch an interactive matplotlib window for the user to select a reference
    dose level based on the FBP AUC-dose data.

    Parameters
    ----------
    dose_percent  : array-like, shape (N,)
        Measured dose levels (e.g. [15, 25, 50, 75, 100]).
    aucmean_fbp   : array-like, shape (N, 4)
        Mean AUC values for the FBP method at each dose and insert.
    insert_labels : list of str, length 4
        Display labels for each insert (e.g. ["3mm-14HU", ...]).
    colors        : list of str, length 4
        Matplotlib color strings for each insert.
    auc_lo        : float, optional
        Lower bound of the recommended AUC range (default 0.75).
    auc_hi        : float, optional
        Upper bound of the recommended AUC range (default 0.85).

    Returns
    -------
    selected_dose     : float
        The dose level chosen by the user (snapped to a measured point).
    selected_dose_idx : int
        Index into dose_percent corresponding to selected_dose.
    """
    dose_percent = np.asarray(dose_percent)
    aucmean_fbp  = np.asarray(aucmean_fbp)

    # Pre-fit Weibull curves to FBP data for smooth background curves only
    
    fbp_smooth_params = []
    dose_fine = np.linspace(dose_percent.min(), dose_percent.max(), 300)

    for i_ins in range(4):
        aucfbp_i = aucmean_fbp[:, i_ins].flatten()
        _, p = fit_weibull_and_interpolate(dose_percent, aucfbp_i, np.array([0.8]))
        fbp_smooth_params.append(p)

    fig_sel, ax_sel = plt.subplots(figsize=(10, 6))
    plt.subplots_adjust(bottom=0.18)
    fig_sel.suptitle(
        "Select Reference Dose Level\n"
        "(by moving the vertical line along the curves.)\n"
        "Press Confirm when done.",
        fontsize=12, color='#222C67'
    )

    # Smooth Weibull background curves
    for i_ins in range(4):
        p = fbp_smooth_params[i_ins]
        if p is not None:
            ax_sel.plot(dose_fine,
                        weibull_psychometric(dose_fine, *p),
                        color=colors[i_ins], linewidth=1.8, alpha=0.3,
                        linestyle='-')

    # FBP data points with error bars
    for i_ins in range(4):
        aucfbp_i = aucmean_fbp[:, i_ins].flatten()
        ax_sel.plot(dose_percent, aucfbp_i, 'o',
                    color=colors[i_ins], markersize=9,
                    label=insert_labels[i_ins], alpha=0.9, zorder=3)

    # Shaded recommended AUC band
    ax_sel.axhspan(auc_lo, auc_hi, alpha=0.08, color='green',
                   label=f'Recommended AUC [{auc_lo}, {auc_hi}]')
    ax_sel.axhline(auc_lo, color='green', linewidth=0.8, linestyle='--', alpha=0.5)
    ax_sel.axhline(auc_hi, color='green', linewidth=0.8, linestyle='--', alpha=0.5)

    ax_sel.set_xlabel('Dose Percentage (%)', fontsize=13)
    ax_sel.set_ylabel('AUC (FBP)', fontsize=13)
    ax_sel.set_ylim([0.50, 1.02])
    ax_sel.set_xticks(dose_percent)
    ax_sel.legend(loc='lower right', fontsize=11)

    # Initial selection: middle measured dose level
    init_idx  = len(dose_percent) // 2
    init_dose = dose_percent[init_idx]

    vline = ax_sel.axvline(x=init_dose, color='#007CBA', linewidth=2.5,
                           linestyle='-', alpha=0.85, zorder=2)

    sel_markers = []
    for i_ins in range(4):
        auc_val = float(aucmean_fbp[init_idx, i_ins])
        mk, = ax_sel.plot(init_dose, auc_val, 'o',
                          color=colors[i_ins], markersize=14,
                          markeredgecolor='#007CBA', markeredgewidth=2.5,
                          zorder=4)
        sel_markers.append(mk)

    init_aucs  = get_fbp_auc_at_measured(init_idx, aucmean_fbp)
    init_annot = build_annot_text(init_dose, init_aucs, insert_labels,
                                  auc_lo, auc_hi)
    annot_box = ax_sel.text(
        0.02, 0.97, init_annot,
        transform=ax_sel.transAxes,
        fontsize=10, verticalalignment='top',
        bbox=dict(boxstyle='round,pad=0.5', facecolor='lightyellow',
                  edgecolor='#007CBA', alpha=0.9),
        family='monospace'
    )

    state = {'dose': init_dose, 'dose_idx': init_idx, 'confirmed': False}

    def update_display(snapped_dose, snapped_idx):
        vline.set_xdata([snapped_dose, snapped_dose])
        aucs = get_fbp_auc_at_measured(snapped_idx, aucmean_fbp)
        for i_ins, mk in enumerate(sel_markers):
            mk.set_xdata([snapped_dose])
            mk.set_ydata([aucs[i_ins]])
        annot_box.set_text(
            build_annot_text(snapped_dose, aucs, insert_labels, auc_lo, auc_hi)
        )
        fig_sel.canvas.draw_idle()

    def on_click(event):
        if event.inaxes != ax_sel or event.xdata is None:
            return
        snapped_dose, snapped_idx = snap_to_measured(event.xdata, dose_percent)
        state['dose']     = snapped_dose
        state['dose_idx'] = snapped_idx
        update_display(snapped_dose, snapped_idx)

    def on_confirm(event):
        state['confirmed'] = True
        plt.close(fig_sel)

    fig_sel.canvas.mpl_connect('button_press_event', on_click)

  #  ax_btn = plt.axes([0.40, 0.04, 0.20, 0.07]) #"Confirm" button position
    ax_btn = plt.axes([0.80, 0.90, 0.10, 0.07]) #"Confirm" button position
    btn_confirm = Button(ax_btn, 'Confirm', color='#007CBA', hovercolor='#222C67')
    btn_confirm.label.set_color('white')
    btn_confirm.label.set_fontsize(12)
    btn_confirm.on_clicked(on_confirm)

    plt.show(block=True)

    selected_dose     = state['dose']
    selected_dose_idx = state['dose_idx']

    print(f"\n>>> Reference dose selected: {selected_dose:.1f}%")

    chosen_aucs  = get_fbp_auc_at_measured(selected_dose_idx, aucmean_fbp)
    all_in_range = all(auc_lo <= a <= auc_hi for a in chosen_aucs)
    if not all_in_range:
        print("WARNING: Not all insert AUCs are in [0.75, 0.85] at the chosen dose!")
        for lbl, auc in zip(insert_labels, chosen_aucs):
            flag = "OK" if auc_lo <= auc <= auc_hi else "OUT OF RANGE"
            print(f"  {lbl}: AUC = {auc:.3f}  [{flag}]")
    else:
        print("All insert AUCs are within [0.75, 0.85].  Proceeding with analysis.")

    return selected_dose, selected_dose_idx


# ===========================================================================
# Main analysis function
# ===========================================================================

def analyze_dose_reduction(
    dose_percent,
    aucmean_fbp,
    aucmean_dl,
    aucse_fbp,
    aucse_dl,
    insert_labels=None,
    colors=None,
    n_mc=30,
    rng_seed=12345,
):
    """
    Analyze the dose reduction of a DL reconstruction method relative to FBP
    for maintaining equivalent low-contrast detectability (AUC).

    An interactive window is launched first so the user can select the
    reference FBP dose level.  Monte Carlo resampling is then used to
    propagate AUC measurement uncertainty into the dose-reduction estimates.

    Parameters
    ----------
    dose_percent  : array-like, shape (N,)
        Measured dose levels as percentages (e.g. [15, 25, 50, 75, 100]).
    aucmean_fbp   : array-like, shape (N, 4)
        Mean AUC values for the FBP reconstruction at each dose and insert.
    aucmean_dl    : array-like, shape (N, 4)
        Mean AUC values for the DL reconstruction at each dose and insert.
    aucse_fbp     : array-like, shape (N, 4)
        Standard error of AUC for the FBP reconstruction.
    aucse_dl      : array-like, shape (N, 4)
        Standard error of AUC for the DL reconstruction.
    insert_labels : list of str, optional
        Display labels for each insert.
        Default: ['3mm-14HU', '5mm-7HU', '7mm-5HU', '10mm-3HU'].
    colors        : list of str, optional
        Matplotlib color strings for each insert.
        Default: ['blue', 'red', 'green', 'orange'].
    n_mc          : int, optional
        Number of Monte Carlo iterations for uncertainty estimation.
        Default: 30.
    rng_seed      : int, optional
        Random seed for reproducibility.  Default: 12345.

    Returns
    -------
    results : dict with keys
        'basedose'      : float  -- the user-selected reference dose (%)
        'insert_labels' : list   -- insert labels used
        'rr_mean'       : ndarray, shape (4,) -- mean dose reduction fraction
        'rr_std'        : ndarray, shape (4,) -- std of dose reduction fraction
        'rr_ci_low'     : ndarray, shape (4,) -- 2.5th percentile (95% CI lower)
        'rr_ci_high'    : ndarray, shape (4,) -- 97.5th percentile (95% CI upper)

        Multiply by 100 to convert fractions to percentages.
    """
    dose_percent = np.asarray(dose_percent, dtype=float)
    aucmean_fbp  = np.asarray(aucmean_fbp,  dtype=float)
    aucmean_dl   = np.asarray(aucmean_dl,   dtype=float)
    aucse_fbp    = np.asarray(aucse_fbp,    dtype=float)
    aucse_dl     = np.asarray(aucse_dl,     dtype=float)

    if insert_labels is None:
        insert_labels = ['3mm-14HU', '5mm-7HU', '7mm-5HU', '10mm-3HU']
    if colors is None:
        colors = ['blue', 'red', 'green', 'orange']

    # ------------------------------------------------------------------
    # Step 1: Interactive reference dose selection
    # ------------------------------------------------------------------
    basedose, basedose_idx = select_reference_dose(
        dose_percent, aucmean_fbp, insert_labels, colors
    )

    # ------------------------------------------------------------------
    # Step 2: Fit Weibull curves and plot AUC-dose curves
    # ------------------------------------------------------------------
    delta     = 0.01
    auc_range = np.arange(0.65, 0.9 + delta / 2, delta)

    plt.rcParams['axes.titlesize']   = 20
    plt.rcParams['axes.labelsize']   = 18
    plt.rcParams['figure.titlesize'] = 22
    plt.rcParams['xtick.labelsize']  = 18
    plt.rcParams['ytick.labelsize']  = 18
    plt.rcParams['legend.fontsize']  = 14

    fig, ax = plt.subplots(1, 1, figsize=(12, 8))

    for i_insert in range(4):
        aucfbp = aucmean_fbp[:, i_insert].flatten()
        aucdl  = aucmean_dl[:, i_insert].flatten()
        sefbp  = aucse_fbp[:, i_insert].flatten()
        sedl   = aucse_dl[:, i_insert].flatten()

        fbp_dose, fbp_params = fit_weibull_and_interpolate(
            dose_percent, aucfbp, auc_range)
        dl_dose,  dl_params  = fit_weibull_and_interpolate(
            dose_percent, aucdl,  auc_range)

        dose_smooth = np.linspace(dose_percent.min(), dose_percent.max(), 200)
        if fbp_params is not None:
            fbp_fitted = weibull_psychometric(dose_smooth, *fbp_params)
            ax.plot(dose_smooth, fbp_fitted, color=colors[i_insert],
                    linestyle='-', linewidth=2.5,
                    label=f'{insert_labels[i_insert]} - FBP')
        if dl_params is not None:
            dl_fitted = weibull_psychometric(dose_smooth, *dl_params)
            ax.plot(dose_smooth, dl_fitted, color=colors[i_insert],
                    linestyle='--', linewidth=2.5,
                    label=f'{insert_labels[i_insert]} - DL')

        ax.errorbar(dose_percent, aucfbp, sefbp, fmt='o',
                    color=colors[i_insert], alpha=0.6, markersize=7,
                    capsize=4, linestyle='None',
                    markeredgewidth=0.5, markeredgecolor=colors[i_insert],
                    markerfacecolor=colors[i_insert])
        ax.errorbar(dose_percent, aucdl, sedl, fmt='o',
                    color=colors[i_insert], alpha=0.6, markersize=6,
                    capsize=4, linestyle='None',
                    markeredgewidth=1.5, markeredgecolor=colors[i_insert],
                    fillstyle='none')

    # ------------------------------------------------------------------
    # Step 3: Calculate dose reduction perentages
    # apply Monte Carlo method for uncertainty estimation (mean, std, 95% CI)
    # ------------------------------------------------------------------
    print(f"\nRunning Monte Carlo uncertainty estimation with n_mc={n_mc}...")

    rng = np.random.default_rng(rng_seed)
    reduction_rate_mc = np.full((n_mc, 4), np.nan)

    for i_mc in range(n_mc):
        aucfbp_sample = np.clip(
            rng.normal(loc=aucmean_fbp, scale=aucse_fbp), 0.5, 1.0)
        aucdl_sample  = np.clip(
            rng.normal(loc=aucmean_dl,  scale=aucse_dl),  0.5, 1.0)

        for i_insert_mc in range(4):
            aucfbp_mc = aucfbp_sample[:, i_insert_mc].flatten()
            aucdl_mc  = aucdl_sample[:, i_insert_mc].flatten()

            fbp_dose_mc, fbp_params_mc = fit_weibull_and_interpolate(
                dose_percent, aucfbp_mc, auc_range)
            dl_dose_mc,  dl_params_mc  = fit_weibull_and_interpolate(
                dose_percent, aucdl_mc,  auc_range)

            if fbp_params_mc is None or dl_params_mc is None:
                continue

            aucfbp0_mc = weibull_psychometric(basedose, *fbp_params_mc)
            dosedl0_mc = weibull_psychometric_inverse(aucfbp0_mc, *dl_params_mc)
            reduction_rate_mc[i_mc, i_insert_mc] = (
                basedose - dosedl0_mc
            ) / basedose

    rr_mean    = np.nanmean(reduction_rate_mc,            axis=0)
    rr_std     = np.nanstd(reduction_rate_mc,             axis=0)
    rr_ci_low  = np.nanpercentile(reduction_rate_mc,  2.5, axis=0)
    rr_ci_high = np.nanpercentile(reduction_rate_mc, 97.5, axis=0)
    min_rr_mean = round(rr_mean.min()*100)
    max_rr_mean = round(rr_mean.max()*100)

    # ------------------------------------------------------------------
    # Step 4: Print results
    # ------------------------------------------------------------------
    print("\nMonte Carlo dose reduction uncertainty:")
    for i_insert_mc in range(4):
        print(f"\n{insert_labels[i_insert_mc]}:")
        print(
            f"  Baseline dose {basedose:.1f}%: "
            f"{rr_mean[i_insert_mc] * 100:.1f}% +/- "
            f"{rr_std[i_insert_mc] * 100:.1f}% "
            f"(95% CI: {rr_ci_low[i_insert_mc] * 100:.1f}% to "
            f"{rr_ci_high[i_insert_mc] * 100:.1f}%)"
        )

    # ------------------------------------------------------------------
    # Step 5: Finalize the AUC-dose plot
    # ------------------------------------------------------------------
    ax.axvline(x=basedose, color='black', linestyle='--', alpha=0.5, linewidth=2)
    ax.text(basedose + 0.5, 0.56,
            f"Ref. dose\n{basedose:.1f}%",
            fontsize=11, color='black', alpha=0.7)

    custom_handles = [
        Line2D([0], [0], marker='o', color='w', markerfacecolor='black',
               markersize=8, markeredgecolor='gray', markeredgewidth=1.5,
               label='FBP data'),
        Line2D([0], [0], marker='o', color='w', markerfacecolor='none',
               markersize=8, markeredgecolor='gray', markeredgewidth=1.5,
               label='DL data'),
    ]

    ax.set_xlabel('Dose Percentage (%)')
    ax.set_ylabel('AUC')
    ax.set_title(f'AUC vs. dose curves for all four inserts  '
                 f'[ref. dose = {basedose:.1f}%]')
    ax.set_ylim([0.54, 1])

    handles, labels_plot = ax.get_legend_handles_labels()
    ax.legend(handles + custom_handles,
              labels_plot + ['FBP data', 'DL data'],
              loc='best', ncol=2, framealpha=0.9)

    dose_reduction_text = (
        f"Estimated Dose Reduction% \n"
        f"3 mm: {rr_mean[0] * 100:.1f}%\n"
        f"5 mm: {rr_mean[1] * 100:.1f}%\n"
        f"7 mm: {rr_mean[2] * 100:.1f}%\n"
        f"10 mm: {rr_mean[3] * 100:.1f}%\n\n"
        f"Overall dose reduction range: {min_rr_mean:d}% to {max_rr_mean:d}%"
    )
    ax.text(
        0.05, 0.95, dose_reduction_text,
        transform=ax.transAxes,
        fontsize=12, color="blue",
        verticalalignment="top",
        horizontalalignment="left",
        bbox=dict(facecolor="white", alpha=0.5, edgecolor="black")
    )

    plt.tight_layout()
    plt.show()

    return {
        'basedose'      : basedose,
        'insert_labels' : insert_labels,
        'rr_mean'       : rr_mean,
        'rr_std'        : rr_std,
        'rr_ci_low'     : rr_ci_low,
        'rr_ci_high'    : rr_ci_high,
    }


# ===========================================================================
# Entry point  --  supply your input data here
# ===========================================================================

if __name__ == "__main__":

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
