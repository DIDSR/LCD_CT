function plot_results(results)
% results can be a csv filename, Matlab Table, or 2D array
%% plotting examples

if ~exist('results', 'var')
   results = "results_demo_02.csv";
end

if is_octave
readtable =@(fname) readtable_octave(fname)
end

switch class(results)
    case "table"
        res_table = results;
    case "char"
        res_table = readtable(results);
    case "string"
        res_table = readtable(results);
    case "double"
        res_table = results;
    case "uint16"
        res_table = results;
end

if is_octave
  observers = unique(cellstr(res_table.observer))
else
  observers = unique(res_table.observer);
end
dose_levels = unique(res_table.dose_level);
insert_HUs = unique(res_table.insert_HU);

ndoses = length(dose_levels);
nobservers = length(observers);
ninserts = length(insert_HUs);

switch ninserts
  case 1
    subx = 1; suby = 1;
   case 2
    subx = 1; suby = 2;
   otherwise
    subx = 2; suby = 2;
end

for inst_idx = 1:ninserts
    means = zeros(ndoses, nobservers);
    stds = zeros(ndoses, nobservers);
    insert_HU = insert_HUs(inst_idx);
    for obsv_idx = 1:nobservers
        for dose_idx = 1:ndoses
            table_filter = res_table.insert_HU == insert_HU & ...
                           string(res_table.observer) == string(observers(obsv_idx)) & ...
                           res_table.dose_level == dose_levels(dose_idx);
            means(dose_idx, obsv_idx) = mean(res_table.auc(table_filter));
            stds(dose_idx, obsv_idx) = std(res_table.auc(table_filter));
        end
    end
    subplot(subx,suby,inst_idx);
    errorbar(repmat(dose_levels, [1 nobservers]), means, stds)

    switch insert_HU
        case 3
            insert_size = "10 mm";
        case 5
            insert_size = "7 mm";
        case 7
            insert_size = "5 mm";
        case 14
            insert_size = "3 mm";
        otherwise
            insert_size = "";
    end
    title(sprintf('%s, %d HU insert', insert_size, insert_HU))
    ylabel('AUC')
    xlabel('dose level %')
    legend(observers)
end

end
