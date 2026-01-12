from pathlib import Path
import numpy as np
import SimpleITK as sitk
from skimage.measure import label, regionprops
from skimage.transform import hough_circle, hough_circle_peaks
from skimage.feature import canny
from skimage.draw import disk
from scipy.ndimage import median_filter
from typing import Tuple, Union, Optional

def read_mhd(filename: Union[str, Path]) -> np.ndarray:
    """
    Read an MHD/MHA file using SimpleITK.
    Returns: numpy array (Z, Y, X)
    """
    img = sitk.ReadImage(str(filename))
    return sitk.GetArrayFromImage(img)

def write_mhd(filename: Union[str, Path], array: np.ndarray, offset: int = 0) -> None:
    """Writes a numpy array to an MHD file.

    Args:
        filename: Path to the output MHD file.
        array: Numpy array to write.
        offset: Offset value (unused in current implementation, kept for compatibility).
    """
    img = sitk.GetImageFromArray(array)
    sitk.WriteImage(img, str(filename))

def get_insert_radius(truth_mask: np.ndarray) -> float:
    """Gets the diameter of inserts from a binary mask.

    Note: The function name implies radius, but it returns the maximum dimension of the bounding box,
    effectively the diameter, to match legacy MATLAB behavior.

    Args:
        truth_mask: Binary mask of the insert.

    Returns:
        float: Diameter of the insert (max bounding box dimension), or 0 if no region found.
    """
    lbl = label(truth_mask > 0)
    regions = regionprops(lbl)
    if not regions:
        return 0.0
    # Assuming circular inserts, max dimension of bounding box is approx diameter
    return max(regions[0].bbox[2] - regions[0].bbox[0], regions[0].bbox[3] - regions[0].bbox[1])

def get_roi_from_truth_mask(truth_mask: np.ndarray, img: np.ndarray, nx: Optional[int] = None) -> Optional[np.ndarray]:
    """Crops image around the centroid of the truth mask.

    Args:
        truth_mask: 2D binary mask (or 3D with 1 slice).
        img: 3D image stack (Z, Y, X) or 2D image.
        nx: Half-width of crop (result size will be approx 2*nx + 1). 
            If None, defaults to half the bounding box width. 
            Note: If passed, effective width is nx (legacy behavior parity).

    Returns:
        np.ndarray: Cropped image region, or None if no regions found in mask.
    """
    lbl = label(truth_mask > 0)
    regions = regionprops(lbl)
    if not regions:
        return None 
    
    centroid = regions[0].centroid # (row, col) -> (y, x)
    cy, cx = int(round(centroid[0])), int(round(centroid[1]))
    
    if nx is None:
        # Default to bounding box radius
        height = regions[0].bbox[2] - regions[0].bbox[0]
        width = regions[0].bbox[3] - regions[0].bbox[1]
        ny = int(round(height / 2))
        nx = int(round(width / 2))
    else:
        # nx is passed as full width in MATLAB legacy
        nx = int(round(nx / 2))
        ny = nx
        
    y_slice = slice(max(0, cy - ny), cy + ny + 1)
    x_slice = slice(max(0, cx - nx), cx + nx + 1)
    
    if img.ndim == 3:
        # Assuming (Z, Y, X)
        return img[:, y_slice, x_slice]
    else:
        return img[y_slice, x_slice]

from skimage.transform import hough_circle, hough_circle_peaks
from skimage.feature import canny
from skimage.draw import disk
import pandas as pd

def find_insert_centers(image: np.ndarray, smoothing_window_size: int = 11, search_range: Tuple[int, int] = (7, 22)) -> np.ndarray:
    """Finds circular inserts in the image and creates a ground truth mask.

    Args:
        image: 2D numpy array (signal present image).
        smoothing_window_size: Size of smoothing window (unused in current implementation).
        search_range: Tuple of (min_radius, max_radius) for circle detection.

    Returns:
        np.ndarray: Mask with assigned HU values for detected inserts.
    """
    # Normalize image for processing
    img_norm = (image - image.min()) / (image.max() - image.min())
    
    # Edge detection
    edges = canny(img_norm, sigma=3)
    
    # Hough circle transform
    hough_radii = np.arange(search_range[0], search_range[1], 2) # check every 2 pixels
    hough_res = hough_circle(edges, hough_radii)
    
    # Select the most prominent circles
    # We expect 4 inserts usually.
    accums, cx, cy, radii = hough_circle_peaks(hough_res, hough_radii, total_num_peaks=4, min_xdistance=20, min_ydistance=20)
    
    # Create mask
    mask = np.zeros_like(image, dtype=np.float32)
    
    # Known HU values sorted by radius size (smallest to largest)
    known_HUs = [14, 7, 5, 3] 
    
    # Sort found circles by radius
    circles = sorted(zip(cx, cy, radii), key=lambda x: x[2])
    
    # Use as many HUs as we have circles, or trunc
    current_HUs = known_HUs[:len(circles)]
    
    for (cx_i, cy_i, r_i), hu in zip(circles, current_HUs):
        rr, cc = disk((cy_i, cx_i), r_i, shape=image.shape)
        mask[rr, cc] = hu
        
    return mask

