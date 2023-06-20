function reshaped = reshape_by_stimulus(data, inner, outer)
   
    
    if length(unique(outer)) > 1
        stim_ind = findgroups(inner, outer);
    else
        stim_ind = inner;
    end
    
    
    for i = 1:max(stim_ind)
        reshaped(:,i,:) = data(:,stim_ind == i);
    end
    
   
    
    
    
end