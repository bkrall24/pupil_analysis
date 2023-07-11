%% Workflow 
% The goal of this code is simplify data extraction and organization to
% streamline analysis of neural data based on pupil states

%% Determine data of interest
% Initial extraction code relies on the data spreadsheets. 

spreadsheet = "D:\Data\Arousal_Project\dataSpreadsheet.csv";

% Convert FOV column into char to allow users to input numerical as
% well as alphanumerical values
opts = detectImportOptions(spreadsheet);
opts = setvartype(opts,{'FOV'},'char');
sp   = readtable(spreadsheet,opts);


%% Determine pupil binning
% Decide on a number of bins you want to include. This creates edges_struct
% with options to use as edges and more can be easily added, if you
% wanted. It also normalizes your pupil data as percent max across all
% sessions for an animal, as well as percent max for each given session. I
% would recommend saving the output that you want (i.e. norm_p.animal).
% In that case norm_p.animal(i) would correspond to sp(i) so you can
% easily access corresponding data. Also you won't have to rely on
% regenerating and renormalizing the pupil data.


num_bins = 3;
[edge_struct, norm_p] = generate_pupil_bin_edges(sp, num_bins);

% NOTE: this function might be a bit overengineered if we just want to use
% evenly spaced bins. To do that you just need the discretize function
% which will generate edges and bins. Also I realized that we might be
% overextending our equally spaced bins by including the absolute minimum
% across the dataset. It almost ensures that your first bin will be
% undersampled cause its already a rare state. An alternative is to simply
% find the low and high of [all_pupil.pupil] then 
% edges = low:(high-low)/num_bins:high

%% Grab data
% Select data based on a given cell type. Use whatever method
% you want to select data (i.e. choose experiments) but you'll want to have
% a reference to what rows you're choosing of your spreadsheet cause then
% you'll use the same indices to select the pupil data from norm_p.animal. 

cell_type = 'ET';
data_choice = sp(contains(sp{:,2}, cell_type),:);
p = norm_p.animal(contains(sp{:,2}, cell_type));

% compile arousal data will grab all the data and organize it into cell x
% stimulus x trial. Output will have an array of structs with length equal
% to the number of FOVs. If match_boo == true, matched FOVs are
% concatenated into a single struct with matched cells concatenated across
% trials. If match_boo == false, each day of imaging is kept as separate
% but the cell_index will be the same for cells that are matched. I would
% save these structs as they are very useful starting points for analysis.

% [cells * stim * reps]. The 'cells' are based on matched indexing, whereby
% the no. of cells is based on whether it was matched to the first day of
% imaging (ie, if a cell didn't match to a cell from Day 1, then it was
% given a new cell ID). This can turn a FOV with 300 cells matched across 6
% days, and ramp up the no. of cells to 1000.
match_boo = true;
[all_neural, all_pupil, all_ref] = compile_arousal_data(data_choice, p,...
    match_boo);


% Save the above structs
save_loc = ['D:\Data\Arousal_Project\',cell_type,'\Data_structs\']
save(fullfile(save_loc, 'all_neural.mat'), 'all_neural');
save(fullfile(save_loc, 'all_pupil.mat'), 'all_pupil');
save(fullfile(save_loc, 'all_ref.mat'), 'all_ref');

%% Bin Pupil
% Just use discretize to easily bin each row of your all_pupil struct. A
% nice thing here is you can change the binning incredibly easily with just
% two lines of code.

% Option to discretize based on custom pupil bins
edge_struct.custom = [0 .5 .75 1];

binned = arrayfun(@(x) discretize(x.pupil, edge_struct.custom), ...
    all_pupil, 'UniformOutput', false);
[all_pupil.bins] = binned{:};

%% Calculate Pupil modulation index
% This index is less than ideal for low values, I'm going to continue to
% validate it and improve it
pmi = arrayfun(@(x,y) determine_pupil_modulation_index(x.spikes, y.bins,...
    num_bins, false, true), all_neural, all_pupil);


%% Determine the max number of trials that a single cell might have

max_neural = max(arrayfun(@(x) size(x.spikes,3), all_neural));
max_pupil = max(arrayfun(@(x) size(x.pupil,3), all_pupil));
if max_neural ~= max_pupil
    warning("Something's up, pupil and neural trials should match");
end

%% Concatenate across experiments to generate a single struct of all cells

pmi = concatenate_struct_array(pmi);
neural = concatenate_struct_array(all_neural, max_neural);
pupil = concatenate_struct_array(all_pupil, max_pupil);

%% Add an index to the neural data. 
% Neural and pupil data struct will have different lengths in the first
% dimension. Using the reference struct you can make an array equal to the
% first dimension of neural data that refers to the corresponding row in
% the pupil data.

index = arrayfun(@(x) repmat(x.index, x.cell_count,1), all_ref, ...
    'UniformOutput', false);
index = cat(1, index{:});
neural.index = index;


%% Create new data_choice variable to use on older code
% To use the same data_choice table for the other code, the match_dir
% column class must be changed from a 'cell' to a 'string'

% Create new variable, convert column format from cell to string, assign to
% the same column and rename the column
data_csv       = data_choice;
data_csv(:,24) = varfun(@string, data_csv(:,23));
data_csv(:,23) = [];
data_csv       = renamevars(data_csv,["Var24"],["matchMatDir"]);


%% From here, do your analysis. 
%  response_at_BF is a good example of a simple process to easily generate
%  your data.

bf = response_at_BF(neural.zscores, neural.index, pupil.bins, ...
    logical(neural.sound_resp), 10);

