"""
Demo 02: Two Recon LCD Analysis
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
        
    recon_1_name = 'fbp'
    recon_2_name = 'DL_denoised'
    
    # Ground Truth (using FBP one)
    ground_truth_fname = base_directory / recon_1_name / 'ground_truth.mhd'
    offset = 1000
    if not ground_truth_fname.exists():
        print(f"Ground truth not found at {ground_truth_fname}")
        return
        
    ground_truth = read_mhd(str(ground_truth_fname)).astype(np.float32) - offset
    
    # Dose 10
    dose = 10
    dose_str = f"dose_{dose:03d}"
    
    results_list = []
    
    for recon_name in [recon_1_name, recon_2_name]:
        recon_dir = base_directory / recon_name / dose_str
        print(f"Analyzing {recon_dir}...")
        
        try:
            sp, sa = load_dataset(recon_dir, offset=offset)
        except Exception as e:
            print(f"Failed to load dataset: {e}")
            continue
            
        observers = ['LG_CHO_2D']
        res = measure_LCD(sp, sa, ground_truth, observers=observers)
        res['recon'] = recon_name
        res['dose_level'] = dose
        results_list.append(res)
        
    if results_list:
        final_df = pd.concat(results_list, ignore_index=True)
        print("Results Head:")
        print(final_df.head())
        
        final_df.to_csv('results_demo_02.csv', index=False)
        plot_results(final_df, ylim=[0.5, 1.0])
    
if __name__ == '__main__':
    main()
