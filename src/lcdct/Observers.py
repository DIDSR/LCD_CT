from pathlib import Path
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score
from scipy.linalg import pinv
import pandas as pd
from typing import Union, List, Optional, Tuple, Dict, Any
from .functions import laguerre_gaussian_2d

class Observer:
    """Base class for Model Observers."""
    
    def __init__(self, signal_present: np.ndarray, signal_absent: np.ndarray):
        """Initialize the observer with signal-present and signal-absent images.

        Args:
            signal_present: Array of signal-present images (N, Y, X) or (N,).
            signal_absent: Array of signal-absent images (N, Y, X) or (N,).
        """
        # subtract DC component
        if signal_present.ndim == 3:
            # (N, Y, X)
             self.signal_present = signal_present - signal_present.mean(axis=(1, 2), keepdims=True)
             self.signal_absent = signal_absent - signal_absent.mean(axis=(1, 2), keepdims=True)
        else:
            self.signal_present = signal_present - signal_present.mean()
            self.signal_absent = signal_absent - signal_absent.mean()

    def __repr__(self) -> str:
        return f'''{self.__class__.__name__}
signal present array shape [n, y, x]: {self.signal_present.shape}
signal absent array shape [n, y, x]:  {self.signal_absent.shape}'''

    def perform_study(self, signal_absent_train: np.ndarray, signal_present_train: np.ndarray,
                      signal_absent_test: np.ndarray, signal_present_test: np.ndarray) -> Dict[str, float]:
        """Performs the observer study (train/test) and calculates metrics.

        Args:
           signal_absent_train: Training signal-absent images.
           signal_present_train: Training signal-present images.
           signal_absent_test: Testing signal-absent images.
           signal_present_test: Testing signal-present images.

        Returns:
            Dict[str, float]: Dictionary containing metrics 'auc' and 'snr'.
        """
        # Renamed calculate_auc to perform_study to match MATLAB `measure_LCD` call:
        return self.calculate_metrics(signal_absent_train, signal_present_train,
                                      signal_absent_test, signal_present_test)

    def get_splits(self, pct_split: float = 0.5, seed: Optional[int] = None) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        """Splits data into training and testing sets.

        Args:
            pct_split: Percentage of data to use for training.
            seed: Random seed for splitting.

        Returns:
            Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]: 
                (sa_train, sa_test, sp_train, sp_test).
        """
        sp_train, sp_test = train_test_split(self.signal_present, train_size=pct_split, shuffle=True, random_state=seed)
        sa_train, sa_test = train_test_split(self.signal_absent, train_size=pct_split, shuffle=True, random_state=seed)
        return sa_train, sa_test, sp_train, sp_test

    def run_study(self, n_readers: int = 10, pct_split: float = 0.5, seed: list = None) -> pd.DataFrame:
        """Runs multiple bootstraps/splits of the study.

        Args:
            n_readers: Number of random splits (readers).
            pct_split: Percentage of data used for training.
            seed: List of seeds for each reader, or None.

        Returns:
            pd.DataFrame: Results dataframe with cols 'auc', 'snr', 'observer', 'reader'.
        """
        rng = np.random.default_rng(seed=seed)
        # Seeds for each reader
        seed_split = rng.integers(0, 100000, size=n_readers)
        
        results = []
        for reader in range(n_readers):
            sa_train, sa_test, sp_train, sp_test = self.get_splits(pct_split=pct_split, seed=seed_split[reader])
            res = self.perform_study(sa_train, sp_train, sa_test, sp_test)
            res['observer'] = self.__class__.__name__
            res['reader'] = reader
            results.append(res)
            
        return pd.DataFrame(results)

    def calculate_metrics(self, sa_train: np.ndarray, sp_train: np.ndarray, sa_test: np.ndarray, sp_test: np.ndarray) -> Dict[str, float]:
        """Calculates AUC and SNR metrics. Must be implemented by subclasses.

        Args:
            sa_train: Training signal-absent images.
            sp_train: Training signal-present images.
            sa_test: Testing signal-absent images.
            sp_test: Testing signal-present images.

        Returns:
            Dict[str, float]: Dictionary with 'auc' and 'snr'.
        """
        raise NotImplementedError


