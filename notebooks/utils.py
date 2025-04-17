import matplotlib.pyplot as plt
from pathlib import Path
import pydicom


def ctshow(img, window='soft_tissue'):
  # Define some specific window settings here
  if window == 'soft_tissue':
    ww = 400
    wl = 40
  elif window == 'bone':
    ww = 2500
    wl = 480
  elif window == 'lung':
    ww = 1500
    wl = -600
  elif isinstance(window, tuple):
    ww = window[0]
    wl = window[1]
  else:
    ww = 6.0 * img.std()
    wl = img.mean()

  # Plot image on clean axes with specified window level
  vmin = wl - ww // 2
  vmax = wl + ww // 2

  plt.imshow(img, cmap='gray', vmin=vmin, vmax=vmax)
  plt.xticks([])
  plt.yticks([])

  return

def get_ground_truth(fname):
    fname = Path(fname)
    if fname.stem.startswith('signal'):
        gt_file = 'noise_free.mhd'
        return Path(fname).parents[2] / gt_file
    if fname.stem.startswith('ACR464'):
        gt_file = 'true.mhd'
        return Path(fname).parents[3] / gt_file
    else:
        gt_file = 'true.mhd'
        return Path(fname).parents[2] / gt_file

def wwwl_to_minmax(wwwl:tuple): return wwwl[1] - wwwl[0]/2, wwwl[1] + wwwl[0]/2

# https://radiopaedia.org/articles/windowing-ct?lang=us
display_settings = {
    'brain': (80, 40),
    'subdural': (300, 100),
    'stroke': (40, 40),
    'temporal bones': (2800, 600),
    'soft tissues': (400, 50),
    'lung': (1500, -600),
    'liver': (150, 30),
}

def browse_studies(metadata, phantom='ACR464', fov=25, dose=100, recon='fbp', kernel='Qr43', repeat=0, display='soft tissues', slice_idx=0):
    patient = metadata[(metadata['Dose [%]']==dose) &
                       (metadata['phantom'] == phantom) &
                       (metadata['FOV (cm)']==fov) &
                       (metadata['recon'] == recon) &
                       (metadata['kernel'] == kernel) &
                       (metadata['repeat']==repeat) &
                       (metadata['slice']==slice_idx)]
    dcm_file = patient.file.item()
    dcm = pydicom.dcmread(dcm_file)
    img = dcm.pixel_array + int(dcm.RescaleIntercept)
    
    ww, wl = display_settings[display]
    minn = wl - ww/2
    maxx = wl + ww/2
    plt.figure()
    plt.imshow(img, cmap='gray', vmin=minn, vmax=maxx)
    plt.colorbar(label=f'HU | {display} [ww: {ww}, wl: {wl}]')
    plt.title(patient['Name'].item())
