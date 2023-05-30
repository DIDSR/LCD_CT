function plot_objects = plot_results(results, set_ylim)
% results can be a csv filename, Matlab Table, or 2D array
% :param results: Table or csv filename of LCD results from `make_auc_curve`
% :param set_ylim: y limits for plotting AUC
% :param comparison: (default is none []) method for comparing different recons
%% plotting examples

if ~exist('results', 'var')
   results = "results_demo_02.csv";
end

if ~exist('set_ylim', 'var')
    set_ylim = [];
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

if ~ismember('recon', res_table.Properties.VariableNames)
  if is_octave
    res_table.recon = "";
  else
    res_table.recon(:) = "";
  end
end
recons = unique(res_table.recon);

ndoses = length(dose_levels);
nobservers = length(observers);
ninserts = length(insert_HUs);
nrecons = length(recons);

switch ninserts
  case 1
    subx = 1; suby = 1;
   case 2
    subx = 1; suby = 2;
   otherwise
    subx = 2; suby = 2;
end


for inst_idx = 1:ninserts
    means = zeros(ndoses, nobservers*nrecons);
    stds = zeros(ndoses, nobservers*nrecons);
    insert_HU = insert_HUs(inst_idx);
    recon_observer_pairs = [];
    idx = 1;
    for obsv_idx = 1:nobservers
        for recon_idx = 1:nrecons
          if is_octave
            recon_observer_pairs = strvcat([recons{recon_idx} ' ' observers{obsv_idx}], recon_observer_pairs);
          else
            recon_observer_pairs = [recons(recon_idx) + " "...
                                   + observers(obsv_idx), recon_observer_pairs];
          end
            for dose_idx = 1:ndoses
                table_filter = res_table.insert_HU == insert_HU & ...
                               string(res_table.observer) == string(observers(obsv_idx)) & ...
                               res_table.dose_level == dose_levels(dose_idx) & ...
                               string(res_table.recon) == string(recons(recon_idx));
                means(dose_idx, idx) = mean(res_table.auc(table_filter));
                stds(dose_idx, idx) = std(res_table.auc(table_filter));
            end
            idx = idx + 1;
        end
    end
    subplot(subx,suby,inst_idx);
    plot_objects = [];
    if length(dose_levels) < 2 & ~is_octave
       bar(categorical(recon_observer_pairs), means)
       hold on
       errorbar(categorical(recon_observer_pairs), means, stds, "LineStyle","none")
       hold off
    else
        plot_objects = errorbar(repmat(dose_levels, [1 nobservers*nrecons]), means, stds);
        colorVec = {'b', 'r', 'y', 'm', 'g', 'c'};
        c_idx = 1;
        if ~is_octave
          for i =1:length(plot_objects)
              if mod(i, nrecons)==0
                  plot_objects(i).LineStyle = '--';
                  plot_objects(i).Color = colorVec{c_idx};
                  c_idx = c_idx + 1;
              else
                  plot_objects(i).LineStyle = '-';
                  plot_objects(i).Color = colorVec{c_idx};
              end
          end
        end    
        xlabel('dose level %')
        legend(recon_observer_pairs)
    end
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
    if ~isempty(set_ylim)
        ylim(set_ylim);
    end
    ylabel('AUC')
    title(sprintf('%s, %d HU insert', insert_size, insert_HU))
end

end
