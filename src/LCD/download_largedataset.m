function large_dataset_directory = download_largedataset(dataset_url, large_dataset_directory)
%DOWNLOAD_LARGEDATASET Summary of this function goes here
%   Detailed explanation goes here
    if ~exist('dataset_url', 'var')
        dataset_url = 'https://zenodo.org/record/7991067/files/large_dataset.zip';
    end
    if ~exist('large_dataset_directory', 'var')
        large_dataset_directory = 'data';
        mkdir
    large_dataset_directory = fullfile(base_directory, 'large_dataset');
    if ~exist(large_dataset_directory, 'dir')
        disp(['dataset not found in: ', base_directory])
        disp('now downloading from ')
        disp(dataset_url)
        unzip(dataset_url, base_directory);
    end
end

