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
base_directory = 'data';
if use_large_dataset
    large_dataset_directory = fullfile(base_directory, 'large_dataset');
    if ~exist(large_dataset_directory, 'dir')
        disp(['dataset not found in: ', base_directory])
        disp('now downloading from ')
        dataset_url = 'https://zenodo.org/record/7991067/files/large_dataset.zip'
        unzip(dataset_url, base_directory);
    end
    base_directory = large_dataset_directory;
else
    base_directory = fullfile(base_directory, 'small_dataset');
end
recon_1_dir = fullfile(base_directory, 'fbp');
recon_2_dir  = fullfile(base_directory, 'DL_denoised');
%% Next specify a ground truth image
% This is used to determine the center of each lesion for Location Known Exactly (LKE) low contrast detection

ground_truth_fname = fullfile(base_directory,'fbp','ground_truth.mhd');
offset = 1000;
ground_truth = mhd_read_image(ground_truth_fname) - offset; %need to build in offset to dataset

%% run
recon_1_res = measure_LCD(recon_1_dir, observers, ground_truth, offset);
if is_octave
  recon_1_res.recon = "fbp"
else
  recon_1_res.recon(:) = "fbp";
end

recon_2_res = measure_LCD(recon_2_dir, observers, ground_truth, offset);
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
figure('NumberTitle', 'off', 'Name', 'AUC vs. Dose Curves');
plot_results(res_table, set_ylim)

res_table
%% plot the difference
% let's just look at a subset
figure('NumberTitle', 'off', 'Name', 'AUC Difference');
diff_auc = recon_2_res.auc - recon_1_res.auc;
diff_res = recon_1_res;
diff_res.auc = diff_auc;
diff_res.recon(:) = "DL denoised - fbp";
plot_results(diff_res)

diff_res