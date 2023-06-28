function [neural, pupil] = combine_matched_cells(neural_match, pupil_match, ref_match)

    % identify redundant cell ids and corresponding experiments and sound
    % responsivity
    exp_ref = arrayfun(@(x) repmat(x.index, x.cell_count,1), ref_match, 'UniformOutput', false);
    exp_ref = cat(1, exp_ref{:});
    
    dat = {neural_match.cell_ids};
    cell_id = cat(1, dat{:});
    
    sound_resp = {neural_match.sound_resp};
    sound_resp = cat(1, sound_resp{:});
    
    [a,b] = groupcounts(cell_id);
    
    % Determine the max number of trials a given cell could have had
    daily_trial = cellfun(@(x) size(x,3), {neural_match.spikes});
    trials = sum(daily_trial);
    
    % initialize nan matrices of combination of all days
    spikes = nan(length(b), size(neural_match(1).spikes,2), trials);
    zscores = nan(length(b), size(neural_match(1).spikes,2), trials);
    resp = [];
    
    % iterate across cells
    for i = 1:length(b)
        
        sr = sound_resp(cell_id == b(i));
        resp(i) = sum(sr);
        
        % identify all the experiments where this cell was identified
        exp = exp_ref((cell_id == b(i)));
        
        % If the cell is matched, iterate through experiments containing
        % matched cells and add to the appropriate index
        if a(i) > 1
            for j = 1:length(exp)
                
                end_ind = sum(daily_trial(exp(1:j)));
                start_ind = end_ind - daily_trial(exp(j)) + 1;
                spikes(i,:,start_ind:end_ind) =  neural_match(exp(j)).spikes(neural_match(exp(j)).cell_ids == b(i),:,:);
                zscores(i,:,start_ind:end_ind) =  neural_match(exp(j)).spikes(neural_match(exp(j)).cell_ids == b(i),:,:);
                
            end
        
        % If its not matched, just pull out the data and put in appropriate
        % index
        else
            end_ind = sum(daily_trial(exp));
            start_ind = end_ind - daily_trial(exp) + 1;
            spikes(i,:,start_ind:end_ind) =  neural_match(exp).spikes(neural_match(exp).cell_ids == b(i),:,:);
            zscores(i,:,start_ind:end_ind) =  neural_match(exp).spikes(neural_match(exp).cell_ids == b(i),:,:);
        end
    end
        
    neural.spikes = spikes;
    neural.zscores = zscores;
    neural.sound_resp = resp';
    neural.cell_ids = b;
    neural.matched_days = a;
        
    pp = {pupil_match.pupil};
    pupil.pupil = cat(3, pp{:});
    %pb = {pupil_match.bins};
    %pupil.bins = cat(3, pb{:});
        
    
end