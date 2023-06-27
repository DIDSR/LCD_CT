function ground_truth = approximate_groundtruth(base_directory, ground_truth_filename, offset)
% given a `base_directory` with many repeat scans of signal-present and signal-absent images estimate a ground truth image by avaging the repeat images and subtracting background images to get signal only images. Filtering and segmentation are applied to approximate ground truth masks with no noise.
%
% :param base_directory: directory containing `dose_100` directory and two subdirectories `signal_present` and `signal_absent` each with repeat images like so:
%
% |-- dose_100
% |   |-- signal_absent
% |   |   |-- signal_absent_001.raw
% |   |   |-- signal_absent_002.raw
% |   |   |-- signal_absent_XXX.raw
% |   |   |-- signal_absent.mhd
% |   |-- signal_present
% |       |-- signal_present_001.raw
% |       |-- signal_present_002.raw
% |       |-- signal_present_XXX.raw
% |       |-- signal_present.mhd
%
% :param ground_truth_filename: [optional] full pathname to the file where the estimagte ground truth image will be saved to. Defaults to `ground_truth.mhd`
% :param offset: [optional] subtract a constant HU value from all pixels. Can be useful if loading from int16 images where only positive values ares kept, thus subtracting an offset would yield the correct HU alues, say negative values in air.
%
% :return ground_truth: ground truth image used as input for themake_auc
    if ~exist('offset', 'var')
        offset = 1000;
    end
    if ~exist('ground_truth_filename', 'var')
        ground_truth_filename = 'ground_truth.mhd';
    end
    signal_present_dir = fullfile(base_directory, 'dose_100', 'signal_present');
    signal_absent_dir = fullfile(base_directory, 'dose_100', 'signal_absent');

    sp_raw_array = mhd_read_image(fullfile(signal_present_dir, 'signal_present.mhd')) - offset;
    sa_raw_array = mhd_read_image(fullfile(signal_absent_dir, 'signal_absent.mhd')) - offset;
    low_noise_signal = mean(sp_raw_array, 3) - mean(sa_raw_array, 3);
    ground_truth = find_insert_centers(low_noise_signal);
    f = mhd_write_volume(ground_truth_filename, ground_truth + offset);
end
