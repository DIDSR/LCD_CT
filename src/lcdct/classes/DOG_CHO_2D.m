classdef DOG_CHO_2D < BaseObserver
    %DOG_CHO_2D Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DOGtype = 'dense'
    end
    
    methods
        function obj = DOG_CHO_2D(DOGtype)
            %DOG_CHO_2D Construct an instance of this class
            %   Detailed explanation goes here
            if(nargin<1)
                DOGtype = 'dense';
            end
            obj.DOGtype = DOGtype;
            obj.type = 'DOG CHO 2D';
        end
        
        function [results] = perform_study(obj,signal_absent_train, signal_present_train,signal_absent_test, signal_present_test)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            [auc, snr,t_sa, t_sp, meanSA, meanSP, meanSig, tplimg, chimg, k_ch] = ...
            dog_cho_2d(signal_absent_train, signal_present_train,...
                      signal_absent_test, signal_present_train,...
                      obj.DOGtype);
            results.auc = auc;
            results.snr = abs(snr); % <-- does magnitude or real make more sense here??
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
