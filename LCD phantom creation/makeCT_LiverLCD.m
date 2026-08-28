% Purpose: To simulate CT images of the MITA LCD body phantom CCT189 and a 
% uniform phantom. This generates multiple noisy realizations. Noise level 
% is specified by 'I0'.
%
% ------ Note -----
% The CT simulation is implemented based on the Michigan Image Reconstruction Toolbox (MIRT). 
% MIRT is downloaded the first time when the phantom creation code runs:
%   1. Download MIRT from https://github.com/JeffFessler/mirt to a local directory.
%   2. Include MIRT functions to the Matlab path by running "setup.m" in MIRT

close all; 

demo = 1 % Set demo to 1 if you want to make the low-contrast disk inserts more visible.   
if(demo==1)   
   scale = 30 % for illustration purpose, scale up the low-contrast disks' intensity levels. 
else
   scale = 1  %for actual LCD data simulation, 'scale' is 1.
end  

% ------ define the CT scanner setting ------
CT_setup;   %this will load in CT parameters. See "CT_setup.m" for details. 

I_full = 4e5; % Photon flux corresponding to full-dose level.      
dose_level = 100; 
I0 = I_full*dose_level/100; %adjust the photon flux based on 'dose_level'.

has_bowtie = 1; % Include a bowtie filter if 'has_bowtie' is 1.

%Create "sg", sinogram geometry
sg = sino_geom('fan', 'units', 'mm', ...
    'nb', nb, 'na', na, 'ds', ds, ...
    'dsd', sdd, 'dod', dod, 'offset_s', offset_s, ...
    'strip_width', ds, 'down', down); 
                                                   
 %create "ig" (image geometry)                                                  
ig = image_geom('nx', nx, 'fov', fov, 'down', down);
                                                   
                                          
 
nsim = 1; %number of noisy simulations. 
          %Suggest 200 noisy realizations for the LCD task performance evaluation

% ------ create the phantom objects: patient-based liver backgro with four low-contrast disk inserts ------
mu_water = 0.2059 / 10;     % in mm^-1

% create background module (by loading in a patient slice)
filename = 'L506_FD_3mm_SHARP_slice30.IMA';% A full-dose patient CT slice
info = dicominfo(filename); 
imgpatient = single(dicomread(filename)); %full-dose image

fovmask = sqrt((ig.xg).^2+(ig.yg).^2)>=fov/2;
bkg_true = imgpatient-1000; %offset by 1000 to make water HU = 0
bkg_true(fovmask)= -1000;  %set the value outside of the FOV to be air.

% Creat disk module (by inserting four low-contrast disk objects to the patient slice)

disk_ctr = [250 194; 180 126; 253 90; 298 110]; % Coordinates of the four disk centers, in pixel unit 
ells_disk = [                                
        ig.x(disk_ctr(1,1))  ig.y(disk_ctr(1,2)) 3/2  3/2 0 -21/1000*mu_water*scale;     % 3 mm, -21 HU
        ig.x(disk_ctr(2,1))  ig.y(disk_ctr(2,2))   5/2  5/2 0 -10.5/1000*mu_water*scale;     % 5 mm, -10.5 HU
        ig.x(disk_ctr(3,1))  ig.y(disk_ctr(3,2))   7/2  7/2 0 -7.5/1000*mu_water*scale;     % 7 mm,  -7.5 HU
        ig.x(disk_ctr(4,1))  ig.y(disk_ctr(4,2))  10/2 10/2 0 -4.5/1000*mu_water*scale;     % 10 mm, -4.5 HU
        ];

insert_mu = ellipse_im(ig, ells_disk, 'oversample', 4, 'rot', 0);
insert_hu = 1000*insert_mu/mu_water;
disk_true = bkg_true + insert_hu;

% ------ Generate sinogram -------

% ray-tracing method to calculate the sinogram of the background-only module
bkg_mu= bkg_true*mu_water/1000 + mu_water; %Convert to attenuation coefficient
A_forward = Gtomo2_dscmex(sg, ig); % construct the forward projection matrix 
sino_bkg = A_forward * bkg_mu;

% analytically calculating the sinogram of disk inserts
sino_inserts = ellipse_sino(sg, ells_disk, 'oversample', 4); 

% Sinogram of disk-present module by adding sinograms of the background and the inerts together
sino_disk = sino_bkg + sino_inserts; 

% ------ Noiseless FBP reconstruction------
 % Generate the reconstruction operator. Choose 'std:mat' to allow options of different recon filter.                                            
 fg = fbp2(sg, ig,'type','std:mat');        

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

    %attenuating x-ray photon source by the bowtie filter
    if(has_bowtie==1)
        I0_afterbowtie=I0*bowtie;           
    else
        I0_afterbowtie=I0;            
    end

    %convert attenuation integrals to photon counts
    proj_disk = I0 .* exp(-sino_disk);
    proj_bkg = I0 .* exp(-sino_bkg);
    
    %add poisson noise
    proj_disk_noisy = poissrnd(proj_disk); 
    proj_bkg_noisy = poissrnd(proj_bkg);
   
    %add electronic noise
    e_noise = sigma_e * randn(size(sino_bkg)); %electronic noise
    proj_disk_noisy = proj_disk_noisy + e_noise;
    proj_bkg_noisy = proj_bkg_noisy + e_noise;

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
clip = [];
subplot(241), im(disk_true',clip), title 'True object image: signal module';
subplot(245), im(bkg_true',clip), title 'True object image: background module';
subplot(242), im(sino_disk,[]), title 'Sinogram: signal module';
subplot(246), im(sino_bkg,[]), title 'Sinogram: background module';
subplot(243), im(disk_ct_noiseless',clip), title 'Noiseless fbp image: signal module';
subplot(247), im(bkg_ct_noiseless',clip), title 'Noiseless fbp image: background module';
subplot(244), im(disk_ct_noisy',clip), title 'Noisy fbp image: signal module';
subplot(248), im(bkg_ct_noisy',clip), title 'Noisy fbp image: background module';    
colormap(gray)

if(demo==1)
   printf('Note: The intensity of disks was scaled up for illustration purpose. \n For actual LCD data simulation, set the parameter "demo" to 0.')
end