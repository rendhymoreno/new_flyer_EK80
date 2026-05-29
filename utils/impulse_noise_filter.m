%% Impulse noise filter based on Anderson 2005 and Ryan 2015: Reducing bias due to noise and attenuation in open-ocean echo integration data
% TODO: replace with mean option
%
% see also https://support.echoview.com/WebHelp/Windows_And_Dialog_Boxes/Dialog_Boxes/Variable_Properties_Dialog_Box/Operator_Pages/Impulse_Noise_Removal_page.htm
% OUTPUT:
% data_filt (struct): Filtered data struct
% 
% INPUT:
% data (struct): EK80/ES60/EK60 data struct that contains either Sv/TS/Power
% trans (char/string): transducer. Choose between 'EK60' or 'ES60' or 'EK80'
% channel (1x1 scalar): choose which channel to run (limited to max 2). Enter [] if you want to run this for all channels.
% depth_samples (1x1 scalar): number of depth samples required for vertical smoothing (resampling). 
%   If no resampling wanted, then input value of 1. Needs resample_weighted_mean.m
% ping_window (1x1 scalar): number of pings to compare with reference ping (this is one sided)
% thres (1x1 scalar): units are in dB. This is the threshold used for the algorithm
% method (1x1 string/char): 'Nan' or 'mean' (Not implemented yet)
% plot_fig (1x1 scalar): enter 1 if you want to plot results or [] if you do not want to plot.
% Default values:
% data = load('E:\2023_MSET\processed\syncedES60_sv.mat'); plot_fig = 1; vert_resample = 1; ping_samples = 10;
% ping_window = 2; trans = 'ES60'; thres = 9; method = 'NaN';
% RMS 2023

function [data_filt,mask_array] = impulse_noise_filter(data,trans,channel,depth_samples,ping_window,thres,r_start,r_end,method,hardcore,hrd_thres,plot_fig)
if strcmp(hardcore,'remove_ping')
    warning('[IN Filter] Hardcore mode activated: where if a percentage of samples detected with IN exceeds [hrd_thres %] then the whole ping will be removed completely!');
    hardcore = 1;
    if isempty(hrd_thres)
        warning('[IN Filter] If Hardcore mode is activated, a threshold percentage should be inputted (hrd_thres). Using default value 10% of total depth samples instead')
        hrd_thres = 10;
    end
elseif strcmp(hardcore,'remove_gap')
    warning('[IN Filter] Remove gap mode activated: Setting all samples between successive IN detections to IN if dist < [hrd_thres %] for every ping');
    hardcore = 2;
    if isempty(hrd_thres)
        warning('[IN Filter] If Remove gap mode is activated, a threshold percentage should be inputted (hrd_thres). Using default value 5% of total depth samples instead')
        hrd_thres = 5;
    end
else
    hardcore = 0;
end

chan = fieldnames(data);
if channel == 1
    fprintf('[IN Filter] Reading data from channel 1: %s \n',chan{1});
    chan = chan(1);
elseif channel == 2
    fprintf('[IN Filter] Reading data from channel 2: %s \n',chan{2});
    chan = chan(2);
else
    fprintf('[IN Filter] Reading data from all %i channels\n',length(chan));
end   

