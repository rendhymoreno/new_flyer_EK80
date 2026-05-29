%% Fix ES60 Timestamps
% There has been strange timestamp values occasionally seen in the ES60
% data. This function replaces those erroneous pings with NaN (problematic?? Decided to remove completely!). 
% The erroneous values typically are much lesser than the serial datenum
% therefore a simple function to remove timestamp values lower than the
% first timestamp is incorporated
% RMS 2023

function dataout = fix_ES60_timestamp(data)
chan = fieldnames(data);
for ch = 1:length(chan)
    sv_data = data.(chan{ch}).Sv;
    range = data.(chan{ch}).range;
    time = data.(chan{ch}).time;
    time(time<time(1)) = NaN;
    %r_idx = isnan(range);
    t_idx = isnan(time);
    sv_data(:,t_idx) = NaN;
    %sv_data(r_idx,:) = NaN;
    fprintf('[Fix ES60 Timestamps] Removed %i erroneous timestamps for data in %s\n',sum(t_idx),(chan{ch}))
    if length(range) < size(sv_data,1)
        fprintf('[Fix ES60 Timestamps] Detected mismatch in range vector length: %i and Sv rows: %i. Will adjust length or pad with NaNs \n',length(range),size(sv_data,1))
        sv_data = sv_data(1:length(range),:);
    end
    time(:,t_idx) = [];
    sv_data(:,t_idx) = [];
    dataout.(chan{ch}).Sv = sv_data;
    dataout.(chan{ch}).range = data.(chan{ch}).range;
    dataout.(chan{ch}).time = time;
    dataout.(chan{ch}).cal = data.(chan{ch}).cal;
end
fprintf('[Fix ES60 Timestamps] Timestamps and range vectors completed!\n')
end