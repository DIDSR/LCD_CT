function im_array = read_raw_images_from_directory(dirname, imread_func)

    file_list = dir(fullfile(dirname));
    n_files = length(file_list) - 2;

    fname = fullfile(dirname, file_list(1 + 2).name);
    first_img = imread_func(fname);
    imsize = size(first_img);
        
    im_array = zeros(imsize(1), imsize(2), n_files);
    im_array(:,:,1) = first_img;
    for i=2:n_files
        fname = fullfile(dirname, file_list(i + 2).name);
        im_array(:, :, i) = imread_func(fname);
    end
end