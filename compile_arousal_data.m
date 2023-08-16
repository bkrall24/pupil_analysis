function [all_neural, all_pupil, all_ref] = compile_arousal_data(data_choice, p, match_boo, resp_window, spont_window)

    % hardcoded variables
    if nargin < 4
        resp_window = 15:24;
        spont_window = 1:14;
    end

    % initialize variables
    last_ind = 0;
    ind = 1;
    all_neural = [];
    all_pupil = [];
    all_ref = [];
    
    % load data according to animals
    animals = unique(data_choice.Animal);
    for i = 1:length(animals)

        % pull out rows containing all information for a given animal
        animal_choice = data_choice( ismember(data_choice.Animal, animals{i}), :);
        animal_pupil = p(ismember(data_choice.Animal, animals{i}));
        
        % identify which FOVs have a match file
        mf = animal_choice{:,23};
        matched = ~cellfun(@isempty, mf);

        % identify shared match files across FOVs 
        [counts, match_files] =  groupcounts(string(mf(matched,:)));
        match_files = match_files(counts > 1);
        matched = ismember(mf, match_files);


        % load each match file and identify the corresponding data files
        % according to the Fall.mat files listed in the roiMatch struct
        for j = 1:length(match_files)

            this_file = strrep(match_files(j), 'D:', 'W:');
            load(this_file);
            match_choice = animal_choice(ismember(mf, match_files(j)),:);
            match_pupil = animal_pupil(ismember(mf, match_files(j)));

            neural_match = [];
            pupil_match = [];
            ref_match = [];
            match_index = [];
            match_ind = 1;
            for k = 1:length(roiMatchData.allRois) 

                % identify the corresponding row of data in table
                row = find(arrayfun(@(x) contains(roiMatchData.allRois{k},x), string(match_choice{:,4})));
                
                if ~isempty(row) && ~match_boo

                    % Load the data and pull out the relevant data and nan-pad
                    % to match across FOVs
                    d = grab_single_experiment(match_choice(row,:));
                   
                    [neural_struct, pupil_struct, trial_ref] = compile_data_fields(match_pupil{row}, d, ...
                        spont_window, resp_window);
                  

                    % for the first matched day, label the cells sequentially
                    % and save a reference for each row
                    if k == 1 || isempty(match_index)
                        cell_index = [1:size(neural_struct.spikes,1)] + last_ind;
                        last_ind = max(cell_index);
                        match_index = cell_index(roiMatchData.allSessionMapping(:,k));

                    % for all remaining days, place the references to matched
                    % index from day 1 at appropriate cell index, and
                    % sequentially fill in the unmatched cells
                    else
                        temp_index = nan(1, size(neural_struct.spikes,1)) ;
                        temp_index(roiMatchData.allSessionMapping(:,k)) = match_index;
                        temp_index(isnan(temp_index)) = [1:sum(isnan(temp_index))] + last_ind;
                        cell_index = temp_index;
                        last_ind = max(cell_index);
                    end

                    
                    neural_struct.cell_ids = cell_index';
                    ref_struct.animal_id = string(match_choice{row, 3}{:});
                    ref_struct.cell_type = string(match_choice{row, 2}{:});
                    ref_struct.date_id = (match_choice{row, 4});
                    ref_struct.parameter = match_choice{row, 6};
                    ref_struct.directory = match_choice{row, 1};
                    ref_struct.cell_count = size(neural_struct.spikes,1);
                    ref_struct.trial_count = size(neural_struct.spikes,3);
                    ref_struct.match_file = match_files(j);
                    ref_struct.trial_ref = trial_ref;
                  
                    % If not combining trials of matched cells, just
                    % concatenate the structs to the array of structs
                   % if ~match_boo
                        
                    neural_struct.matched_days = zeros(size(neural_struct.cell_ids));
                    ref_struct.index = ind;
                    ind = ind +1;

                    all_ref = cat(1, all_ref, ref_struct);
                    all_neural = cat(1, all_neural, neural_struct);
                    all_pupil = cat(1, all_pupil, pupil_struct);
                        
                   
                elseif ~isempty(row) 
                    d = grab_single_experiment(match_choice(row,:));
                    
                    if k == 1 || isempty(match_index)
                        cell_index = [1:size(d.spike_zscores,1)] + last_ind;
                        last_ind = max(cell_index);
                        match_index = cell_index(roiMatchData.allSessionMapping(:,k));
                        
                        % for all remaining days, place the references to matched
                        % index from day 1 at appropriate cell index, and
                        % sequentially fill in the unmatched cells
                    else
                        temp_index = nan(1, size(d.spike_zscores,1)) ;
                        temp_index(roiMatchData.allSessionMapping(:,k)) = match_index;
                        temp_index(isnan(temp_index)) = [1:sum(isnan(temp_index))] + last_ind;
                        cell_index = temp_index;
                        last_ind = max(cell_index);
                    end
                    
                    d2.cell_ids = cell_index';
                    d2.spike_zscores = d.spike_zscores;
                    d2.spike_traces = d.spike_traces;
                    d2.inner_index = d.inner_index;
                    d2.inner_sequence = d.inner_sequence;
                    
                    ref_struct.animal_id = string(match_choice{row, 3}{:});
                    ref_struct.cell_type = string(match_choice{row, 2}{:});
                    ref_struct.date_id = (match_choice{row, 4});
                    ref_struct.cell_count = size(d2.spike_zscores,1);
                    ref_struct.parameter = match_choice{row, 6};
                    ref_struct.directory = match_choice{row, 1};
                    ref_struct.index = match_ind;
                    match_ind = match_ind +1;
                    ref_match = cat(1, ref_match, ref_struct);
                    neural_match = cat(1, neural_match, d2);
                    pupil_match = cat(2, pupil_match, match_pupil{row});
                end
                    
                
            end
            
            if match_boo
                [neural_struct, pupil_struct, trial_ref]  = ...
                    combine_matched_cells(neural_match, pupil_match,...
                    ref_match, spont_window, resp_window);
               
                    
                
                ref_struct.animal_id = unique([ref_match.animal_id]);
                ref_struct.date_id = [ref_match.date_id];
                ref_struct.cell_type = unique([ref_match.cell_type]);
                ref_struct.index = ind;
                ind = ind +1;
                ref_struct.cell_count = cellfun(@length, {neural_match.cell_ids});
                ref_struct.trial_count = arrayfun(@(x) length(x.inner_index)/length(x.inner_sequence), neural_match);
                ref_struct.match_file = match_files(j);
                ref_struct.directory = [ref_match.directory];
                ref_struct.parameter = [ref_match.parameter];
                ref_struct.trial_ref = trial_ref;
                
                all_ref = cat(1, all_ref, ref_struct);
                all_neural = cat(1, all_neural, neural_struct);
                all_pupil = cat(1, all_pupil, pupil_struct);
            end
        end

        % identify all the remaining FOVs that are not matched and load
        % that data
        unmatched = animal_choice(~matched,:);
        unmatched_pupil = animal_pupil(~matched);

        for q = 1:height(unmatched)

            d = grab_single_experiment(unmatched(q,:));
            [neural_struct, pupil_struct, trial_ref] = compile_data_fields(unmatched_pupil{q}, d, ...
                 spont_window, resp_window);

            cell_index = [1:size(neural_struct.spikes,1)] + last_ind;
            last_ind = max(cell_index);

            neural_struct.cell_ids = cell_index';
            neural_struct.matched_days = zeros(size(neural_struct.cell_ids));
            ref_struct.animal_id = string(unmatched{q,3}{:});
            ref_struct.date_id = (unmatched{q,4});
            ref_struct.parameter = unmatched{q,6};
            ref_struct.cell_type = string(unmatched{q,2}{:});
            ref_struct.index = ind;
            ref_struct.cell_count = size(neural_struct.spikes,1);
            ref_struct.trial_count = size(neural_struct.spikes,3);
            ref_struct.match_file = [];
            ref_struct.directory = unmatched{q, 1};
            ref_struct.trial_ref = trial_ref;
            ind = ind +1;

            all_ref = cat(1, all_ref, ref_struct);
            all_neural = cat(1, all_neural, neural_struct);
            all_pupil = cat(1, all_pupil, pupil_struct);

        end   
    end  
end
