
% ------ Note -----
% The CT simulation is implemented based on the Michigan Image Reconstruction Toolbox (MIRT). 
% MIRT is downloaded the first time when the phantom creation code runs:
%   1. Download MIRT from https://github.com/JeffFessler/mirt to a local directory.
%   2. Include MIRT functions to the Matlab path by running "setup.m" in MIRT
%-------------------

close all; 

%Download MIRT and include the MIRT path in the MATLAB workspace. 
if ~exist('mirt-main', 'dir')
unzip('https://github.com/JeffFessler/mirt/archive/refs/heads/main.zip', '.');
end
irtdir = 'mirt-main';
addpath(irtdir)
setup

%check if MIRT path is included
if(~exist('fbp2.m'))
    disp('Setup error!')
    disp('It appears that MIRT is not available. Please follow the instructions below to set up MIRT for phanotm creation.')
    disp('1. Download and upzip the MIRT Github version https://github.com/JeffFessler/mirt')
    disp('2. MIRT contains a file named "setup.m", run it to include MIRT funcitons to your matlab path.')
end

addpath(genpath('LCD phantom creation'));
makeCT_CCT189
disp('LCD phantom creation code is run successfully!')


return
