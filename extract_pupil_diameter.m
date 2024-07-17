function eyeData = extract_pupil_diameter(filename, rows)

    if nargin == 1 
        rows = 0;
    end
    
    if rows == 0
        data_matrix = readmatrix(filename);
    else
        % Due to the header with column names, add three to beginning and ending
        % index to select the rows were column 1 == rows
        select = [rows(1)+3, rows(end)+3];
        opts = delimitedTextImportOptions('DataLines', select); 
        opts.VariableTypes = 'double';
        data_matrix = readmatrix(filename, opts);
    end


    pupil_range = 2:25;
    eye_range = 26:49;

    pupil_matrix = data_matrix(:,pupil_range);
    eye_matrix = data_matrix(:,eye_range);

    x = [1,4,7,10,13,16,19,22];
    y = x+1;
    lik = x+2;
    top = 4;
    bottom = 3;

    pupil_x = pupil_matrix(:, x);
    pupil_y = pupil_matrix(:,y);
    pupil_lik = pupil_matrix(:,lik);

    eye_x = eye_matrix(:, x);
    eye_y = eye_matrix(:,y);
    eye_lik = eye_matrix(:,lik);

    thresh = 0.95;
    eyeData = nan(size(pupil_matrix,1),6);
    parfor ii = 1:size(pupil_matrix,1)

        warning off
        goodPoints = (pupil_lik(ii,:) > thresh);

        if sum(goodPoints) > 5
            pupil_points = [pupil_x(ii,goodPoints); pupil_y(ii,goodPoints)];
        end

        try            
            [z,a,b,alpha] = fitellipse(pupil_points);
            pupil_diameter = 2*max(a,b);
            pupil_height = 2*min(a,b);
            pupil_center = norm(z);

        catch
            pupil_height = nan;
            pupil_diameter = nan;
            pupil_center = nan;

        end

        goodEyes = (eye_lik(ii,:) > thresh);

        if sum(goodEyes) > 5
            eye_points = [eye_x(ii,goodPoints); eye_y(ii,goodPoints)];
        end

        try            
            [z,a,b,alpha] = fitellipse(eye_points);
            eye_diameter = 2*max(a,b);
            eye_height = 2*min(a,b);
            eye_center = norm(z);

        catch
            eye_height = nan;
            eye_diameter = nan;
            eye_center = nan;

        end

        eyeData(ii,:) = [pupil_diameter, pupil_height, pupil_center, eye_diameter, eye_height, eye_center];
    end
    
end

