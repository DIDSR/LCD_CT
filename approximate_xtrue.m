function xtrue = approximate_xtrue(base_directory, ground_truth_filename, offset)
    if ~exist('offset', 'var')
        offset = 1000;
    end
    signal_present_dir = fullfile(base_directory, 'dose_100', 'signal_present');
    signal_absent_dir = fullfile(base_directory, 'dose_100', 'signal_absent');

    sp_raw_array = mhd_read_image(fullfile(signal_present_dir, 'signal_present.mhd')) - offset;
    sa_raw_array = mhd_read_image(fullfile(signal_absent_dir, 'signal_absent.mhd')) - offset;
    low_noise_signal = mean(sp_raw_array, 3) - mean(sa_raw_array, 3);
    xtrue = find_insert_centers(low_noise_signal);
    f = mhd_write_volume(ground_truth_filename, xtrue + offset);
end