class LG_CHO(Observer):
    """Laguerre-Gaussian Channelized Hotelling Observer."""
    
    def __init__(self, signal_present: np.ndarray, signal_absent: np.ndarray, channel_width: float, n_channels: int = 5):
        """Initializes the LG_CHO observer.

        Args:
            signal_present: Training signal-present images.
            signal_absent: Training signal-absent images.
            channel_width: Gaussian width parameter for Laguerre-Gaussian channels.
            n_channels: Number of channels.
        """
        super().__init__(signal_present, signal_absent)
        self.channel_width = channel_width
        self.n_channels = n_channels
        self.type = 'LG_CHO_2D'

    def calculate_metrics(self, trimg_sa: np.ndarray, trimg_sp: np.ndarray, testimg_sa: np.ndarray, testimg_sp: np.ndarray) -> Dict[str, float]:
        """Calculates CHO metrics using Laguerre-Gaussian channels.

        Args:
           trimg_sa: Training signal-absent images (N, Y, X).
           trimg_sp: Training signal-present images (N, Y, X).
           testimg_sa: Testing signal-absent images (N, Y, X).
           testimg_sp: Testing signal-present images (N, Y, X).

        Returns:
            Dict[str, float]: AUC and SNR.
        """
        n_sa, ny, nx = trimg_sa.shape
        # Assuming images are (N, Y, X)
        
        # LG channels
        # Coordinate system centered
        xi = np.arange(nx) - (nx - 1) / 2
        yi = np.arange(ny) - (ny - 1) / 2
        xxi, yyi = np.meshgrid(xi, yi) # Note: meshgrid default is 'xy' -> xxi corresponds to columns (x), yyi to rows (y)
        r = np.sqrt(xxi**2 + yyi**2)
        
        u = laguerre_gaussian_2d(r, self.n_channels - 1, self.channel_width)
        # u shape: (ny, nx, nch)
        
        ch = u.reshape(nx * ny, self.n_channels)
        
        # Training
        # Flatten images: (N, Y*X)
        tr_sa_flat = trimg_sa.reshape(trimg_sa.shape[0], -1)
        tr_sp_flat = trimg_sp.reshape(trimg_sp.shape[0], -1)
        
        # Project onto channels: (N, nch)
        tr_sa_ch = tr_sa_flat @ ch
        tr_sp_ch = tr_sp_flat @ ch
        
        # Mean stats
        s_ch = np.mean(tr_sp_ch, axis=0) - np.mean(tr_sa_ch, axis=0) # (nch,)
        
        k_sa = np.cov(tr_sa_ch, rowvar=False)
        k_sp = np.cov(tr_sp_ch, rowvar=False)
        k = (k_sa + k_sp) / 2
        
        # Hotelling template in Channel Space
        # w_ch = inv(K) * s_ch
        w_ch = s_ch @ pinv(k) # (nch,)
        
        # Testing
        te_sa_flat = testimg_sa.reshape(testimg_sa.shape[0], -1)
        te_sp_flat = testimg_sp.reshape(testimg_sp.shape[0], -1)
        
        te_sa_ch = te_sa_flat @ ch
        te_sp_ch = te_sp_flat @ ch
        
        # Decision variables
        t_sa = te_sa_ch @ w_ch
        t_sp = te_sp_ch @ w_ch
        
        # Metrics
        snr = (np.mean(t_sp) - np.mean(t_sa)) / np.sqrt((np.std(t_sp, ddof=1)**2 + np.std(t_sa, ddof=1)**2) / 2)
        
        # ROC AUC
        y_true = np.concatenate([np.zeros(len(t_sa)), np.ones(len(t_sp))])
        y_scores = np.concatenate([t_sa, t_sp])
        auc = roc_auc_score(y_true, y_scores)
        
        return {'auc': auc, 'snr': snr}


