function cropped_img = get_ROI_from_truth_mask(bw_truth_mask, img, nx)
% return bounding box region of interest around a known signal
% ===
% inputs: bw_truth_mask - a binary image with a one signal, will error if
% multiple signals are provided
% img: image to crop around the truth signal and return
% nx: matrix size (area around the signal to crop) optional, if left
% unspecified, will grab bounding box width
% ===
% outputs: cropped_img

roi_properties = regionprops(bw_truth_mask);

y = round(roi_properties.Centroid(1));
x = round(roi_properties.Centroid(2));

if ~exist('nx', 'var')
    ny = round(roi_properties.BoundingBox(3)/2);
    nx = round(roi_properties.BoundingBox(4)/2);
else
    nx = round(nx / 2);
    ny = nx;
end

cropped_img = img(x - nx: x + nx, y - ny: y + ny, :);
end

