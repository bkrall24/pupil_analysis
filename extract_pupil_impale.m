function [pupil, inner, outer] = extract_pupil_impale(camera_folder, impale_file, sync_file, filtered)
    
    if nargin < 4
        filtered = 0;
    end
    
    % Grab timing data from either ThorSync file (slower) or
    % initial_analysis.mat file (faster) 
    [~, ~, extension] = fileparts(sync_file);
    if contains(extension, '.h5')
        disp('Extracting ThorSync data to retrieve tTrial and tFrame')
        [syncInfo] = extract_ThorSyncData(sync_file,'Impale',1);
        tTrial = syncInfo.tTrial;
        tFrame = syncInfo.tFrame;
    else
        load(sync_file)
        try
            tTrial = d.tTrial;
            tFrame = d.tFrame;
        catch
            error(['File entered contains no tTrial or tFrame info...',...
                'check to see if sync_file dir was created correctly'])
        end
    end
    
    % Get the file names for all the dlc files
    [~,name,~] = fileparts(impale_file);
    csv_files = dir2(camera_folder,'.csv','/s');
    unfiltered_dlc = [];
    filtered_dlc = [];

    for i = 1:length(csv_files)           
        if contains(csv_files(i), name)
            current=csv_files(i);
            if contains(current, 'filtered')
                filtered_dlc = [filtered_dlc,current];
            else
                unfiltered_dlc = [unfiltered_dlc,current];
            end
        end 
    end

    % iteratively extract the pupil from each dlc file
    eyeData = [];
    if exist('filtered','var') && filtered == 1
        for i=1:length(filtered_dlc)
            eyeData_temp = extract_pupil_diameter(filtered_dlc{i},0);
            eyeData_temp(:,7) = i;
            eyeData = [eyeData;eyeData_temp];
        end
    else 
        for i=1:length(unfiltered_dlc)
            eyeData_temp = extract_pupil_diameter(unfiltered_dlc{i},0);
            eyeData_temp(:,7) = i;
            eyeData = [eyeData; eyeData_temp];
        end
    end
    pupil_diameter = eyeData(:,1);
    pupil_diameter = process_pupil(pupil_diameter);
    
    % Get the .txt files containing the TTL information for each video & DLC file
    cameraFiles_txt = dir2(camera_folder,['*',name,'*'],'.txt','/s');
    video_data = [];
        
    for i=1:length(cameraFiles_txt)
        data = table2array(readtable(cameraFiles_txt{i}));
        if isempty(data)
            disp(['NOTE: A .txt camera file containing a single frame was detected'])
            disp([cameraFiles_txt{i}])                               
            fileID = fopen(cameraFiles_txt{i});
            formatSpec = '%f%f%f';
            sizeA = [1 Inf];
            data=fscanf(fileID,formatSpec,sizeA);                
        end
        video_data = [video_data; data];            
    end
    
    
    warning off
    load(impale_file)
    warning on
    
    % Get imaging parameters from the impale file
    fr = round(imaging.frameRate_Hz);
    ISI = imaging.nominalISI/1000;
    framesPerTrial = fr*ISI;
    
    % Grab the time vector from thorSync and noramlize to first frame of
    % first trial
    trial_time_thor = tTrial(1);
    first_frame_t = find(tFrame >= trial_time_thor, 1, 'first');
    thor_delta = tFrame - tFrame(first_frame_t);
    
    % get the timing of all the pupil samples 
    pupil_time = video_data(video_data(:,2) > 0,3);
    time_first_trial = video_data(find(video_data(:,2) < 0, 1, 'first'), 3);
    pupil_delta = pupil_time - time_first_trial;
    
    % get the data corresponding to the pupil on every given trial
    for i=1:length(tTrial)
        trialTime = tTrial(i);

        %grab the frames between these trial times
        frames_a = find(tFrame>=trialTime);
        if length(frames_a)>framesPerTrial
            frames = frames_a(1:framesPerTrial);
        else
            frames = frames_a(1:end);
        end
        
        %grab the timing of the trial (relative to onset of first trial)
        trial_timing = thor_delta(frames);
        
        %interpolate pupil data from pupil timescale to impale
        pupil(:,i) = interp1(pupil_delta, pupil_diameter, trial_timing);
        
    end
    
%     thor_delta = thor_delta(included_frames);
% 
%     % Grab the time vector from the camera .txt files and normalize to
%     % first frame of first trial
%     pupil_time = video_data(:,3);
%     first_frame_p = find(video_data(:,2) < 0, 1, 'first')+1;
%     pupil_delta = pupil_time - pupil_time(first_frame_p);
% 
%     % Cut off extra frames after the last trial
%     last_frame_p = find(video_data(:,2) < 0, 1, 'last')+framesPerTrial;
%     pupil_delta = pupil_delta(first_frame_p:last_frame_p);
% 
%     % Remove the indicies where the TTL pulses came through from the time
%     % vector and the pupil vector.
%     index_ref = video_data(first_frame_p:last_frame_p,2)-2;
%     pupil_delta = pupil_delta(index_ref > 0);
%     pupil_diameter2 = pupil_diameter(index_ref(index_ref > 0));
%     
%     
%     
%     % process the pupil to remove outliers, run a median smoothing filters
%     % and interpolate nan's. Then reinterpolate the processed pupil unto
%     % the timing from tFrames. Reshape it Trial Length * Trials
%     pupil_diameter2 = process_pupil(pupil_diameter2);
%     pupil = interp1(pupil_delta, pupil_diameter2, thor_delta);
%     pupil = reshape(pupil, framesPerTrial, []);
    
    if size(pupil,2) > -min(video_data(:,2))
        disp("Impale indicates more trials than present in video data")
    elseif size(pupil,2) < -min(video_data(:,2))
        disp("Impale indicates fewer trials than present in video data")
    end
    
    inner = SCL.innerIndex;
    outer = SCL.outerIndex;
end



