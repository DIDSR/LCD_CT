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

dose = 10;

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
        download_largedataset(base_directory)
    end
    base_directory = large_dataset_directory;
else
    base_directory = fullfile(base_directory, 'small_dataset');
end
recon_1_dir = fullfile(base_directory, 'fbp');
recon_2_dir  = fullfile(base_directory, 'DL_denoised');
%% select a single dose level for this demo

recon_1_dir = fullfile(recon_1_dir, ['dose_' num2str(dose, '%03d')]);
recon_2_dir = fullfile(recon_2_dir, ['dose_' num2str(dose, '%03d')]);
%% Next specify a ground truth image
% This is used to determine the center of each lesion for Location Known Exactly (LKE) low contrast detection

ground_truth_fname = fullfile(base_directory,'fbp','ground_truth.mhd');
offset = 1000;
ground_truth = mhd_read_image(ground_truth_fname) - offset; %need to build in offset to dataset

%% run
nreader = 20;  
pct_split = 0.6;
seed_split = randi(1000, nreader,1); 
recon_1_res = measure_LCD(recon_1_dir, observers, ground_truth, offset, nreader, pct_split, seed_split);

if is_octave
  recon_1_res.recon = "fbp";
  recon_1_res.dose_level = dose;
else
  recon_1_res.recon(:) = "fbp";
  recon_1_res.dose_level(:) = dose;
end

recon_2_res = measure_LCD(recon_2_dir, observers, ground_truth, offset, nreader, pct_split, seed_split);
if is_octave
  recon_2_res.recon = "DL denoised";
  recon_2_res.dose_level = dose;
else
  recon_2_res.recon(:) = "DL denoised";
  recon_2_res.dose_level(:) = dose;
end

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
figure('NumberTitle', 'off', 'Name', 'AUC Recon Comparison');
plot_results(res_table, set_ylim)

%% plot the difference
figure('NumberTitle', 'off', 'Name', 'AUC Difference');
diff_auc = recon_2_res.auc - recon_1_res.auc;
diff_res = recon_1_res;
diff_res.auc = diff_auc;
diff_res.recon(:) = "DL denoised - fbp";
plot_results(diff_res)

%print the mean and std results of difference AUC/SNR
diff_snr = recon_2_res.snr - recon_1_res.snr;
for i=1:4
    mean_diffAUC(i) = mean(diff_auc([1:nreader]+(i-1)*nreader));
    std_diffAUC(i) = std(diff_auc([1:nreader]+(i-1)*nreader));
    mean_diffSNR(i) = mean(diff_snr([1:nreader]+(i-1)*nreader));
    std_diffSNR(i) = std(diff_snr([1:nreader]+(i-1)*nreader));
end
insert_HU = diff_res.insert_HU(1:nreader:end);
mean_diffAUC = mean_diffAUC(:);
std_diffAUC = std_diffAUC(:);
mean_diffSNR = mean_diffSNR(:);
std_diffSNR = std_diffSNR(:);
diffAUC_res = table(insert_HU, mean_diffAUC, std_diffAUC, mean_diffSNR, std_diffSNR);
diffAUC_res

if ~use_large_dataset
    warning("`use_large_dataset` (line 15) is set to false`. This script is using a small dataset (10 repeat scans) to demonstrate usage of the LCD tool. For more accurate results, set `use_large_dataset = true`")
end
