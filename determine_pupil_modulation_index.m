function pmi = determine_pupil_modulation_index(response, bins, num_bins, by_stim, exclude_adjacent)
    
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
    
    
    % method: for every combination of bins (i.e. 1 v 2, 1 v 3, 2 v 3 for 3
    % bins) calculate an asymmetry index of (resp1 - resp2)/(resp1 +
    % resp2).
    %pairwise = nchoosek(unique(bins), 2);
    bins = squeeze(bins);
    pairwise = nchoosek(1:num_bins, 2);
    
    if exclude_adjacent
        dif = pairwise(:,2) - pairwise(:,1);
        pairwise = pairwise(abs(dif) ~= 1, :);
    end
    
    if by_stim
        mi = nan(size(response,1), size(response,2),  size(pairwise,1));
    else
        mi = nan(size(response,1), size(pairwise,1));
    end
    
    for i = 1:size(pairwise,1)
        
        pair = pairwise(i,:);
        
        if by_stim
        % stimulus dependent calculation
            for j = 1:size(response, 2)
                resp = squeeze(response(:, j,:));
                b = (bins(j,:));
                resp2 = nanmean(resp(:, b == pair(1)), 2);
                resp1 = nanmean(resp(:, b == pair(2)),2);

                if all(isnan(resp1)) || all(isnan(resp2))
                    mi(:,j,i) = nan(size(response,1),1);
                else
                    mi(:,j,i) = (resp1 - resp2)./(resp1 + resp2);
                end
            end
            
        else
        % stimulus independent calculation
            resp2 = nanmean(response(:, bins == pair(1)), [2,3]);
            resp1 = nanmean(response(:, bins == pair(2)), [2,3]);

           if all(isnan(resp1)) || all(isnan(resp2))
                mi(:,i) = nan;
            else
                mi(:,i) = (resp1 - resp2)./(resp1 + resp2);
           end
           
        end

    end
    
    for i = 1:size(mi,1)
        if by_stim
            all_stim = mi(i,:,:);
            p(i) = ttest(all_stim(:));
        else
            p(i) = ttest(mi(i,:));
        end
        
    end
   
    pmi.p = p';
    pmi.mi = mi;
    %pmi.pairwise = pairwise;
    
end