class DOG_CHO(Observer):
    """Difference of Gaussian Channelized Hotelling Observer."""
    
    def __init__(self, signal_present: np.ndarray, signal_absent: np.ndarray, type: str = 'dense'):
        """Initializes the DOG_CHO observer.

        Args:
           signal_present: Training signal-present images.
           signal_absent: Training signal-absent images.
           type: 'dense' or 'sparse'.
        """
        super().__init__(signal_present, signal_absent)
        self.dog_type = type
        self.type = 'DOG_CHO_2D'

    def calculate_metrics(self, trimg_sa: np.ndarray, trimg_sp: np.ndarray, testimg_sa: np.ndarray, testimg_sp: np.ndarray) -> Dict[str, float]:
        """Calculates CHO metrics using Difference-of-Gaussian channels.

        Args:
           trimg_sa: Training signal-absent images (N, Y, X).
           trimg_sp: Training signal-present images (N, Y, X).
           testimg_sa: Testing signal-absent images (N, Y, X).
           testimg_sp: Testing signal-present images (N, Y, X).

        Returns:
            Dict[str, float]: AUC and SNR.

        Raises:
            ValueError: If an unknown DOG type is specified.
        """
        n_sa, ny, nx = trimg_sa.shape
        
        # Build DOG channels
        fi = (np.arange(nx) - (nx - 1) / 2) / nx
        fx, fy = np.meshgrid(fi, fi)
        fxy = fx**2 + fy**2
        
        if self.dog_type == 'dense':
            a0, a, Q, nch = 0.005, 1.4, 1.67, 10
        elif self.dog_type == 'sparse':
            a0, a, Q, nch = 0.015, 2.0, 2.0, 3
        else:
            raise ValueError(f"Unknown DOG type: {self.dog_type}")
            
        sdog_list = []
        for i in range(1, nch + 1): # 1 to nch
            aj = a0 * (a**(i - 1))
            # aj1 = a0 * (a**i) # Unused in MATLAB code loop? actually used for next band implicitly but equation uses `aj`
            
            exp1 = np.exp(-fxy / (Q * aj)**2 / 2) # Note: MATLAB (Q*aj)^2/2
            exp2 = np.exp(-fxy / aj**2 / 2)
            sdogfreq = exp1 - exp2
            
            # ifftshift, ifft2, fftshift
            sdog_spatial = np.fft.fftshift(np.fft.ifft2(np.fft.ifftshift(sdogfreq)))
            sdog_list.append(sdog_spatial.real) # Should be real
            
        ch = np.stack(sdog_list, axis=-1).reshape(nx * ny, nch)
        
        # Training
        tr_sa_flat = trimg_sa.reshape(trimg_sa.shape[0], -1)
        tr_sp_flat = trimg_sp.reshape(trimg_sp.shape[0], -1)
        
        tr_sa_ch = tr_sa_flat @ ch
        tr_sp_ch = tr_sp_flat @ ch
        
        s_ch = np.mean(tr_sp_ch, axis=0) - np.mean(tr_sa_ch, axis=0)
        k = (np.cov(tr_sa_ch, rowvar=False) + np.cov(tr_sp_ch, rowvar=False)) / 2
        w_ch = s_ch @ pinv(k)
        
        # Testing
        te_sa_flat = testimg_sa.reshape(testimg_sa.shape[0], -1)
        te_sp_flat = testimg_sp.reshape(testimg_sp.shape[0], -1)
        
        te_sa_ch = te_sa_flat @ ch
        te_sp_ch = te_sp_flat @ ch
        
        t_sa = te_sa_ch @ w_ch
        t_sp = te_sp_ch @ w_ch
        
        snr = (np.mean(t_sp) - np.mean(t_sa)) / np.sqrt((np.std(t_sp, ddof=1)**2 + np.std(t_sa, ddof=1)**2) / 2)
        
        y_true = np.concatenate([np.zeros(len(t_sa)), np.ones(len(t_sp))])
        y_scores = np.concatenate([t_sa, t_sp])
        auc = roc_auc_score(y_true, y_scores)
        
        return {'auc': auc, 'snr': snr}


