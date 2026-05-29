%% Convolution Filter
% TODO: EK80 implementation
% Apply a (nxn) convolution filter of your choosing (average, blur, or median)
% Dependency: 
% nanconv.m : Perform convolutions but including NaNs. Obtained from:
% (https://www.mathworks.com/matlabcentral/fileexchange/41961-nanconv)
% Notes: 
% average(3x3) and blur (3x3) works very similar. Blur kernel from echoview: 
% https://support.echoview.com/WebHelp/Reference/Algorithms/Operators/Convolution_algorithms.htm#Edges
% increasing n will result in harsher cleaning
% use typically before BN filter or post-BN filter
% RMS 2023

function data_conv = conv_filter(data,trans,channel,win_size,method,plot_fig)

%data = load('E:\2023_MSET\processed\syncedES60_sv.mat');
%plot_fig = 1;
%win_size = 7; %3,5,7 only for average and median.
%method = 'median'; %average %blur %median
%trans = 'ES60';
%channel = 1;

chan = fieldnames(data);

if channel == 1
    lg = sprintf('[conv filt] Reading data from channel 1: %s ',chan{1});
    disp(lg)
    chan = chan(1);
elseif channel == 2
    lg = sprintf('[conv filt] Reading data from channel 2: %s ',chan{2});
    disp(lg)
    chan = chan(2);
else
    lg = sprintf('[conv filt] Reading data from all %i channels',length(chan));
    disp(lg)
end   

for ch = 1:length(chan)
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if isfield(data.(chan{ch}),'Sv')
            xlog = data.(chan{ch}).Sv;
            xlin = 10.^(xlog/10);
            r = data.(chan{ch}).range;
            t = data.(chan{ch}).time;
            dataflag = 'Sv';
            fprintf('[conv filt] Reading ES/EK60 Data: data will be converted to linear scale\n');
            %dr = r(2)-r(1);
            %dt = seconds(datetime(t(2),"ConvertFrom","datenum")-datetime(t(1),"ConvertFrom","datenum"));
            %fprintf('[Resample Data] Resampling data with bin size of %0.3fm (%i depth samples) and %0.3fseconds (%i ping samples)\n',...
            %    dr*depth_samples,depth_samples,dt*ping_samples, ping_samples);
        elseif isfield(data.(chan{ch}),'TS')
            xlog = data.(chan{ch}).Sv;
            xlin = 10.^(xlog/10);
            r = data.(chan{ch}).range;
            t = data.(chan{ch}).time;
            fprintf('[conv filt] Reading ES/EK60 Data: data will be converted to linear scale\n');
            dataflag = 'TS';
%             lg = sprintf('[Resample Data] Resampling data with bin size of %0.3fm (%i depth samples) and %0.3fseconds (%i ping samples)',...
%                 dr*depth_samples,depth_samples,dt*ping_samples, ping_samples);
%             disp(lg)
        end
        
    elseif strcmp(trans,'EK80')
        xlog = data.(chan{ch}).val; %using val for now not val2
        xlin = 10.^(xlog/10);
        r = [data.(chan{ch}).range];
        t = [data.(chan{ch}).vars.timestamp];

        if t(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
            t = datenum(datetime(t,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
        end
        fprintf('[conv filt] Reading EK80 Data: data will be converted to linear scale\n');
    else
        error('[conv filter] input data is not from a known format');
    end
    
    %% Kernel
    if strcmp(method,'average')
        kernel = ones(win_size)/win_size^2;
        fprintf('[conv filt] Kernel selected is "%s" with size: %ix%i\n',method,win_size,win_size);
        dataout = nanconv(xlin,kernel);
    elseif strcmp(method,'blur')
        kernel = [1 2 1 ; 2 1 2 ; 1 2 1]/13;
        fprintf('[conv filt] Kernel selected is "%s" with size: 3x3\n',method);
        %dataout = conv2(xlin,kernel,"same");
        dataout = nanconv(xlin,kernel);
    elseif strcmp(method,'median')
        fprintf('[conv filt] Kernel selected is "%s" with size: %ix%i\n',method,win_size,win_size);
        dataout = medfilt2(xlin,[win_size win_size]);
    end
    
    %% Storing Output
    fprintf('[conv filt] Convolution is finished. Converting to log scale and saving Output\n');
    dataout = 10*log10(dataout); %converted back to log
    if ~strcmp(trans,'EK80')
        data_conv.(chan{ch}) = data.(chan{ch});
        if strcmp(dataflag,'Sv')
            data_conv.(chan{ch}).Sv = dataout;
        else
            data_conv.(chan{ch}).TS = dataout;
        end
        %data_conv.(chan{ch}).range = r;
        %data_conv.(chan{ch}).time = t;
        %data_conv.(chan{ch}).cal = data.(chan{ch}).cal;
    else
        data_conv.(chan{ch}) = data.(chan{ch});
        data_conv.(chan{ch}).val = dataout;
    end
    if plot_fig == 1
        %plotEk_Echogram_Niskin(data,channel,ctdpath,eventdn,range,timelength,crange,plt_title,export1)
        plt_t = sprintf('Data applied with %s %ix%i kernel',method,win_size,win_size);
        plotEk_Echogram_Niskin(data,ch,[],[],{0 'inf'},[],[-77 -36; -74 -35],'Original Data',[])
        plotEk_Echogram_Niskin(data_conv,ch,[],[],{0 'inf'},[],[-77 -36; -74 -35],plt_t,[])
    end
end

end