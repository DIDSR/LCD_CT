function [auc, snr,t_sa, t_sp, meanSA, meanSP, meanSig, tplimg, chimg, k_ch]=dog_cho_2d(trimg_sa, trimg_sp,testimg_sa, testimg_sp, DOGtype)
% [auc,snr, chimg,tplimg,meanSP,meanSA,meanSig, k_ch, t_sp, t_sa,]=dog_cho_2d(trimg_sa, trimg_sp, testimg_sa, testimg_sp, DOGtype)
% Calculating lesion detectability using difference-of-Gaussian channelized Hoteling model observer.
%
% Inputs
%
%   trimg_sa: the training set of signal-absent (SA) images;
%   trimg_sp: the training set of signal-present (SP) images;
%   testimg_sa: the test set of signal-absent images; 
%   testimg_sp: the test set of signal-present iamges;
%   DOGtype: 'dense' or 'sparse' (default is 'dense'), based on the parameter settings in Abbey&Barrett2001-josa-v18n3.
%
% Outputs
%
%   auc: the AUC values
%   snr: the detectibility SNR
%   t_sa: t-scores of SA cases
%   t_sp: t-scores of SP cases
%   meanSA: mean of training SP ROIs 
%   meanSP: mean of traning SA ROIs
%   meanSig: mean singal images (= meanSP-meanSA)
%   tplimg: the template of the model observer
%   chimg: channel images
%   k_ch: the channelized data covariance matrix estimated from the training data 
%
% R Zeng, 11/2022, FDA/CDRH/OSEL/DIDSR

if(nargin<5)
    DOGtype = 'dense';
end

[nx, ny, nte_sa]=size(testimg_sa);

%Ensure the images all having the same x,y sizes. 
[nx1, ny1, nte_sp]=size(testimg_sp);
if(nx1~=nx | ny1~=ny)
    error('Image size does not match! Exit.');
end
[nx1, ny1, ntr_sa]=size(trimg_sa);
if(nx1~=nx | ny1~=ny)
    error('Image size does not match! Exit.');
end
[nx1, ny1, ntr_sp]=size(trimg_sp);
if(nx1~=nx | ny1~=ny)
    error('Image size does not match! Exit.');
end

%Build DOG channels 
fi=([0:nx-1]-(nx-1)/2)/nx/1; 
[fx,fy]=ndgrid(fi,fi);
fxy = (fx.^2+fy.^2);

if strcmp(DOGtype,'dense')
   a0=0.005;
   a=1.4;
   Q=1.67;
   nch = 10;
elseif strcmp(DOGtype, 'sparse')
   a0=0.015;
   a=2.0;
   Q=2.0;
   nch = 3;
else 
   error('unknown DOG channel types. The available types are "dense" or "spare".')
end

sdog = zeros(nx,ny,nch);
for i=1:nch
    aj=a0*a^(i-1);
    aj1 = a0*a^(i);
    
    %S-DOG channels
    exp1 = exp(-fxy/(Q*aj)^2/2);
    exp2 = exp(-fxy/aj^2/2);
    sdogfreq(:,:,i)=exp1-exp2;
    sdog(:,:,i) = fftshift(ifft2(ifftshift(sdogfreq(:,:,i))));

end

ch = reshape(sdog, nx*ny, size(sdog,3));


%Training MO
nxny=nx*ny;
tr_sa_ch = zeros(nch, ntr_sa);
tr_sp_ch = zeros(nch, ntr_sp);
for i=1:ntr_sa
    tr_sa_ch(:,i) = reshape(trimg_sa(:,:,i), 1,nxny)*ch;
end
for i=1:ntr_sp
    tr_sp_ch(:,i) = reshape(trimg_sp(:,:,i), 1,nxny)*ch;
end
s_ch = mean(tr_sp_ch,2) - mean(tr_sa_ch,2);
k_sa = cov(tr_sa_ch');
k_sp = cov(tr_sp_ch');
k = (k_sa+k_sp)/2;
w = s_ch(:)'*pinv(k); %this is the hotelling template

%detection (testing)
for i=1:nte_sa
    te_sa_ch(:,i) = reshape(testimg_sa(:,:,i), 1, nxny)*ch;
end
for i=1:nte_sp
    te_sp_ch(:,i) = reshape(testimg_sp(:,:,i), 1, nxny)*ch;
end
t_sa=w(:)'*te_sa_ch;
t_sp=w(:)'*te_sp_ch;

snr = (mean(t_sp)-mean(t_sa))/sqrt((std(t_sp)^2+std(t_sa)^2)/2);

nte = nte_sa + nte_sp;
data=zeros(nte,2);
data(1:nte_sp,1) = t_sp(:);
data(nte_sp+[1:nte_sa],1) = t_sa(:);
data = real(data); % <--- is this appropriate???
data(1:nte_sp,2)=1;
out = roc(data);
auc = out.AUC;

%Optional outputs
tplimg=(reshape(w*ch',nx,ny)); % MO template
chimg=reshape(ch,nx,ny,nch); %Channels
meanSP=mean(trimg_sp,3);
meanSA=mean(trimg_sa,3);
meanSig=mean(trimg_sp,3)-mean(trimg_sa,3);
k_ch=k;
