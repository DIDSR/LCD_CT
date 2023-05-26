clear all; close all; clc;
addpath(genpath('src'))

if is_octave
  pkg load image tablicious
end

%%
% specify the `base_directory` containing images to be evaluated
use_large_dataset = true;
if use_large_dataset
    base_directory = 'data/fbp'
else
    base_directory = 'Sample_Data/MITA_LCD';
end

% The required structure used in this demo is given below in detail for one dose level,
% note the XXX denotes other image files not shown:
% Sample_Data/
% └── MITA_LCD
%     ├── dose_010
%     │   ├── signal_absent
%     │   │   ├── signal_absent_001.raw
%     │   │   ├── signal_absent_002.raw
%     │   │   ├── signal_absent_XXX.raw
%     │   │   └── signal_absent.mhd
%     │   └── signal_present
%     │       ├── signal_present_001.raw
%     │       ├── signal_present_002.raw
%     │       ├── signal_present_XXX.raw
%     │       └── signal_present.mhd
%     ├── dose_0XX
%     ├── dose_100       
%% Next specify a ground truth image
% This is used to determine the center of each lesion for Location Known Exactly (LKE) low contrast detection

offset = 1000;

ground_truth_filename = fullfile(base_directory, 'ground_truth1.mhd');
if exist(ground_truth_filename, 'file')
    xtrue = mhd_read_image(ground_truth_filename ) - offset;
else
    xtrue = approximate_xtrue(base_directory, ground_truth_filename, offset);
end

% input is a binary mask specifying signal known exactly (SKE)

truth_masks = get_demo_truth_masks(xtrue);

truth_mask = truth_masks(:,:,1);
insert_r = get_insert_radius(truth_mask);

% observers can also be constructed ahead of time and then iterated through
observers = {LG_CHO_2D(2/3*insert_r)};
% observers = {LG_CHO_2D(2/3*insert_r),...
%              DOG_CHO_2D(),...
%              GABOR_CHO_2D(),...
%              };

dose = [];
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

    dose_level_dirs = dir(fullfile(base_directory, 'dose_*'));

    for d=1:length(dose_level_dirs)
        dose_level_dir = dose_level_dirs(d);
        dose = str2double(dose_level_dir.name(6:end));

        signal_present_dir = fullfile(base_directory, dose_level_dir.name, 'signal_present');
        signal_absent_dir = fullfile(base_directory, dose_level_dir.name, 'signal_absent');

        sp_raw_array = mhd_read_image(fullfile(signal_present_dir, 'signal_present.mhd')) - offset;
        sa_raw_array = mhd_read_image(fullfile(signal_absent_dir, 'signal_absent.mhd')) - offset;

        sp_imgs = get_ROI_from_truth_mask(truth_mask, sp_raw_array);
        sa_imgs = get_ROI_from_truth_mask(truth_mask, sa_raw_array);

       for n=1:n_reader
           [sa_train, sa_test, sp_train, sp_test] = train_test_split(sa_imgs, sp_imgs);
           res = model_observer.perform_study(sa_train, sp_train, sa_test, sp_test);

           observer = [observer; string(model_observer.type)];
           insert_HU = [insert_HU; mode(xtrue(boolean(truth_mask)))];
           insert_diameter_pix = [insert_diameter_pix; 2*insert_r];
           dose_level = [dose_level; round(dose)];
           snr = [snr; res.snr];
           auc = [auc; res.auc];
           reader = [reader; n];

       end
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
