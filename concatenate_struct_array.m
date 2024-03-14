function st2 = concatenate_struct_array(st, trials)
    
    field_id = fieldnames(st);
    if nargin < 2
        for i = 1:length(field_id)
            dat = {st.(field_id{i})};
            st2.(field_id{i}) = cat(1, dat{:});
        end
    else
        for i = 1:length(field_id)
            field_size = size(st(1).(field_id{i}));
            
            % Any 3D arrays are NaN padded
            if length(field_size) == 3
                st2.(field_id{i}) = [];
                
                for j = 1:length(st)
                    field_size = size(st(j).(field_id{i}));
                    temp = nan(field_size(1), field_size(2), trials);
                    temp(:,:,1:size(st(j).(field_id{i}),3)) = st(j).(field_id{i});
                    st2.(field_id{i}) = cat(1, st2.(field_id{i}), temp);
                end
%             elseif field_size(2) > 1
%                  st2.(field_id{i}) = [];
%                 
%                 for j = 1:length(st)
%                     field_size = size(st(j).(field_id{i}));
%                     temp = nan(field_size(1), trials);
%                     temp(:,1:size(st(j).(field_id{i}),2)) = st(j).(field_id{i});
%                     st2.(field_id{i}) = cat(1, st2.(field_id{i}), temp);
%                 end
            else
                dat = {st.(field_id{i})};
                st2.(field_id{i}) = cat(1, dat{:});
            end
        end
    end
        
       
end