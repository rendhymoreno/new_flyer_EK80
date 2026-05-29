function dsdata = add_vars_data(data)

casts = unique([data.vars.cast]);
dsdata=data;

for i = 1:length(casts)
    cast_index = [data.vars.cast] == casts(i);
    index_vars  = data.vars(:,cast_index);
    index_pings = data.val(:, cast_index);
    
    mindepth= min([index_vars.depth]);
    maxdepth= max([index_vars.depth]);
    meandepth = mean([index_vars.depth]);
    
    mintrack= min([index_vars.along_track]);
    maxtrack= max([index_vars.along_track]);
    
    start_ping= find(cast_index, 1, 'first');
    end_ping = find(cast_index, 1, 'last');
    
    mindepth =num2cell(ones(end_ping-start_ping+1,1)*mindepth);
    maxdepth =num2cell(ones(end_ping-start_ping+1,1)*maxdepth);
    meandepth =num2cell(ones(end_ping-start_ping+1,1)*meandepth);
    
    mintrack =num2cell(ones(end_ping-start_ping+1,1)*mintrack);
    maxtrack =num2cell(ones(end_ping-start_ping+1,1)*maxtrack);
    
    [dsdata.vars(start_ping:end_ping).depth_min] = mindepth{:};
    [dsdata.vars(start_ping:end_ping).depth_max] = maxdepth{:};
    [dsdata.vars(start_ping:end_ping).depth_mean] = meandepth{:};
    [dsdata.vars(start_ping:end_ping).along_track_min] = mintrack{:};
    [dsdata.vars(start_ping:end_ping).along_track_max] = maxtrack{:};
    
    mean_ping = nanmean(index_pings, 1);
    vbs =num2cell(mean_ping);
    [dsdata.vars(start_ping:end_ping).vbs] = vbs{:};
    
    mean_ping = nanmean(mean_ping);
    vbs_profile =num2cell(ones(end_ping-start_ping+1,1)*mean_ping);
    [dsdata.vars(start_ping:end_ping).vbs_profile] = vbs_profile{:};
    
%     profile_n =num2cell(ones(end_ping-start_ping+1,1)*(end_ping-start_ping+1));
%     [dsdata.vars(start_ping:end_ping).profile_n] = profile_n{:};


    
    disp(100*i/length(casts));
end

