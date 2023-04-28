%**************************************************************************
% CT_setup.m: Define the parameters of a fan-bean CT scanner. This code prepare 
% the variables "sg" (sinogram geometry), "ig" (image geometry), "fg" (forward 
% projection operator) to be used in the phantom CT image simulation code
% named "makeCT_CCT189.m".
%
% Users can change the parameter values included in the code to define the 
% the CT system they want to simulate.
%
% Note: the simulation code is based on the Michigan Image Reconstruction
% Toolbox (MIRT), follow this two steps to set up the toolbox
%   1. Download and upzip MIRT(http://web.eecs.umich.edu/~fessler/irt/fessler.tgz) 
%      to your local directory.
%   2. MIRT contains a code named "setup.m", run it to include MIRT files to
%      your matlab path.
%*************************************************************************

down = 2;%Downsample rate. set it to "1" to generate 512x512 full size image 
         %Set "down" to 2 to generate downsampled sinogram/image to save 
         %compuation time for testing purpose.
disp(sprintf('Downsample rate is %d', down));

% CT geometry (the following parameter values simulate Siemens Force) 
sid = 595;          %(mm) source-to-isocenter distance (value based on AAPM LDCT data dicom header)
sdd = 1085.6;          % source-to-detector distance
dod = sdd - sid;    % isocenter-to-detector distance

nb = 880;           % number of detector columns (set it to be large enough to cover the projected FOV to avoid truncation)
na = 1160;          % number of views in a rotation
                      % (na=1160 based on ZengEtAl2015-IEEE-NuclearScience-v62n5:"A Simple Low-Dose X-Ray CT Simulation From High-Dose Scan")
                      
ds = 1;        % detector column size 
offset_s = 1.25;    % lateral shift of detector

sg = sino_geom('fan', 'units', 'mm', ...
    'nb', nb, 'na', na, 'ds', ds, ...
    'dsd', sdd, 'dod', dod, 'offset_s', offset_s, ...
    'down', down);

% Define the reconstruction image matrix: pixel size, fov, kernel
nx = 512; % number of imge pixels in x-dimension 
dx = 0.664; %PixelSpacing (mm). This value equal to 340/512, corresponding to FOV of 340 mm for a 512x512 image matrix
fov = dx*nx;      % mm
ig = image_geom('nx', nx, 'fov', fov, 'down', down);
fbp_kernel = 'hann205'; % 'hannxxx', xxx/100 = the cutoff frequency, see fbp2_window.m in MIRT for details.
                        %'hann205' approximate a sharp kernel D45 in Siemens Force.
                        %'hann85' approximate a smooth kernel B30 in
                        %Siemens Force.
% Generate the forward projection operator -------
fg = fbp2(sg, ig,'type','std:mat'); %choose 'std:mat' to be able to using different recon filter
                                    