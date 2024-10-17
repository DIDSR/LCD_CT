function roi = get_ROI_from_manual_selection(img, x_center, y_center, r)
    % Extract a square region from the image centered on (x_center, y_center) with radius r

    [rows, cols,slices] = size(img);
    
    % Define the bounding box for the region
    x_min = max(1, x_center - r);
    x_max = min(cols, x_center + r);
    y_min = max(1, y_center - r);
    y_max = min(rows, y_center + r);
    
    % Extract the region of interest
    roi = img(y_min:y_max, x_min:x_max,:);  
end