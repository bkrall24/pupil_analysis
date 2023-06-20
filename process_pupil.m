function final_pupil = process_pupil(pupil)

    % need to update comments
    % This function does the following:
    %   1) Sets outlier raw pupil values to NaN
    %   2) Sets single sharp outlier within typical pupil bounds to NaN
    %   3) Uses a median smoothing filter to smooth pupil trace
    %   4) 

    % Set the upper and lower bounds for pupil size - ideally would be
    % determined using data, but for now these bounds seem good at id-ing
    % outliers
    outlier1 = find(pupil > 200 | pupil < 10);

    % Outliers here are defined as instances where pupil units exceeded 20 on
    % consecutive frames
    diffPup = diff(pupil);
    outlier2 = find(abs(diffPup ) > 20);

    % Occasionally you end up with a single sharp outlier that is within
    % the bounds of the pupil - this should detect these. One challenge
    % using isoutlier is certain types of outlier detection cut the peaks
    % off of pupil dilations. So far this has worked, but may need
    % modification
    oInd = isoutlier(pupil, 'movmedian', 15);
    pupil(oInd) = nan;

    % This bit of code creates a moving window that sweeps through diffPup, and
    % if there is a chunk whose sum of absolute pupil frame difference exceeds
    % a threshold, then all frames within that chunk are rendered as NaNs.
    outlier3 = [];
    windowLength = 30;
    for idx = 1:length(diffPup)-windowLength
        thisWindow = idx : idx+windowLength;
        block = diffPup(thisWindow);
        if sum(abs(block)) > 250
            outlier3 = [outlier3, thisWindow];
        end
    end
    outliers = unique(cat(1, outlier1(:),outlier2(:),outlier3(:)));
    pupil(outliers) = nan;

    % This uses a median smoothing filter with a window of 7 samples - the
    % bigger the window, the smoother the data. 5-10 seems to maintain the
    % shape of smaller pupil changes while still smoothing nicely
    smoothPupil = smoothdata(pupil, 'movmedian', 7);

    % 1-D linear interpolation will not address any NaNs in first and last
    % indices. This bit of code checks to see if there are NaNs at the tails of
    % the pupil trace. If so, it will fill in those NaNs with a single value,
    % based on the average pupil of the nearest 3 seconds relative to the NaNs
    if isnan(smoothPupil(1)) == 1 && isnan(smoothPupil(end)) == 1
        first = find(~isnan(smoothPupil), 1, 'first');
        smoothPupil(1:first-1) = mean(smoothPupil(first:first+90),'omitnan');
        last = find(~isnan(smoothPupil), 1, 'last');
        smoothPupil(last+1:end) = mean(smoothPupil(last-90:last),'omitnan');    
    elseif isnan(smoothPupil(end)) == 1
        last = find(~isnan(smoothPupil), 1, 'last');
        smoothPupil(last+1:end) = mean(smoothPupil(last-90:last),'omitnan');
    elseif isnan(smoothPupil(1)) == 1
        first = find(~isnan(smoothPupil), 1, 'first');
        smoothPupil(1:first-1) = mean(smoothPupil(first:first+90),'omitnan');
    end

    % Linearly interpolate any NaNs within the processed pupil trace
    nanx              = isnan(smoothPupil);
    t                 = 1:numel(smoothPupil);
    smoothPupil(nanx) = interp1(t(~nanx), smoothPupil(~nanx), t(nanx));

    
    final_pupil = smoothPupil;
    if ~isempty(find(isnan(final_pupil) == 1))
        fprintf('*** NaNs detected in processed pupil trace **** \n');
    end

    
     
end