
% Purpose: To simulate CT images of the MITA LCD body phantom CCT189 and a 
% uniform phantom. This generates multiple noisy realizations. Noise level 
% is specified by 'I0'.
%
 
close all; 
% ------ Note -----
% The CT simulation is implemented based on the Michigan Image Reconstruction Toolbox (MIRT). 
% MIRT is downloaded the first time when the phantom creation code runs:
%   1. Download MIRT from https://github.com/JeffFessler/mirt to a local directory.
%   2. Include MIRT functions to the Matlab path by running "setup.m" in MIRT

if ~exist('mirt-main', 'dir')
download_dataset('https://github.com/JeffFessler/mirt/archive/refs/heads/main.zip', '.', false);
irtdir = 'mirt-main';
addpath(irtdir)
end
setup
%-------------------

% ------ define the CT scanner setting ------
CT_setup;   %this will load in CT parameters. See "CT_setup.m" for details. 
I0 = 3e6; %Photon flux, related to dose level.      
                                                   
%Create "sg", sinogram geometry
sg = sino_geom('fan', 'units', 'mm', ...
    'nb', nb, 'na', na, 'ds', ds, ...
    'dsd', sdd, 'dod', dod, 'offset_s', offset_s, ...
    'strip_width', ds, 'down', down); 
                                                   
 %create "ig" (image geometry)                                                  
ig = image_geom('nx', nx, 'fov', fov, 'down', down);
                                                   
 % Generate the forward projection operator. Choose 'std:mat' to be able to using different recon filter                                            
fg = fbp2(sg, ig,'type','std:mat');                                                  
 
nsim = 1; %number of noisy simulations. 
           %Suggest 200 noisy realizations for the LCD task performance evaluation

% ------ create the phantom objects: low-contrast disk module and background module ------
mu_water = 0.2059 / 10;     % in mm^-1
[cct189_disk_geo, cct189_bkg_geo] = CCT189_obj(mu_water);

%generate the phantom object images
x_true = ellipse_im(ig, cct189_disk_geo, 'oversample', 4, 'rot', 0);
cct189_disk_true= 1000*(x_true - mu_water)/mu_water; %Convert to HU

x_true = ellipse_im(ig, cct189_bkg_geo, 'oversample', 4, 'rot', 0);
cct189_bkg_true = 1000*(x_true - mu_water)/mu_water;
clear x_true;

% ------ Generate sinogram -------
sino_disk = ellipse_sino(sg, cct189_disk_geo, 'oversample', 4);
sino_bkg = ellipse_sino(sg, cct189_bkg_geo, 'oversample', 4);

% ------ Noiseless FBP reconstruction------
 xrecon = fbp2(sino_disk, fg, 'window', fbp_kernel);
 disk_ct_noiseless = 1000*(xrecon - mu_water)/mu_water; %convert to HU
 
 xrecon = fbp2(sino_bkg, fg, 'window', fbp_kernel);
 bkg_ct_noiseless = 1000*(xrecon - mu_water)/mu_water; %convert to HU
 clear xrecon

%  ------ Simulate noisy sinograms and create noisy FBP reconstruction  -------
% seednum = 30; %any number will do
% rand('state',seednum); % set a random seed number if needed.

for isim = 1: nsim      
    isim
    %convert attenuation integrals to photon counts
    proj_disk = I0 .* exp(-sino_disk);
    proj_bkg = I0 .* exp(-sino_bkg);
    
    %add poisson noise
    proj_disk_noisy = poisson(proj_disk); 
    proj_bkg_noisy = poisson(proj_bkg);

    if any(proj_disk_noisy(:) == 0)
        %dose too low, may need to increase "I0".
        warn('%d of %d values are 0 in sinogram!', ...
            sum(proj_disk_noisy(:)==0), length(proj_disk_noisy(:)));        
    end
    proj_disk_noisy(proj_disk_noisy==0) = 1;
    proj_bkg_noisy(proj_bkg_noisy==0) = 1;

    %Convert counts to attenuation integrals 
    sino_disk_noisy = -log(proj_disk_noisy ./ I0);            
    sino_bkg_noisy = -log(proj_bkg_noisy ./ I0); 

    % FBP recon
    xrecon = fbp2(sino_disk_noisy, fg, 'window', fbp_kernel);
    disk_ct_noisy = 1000*(xrecon - mu_water)/mu_water; %convert to HU.
    
    xrecon = fbp2(sino_bkg_noisy, fg, 'window', fbp_kernel);
    bkg_ct_noisy = 1000*(xrecon - mu_water)/mu_water; 
    clear xrecon
end

%display
figure(1);
subplot(241), im(cct189_disk_true,[-30 30]), title 'True object image: signal module';
subplot(245), im(cct189_bkg_true,[-30 30]), title 'True object image: background module';
subplot(242), im(sino_disk,[]), title 'Sinogram: signal module';
subplot(246), im(sino_bkg,[]), title 'Sinogram: background module';
subplot(243), im(disk_ct_noiseless,[-30 30]), title 'Noiseless fbp image: signal module';
subplot(247), im(bkg_ct_noiseless,[-30 30]), title 'Noiseless fbp image: background module';
subplot(244), im(disk_ct_noisy,[-30 30]), title 'Noisy fbp image: signal module';
subplot(248), im(bkg_ct_noisy,[-30 30]), title 'Noisy fbp image: background module';    

