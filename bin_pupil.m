function [bins, edges] = bin_pupil(p, num_bins, method)
    
    if method == 1
    % generate equal sized bins
        low = min(p, [], 'all');
        high = max(p, [], 'all');
        edges = low:(high-low)/num_bins:high;
        bins = discretize(p, edges);
    
    elseif method == 2
        % generate bins with equal samples but different bin sizes
        p(isnan(p)) = nanmedian(p, 'all');
        sortedData= sort(p(:));
        samplesPerBin = ceil(numel(p) / num_bins);
        binRanges = zeros(num_bins, 2);
        startIndex = 1;

        for i = 1:num_bins
            endIndex = min(startIndex + samplesPerBin - 1, numel(p));
            binRanges(i, :) = [sortedData(startIndex), sortedData(endIndex)];
            startIndex = endIndex + 1;
        end
        edges = [binRanges(:,1); binRanges(end, 2)];
        edges = edges';
        bins = discretize(p, edges);
    else
        error('Only 1 or 2 are valid method inputs')
    end
    
   
    
end
