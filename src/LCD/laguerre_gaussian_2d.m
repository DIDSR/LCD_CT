function u=laguerre_gaussian_2d(x,J,h)
%function u=laguerre_gaussian_2d(x,J,h)
%Calculate the Laguerre-gaussian function
%Inputs
%
%       x: 1d vector of pixel locations
%       J: # of channels
%       h: the Guassian width 
%
%2009, R Zeng, FDA/CDRH/OSEL
xsize=size(x);
x=x(:);
L=laguerre(2*pi*x.^2/h^2,J);
for j=0:J
    u(:,j+1)= L(:,j+1).*exp(-pi*x.^2/h^2);
end

scale=sqrt(2)/h;%sqrt(2/2)/h/2;
u=u*scale;
u=reshape(u,[xsize J+1]);

