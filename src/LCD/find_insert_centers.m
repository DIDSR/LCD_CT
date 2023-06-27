function xtrue = find_insert_centers(signal_present_image, smoothing_window_size, search_range)
% given a signal-present MITA-LCD image with 14, 7, 5, and 3 HU inserts, segment the inserts and yield a noise-free ground truth mask
% :param signal_present_image: high dose/low noise MITA-LCD signal-present image used to find centers
% :param smoothing_window_size: [optional] defaults to 11 pixels wide. Larger values can be used to increase smoothing of image to help find circlular inserts in highly noisy images
% :param search_range: [optional] circle radius serch range in pixels to detect circlar inserts. Try `help imfindcircles` to learn more

  if ~exist('smoothing_window_size', 'var')
    smoothing_window_size = 11;
  end
  w = smoothing_window_size;

  if ~exist('search_range', 'var')
    search_range = [7 22]
  end
  imshow(signal_present_image,[]);
  [c, r] = imfindcircles(medfilt2(signal_present_image, [w w]), search_range);
  viscircles(c, r)
  out = input('Please confirm segmentation quality [y] or n');
  if isempty(out)
    out = 'y'
  end

  if out == 'y'
    xtrue = createCirclesMask(signal_present_image, c, r);
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
  T_sorted.insert_HU = known_HUs';
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
