"""
Demo 01: Single Recon LCD Analysis
"""
from pathlib import Path
import numpy as np
from src.LCD.LCD import measure_LCD, plot_results
from src.LCD.utils import load_dataset, read_mhd

def main():
    base_dir = Path('data')
    use_large_dataset = False
    
    if use_large_dataset:
        base_directory = base_dir / 'large_dataset'
        # download if needed
    else:
        base_directory = base_dir / 'small_dataset'
        
    recon_name = 'fbp'
    recon_dir = base_directory / recon_name
    
    # Ground Truth
    ground_truth_fname = recon_dir / 'ground_truth.mhd'
    offset = 1000
    if not ground_truth_fname.exists():
        print(f"Ground truth not found at {ground_truth_fname}")
        return
        
    ground_truth = read_mhd(str(ground_truth_fname)).astype(np.float32) - offset
    
    # Dose 100
    dose = 100
    dose_dir = recon_dir / f"dose_{dose:03d}"
    
    print(f"Analyzing {dose_dir}...")
    try:
        sp, sa = load_dataset(dose_dir, offset=offset)
    except Exception as e:
        print(f"Failed to load dataset: {e}")
        return

    # Observers
    observers = ['LG_CHO_2D']
    
    # Run
    res = measure_LCD(sp, sa, ground_truth, observers=observers)
    
    # Add metadata
    res['recon'] = recon_name
    res['dose_level'] = dose
    
    print("Results:")
    print(res)
    
    # Save
    res.to_csv('results_demo_01.csv', index=False)
    
    # Plot
    plot_results(res, ylim=[0, 1.1])

if __name__ == '__main__':
    main()
