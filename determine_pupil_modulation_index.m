function [p, mi, pairwise] = determine_pupil_modulation_index(response, bins, by_stim)
    
    % Inputs:
    %   response: cell x stimulus x trial data. Note to properly calculate
    %   index, values must be positive. Pass in spike_traces to easily
    %   accomplish this
    %
    %   bins: stimulus x trial, bin number for each trial
    %
    %   by_stim : boolean, if true function will determine the modulation
    %   index for each individual stimulus independently
    
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
    
    num_bins = max(bins, [], 'all');
    
    % method: for every combination of bins (i.e. 1 v 2, 1 v 3, 2 v 3 for 3
    % bins) calculate an asymmetry index of (resp1 - resp2)/(resp1 +
    % resp2).
    pairwise = nchoosek(unique(bins), 2);
    for i = 1:size(pairwise,1)
        
        pair = pairwise(i,:);
        
        if by_stim
        % stimulus dependent calculation
            for j = 1:size(response, 2)
                resp = squeeze(response(:, j,:));
                b = squeeze(bins(j,:));
                resp2 = mean(resp(:, b == pair(1)), 2);
                resp1 = mean(resp(:, b == pair(2)),2);

                if all(isnan(resp1)) || all(isnan(resp2))
                    mi(:,i,j) = nan(size(response,1),1);
                else
                    mi(:,i,j) = (resp1 - resp2)./(resp1 + resp2);
                end
            end
            
        else
        % stimulus independent calculation
            resp2 = mean(response(:, bins == pair(1)), [2,3]);
            resp1 = mean(response(:, bins == pair(2)), [2,3]);

           if all(isnan(resp1)) || all(isnan(resp2))
                mi(:,i) = nan;
            else
                mi(:,i) = (resp1 - resp2)./(resp1 + resp2);
           end
           
        end

    end
    
    for i = 1:length(mi)
        if by_stim
            all_stim = mi(i,:,:);
            p(i) = ttest(all_stim(:));
        else
            p(i) = ttest(mi(i,:));
        end
        
    end
   
    
    
end
