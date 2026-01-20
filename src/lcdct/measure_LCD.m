function results = measure_LCD(varargin)
% given a dataset calculate low contrast detectability as auc curves and return as a table ready for saving or plotting
% 
% Usage:
% 1. measure_LCD(signal_present_array, signal_absent_array, ground_truth, observers, n_reader, pct_split, seed_split)
% 2. measure_LCD(base_directory, observers, ground_truth, offset, n_reader, pct_split, seed_split)
%
% :param signal_present_array: image stack of signal present images
% :param signal_absent_array: corresponding image stack of signal absent images
% :param base_directory: path to directory containing 'signal_present' and 'signal_absent' subfolders
% :param observers: list of observer objects or strings of name of observers. Options: LG_CHO_2D, DOG_CHO_2D, GABOR_CHO_2D
% :param ground_truth: image or filename of image with no noise of MITA LCD phantom
% :param offset: offset value to subtract from loaded images (only used with directory input)
% :param n_reader: number of readers (default is 10)
% :param pct_split: percent of images to be used for training (default is 0.5)
% :param seed_split: 1d vector containing 'nreader' of random seed values
% 
% :return results: table (or struct in Octave) ready for saving or plotting

if is_octave
    if length(pkg('list', 'image')) < 1
        pkg install -forge image
    end
  pkg load image
end

% Parse inputs
arg1 = varargin{1};
dose_level_extracted = NaN;

if ischar(arg1) || (isstring(arg1) && isscalar(arg1))
    % Signature 2: Directory input
    base_dir = char(arg1);
    observers = varargin{2};
    ground_truth = varargin{3};
    if length(varargin) >= 4
        offset = varargin{4};
    else
        offset = 0;
    end
    if length(varargin) >= 5; n_reader = varargin{5}; end
    if length(varargin) >= 6; pct_split = varargin{6}; end
    if length(varargin) >= 7; seed_split = varargin{7}; end

    % Load images
    sp_dir = fullfile(base_dir, 'signal_present');
    sa_dir = fullfile(base_dir, 'signal_absent');

    sp_mhd = fullfile(sp_dir, 'signal_present.mhd');
    if exist(sp_mhd, 'file')
        signal_present_array = mhd_read_image(sp_mhd);
    else
         error(['Could not find ' sp_mhd]);
    end

    sa_mhd = fullfile(sa_dir, 'signal_absent.mhd');
     if exist(sa_mhd, 'file')
        signal_absent_array = mhd_read_image(sa_mhd);
    else
         error(['Could not find ' sa_mhd]);
    end

    if offset ~= 0
        signal_present_array = signal_present_array - offset;
        signal_absent_array = signal_absent_array - offset;
    end

    % Try to extract dose from base_dir path
    [~, name, ~] = fileparts(base_dir);
    % Check for dose_XXX format
    tokens = regexp(name, 'dose_(\d+)', 'tokens');
    if ~isempty(tokens)
        dose_level_extracted = str2double(tokens{1}{1});
    end

else
    % Signature 1: Array input
    signal_present_array = varargin{1};
    signal_absent_array = varargin{2};
    ground_truth = varargin{3};
    observers = varargin{4};
    if length(varargin) >= 5; n_reader = varargin{5}; end
    if length(varargin) >= 6; pct_split = varargin{6}; end
    if length(varargin) >= 7; seed_split = varargin{7}; end
end

% Default values
if ~exist('n_reader','var'); n_reader = 10; end
if ~exist('pct_split','var'); pct_split = 0.5; end
if ~exist('seed_split','var'); seed_split = randi(10000, n_reader, 1); end

% Instantiate observers if strings are passed
observer_objs = cell(1, length(observers));
for i=1:length(observers)
    obs = observers{i};
    if ischar(obs) || (isstring(obs) && isscalar(obs))
         switch upper(obs)
            case 'LG_CHO_2D'
                observer_objs{i} = LG_CHO_2D();
            case 'NPWE_2D'
                observer_objs{i} = NPWE_2D();
            case 'DOG_CHO_2D'
                observer_objs{i} = DOG_CHO_2D();
            case 'GABOR_CHO_2D'
                observer_objs{i} = GABOR_CHO_2D();
            otherwise
                error([obs ' not in LG_CHO_2D, DOG_CHO_2D, GABOR_CHO_2D, NPWE_2D'])
        end
    else
        % Assuming it is already an object
        observer_objs{i} = obs;
    end
end
observers = observer_objs;

% input is a binary mask specifying signal known exactly (SKE)
truth_masks = get_demo_truth_masks(ground_truth);

insert_rs = [];
n_inserts = size(truth_masks, 3);
for i=1:size(truth_masks, 3)
    crop_r = max(insert_rs);
    truth_mask = truth_masks(:,:,i);
    if sum(truth_mask(:)) < 1
        continue
    end
    insert_r = get_insert_radius(truth_mask);
    insert_rs = [insert_rs insert_r];
end

observer = [];
snr = [];
auc = [];
reader = [];
insert_HU = [];
insert_diameter_pix = [];

for i=1:length(observers)
    model_observer = observers{i};

    for insert_idx = 1:n_inserts
        truth_mask = truth_masks(:, :, insert_idx);
        if sum(truth_mask(:)) < 1
            continue
        end
        insert_r = get_insert_radius(truth_mask);
        if isa(model_observer, "LG_CHO_2D")
            model_observer.channel_width = 2/3*insert_r; % necesarry for LG_CHO to update channel width based on expected lesion size
        end

        sp_imgs = get_ROI_from_truth_mask(truth_mask, signal_present_array, 2*crop_r);
        sa_imgs = get_ROI_from_truth_mask(truth_mask, signal_absent_array, 2*crop_r);

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
            evalc("res = model_observer.perform_study(sa_train, sp_train, sa_test, sp_test);");
            if is_octave
                observer = strvcat(observer, model_observer.type);
            else
                observer = [string(observer); string(model_observer.type)];
            end
            insert_HU = [insert_HU; mode(ground_truth(logical(truth_mask)))];
            insert_diameter_pix = [insert_diameter_pix; 2*insert_r];
            snr = [snr; res.snr];
            auc = [auc; res.auc];
            reader = [reader; n];
        end
    end
end

results_dict.observer = observer;
results_dict.insert_HU = insert_HU;
results_dict.snr = snr;
results_dict.auc = auc;
results_dict.reader = reader;
results_dict.diameter = insert_diameter_pix;
results_dict.dose_level = repmat(dose_level_extracted, length(auc), 1);

if is_octave
    pkg load tablicious
end

results = struct2table(results_dict);

end
