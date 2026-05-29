%% Attenuation Noise Filter based on Ryan 2015:
% TODO: EK80 data option and Percentile replacement option
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
% data = load('E:\2023_MSET\processed\syncedES60_sv.mat'); plot_fig = 1; r_start = 10; r_end = 80;
% ping_window = 31;% percentile = 50;% trans = 'ES60';% thres = 8; % method = 'NaN';
% RMS 2023

function [data_filt,pings_effected] = attenuation_noise_filter(data,trans,channel,r_start,r_end,ping_window,percentile,thres,method,plot_fig)

chan = fieldnames(data);
if channel == 1
    fprintf('[AN Filter] Reading data from channel 1: %s \n',chan{1});
    chan = chan(1);
elseif channel == 2
    fprintf('[AN Filter] Reading data from channel 2: %s \n',chan{2});
    chan = chan(2);
else
    fprintf('[AN Filter] Reading data from all %i channels\n',length(chan));
end   

%%
for ch = 1:length(chan)
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if isfield(data.(chan{ch}),'Sv')
                datain = data.(chan{ch}).Sv;
                r = data.(chan{ch}).range;
                t = data.(chan{ch}).time;
                fprintf('[AN Filter] Detected ES/EK60 Sv Data: channel %i\n',ch);
                dataflag = 'Sv';
        elseif isfield(data.(chan{ch}),'TS')
                datain = data.(chan{ch}).TS;
                r = data.(chan{ch}).range;
                t = data.(chan{ch}).time;
                fprintf('[AN Filter] Detected ES/EK60 TS Data: channel %i\n',ch);
                dataflag = 'TS';
        end
        
    elseif strcmp(trans,'EK80') %unfinished!!
        if strcmp(data.(chan{ch}).type,'sv_pc') || strcmp(data.(chan{ch}).type,'sv_cw')
            datain = data.(chan{ch}).val;
            t = [data.(chan{ch}).vars.timestamp];
            r = [data.(chan{ch}).range];
            if t(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
                t = datenum(datetime(t,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
            end
            fprintf('[AN Filter] Detected EK80 Sv Data: channel %i\n',ch);
            dataflag = 'Sv';

        elseif strcmp(data.(chan{ch}).type,'ts_pc') || strcmp(data.(chan{ch}).type,'ts_cw')
            datain = data.(chan{ch}).val;
            t = [data.(chan{ch}).vars.timestamp];
            r = [data.(chan{ch}).range];
            if t(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
                t = datenum(datetime(t,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
            end
            fprintf('[AN Filter] Detected EK80 TS Data: channel %i\n',ch);
            dataflag = 'TS';
        end
        
    else
        error('input data is not from a known format');
    end
    
    %% Range indexing and plotting 
    r_index = r >= r_start & r <= r_end;
    r_new = r(r_index);
    data_ind = datain(r_index,:);
    data_filt.(chan{ch}).Sv = data_ind;
    data_filt.(chan{ch}).range = r_new;
    data_filt.(chan{ch}).time = t;
    eventdn = [t(1) r_new(1); t(end) r_new(end)];
    %event_ctx = [t(floor(end/2)) r_new(1); t((floor(end/2)) + ping_window) r_new(end)];
    if plot_fig == 1
        lg = sprintf('[%s] Subset of data that will be applied to AN filtering (black box: %0.2fm to %0.2fm)',(chan{ch}),r_new(1),r_new(end));
        plotEk_Echogram_Niskin(data,ch,[],eventdn,{0 'inf'},[],[-77 -36],lg,[])
        lg = sprintf('[%s] Subsetted data',(chan{ch}));
        plotEk_Echogram_Niskin(data_filt,ch,[],[],{0 'inf'},[],[-77 -36],lg,[])
    end
    
    %% Algorithm
    if percentile ~= 50
        fprintf('[AN Filter] Calculating Percentile = %0.2f%% for all pings. Moving window width: %i pings. Threshold for detection: %idB \n',...
            percentile,ping_window,thres);
    else
        fprintf('[AN Filter] Calculating the median for all pings (P = %0.2f%%). Moving window width: %i pings. Threshold for detection: %idB \n',...
            percentile,ping_window,thres);
    end

    p_ij = prctile(data_ind,percentile,1,"Method","exact"); %calculate percentile p for all pings using sorting method
    I_max = (size(t,2)-ping_window)+1;
    p_mn = zeros(1,I_max);
    %noise = zeros(size(data_ind,1),size(data_ind,2));
    cond1 = zeros(1,size(data_ind,2));
    
    for i=1:I_max
        i_start = i; i_end = i+ping_window-1;
        i_index = i_start:i_end;
        if i == 1
            center_index = ceil(0.5*ping_window);
        else
            center_index = center_index+1;
        end
        
        i_index(ceil(length(i_index)/2)) = [];
        p_mn(i) = prctile(data_ind(:,i_index),percentile,"all","Method","exact");
        %diff(i) = p_mn(i) - p_ij(center_index);
        
        cond1(center_index) = (p_mn(i) - p_ij(center_index) < thres);
        
        %if ~cond1(i) && strcmp(method,'NaN')
        %    noise(:,center_index) = NaN;
            %elseif cond1 && strcmp(method,'percentile') %not yet implemented!!
            %    noise(j,i) = mean(
        %else
        %    noise(:,center_index) = data_ind(:,center_index);
        %end
        
        if i == floor(I_max/2) || i == I_max
            fprintf('[AN Filter] computed attenuation noise for ping %d out of %d \n',i,I_max);
        end  
    end
  %% append data
    cond1(1:ceil(length(i_index)/2)) = 1;
    cond1(center_index+1:end) = 1;
    remove_idx = find(~cond1); %pings that were removed
    datain(:,remove_idx) = NaN;
    ping_aff = sum(length(remove_idx));
    fprintf('[AN Filter] Detected %i out of %i total pings (%0.2f%%). Replaced affected pings with %s. %i pings were not processed\n',...
        ping_aff,I_max,ping_aff*100/I_max,method,ping_window-1);
    pings_effected = t(remove_idx)';
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if strcmp(dataflag,'Sv')
            data_filt.(chan{ch}).Sv = datain;
        elseif strcmp(dataflag,'TS')
            data_filt.(chan{ch}).TS = datain;
        end
        data_filt.(chan{ch}).range = r;
        data_filt.(chan{ch}).time = t;
        data_filt.(chan{ch}).cal = data.(chan{ch}).cal;
    elseif strcmp(trans,'EK80')
        data_filt.(chan{ch}) = data.(chan{ch});
        data_filt.(chan{ch}).val = datain;
    end
    fprintf('[AN Filter] Finished processing: output saved for channel %s\n',chan{ch});
    if plot_fig == 1
        lg = sprintf('[%s] Pings that were detected as attenuated noise',(chan{ch}));
        plotEk_Echogram_Niskin(data,ch,[],pings_effected,{0 'inf'},[],[-77 -36; -74 -35],lg,[])
    end
end

end