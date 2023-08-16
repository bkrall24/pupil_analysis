function [experiment_dir, pupil_dir, exp_index, day] = find_raw_data(ref, neural, index)

    % goal of this function is to be able to pass in a reference and neural
    % structure (output of compile_arousal_data) and identify the raw data
    % files for both pupil and suite2p. If index is passed, it will also
    % identify the exact cell (i.e. index in first dimension of
    % initial_analysis.mat) that corresponds to the cell at the index of your
    % data. This allows for troubleshooting (ensure data is properly aligned)
    % as well as easy tracing in case more detailed analyses are needed.
    
    
    % If cells are matched across days, you need to do more. Matched
    % reference structures will have multiple values for the cell count.
    matched_days = length(ref.trial_count);
    
    
    % 
    if matched_days == 1
        
        experiment_dir = strcat(ref.directory, ref.cell_type, '\2P\', ref.animal_id, '\0',  string(ref.date_id), '\',ref.parameter, '\MAT\initial_analysis.mat');
        pupil_dir = strcat( ref.directory,  ref.cell_type, '\2P\', ref.animal_id, '\0',  string(ref.date_id), '\',ref.parameter, '\MAT\pupil_data.mat');
        exp_index = index;
        day = 1;
    else
        % load the match file to identify if the cell in question is 
        % matched across days 
        try
            load(ref.match_file)
        end
        
        try
            load(strrep(ref.match_file , 'D:', 'W:'));
        catch
            error('Error match file not found, despite cells matched')
        end
        
        % Identify the number of matched cells. This code assumes cells are
        % matched across all days. 
        match_count = size(roiMatchData.allSessionMapping,1);
        
        % Determine how many unique cells are recorded on each day. Since
        % all matched cells appear on day 1, their index will correspond to
        % their index on day 1.
        day_count = ref.cell_count;
        day_count(2:end) = day_count(2:end) - match_count;
        
    
        % sum of unique cells should equal to the total number of final
        % cells
        if ~(sum(day_count) == size(neural.spikes,1))
            error('Different cells counts than expected based on matching')
        end

        
        % map the index of cells in the matched set back to the index in
        % the original set using allSessionMapping
        cell_index{1} = (1:day_count(1))';
        matched_index = cell_index{1}(roiMatchData.allSessionMapping(:,1));
        for i = 2:matched_days
           
            all_possible = nan(ref.cell_count(i),1);
            all_possible(roiMatchData.allSessionMapping(:,i)) = matched_index;
            unmatched_start = cumsum(day_count)+1;
            unmatched_indices = unmatched_start(i-1):unmatched_start(i-1)+day_count(i)-1;
            all_possible(isnan(all_possible)) = unmatched_indices;
            cell_index{i} = all_possible;
        end
        
        
        % Find what day the cell of interest (index) appeared on. If its
        % matched, it'll show up on day 1
        %which_day = find(index <= cumsum(day_count), 1, 'first');
        which_day = find(cellfun(@(x) sum(x == index), cell_index));
        %cell_index = cat(1, cell_index{:});
        % If the cell is found on day 1, check to see if its matched across
        % days or not. Indexes of matched cells from day 1 should be
        % included in the session mapping of that day. Note, 'day 1' is
        % arbitrary because you might not include all matched days in
        % analysis. Therefore, this looks for the column corresponding to
        % the first date used for matching.
        for i = 1:length(which_day)
            j = which_day(i);
            if ref.date_id(i) < 100000
                experiment_dir(i) = strcat(ref.directory{j}, ref.cell_type, '\2P\', ref.animal_id, '\0',  string(ref.date_id(j)), '\',ref.parameter{j}, '\MAT\initial_analysis.mat');
                pupil_dir(i) = strcat( ref.directory{j},  ref.cell_type, '\2P\', ref.animal_id, '\0',  string(ref.date_id(j)), '\',ref.parameter{j}, '\MAT\pupil_data.mat');
                
            else
                experiment_dir(i) = strcat( ref.directory{j},ref.cell_type, '\2P\', ref.animal_id, '\', string( ref.date_id(j)), '\',ref.parameter{j}, '\MAT\initial_analysis.mat');
                pupil_dir(i) = strcat( ref.directory{j},ref.cell_type, '\2P\', ref.animal_id, '\',  string(ref.date_id(j)), '\',ref.parameter{j}, '\MAT\pupil_data.mat');
            end
            
            
            matching_index = roiMatchData.allSessionMapping(:,cellfun(@(x) contains(x, string(ref.date_id(i))), roiMatchData.allRois));
            exp_index(i) = find(cell_index{which_day(i)} == index);
            
        end
        
        day = which_day;
        
        
    end
end
