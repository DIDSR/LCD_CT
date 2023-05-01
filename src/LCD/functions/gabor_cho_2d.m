function [auc, snr,t_sa, t_sp, meanSA, meanSP, meanSig, tplimg, chimg, k_ch]=gabor_cho_2d(trimg_sa, trimg_sp,testimg_sa, testimg_sp, nband, ntheta, phase)
% [auc,snr, chimg,tplimg,meanSP,meanSA,meanSig, k_ch, t_sp, t_sa,]=gabor_cho_2d(trimg_sa, trimg_sp, testimg_sa, testimg_sp, nband, ntheta, phase)
% Calculating lesion detectability using Gabor channelized Hoteling model observer.
% Inputs
%
%   :param testimg_sa: the test set of signal-absent, a stack of 2D array;
%   :param testimg_sp: the test set of signal-present;
%   :param trimg_sa: the training set of signal-absent;
%   :param trimg_sp: the training set of signal-present;
%   :param nband: number of octave bands; (default is 4)
%   :param ntheta: number of angles; (default is 4)
%   :param phase: a vector containing the phase values in radian such as 0,pi/3,pi/2 etc.(default is 0)
%
% Outputs
%
%   :return: auc: the AUC values
%   :return: snr: the detectibility SNR
%   :return: t_sa: t-scores of SA cases
%   :return: t_sp: t-scores of SP cases
%   :return: meanSA: mean of training SP ROIs 
%   :return: meanSP: mean of traning SA ROIs
%   :return: meanSig: mean singal images (= meanSP-meanSA)
%   :return: tplimg: the template of the model observer
%   :return: chimg: channel images
%   :return: k_ch: the channelized data covariance matrix estimated from the training data 
%
% R Zeng, 11/2022, FDA/CDRH/OSEL/DIDSR

if(nargin<7)
    phase = 0;
end

if(nargin<6)
   ntheta = 4;
end

if(nargin<5)
  nband = 4;
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


%Build Gabor channels 
xi=[0:nx-1]-(nx-1)/2;
yi=[0:ny-1]-(ny-1)/2;
[xxi,yyi]=meshgrid(xi,yi);
r2=(xxi.^2+yyi.^2);
theta = [0:pi/ntheta:pi/ntheta*(ntheta-1)];
f0=1/8;
for i=1:nband
    f1 = f0/2; 
    fc = (f0+f1)/2; %central freqency of the ocative band[f1, f0]
    wf = f0-f1;  %bandwidth
    ws = 4*log(2)/(pi*wf);
    amp = exp(-4*log(2).*r2/ws^2);

    for j=1:ntheta
        for k=1:length(phase) 
            fcos = cos(2*pi*fc.*(xxi*cos(theta(j))+yyi*sin(theta(j))) + phase(k));
            u = amp.*fcos;
            gb(:,:,k + (j-1)*length(phase) + (i-1)*ntheta*length(phase) ) = u;
        end
    end

    f0=f1; %update f0 for the next band.
end
ch = reshape(gb, nx*ny, size(gb,3));
nch = size(ch,2);

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
meanSig=mean(trimg_sp,3)-mean(trimg_sa,3);
k_ch=k;
