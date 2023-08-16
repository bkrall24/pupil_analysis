
function [sound_mod, pupil_mod, noise_mod, rsquare] = fit_sound_pupil_coefficients(d, p)


    for cell_num = 1:size(d.spike_zscores,1)
    % Use the stimulus (hot-one encoding), spontaneous firing, and pupil value
    % to predict stimulus response
    
        % Spontaneous response
        spont = squeeze(mean(d.spike_zscores(cell_num,1:14,:),2));
        
        % Hot One Encoding of stimulus
        stim = zeros( length(d.inner_index), max(d.inner_index));
        for i = 1:length(d.inner_index)
            stim(i, d.inner_index(i)) = 1;
        end

        % Spontaneous pupil
        pupil = squeeze(mean(p(5:14,:)))';

        % Evoked response
        resp = squeeze(mean(d.spike_zscores(cell_num,15:24,:),2));

        % Design Matrix
        X = [stim, spont, pupil];
        
        % Fit the data
        lm = fitlm(X,resp);
        pupil_mod(cell_num) = lm.Coefficients.Estimate(18);
        noise_mod(cell_num) = lm.Coefficients.Estimate(17);
        sound_coeff = lm.Coefficients.Estimate(2:16);
        sound_mod(cell_num,:) = sound_coeff;
        rsquare(cell_num) =  lm.Rsquared.Adjusted;
       
    end

    
end