function experiment = grab_impale_map(impaleFile, cameraFolder)

        warning off
        %This code generates a map to access the data
        %associated with a given impale file
        %Output --> a matrix (map) that serves as a blueprint with each row
        %containing relevant info for the corresponding video frame. 
        trial = 0;
        file = 1;
        currentImpaleFile = load(impaleFile);
        
        %find the camera files corresponding to just this Impale file,
        %returns cells containing pathfiles
        [~,wc,~] = fileparts(impaleFile);
        cameraFiles_txt = dir2(cameraFolder,['*',wc,'*'],'.txt','/s');
        cameraFiles_avi = dir2(cameraFolder,['*',wc,'*'],'.avi','/s');
        
        %this extracts the date information from the filename - requires
        %filename convention of date-1-#-parameters.mat
        f = split(impaleFile, ["\","-"]);
        dateID = str2num(f{7});
        
        %find dlc files corresponding to Impale file 
        temp_cameraFiles_dlc = dir2(cameraFolder,['*',wc,'*'],'.csv','/s');
        
        %Making arrays containing both the filtered and unfiltered dlc
        %files

        cameraFiles_dlc_filtered = {};
        cameraFiles_dlc_notFiltered = {};
        filtCount = 1;
        notFiltCount = 1;
        
        % This sorts the DLC files into filtered and not filtered
        % categories
        for filter_check = 1:length(temp_cameraFiles_dlc)
            current = temp_cameraFiles_dlc{filter_check};
            
            if contains(current, 'filtered')
                cameraFiles_dlc_filtered(filtCount) = {current};
                filtCount = filtCount+1;
            else
                cameraFiles_dlc_notFiltered(notFiltCount) = {current};
                notFiltCount = notFiltCount+1;
            end
        end
        
        
        %video_data contains indices and timing info for video files
        %File structure - each video is split into shorter videos sampled
        %around stimuli. Onset of stimuli is indicated by a negative one in
        %the second column of the txt file.
        %The following code takes all the txt files from a given experiment and
        %concatenates it into one large data matrix called video_data with
        %additional columns added on to indicate file locations, trial
        %numbers, and stimuli information
        
        %columns 1 and 2 - real frame numbers from video camera (not used), but
        %   positioning of negative numbers in column 2 indicate impale trial times
        %column 3 - clock 
        %column 4 - software pupil (if used)
        %column 5 - file relative frame index - 0 indexed to match .csv
        %   DLC files
        %column 6 - camera file index - directly corresponds to index of
        %   path/filename in the cell arrays (i.e experiment.txt).
        %   Therefore if column 6 == 2 then cameraFiles_dlc_notFiltered{2}
        %   is the pathfile to the corresponding file
        %column 7 - actual frame index
        %column 8 - trial number
        %column 9 - rep
        %column 10 - outer value - at indices where it was presented -
        %   actually stimChan{1,1} value so if outer is empty, this column
        %   will contain the inner value
        %column 11 - inner value - at indices where it was presented
        %column 12 - outer index - corresponding to impale's conventions
        %   where each stim has an index 
        %column 13 - inner index
        %column 14 - date of experiment
        
        %concatenate all of these text files together into a large matrix
        video_data = [];
        
        for i=1:length(cameraFiles_txt)
            data = table2array(readtable(cameraFiles_txt{i}));
            
        % Variable 'data' may be empty if .txt file contains only a single
        % frame. This scenario is rare but an IF statement has been added
        % because function readtable cannot be used for .txt files
        % containing only a single row.   EDITED 1.19.22
            if isempty(data)
                disp(['NOTE: A .txt camera file containing a single frame was detected'])
                disp([cameraFiles_txt{i}])                               
                fileID = fopen(cameraFiles_txt{i});
                formatSpec = '%f%f%f';
                sizeA = [1 Inf];
                data=fscanf(fileID,formatSpec,sizeA);                
            end
            
            % some .txt files do not contain the fifth column which is a 0
            % to N index for the file itself - This column is useful for
            % referencing the corresponding rows in dlc files so the
            % following code fills it in
            if size(data,2) < 5
                n = 0;
                for j = 1:size(data,1)
                    
                    if data(j,2) < 0
                        data(j,5) = NaN;
                    else
                        data(j,5) = n;
                        n = n+1;
                    end
                end
            end

            %augment data with an extra column denoting which camera file it came
            %from
            data(:,5) = data(:,5)+1;
            data(:,6) = ones(1,size(data,1)) .* file;
            file = file +1;
            video_data = [video_data; data];            
        end
        
       % trial markers pulls out the indices where the second column == -1
       % which are the TTL pulses. 
        trial_markers = find(video_data(:,2)<0);
        numTrials = sum([currentImpaleFile.SCL.repIndex] >= 0);
        t_times = video_data(:,3);
        
        %30 = hertz, sampling rate of the camera 
        %trialInterval = currentImpaleFile.dacInt.TotalDuration;
        %trialLength = 30*(trialInterval)/1000;   % EDITED 6.29.21
        
        fr = round(currentImpaleFile.imaging.frameRate_Hz);
        ISI = currentImpaleFile.imaging.nominalISI/1000;
        trialLength = fr*ISI;
        
        
        %This determines the length of the stimulus based on parameters
        %defined within the impale file
         for i = 1:length(currentImpaleFile.stimChans) 
            stimDelay(i) = (currentImpaleFile.stimChans{1,i}.Gate.Delay)/1000;
            if currentImpaleFile.stimChans{1,i}.Gate.IsTrainOn
                stimLength(i) = (currentImpaleFile.stimChans{1,i}.Gate.TrainDuration)/1000;
            else
                stimLength(i) = (currentImpaleFile.stimChans{1,i}.Gate.Width)/1000;
            end
         end
                 
         
        for i=1:numTrials
            %times of start and end of trial
            trial = trial + 1;
            trial_start = t_times(trial_markers(i));
            if i==numTrials   %EDITED 6.29.21 (otherwise exceeds numTrials)
                trial_end = t_times(end);
            else
                trial_end = t_times(trial_markers(i+1));
            end 

            %This simply catches the rare case where the TTL pulse and
            %first point of the trial fall at the exact same time.
            if trial_start == t_times(trial_markers(i)+1)
                framefile_indices = find(t_times > trial_start & t_times < trial_end);
                %augment framefile_indices with one previous frame
                aug = framefile_indices(1)-1;
                framefile_indices = [aug; framefile_indices];
              
            else
                framefile_indices = find(t_times > trial_start & t_times < trial_end);
              
            end
             
            frame_index = framefile_indices;
            %this creates a trial index in column 8 of video_data, such
            %that the 8th column of video_data has the number indicating
            %which trial it belongs to
            
            outer = currentImpaleFile.SCL(i).outerIndex;
            inner = currentImpaleFile.SCL(i).innerIndex;
            
            video_data(frame_index,8) = ones(size(frame_index)) .* trial;
            video_data(frame_index,12) = ones(size(frame_index)) .* outer;
            video_data(frame_index,13) = ones(size(frame_index)) .* inner;
            video_data(frame_index,9) = ones(size(frame_index)) .* currentImpaleFile.SCL(i).repIndex;
            
            % For the next two columns, we want to put 0 if the stimuli
            % is not being presented. If there is stimuli presented, put the value of the
            % outer stimulus in column 10 and the inner stimulus in 11.
                % This bit of code assumes a couple things. First it assumes
                % that the outer sequence will be driven by the stimChan{1,1}
                % and the inner sequence will be driven by stimChan{1,2} unless
                % there is only 1 stimChan. This may need to modified if more
                % complex or differently structured stimuli are presented. 
            for i = 1:length(currentImpaleFile.stimChans) 
                delay = stimDelay(i);
                len = stimLength(i);
                
                if isempty(currentImpaleFile.outerSeq.master.values)==1 ...
                        && isempty(currentImpaleFile.innerSeq.master.values)==1
                    %This line was added so one could determine stimulus
                    %onset for params that lack both an inner and outer.
                    %Instead of stimulus info inputted into column 10, NaN
                    %will be inputted. If we do anything w/ this col in
                    %the future, this may change. EDITED 6.29.21
                    stimValue = NaN;
                elseif i == 1 && length(currentImpaleFile.stimChans) > 1
                    stimValue = currentImpaleFile.outerSeq.master.values(outer);
                else
                    stimValue = currentImpaleFile.innerSeq.master.values(inner);
                end
                
                stimEnd = len+delay;
                subIndex = find(t_times > trial_start+delay & t_times < trial_start+stimEnd);
                video_data(subIndex, 9+i) = ones(size(subIndex)) .* stimValue;
            end
            
        end
        
        
        %Remove the TTL pulse rows from the video_data matrix so that
        %it has the same exact dimensions as the data (i.e. pupil
        %diameter). This means that both can be saved (or
        %concatenated) and the indices will correspond
        
        % NOTE for using these maps to correspond to different types of
        % data files (i.e. 2p imaging) more consideration may need to be
        % taken to ensure proper syncing of data
        video_data = video_data(video_data(:,2)>0,:);
        video_data(:,7) = 1:size(video_data,1);
        video_data(:,14) = ones(size(video_data,1),1) * dateID;
    
        %experiment.ttlPulses = video_data(trial_markers,2); %Times of each TTL pulse
        %experiment.stimDelay = stimDelay; %delay of stimulus onset for each channel (in ms)
        %30*str2double(currentImpaleFile.dacInt.TotalDuration)/1000;
        %experiment.stimLength = 30*stimLength; %length of stimulus onset for each channel (in ms)
        %experiment.trialInterval = trialInterval; %length of trial (in ms)

        
        legend = {'Impale_Index_1', 'Impale_Index_2', 'Time', 'Impale_Pupil', 'Video_Index', 'File_Index', 'Data_Index', 'Trial_Index', 'Rep', 'Outer_Stim', 'Inner_Stim', 'Outer_ID', 'Inner_ID', 'Date'}; 
        experiment.tL = trialLength;  %tL=trial length. Note that lengths are in unit frames (not sec)
        experiment.sL = stimLength*fr; %sL=stimulus length
        experiment.fr = fr;
        experiment.ISI = ISI;
        %experiment.map = video_data;
        experiment.map = array2table(video_data, 'VariableNames', legend);
        experiment.txt = cameraFiles_txt;
        experiment.avi = cameraFiles_avi;
        experiment.dlc_filtered = cameraFiles_dlc_filtered;
        experiment.dlc_notfiltered = cameraFiles_dlc_notFiltered; 
        warning on
    
end

