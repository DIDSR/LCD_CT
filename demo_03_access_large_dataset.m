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
addpath(genpath('src'))

if ~exist('base_dir', 'var')
    base_dir = 'data/MITA_LCD'; %<-- Replace with directory containing large data set
end

ground_truth_fname = fullfile(base_dir, 'ground_truth.mhd');
if ~exist(ground_truth_fname, 'file')
    base_dir = download_dataset('https://sandbox.zenodo.org/record/1150650/files/MITA_LCD.zip', base_dir)
end

res_table = make_auc_curve(base_dir);

fname = mfilename;
output_fname = ['results_', fname(1:7), '.csv'];
write_lcd_results(res_table, output_fname)

plot_results(res_table)

res_table
