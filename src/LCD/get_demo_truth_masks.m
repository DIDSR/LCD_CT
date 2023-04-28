function truth_masks = get_demo_truth_masks(xtrue)
    roi_HUs = [14, 7, 5, 3];
    n_roi = length(roi_HUs);
    [nx, ny] = size(xtrue);
    truth_masks = zeros(nx, ny, n_roi);

    for i = 1:n_roi
        truth_mask = xtrue == roi_HUs(i);
        truth_masks(:, :, i) = medfilt2(truth_mask); %this shouldn't be necesarry but defining the truth mask is up to the user
    end
end