% demo_04_running_comparisons.m
% authors: Brandon Nelson, Rongping Zeng
%
% This demo outputs AUC curves of two recon options to show how the LCD-CT tool can be used to compare to denoising devices or recon methods
%% add relevant source files and packages
addpath(genpath('src'))
% clear all;
% close all;
clc;

if is_octave
  pkg load image tablicious
end
%% User specified parameters
% specify the `base_directory` containing images to be evaluated
if ~exist('use_large_dataset', 'var')
    use_large_dataset = false;
end

observers = {LG_CHO_2D()};
% observers = {LG_CHO_2D(),...
%              DOG_CHO_2D(),...
%              GABOR_CHO_2D(),...
%              };
%% Select datasets
% download if necesarry
%% Select datasets
% download if necesarry
base_directory = 'data';
if use_large_dataset
    base_directory = fullfile(base_directory, 'large_dataset');
    recon_1_dir = fullfile(base_directory, 'fbp');
    if ~exist(recon_1_dir, 'dir')
        disp(['dataset not found in: ', recon_1_dir])
        disp('now downloading from ')
        fbp_url = 'https://sandbox.zenodo.org/record/1205888/files/fbp.zip?download=1'
        unzip(fbp_url, recon_1_dir);
    end

    recon_2_dir  = fullfile(base_directory, 'DL_denoised');
    if ~exist(recon_2_dir, 'dir')
        disp(['dataset not found in: ', recon_2_dir])
        disp('now downloading from ')
        dl_url = 'https://sandbox.zenodo.org/record/1205888/files/DL_denoised.zip?download=1'
        unzip(dl_url, recon_2_dir);
    end
else
    base_directory = fullfile(base_directory, 'small_dataset');
    recon_1_dir = fullfile(base_directory, 'fbp');
    recon_2_dir  = fullfile(base_directory, 'DL_denoised');
end

%% Next specify a ground truth image
% This is used to determine the center of each lesion for Location Known Exactly (LKE) low contrast detection

ground_truth_fname = fullfile(base_directory,'fbp','ground_truth.mhd');
offset = 1000;
ground_truth = mhd_read_image(ground_truth_fname) - offset; %need to build in offset to dataset

%% run
recon_1_res = make_auc_curve(recon_1_dir, observers, ground_truth, offset);
if is_octave
  recon_1_res.recon = "fbp"
else
  recon_1_res.recon(:) = "fbp";
end

recon_2_res = make_auc_curve(recon_2_dir, observers, ground_truth, offset);
if is_octave
  recon_2_res.recon = "DL denoised";
else
  recon_2_res.recon(:) = "DL denoised";
end
%% combine results
if is_octave
  res_table = vertcat(recon_1_res, recon_2_res);
else
  res_table = cat(1, recon_1_res, recon_2_res);
end
%% save results
fname = mfilename;
output_fname = ['results_', fname(1:7), '.csv'];
write_lcd_results(res_table, output_fname)
%% plot results
set_ylim = [];
if use_large_dataset
    set_ylim = [0.7 1.01];
end
if ~use_large_dataset
    warning("`use_large_dataset` (line 31) is set to false`. This script is using a small dataset (10 repeat scans) to demonstrate usage of the LCD tool. For more accurate results, set `use_large_dataset = true`")
end
plot_results(res_table, set_ylim)

res_table
%% plot the difference
% let's just look at a subset
diff_auc = recon_2_res.auc - recon_1_res.auc;
diff_res = recon_1_res;
diff_res.auc = diff_auc;
diff_res.recon(:) = "DL denoised - fbp";
plot_results(diff_res)

diff_res