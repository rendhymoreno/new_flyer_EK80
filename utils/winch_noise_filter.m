%%
%Default values
%channel = 1;
%r_filt = 425;
%depth_min = 50;
%depth_max = 500;
%plot_fig = 1;
%filtblocks = 9;
%filtblocks = filtblocks*2;

function data_filt = winch_noise_filter(data,channel,depth_min,depth_max,r_filt,filtblocks,plot_fig)

chan = fieldnames(data);
filtblocks = filtblocks*2;
if channel == 1
    lg = sprintf('[WN Filter] Reading data from channel 1: %s ',chan{1});
    disp(lg)
    chan = chan(1);
elseif channel == 2
    lg = sprintf('[WN Filter] Reading data from channel 2: %s ',chan{2});
    disp(lg)
    chan = chan(2);
else
    lg = sprintf('[WN Filter] Reading data from all %i channels',length(chan));
    disp(lg)
end

%plotEk_Echogram_Niskin(data,channel,[],r_filt,{0 'inf'},[],[-77 -36; -77 -36],'Depth where filter will be analyzed',[])

for n=1:length(chan)
    r = data.(chan{n}).range;
    t = data.(chan{n}).time;

    if isfield(data.(chan{n}),'Sv')
        datain = data.(chan{n}).Sv;
        dataflag = 'Sv';
    elseif isfield(data.(chan{n}),'TS')
        datain = data.(chan{n}).TS;
        dataflag = 'TS';
    end

    %% Range indexing
    r_index = r >= depth_min & r <= depth_max;
    r_new = r(r_index);
    %Xj = Xj(r_index,:); %Xj needs to be indexed for the exclude depths
    data_ind = datain(r_index,:);
    fprintf('[WN Filter] Resampled data has been subsetted from depths: %0.2fm to %0.2fm\n',r_new(1),r_new(end))

    %% Extract selected depth time series
    rf_ind = dsearchn(r_new',r_filt);
    y = data_ind(rf_ind,:);
    [TF,S1,S2] = ischange(y,'linear','MaxNumChanges',filtblocks-1); %number of filter blocks are 9 for Bermuda dive3.
    segline = S1.*(1:length(y)) + S2;

    figure()
    plot(t,y)
    hold on
    plot(t,segline)
    hold off

    tt = zeros(filtblocks/2,2);
    asu = zeros(filtblocks,1);
    asu(2:end) = find(TF);
    asu(1) = 1;
    tt(1:end,1) = asu(1:2:filtblocks);
    tt(1:end,2) = asu(2:2:filtblocks);
    %extra layer to remove outliers
    %tt2 = tt;
    tt(1,2) = tt(1,2)+1;
    tt(2:end,1) = tt(2:end,1)-1;
    tt(2:end,2) = tt(2:end,2)+1;
    %% Replace values and save output
    for i=1:filtblocks/2
        data_ind(:,tt(i,1):tt(i,2)) = NaN;
    end

    datain(r_index,:) = data_ind;
    data_filt.(chan{n}) = data.(chan{n});

    if strcmp(dataflag,'Sv')
        data_filt.(chan{n}).Sv = datain;
    else
        data_filt.(chan{n}).TS = datain;
    end

    if plot_fig == 1
        %plotEk_Echogram_Niskin(data,channel,ctdpath,eventdn,range,timelength,crange,plt_title,export1)
        plt_t = sprintf('[WN Filter] Removed %i noise blocks',filtblocks/2);
        plotEk_Echogram_Niskin(data,n,[],[],{0 'inf'},[],[-77 -36; -74 -35],'Original Data',[])
        plotEk_Echogram_Niskin(data_filt,n,[],[],{0 'inf'},[],[-77 -36; -74 -35],plt_t,[])
    end
end
end

