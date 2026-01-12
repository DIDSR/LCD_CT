function large_dataset_directory = download_largedataset(large_dataset_directory)
%DOWNLOAD_LARGEDATASET Summary of this function goes here
%   Detailed explanation goes here
    if ~exist('large_dataset_directory', 'var')
        large_dataset_directory = 'data';
    end
    if ~exist(large_dataset_directory, 'dir')
        mkdir(large_dataset_directory)
    end
    dataset_url = 'https://zenodo.org/record/7996580/files/large_dataset.zip';
    disp('now downloading from ')
    disp(dataset_url)
    unzip(dataset_url, large_dataset_directory);
end

