
close all; 

%Download MIRT and include the MIRT path in the MATLAB workspace by running "setup.m". 
if ~exist('mirt-main', 'dir')
    %unzip('https://github.com/JeffFessler/mirt/archive/refs/heads/main.zip', '.');
    options = weboptions('CertificateFilename', '');
    % Define the file URL and local destination path
    url = 'http://web.eecs.umich.edu/~fessler/irt/fessler.tgz';
    % Step 1: Download and save the zip file
    websave('fessler.tgz', url, options);
    % Step 2: Unzip the file into the target folder
    untar('fessler.tgz', 'mirt-main');
end
irtdir = 'mirt-main/irt/';
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
disp('Simulating CCT189 scans')
makeCT_CCT189
disp('Simulating LiverLCD scans')
makeCT_LiverLCD
disp('LCD phantom creation code is run successfully!')


