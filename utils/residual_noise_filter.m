% Residual Noise Filter
% Based on 2021 Haris et al Sounding out life in the deep using acoustic data from ships of opportunity
% This function is used after thresholding the data outputted from Background
% Noise Filter. Default median filter size used in paper is 7.
% RMS

function data_filt = residual_noise_filter(data,trans,channel,depth_min,depth_max,medsize,plot_fig)
chan = fieldnames(data);
if channel == 1
    fprintf('[RN Filter] Reading data from channel 1: %s\n',chan{1});
    chan = chan(1);
elseif channel == 2
    fprintf('[RN Filter] Reading data from channel 2: %s\n',chan{2});
    chan = chan(2);
else
    fprintf('[RN Filter] Reading data from all %i channels\n',length(chan));
end   

for ch = 1:length(chan)
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if isfield(data.(chan{ch}),'Sv') 
            fprintf('[RN Filter] Detected Sv Data. Median bitmap mask will be generated\n');
            datain = data.(chan{ch}).Sv;
            r = data.(chan{ch}).range;
            t = data.(chan{ch}).time;
        elseif isfield(data.(chan{ch}),'TS') 
            fprintf('[RN Filter] Detected TS Data. Median bitmap mask will be generated\n');
            datain = data.(chan{ch}).TS;
            r = data.(chan{ch}).range;
            t = data.(chan{ch}).time;
        end
        
    elseif strcmp(trans,'EK80') %unfinished!!
        datain = data.(chan{ch}).val; %using val for now not val2
        r = [data.(chan{ch}).range];
        t = [data.(chan{ch}).vars.timestamp];
        if t(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
            t = datenum(datetime(t,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
        end
        fprintf('[RN Filter] Detected EK80 Data. Median bitmap mask will be generated\n');
    else
        error('[RN Filter] input data is not from a known format');
    end
    
    %% range indexing
    r_index = r >= depth_min & r <= depth_max;
    r_new = r(r_index);
    %Xj = Xj(r_index,:); %Xj needs to be indexed for the exclude depths
    data_ind = datain(r_index,:);
    if ~strcmp(trans,'EK80')
        data_filt.(chan{ch}) = data.(chan{ch});
        if isfield(data.(chan{ch}),'Sv') %|| strcmp(data.(chan{ch}).type,'sv_pc') || strcmp(data.(chan{ch}).type,'sv_cw')
            data_filt.(chan{ch}).Sv = data_ind;
        elseif isfield(data.(chan{ch}),'TS') %|| strcmp(data.(chan{ch}).type,'ts_pc') || strcmp(data.(chan{ch}).type,'ts_cw')
            data_filt.(chan{ch}).TS = data_ind;
        end
        data_filt.(chan{ch}).range = r_new;
        %data_filt.(chan{ch}).time = t;
        %data_filt.(chan{ch}).cal = data.(chan{ch}).cal;
    else %EK80
        data_filt.(chan{ch}) = data.(chan{ch});
        data_filt.(chan{ch}).val = data_ind;
        data_filt.(chan{ch}).range = r_new;
    end
    eventdn = [t(1) r_new(1); t(end) r_new(end)];
    %event_ctx = [t(floor(end/2)) r_new(1); t((floor(end/2)) + ping_window) r_new(end)];
    if plot_fig == 1
        lg = sprintf('[%s] Subset of data that will be applied to RN filtering (black box: %0.2fm to %0.2fm)',(chan{ch}),r_new(1),r_new(end));
        plotEk_Echogram_Niskin(data,ch,[],eventdn,{0 'inf'},[],[-77 -36],lg,[])
        lg = sprintf('[%s] Subsetted data',(chan{ch}));
        plotEk_Echogram_Niskin(data_filt,ch,[],[],{0 'inf'},[],[-77 -36],lg,[])
    end
    fprintf('[RN Filter] Resampled data has been subsetted from depths: %0.2fm to %0.2fm\n',r_new(1),r_new(end))
    
    %% Generating Median Mask
    data_med = conv_filter(data_filt,trans,ch,medsize,'median',[]);
    if ~strcmp(trans,'EK80')
        if isfield(data.(chan{ch}),'Sv')
            dataout = data_med.(chan{ch}).Sv;
        else
            dataout = data_med.(chan{ch}).TS;
        end
    else %EK80
        dataout = data_med.(chan{ch}).val;
    end
    cond = -998>dataout | dataout>-20; %values outside the limits
    %dataout(cond) = -999;
    %datain(cond) = -999;
    dataout2 = datain(r_index,:);
    dataout2(cond) = -999; 
    count = sum(cond(:));
    fprintf('[RN Filter] Saving output. Samples that do not match with median bitmap mask have been removed (%0.1f%%)\n',...
        (count*100/sum(~isnan(datain),"all")));
    %datain(r_index,:) = dataout;
    datain(r_index,:) = dataout2;
    
    if ~strcmp(trans,'EK80')
        if isfield(data.(chan{ch}),'Sv')
            data_filt.(chan{ch}).Sv = datain;
        else
            data_filt.(chan{ch}).TS = datain;
        end
        data_filt.(chan{ch}).range = r;
    else
        data_filt.(chan{ch}).val = datain;
    end

    if plot_fig == 1
        %plotEk_Echogram_Niskin(data,channel,ctdpath,eventdn,range,timelength,crange,plt_title,export1)
        plt_t = sprintf('Data removed using median %ix%i bitmap mask',medsize,medsize);
        plotEk_Echogram_Niskin(data,ch,[],[],{0 'inf'},[],[-77 -36; -74 -35],'Original Data',[])
        plotEk_Echogram_Niskin(data_filt,ch,[],[],{0 'inf'},[],[-77 -36; -74 -35],plt_t,[])
    end
end