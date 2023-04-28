classdef LG_CHO_2D < BaseObserver
    %LG_CHO_2D Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channel_width
        n_channels = 5
    end
    
    methods
        function obj = LG_CHO_2D(channel_width, n_channels)
            %LG_CHO_2D Construct an instance of this class
            %   Detailed explanation goes here
            if (nargin<1)
                channel_width = false;
            end
            if(nargin<2)
                n_channels = 5;
            end
            obj.channel_width = channel_width;
            obj.n_channels = n_channels;
            obj.type = 'Laguerre-Gauss CHO 2D';
        end
        
        function [results] = perform_study(obj,signal_absent_train, signal_present_train,signal_absent_test, signal_present_test)
            %[results] = perform_study(obj,signal_absent_train, signal_present_train,signal_absent_test, signal_present_test)
            %   Detailed explanation goes here
            if ~obj.channel_width
               error(['LG CHO 2D channel_width not specified! '...
                      'Either instantiate with channel_width: lg_observer = LG_CHO_2D(channel_width) ' ...
                      'or modify object attribute: lg_observer.channel_width = channel_width']); 
            end
            [auc, snr,t_sa, t_sp, meanSA, meanSP, meanSig, tplimg, chimg, k_ch] = ...
            lg_cho_2d(signal_absent_train, signal_present_train,...
                      signal_absent_test, signal_present_test,...
                      obj.channel_width, obj.n_channels);
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

