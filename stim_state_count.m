function trial_count = stim_state_count(spikes, index, bins)
% spikes = cell x stimulus x bin - cell array 
    d = {};
    for i = 1:size(spikes,1)
        for j = 1:size(spikes,2)
            for k = 1:max(bins, [],'all')
                ind = index(i);
                sp = spikes(i,j, bins(ind,j,:) == k);
                sp = sp(~isnan(sp));
                d(i,j,k) = {squeeze(sp)};
            end
        end
    end

    trial_count =  cellfun(@numel, d);
     
end

    