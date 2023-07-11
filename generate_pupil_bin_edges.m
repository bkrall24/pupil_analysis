function [edge_struct, norm_p] = generate_pupil_bin_edges(data_choice, num_bins)

    % Function to easily generate multiple options for binning pupil data.
    % First it normalizes the pupil to a max value. This is done across all
    % possible pupil values within an animal or a given session. Then using
    % that data it generates bins in four ways. First it creates on set of
    % equally sized bins that span the entire range of pupil across all
    % animals (even_all). Then it creates bins with the same number of
    % samples in each bin (sample_all) but unequal bin sizes. Then it does
    % the same process but creates unique binning options for each animal.
    % (even_animal, sample_animal). The name of each animal is saved as
    % reference in animal_ref.
    
    for i = 1:height(data_choice)
        % p  --> {no. of session days in spreadsheeet} [frames * trials] (regardless of matched/unmatched)
        p{i} = grab_single_pupil(data_choice(i,:), 0);
    end
    
    ct = data_choice{:, 2};        % cell type
    animal_id = data_choice{:,3};  % mouse ID
    date = data_choice{:,4};       % session date

   
    by_session = normalize_pupil(p, true);     % same dimensions as 'p'
    by_animal = normalize_pupil(p, false, findgroups(animal_id));

    [groups, names] = findgroups(animal_id);
    by_animal2 = splitapply(@(x){cat(2,x{:})}, by_animal, groups');    % {mouse} [frames * trials]
    by_session2 = splitapply(@(x){cat(2,x{:})}, by_session, groups');  % {mouse} [frames * trials]

    all_p = cat(2, by_animal{:});

    [~, even_edges] = bin_pupil(all_p, num_bins, 1);
    [~, sample_edges] = bin_pupil(all_p, num_bins, 2);

    for i = 1:length(by_animal2)
        [~, even_edges_animal{i}] = bin_pupil(by_animal2{i}, num_bins, 1);
        [~, sample_edges_animal{i}] = bin_pupil(by_animal2{i}, num_bins, 2);
    end

    edge_struct.even_all = even_edges;
    edge_struct.sample_all = sample_edges;
    edge_struct.even_animal = even_edges_animal;
    edge_struct.sample_animal = sample_edges_animal;
    edge_struct.animal_ref = names';
    
    norm_p.animal = by_animal;
    norm_p.session = by_session;
 
end
