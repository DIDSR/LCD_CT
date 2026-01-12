function T = readtable_octave(fname)
[observer, insert_HU, dose_level, snr, auc, reader] = textread(fname,'%s, %d, %d, %f, %f, %d\n', 'headerlines', 1, 'delimiter', ',');
T = table(observer, insert_HU, dose_level, snr, auc, reader);
end
