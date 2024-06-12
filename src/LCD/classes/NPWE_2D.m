classdef NPWE_2D < BaseObserver
    %NPWE_2D Summary of this class goes here
    %   eye: 1 or 0 indicating the use of eye filter or not. (default is 0, no eye filter)

    properties
        eye = 0
    end

    methods
        function obj = NPWE_2D(use_eye)
            %NPWE_2D Construct an instance of this class
            %   Detailed explanation goes here
            if(nargin<1)
                use_eye = 0;
            end
            obj.eye = use_eye;
            if use_eye
                obj.type = 'NPWE 2D';
            else
                obj.type = 'NPW 2D';
            end
        end

        function [results] = perform_study(obj,signal_absent_train, signal_present_train,signal_absent_test, signal_present_test)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            [auc, snr,t_sa, t_sp, meanSA,meanSP,meanSig, tplimg, eyefunc] = ...
            npwe_2d(signal_absent_train, signal_present_train,...
                      signal_absent_test, signal_present_test,...
                      obj.eye);
            results.auc = auc;
            results.snr = snr;
            results.t_sa = t_sa;
            results.t_sp = t_sp;
            results.meanSA = meanSA;
            results.meanSP = meanSP;
            results.meanSig = meanSig;
            results.tplimg = tplimg;
            results.eyefunc = eyefunc;
        end
    end
end