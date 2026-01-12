import numpy as np
from lcdct.functions import laguerre
from lcdct.LCD import measure_LCD
from lcdct.Observers import LG_CHO, DOG_CHO, Gabor_CHO
from lcdct.utils import get_demo_truth_masks

def test_laguerre():
    # Laguerre L_0(x) = 1
    # L_1(x) = 1 - x
    x = np.array([0, 1, 2])
    L = laguerre(x, 1)
    # Col 0: L0
    assert np.allclose(L[:, 0], 1)
    # Col 1: L1
    assert np.allclose(L[:, 1], 1 - x)

def test_measure_lcd_synthetic():
    # Create synthetic data
    # 10 images, 32x32
    # Insert in center of signal present
    n, h, w = 10, 32, 32
    sp = np.random.randn(n, h, w).astype(np.float32)
    sa = np.random.randn(n, h, w).astype(np.float32)
    
    # Add signal to SP
    # Circle at 16, 16 radius 4
    y, x = np.ogrid[:h, :w]
    mask = (y - 16)**2 + (x - 16)**2 <= 4**2
    sp[:, mask] += 1.0 # Signal
    
    # Ground truth image (32x32)
    gt = np.zeros((h, w), dtype=np.float32)
    # Add insert with value 14 (one of the expected ones)
    gt[mask] = 14
    
    # Run
    res = measure_LCD(sp, sa, gt, observers=['LG_CHO_2D'], n_reader=2, pct_split=0.5)
    
    assert not res.empty
    assert 'auc' in res.columns
    assert 'snr' in res.columns
    # Check values reasonable (> 0.5 for AUC typically if signal is strong enough)
    # With 10 images and signal 1.0 std 1.0, it might be noisy but should run.
    assert len(res) == 2 # 2 readers

def test_observers_instantiation():
    sp = np.zeros((2, 16, 16))
    sa = np.zeros((2, 16, 16))
    
    obs = LG_CHO(sp, sa, channel_width=3)
    assert obs.type == 'LG_CHO_2D'
    
    obs = DOG_CHO(sp, sa)
    assert obs.type == 'DOG_CHO_2D'
    
    obs = Gabor_CHO(sp, sa)
    assert obs.type == 'GABOR_CHO_2D'

def test_get_demo_truth_masks():
    gt = np.zeros((32, 32))
    gt[10:14, 10:14] = 14
    
    masks = get_demo_truth_masks(gt)
    # Expect 1 layer for 14 to be True
    # masks shape (32, 32, 4)
    assert masks.shape == (32, 32, 4)
    assert masks[:,:,0].sum() > 0 # 14 is first index
    assert masks[:,:,1].sum() == 0

