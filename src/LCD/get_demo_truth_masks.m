function truth_masks = get_demo_truth_masks(xtrue, tol)
    % :param tol: relative tolerance
    if ~exist('tol', 'var')
        tol = 1;
    end
    roi_HUs = [14, 7, 5, 3];
    n_roi = length(roi_HUs);
    [nx, ny] = size(xtrue);
    truth_masks = zeros(nx, ny, n_roi);

    for i = 1:n_roi
        truth_mask = xtrue == roi_HUs(i);
        truth_mask = abs(double(xtrue) - roi_HUs(i)) < tol;
        truth_mask =  medfilt2(truth_mask); %this shouldn't be necesarry but defining the truth mask is up to the user
        truth_masks(:, :, i) = truth_mask;
    end
end