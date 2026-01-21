function fname = write_lcd_results(res_table, fname)
% write low contrast detectability measures to csv file
%
% :param res_table: Matlab or Octave table containing LCD results
% :param fname: file name of csv file to be saved

if is_octave
  headers = ["observer,recon,diameter,insert_HU,dose_level,snr,auc,reader"];
  fid = fopen(fname, 'w'); fdisp(fid, headers);
  for r=1:length(res_table.dose_level)
    obs_val = res_table.observer(r, :);
    if iscell(obs_val), obs_val = obs_val{1}; end
    recon_val = res_table.recon(r, :);
    if iscell(recon_val), recon_val = recon_val{1}; end
    
    fprintf(fid, "%s, %s, %d, %d, %d, %f, %f, %d\n",...
          obs_val,...
          recon_val,...
          res_table.diameter(r),...
          res_table.insert_HU(r),...
          res_table.dose_level(r),...
          res_table.snr(r),...
          res_table.auc(r),...
          res_table.reader(r));
  end
  fclose(fid);
else
  writetable(res_table, fname);
end

end

