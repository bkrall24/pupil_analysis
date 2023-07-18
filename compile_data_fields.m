function [neural_struct, pupil_struct] = compile_data_fields(p, d, spont_window, resp_window)

    s = mean(d.spike_traces(:,resp_window,:), 2);
    z = mean(d.spike_zscores(:,resp_window,:), 2);
    
    spikes = reshape_by_stimulus(s, d.inner_index, []);   % [cells * stim * reps]
    %spikes = nan(size(s,1), size(s,2), trials);
    %spikes(:,:,1:size(s,3)) = s;
    
    zscores = reshape_by_stimulus(z, d.inner_index, []);  % [cells * stim * reps]
    %zscores = nan(size(z,1), size(z,2), trials);
    %zscores(:,:,1:size(z,3)) = z;
    resp = is_responsive(d, 7, resp_window, spont_window)';


    p = squeeze(nanmean(p(spont_window,:),1));
    p = squeeze(reshape_by_stimulus(p, d.inner_index, []));
    %pupil = nan(1, size(p,1), trials);
    pupil(1, :, :) = p;
    
    %b = discretize(p, edges);
    %bins = nan(1, size(b,1), trials);
    %bins(1, :, :) = b;
    
    
%     [p_value, mi, ~] = determine_pupil_modulation_index(spikes, bins, false);
%     pupil_resp = p_value';
%     pupil_indices = mean(mi,2);
    
    neural_struct.spikes = spikes;
    neural_struct.zscores = zscores;
    neural_struct.sound_resp = logical(resp);
    pupil_struct.pupil = pupil;
    %pupil_struct.bins = bins;
%     neural_struct.pupil_resp = pupil_resp;
%     neural_struct.pupil_mod = pupil_indices;
    
                                
end
