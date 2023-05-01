function [cct189_disk_geo, cct189_bkg_geo] = CCT189_obj(mu_water);
% function [CCT189_obj, image] = CCT189_geo(mu_water);
% Define the geometrical objects contained in the CCT189 phantom disk
% module with the following ellipse format: [x_center y_center x_radius y_radius angle_degrees mu]
% Check here for the CCT189 specifications: https://www.phantomlab.com/catphan-mita
% Input:
%   :param mu_water: attenuation value of water in mm^(-1), default was set to
%   0.2059 mm^-1, water attenuation at 60 KeV according to NIST table 
% Outputs:
%   :return: cct189_disk_geo: geometry of the low-contrast disk module
%   :return: cct189_bkg_geo: geometry of the background module
%
% R Zeng, FDA/CDRH/OSEL, 2023

if(nargin==0)
    mu_water = 0.2059 / 10;     % in the unit of mm^-1. Set the default value to be the water attenuation value at 60KeV according to the NIST table 
                                % https://physics.nist.gov/PhysRefData/XrayMassCoef/ComTab/water.html.
end
d = 40; %peripheral distance from the disk centers to the phantom enter

%define the background module: [x_center y_center x_radius y_radius angle_degrees mu]
cct189_bkg_geo = [0 0 200/2 200/2 0 mu_water];               % 200 mm, water

%define the low contrast disk module
cct189_disk_geo = [0 0 200/2 200/2 0 mu_water;               % 200 mm, water
    d*cosd(45)  d*sind(45)   3/2  3/2 0 14/1000*mu_water;    % 3mm, 14 HU
   -d*cosd(45)  d*sind(45)   5/2  5/2 0 7/1000*mu_water;     % 5 mm, 7 HU
   -d*cosd(45) -d*sind(45)   7/2  7/2 0 5/1000*mu_water;     % 7 mm, 5 HU
    d*cosd(45) -d*sind(45)  10/2 10/2 0 3/1000*mu_water;     % 10 mm, 3 HU
    ];


