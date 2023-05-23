%check if MIRT path is included
if(~exist('fbp2.m'))
    disp('Setup error!')
    disp('It appears that MIRT is not available. Please follow the instructions below to set up MIRT for phanotm creation.')
    disp('1. Download and upzip the MIRT Github version https://github.com/JeffFessler/mirt')
    disp('2. MIRT contains a file named "setup.m", run it to include MIRT funcitons to your matlab path.')
end
return
addpath(genpath('LCD phantom creation'));
makeCT_CCT189
disp('LCD phantom creation code is run successfully!')