class Gabor_CHO(Observer):
    """Gabor Channelized Hotelling Observer."""
    
    def __init__(self, signal_present: np.ndarray, signal_absent: np.ndarray, nband: int = 4, ntheta: int = 4, phase: Union[int, List[int]] = 0):
        """Initializes the Gabor_CHO observer.

        Args:
            signal_present: Training signal-present images.
            signal_absent: Training signal-absent images.
            nband: Number of frequency bands.
            ntheta: Number of orientations.
            phase: Phase value or list of phases.
        """
        super().__init__(signal_present, signal_absent)
        self.nband = nband
        self.ntheta = ntheta
        self.phase = [phase] if np.isscalar(phase) else phase
        self.type = 'GABOR_CHO_2D'

    def calculate_metrics(self, trimg_sa: np.ndarray, trimg_sp: np.ndarray, testimg_sa: np.ndarray, testimg_sp: np.ndarray) -> Dict[str, float]:
        """Calculates CHO metrics using Gabor channels.

        Args:
           trimg_sa: Training signal-absent images (N, Y, X).
           trimg_sp: Training signal-present images (N, Y, X).
           testimg_sa: Testing signal-absent images (N, Y, X).
           testimg_sp: Testing signal-present images (N, Y, X).

        Returns:
            Dict[str, float]: AUC and SNR.
        """
        n_sa, ny, nx = trimg_sa.shape
        
        xi = np.arange(nx) - (nx - 1) / 2
        yi = np.arange(ny) - (ny - 1) / 2
        xxi, yyi = np.meshgrid(xi, yi)
        r2 = xxi**2 + yyi**2
        
        theta_list = np.arange(0, np.pi, np.pi / self.ntheta)
        f0 = 1/8.0
        
        gb_channels = []
        
        for i in range(self.nband):
            f1 = f0 / 2
            fc = (f0 + f1) / 2
            wf = f0 - f1
            ws = 4 * np.log(2) / (np.pi * wf)
            amp = np.exp(-4 * np.log(2) * r2 / ws**2)
            
            for theta_val in theta_list:
                for ph in self.phase:
                    # cos(2*pi*fc*(x*cos + y*sin) + ph)
                    # MATLAB: xxi*cos + yyi*sin
                    fcos = np.cos(2 * np.pi * fc * (xxi * np.cos(theta_val) + yyi * np.sin(theta_val)) + ph)
                    u = amp * fcos
                    gb_channels.append(u)
            
            f0 = f1
            
        # Stack channels
        ch_stack = np.stack(gb_channels, axis=-1)
        nch = ch_stack.shape[-1]
        ch = ch_stack.reshape(nx * ny, nch)
        
        # Training and Testing same as generic CHO
        tr_sa_flat = trimg_sa.reshape(trimg_sa.shape[0], -1)
        tr_sp_flat = trimg_sp.reshape(trimg_sp.shape[0], -1)
        
        tr_sa_ch = tr_sa_flat @ ch
        tr_sp_ch = tr_sp_flat @ ch
        
        s_ch = np.mean(tr_sp_ch, axis=0) - np.mean(tr_sa_ch, axis=0)
        k = (np.cov(tr_sa_ch, rowvar=False) + np.cov(tr_sp_ch, rowvar=False)) / 2
        w_ch = s_ch @ pinv(k)
        
        te_sa_flat = testimg_sa.reshape(testimg_sa.shape[0], -1)
        te_sp_flat = testimg_sp.reshape(testimg_sp.shape[0], -1)
        
        te_sa_ch = te_sa_flat @ ch
        te_sp_ch = te_sp_flat @ ch
        
        t_sa = te_sa_ch @ w_ch
        t_sp = te_sp_ch @ w_ch
        
        snr = (np.mean(t_sp) - np.mean(t_sa)) / np.sqrt((np.std(t_sp, ddof=1)**2 + np.std(t_sa, ddof=1)**2) / 2)
        
        y_true = np.concatenate([np.zeros(len(t_sa)), np.ones(len(t_sp))])
        y_scores = np.concatenate([t_sa, t_sp])
        auc = roc_auc_score(y_true, y_scores)
        
        return {'auc': auc, 'snr': snr}


