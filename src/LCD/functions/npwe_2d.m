function [auc, snr, t_sp, t_sa, meanSA,meanSP,meanSig, tplimg, eyefunc]=npwe_2d(trimg_sa, trimg_sp,testimg_sa, testimg_sp, eye)
% [auc,snr,t_sp, t_sa,meanSP,meanSA,meanSig, tplimg, eyefunc]=NPWE_2d(trimg_sa, trimg_sp, testimg_sa, testimg_sp, eye)
% Calculating lesion detectability using non-prewhitening model observer with or without the eye filter model observer.
%
% :Parameters:
%
%   :testimg_sa: the test set of signal-absent, a stack of 2D array;
%   :testimg_sp: the test set of signal-present;
%   :trimg_sa: the training set of signal-absent;
%   :trimg_sp: the training set of signal-present;
%   :eye: 1 or 0 indicating the use of eye filter or not. (default is 0, no eye filter)
%
% :Returns:
%
%   :auc: the AUC values
%   :snr: the detectibility SNR
%   :t_sp: t-scores of SP cases
%   :t_sa: t-scores of SA cases
%   :meanSA: mean of training SP ROIs 
%   :meanSP: mean of traning SA ROIs
%   :meanSig: mean singal images (= meanSP-meanSA)
%   :tplimg: the template of the model observer
%   :eyefunc: the eye function in spatial domain
% 
% R Zeng, 11/2022, FDA/CDRH/OSEL/DIDSR

if(nargin<5)
   eye=0;
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


%Calculate the eye filter 
%E(f)=f^1.3 exp(-cf^2), with c selected to yield a peak at 4 cycles/degBurgess-JOSA1994 "Statistically defined backgrounds: performance of a modified nonprewhitening observer model"; 
%E(f)=f^1.3*exp(-3f^2)RichardEtAl-MP2008-"Comparison of model and human observer performance for detection and discrimination tasks using dual-energy x-ray images"
xi=[0:nx-1]-(nx-1)/2;
yi=[0:ny-1]-(ny-1)/2;
[xxi,yyi]=meshgrid(xi,yi);
disp_dx = 54/128; %mm, display 128 pixels in 54 mm length.
fi=([0:nx-1]-(nx-1)/2)/(nx-1)/disp_dx; 
[fx,fy]=ndgrid(fi,fi);
f_ratio =1/0.1146; % 1 cyc/deg @ 50 cm viewing distance --> 1 cyc/(50cm*pi/180) = 1.146 cyc/cm = 0.1146 cyc/mm 
fxy = (fx.^2+fy.^2)*f_ratio^2;
beta=1.3;
c = 0.04;
eyeflt = zeros(nx,ny);
eyeflt = fxy.^(beta/2) .* exp(-c*fxy); %0.04*(1/0.1146) = 3.04, the value agrees with the references.
eyefunc = fftshift(ifft2(ifftshift(eyeflt)));

%for NPW filter, set 'eyeflt' to ones.
if(eye==0)
   eyeflt = ones(nx, ny)/nx/ny; %equivalent to no filtering by setting 'eyeflt' to ones.
end


%Training MO (obtain the mean for NPWE)
nxny=nx*ny;
s = mean(trimg_sp,3) - mean(trimg_sa,3);
s_fft = fftshift(fft2(s));
s_eye = s_fft.*(eyeflt); 

%detection (testing)
for i=1:nte_sa
    tmp=fftshift(fft2(testimg_sa(:,:,i))).*(eyeflt);
  %  tmp = conv2(testimg_sa(:,:,i), eyefunc, 'same'); %spatial domain operation, very slow.
    te_sa_eye(:,i)=reshape(tmp, nx*ny,1);
end
for i=1:nte_sp
    tmp=fftshift(fft2(testimg_sp(:,:,i))).*(eyeflt);
  %  tmp = conv2(testimg_sp(:,:,i), eyefunc, 'same');    
    te_sp_eye(:,i)=reshape(tmp, nx*ny,1);
end
t_sa = real(s_eye(:)'*te_sa_eye);
t_sp = real(s_eye(:)'*te_sp_eye);

snr = (mean(t_sp)-mean(t_sa))/sqrt((std(t_sp)^2+std(t_sa)^2)/2);

nte = nte_sa + nte_sp;
data=zeros(nte,2);
data(1:nte_sp,1) = t_sp(:);
data(nte_sp+[1:nte_sa],1) = t_sa(:);
data(1:nte_sp,2)=1;
out = roc(data);
auc = out.AUC;

%Optional outputs
meanSP=mean(trimg_sp,3);
meanSA=mean(trimg_sa,3);
meanSig=mean(trimg_sp,3)-mean(trimg_sa,3);

if(eye==0)
   tplimg=meanSig;
else
   tplimg=0; %placeholder; to be calculated
   tplimg = (ifft2(abs(fft2(eyefunc)).^2 .* fft2(meanSig)))/nx/ny;
end
