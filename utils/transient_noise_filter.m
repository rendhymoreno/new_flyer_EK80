%% Transient Noise Filter based on Ryan 2015:
% TODO: EK80 data option and Percentile replacement option
% Sensitive to Threshold!!
% Reducing bias due to noise and attenuation in open-ocean echo integration data
% see also https://support.echoview.com/WebHelp/Windows_And_Dialog_Boxes/Dialog_Boxes/Variable_Properties_Dialog_Box/Operator_Pages/Attenuated_Signal_Removal.htm
% OUTPUT:
% data_filt (struct): Filtered data struct
% pings_effected (nx1 vector): timestamps of pings that were removed or replaced
% 
% INPUT:
% data (struct): EK80/ES60/EK60 data struct that contains either Sv/TS/Power
% trans (char/string): transducer. Choose between 'EK60' or 'ES60' or 'EK80'
% channel (1x1 scalar): choose which channel to run (limited to max 2). Enter [] if you want to run this for all channels.
% r_start (1x1 scalar): exclusion line above in meters (see echoview and paper for explanation)
% r_end (1x1 scalar): exclusion line below in meters (see echoview and paper for explanation)
% ping_window (1x1 scalar): number of pings for "context window"/moving window (in echoview). Must be an odd number.
% percentile (1x1 scalar): reference percentile (N-th percentile:  0-100%) that will be calculated to compare 
%   between reference ping (center ping of context window) and all samples within the context window pings.
% thres (1x1 scalar): units are in dB. This is the threshold used for the algorithm
% method (1x1 string/char): 'Nan' or 'percentile' (Not implemented yet)
% plot_fig (1x1 scalar): enter 1 if you want to plot results or [] if you do not want to plot.
% Default values:
% data = load('E:\2023_MSET\processed\syncedES60_sv.mat'); plot_fig = 1; r_start = 270;  r_end = 700;
% depth_samples = 80; %sample_window = 9; ping_window = 51; percentile = 15; trans = 'ES60'; thres = 12; 
% method = 'NaN'; channel = 1;
% RMS 2023

function data_filt = transient_noise_filter(data,trans,channel,depth_samples,sample_window,ping_window,r_start,r_end,percentile,thres,method,depth_cutoff,plot_fig)
if ~isstring(method)&&~ischar(method)
    error('Method variable not detected!')
elseif ~strcmp(method,'NaN')
    fprintf('Method variable input is unknown, will use NaN replacement instead')
    method = 'NaN';
end
chan = fieldnames(data);
if channel == 1
    fprintf('[TN Filter] Reading data from channel 1: %s \n',chan{1});
    chan = chan(1);
elseif channel == 2
    fprintf('[TN Filter] Reading data from channel 2: %s \n',chan{2});
    chan = chan(2);
else
    fprintf('[TN Filter] Reading data from all %i channels\n',length(chan));
