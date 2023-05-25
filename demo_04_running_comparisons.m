% demo_04_running_comparisons.m
% authors: Brandon Nelson, Rongping Zeng
%
% This demo outputs AUC curves of two recon options to show how the LCD-CT tool can be used to compare to denoising devices or recon methods
addpath(genpath('src'))

if is_octave
  pkg load image
  pkg load tablicious
end

recon_1_dir = 'data/fbp';
if ~exist(recon_1_dir, 'dir')
    disp(['dataset not found in: ', recon_1_dir])
    disp('now downloading from ')
    fbp_url = 'https://sandbox.zenodo.org/record/1205888/files/fbp.zip?download=1'
    unzip(fbp_url, 'data');
end

recon_1_res = make_auc_curve(recon_1_dir);
recon_1_res.recon(:) = "fbp";

recon_2_dir  = 'data/DL_denoised';
if ~exist(recon_2_dir, 'dir')
    disp(['dataset not found in: ', recon_2_dir])
    disp('now downloading from ')
    dl_url = 'https://sandbox.zenodo.org/record/1205888/files/DL_denoised.zip?download=1'
    unzip(dl_url, 'data')
end

recon_2_res = make_auc_curve(recon_2_dir);
recon_2_res.recon(:) = "DL denoised";

combined_res = cat(1, recon_1_res, recon_2_res);
write_lcd_results(combined_res, 'fbp_DL_auc_comparison.csv')
%%
plot_results(combined_res)

%% 
% let's just look at a subset
idx = combined_res.observer == "Laguerre-Gauss CHO 2D" & combined_res.insert_HU < 7
filtered_res = combined_res(idx, :)

plot_results(filtered_res)