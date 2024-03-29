%**************************************************************************
% CT_setup.m: Define the parameters of a fan-bean CT scanner
%
% Users can change the parameter values included in the code to define the 
% the CT system they want to simulate.
%*************************************************************************

down = 2;%Downsample rate. set it to "1" to generate 512x512 full size image 
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
                      
ds = 1;        % detector column size 
offset_s = 1.25;    % lateral shift of detector


% Define the reconstruction image matrix: pixel size, fov, kernel
nx = 512; % number of imge pixels in x-dimension 
dx = 0.664; %PixelSpacing (mm). This value equal to 340/512, corresponding to FOV of 340 mm for a 512x512 image matrix
fov = dx*nx;      % mm

fbp_kernel = 'hanning,2.05'; % 'hanning,xxx', xxx = the cutoff frequency, see fbp2_window.m in MIRT for details.
                        %'hanning,2.05' approximate a sharp kernel D45 in Siemens Force.
                        %'hanning, 0.85' approximate a smooth kernel B30 in
                        %Siemens Force.

                                    
