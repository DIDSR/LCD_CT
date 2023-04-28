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
addpath(genpath('bin'))

if ~exist('base_dir', 'var')
    base_dir = ''; %<-- Replace with directory containing large data set
end

offset = 1000;

ground_truth_fname = fullfile(base_dir, 'ground_truth.mhd');
if ~exist(ground_truth_fname, 'file')
   data_dir = input(['No dataset found in: ', base_dir, 'Please enter a target directory to download dataset (~1 gb) or hit enter for default [./data]:'],'s');
   if isempty(data_dir)
      data_dir = './data';
   end
   mkdir(data_dir)
   what_obj = what(data_dir);
   data_dir = what_obj.path;
   disp(['Downloading MITA LCD dataset from https://sandbox.zenodo.org/record/1150650 (~ 1gb) to `', data_dir, '`...'])
   if is_octave
    fname = urlwrite('https://sandbox.zenodo.org/record/1150650/files/MITA_LCD.zip', fullfile(data_dir, 'MITA_LCD.zip'))
   else
    fname = websave(fullfile(data_dir, 'MITA_LCD.zip'),'https://sandbox.zenodo.org/record/1150650/files/MITA_LCD.zip');
   end
   unzip(fname, data_dir);
   [FILEPATH, NAME, ~] = fileparts(fname);
   base_dir = fullfile(FILEPATH, NAME);
   delete(fname)
   disp(['Dataset saved to ', base_dir])
   clear FILEPATH NAME what_obj
end

xtrue = mhd_read_image(ground_truth_fname) - offset; %need to build in offset to dataset
% input is a binary mask specifying signal known exactly (SKE)

truth_masks = get_demo_truth_masks(xtrue);

insert_rs = [];
n_inserts = size(truth_masks, 3);
for i=1:n_inserts
    insert_r = get_insert_radius(truth_masks(:,:,i));
    insert_rs = [insert_rs insert_r];
end
crop_r = max(insert_rs);
%% define observers
observers_list = {LG_CHO_2D(),... % will need to modify .channel_width attribute later when insert width known
                  DOG_CHO_2D(),...
                  GABOR_CHO_2D(),...
                  NPWE_2D(),...
                  NPWE_2D(1)
                 };
%% iterate through conditions

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

for i=1:length(observers_list)
    model_observer = observers_list{i};

    dose_level_dirs = dir(fullfile(base_dir, 'dose_*'));

    for d=1:length(dose_level_dirs)
        dose_level_dir = dose_level_dirs(d);
        dose = str2double(dose_level_dir.name(6:end));

        signal_present_dir = fullfile(base_dir, dose_level_dir.name, 'signal_present');
        signal_absent_dir = fullfile(base_dir, dose_level_dir.name, 'signal_absent');

        sp_raw_array = mhd_read_image(fullfile(signal_present_dir, 'signal_present.mhd')) - offset;
        sa_raw_array = mhd_read_image(fullfile(signal_absent_dir, 'signal_absent.mhd')) - offset;

        for insert_idx = 1:n_inserts
            truth_mask = truth_masks(:, :, insert_idx);
            insert_r = get_insert_radius(truth_mask);
            if isa(model_observer, "LG_CHO_2D")
                model_observer.channel_width = 2/3*insert_r; % necesarry for LG_CHO to update channel width based on expected lesion size
            end

            sp_imgs = get_ROI_from_truth_mask(truth_mask, sp_raw_array, 2*crop_r);
            sa_imgs = get_ROI_from_truth_mask(truth_mask, sa_raw_array, 2*crop_r);

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
