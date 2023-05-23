function res_table = make_auc_curve(base_dir)
% given a dataset calculate auc curves and return as a table ready for saving or plotting
% 
% :param base_dir: directory containing dataset
%
% :return res_table: table ready for saving or plotting

offset = 1000;

ground_truth_fname = fullfile(base_dir, 'ground_truth.mhd');

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
    error('octave')
%     string = @(x) x;
%     boolean = @(x) logical(x);
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

end