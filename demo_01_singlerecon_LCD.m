%% add relevant source files and packages
% clear all;
% close all;
clc;
addpath(genpath('src'))

if is_octave
  pkg load image tablicious
end

%%
% specify the `base_directory` containing images to be evaluated
recon_name = "fbp";
if ~exist('use_large_dataset', 'var')
    use_large_dataset = false;
end

dose = 100;

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

% The required structure used in this demo is given below in detail for one dose level,
% note the XXX denotes other image files not shown:
% Sample_Data/
% |-- MITA_LCD
%     |-- dose_010
%     |   |-- signal_absent
%     |   |   |-- signal_absent_001.raw
%     |   |   |-- signal_absent_002.raw
%     |   |   |-- signal_absent_XXX.raw
%     |   |   |-- signal_absent.mhd
%     |   |-- signal_present
%     |       |-- signal_present_001.raw
%     |       |-- signal_present_002.raw
%     |       |-- signal_present_XXX.raw
%     |       |-- signal_present.mhd
%     |-- dose_0XX
%     |-- dose_100
%% specify observers to use
%observers can also be constructed ahead of time and then iterated through
observers = {LG_CHO_2D()};
% observers = {LG_CHO_2D(2/3*insert_r),...
%              DOG_CHO_2D(),...
%              GABOR_CHO_2D(),...
%              };
%% Next specify a ground truth image
% This is used to determine the center of each lesion for Location Known Exactly (LKE) low contrast detection

ground_truth_fname = fullfile(base_directory,'ground_truth.mhd');
offset = 1000;
ground_truth = mhd_read_image(ground_truth_fname) - offset; %need to build in offset to dataset
%% select a single dose level for this demo

base_directory = fullfile(base_directory, ['dose_' num2str(dose, '%03d')]);
%% run
res_table = make_auc_curve(base_directory, observers, ground_truth, offset);

if is_octave
  res_table.recon = recon_name;
else
  res_table.recon(:) = recon_name;
end

%% save results
fname = mfilename;
output_fname = ['results_', fname(1:7), '.csv'];
write_lcd_results(res_table, output_fname)

%% plot results
set_ylim = [0 1.1];
plot_results(res_table, set_ylim)

res_table

if ~use_large_dataset
    warning("`use_large_dataset` (line 15) is set to false`. This script is using a small dataset (10 repeat scans) to demonstrate usage of the LCD tool. For more accurate results, set `use_large_dataset = true`")
end
