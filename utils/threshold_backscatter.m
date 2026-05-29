%% Thresholding using time varying threshold over range or normal method
% Based on Haris 2021 et al Sounding out life in the deep using acoustic data from ships of opportunity
% more info: https://support.echoview.com/WebHelp/Reference/Algorithms/Time-varied_threshold.htm?rhhlterm=threshold%20thresholded
% 
function data_thres = threshold_backscatter(data,trans,channel,min_thres,max_thres,method,plot_fig)

chan = fieldnames(data);
if channel == 1
    fprintf('[thresholding] Reading data from channel 1: %s\n',chan{1});
    chan = chan(1);
elseif channel == 2
    fprintf('[thresholding] Reading data from channel 2: %s\n',chan{2});
    chan = chan(2);
else
    fprintf('[thresholding] Reading data from all %i channels\n',length(chan));
end   

for ch = 1:length(chan)
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if isfield(data.(chan{ch}),'Sv')
            datain = data.(chan{ch}).Sv;
            if size(data.(chan{ch}).range,1) == 1
                r = repmat(data.(chan{ch}).range',1,size(datain,2));
            else
                r = repmat(data.(chan{ch}).range,1,size(datain,2));
            end
            t = data.(chan{ch}).time;
            c = data.(chan{ch}).cal.soundvelocity;
            alpha = data.(chan{ch}).cal.absorptioncoefficient;
            tau = data.(chan{ch}).cal.pulselength;
            tvg_start = 1;
            fprintf('[thresholding] Reading ES/EK60 Sv Data and cal parameters\n');
            dataflag = 'Sv';
            %dr = r(2)-r(1);
            %dt = seconds(datetime(t(2),"ConvertFrom","datenum")-datetime(t(1),"ConvertFrom","datenum"));
            %fprintf('[Resample Data] Resampling data with bin size of %0.3fm (%i depth samples) and %0.3fseconds (%i ping samples)\n',...
            %    dr*depth_samples,depth_samples,dt*ping_samples, ping_samples);
        elseif isfield(data.(chan{ch}),'TS')
            datain = data.(chan{ch}).TS;
            r = repmat(data.(chan{ch}).range',1,size(datain,2));
            t = data.(chan{ch}).time;
            c = data.(chan{ch}).cal.soundvelocity;
            alpha = data.(chan{ch}).cal.absorptioncoefficient;
            tau = data.(chan{ch}).cal.pulselength;
            tvg_start = 1;
            fprintf('[thresholding] Reading ES/EK60 TS Data and cal parameters\n');
            dataflag = 'TS';
%             lg = sprintf('[Resample Data] Resampling data with bin size of %0.3fm (%i depth samples) and %0.3fseconds (%i ping samples)',...
%                 dr*depth_samples,depth_samples,dt*ping_samples, ping_samples);
%             disp(lg)
        end
        
    elseif strcmp(trans,'EK80') %unfinished!!
        if strcmp(data.(chan{ch}).type,'sv_pc') || strcmp(data.(chan{ch}).type,'sv_cw')
            datain = data.(chan{ch}).val;
            
            r = repmat([data.(chan{ch}).range],1,size(datain,2));
            t = [data.(chan{ch}).vars.timestamp];
            c = mean([data.(chan{ch}).vars.soundspeed]);
            alpha = unique([data.(chan{ch}).vars.absorptionCoeff]);
            if length(alpha)>1
                alpha = mean([data.(chan{ch}).vars.absorptionCoeff]);
            end
            tau = data.(chan{ch}).cal.pulse_length; %effective pulse length???
            tvg_start = data.(chan{ch}).vars.TVGStart;
            dataflag = 'Sv';
        elseif strcmp(data.(chan{ch}).type,'ts_pc') || strcmp(data.(chan{ch}).type,'ts_cw')
            datain = data.(chan{ch}).val;
            r = repmat([data.(chan{ch}).range],1,size(datain,2));
            t = [data.(chan{ch}).vars.timestamp];
            c = mean([data.(chan{ch}).vars.soundspeed]);
            alpha = unique([data.(chan{ch}).vars.absorptionCoeff]);
            if length(alpha)>1
                alpha = mean([data.(chan{ch}).vars.absorptionCoeff]);
            end
            tau = data.(chan{ch}).cal.pulse_length; %effective pulse length???
            tvg_start = data.(chan{ch}).vars.TVGStart;
            dataflag = 'TS';
        end

        if t(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
            disp('[thresholding] Timestamp of EK80 is in epoch milliseconds')
            t = datenum(datetime(t,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
        end
    else
        error('[Resample Data] input data is not from a known format');
    end
    %% corrected range for TVG
    if strcmp(method,'TVT')||strcmp(method,'tvt')
        r_tvg = zeros(size(datain,1),size(datain,2));
        for i = 1:size(datain,2)
            for j = 1:size(datain,1)
                if r(j,i) < tvg_start %all range values under ct/2 will not have TVG applied
                    r_tvg(j,i) = 1; %remember that log10(1) = 0!!!
                else
                    r_tvg(j,i) = r(j,i) - (tau*(c/4));
                end
            end
        end
        if strcmp(dataflag,'Sv')
            TVT = min_thres + (20*log10(r_tvg)) + 2*alpha*(r_tvg);
            fprintf('[thresholding] Time Varying Threshold(r) has been calculated for Sv\n');
        else %TS
            TVT = min_thres + (40*log10(r_tvg)) + 2*alpha*(r_tvg);
            fprintf('[thresholding] Time Varying Threshold(r) has been calculated for TS\n');
        end
    else %normal thresholding
        TVT = min_thres;
        fprintf('[thresholding] Using scalar threshold method\n');
    end
    %% Thresholding algorithm
    dataout = datain;
    cond = (datain < TVT) | (datain > max_thres);
    % Use logical indexing to update dataout
    dataout(cond) = -999;
    % Count the number of elements set to NaN
    count = sum(cond(:));
    fprintf('[thresholding] %i sample values have been removed (%0.1f%%)\n',count,(count*100/numel(datain)));
    %% Saving Output
    %data_thres.(chan{ch}).Sv = dataout;
    %data_thres.(chan{ch}).range = data.(chan{ch}).range;
    %data_thres.(chan{ch}).time = t;
    %data_thres.(chan{ch}).cal = data.(chan{ch}).cal;

    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if strcmp(dataflag,'Sv')
            data_thres.(chan{ch}) = data.(chan{ch});
            data_thres.(chan{ch}).Sv = dataout;
        elseif strcmp(dataflag,'TS')
            data_thres.(chan{ch}) = data.(chan{ch});
            data_thres.(chan{ch}).Sv = dataout;
        end
        %data_filt.(chan{ch}).range = data.(chan{ch}).range;
        %data_filt.(chan{ch}).time = data.(chan{ch}).time;
        %data_filt.(chan{ch}).cal = data.(chan{ch}).cal;
    elseif strcmp(trans,'EK80')
        data_thres.(chan{ch}) = data.(chan{ch});
        data_thres.(chan{ch}).val = dataout;
    end

    fprintf('[thresholding] Output saved for channel %s\n',chan{ch});
    if plot_fig == 1
        lg = sprintf('[%s] Original Data',(chan{ch}));
        plotEk_Echogram_Niskin(data,ch,[],[],{0 'inf'},[],[-77 -36],lg,[])
        if ~strcmp(method,'TVT') && ~strcmp(method,'tvt')
            lg = sprintf('[%s] Thresholded using scalar values',(chan{ch}));
        else
            lg = sprintf('[%s] Thresholded using TVT method',(chan{ch}));
        end
        plotEk_Echogram_Niskin(data_thres,ch,[],[],{0 'inf'},[],[-77 -36],lg,[])
    end
end