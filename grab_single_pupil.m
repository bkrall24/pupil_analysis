function p = grab_single_pupil(d_c, filtered)

    % future issues: add tosca capabilities here. incorporate the same
    % basic code structure for impale and tosca
    if (d_c{1,4}) < 100000
        experiment_dir = strcat(d_c{1,1}, d_c{1,2}, '\2P\', d_c{1,3}, '\0', num2str(d_c{1,4}), '\',d_c{1,6});
        impale_file = strcat(char(d_c{1,1}), char(d_c{1,2}), '\Impale\', char(d_c{1,3}), '\0', num2str(d_c{1,4}), '\0',num2str(d_c{1,4}),'-',char(d_c{1,6}),'.mat');
        camera_folder = strcat(char(d_c{1,1}), char(d_c{1,2}), '\Camera\', char(d_c{1,3}), '\0', num2str(d_c{1,4}));
    else
        experiment_dir = strcat(d_c{1,1}, d_c{1,2}, '\2P\', d_c{1,3}, '\', num2str(d_c{1,4}), '\',d_c{1,6}');
        impale_file = strcat(char(d_c{1,1}), char(d_c{1,2}), '\Impale\', char(d_c{1,3}), '\', num2str(d_c{1,4}), '\',num2str(d_c{1,4}),'-',char(d_c{1,6}),'.mat');
        camera_folder = strcat(char(d_c{1,1}), char(d_c{1,2}), '\Camera\', char(d_c{1,3}), '\', num2str(d_c{1,4}));
    end

    if ~isfolder([experiment_dir{1},'\MAT'])
        mkdir(experiment_dir{1}, 'MAT');
    end 

    full_path = [experiment_dir{1},'\MAT\pupil_data.mat'];
    
    experiment_file = [experiment_dir{1},'\MAT\initial_analysis.mat'];

    
    if isfile(experiment_file)
        sync_file = experiment_file;
    else
        impaleName = split(d_c.ImpaleParameterFile,{'-'});
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
        sync_file = data_sync{1};
    end
    

    try
        load(full_path);
      
    catch
        dumDir = split(experiment_dir,'\');
        dums = [dumDir{4},'\',dumDir{6},'\',dumDir{7},'\',dumDir{8}];
        disp(['Processing pupil_data for: ',dums] )   
        
        %if isequal(d_c(1,:).stim_software, "Impale")
            
        [p, inner, outer] = extract_pupil_impale(camera_folder, impale_file, sync_file, filtered);
        save(full_path, 'p');
        %else
       % disp("GOTTA ADD THIS CAPABILITY <3 BECCA 5.31.23")
        %end
    end

    
    

end