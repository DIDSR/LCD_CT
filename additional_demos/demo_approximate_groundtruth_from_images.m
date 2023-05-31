% this script demonstrates how to use the `approximate_groundtruth`
% function to generate a ground truth mask for location known exactly low
% contrast detectability.
fname = dir([mfilename('fullpath'), '.m']);
[fpath, fname, ~] = fileparts(fname.folder);
if fname == "additional_demos"
    cd('..')
end
addpath(genpath('src'))

base_directory = 'data/large_dataset/fbp';
ground_truth_filename = 'additional_demos/ground_truth.mhd';
offset=1000;

ground_truth = approximate_groundtruth(base_directory, ground_truth_filename, offset);

signal_present_image = mean(mhd_read_image(fullfile(base_directory,'dose_100','signal_present', 'signal_present.mhd')) - offset, 3);

imshow([ground_truth, signal_present_image], [-10 20])