function [pupil, bins] = compile_pupil_fields(pupil, d,  trials, edges, spont_window)


    p = squeeze(mean(pupil(spont_window,:),1));
    p = squeeze(reshape_by_stimulus(p, d.inner_index, []));
    pupil = nan(size(p,1), trials);
    pupil(:, 1:size(p,2)) = p;
    
    b = discretize(p, edges);
    bins = nan(size(b,1), trials);
    bins(:, 1:size(b,2)) = b;
    
    
    [p_value, mi, pairwise] = determine_pupil_modulation_index(d2.spikes, d2.bins, false);
    d2.pupil_resp = p_value';
    d2.pupil_indices = mean(mi,2);
    
    
                                
end
