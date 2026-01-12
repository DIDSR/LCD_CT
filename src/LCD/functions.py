import numpy as np
from scipy.special import factorial

def laguerre(x, J):
    """
    Calculate the Laguerre polynomials.
    x: input values
    J: order
    Returns: L matrix of shape (len(x), J+1)
    """
    x = np.asarray(x)
    L = np.zeros((x.size, J + 1))
    
    for j in range(J + 1):
        combin = factorial(j) / (factorial(np.arange(j + 1)) * factorial(j - np.arange(j + 1)))
        # Vectorized internal loop
        # The equation in MATLAB:
        # L(:,j+1) sum over k=0:j of combin(k+1) * ((-x).^k) / factorial(k)
        
        # We can implement this sum:
        col_j = np.zeros_like(x, dtype=np.float64)
        for k in range(j + 1):
             col_j += combin[k] * ((-x)**k) / factorial(k)
        L[:, j] = col_j # MATLAB is 1-based, we are 0-based index for columns
        
    return L

def laguerre_gaussian_2d(x, J, h):
    """
    Calculate the Laguerre-Gaussian function.
    x: 1d vector of pixel locations (radial distance)
    J: # of channels (order)
    h: Gaussian width
    """
    x = np.asarray(x)
    x_flat = x.flatten()
    
    # MATLAB: L = laguerre(2*pi*x.^2/h^2, J);
    # x argument to laguerre is scaled r^2
    lag_arg = 2 * np.pi * (x_flat**2) / (h**2)
    L = laguerre(lag_arg, J)
    
    u = np.zeros_like(L)
    # MATLAB: loop j=0:J ... u(:,j+1) = L(:,j+1) .* exp(-pi*x.^2/h^2)
    exp_term = np.exp(-np.pi * (x_flat**2) / (h**2))
    
    for j in range(J + 1):
        u[:, j] = L[:, j] * exp_term
        
    scale = np.sqrt(2) / h
    u = u * scale
    
    # Reshape back to (shape of x, J+1)
    # If x was 2D grid (which it usually is before flattening, e.g. meshgrid r),
    # MATLAB: u = reshape(u, [xsize J+1])
    # xsize is original shape.
    final_shape = x.shape + (J + 1,)
    return u.reshape(final_shape)