def approximate_groundtruth(base_directory: Union[str, Path], ground_truth_filename: str = 'ground_truth.mhd', offset: int = 1000) -> np.ndarray:
    """Estimates ground truth from repeat scans.

    Args:
        base_directory: Base directory containing 'signal_present' and 'signal_absent' subdirectories.
        ground_truth_filename: Filename of the ground truth file (unused in logic, refers to source structure).
        offset: HU offset to subtract.

    Returns:
        np.ndarray: Estimated ground truth mask.
    """
    base_dir = Path(base_directory)
    sp_dir = base_dir / 'dose_100' / 'signal_present'
    sa_dir = base_dir / 'dose_100' / 'signal_absent'
    
    sp_path = sp_dir / 'signal_present.mhd'
    sa_path = sa_dir / 'signal_absent.mhd'
    
    # Read images
    sp_img = read_mhd(sp_path).astype(np.float32) - offset
    sa_img = read_mhd(sa_path).astype(np.float32) - offset
    
    low_noise_signal = np.mean(sp_img, axis=0) - np.mean(sa_img, axis=0)
    
    return find_insert_centers(low_noise_signal)

def get_demo_truth_masks(xtrue: np.ndarray, tol: int = 1) -> np.ndarray:
    """Generates truth masks for known HU values [14, 7, 5, 3].

    Args:
        xtrue: Ground truth image.
        tol: Tolerance for HU value matching.

    Returns:
        np.ndarray: Stacked boolean masks (Y, X, N_inserts).
    """
    roi_HUs = [14, 7, 5, 3]
    truth_masks = []
    
    for hu in roi_HUs:
        # abs diff < tol
        mask = np.abs(xtrue - hu) < tol
        # Median filter to clean up (parroting MATLAB medfilt2 default kernel 3x3)
        mask = median_filter(mask, size=3)
        truth_masks.append(mask)
        
    if not truth_masks:
        return np.zeros(xtrue.shape + (0,), dtype=bool)
        
    return np.stack(truth_masks, axis=-1)

def load_dataset(base_dir: Union[str, Path], offset: int = 0) -> Tuple[np.ndarray, np.ndarray]:
    """Loads signal present and signal absent images from a directory.

    Expected structure:
      base_dir/signal_present/signal_present.mhd (or raw images)
      base_dir/signal_absent/signal_absent.mhd (or raw images)

    Args:
        base_dir: Path to the dataset directory.
        offset: Value to subtract from image data (e.g. 1000).

    Returns:
        Tuple[np.ndarray, np.ndarray]: Tuple of (signal_present_array, signal_absent_array).
        
    Raises:
        FileNotFoundError: If directory structure or files are missing.
        ValueError: If images cannot be loaded.
    """
    base = Path(base_dir)
    sp_dir = base / 'signal_present'
    sa_dir = base / 'signal_absent'
    
    if not sp_dir.exists() or not sa_dir.exists():
        raise FileNotFoundError(f"Directory structure not found in {base_dir}")
        
    def load_imgs(d, name_hint):
        # Try mhd first
        mhd_file = d / f"{name_hint}.mhd"
        if mhd_file.exists():
            return read_mhd(mhd_file)
        
        # Try finding *any* mhd
        mhds = list(d.glob("*.mhd"))
        if mhds:
            return read_mhd(mhds[0])
            
        # Fallback to loading all files (sorted)
        # Assuming simple image files if no mhd
        files = sorted([f for f in d.iterdir() if f.is_file() and not f.name.startswith('.')])
        if not files:
            raise FileNotFoundError(f"No files found in {d}")
            
        imgs = []
        for f in files:
            try:
                img = sitk.ReadImage(str(f))
                arr = sitk.GetArrayFromImage(img)
                # arr might be 2D or 3D (1 slice).
                imgs.append(arr)
            except Exception:
                continue
                
        if not imgs:
            raise ValueError(f"Could not load images from {d}")
            
        # Stack
        return np.stack(imgs, axis=0).squeeze() # Adjust dims if needed

    sp_arr = load_imgs(sp_dir, 'signal_present').astype(np.float32) - offset
    sa_arr = load_imgs(sa_dir, 'signal_absent').astype(np.float32) - offset
    
    # Ensure 3D (N, Y, X)
    if sp_arr.ndim == 2:
        sp_arr = sp_arr[np.newaxis, ...]
    if sa_arr.ndim == 2:
        sa_arr = sa_arr[np.newaxis, ...]
        
    return sp_arr, sa_arr



