"""
Demo 03: Two Recon Dose Curve LCD Analysis
"""
from pathlib import Path
import numpy as np
import pandas as pd
from lcdct.LCD import measure_LCD, plot_results
from lcdct.utils import load_dataset, read_mhd

def main():
    base_dir = Path('data')
    use_large_dataset = False
    
    if use_large_dataset:
        base_directory = base_dir / 'large_dataset'
    else:
        base_directory = base_dir / 'small_dataset'
        
    recon_names = ['fbp', 'DL_denoised']
    
    # Ground Truth
    ground_truth_fname = base_directory / 'fbp' / 'ground_truth.mhd'
    offset = 1000
    if not ground_truth_fname.exists():
        print(f"Ground truth not found at {ground_truth_fname}")
        return
        
    ground_truth = read_mhd(str(ground_truth_fname)).astype(np.float32) - offset
    
    results_list = []
    observers = ['LG_CHO_2D']

    # Find common dose levels
    # Scan fbp dir for dose_*
    fbp_dir = base_directory / 'fbp'
    dose_dirs = sorted(list(fbp_dir.glob('dose_*')))
    
    for d_path in dose_dirs:
        try:
            dose_val = int(d_path.name.split('_')[1])
        except Exception:
            continue
            
        print(f"Processing Dose {dose_val}...")
        
        for recon in recon_names:
            recon_dir = base_directory / recon / d_path.name
            
            try:
                sp, sa = load_dataset(recon_dir, offset=offset)
            except Exception as e:
                # print(f"Skipping {recon_dir}: {e}")
                continue
            
            res = measure_LCD(sp, sa, ground_truth, observers=observers)
            res['recon'] = recon
            res['dose_level'] = dose_val
            results_list.append(res)

    if results_list:
        final_df = pd.concat(results_list, ignore_index=True)
        print("Results Head:")
        print(final_df.head())
        
        final_df.to_csv('results_demo_03.csv', index=False)
        plot_results(final_df, ylim=[0.5, 1.0])
    
if __name__ == '__main__':
    main()