class NPWE(Observer):
    """Non-Prewhitening Eye Model Observer."""
    
    def __init__(self, signal_present: np.ndarray, signal_absent: np.ndarray, eye: bool = False):
        """Initializes the NPWE observer.

        Args:
            signal_present: Training signal-present images.
            signal_absent: Training signal-absent images.
            eye: Boolean, whether to use the eye filter.
        """
        super().__init__(signal_present, signal_absent)
        self.eye = eye
        self.type = 'NPWE_2D'

    def calculate_metrics(self, trimg_sa: np.ndarray, trimg_sp: np.ndarray, testimg_sa: np.ndarray, testimg_sp: np.ndarray) -> Dict[str, float]:
        """Calculates NPWE metrics.

        Args:
           trimg_sa: Training signal-absent images (only used for mean signal).
           trimg_sp: Training signal-present images (only used for mean signal).
           testimg_sa: Testing signal-absent images.
           testimg_sp: Testing signal-present images.

        Returns:
            Dict[str, float]: AUC and SNR.
        """
        n_sa, ny, nx = trimg_sa.shape
        
        # Eye filter
        # disp_dx = 54/128 # mm
        # fi = ...
        # f_ratio = 1/0.1146
        
        disp_dx = 54.0 / 128.0
        fi = (np.arange(nx) - (nx - 1) / 2) / (nx - 1) / disp_dx
        fx, fy = np.meshgrid(fi, fi)
        f_ratio = 1.0 / 0.1146
        fxy = (fx**2 + fy**2) * f_ratio**2
        
        beta = 1.3
        c = 0.04
        
        if self.eye:
            eyeflt = (fxy**(beta / 2)) * np.exp(-c * fxy)
        else:
            eyeflt = np.ones((ny, nx)) / (nx * ny) # MATLAB: ones(nx,ny)/nx/ny
            # Wait, MATLAB: `ones(nx, ny)/nx/ny`
            # This scale factor 1/(nx*ny) might be important for normalization?
            # Or is it an artifact of FFT implementation?
            # The MATLAB code comments say "equivalent to no filtering by setting 'eyeflt' to ones."
            # But line 67 says `ones(nx, ny)/nx/ny`.
            # I will follow MATLAB logic strictly.
            
        # Training (mean signal)
        # s_eye = fftshift(fft2(s)) .* eyeflt
        s = np.mean(trimg_sp, axis=0) - np.mean(trimg_sa, axis=0)
        s_fft = np.fft.fftshift(np.fft.fft2(s))
        s_eye = s_fft * eyeflt
        
        # Testing
        # te_sa_eye = fftshift(fft2(test_img)) .* eyeflt
        # t_sa = real(s_eye(:)' * te_sa_eye(:))
        # Internal product in freq domain involves conj?
        # MATLAB `s_eye(:)' * te_sa_eye` is dot product.
        # `s_eye` is complex. `s_eye(:)'` is conjugate transpose (Hermitian).
        # So it is sum(conj(s_eye) * te_sa_eye).
        # This is equivalent to cross-correlation at 0 lag in freq domain if handled correctly.
        # Or Just inner product.
        
        # Let's Vectorize testing
        # Test images: (N, Y, X)
        # FFT all
        
        # We can optimize: s_eye is constant.
        # t = Real( Sum( Conj(S_eye) * Test_Eye ) )
        
        flattened_s_eye = s_eye.flatten() # 1D array
        
        def project(images: np.ndarray) -> np.ndarray:
            # images: (N, Y, X)
            n_imgs = images.shape[0]
            scores = np.zeros(n_imgs)
            for i in range(n_imgs):
                tmp = np.fft.fftshift(np.fft.fft2(images[i])) * eyeflt
                # dot product: s_eye' * tmp
                # np.vdot(a, b) does conjugate(a) * b?
                # MATLAB: s_eye(:)' * te_sa_eye
                # This is conjugate transpose of s_eye
                # np.vdot(a, b) is sum(conj(a)*b). So correct.
                # using vdot on flattened arrays
                val = np.vdot(flattened_s_eye, tmp.flatten())
                scores[i] = val.real
            return scores

        t_sa = project(testimg_sa)
        t_sp = project(testimg_sp)
        
        snr = (np.mean(t_sp) - np.mean(t_sa)) / np.sqrt((np.std(t_sp, ddof=1)**2 + np.std(t_sa, ddof=1)**2) / 2)
        
        y_true = np.concatenate([np.zeros(len(t_sa)), np.ones(len(t_sp))])
        y_scores = np.concatenate([t_sa, t_sp])
        auc = roc_auc_score(y_true, y_scores)
        
        return {'auc': auc, 'snr': snr}
