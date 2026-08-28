%**************************************************************************
% CT_setup.m: Define the parameters of a fan-bean CT scanner
%
% Users can change the parameter values included in the code to define the 
% the CT system they want to simulate.
%*************************************************************************

down = 1;%Downsample rate. set it to "1" to generate 512x512 full size image 
         %Set "down" to 2 to generate downsampled sinogram/image to save 
         %compuation time for testing purpose.
if(down>1)
    disp(sprintf('Downsample rate is: down=%d for testing purpose. \nYou can set down=1 to generate full-size images.', down));
end

% CT geometry (the following parameter values simulate Siemens Force) 
sid = 595;          %(mm) source-to-isocenter distance (value based on AAPM LDCT data dicom header)
sdd = 1085.6;          % source-to-detector distance
dod = sdd - sid;    % isocenter-to-detector distance

nb = 880;           % number of detector columns (set it to be large enough to cover the projected FOV to avoid truncation)
na = 1160;          % number of views in a rotation
                      % (na=1160 based on ZengEtAl2015-IEEE-NuclearScience-v62n5:"A Simple Low-Dose X-Ray CT Simulation From High-Dose Scan")
                      
ds = 0.6*sdd/sid;;        % detector column size 
offset_s = 1.25;    % lateral shift of detector

sigma_e = 10;  %electronic noise

% Define the reconstruction image matrix: pixel size, fov, kernel
nx = 512; % number of imge pixels in x-dimension 
fov = 380; % reconstruction/scan field of view (FOV), in mm
dx = fov/nx; % PixelSpacing (mm). 

fbp_kernel = 'hanning,2.05'; % 'hanning,xxx', xxx = the cutoff frequency, see fbp2_window.m in MIRT for details.
                        %'hanning,2.05' approximate a sharp kernel D45 in Siemens Force.
                        %'hanning, 0.85' approximate a smooth kernel B30 in Siemens Force.

%Bowtie filter: shape automatically adjusted to the FOV size
% The bowtie shape was validatded to match with the measurement reported in Figure 3 of the following paper: 
% Yu et. al., "Development and Validation of a Practical Lower-Dose-Simulation Tool for Optimizing Computed Tomography Scan Protocols", JCAT 2012.
ell_fovdisk = [0 0 fov/2 fov/2 0 1];
pathlength = ellipse_sino(sg, ell_fovdisk, 'oversample',4);
maxpl = max(pathlength(:));
mu_water = 0.2059 / 10;     % in mm^-1
bowtie =exp(-mu_water*maxpl)./exp(-mu_water*pathlength);
edge_val = 0.16; %raise the edge value to allow photons, see the fitting curve by running "make_bowtie.m" 
bowtie = (1-edge_val)*bowtie + edge_val; %normalize to [0, 1];
                                    
