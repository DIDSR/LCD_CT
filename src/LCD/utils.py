from pathlib import Path
import numpy as np
import SimpleITK as sitk
from skimage.measure import label, regionprops

def read_mhd(filename):
    """
    Read an MHD/MHA file using SimpleITK.
    Returns: numpy array (Z, Y, X)
    """
    img = sitk.ReadImage(str(filename))
    return sitk.GetArrayFromImage(img)

def write_mhd(filename, array, offset=0):
    """
    Write a numpy array to MHD file.
    """
    img = sitk.GetImageFromArray(array)
    sitk.WriteImage(img, str(filename))

def get_insert_radius(truth_mask):
    """
    Get radii of inserts from a binary mask.
    """
    lbl = label(truth_mask > 0)
    regions = regionprops(lbl)
    if not regions:
        return 0
    # Assuming circular inserts, max dimension of bounding box is approx diameter
    # Returning radius (max_dim / 2)
    # The MATLAB code returned max(BoundingBox(3:4)), which is width/height.
    # It didn't divide by 2 in `get_insert_radius.m` (lines 1-4), but in `measure_LCD.m` it seemed to treat it as a scale.
    # Wait, `get_insert_radius.m` returned max(bbox(3:4)) which is diameter?
    # No, the function is named `get_insert_radius`, but the code returns `max(shape_info.BoundingBox(3:4))`.
    # BoundingBox(3) is width, (4) is height.
    # So it returns diameter. Let's verify usage in `measure_LCD.m`.
    # line 75: `insert_r = get_insert_radius(truth_mask);`
    # line 96: `model_observer.channel_width = 2/3*insert_r;`
    # line 123: `insert_diameter_pix = [insert_diameter_pix; 2*insert_r];`
    # If insert_r was diameter, then line 123 would be 2 * diameter.
    # If insert_r is radius...
    # `LG_CHO` typically uses channel width related to radius.
    # If `get_insert_radius` returns Diameter, then `2*insert_r` is `2*Diameter`. That seems odd for a diameter tracker.
    # BUT, if `get_insert_radius` returns diameter, then line 96 uses 2/3 * diameter.
    # Let's assume the name is slightly misleading and it returns diameter/size, OR check usage more carefully.
    # In `measure_LCD.m`, `insert_rs` collects them.
    # In `get_ROI_from_truth_mask.m`: `ny = round(roi_properties.BoundingBox(3)/2);` -> this is half-width (radius).
    # I will stick to returning the max bbox dimension (Diameter) to match MATLAB behaviour of `get_insert_radius` function body,
    # but I'll document it clearly.
    # Actually, let's call it `get_insert_diameter` or keep parity. I will keep parity but might rename internally if clearer.
    # Let's look at `get_insert_radius.m` again. 
    #   r = max(shape_info.BoundingBox(3:4));
    # That is definitely the full extent (diameter).
    return max(regions[0].bbox[2] - regions[0].bbox[0], regions[0].bbox[3] - regions[0].bbox[1])

def get_roi_from_truth_mask(truth_mask, img, nx=None):
    """
    Crop image around the centroid of the truth mask.
    mask: 2D binary mask (or 3D with 1 slice?)
    img: 3D image stack (Z, Y, X) or 2D image.
    nx: half-width of crop (result size will be 2*nx + 1 approx)
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
        # nx is passed as full width in MATLAB (wait, let's check input of `get_ROI_from_truth_mask`)
        # MATLAB: nx passed, then `nx = round(nx / 2);`
        # So input nx is effectively "width of crop region"?
        # In measure_LCD.m: `sp_imgs = get_ROI_from_truth_mask(..., 2*crop_r)`
        # `crop_r` was `max(insert_rs)` (where insert_rs came from get_insert_radius, so Diameters)
        # So `2 * crop_r` passed in. -> `2 * Diameter`.
        # Inside function: `nx = round(nx / 2)` -> `Diameter`.
        # Then crop is `x - nx : x + nx`.
        # So total width is `2 * nx` -> `2 * Diameter`.
        # This makes the ROI 2x the lesion size.
        
        # In Python:
        nx = int(round(nx / 2))
        ny = nx
        
    # Handling 3D img vs 2D img
    # MATLAB: `cropped_img = img(x - nx: x + nx, y - ny: y + ny, :);`
    # Note: MATLAB is (row, col) for indices usually, but X/Y often swapped.
    # `x = round(roi_properties.Centroid(2));` -> Centroid(2) is X-coordinate (column).
    # `img(x - nx: x + nx, ...)` -> First dim is rows? usually Y?
    # If X is Centroid(2), and used on first dimension...
    # `img(rows, cols)`
    # So `img(x-nx..., y-ny...)` implies x is row index?
    # BUT Centroid(2) is typically X (horizontal, column).
    # This suggests the MATLAB code might be treating images as (X, Y) or Transposed? 
    # Or strict simple matrix indexing: (row, col). Centroid(1) is row (y), Centroid(2) is col (x).
    # The MATLAB code lines 14-15:
    # y = round(roi_properties.Centroid(1));
    # x = round(roi_properties.Centroid(2));
    # Line 25: `img(x - nx: x + nx, y - ny: y + ny, :)`
    # This uses 'x' (col center) for the first dimension (row index). 
    # And 'y' (row center) for the second dimension (col index).
    # This effectively TRANSPOIES the crop or expects transposed image?
    # `LCD.py` does `signal_present.transpose(1, 2, 0)` before calling octave.
    # signal_present usually (Z, Y, X). Transpose(1, 2, 0) -> (Y, X, Z).
    # So Octave receives (Rows, Cols, Slices).
    # If code uses `x` (Centroid(2)=Col) for dim 1 (Rows)... that is a swap.
    # I will trust standard Python orientation (Z, Y, X) or (Y, X).
    # I will strictly implement "Crop around centroid".
    # And handle dimensions clearly.
    
    # img is likely (Z, Y, X) or (Y, X).
    # We want to crop in Y and X.
    
    y_slice = slice(max(0, cy - ny), cy + ny + 1) # python exclusive end
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

def find_insert_centers(image, smoothing_window_size=11, search_range=(7, 22)):
    """
    Find circular inserts in the image and create a ground truth mask.
    image: 2D numpy array (signal present image)
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
    
    # If we didn't find 4, maybe we found fewer or more.
    # The MATLAB code asks for user confirmation. We will just proceed with what we found or top 4.
    
    # Create mask
    mask = np.zeros_like(image, dtype=np.float32)
    
    # Known HU values sorted by radius size (smallest to largest)
    # MATLAB: [14, 7, 5, 3] for radii sorted smallest to largest?
    # The MATLAB code: T_sorted = sortrows(T, 'radii'); known_HUs = [14, 7, 5, 3];
    # So the SMALLEST radius gets 14 HU. Largest gets 3 HU.
    known_HUs = [14, 7, 5, 3] # Check if this matches logic.
    # If we found fewer than 4, we might have issues matching. 
    # For now, we'll zip them.
    
    # Sort found circles by radius
    circles = sorted(zip(cx, cy, radii), key=lambda x: x[2])
    
    # Use as many HUs as we have circles, or trunc
    current_HUs = known_HUs[:len(circles)]
    
    for (cx_i, cy_i, r_i), hu in zip(circles, current_HUs):
        rr, cc = disk((cy_i, cx_i), r_i, shape=image.shape)
        mask[rr, cc] = hu
        
    return mask

