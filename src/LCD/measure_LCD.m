function res_table = measure_LCD(base_dir, observers, ground_truth, offset, n_reader, pct_split, seed_split)
% given a dataset calculate low contrast detectability as auc curves and return as a table ready for saving or plotting
% 
% :param base_dir: directory containing dataset
% :param observers: list of observer objects or strings of name of observers. Options: LG_CHO_2D, DOG_CHO_2D, GABOR_CHO_2D
% :param ground_truth: image or filename of image with no noise of MITA LCD phantom, see `approximate_groundtruth` for details on how to turn repeat scans into a ground truth image
% :param offset: an optional offset subtracted from each image (default 0)
% :param n_reader: number of readers (default is 10)
% :param pct_split: percent of images to be used for training, remainder (1 - split_pct) to be used for testing (default is 0.5)
% :param seed_split: 1d vector containing 'nreader' of random seed values. (defaults to randomly selected seed) 
% 
% :return res_table: table ready for saving or plotting

%% define observers
if ~exist('observers', 'var')
    observers = {LG_CHO_2D()};
%   observers = {LG_CHO_2D(),... % will need to modify .channel_width attribute later when insert width known
%                     DOG_CHO_2D(),...
%                     GABOR_CHO_2D(),...
%                     };
end

%% check for ground truth
if ~exist('ground_truth', 'var')
    ground_truth_fname = fullfile(base_dir, 'ground_truth.mhd');
    offset = 1000;
    ground_truth = mhd_read_image(ground_truth_fname) - offset; %need to build in offset to dataset
end

if ~exist('offset', 'var')
    offset = 0;
end
if ~exist('n_reader','var')
    n_reader = 10;
end
if ~exist('pct_split','var')
    pct_split = 0.5;
end
if ~exist('seed_val','var')
    seed_split = randi(10000, n_reader, 1);
end
% input is a binary mask specifying signal known exactly (SKE)

truth_masks = get_demo_truth_masks(ground_truth);

insert_rs = [];
n_inserts = size(truth_masks, 3);
for i=1:n_inserts
    crop_r = max(insert_rs);
    insert_r = get_insert_radius(truth_masks(:,:,i));
    insert_rs = [insert_rs insert_r];
end

%% iterate through conditions

dose = [];
%n_reader = 10;

observer = [];
dose_level = [];
snr = [];
auc = [];
reader = [];
insert_HU = [];
insert_diameter_pix = [];

for i=1:length(observers)
    model_observer = observers{i};

    dose_level_dirs = dir(fullfile(base_dir, 'dose_*'));
    if length(dose_level_dirs) < 1
        clear dose_level_dirs
        [filepath, name, ext] = fileparts(base_dir);
        if ~startsWith(name, 'dose_')
            error('please check that `base_directory` is named `dose_XXX` or contains a `dose_level` folder')
        end
        dose_level_dirs.name = char(name);
        base_dir = filepath;
    end

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
            
            % remove the dc component in images which human eyes do not perceive.
            for i_sp = 1:size(sp_imgs,3)
                 dummy = sp_imgs(:,:,i_sp);
                 dc_val = mean(dummy(:));
                 sp_imgs(:,:,i_sp) = sp_imgs(:,:,i_sp)-dc_val;
             end
             for i_sa = 1:size(sa_imgs,3)
                 dummy = sa_imgs(:,:,i_sa);
                 dc_val = mean(dummy(:));
                 sa_imgs(:,:,i_sa) = sa_imgs(:,:,i_sa)-dc_val;
             end

           for n=1:n_reader
               [sa_train, sa_test, sp_train, sp_test] = train_test_split(sa_imgs, sp_imgs, pct_split, seed_split(n));
               res = model_observer.perform_study(sa_train, sp_train, sa_test, sp_test);
               if is_octave
                   observer = strvcat(observer, model_observer.type);
               else
                   observer = [string(observer); string(model_observer.type)];
               end
               insert_HU = [insert_HU; mode(ground_truth(logical(truth_mask)))];
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

end
