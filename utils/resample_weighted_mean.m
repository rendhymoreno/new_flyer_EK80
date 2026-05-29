%% Resample data by range samples and pings using weighted mean
% TODO: Not yet complete: Need EK80 data option
% Need to save original sample indexes for each resampled grid (DONE, OPTIMIZED)
% Based on echoview
% https://support.echoview.com/WebHelp/Windows_And_Dialog_Boxes/Dialog_Boxes/Variable_Properties_Dialog_Box/Operator_Pages/Resample_by.htm#Resample_page
% resamples the original data to a bin width in # of samples in depth and
% pings. 
% OUTPUT:
%       data_resampled (struct): Will contain Sv/TS/Power (depending on
%       input), new range vectors, new ping/time vectors, and old
%       calibration parameters from original data
% INPUT:
%       data (string/char): path to data (Sv/Ts/Power) struct or data variable
%       trans (string/char): 'ES60' or 'EK60' or 'EK80'
%       ping_samples (int 1x1): number of ping samples for bin width in
%           time
%       depth_samples (int 1x1): number of depth samples for bin width in
%           depth
%       plot_fig (int 1x1): set to 1 to plot before after resampling
% RMS 2023

function [data_resampled, Xnum_j, Xnum_i] = resample_weighted_mean(data, trans, channel, ping_samples, depth_samples, plot_fig)

%datain = load('E:\2023_MSET\processed\syncedES60_sv.mat');
%plot_fig = 1;
%ping_samples = 10;
%depth_samples = 10;
%trans = 'ES60';

%data = load(datain);
chan = fieldnames(data);

if channel == 1
    lg = sprintf('[Resample Data] Reading data from channel 1: %s ',chan{1});
    disp(lg)
    chan = chan(1);
elseif channel == 2
    lg = sprintf('[Resample Data] Reading data from channel 2: %s ',chan{2});
    disp(lg)
    chan = chan(2);
else
    lg = sprintf('[Resample Data] Reading data from all %i channels',length(chan));
    disp(lg)
end   

%% Parsing input dataset

