function [resp, mi2, pvalue] = determine_sound_modulation_index(response, spontaneous, by_stim)
    

    % responsive index:
    %   reliability
    %   







    % Inputs:
    %   response: cell x stimulus x trial data. Note to properly calculate
    %   index, values must be positive. Pass in spike_traces to easily
    %   accomplish this
    %
    %   spontaneous: cell x stimulus x trial data. Note to properly calculate
    %   index, values must be positive. Pass in spike_traces to easily
    %   accomplish this
    %

    
    % Outputs:
    %   index: cell x 1 vector of 0 or 1 indicating if the stimulus
    %   independent modulation index values were significantly different
    %   from 0 via t-test
    
    %   mi: 
    %       if by_stim = cell x C x stimulus
    %       else = cell x C x stimulus
    %   where C = (num_bins! / (2! * (num_bins-2)!)) or the
    %   total number of pairwise combinations of all bins. This is the
    %   value of the modulation index for each combination of pupil states
    %   for each cell
    

    
    % method: for every combination of bins (i.e. 1 v 2, 1 v 3, 2 v 3 for 3
    % bins) calculate an asymmetry index of (resp1 - resp2)/(resp1 +
    % resp2).
    
%     response = response + 0.0001;
%     spontaneous = spontaneous + 0.0001;
%     
%     mi = (response - spontaneous)./(response+spontaneous);
%     if by_stim
%     % stimulus dependent calculation
%         mi2 = mean(mi,3);
%         
%     else
%     % stimulus independent calculation
%         mi2 = mean(mi, [2,3]);
%     end
% 
% 
%     
%     for i = 1:size(mi,1)
%         if by_stim
%             for j = 1:size(mi,2)
%                 %[resp(i,j), pvalue(i,j)] = ttest(squeeze(mi(i,j,:)));
%                 [pvalue(i,j), resp(i,j)] = signrank(squeeze(mi(i,j,:)));
%             end
%         else
%             cell_mi = mi(i,:,:);
%             %[resp(i), pvalue(i)] = ttest(cell_mi(:));
%             [pvalue(i), resp(i)] = signrank(cell_mi(:));
%         end
%         
%     end



    
   
    
    
end