def approximate_groundtruth(base_directory, ground_truth_filename='ground_truth.mhd', offset=1000):
    """
    Estimate ground truth from repeat scans.
    """
    base_dir = Path(base_directory)
    sp_dir = base_dir / 'dose_100' / 'signal_present'
    sa_dir = base_dir / 'dose_100' / 'signal_absent'
    
    # Assuming mhd files exist that point to the volume of repeats, 
    # OR we read individual raw files if mhd points to one.
    # approximate_groundtruth.m reads 'signal_present.mhd' which presumably contains the volume stack.
    
    sp_path = sp_dir / 'signal_present.mhd'
    sa_path = sa_dir / 'signal_absent.mhd'
    
    # Read images
    # mhd_read_image in MATLAB subtracts offset.
    sp_img = read_mhd(sp_path).astype(np.float32) - offset
    sa_img = read_mhd(sa_path).astype(np.float32) - offset
    
    # Mean across replicates (axis 0 is typically Z/replicates in this context if they are stacked)
    # The MATLAB code: `mean(sp_raw_array, 3)` implies 3rd dimension is replicates/slices.
    # If `read_mhd` returns (Z, Y, X), then axis 0 is Z.
    # If the Z dimension stores the replicates, we take mean over axis 0.
    
    low_noise_signal = np.mean(sp_img, axis=0) - np.mean(sa_img, axis=0)
    
    # Identify center slice or use the resulting 2D mean image?
    # If the result is 3D (volumetric mean), `find_insert_centers` expects 2D?
    # MATLAB `find_insert_centers` takes `signal_present_image`.
    # `approximate_groundtruth` calls `find_insert_centers(low_noise_signal)`.
    # If `low_noise_signal` is 2D, we are good.
    # If the original was (Replicates, Y, X), mean is (Y, X).
    # If original was (Z, Y, X) and it's a volume...
    # The MATLAB code `mean(..., 3)` implies the stack is in 3rd dim.
    # Usually in medical imaging, Z is slices. If they scan the phantom repeatedly, they might stack them in Z.
    
    ground_truth = find_insert_centers(low_noise_signal)
    
from scipy.ndimage import median_filter

def get_demo_truth_masks(xtrue, tol=1):
    """
    Generate truth masks for known HU values [14, 7, 5, 3].
    """
    roi_HUs = [14, 7, 5, 3]
    truth_masks = []
    
    for hu in roi_HUs:
        # abs diff < tol
        mask = np.abs(xtrue - hu) < tol
        # Median filter to clean up (parroting MATLAB medfilt2 default kernel 3x3)
        mask = median_filter(mask, size=3)
        truth_masks.append(mask)
        
    # Stack along new axis (H, W, N) to match MATLAB shape (X, Y, N) or (H, W, N)
    if not truth_masks:
        return np.zeros(xtrue.shape + (0,), dtype=bool)
        
    return np.stack(truth_masks, axis=-1)

def load_dataset(base_dir, offset=0):
    """
    Load signal present and signal absent images from a directory.
    Expected structure:
      base_dir/signal_present/signal_present.mhd (or raw images)
      base_dir/signal_absent/signal_absent.mhd (or raw images)
    
    Returns: (signal_present_array, signal_absent_array)
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