%%
for ch = 1:length(chan)
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if isfield(data.(chan{ch}),'Sv')
                [data_rs,Xj,Xi] = resample_weighted_mean(data,'ES60',ch,1, depth_samples, []);
                datain = data_rs.(chan{ch}).Sv;
                rw = data_rs.(chan{ch}).range;
                tw = data_rs.(chan{ch}).time;
                data_out = data.(chan{ch}).Sv;            
                dataflag = 'Sv';
        elseif isfield(data.(chan{ch}),'TS')
                [data_rs,Xj,Xi] = resample_weighted_mean(data, 'ES60',ch, 1, depth_samples, []);
                datain = data_rs.(chan{ch}).TS;
                data_out = data.(chan{ch}).TS;
                rw = data_rs.(chan{ch}).range;
                tw = data_rs.(chan{ch}).time;
                %r = data_rs.(chan{ch}).range;
                %t = data_rs.(chan{ch}).time;
                dataflag = 'TS';
        end
    elseif strcmp(trans,'EK80') %unfinished!!
        if strcmp(data.(chan{ch}).type,'sv_pc') || strcmp(data.(chan{ch}).type,'sv_cw')
            [data_rs,Xj,Xi] = resample_weighted_mean(data, 'EK80',ch, 1, depth_samples, []);
            %datain = data_rs.(chan{ch}).Sv;
            datain = data_rs.(chan{ch}).val;
            rw = data_rs.(chan{ch}).range;
            tw = data_rs.(chan{ch}).time;
            data_out = data.(chan{ch}).val;
            depth = [data.(chan{ch}).vars.depth]'; 
        elseif strcmp(data.(chan{ch}).type,'ts_pc') || strcmp(data.(chan{ch}).type,'ts_cw')
            [data_rs,Xj,Xi] = resample_weighted_mean(data, 'EK80',ch, 1, depth_samples, []);
            %datain = data_rs.(chan{ch}).TS;
            datain = data_rs.(chan{ch}).val;
            rw = data_rs.(chan{ch}).range;
            tw = data_rs.(chan{ch}).time;
            data_out = data.(chan{ch}).val;
            depth = [data.(chan{ch}).vars.depth]'; 
        end
    else
        error('[IN Filter] input data is not from a known format');
    end
    
    %% Range indexing
    r_index = rw >= r_start & rw <= r_end;
    r_new = rw(r_index);
    Xj = Xj(r_index,:); %Xj needs to be indexed for the exclude depths

    if ~strcmp(trans,'EK80')
        datain = datain(r_index,:);
    else
        fprintf('[TN Filter] Detected EK80 Flyer data. Will not apply filter on data with flyer depths < 50m\n');
        d_index = depth >= 50;
        datain = datain(r_index,d_index);
        Xi = Xi(d_index);
    end

    data_filt.(chan{ch}).Sv = datain;
    data_filt.(chan{ch}).range = r_new;
    data_filt.(chan{ch}).time = tw;
    eventdn = [tw(1) r_new(1); tw(end) r_new(end)];
    %event_ctx = [t(floor(end/2)) r_new(1); t((floor(end/2)) + ping_window) r_new(end)];
    if plot_fig == 1
        lg = sprintf('[%s] Subset of data that will be applied to IN filtering (black box: %0.2fm to %0.2fm)',(chan{ch}),r_new(1),r_new(end));
        plotEk_Echogram_Niskin(data,ch,[],eventdn,{0 'inf'},[],[-77 -36],lg,[])
        lg = sprintf('[%s] Subsetted data',(chan{ch}));
        plotEk_Echogram_Niskin(data_filt,ch,[],[],{0 'inf'},[],[-77 -36],lg,[])
    end
    fprintf('[IN Filter] Resampled data has been subsetted from depths: %0.2fm to %0.2fm\n',r_new(1),r_new(end))
    %% Algorithm
    imax = size(datain,2);
    jmax = size(datain,1);
    i_start = 1+ping_window;
    i_end = imax-ping_window;
    cond1 = zeros(jmax,imax);
    cond2 = zeros(jmax,imax);
    mask_array = false(size(data_out,1),size(data_out,2));

    for i = i_start:i_end
        for j = 1:jmax
            %if ping_window == 3 %need to implement this agnostically
             %   cond1(j,i) = (datain(j,i) - datain(j,i-ping_window) > thres) || (datain(j,i) - datain(j,i-ping_window+1) > thres)...
              %      || (datain(j,i) - datain(j,i-ping_window+2) > thres);
               % cond2(j,i) = (datain(j,i) - datain(j,i+ping_window) > thres) || (datain(j,i) - datain(j,i+ping_window-1) > thres)...
                %    || (datain(j,i) - datain(j,i+ping_window+2) > thres);
            if ping_window == 2 %need to implement this agnostically
                cond1(j,i) = (datain(j,i) - datain(j,i-ping_window) > thres) || (datain(j,i) - datain(j,i-ping_window+1) > thres);
                cond2(j,i) = (datain(j,i) - datain(j,i+ping_window) > thres) || (datain(j,i) - datain(j,i+ping_window-1) > thres);
            else
                cond1(j,i) = datain(j,i) - datain(j,i-ping_window) > thres;
                cond2(j,i) = datain(j,i) - datain(j,i+ping_window) > thres;
            end

            if cond1(j,i) && cond2(j,i) && strcmp(method,'NaN')
                if j ~= jmax %everything else
                    %if ~hardcore == 1
                    %    data_out(Xj(j,:),Xi(:,i)) =  NaN;
                    %else
                    %    data_out((min(Xj,[],"all"):max(Xj,[],"all")),Xi(:,i)) =  NaN; %whole ping will be erased
                    %end
                    data_out(Xj(j,:),Xi(:,i)) =  NaN;
                    mask_array(Xj(j,:),Xi(:,i)) = 1;
                else %When j=jmax (there will be a NaN at the last depth sample from resampled data)
                    if ~hardcore == 1
                        j_ind = sum(~isnan(Xj(j,:)));
                        data_out(Xj(j,1:j_ind),Xi(:,i)) =  NaN;
                        mask_array(Xj(j,1:j_ind),Xi(:,i)) = 1;
                    elseif any(hardcore == 1) && (sum(cond1(:,i)) > floor((hrd_thres/100)*jmax)) %if 10% of total range samples have NaNs then the whole ping will be removed
                        %j_ind = sum(~isnan(Xj(j,:)));
                        data_out((min(Xj,[],"all"):max(Xj,[],"all")),Xi(:,i)) =  NaN; %whole ping will be erased
                        mask_array((min(Xj,[],"all"):max(Xj,[],"all")),Xi(:,i)) = 1;
                    end
                end
            %elseif cond1 && cond2 && strcmp(method,'mean') %not yet implemented!!
                %    noise(j,i) = mean(
            end
        end
    end
    
    
    %% Appending output and plotting
    if hardcore == 2
        new_mask = INF_Remove_Gaps(mask_array,hrd_thres);
        mask_array = new_mask;
        data_out(new_mask) = NaN;
    end
    
    ping_aff = sum(any(isnan(data_out)));
    data_aff = sum(isnan(data_out),"all")*100/(size(data_out,2)*(size(data_out,1)));
    fprintf('[IN Filter] Impulse noise detected on %0.2f%% of total pings and %0.2f%% of total data was removed\n',...
        ping_aff*100/size(data_out,2),data_aff);

    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if strcmp(dataflag,'Sv')
            data_filt.(chan{ch}).Sv = data_out;
        elseif strcmp(dataflag,'TS')
            data_filt.(chan{ch}).TS = data_out;
        end
        data_filt.(chan{ch}).range = data.(chan{ch}).range;
        data_filt.(chan{ch}).time = data.(chan{ch}).time;
        data_filt.(chan{ch}).cal = data.(chan{ch}).cal;
    elseif strcmp(trans,'EK80')
        data_filt.(chan{ch}) = data.(chan{ch});
        data_filt.(chan{ch}).val = data_out;
    end
    
    fprintf('[IN Filter] Finished processing: output saved for channel %s\n',chan{ch});
    if plot_fig == 1
        lg = sprintf('[%s] Original Data',(chan{ch}));
        plotEk_Echogram_Niskin(data,ch,[],[],{0 'inf'},[],[-77 -36],lg,[])
        lg = sprintf('[%s] IN Filtered',(chan{ch}));
        plotEk_Echogram_Niskin(data_filt,ch,[],[],{0 'inf'},[],[-77 -36],lg,[])
    end
end
end