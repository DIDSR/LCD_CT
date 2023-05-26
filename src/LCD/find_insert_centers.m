function xtrue = find_insert_centers(extrue, smoothing_window_size, search_range)
  % :param extrue: high dose/low noise MITA-LCD image used to find centers
  % :param smoothing_window_size: [optional]
  % :param search_range: [optional]

  if ~exist('smoothing_window_size', 'var')
    smoothing_window_size = 11;
  end
  w = smoothing_window_size;
  
  if ~exist('search_range', 'var')
    search_range = [8 22]
  end
  imshow(extrue,[]);
  [c, r] = imfindcircles(medfilt2(extrue, [w w]), search_range);
  viscircles(c, r)
  out = input('Please confirm segmentation quality [y] or n');
  if isempty(out)
    out = 'y'
  end
  
  if out == 'y'
    xtrue = createCirclesMask(extrue, c, r);
  else
    xtrue = false;
  end
end


function mask = createCirclesMask(img,centers,radii)
xc = centers(:,1);
yc = centers(:,2);
mask_size = size(img);
xDim = mask_size(1);
yDim = mask_size(2);
[xx,yy] = meshgrid(1:yDim,1:xDim);
mask = zeros(xDim,yDim);

T = table(xc, yc, radii);
T_sorted = sortrows(T, 'radii');
known_HUs = [14, 7, 5, 3]; %sort radii from smallest to largest and assign these HU values
if is_octave
  T_sorted.insert_HU = known_HUs;
else
  T_sorted.insert_HU(:) = known_HUs;
end

for ii = 1:height(T_sorted)
    insert_mask = hypot(xx - T_sorted.xc(ii), yy - T_sorted.yc(ii)) <= T_sorted.radii(ii);
    insert_HU = T_sorted.insert_HU(ii);
    insert_subimage = insert_HU*insert_mask;
	mask = mask + insert_subimage;
end
end
