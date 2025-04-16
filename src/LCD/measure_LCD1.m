function res_table = measure_LCD_single_dose(signal_present_img, signal_absent_img, observers, ground_truth, offset, n_reader, n_inserts, insert_r, load_coords_filename)
    % Calculate low contrast detectability using signal-present and signal-absent images.
    %
    % :param signal_present_img: The signal-present image
    % :param signal_absent_img: The signal-absent image (signal-free)
    % :param observers: List of observer objects or strings of the name of observers
    % :param ground_truth: Image or filename of the image with no noise of MITA LCD phantom
    % :param offset: An optional offset subtracted from each image (default 0)
    % :param n_reader: Number of readers (default is 10)
    % :param n_inserts: Number of inserts to be selected manually
    % :param insert_r: The radius of the inserts (same for all inserts)
    % :param load_coords_filename: Optional filename to load coordinates from (if it exists)
    %
    % :return res_table: Table ready for saving or plotting

    %% Define observers
    if ~exist('observers', 'var')
        observers = {LG_CHO_2D()};  % Default observer
    end
    pct_split = 0.5; 
    seed_split = randi(10000, n_reader, 1);

    %% Load or select coordinates
    if exist(load_coords_filename, 'file')
        % Load previously saved coordinates
        coords_data = load(load_coords_filename);
        x_coords = coords_data.x_coords;
        y_coords = coords_data.y_coords;
        disp('Loaded coordinates from file.');
    else
        % Manually select the coordinates for each insert using ginput
        centerSliceIndex = round(size(signal_present_img, 3) / 2);
        figure; imagesc(signal_present_img(:, :, centerSliceIndex)); colormap gray; axis off; axis tight; axis equal; 
        title('Select centers of the inserts');
        disp(['Please select ', num2str(n_inserts), ' insert locations']);
        [x_coords, y_coords] = ginput(n_inserts);  % Get n_insert points manually
        
        % Automatically save the coordinates to a file
        coords_data.x_coords = x_coords;
        coords_data.y_coords = y_coords;
        save(load_coords_filename, '-struct', 'coords_data');
    end

    % Use the same radius for all inserts, defined by the input parameter `insert_r`
    insert_rs = ones(1, n_inserts) * insert_r;  % Set the same radius for all inserts

    %% Subtract offset from signal-present and signal-absent images
    sp_raw_array = signal_present_img - offset;
    sa_raw_array = signal_absent_img - offset;

    % Initialize arrays for storing results
    observer = [];
    dose_level = [];
    snr = [];
    auc = [];
    reader = [];
    insert_HU = [];
    insert_diameter_pix = [];

    %% Iterate through inserts and observers
    for i = 1:length(observers)
        model_observer = observers{i};

        for insert_idx = 1:n_inserts
            % Get the manually selected insert coordinates and radius
            x_center = round(x_coords(insert_idx));
            y_center = round(y_coords(insert_idx));

            % Update observer properties (if necessary)
            if isa(model_observer, "LG_CHO_2D")
                model_observer.channel_width = 2 / 3 * insert_r;  % Update channel width for LG_CHO observer
            end

            %% Extract regions of interest (ROIs) using the manually selected center and radius
            sp_imgs = get_ROI_from_manual_selection(sp_raw_array, x_center, y_center, insert_r);
            sa_imgs = get_ROI_from_manual_selection(sa_raw_array, x_center, y_center, insert_r);

            % Remove DC component (mean intensity) from images
            for i_sp = 1:size(sp_imgs, 3)
                sp_imgs(:, :, i_sp) = sp_imgs(:, :, i_sp) - mean(sp_imgs(:, :, i_sp), 'all');
            end
            for i_sa = 1:size(sa_imgs, 3)
                sa_imgs(:, :, i_sa) = sa_imgs(:, :, i_sa) - mean(sa_imgs(:, :, i_sa), 'all');
            end

            %% Perform observer study
            for n = 1:n_reader
                % Split the data into training and testing sets
                [sa_train, sa_test, sp_train, sp_test] = train_test_split(sa_imgs, sp_imgs, pct_split, seed_split(n));

                % Perform the observer study
                res = model_observer.perform_study(sa_train, sp_train, sa_test, sp_test);

                % Store the results
                observer = [observer; string(model_observer.type)];
                insert_HU = [insert_HU; mode(ground_truth(y_center, x_center))];  % Use the ground truth at the selected point
                insert_diameter_pix = [insert_diameter_pix; 2 * insert_r];
                dose_level = [dose_level; 1];  % Since you have only one dose level, set it to 1
                snr = [snr; res.snr];
                auc = [auc; res.auc];
                reader = [reader; n];
            end
        end
    end

    % Return results as a table
    res_table = table(observer, insert_HU, dose_level, snr, auc, reader, insert_diameter_pix);
end
