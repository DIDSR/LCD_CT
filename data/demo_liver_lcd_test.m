%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Demo of LCD test using liver_LCD phantom images
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
small_dataset = true; %true: using small dataset for test run. 
                      %false: using full dataset for reasonable AUC evaluation 
if(small_dataset)
    %using the small dataset (20 pairs of samples) for testing the liver_LCD test code
    data_folder = 'data/smalldata_liver_lcd/'
    n_sp = 20; % number of signal-present cases: 
    n_sa = 20; % number of signal-absent cases: 
    n_train = 12; % number of cases to be used for training 
else
    %using full dataset (200 pairs), you need to download them from zenodo first
    disp('You are running the code with full dataset.')
    yn = input('Have you downloaded the full dataset from zenodo and saved it under "/data/fulldata_liver_lcd"? (y/n) \n', 's');
    if(strcmpi(yn,'n')) 
        disp('Download the full dataset here:https://zenodo.org/records/22149090');
        disp('Exit!');
        return;
    end
    data_folder = 'data/fulldata_liver_lcd/'
    n_sp = 200;
    n_sa = 200;
    n_train = 120;
end

%%---- inputs------------
% data description
all_recon_type = {'fbp_sharp', 'redcnn'} %reconstruction folder names  
dose = [50 100]; % two dose levels 50% and 100%.

% Model observer parameters
mo_option = {'lg-cho', 'gabor-cho'};
mo = mo_option{2} %Select which model observer to use.
n_reader = 10; % Number of readers (times of data re-split into training/testing for variance estimation.)
seed_for_randperm = 30;% random seed for data split 

% CT image info (set them to be the same as the LCD phantom CT images)
nx = 512; %Image size
ny = nx;
fov = 380;  % Image field of view (fov), in mm
dx = fov/nx; % Image pixel size 

% Insert information (center, radius) for ROI extraction. 
% Set them to be the same as the parameter values in phantom creation)
insert_centers = [250 194; 180 126; 253 90; 298 110]; %from the value assigned to 'disk_ctr' in "make_LCD_patient_D45.m"
insert_radii = [3/2 5/2 7/2 10/2]/dx;
idx_insert = [1 2 3 4]; %specify which inserts to be used in the LCD analysis. for example, let idx_insert=[2] if you only want to run the LCD analysis on the second insert (the 5mm one). 

%%----End of inputs----------

n_recon_option = length(all_recon_type);
n_I0 = length(dose);
auc_all = zeros(n_reader, n_recon_option, n_I0, length(idx_insert));

for iI = 1:n_I0
    dose(iI)
    
    %Preload all the images
    
    sp_allrecon = zeros(nx, ny, n_sp, n_recon_option);
    sa_allrecon = zeros(nx, ny, n_sa, n_recon_option);
    for k=1:n_recon_option
        
        % construct filenames according the saved data strucutre
        recon_option = all_recon_type{k};
        I0_string = ['I0_' sprintf('%03d', dose(iI))];
        folder_sp = [data_folder 'sp/' I0_string  '/' recon_option '/'];
        folder_sa = [data_folder 'sa/' I0_string '/' recon_option '/'];
        for i=1:n_sa
            filenum = i;
            filenum_string = ['v' sprintf('%03d', filenum)];
            filename = [folder_sa filenum_string '.raw'];
            fid = fopen(filename);
            im_current = fread(fid, [nx, nx], 'int16');
            img = im_current;
            fclose(fid);
            sa_allrecon(:,:,i,k) = img;  
        end
        for i=1:n_sp
            filenum = i;
            filenum_string = ['v' sprintf('%03d', filenum)];
            filename = [folder_sp filenum_string '.raw'];
            fid = fopen(filename);
            im_current = fread(fid, [nx, nx], 'int16');
            img = im_current;
            fclose(fid);
            sp_allrecon(:,:,i,k) = img;            
        end
    end
    
    %start LCD analysis
    for j = 1:length(idx_insert)
        
        % Specify the ROI around the j-th insert
        center_x = insert_centers(idx_insert(j), 1);
        center_y = insert_centers(idx_insert(j), 2);
        insert_r = insert_radii(idx_insert(j));
        crop_r = ceil(3*insert_r);  % set the signal-present and signal-absent ROI size to be 3 times of the disk size.  
        sa_crop_xfov = center_x + [-crop_r:crop_r];
        sa_crop_yfov = center_y + [-crop_r:crop_r];
        sp_crop_xfov = center_x + [-crop_r:crop_r];
        sp_crop_yfov = center_y + [-crop_r:crop_r];

        rng(seed_for_randperm);
        for ir=1:n_reader
                % shuffle training data
                idx_sa1 = randperm(n_sa);
                idx_sp1 = randperm(n_sp);
                
                %split into training/testing
                idx_sa_tr = idx_sa1(1:n_train);
                idx_sp_tr = idx_sp1(1:n_train);
                idx_sa_test = idx_sa1(n_train+1:end);
                idx_sp_test = idx_sp1(n_train+1:end);

            for k=1:n_recon_option
                % load in data and extract sp and sa ROIs.
                recon_option = all_recon_type{k};
                sa_img = sa_allrecon(:,:,:,k);
                sa_roi = sa_img(sa_crop_xfov, sa_crop_yfov,:);
                sp_img = sp_allrecon(:,:,:,k);
                sp_roi = sp_img(sa_crop_xfov, sa_crop_yfov,:);                                           
    
                % run LG-CHO
                if(strcmp(mo,'lg-cho'))
                    [auc, snr,t_sa, t_sp, meanSA, meanSP, meanSig, tplimg, chimg, k_ch]= ...
                    lg_cho_2d(sa_roi(:, :, idx_sa_tr), sp_roi(:, :, idx_sp_tr), sa_roi(:, :, idx_sa_test), sp_roi(:, :, idx_sp_test), insert_r/1.5, 5);
                end

	            % run Gabor-CHO
                if(strcmp(mo,'gabor-cho'))
                    [auc, snr,t_sa, t_sp, meanSA, meanSP, meanSig, tplimg, chimg, k_ch]= ...
                    gabor_cho_2d(sa_roi(:, :, idx_sa_tr), sp_roi(:, :, idx_sp_tr), sa_roi(:, :, idx_sa_test), sp_roi(:, :, idx_sp_test),3, 3, 0);
                end
                   
                auc_all(ir,j,iI,k) = auc;
                snr_all(ir,j,iI,k) = snr;
              end
            end
    end
end

aucmean =  squeeze(mean(auc_all));
aucse = squeeze(std(auc_all))/sqrt(n_reader);
insert_string = {'3mm-21HU','5mm-10.5HU', '7mm-7.5HU','10mm-4.5HU'}
snrmean =  squeeze(mean(snr_all));
snrse = squeeze(std(snr_all))/sqrt(n_reader);

%show results
disp('===AUC vs dose results===')
for k=1:n_recon_option
    display(all_recon_type{k}); 
    display('meanAUC: 3 mm, 5 mm, 7 mm, 10 mm')
    for iI = 1:n_I0
        display(dose(iI))
        display((squeeze(aucmean(:,iI,k)))')
    end
end

%save results
save('liver_lcd_results.mat' ,'auc_all','snr_all', 'dose', 'aucmean', 'aucse','snrmean','snrse', 'all_recon_type', 'insert_string');

if(small_dataset)
    disp('Successful test run of liver_LCD test with the small dataset.')
end