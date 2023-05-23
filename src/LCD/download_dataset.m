function base_dir = download_dataset(dataset_url, local_dir, request_input)
% Download and unzip dataset from Zenodo online storage
%
% :param dataset_url: Zenodo url to a zipfile dataset
% :param local_dir: Local directory to save dataset to [optional]. If not 
% :param request_input: logical, defaults to true, if set to false dataset will download to current directory '.'
% 
% :return: local_dir: the local directory the dataset was saved to
if ~exist('request_input', 'var')
    request_input = true;
end

default_dir = './data'
if ~exist(local_dir, 'var')
   if request_input
    data_dir = input(['No dataset found in: ', local_dir, '\nPlease enter a target directory to download dataset or hit enter for default: [', default_dir, ']'],'s');
   else
       data_dir = '.';
   end
   if isempty(data_dir)
      data_dir = default_dir;
   end
   mkdir(data_dir)
   what_obj = what(data_dir);
   data_dir = what_obj.path;
   disp(['Downloading MITA LCD dataset from ', dataset_url, ' to ', data_dir, '...'])
   if is_octave
    disp('Please be patient when using Octave, saving large files takes longer than with Matlab')
    fname = urlwrite(dataset_url, fullfile(data_dir, 'MITA_LCD.zip'))
   else
    fname = websave(fullfile(data_dir, 'MITA_LCD.zip'), dataset_url);
   end
   unzip(fname, data_dir);
   [FILEPATH, NAME, ~] = fileparts(fname);
   base_dir = fullfile(FILEPATH, NAME);
   ground_truth_fname = fullfile(base_dir, 'ground_truth.mhd');
   delete(fname)
   disp(['Dataset saved to ', base_dir])
   clear FILEPATH NAME what_obj
end

end