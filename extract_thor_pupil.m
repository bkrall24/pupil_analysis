%% reworking the pupil data extraction and alignment
spreadsheet = 'W:\Data\Arousal_Project\Arousal_Project_Data_Files.csv';
sp = readtable(spreadsheet);
d_c = sp(331, :);
if (d_c{1,4}) < 100000
    experiment_dir = strcat(d_c{1,1}, d_c{1,2}, '\2P\', d_c{1,3}, '\0', num2str(d_c{1,4}), '\',d_c{1,6});
    impale_file = strcat(char(d_c{1,1}), char(d_c{1,2}), '\Impale\', char(d_c{1,3}), '\0', num2str(d_c{1,4}), '\0',num2str(d_c{1,4}),'-',char(d_c{1,6}),'.mat');
    camera_folder = strcat(char(d_c{1,1}), char(d_c{1,2}), '\Camera\', char(d_c{1,3}), '\0', num2str(d_c{1,4}));
else
    experiment_dir = strcat(d_c{1,1}, d_c{1,2}, '\2P\', d_c{1,3}, '\', num2str(d_c{1,4}), '\',d_c{1,6}');
    impale_file = strcat(char(d_c{1,1}), char(d_c{1,2}), '\Impale\', char(d_c{1,3}), '\', num2str(d_c{1,4}), '\',num2str(d_c{1,4}),'-',char(d_c{1,6}),'.mat');
    camera_folder = strcat(char(d_c{1,1}), char(d_c{1,2}), '\Camera\', char(d_c{1,3}), '\', num2str(d_c{1,4}));
end

exp = table2struct(d_c);
impaleName = split(exp.ImpaleParameterFile,{'-'});
impaleIndex = impaleName{2};
if str2double(impaleIndex) > 99
    sync_folder = '\SyncData';
elseif str2double(impaleIndex) > 9
    sync_folder = '\SyncData0';
else
    sync_folder = '\SyncData00';
end
if (exp.Date) < 100000
    thorFolder = [exp.MainPath, exp.CellType, '\2P\', exp.Animal, '\0', num2str(exp.Date) sync_folder, impaleIndex];
else
    thorFolder = [exp.MainPath, exp.CellType, '\2P\', exp.Animal, '\', num2str(exp.Date) sync_folder, impaleIndex];
end
data_sync = dir2(thorFolder, '.h5', '/s');
thorSync_file = data_sync{1};

%% Get ThorSync data
syncInfo = extract_ThorSyncData(thorSync_file,'Impale',1);

%% Get Pupil data
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
        eyeData=[eyeData; eyeData_temp];
    end
end

pupil_diameter = eyeData(:,1);

%% Get Camera .txt files

[~,wc,~] = fileparts(impale_file);
cameraFiles_txt = dir2(camera_folder,['*',wc,'*'],'.txt','/s');
cameraFiles_avi = dir2(camera_folder,['*',wc,'*'],'.avi','/s');

%%
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
    video_data = [video_data; data];            
end


%% generate two equal time vectors based on the video time and the thor sync time

thor_time = syncInfo.tFrame;
trial_time_thor = syncInfo.tTrial(1);
first_frame_t = find(syncInfo.tFrame>=trial_time_thor, 1, 'first');
thor_delta = thor_time - thor_time(first_frame_t);

fr = 30;
trialLength = round(diff(syncInfo.tTrial(1:2)));
framesPerTrial = round(fr * trialLength);
last_frame_t = find(syncInfo.tFrame >= syncInfo.tTrial(end), 1, 'first')+framesPerTrial-1;
thor_delta = thor_delta(first_frame_t: last_frame_t);

pupil_time = video_data(:,3);
first_frame_p = find(video_data(:,2) < 0, 1, 'first')+1;
pupil_delta = pupil_time - pupil_time(first_frame_p);

last_frame_p = find(video_data(:,2) < 0, 1, 'last')+framesPerTrial;
pupil_delta = pupil_delta(first_frame_p:last_frame_p);

index_ref = video_data(first_frame_p:last_frame_p,2)-2;

pupil_delta = pupil_delta(index_ref> 0);
pupil_diameter2 = pupil_diameter(index_ref(index_ref > 0));

%% 

pupil = interp1(pupil_delta, pupil_diameter2, thor_delta);

%pupil = reshape(pupil, framesPerTrial, []);