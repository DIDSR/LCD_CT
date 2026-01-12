classdef GABOR_CHO_2D < BaseObserver
    %GABOR_CHO_2D Summary of this class goes here
    %   Detailed explanation goes here
    %   nband: number of octave bands; (default is 4)
%   ntheta: number of angles; (default is 4)
%   phase: a vector containing the phase values in radian such as 0,pi/3,pi/2 etc.(default is 0)

    
    properties
        nband = 4;
        ntheta = 4;
        phase = 0;
    end
    
    methods
        function obj = GABOR_CHO_2D(nband, ntheta, phase)
            %DOG_CHO_2D Construct an instance of this class
            %   Detailed explanation goes here
            if(nargin<1)
                nband = 4;
            end
            if(nargin<2)
                ntheta = 4;
            end
            if(nargin<3)
                phase = 0;
            end
            obj.nband = nband;
            obj.ntheta = ntheta;
            obj.phase = phase;
            obj.type = 'Gabor CHO 2D';
        end
        
        function [results] = perform_study(obj,signal_absent_train, signal_present_train,signal_absent_test, signal_present_test)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            [auc, snr,t_sa, t_sp, meanSA, meanSP, meanSig, tplimg, chimg, k_ch] = ...
            gabor_cho_2d(signal_absent_train, signal_present_train,...
                      signal_absent_test, signal_present_train,...
                      obj.nband, obj.ntheta, obj.phase);
            results.auc = auc;
            results.snr = snr;
            results.t_sa = t_sa;
            results.t_sp = t_sp;
            results.meanSA = meanSA;
            results.meanSP = meanSP;
            results.meanSig = meanSig;
            results.tplimg = tplimg;
            results.chimg = chimg;
            results.k_ch = k_ch;
        end
    end
end

