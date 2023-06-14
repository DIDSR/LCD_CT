
close all; 

%Download MIRT and include the MIRT path in the MATLAB workspace. 
if ~exist('mirt-main', 'dir')
unzip('https://github.com/JeffFessler/mirt/archive/refs/heads/main.zip', '.');
end
irtdir = 'mirt-main';
addpath(irtdir)
if(exist('setup.m'))
    setup
end

%check if MIRT path is included
if(~exist('fbp2.m'))
    disp('Setup error!')
    disp('It appears that MIRT is not available. Please follow the instructions below to set up MIRT manually.')
    disp('1. Download and upzip the MIRT Github version https://github.com/JeffFessler/mirt')
    disp('2. MIRT contains a file named "setup.m", run it to include MIRT functions to your matlab path.')
    return
end

addpath(genpath('LCD phantom creation'));
makeCT_CCT189
disp('LCD phantom creation code is run successfully!')


