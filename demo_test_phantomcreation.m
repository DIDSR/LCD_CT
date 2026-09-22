
close all; 
addpath(genpath('src'))

%Download MIRT and include the MIRT path in the MATLAB workspace by running "setup.m". 
if ~exist('mirt-main', 'dir')
    % Define the file URL and local destination path
    url = 'http://web.eecs.umich.edu/~fessler/irt/fessler.tgz';
    outfile = 'fessler.tgz';

    % Step 1: Download and save the tar file
    if exist('OCTAVE_VERSION', 'builtin')
        cmd = sprintf('wget --no-check-certificate -O "%s" "%s"', outfile, url);
        status = system(cmd);
        if status ~= 0
            error('Failed to download MIRT.');
        end
    else
        %unzip('https://github.com/JeffFessler/mirt/archive/refs/heads/main.zip', '.');
        options = weboptions('CertificateFilename', '');
        websave(outfile, url, options);
    end

    % Step 2: Extract the file into the target folder
    untar(outfile, 'mirt-main');
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
    disp('1. Download and upzip the MIRT full version http://web.eecs.umich.edu/~fessler/irt/fessler.tgz')
    disp('2. MIRT/irt/ contains a file named "setup.m", run it to include MIRT/irt/ functions to your matlab path.')
    return
end

addpath(genpath('LCD phantom creation'));
disp('Simulating CCT189 scans')
makeCT_CCT189
disp('MITA-LCD phantom creation code is run successfully!')

%"makeCT_LiverLCD" only properly runs in MATLAB currently. It can't run in Octave because it calls some MIRT mex functions that were not compiled for Octave.  
if (~exist('OCTAVE_VERSION', 'builtin'))
     disp('Simulating LiverLCD scans')
     makeCT_LiverLCD
     disp('Liver-LCD phantom creation code is run successfully!')
else
    warning('Liver-LCD phantom creation code is not tested in OCTAVE due to incompatibility.')
end


