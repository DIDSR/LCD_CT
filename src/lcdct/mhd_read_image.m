function data = mhd_read_image(mhd_header)
%MHD_READ_IMAGE Summary of this function goes here
%   Detailed explanation goes here
if ~exist(mhd_header, 'file')
  error(sprintf('file %s not found', mhd_header))
end
info = mha_read_header(mhd_header);
if length(strsplit(info.DataFile, '%')) > 1
    [pathname, file, ext] = fileparts(info.Filename);
    file_base = strsplit(info.DataFile, '%'); file_base = file_base{1};
    files_list = dir(fullfile(pathname, [file_base, '*']));

    data = zeros(info.Dimensions);
    for i=1:length(files_list)
        fid = fopen(fullfile(pathname, files_list(i).name));
        data(:,:,i) = fread(fid, info.Dimensions(1:2), info.DataType);
        fclose(fid);
    end
    else
        data = mha_read_volume(info);
    end
end

