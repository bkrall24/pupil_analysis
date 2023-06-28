function [spikes, zscores, resp] = compile_neural_fields(d, trials, resp_window)

    s = mean(d.spike_traces(:,resp_window,:), 2);
    z = mean(d.spike_zscores(:,resp_window,:), 2);
    
    s = reshape_by_stimulus(s, d.inner_index, []);
    spikes = nan(size(s,1), size(s,2), trials);
    spikes(:,:,1:size(s,3)) = s;
    
    z = reshape_by_stimulus(z, d.inner_index, []);
    zscores = nan(size(z,1), size(z,2), trials);
    zscores(:,:,1:size(z,3)) = z;
    resp = is_responsive(d, 7)';

end
