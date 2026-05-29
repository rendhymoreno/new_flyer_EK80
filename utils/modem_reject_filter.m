function out_data = modem_reject_filter(in_data, start_range, filter_k,  std_limit)
out_data=in_data

%average back half
distal_mean=rangeds(in_data,start_range, max(in_data.range(:,1)), max(in_data.range(:,1))-start_range); 
distal_mean=distal_mean.val;

%median filter with using neighboring pings. 7 or 9 seems to work
val_filtered = medfilt1(distal_mean,filter_k, 'omitnan');

%find pings where the difference from the median exceeds 1.5 or 2 standard deviations of the median difference.  
ind = find((distal_mean-val_filtered) > std_limit*std(distal_mean-val_filtered));

%gert rid of those
out_data.val(:,ind) =[]
out_data.range(:,ind) =[]
out_data.vars(ind) =[]
% out_data.val(:,ind) =nan
% out_data.range(:,ind) =nan
% out_data.vars(ind) =nan
disp('Modem Reject Filter Done')
