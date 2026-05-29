%% Cannot combine from two channels, must only summon one channel!
% Another issue: findpeaks is based on "depth" positive not -1*depth!! (unsure difference) 
function [outdata,ncast_num,idx_output,tcast] = flyer_cast_idx(data, channel)
chan = fieldnames(data);

if channel == 1
    lg = sprintf('[Fix cast] Reading data from channel 1: %s ',chan{1});
    disp(lg)
    chan = chan(1);
elseif channel == 2
    lg = sprintf('[Fix cast] Reading data from channel 2: %s ',chan{2});
    disp(lg)
    chan = chan(2);
else
    lg = sprintf('[Fix cast] Reading data from all %i channels',length(chan));
    disp(lg)
end

for ch = 1:length(chan)
    vars = [data.(chan{ch}).vars];
    % range = [data.(chan{ch}).range];
    depth = [data.(chan{ch}).vars.depth];
    % val = [data.(chan{ch}).val];
    casts = [vars.cast];
    cast_id = unique(casts);
    for i = 1:length(cast_id)
        cast_idx = (casts==cast_id(i));
        cast_idx2 = find(cast_idx==1);
        cast_idx_list(1,i) = cast_idx2(1);
        cast_idx_list(2,i) = cast_idx2(end);
        %flyer_casts.(chan{ch}).("C"+sprintf('%d',cast_id(i))).global_idx = cast_idx2;
    end

    % Fix casts and merge them

    % Determine if upcast or downcast from the middle cast 
    midc = floor(size(cast_idx_list,2)/2);

    if depth(cast_idx_list(2,midc))-depth(cast_idx_list(1,midc)) < 0 %negative depth/depth is smaller
        tcast = 'upcast';
    elseif depth(cast_idx_list(2,midc))-depth(cast_idx_list(1,midc)) > 0 %positive/going deeper
        tcast = 'dcast';
    end

    % if depth(cast_idx_list(2,1)-depth(cast_idx_list(1,1)) ~= 0
    %     if depth(cast_idx_list(2,1))-depth(cast_idx_list(1,1)) < 0 %negative depth/depth is smaller
    %         tcast = 'upcast';
    %     elseif depth(cast_idx_list(2,1))-depth(cast_idx_list(1,1)) > 0 %positive/going deeper
    %         tcast = 'dcast';
    %     end
    % else % The first cast has only 1 element, will check from the next cast instead
    %     if depth(cast_idx_list(2,2))-depth(cast_idx_list(1,2)) < 0 %negative depth/depth is smaller
    %         tcast = 'upcast';
    %     elseif depth(cast_idx_list(2,2))-depth(cast_idx_list(1,2)) > 0 %positive/going deeper
    %         tcast = 'dcast';
    %     end
    % end
    fprintf('[Fix cast] Detected %scasts\n',tcast);
    
    %% Simple algo

    % Find gradient of depth and find discontinuities
    
    if strcmp(tcast,'upcast')
        [h_pks,f_loc] = findpeaks(depth,'MinPeakProminence',10);
        s_loc = [1 f_loc];
        cast_new_idx = [s_loc ; f_loc-1 length(depth)];
        cast_new_idx(3,:) = [cast_id(1):1:cast_id(1)+size(cast_new_idx,2)-1];
        idx_output = cast_new_idx(1:2,:);
        ncast_num = cast_new_idx(3,:);
    elseif strcmp(tcast,'dcast') %Not figured out
        [h_pks,f_loc] = findpeaks(depth,'MinPeakProminence',10);
        s_loc = [1 f_loc+1];
        cast_new_idx = [s_loc ; f_loc length(depth)];
        cast_new_idx(3,:) = [cast_id(1):1:cast_id(1)+size(cast_new_idx,2)-1];
        idx_output = cast_new_idx(1:2,:);
        ncast_num = cast_new_idx(3,:);
    end
    
    new_cast = zeros(length(depth),1);
    for j=1:length(cast_new_idx)
        %do quick check
        if cast_new_idx(1,j) == 1 && cast_new_idx(2,j) == 1
            cond1 = abs(depth(cast_new_idx(1,j)) - depth(cast_new_idx(1,j) + 1)) < 50;
            cond2 = 1;
        elseif cast_new_idx(1,j) ~= numel(depth)
            cond1 = abs(depth(cast_new_idx(1,j)) - depth(cast_new_idx(1,j) + 1)) < 50;
            cond2 = abs(depth(cast_new_idx(2,j)) - depth(cast_new_idx(2,j) - 1)) < 50;
        elseif cast_new_idx(1,j) == numel(depth)
            cond1 = 1;
            cond2 = abs(depth(cast_new_idx(2,j)) - depth(cast_new_idx(2,j) - 1)) < 50;
        %elseif cast_new_idx(1,j) == 1
        %    cond1 = abs(depth(cast_new_idx(1,j)) - depth(cast_new_idx(1,j) + 1)) < 50;
        %    cond2 = 1;
        end

        if cond1 && cond2
            new_cast(cast_new_idx(1,j):cast_new_idx(2,j)) = cast_new_idx(3,j);
        elseif cond1 == 0 && cond2 %1st data point should be in previous cast
            new_cast((cast_new_idx(1,j)+1):cast_new_idx(2,j)) = cast_new_idx(3,j);
            if j ~= 1
                new_cast(cast_new_idx(1,j)) = cast_new_idx(3,j)-1;
            elseif j == 1
                new_cast(cast_new_idx(2,j)) = cast_new_idx(3,j);
            end
        elseif cond1 && cond2 == 0 %last data point is a jump, should be in next cast!
            new_cast((cast_new_idx(1,j)):cast_new_idx(2,j)-1) = cast_new_idx(3,j);
            if j ~= length(cast_new_idx)
                new_cast(cast_new_idx(2,j)) = cast_new_idx(3,j)+1;
            elseif j == length(cast_new_idx)
                new_cast(cast_new_idx(2,j)) = cast_new_idx(3,j);
            end
        end


    end

    %{
    new_castID = zeros(1,length(cast_id));
    for j=1:length(cast_id)-1 %running up to last cast - 1
        %fprintf('[casts] Processing cast %d\n',cast_id(j));
        
        if strcmp(tcast,'up')

            if j==1
                new_castID(j) = cast_id(j);
            elseif j==length(cast_id)-1
                if flag == 0 %seperate
                    new_castID(j) = new_castID(j-1)+1;
                elseif flag == 1 %same as previous/merge
                    new_castID(j) = new_castID(j-1);
                end
            else
                if flag == 0 %seperate
                    new_castID(j) = new_castID(j-1)+1;
                elseif flag == 1 %same as previous/merge
                    new_castID(j) = new_castID(j-1);
                end
            end

            %fprintf('[casts] j=%d // Checking for the next cast (Cast %d)\n',j,cast_id(j+1));
            if (depth(cast_idx_list(1,j+1)) - depth(cast_idx_list(2,j)) < 0) %1st cond: if going up and 2nd cast depth is lower/shallower
                if (depth(cast_idx_list(2,j+1)) - depth(cast_idx_list(1,j+1)) < 0) %2nd cond: if 2nd cast is monotonically increasing
                    %fprintf('[casts] Cast %d will be merged with cast %d\n',cast_id(j+1),cast_id(j));
                    flag = 1;

                else %2nd cast is not monotonically increasing / strange error
                    %fprintf('[casts] Cast %d and cast %d are seperate\n',cast_id(j+1),cast_id(j));
                    new_castID(j+1) = new_castID(j+1);
                    flag = 0;
                end
                %fprintf('[casts] Cast %d and cast %d are seperate \n',cast_id(j+1),cast_id(j)); %seperate casts
                %new_castID(j+1) = new_castID(j+1);
                %flag = 0;
            else
                %fprintf('[casts] Cast %d and cast %d are seperate; no change needed \n',cast_id(j+1),cast_id(j)); %seperate casts
                %new_castID(j+1) = new_castID(j+1);
                flag = 0;
            end

        elseif strcmp(tcast,'down') %Not Fixed!!!!
            if (depth(cast_idx_list(1,j+1)) - depth(cast_idx_list(2,j)) > 0) %1st cond: if going up and 2nd cast depth is lower/shallower
                if (depth(cast_idx_list(2,j+1)) - depth(cast_idx_list(1,j+1)) > 0) %2nd cond: if 2nd cast is monotonically decreasing
                    %fprintf('[casts] Cast %d will be merged with cast %d\n',cast_id(j+1),cast_id(j));
                    new_castID(j+1) = cast_id(j);
                    new_castID(j) = cast_id(j);
                else %2nd cast is not monotonically decreasing / strange error
                    %fprintf('[casts] Cast %d and cast %d are seperate\n',cast_id(j+1),cast_id(j));
                    new_castID(j) = cast_id(j);
                end
                % fprintf('[casts] Cast %d and cast %d are seperate \n',cast_id(j+1),cast_id(j)); %seperate casts
                % new_castID(j) = cast_id(j);
            else
                %fprintf('[casts] Cast %d and cast %d are seperate \n',cast_id(j+1),cast_id(j)); %seperate casts
                new_castID(j) = cast_id(j);
            end
        end
        
        % Final index
        if flag == 0 %seperate
            new_castID(end) = new_castID(end-1)+1;
        elseif flag == 1 %same as previous/merge
            new_castID(end) = new_castID(end);
        end
    end


% Map from cast_index to new index
ncast_num = unique(new_castID);
casts_output = casts;

for k = 1:length(ncast_num)
    idx_map_old = find(new_castID == ncast_num(k));
    idx_global = [cast_idx_list(1,min(idx_map_old));cast_idx_list(2,max(idx_map_old))];
    %flyer_casts.(chan{ch}).("C"+sprintf('%d',ncast_num(k))).global_idx = idx_global(1):1:idx_global(end);
    casts_output(idx_global(1):idx_global(2)) = ncast_num(k);
    idx_output(:,k) = idx_global;
end
    %}

outdata = data;
for l=1:numel(depth)
    outdata.(chan{ch}).vars(l).cast_new = new_cast(l);
end

fprintf('[Fix cast] Finished remapping casts for channel: %s\n',chan{ch});
end

end

