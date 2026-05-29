function dsdata = detrend_data_profilewise(data, mindepth, filter_size)

casts = unique([data.vars.cast]);
dsdata=data;

mean_ping_scalar = mean([data.val],1, 'omitnan');
mean_ping_scalar = mean(mean_ping_scalar,2,'omitnan');

for i = 1:length(casts)
    cast_index = [data.vars.cast] == casts(i);
    depth_index = [data.vars.depth] >= mindepth;
    castdepth_index = and(cast_index, depth_index);
    
    index_pings = data.val(:, castdepth_index);
    cast_ping_n= sum(cast_index);
    start_ping= find(cast_index, 1, 'first');
    end_ping = find(cast_index, 1, 'last');

    mean_ping = mean(index_pings, 2,'omitnan');
    if(~filter_size == 0)
        mean_ping= medfilt1(mean_ping, filter_size);
    end
    meanval_rep = repmat(mean_ping,1,  cast_ping_n);
    
%     if(~sum(isnan(mean_ping)) == size(mean_ping,1))
if(sum(isnan(mean_ping)) == 0)
    [dsdata.val(:,start_ping:end_ping)] = [dsdata.val(:,start_ping:end_ping)] - meanval_rep;
    [dsdata.val(:,start_ping:end_ping)] =   [dsdata.val(:,start_ping:end_ping)] + mean_ping_scalar;
end
    
    disp(100*i/length(casts));
end

disp('Detrend Profilewise Done')