end   
%%
for ch = 1:length(chan)
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if isfield(data.(chan{ch}),'Sv')
                [data_rs,Xj,Xi] = resample_weighted_mean(data,'ES60',ch,1, depth_samples, []);
                datain = data_rs.(chan{ch}).Sv;
                data_out = data.(chan{ch}).Sv;            
                rw = data_rs.(chan{ch}).range;
                tw = data_rs.(chan{ch}).time;
                dr = rw(2)-rw(1);
                dt = seconds(datetime(tw(2),"ConvertFrom","datenum")-datetime(tw(1),"ConvertFrom","datenum"));
                dataflag = 'Sv';
        elseif isfield(data.(chan{ch}),'TS')
                [data_rs,Xj,Xi] = resample_weighted_mean(data, 'ES60',ch, 1, depth_samples, []);
                datain = data_rs.(chan{ch}).TS;
                data_out = data.(chan{ch}).TS;
                rw = data_rs.(chan{ch}).range;
                tw = data_rs.(chan{ch}).time;
                dr = rw(2)-rw(1);
                dt = seconds(datetime(tw(2),"ConvertFrom","datenum")-datetime(tw(1),"ConvertFrom","datenum"));
                dataflag = 'TS';
        end
        
    elseif strcmp(trans,'EK80') %unfinished!!
        if strcmp(data.(chan{ch}).type,'sv_pc') || strcmp(data.(chan{ch}).type,'sv_cw')
            [data_rs,Xj,Xi] = resample_weighted_mean(data, 'EK80',ch, 1, depth_samples, []);
            datain = data_rs.(chan{ch}).val;
            data_out = data.(chan{ch}).val;
            rw = data_rs.(chan{ch}).range;
            tw = data_rs.(chan{ch}).time;
            dr = rw(2)-rw(1);
            depth = [data.(chan{ch}).vars.depth]'; 
            if depth(2)-depth(1) < 0
                ctype = 'upcast';
            else
                ctype = 'downcast';
            end
            if tw(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
                tw = datenum(datetime(tw,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
            end
            dt = seconds(datetime(tw(2),"ConvertFrom","datenum")-datetime(tw(1),"ConvertFrom","datenum"));
            dataflag = 'Sv';
        elseif strcmp(data.(chan{ch}).type,'ts_pc') || strcmp(data.(chan{ch}).type,'ts_cw')
            [data_rs,Xj,Xi] = resample_weighted_mean(data, 'EK80',ch, 1, depth_samples, []);
            datain = data_rs.(chan{ch}).val;
            data_out = data.(chan{ch}).val;
            rw = data_rs.(chan{ch}).range;
            tw = data_rs.(chan{ch}).time;
            dr = rw(2)-rw(1);
            depth = [data.(chan{ch}).vars.depth]'; 
            if depth(2)-depth(1) < 0
                ctype = 'upcast';
            else
                ctype = 'downcast';
            end
            if tw(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
                tw = datenum(datetime(tw,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
            end
            dt = seconds(datetime(tw(2),"ConvertFrom","datenum")-datetime(tw(1),"ConvertFrom","datenum"));
            dataflag = 'TS';
        end
    else
        error('[TN Filter] input data is not from a known format');
    end
    
    %% range indexing  
    r_index = rw >= r_start & rw <= r_end;
    r_new = rw(r_index);
    Xj = Xj(r_index,:); %Xj needs to be indexed for the exclude depths
    
    if ~strcmp(trans,'EK80')
        data_ind = datain(r_index,:);
        eventdn = [tw(1) r_new(1); tw(end) r_new(end)];
    else
        fprintf('[TN Filter] Detected EK80 Flyer with %s profile. Will not apply filter on surface return\n',ctype);
        %depth_cutoff = 100;
        %d_ind_f = dsearchn(depth,depth_cutoff);
        %d_ind_f = dsearchn(depth,d_start);
        if strcmp(ctype,'upcast')
            d_index = depth >= depth_cutoff;
            %eventdn = [tw(1) r_new(1); tw(d_ind_f) r_new(end)];
        else
            d_index = depth >= depth_cutoff;
            %eventdn = [tw(d_ind_f) r_new(1); tw(end) r_new(end)];
        end
            data_ind = datain(r_index,d_index);
            Xi = Xi(d_index);
    end

    if strcmp(dataflag,'Sv')
        data_filt.(chan{ch}).Sv = data_ind;
    else
        data_filt.(chan{ch}).TS = data_ind;
    end
    data_filt.(chan{ch}).range = r_new;
    data_filt.(chan{ch}).time = tw;
    %event_ctx = [t(floor(end/2)) r_new(1); t((floor(end/2)) + ping_window) r_new(end)];
    if isempty(plot_fig) && ~strcmp(trans,'EK80') %Cannot plot EK80
        lg = sprintf('[%s] Subset of data that will be applied to AN filtering (black box: %0.2fm to %0.2fm)',(chan{ch}),r_new(1),r_new(end));
        plotEk_Echogram_Niskin(data,ch,[],eventdn,{0 'inf'},[],[-77 -36],lg,[])
        lg = sprintf('[%s] Subsetted data',(chan{ch}));
        plotEk_Echogram_Niskin(data_filt,ch,[],[],{0 'inf'},[],[-77 -36],lg,[])
    end
    fprintf('[TN Filter] Resampled data has been subsetted from depths: %0.2fm to %0.2fm\n',r_new(1),r_new(end))
    %% Algorithm
    tic
    if rem(ping_window,2) == 0 %even
        ping_window = ping_window+1;
    end
    if rem(sample_window,2) == 0 %even
        sample_window = sample_window+1;
    end
    
    fprintf('[TN Filter] Moving Window height is %0.2fm (%i depth samples) and width is %0.2fseconds (%i ping samples)\n',...
            dr*sample_window,sample_window,dt*ping_window, ping_window);
        
    fprintf('[TN Filter] Calculating Percentile = %i%% for all samples in moving window. Threshold for detection: %idB \n',...
            percentile,thres);
        
    I_max = (size(data_ind,2)-ping_window)+1; %total number of windows in the x-direction/pings (Overlap)
    J_max = (size(data_ind,1)-sample_window)+1; %  the number of windows in depth/last window index in y-direction (Overlap)    
    ctr_wj = ceil(sample_window / 2);
    ctr_wi = ceil(ping_window / 2);
    cond1 = false(J_max, I_max);
    i_idx = 1:I_max;
    j_idx = 1:J_max;
    [I_idx, J_idx] = meshgrid(i_idx, j_idx);
    j_start = J_idx;
    j_end = J_idx + sample_window - 1;
    i_start = I_idx;
    i_end = I_idx + ping_window - 1;    
    ctr_j = 0.5 * (j_end - j_start) + j_start;
    ctr_i = 0.5 * (i_end - i_start) + i_start;
    
    for i = 1:I_max
        for j=1:J_max
            win_samples = data_ind(j_start(j):j_end(j), i_start(i):i_end(i));
            win_samples(ctr_wj, ctr_wi, :) = NaN;
            v_mn = prctile(win_samples(:), percentile, 'Method', 'exact');
            cond1(j,i) = (data_ind(ctr_j(j,i), ctr_i(j,i)) - v_mn > thres);
            if cond1(j,i) && strcmp(method,'NaN')
                if j == J_max
                    j_nan = sum(~isnan(Xj(j,:)));
                    data_out(Xj(ctr_j(j,i),1:j_nan),Xi(:,ctr_i(j,i))) =  NaN;
                else
                    data_out(Xj(ctr_j(j,i),:),Xi(:,ctr_i(j,i))) =  NaN; %replace the center sample of context window [data_ind(ctr_j,ctr_i)]...
                                                                        %and corresponding real samples [data_out(Xj=ctr_j,Xi=ctr_i)] to nan
                end
                %elseif cond1 && cond2 && strcmp(method,'mean') %not yet implemented!!
                % noise(j,i) = mean(
            end
        end
        if any(i == [floor(I_max/4), floor(I_max/2), floor(I_max*3/4), I_max])
            fprintf('[TN Filter] Computed noise for ping %d out of %d\n', i, I_max);
        end
    end
    fprintf('[TN Filter] Completed TN Filtering Algorithm in %0.1f secs \n',toc)
%{
    for i = 1:I_max
        for j = 1:J_max
                j_start = j; j_end = j+sample_window-1;
                i_start = i; i_end = i+ping_window-1;
                
                ctr_j = 0.5*(j_end-j_start)+j_start; %index of center ping in x
                ctr_i = 0.5*(i_end-i_start)+i_start; %index of center ping in y
                win_samples = data_ind(j_start:j_end,i_start:i_end);
                win_samples(ctr_j,ctr_i) = NaN; %excluding the center sample
                v_mn = prctile(win_samples,percentile,"all","Method","exact");
                
                cond1(j,i) = (data_ind(ctr_j,ctr_i) - v_mn > thres);
                %{
                if cond1(j,i) && strcmp(method,'NaN')
                    
                    data_out(Xj(ctr_j,:),Xi(:,ctr_i)) =  NaN; %replace the center sample of context window [data_ind(ctr_j,ctr_i)]...
                                                                %and corresponding real samples [data_out(Xj=ctr_j,Xi=ctr_i)] to nan
                    %elseif cond1 && cond2 && strcmp(method,'mean') %not yet implemented!!
                    %    noise(j,i) = mean(
                end
                %}
        end
           
    end
    %}
    %% Appending data
    samp_aff = sum(isnan(data_out),"all"); %sum(any(isnan(data_out)));
    data_aff = sum(isnan(data_out),"all")*100/(size(data_out,2)*(size(data_out,1)));
    fprintf('[TN Filter] Transient noise detected on %i out of %i backscatter samples (%0.2f%%)\n',...
        samp_aff,(size(data_out,2)*(size(data_out,1))),data_aff);
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
        
    fprintf('[TN Filter] Finished processing: output saved for channel %s\n',chan{ch});
    if plot_fig == 1
        lg = sprintf('[%s] Original Data',(chan{ch}));
        plotEk_Echogram_Niskin(data,ch,[],[],{0 'inf'},[],[-77 -36],lg,[])
        lg = sprintf('[%s] TN Filtered',(chan{ch}));
        plotEk_Echogram_Niskin(data_filt,ch,[],[],{0 'inf'},[],[-77 -36],lg,[])
    end
    
end
end