function [max_zscore, av_zscore, latency] = determine_responsive_index(psth,resp_window,spont_window)

    % determine_responsive.m

    % Take a 1D psth as input and determines a zscore relative to a region of
    % spontaneous activity. Then determines responsiveness based on whether the
    % maximum zscore alongside neighboring zscores exceeds a chosen threshold
    %
    % 03.24.21
    % Added ability to set avg_spont_trace instead of computing spont response
    % from PSTH
    % 
    %
    % Default parameters will likely be:
    %   resp_window = 15:25
    %   spont_window = 1:14 
    %   thresh = 3
    %
    % (c) Ross S Williamson, March 2021; rsw@pitt.edu
    
    % edit to return max zscore, and average zscore across three frames

    if nargin == 5
        psth_zscored=smooth((psth-nanmean(avg_spont_trace))/nanstd(avg_spont_trace));
    else
        psth_zscored=smooth((psth-nanmean(psth(spont_window)))/nanstd(psth(spont_window)));
    end

     %find max in zscore and location
    [~,loc_temp] = max(abs(psth_zscored(resp_window)));

    %loc is relative to the start of the response window, so convert
    loc = resp_window(1)+loc_temp-1;
    max_zscore = psth_zscored(loc); 
    av_zscore = (psth_zscored(loc-1:loc+1));
    latency = loc;


end
