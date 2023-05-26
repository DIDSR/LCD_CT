clear all; close all; clc;
addpath(genpath('src'))

if is_octave
  pkg load image
  pkg load tablicious
end

base_dir = 'Sample_Data/MITA_LCD';

offset = 1000;
xtrue = mhd_read_image(fullfile(base_dir, 'ground_truth.mhd')) - offset;
% input is a binary mask specifying signal known exactly (SKE)

truth_masks = get_demo_truth_masks(xtrue);

truth_mask = truth_masks(:,:,1);
insert_r = get_insert_radius(truth_mask);

% observers can also be constructed ahead of time and then iterated through
observers = {LG_CHO_2D(2/3*insert_r),...
             DOG_CHO_2D(),...
             GABOR_CHO_2D(),...
             };

dose = 100;
n_reader = 10;

observer = [];
dose_level = [];
snr = [];
auc = [];
reader = [];
insert_HU = [];
insert_diameter_pix = [];

if is_octave
string = @(x) x
boolean = @(x) logical(x)
end

for i=1:length(observers)
    model_observer = observers{i};

    dose_level_dir = fullfile(base_dir, sprintf('dose_%03d', dose));

    signal_present_dir = fullfile(dose_level_dir, 'signal_present');
    signal_absent_dir = fullfile(dose_level_dir, 'signal_absent');

    sp_raw_array = mhd_read_image(fullfile(signal_present_dir, 'signal_present.mhd')) - offset;
    sa_raw_array = mhd_read_image(fullfile(signal_absent_dir, 'signal_absent.mhd')) - offset;

    sp_imgs = get_ROI_from_truth_mask(truth_mask, sp_raw_array);
    sa_imgs = get_ROI_from_truth_mask(truth_mask, sa_raw_array);

   for n=1:n_reader
       [sa_train, sa_test, sp_train, sp_test] = train_test_split(sa_imgs, sp_imgs);
       res = model_observer.perform_study(sa_train, sp_train, sa_test, sp_test);

       observer_str = string(model_observer.type)
       observer = [observer; observer_str];
       insert_HU = [insert_HU; mode(xtrue(boolean(truth_mask)))];
       dose_level = [dose_level; round(dose)];
       snr = [snr; res.snr];
       auc = [auc; res.auc];
       reader = [reader; n];
   end
end

res_table = table(observer, insert_HU, dose_level, snr, auc, reader);

fname = mfilename;
output_fname = ['results_', fname(1:7), '.csv'];
if is_octave
  headers = ["observer, insert_HU, dose_level, snr, auc, reader"];
  fid = fopen(output_fname, 'w'); fdisp(fid, headers);
  for r=1:length(dose_level)
  fprintf(fid, "%s, %d, %d, %f, %f, %d\n", observer(r, :), insert_HU(r), dose_level(r), snr(r), auc(r), reader(r));
  end
  fclose(fid);
else
  writetable(res_table, output_fname);
end

plot_results(res_table)

res_table
