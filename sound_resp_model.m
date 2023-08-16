function [beta, coeff_names] = sound_resp_model(d, p)

    spont = squeeze(nanmean(d.spike_zscores(:,1:14,:),2));
    resp = squeeze(nanmean(d.spike_zscores(:,15:29,:),2));

    stim = zeros( length(d.inner_index), max(d.inner_index));
    num_stim = length(d.inner_index);
    for i = 1:num_stim
        stim(i, d.inner_index(i)) = 1;
    end

    
    if nargin == 2
        coeff_names = ["Intercept", string(round(d.inner_sequence/1000)), "Baseline", "Pupil"];
        pupil = squeeze(mean(p(1:14,:)))';
        for cell_num = 1:size(resp,1)
            
            X = [ones(size(pupil)), stim, spont(cell_num,:)', pupil];
            y = resp(cell_num,:);
            
            X = X(~isnan(y), :);
            y = y(~isnan(y));
            m = fitrlinear(X, y, 'learner', 'leastsquare');
            
            beta(cell_num,:) = m.Beta;
            
            
        end
    else
        coeff_names = ["Intercept", string(round(d.inner_sequence/1000)), "Baseline"];
        for cell_num = 1:size(resp,1)
            X = [ones(size(spont,2),1), stim, spont(cell_num,:)'];
            y = resp(cell_num,:);
            X = X(~isnan(y), :);
            y = y(~isnan(y));
            
            m = fitrlinear(X, y, 'learner', 'leastsquare');
            
            beta(cell_num,:) = m.Beta;
        end
    end


end
