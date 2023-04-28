function im = imread_raw(fname, imsize, offset, dtype)
    % im = imread_raw(fname, imsize, offset, dtype)
    % see help fread for more

    if ~exist('imsize', 'var')
        error('must specify image size in pixels [nx, ny]')
    end

    if max(size(imsize)) < 2
        imsize = [imsize imsize];
    end  
    
    if ~exist('offset', 'var')
        offset = 0;
    end

    if ~exist('dtype', 'var')
        dtype = 'int16';
    end
    dtype = string(dtype);

    fid = fopen(fname);
    im = fread(fid, imsize, dtype) - offset;
    fclose(fid);

end