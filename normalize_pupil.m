function p = normalize_pupil(p , bysession, animal)
    
    % by session
    if bysession
        for i = 1:length(p)
            p{i} = p{i}./max(p{i},[], 'all');
        end
    else
    % by animal
        if size(animal,1) > size(animal,2)
            animal = animal';
        end
        
        for i = unique(animal)
            p_animal = p(animal == i);
            m = max(cat(2, p_animal{:}), [], 'all');
            p_animal2 = cellfun(@(x) x./m, p_animal, 'UniformOutput', false);
            p(animal == i) = p_animal2;
        end
    end       
           
end