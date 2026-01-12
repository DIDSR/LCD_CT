function r = get_insert_radius(truth_mask)
    shape_info = regionprops(truth_mask);
    r = max(shape_info.BoundingBox(3:4));
end