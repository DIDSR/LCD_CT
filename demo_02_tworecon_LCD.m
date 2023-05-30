% demo_03_access_large_dataset.m
% authors: Brandon Nelson, Rongping Zeng
%
% This script builds upon previous demos by showing how to iterate through
% larger datasets. A dataset is available from
% https://sandbox.zenodo.org/record/1150650 and you will be prompted if
% you'd like to download this dataset and to provide a target directory.
% The dataset is about 1 gb so it might take some time to complete
% depending upon download speeds.
%
% Once the download is complete
%next show an example of how to access the large dataset on Zenodod with
%200 sims
% clear all
% demo_04_running_comparisons.m
% authors: Brandon Nelson, Rongping Zeng
%
% This demo outputs AUC curves of two recon options to show how the LCD-CT tool can be used to compare to denoising devices or recon methods

%% add relevant source files and packages
addpath(genpath('src'))
clear all;
% close all;
clc;

if is_octave
  pkg load image tablicious
end
%% User specified parameters
% specify the `base_directory` containing images to be evaluated
use_large_dataset = false;
dose = 100;
set_ylim = [0 1.1];

observers = {LG_CHO_2D()};
% observers = {LG_CHO_2D(),...
%              DOG_CHO_2D(),...
%              GABOR_CHO_2D(),...
%              };
%% Next specify a ground truth image
% This is used to determine the center of each lesion for Location Known Exactly (LKE) low contrast detection

ground_truth_fname = fullfile('Sample_Data','MITA_LCD','ground_truth.mhd');
offset = 1000;
ground_truth = mhd_read_image(ground_truth_fname) - offset; %need to build in offset to dataset

%% Select datasets
% download if necesarry

if use_large_dataset
recon_1_dir = 'data/fbp';
if ~exist(recon_1_dir, 'dir')
    disp(['dataset not found in: ', recon_1_dir])
    disp('now downloading from ')
    fbp_url = 'https://sandbox.zenodo.org/record/1205888/files/fbp.zip?download=1'
    unzip(fbp_url, 'data');
end
recon_1_dir = fullfile(recon_1_dir, ['dose_' num2str(dose)]);

recon_1_res = make_auc_curve(recon_1_dir, observers, ground_truth, offset);

if is_octave
  recon_1_res.recon = "fbp"
else
  recon_1_res.recon(:) = "fbp";
end
%% re
recon_2_dir  = 'data/DL_denoised';
if ~exist(recon_2_dir, 'dir')
    disp(['dataset not found in: ', recon_2_dir])
    disp('now downloading from ')
    dl_url = 'https://sandbox.zenodo.org/record/1205888/files/DL_denoised.zip?download=1'
    unzip(dl_url, 'data')
end
recon_2_dir = fullfile(recon_2_dir, ['dose_' num2str(dose)]);

recon_2_res = make_auc_curve(recon_2_dir, observers, ground_truth, offset);
if is_octave
  recon_2_res.recon = "DL denoised";
else
  recon_2_res.recon(:) = "DL denoised";
end

if is_octave
  combined_res = vertcat(recon_1_res, recon_2_res);
else
  combined_res = cat(1, recon_1_res, recon_2_res);
end

write_lcd_results(combined_res, 'fbp_DL_auc_comparison.csv')
%%
plot_results(combined_res)


