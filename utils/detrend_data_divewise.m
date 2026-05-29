function dsdata = detrend_data_divewise(data, mindepth, filter_size)

dsdata=data;

mean_ping_scalar=mean(data.val(isfinite(data.val)),'all', 'omitnan') %calc mean of whole pings
% mean_ping_scalar = mean([data.val],1, 'omitnan');
% mean_ping_scalar = mean(mean_ping_scalar,2,'omitnan');

depth_index = [data.vars.depth] >= mindepth; %subsets data above flyer mindepth
index_pings = data.val(:, depth_index); %subsets pings data above flyer mindepth

index_power= mean(index_pings,'omitnan') <= quantile(mean(index_pings, 'omitnan'),0.33); %subsets values with mean (averaged over EK80 range) < 0.3 quartile mean 
index_pings = index_pings(:, index_power);

mean_ping = mean(index_pings, 2, 'omitnan'); %averages all the pings based on EK80 range

if(~filter_size == 0)
    mean_ping= medfilt1(mean_ping, filter_size, 'omitnan', 'truncate'); %detrends with median filter
end
meanval_rep = repmat(mean_ping,1, size([dsdata.val],2)); %replicates filtered value for all pings

% if(sum(isnan(mean_ping)) == 0)
[dsdata.val] = [dsdata.val]-meanval_rep; %decrease values with values > mindepth w/ filtered average
[dsdata.val] = [dsdata.val]+mean_ping_scalar; %scales the value with total mean of pings
% end

disp('Detrend Divewise Done')

