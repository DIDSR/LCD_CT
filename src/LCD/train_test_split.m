function [sa_train, sa_test, sp_train, sp_test] = train_test_split(sa_imgs, sp_imgs, split_pct, seed_val)
% split signal absent and signal present images into training and testing sets
%
%  :param sa_imgs: 3D array of signal absent images
%  :param sp_imgs: 3D array of signal present images
%  :param split_pct: percent of images to be used for training, remainder (1 - split_pct) to be used for testing
%  :param seed_val:  seed value to control the random generator
%
% :return sa_train: training set of sample absent images
% :return sa_test: testing set of sample absent images
% :return sp_train: training set of sample present images
% :return sp_train: testing set of sample present images
%
%    Example:
%       train_test_split(rand(64, 64, 10), rand(64, 64, 10), 0.3)

if ~exist('split_pct', 'var')
    split_pct = 0.5;
end

if ~exist('seed_val','var')
    seed_val = randi(10000);
end

n_sp = size(sp_imgs, 3);
n_sa = size(sa_imgs, 3);
n_sp_train = round(n_sp*split_pct);
n_sa_train = round(n_sa*split_pct);

if ~is_octave
    rng(seed_val);
end
idx_sa = randperm(n_sa);
idx_sp = randperm(size(sp_imgs, 3));

idx_sa_tr = idx_sa(1:n_sa_train);
idx_sp_tr = idx_sp(1:n_sp_train);
idx_sa_test = idx_sa(n_sa_train+1:end);
idx_sp_test = idx_sp(n_sp_train+1:end);

sp_train = sp_imgs(:,:,idx_sp_tr);
sp_test = sp_imgs(:,:,idx_sp_test);

sa_train = sa_imgs(:,:,idx_sa_tr);
sa_test = sa_imgs(:,:,idx_sa_test);
end

