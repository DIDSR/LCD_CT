function plot_objects = plot_results(results, set_ylim, insert_names)
    % Plot results for various dose levels, observers, and insert sizes
    % :param results: Table or csv filename of LCD results from `measure_LCD`
    % :param set_ylim: y limits for plotting AUC (optional)
    % :param insert_names: (optional) Custom names for each insert in the order they appear

    % Default values
    if ~exist('results', 'var')
        results = "results_demo_02.csv";  % Example result file
    end

    if ~exist('set_ylim', 'var')
        set_ylim = [];
    end

    % Handle different data types
    switch class(results)
        case "table"
            res_table = results;
        case {"char", "string"}
            res_table = readtable(results);
        case {"double", "uint16"}
            res_table = results;
    end

    % Extract unique observers, dose levels, insert HU values, and recon types
    observers = unique(res_table.observer);
    dose_levels = unique(res_table.dose_level);
    insert_HUs = unique(res_table.insert_HU);
    
    % If 'recon' is not a column, initialize it
    if ~ismember('recon', res_table.Properties.VariableNames)
        res_table.recon(:) = "";  % Create empty 'recon' column
    end
    recons = unique(res_table.recon);

    % Determine number of inserts, observers, reconstructions, and doses
    ndoses = length(dose_levels);
    nobservers = length(observers);
    ninserts = length(insert_HUs);
    nrecons = length(recons);

    % Check if custom insert names were provided, otherwise use default names
    if ~exist('insert_names', 'var') || length(insert_names) ~= ninserts
        insert_names = cell(1, ninserts);  % Initialize cell array
        for inst_idx = 1:ninserts
            insert_HU = insert_HUs(inst_idx);
            switch insert_HU
                case 3
                    insert_names{inst_idx} = "10 mm";
                case 5
                    insert_names{inst_idx} = "7 mm";
                case 7
                    insert_names{inst_idx} = "5 mm";
                case 14
                    insert_names{inst_idx} = "3 mm";
                otherwise
                    insert_names{inst_idx} = sprintf('%d HU insert', insert_HU);
            end
        end
    end

    % Determine the layout for subplots based on the number of inserts
    subx = ceil(sqrt(ninserts));  % Rows
    suby = ceil(ninserts / subx);  % Columns

    plot_objects = [];

    % Iterate through each insert HU and plot the results
    for inst_idx = 1:ninserts
        means = zeros(ndoses, nobservers * nrecons);
        stds = zeros(ndoses, nobservers * nrecons);
        insert_HU = insert_HUs(inst_idx);
        recon_observer_pairs = [];
        idx = 1;

        % Nested loops for observers and reconstructions
        for obsv_idx = 1:nobservers
            for recon_idx = 1:nrecons
                recon_observer_pairs = [recon_observer_pairs; ...
                                        recons(recon_idx) + " " + observers(obsv_idx)];
                
                % Loop over dose levels
                for dose_idx = 1:ndoses
                    table_filter = res_table.insert_HU == insert_HU & ...
                                   string(res_table.observer) == string(observers(obsv_idx)) & ...
                                   res_table.dose_level == dose_levels(dose_idx) & ...
                                   string(res_table.recon) == string(recons(recon_idx));
                    
                    % Calculate means and standard deviations for filtered data
                    if sum(table_filter) > 0
                        means(dose_idx, idx) = mean(res_table.auc(table_filter));
                        stds(dose_idx, idx) = std(res_table.auc(table_filter));
                    else
                        means(dose_idx, idx) = NaN;  % Leave NaN for invalid means
                        stds(dose_idx, idx) = 0;    % Replace NaN stds with 0
                    end
                end
                idx = idx + 1;
            end
        end

        % Remove NaN values from the means array (but not stds)
        valid_means = means;
        valid_means(isnan(valid_means)) = 0;  % Replace NaN means with 0 for plotting
        
        % Plotting in subplots
        subplot(subx, suby, inst_idx);
        plot_objects(inst_idx).series = [];

        if length(dose_levels) < 2
            % Bar plot if fewer than 2 dose levels
            bar(categorical(recon_observer_pairs), valid_means);
            hold on;
            errorbar(categorical(recon_observer_pairs), valid_means, stds, "LineStyle", "none");
            hold off;
        else
            % Line plot for multiple dose levels
            plot_objects(inst_idx).series = errorbar(repmat(dose_levels, [1, nobservers * nrecons]), valid_means, stds);
            
            % Color each series differently
            colorVec = {'b', 'r', 'y', 'm', 'g', 'c'};
            c_idx = 1;
            for i = 1:length(plot_objects(inst_idx).series)
                plot_objects(inst_idx).series(i).LineStyle = '-';
                plot_objects(inst_idx).series(i).Color = colorVec{mod(i-1, length(colorVec)) + 1};
            end
        end

        % Set labels and title
        xlabel('Dose Level (%)');
        ylabel('AUC');
        title(insert_names{inst_idx});  % Use custom insert names for titles

        % Set legend and y-limits
        legend(recon_observer_pairs, 'Interpreter', 'none');
        if ~isempty(set_ylim)
            ylim(set_ylim);
        end
    end
end



