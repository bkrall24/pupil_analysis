function [neural_struct, pupil_struct, trial_ref] = combine_matched_cells(neural_match, pupil_match,  ref_match, spont_window, resp_window)
    
    exp_ref = arrayfun(@(x) repmat(x.index, x.cell_count,1), ref_match, 'UniformOutput', false);
    exp_ref = cat(1, exp_ref{:});

    trial_index = {neural_match.inner_index};
    m.inner_index = cat(2, trial_index{:});
    
    dat = {neural_match.cell_ids};
    cell_id = cat(1, dat{:});
       
    % 'a' is no. of days matched, 'b' is unique(cell_id)
    [a,b] = groupcounts(cell_id);
    
    % Determine the max number of trials a given cell could have had
    daily_trial = cellfun(@(x) size(x,3), {neural_match.spike_zscores});
    trials = sum(daily_trial);
    
    % initialize nan matrices of combination of all days
    zscores = nan(length(b), size(neural_match(1).spike_zscores,2), trials);
    spikes  = nan(length(b), size(neural_match(1).spike_zscores,2), trials);
    
    % iterate across cells
    yx_corr = [];
    for i = 1:length(b)

        exp = exp_ref((cell_id == b(i)));
        
%         if contains(neural_match(1).Parameter,'Noise')
            % if cell wasn't matched on any other days, get its
            % coordinates on the day it was recorded. Otherwise, if a cell
            % was matched across many days, get its coordinates on Day 1
            if numel(exp) == 1
                yx_corr(i,:) = neural_match(exp).yx_corr(neural_match(exp).cell_ids == b(i),:);
            else
                yx_corr(i,:) = neural_match(1).yx_corr(neural_match(1).cell_ids == b(i),:);
            end            
%         end
        
        
        % If a given cell id appears more than once across matched days,
        % concatenate the data together and call 'compile_data_fields'
        if a(i) > 1
            
            for j = 1:length(exp)
                
                end_ind = sum(daily_trial(exp(1:j)));
                start_ind = end_ind - daily_trial(exp(j)) + 1;
                zscores(i,:,start_ind:end_ind) =  neural_match(exp(j)).spike_zscores(neural_match(exp(j)).cell_ids == b(i),:,:);
                spikes(i,:,start_ind:end_ind) =  neural_match(exp(j)).spike_traces(neural_match(exp(j)).cell_ids == b(i),:,:);
            end
        
        % If its not matched, just pull out the data and put in appropriate
        % index
        else
            end_ind = sum(daily_trial(1:exp));
            start_ind = end_ind - daily_trial(exp) + 1;
            spikes(i,:,start_ind:end_ind) =  neural_match(exp).spike_traces(neural_match(exp).cell_ids == b(i),:,:);
            zscores(i,:,start_ind:end_ind) =  neural_match(exp).spike_zscores(neural_match(exp).cell_ids == b(i),:,:);
            
        end
        
    end
        
    m.spike_traces = spikes;
    m.spike_zscores = zscores;
    m.cell_ids = b;
    m.matched_days = a;
    m.inner_sequence = neural_match(1).inner_sequence;
    m.Parameter = neural_match(1).Parameter;
    
%     if contains(neural_match(1).Parameter,'Noise')
        m.yx_corr = yx_corr;
        % ===== Sum up spike events during resp_wind (needed for NC) ====
        [sumTrialResp,~] = get_trialResp(m,resp_window);
        m.sumTrialResp   = sumTrialResp;
%     end
    
    [neural_struct, pupil_struct, trial_ref] = compile_data_fields(pupil_match, m, ...
                        spont_window, resp_window);
    neural_struct.cell_ids = m.cell_ids;  
    neural_struct.matched_days = m.matched_days;
    %pp = {pupil_match.pupil};
    %pupil.pupil = cat(3, pp{:});
    %pb = {pupil_match.bins};
    %pupil.bins = cat(3, pb{:});
        
    
end