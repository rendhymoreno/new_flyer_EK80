function datafilt = remove_nan(data,trans)
chan = fieldnames(data);
datafilt = data;
for ch = 1:length(chan)
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if isfield(data.(chan{ch}),'Sv')
            dataout = data.(chan{ch}).Sv;
            dataflag = 'Sv';
        elseif isfield(data.(chan{ch}),'TS')
            datain = data.(chan{ch}).TS;
            dataflag = 'TS';
        end
    elseif strcmp(trans,'EK80') %unfinished!!
        dataout = data.(chan{ch}).val;
        dataflag = [];
    end
sdata = sum(isnan(dataout),"all");
dataout(isnan(dataout)) = -999;
fprintf('[Remove NaN Backscatter] Removed %i NaN values for data in %s\n',sdata,(chan{ch}))
if isempty(dataflag)
    datafilt.(chan{ch}).val = dataout;
elseif strcmp(dataflag,'Sv')
    datafilt.(chan{ch}).Sv = dataout;
elseif strcmp(dataflag,'TS')
    datafilt.(chan{ch}).TS = dataout;
end
fprintf('[Remove NaN Backscatter] Completed for channel: %s \n',(chan{ch}));
end

end