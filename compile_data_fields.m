function [neural_struct, pupil_struct, trial_ref] = compile_data_fields(p, d, spont_window, resp_window)

    [beta, coeff_names] = sound_resp_model(d, p);


    s = mean(d.spike_traces(:,resp_window,:), 2);
    z = mean(d.spike_zscores(:,resp_window,:), 2);
    
    spikes = reshape_by_stimulus(s, d.inner_index, []);
%     spikes = nan(size(s,1), size(s,2), trials);
%     spikes(:,:,1:size(s,3)) = s;
%     
    
    zscores = reshape_by_stimulus(z, d.inner_index, []);
%     zscores = nan(size(z,1), size(z,2), trials);
%     zscores(:,:,1:size(z,3)) = z;
    resp = is_responsive(d, 7)';
% 
%     [sound_mod, pupil_mod, noise_mod, rsquare] = fit_sound_pupil_coefficients(d, p);
%     
    trial_ref = reshape_by_stimulus(1:length(d.inner_index), d.inner_index, []);

    p = squeeze(nanmean(p(spont_window,:),1));
    p = squeeze(reshape_by_stimulus(p, d.inner_index, []));
%     pupil = nan(1, size(p,1), trials);
    pupil(1, :, :) = p;
    
%     b = discretize(p, edges);
%     bins = nan(1, size(b,1), trials);
%     bins(1, :, :) = b;
%     
    
%     [p_value, mi, ~] = determine_pupil_modulation_index(spikes, bins, false);
%     pupil_resp = p_value';
%     pupil_indices = mean(mi,2);
    
    
    neural_struct.spikes = spikes;
    neural_struct.zscores = zscores;
    neural_struct.sound_resp = logical(resp);
    neural_struct.sound_beta = beta(:,2:16);
    neural_struct.pupil_mod = beta(:,18);
   % neural_struct.trial_ref = trial_ref;
%     neural_struct.sound_mod = sound_mod;
%     neural_struct.pupil_mod = pupil_mod';
%     neural_struct.noise_mod = noise_mod';
%     neural_struct.rsquare = rsquare';
    pupil_struct.pupil = pupil;
%     pupil_struct.bins = bins;
%     neural_struct.pupil_resp = pupil_resp;
%     neural_struct.pupil_mod = pupil_indices;
    
                                
end


% s2 = mean(d.spike_traces(:,spont_window,:), 2);
% z2 = mean(d.spike_zscores(:,spont_window,:), 2);
% spikes_spont = reshape_by_stimulus(s2, d.inner_index, []);
% zscores_spont = reshape_by_stimulus(z2, d.inner_index, []);
% neural_struct.spikes_spont = spikes_spont;
% 
% neural_struct.zscores_spont = zscores_spont;