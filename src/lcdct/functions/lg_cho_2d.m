function [auc, snr,t_sa, t_sp, meanSA, meanSP, meanSig, tplimg, chimg, k_ch]=lg_cho_2d(trimg_sa, trimg_sp,testimg_sa, testimg_sp,  ch_width, nch)
% [auc,snr, chimg,tplimg,meanSP,meanSA,meanSig, k_ch, t_sp, t_sa,]=LG_CHO_2d(trimg_sa, trimg_sp, testimg_sa, testimg_sp, ch_width, nch)
% Calculating lesion detectability using Laguerre-Gauss channelized model observer.
%
% :Parameters:
%   :trimg_sa: the training set of signal-absent (SA) images;
%   :trimg_sp: the training set of signal-present (SP) images;
%   :testimg_sa: the test set of signal-absent images; 
%   :testimg_sp: the test set of signal-present iamges;
%   :ch_width: channel width parameter; (suggest setting this parameter to be about 2/3 of the disk radius (in pixel)). 
%   :nch: number of channels to be used; default is 5.
%   
% :Returns:
%
%   :auc: the AUC values
%   :snr: the detectibility SNR
%   :t_sa: t-scores of SA cases
%   :t_sp: t-scores of SP cases
%   :meanSA: mean of training SP ROIs 
%   :meanSP: mean of traning SA ROIs
%   :meanSig: mean singal images (= meanSP-meanSA)
%   :tplimg: the template of the model observer
%   :chimg: channel images
%   :k_ch: the channelized data covariance matrix estimated from the training data 
%
% R Zeng, 6/2016, FDA/CDRH/OSEL/DIDSR
if(nargin<6)
    nch = 5;
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

%LG channels
xi=[0:nx-1]-(nx-1)/2;
yi=[0:ny-1]-(ny-1)/2;
[xxi,yyi]=meshgrid(xi,yi);
r=sqrt(xxi.^2+yyi.^2);
u=laguerre_gaussian_2d(r,nch-1,ch_width);
ch=reshape(u,nx*ny,size(u,3)); %if not applying the following filtering to the channels

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
data(1:nte_sp,2)=1;
out = roc(data);
auc = out.AUC;

%Optional outputs
tplimg=(reshape(w*ch',nx,ny)); % MO template
chimg=reshape(ch,nx,ny,nch); %Channels
meanSP=mean(trimg_sp,3);
meanSA=mean(trimg_sa,3);
meanSig=meanSP-meanSA;
k_ch=k;
