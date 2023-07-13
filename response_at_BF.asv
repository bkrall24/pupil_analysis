function bf3 = response_at_BF(data, index, bins, cell_boolean, trial_threshold)

    % The best frequency is simply the max for each cell when averaged
    % across trials. BF contains a index from 1:size(neural.zscores,2) for
    % each cell. 
    [~, BF] = max(nanmean(data,3)');

    % Iterate through each cell and grab the neural data corresponding to
    % the best frequency and the pupil data corresponding to those trials. 
    for i = 1:length(BF)
        best_frequency(i,:) = squeeze(data(i, BF(i), :));    % [cells * trials]
        pupil_ind = index(i);
        bf_pupil(i,:) = squeeze(bins(pupil_ind, BF(i), :));  % [cells * trials]
    end

    % Next break the data into pupil states. Since you'll definitely have
    % different numbers of trials for each cell, instead make a cell array
    % of dimensions [cell x state]. Each vector is [trials] whereby each
    % element is response at BF/state combo
    bf2 = {};
    for i = 1:size(best_frequency,1)       % iterate cells
        for k = 1:max(bf_pupil, [],'all')  % iterate states
            spp = best_frequency(i, bf_pupil(i,:) == k);
            spp = spp(~isnan(spp));
            bf2(i,k) = {squeeze(spp)};   % {cells * state}, [trials]
        end
    end

    % cellfun allows you to easily create matrices of the exact size as
    % your bf2 data with information. So grab numel of each cell, to easily
    % reference which cell/state combos have sufficient trials. Then use
    % mean to get the average response at BF for each cell
    trial_cutoff = cellfun(@numel, bf2) < trial_threshold;
    bf3 = cellfun(@mean, bf2);
    bf3(trial_cutoff) = nan;

    % Next you can use a boolean to easily choose cells (i.e.
    % sound responsive cells. Then plot it.
    bf3 = bf3(cell_boolean,:,:);
    
    
end
