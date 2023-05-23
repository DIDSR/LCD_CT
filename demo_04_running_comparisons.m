% demo_04_running_comparisons.m
% authors: Brandon Nelson, Rongping Zeng
%
% This demo outputs AUC curves of two recon options to show how the LCD-CT tool can be used to compare to denoising devices or recon methods

base_dir = '/gpfs_projects/brandon.nelson/RSTs/LCD_datasets'
recon_1_dir = fullfile(base_dir, 'fbp'); % <-replace with downloaded location
recon_1_res = make_auc_curve(recon_1_dir);
recon_1_res.recon(:) = "fbp";

recon_2_dir = fullfile(base_dir, 'DL_denoised');
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