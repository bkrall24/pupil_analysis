function [pupil] = grab_single_pupil(d_c, filtered)

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

    
    % Change from NAS directory to local directory (delete later)  [dtd 6/30/23, Keith]
    % Ensures camera and impale folders are linked to NAS whereas the other
    % folders aren't
%     experiment_dir{1,1} = strrep(experiment_dir{1,1}, 'W:', 'D:');
%     experiment_dir{1,1} = strrep(experiment_dir{1,1}, 'X:', 'D:');
    
   % Get full path for pupil_data file  
    full_path = [experiment_dir{1},'\MAT\pupil_data.mat'];
        

    % Get ThorSync file (.h5) directory
        impaleName = split(d_c.ImpaleParameterFile,{'-'});
        impaleIndex = impaleName{2};
        if str2double(impaleIndex) > 99
            sync_folder = '\SyncData';
        elseif str2double(impaleIndex) > 9
            sync_folder = '\SyncData0';
        else
            sync_folder = '\SyncData00';
        end
        if (d_c.Date) < 100000
            thorFolder = [d_c.MainPath, d_c.CellType, '\2P\', d_c.Animal, '\0', num2str(d_c.Date) sync_folder, impaleIndex];
        else
            thorFolder = [d_c.MainPath, d_c.CellType, '\2P\', d_c.Animal, '\', num2str(d_c.Date) sync_folder, impaleIndex];
        end
        sync_file = [[thorFolder{:}], '\Episode001.h5'];
    

    try
        load(full_path);
        if ~exist('pupil', 'var')
            pupil = p;
        end
    catch
        dumDir = split(experiment_dir,'\');
        dums = [dumDir{4},'\',dumDir{6},'\',dumDir{7},'\',dumDir{8}];
        disp(['Processing pupil_data for: ',dums] )        
            
        [pupil, inner, outer] = extract_pupil_impale(camera_folder, impale_file, sync_file, filtered);
        save(full_path, 'pupil');
    end

end
