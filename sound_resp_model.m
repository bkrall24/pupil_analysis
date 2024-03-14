function [beta_coeff, coeff_names] = sound_resp_model(d, p)

    % Get mean activity for baseline and evoked periods
    spont = squeeze(nanmean(d.spike_zscores(:,1:14,:),2));
    resp = squeeze(nanmean(d.spike_zscores(:,15:29,:),2));
    
    % If the param file is 'Noise', these variables will be used
    spontEarly = squeeze(nanmean(d.spike_zscores(:,1:14,:),2));
    spontLate  = squeeze(nanmean(d.spike_zscores(:,47:60,:),2));
    resp_evok  = squeeze(nanmean(d.spike_zscores(:,16:24,:),2));
    resp_late  = squeeze(nanmean(d.spike_zscores(:,38:46,:),2));

    
    stim = zeros( length(d.inner_index), max(d.inner_index));
    num_stim = length(d.inner_index);
    for i = 1:num_stim
        stim(i, d.inner_index(i)) = 1;
    end

    % Revise stim vector is Noise param file detected
    if contains(d.Parameter,'Noise')
        stim = [stim ; zeros(numel(stim),1)];
    end
    
    
    beta_coeff = [];    
    if nargin == 2
        coeff_names = ["Intercept", string(round(d.inner_sequence/1000)), "Baseline", "Pupil"];
        pupil = squeeze(mean(p(1:14,:)))';
               
        for cell_num = 1:size(resp,1)
           % If noise param file detected, modify design matrix
                % This is b/c noise params only had the one stimulus, so the
                % two conditions will be stim present and stim absent
            if contains(d.Parameter,'Noise')  % Noise params                
                spont = [spontEarly(cell_num,:)' ; spontLate(cell_num,:)'];
                X     = [ones(numel(pupil)*2,1), stim, spont, [pupil ; pupil] ];
                y     = [resp_evok(cell_num,:)' ; resp_late(cell_num,:)'];
            else  % FreqOneD params
                X = [ones(size(pupil)), stim, spont(cell_num,:)', pupil];
                y = resp(cell_num,:);
            end
            
            X = X(~isnan(y), :);
            y = y(~isnan(y));
            m = fitrlinear(X, y, 'learner', 'leastsquare');

            beta_coeff(cell_num,:) = m.Beta;            
        end
        
        
    else
        coeff_names = ["Intercept", string(round(d.inner_sequence/1000)), "Baseline"];
        for cell_num = 1:size(resp,1)
            X = [ones(size(spont,2),1), stim, spont(cell_num,:)'];
            y = resp(cell_num,:);
            X = X(~isnan(y), :);
            y = y(~isnan(y));
            
            m = fitrlinear(X, y, 'learner', 'leastsquare');
            
            beta_coeff(cell_num,:) = m.Beta;
        end
    end


end