for ch = 1:length(chan)
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if isfield(data.(chan{ch}),'Sv')
            xlog = data.(chan{ch}).Sv;
            xlin = 10.^(xlog/10);
            if size(data.(chan{ch}).range,1) == 1
                r = repmat(data.(chan{ch}).range',1,size(xlin,2));
            else
                r = repmat(data.(chan{ch}).range,1,size(xlin,2));
            end
            d = data.(chan{ch}).time;
            lg = sprintf('[Resample Data] Reading ES/EK60 Data: timestamp format is serial datenum');
            disp(lg)
            dr = r(2)-r(1);
            dt = seconds(datetime(d(2),"ConvertFrom","datenum")-datetime(d(1),"ConvertFrom","datenum"));
            fprintf('[Resample Data] Resampling data with bin size of %0.3fm (%i depth samples) and %0.3fseconds (%i ping samples)\n',...
                dr*depth_samples,depth_samples,dt*ping_samples, ping_samples);
            dataflag = 'Sv';
        elseif isfield(data.(chan{ch}),'TS')
            xlog = data.(chan{ch}).TS;
            xlin = 10.^(xlog/10);
            r = repmat(data.(chan{ch}).range',1,size(xlin,2));
            d = data.(chan{ch}).time;
            lg = sprintf('[Resample Data] Reading ES/EK60 Data: timestamp format is serial datenum');
            disp(lg)
            fprintf('[Resample Data] Resampling data with bin size of %0.3fm (%i depth samples) and %0.3fseconds (%i ping samples)\n',...
                dr*depth_samples,depth_samples,dt*ping_samples, ping_samples);
            dataflag = 'TS';
        end
        
    elseif strcmp(trans,'EK80') %unfinished!!
        if strcmp(data.(chan{ch}).type,'sv_pc') || strcmp(data.(chan{ch}).type,'sv_cw')
            data_resampled = data;
            vars = data.(chan{ch}).vars;
            xlog = data.(chan{ch}).val; %using val for now not val2
            xlin = 10.^(xlog/10);
            d = [data.(chan{ch}).vars.timestamp];
            r = repmat(data.(chan{ch}).range,1,size(xlin,2));
            fprintf('[Resample Data] Reading EK80 Data: timestamp format is serial datenum\n');
            dr = r(2)-r(1);
            if d(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
                d = datenum(datetime(d,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
            end
            dt = seconds(datetime(d(2),"ConvertFrom","datenum")-datetime(d(1),"ConvertFrom","datenum"));
            fprintf('[Resample Data] Resampling data with bin size of %0.3fm (%i depth samples) and %0.3fseconds (%i ping samples)\n',...
                dr*depth_samples,depth_samples,dt*ping_samples, ping_samples);
            dataflag = 'Sv';
            
        elseif strcmp(data.(chan{ch}).type,'ts_pc') || strcmp(data.(chan{ch}).type,'ts_cw')
            data_resampled = data;
            vars = data.(chan{ch}).vars;
            xlog = data.(chan{ch}).val; %using val for now not val2
            xlin = 10.^(xlog/10);
            d = [data.(chan{ch}).vars.timestamp];
            r = repmat(data.(chan{ch}).range,1,size(xlin,2));
            fprintf('[Resample Data] Reading EK80 Data: timestamp format is serial datenum\n');
            dr = r(2)-r(1);
            if d(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
                d = datenum(datetime(d,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
            end
            dt = seconds(datetime(d(2),"ConvertFrom","datenum")-datetime(d(1),"ConvertFrom","datenum"));
            fprintf('[Resample Data] Resampling data with bin size of %0.3fm (%i depth samples) and %0.3fseconds (%i ping samples)\n',...
                dr*depth_samples,depth_samples,dt*ping_samples, ping_samples);
            dataflag = 'TS';
        end
    else
        error('[Resample Data] input data is not from a known format');
    end
    
    %% Calculating near range boundary samples (R(i,j) in Echoview)
    R = zeros(size(r,1)+1,size(r,2)); %size of R(j,i) will always be r(j+1,i)
    for i=1:size(r,2)
        for j=1:size(r,1)
            if j == size(r,1)
                R(j+1,i) = r(j,i);
            else
                R(j+1,i) = (r(j+1,i) + r(j,i))/2;
            end
        end
    end
    
    %R = repmat(R,1,size(xlin,2));
    %% in ping format
    %{
d = 1:length(data.(chan{ch}).time);
D = zeros(size(d,1),size(d,2)+1); %size of R(j,i) will always be r(j+1,i)
D(1,1) = 1;
for j=1:size(d,1)
    for i=1:size(d,2)
        if i == size(d,2)
            D(j,i+1) = d(j,i) + (d(j,i)-D(j,i));
        else
            D(j,i+1) = (d(j,i+1) + d(j,i))/2;
        end
    end
end
    %}
    %% Calculating near boundary distance ping samples (D(i,j) in Echoview)
    %d = data.(chan{ch}).time;
    D = zeros(size(d,1),size(d,2)+1); %size of D(j,i) will always be d(j,i+1)
    D(1,1) = d(1,1);
    for j=1:size(d,1)
        for i=1:size(d,2)
            if i == size(d,2)
                D(j,i+1) = d(j,i) + (d(j,i)-D(j,i));
            else
                D(j,i+1) = (d(j,i+1) + d(j,i))/2;
            end
        end
    end
    lg = sprintf('[Resample Data] Finished calculating boundary of samples in range and pings/time');
    disp(lg)
    %% Mapping from sample to kernel space
    %I_max = (size(xlin,2)-ping_samples)+1; %taken from derobertis! (WRONG!!!)
    I_max = ceil(size(xlin,2)/ping_samples); %total number of windows in the x-direction/pings
    J_max = ceil(size(xlin,1)/depth_samples); %  the number of windows in depth/last window index in y-direction
    
    % Initialize R2 and D2 matrices
    R2 = zeros(J_max, I_max);
    D2 = zeros(1, I_max);
    
    % Update R2 matrix
    %R2(1,:) = r(1,:); %WRONG
    %R2(J_max,:) = r(end,:); %WRONG
    %R2(2:J_max-1,:) = r(idx_j, :); %WRONG
    R2(1,:) = r(1); %different size left (always lower) than right (full data size) except if no resample in ping direction
    R2(J_max,:) = r(end); %different size left (always lower) than right (full data size) in ping direction
    idx_j = 1:depth_samples:size(r,1);
    idx_j = idx_j(2:end-1);
    R2(2:J_max-1,:) = repmat(r(idx_j)',1,I_max);
    
    % Update D2 matrix
    D2(1) = d(1,1); %different size left (always lower) than right (full data size) in ping direction
    D2(I_max) = d(1,end); %different size left (always lower) than right (full data size) in ping direction
    idx_i = 1:ping_samples:size(d,2);
    idx_i = idx_i(2:end-1);
    D2(2:I_max-1) = d(1,idx_i);
    
    lg = sprintf('[Resample Data] Finished calculating boundary of output kernel samples in range and pings/time');
    disp(lg)
    %% Calculating weighted mean for each kernel
    y = zeros(J_max,I_max);
    Xnum_j = zeros(J_max,depth_samples);
    Xnum_i = zeros(ping_samples,I_max);
    tic
    for I=1:I_max
        for J=1:J_max
            if J == 1 %for 1st window in depth
                j_start = 1; j_end = depth_samples;
                
                if I == 1
                    i_start = I; i_end = I+ping_samples-1;
                elseif I == I_max
                    i_start = (I_max-1)*ping_samples+1; i_end = size(xlin,2);
                else
                    i_start = (I-1)*ping_samples+1; i_end = I*ping_samples;
                end
                
                w1 = min(R(j_start+1:j_end+1,i_start:i_end),R2(J+1,I)) - max(R(j_start:j_end,i_start:i_end),R2(J,I));
                if I~=I_max
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I+1)) - max(D(1,i_start:i_end),D2(1,I));
                else
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I)) - max(D(1,i_start:i_end),D2(1,I));
                end
                w = w1.*w2;
                y(J,I) = sum(w.*xlin(j_start:j_end,i_start:i_end),"all","omitnan")/sum(w,"all","omitnan");
                Xnum_j(J,1:(j_end-j_start+1)) = [j_start:j_end];
                Xnum_i(1:(i_end-i_start+1),I) = [i_start:i_end];
            elseif J == J_max %for last window in depth
                j_start = (J_max-1)*depth_samples+1; j_end = size(xlin,1);
                
                if I == 1
                    i_start = I; i_end = I+ping_samples-1;
                elseif I == I_max
                    i_start = (I_max-1)*ping_samples+1; i_end = size(xlin,2);
                else
                    i_start = (I-1)*ping_samples+1; i_end = I*ping_samples;
                end
                
                w1 = min(R(j_start+1:j_end+1,i_start:i_end),R2(J,I)) - max(R(j_start:j_end,i_start:i_end),R2(J,I)); %find out about this (incorrect right now)
                if I~=I_max
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I+1)) - max(D(1,i_start:i_end),D2(1,I));
                else
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I)) - max(D(1,i_start:i_end),D2(1,I));
                end
                w = w1.*w2;
                y(J,I) = sum(w.*xlin(j_start:j_end,i_start:i_end),"all","omitnan")/sum(w,"all","omitnan");
                Xnum_j(J,1:(j_end-j_start+1)) = [j_start:j_end];
                Xnum_i(1:(i_end-i_start+1),I) = [i_start:i_end];
            else %everything else
                j_start = (J-1)*depth_samples+1; j_end = J*depth_samples;
                
                if I == 1
                    i_start = I; i_end = I+ping_samples-1;
                elseif I == I_max
                    i_start = (I_max-1)*ping_samples+1; i_end = size(xlin,2);
                else
                    i_start = (I-1)*ping_samples+1; i_end = I*ping_samples;
                end
                
                w1 = min(R(j_start+1:j_end+1,i_start:i_end),R2(J+1,I)) - max(R(j_start:j_end,i_start:i_end),R2(J,I));
                if I~=I_max
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I+1)) - max(D(1,i_start:i_end),D2(1,I));
                else
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I)) - max(D(1,i_start:i_end),D2(1,I));
                end
                w = w1.*w2;
                y(J,I) = sum(w.*xlin(j_start:j_end,i_start:i_end),"all","omitnan")/sum(w,"all","omitnan");
                Xnum_j(J,1:(j_end-j_start+1)) = [j_start:j_end];
                Xnum_i(1:(i_end-i_start+1),I) = [i_start:i_end];
            end
        end
        if I == floor(I_max/2) || I == I_max
            lg = sprintf('[Resample Data] Applying Weighted Mean: resampled data for ping %d out of %d',I,I_max);
            disp(lg)
        end
    end
    fprintf('[Resample Data] Completed in %0.1f secs \n',toc)
    %% Appending output values into struct
    Xnum_j(Xnum_j == 0) = NaN; %remove index that is 0
    Xnum_i(Xnum_i == 0) = NaN; %remove index that is 0
    y(y==0)=nan; %to remove log10(0) errors
    ylog = 10*log10(y); %Convert back to log
    ylog(imag(ylog) ~= 0) = NaN; %set all imag parts to zero (strange error)
    dr_values = diff(R2(:, 1)); % Calculate dr for all elements in R2
    r_res = zeros(1,size(dr_values,1)+1); % Initialize r_res with the first value
    dr_values(1) = dr_values(1)/2; % Set 1st value
    r_res(1:end-1) = cumsum(dr_values); % Calculate cumulative sum to obtain the final result
    r_res(end) = R2(end,1); % Set final value
    
    if ping_samples ~= 1
        dt_values = diff(D2(1,:));
        t_res = zeros(1,size(dt_values,2)+1);
        dt_values(1) = D2(1,1) + dt_values(1)/2;
        t_res(1:end-1) = cumsum(dt_values);
        t_res(end) = D2(end,1); 
        if t_res(end) < t_res(end-1)
            t_res(end) = D2(end); %Used to work fine before 4/23/2025, but error now where last value is wrong.
        end
    else
        t_res = D2;
    end
    
    %Old slower code but works
    %{
for J = 1:length(r_res)
    if J == 1
        dr = (R2(J+1,1)-R2(J,1))/2;
        r_res(1,J) = dr;
    elseif J == length(r_res)
        %dr = (R2(J+1,1)-R2(J,1))/2;
        r_res(1,J) = R2(end);
    else
        dr = (R2(J+1,1)-R2(J,1));
        r_res(1,J) = r_res(1,J-1)+dr;
    end
end
    %}
    
    %% Vars Data

    if ~strcmp(trans,'EK80')
        if strcmp(dataflag,'Sv')
            data_resampled.(chan{ch}).Sv = ylog;
        elseif strcmp(dataflag,'TS')
            data_resampled.(chan{ch}).TS = ylog;
        end
        data_resampled.(chan{ch}).range = r_res;
        data_resampled.(chan{ch}).time = t_res;
        data_resampled.(chan{ch}).cal = data.(chan{ch}).cal;
        lg = sprintf('[Resample Data] output saved for channel %s',chan{ch});
        disp(lg)
    else %Temporary
        data_resampled.(chan{ch}).range = r_res;
        data_resampled.(chan{ch}).val = ylog;
        data_resampled.(chan{ch}).time = t_res;
    end
    


%% Plot before after if plot_figure = 1
if plot_fig == 1
    %plotEk_Echogram_Niskin(data,channel,ctdpath,eventdn,range,timelength,crange,plt_title,export1)
    plotEk_Echogram_Niskin(data,channel,[],[],{0 'inf'},[],[-77 -36; -74 -35],'Original Data',[])
    plotEk_Echogram_Niskin(data_resampled,ch,[],[],{0 'inf'},[],[-77 -36; -74 -35],'Resampled',[])
end
end
end


