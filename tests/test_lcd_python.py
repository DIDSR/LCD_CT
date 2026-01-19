import pytest
import numpy as np
import pandas as pd
from skimage.draw import disk
from lcdct.LCD import measure_LCD
from lcdct.Observers import LG_CHO, DOG_CHO, Gabor_CHO, NPWE

# --- Fixtures ---

@pytest.fixture
def synthetic_data():
    """Generates synthetic signal-present and signal-absent images."""
    np.random.seed(42)
    n_images = 50
    size = 64
    insert_r = 5
    insert_val = 14  # Must match one of [14, 7, 5, 3] in get_demo_truth_masks

    # Signal Absent: Gaussian Noise
    sa = np.random.normal(0, 10, (n_images, size, size))

    # Signal Present: Noise + Insert
    sp = sa.copy()
    rr, cc = disk((size//2, size//2), insert_r, shape=(size, size))
    sp[:, rr, cc] += insert_val

    # Ground Truth: Single insert at center
    ground_truth = np.zeros((size, size))
    ground_truth[rr, cc] = insert_val

    return sp, sa, ground_truth

# --- Tests ---

def test_measure_lcd_basic(synthetic_data):
    """Test basic functionality with LG_CHO_2D."""
    sp, sa, gt = synthetic_data

    res = measure_LCD(sp, sa, gt, observers=['LG_CHO_2D'], n_reader=2, pct_split=0.5)

    assert isinstance(res, pd.DataFrame)
    assert not res.empty
    assert 'auc' in res.columns
    assert 'snr' in res.columns
    assert 'observer' in res.columns
    # The Observer class name is used in results, which is 'LG_CHO_2D'
    # Observer class names are used: LG_CHO, DOG_CHO, Gabor_CHO, NPWE
    assert 'LG_CHO' in res['observer'].values

def test_all_observers_strings(synthetic_data):
    """Test all observer types passed as strings."""
    sp, sa, gt = synthetic_data
    observers = ['LG_CHO_2D', 'DOG_CHO_2D', 'GABOR_CHO_2D', 'NPWE_2D']

    res = measure_LCD(sp, sa, gt, observers=observers, n_reader=2)

    # Check that we have results for 4 unique observers
    # Note: The observer column will contain the CLASS name (e.g. LG_CHO), not necessarily the input string case
    unique_observers = res['observer'].unique()
    assert len(unique_observers) == 4

    expected_types = ['LG_CHO', 'DOG_CHO', 'Gabor_CHO', 'NPWE']
    for expected in expected_types:
        assert expected in unique_observers

def test_observer_objects(synthetic_data):
    """Test passing observer objects directly."""
    sp, sa, gt = synthetic_data
    # For this test, we create "dummy" objects
    dummy_sp = np.zeros((1, 10, 10))
    dummy_sa = np.zeros((1, 10, 10))

    obs_objects = [
        LG_CHO(dummy_sp, dummy_sa, channel_width=5),
        DOG_CHO(dummy_sp, dummy_sa),
        Gabor_CHO(dummy_sp, dummy_sa),
        NPWE(dummy_sp, dummy_sa)
    ]

    res = measure_LCD(sp, sa, gt, observers=obs_objects, n_reader=2)

    assert len(res['observer'].unique()) == 4
    assert 'LG_CHO' in res['observer'].unique()

def test_input_validation():
    """Test error handling for invalid inputs."""
    # 2D input instead of 3D
    sp = np.zeros((10, 10))
    sa = np.zeros((10, 10))
    gt = np.zeros((10, 10))

    with pytest.raises(ValueError, match="must be 3D"):
        measure_LCD(sp, sa, gt)

def test_no_inserts(synthetic_data):
    """Test behavior when no inserts are found in ground truth."""
    sp, sa, _ = synthetic_data
    gt = np.zeros_like(sp[0]) # Empty ground truth

    res = measure_LCD(sp, sa, gt)

    assert isinstance(res, pd.DataFrame)
    assert res.empty

def test_invalid_observer_name(synthetic_data):
    sp, sa, gt = synthetic_data
    with pytest.raises(ValueError, match="Unknown observer"):
        measure_LCD(sp, sa, gt, observers=['INVALID_NAME'])
