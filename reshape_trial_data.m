function trial_return = reshape_trial_data(experiment, data)
    
    % This function is designed to take sequential data an organize it
    % so the first dimension is organized based on trials. Data should have
    % the same exact number of rows as the map in experiment. 
    
    map = experiment.map{:,:};
    trialLength = round(experiment.tL);
    trials = unique(map(:,8))';
    
    guide = [];
    p = 0;
    for a = 1:max(map(:,13))
        for b = 1:max(map(:,12))
             p = p +1;
            guide(a,b) = p;
        end
    end
    
    if trials(1) == 0
        trials = trials(2:end);
    end
    
    reps = ceil(max(map(:,8))./9);
    
    reshapedData = [];
    reshapedMap = [];
    for i = trials
        trialIndex = find(map(:,8) == i);
        ind = find(trials == i);
        
        %This code ensures that you end up with equal dimensions across
        %trials despite the fact that sometimes you end up with one more
        %or one fewer frame than intended. When we're dealing with
        %sequential trials where the beginning of the next trial has the
        %same stimulus (normally silence) as the end of current trial, just
        %add it to the previous trial so it reaches sufficient length. But
        %if the next trial in the data isn't the sequential or doesn't have
        %the same stimulus presentation, randomly choose another frame from
        %that same trial with the same stimulus presented.
        %
        %This is perhaps overly complicated. A simpler work around would be
        %to simply make the trial length one less than expected. Doing that
        %would ensure that you are not sampling the same data twice.
        dif = length(trialIndex) - trialLength;
        add = [];
        
        if dif < 0
            n = ind + 1;
            if (n <= length(trials)) & (trials(n) - trials(ind) == 1)
                next = find(map(:,8) == trials(n));
                add = next(1:abs(dif));
           
            else
                lastSample = map(trialIndex(end),10:11);
                eqIndices = find(map(trialIndex,10)== lastSample(1) & map(trialIndex,11)== lastSample(2));
                add = randperm(length(eqIndices));
                add = add(1:abs(dif));
                add = trialIndex(add);
                
            end
        elseif dif > 0
            trialIndex = trialIndex(1:trialLength);
        end
        
        trialData = data(trialIndex,:);
        trialMap = map(trialIndex,:);
        
        for j = add
            
            trialData = [trialData; data(j,:)];
            trialMap = [trialMap; map(j,:)];
        end
        
        trialID = guide(trialMap(1,13), trialMap(1,12));
        %rep =ceil(trialMap(1,8,i)./9);
        
        
        reshapedData(:,:,ind) = trialData;
        reshapedMap(:,:,ind) = trialMap;
        trialGuide(ind) = trialID;
        
    end
    
    %This flattens the data so if you're dealing with 1D pupil data, you
    %end up with 2D matrix instead of 3D with size(data,2)==1.
%     if size(reshapedData,2) == 1
%         data = reshape(reshapedData, size(data,[1,3]));
%     end
    %Outputs a Length of trial x D x trial number data matrix where D 
    %is the dimension of the data (1 for pupil diameter)
    trial_return.data = reshapedData;
    %Outputs a Length of trial x 13 x trial number data matrix 
    trial_return.map = reshapedMap;
    trial_return.guide = trialGuide;
end
