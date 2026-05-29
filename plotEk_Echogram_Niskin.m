% Simple Echogram Plotting EK80/60 data
%% Need to incorporate!!
% (1) Should change the event_dn to accomodate agnostic vector size (not just
% vertical lines but also horizontal lines) (Done with rectangle
% 12/26/2023)
% (2) Add options to add custom title to plot! (Done)
% (3) Add options for channel selection (done by adding new channel
% parameter)
% (4) Need to change datenum to datetime for all codes!
% Dependencies (included in the plot folder): 
% (1) dynamicDateTicks.m and setDateAxes.m: (https://www.mathworks.com/matlabcentral/fileexchange/27075-intelligent-dynamic-date-ticks)
% (2) cptcmap and EK60 colormap from ESP3 (add to path). Tutorial on how to
% change directory of cptcmap: open cptcmap.m and change cptcpath to the
% path where cptcmap.m is. Ensure the colormap 'EK60_2.cpt' is in the same
% directory
%
% INPUT:
% data = EK80/60 data struct (with field names as channels)
% range = EK60 range values cell array {1x2} {min_range max_range} or {min_range 'inf'} to get all range values
% ctdpath = path of the ctd file (global indexer/ctdfile)
% eventdn = event vectors taken from notes
% timelength = time subset vector in datenum
% crange = Sv thresholding limits for n-channels(nx2) [min_crange_ch1 max_crange_ch1 ; min_crange_chN max_crange_chN]
% Rendhy Sapiie 2023

function fig2 = plotEk_Echogram_Niskin(data,channel,ctdpath,eventdn,range,timelength,crange,plt_title,export1)

%disp('Plotting...');

if ~isempty(ctdpath)
    if isstring(ctdpath) || ischar(ctdpath)
        ctd = load(ctdpath);
    else
        ctd = ctdpath;
    end
    if isfield(ctd,'time_utc') %check if this is from staroddi
        if isdatetime(ctd.time_utc)
            ctd_t = datenum(ctd.time_utc);
        else
            ctd_t = ctd.time_utc;
        end
        ctd_d = ctd.pressure;
        plotctd = 1;
    else %from flyer
        disp('[EKPlot] reading global_indexer')
        ctd_t = [ctd.global_indexer.timestamp]';
        if ctd_t > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
            disp('[EKPlot] timestamp of EK80 is in epoch/UNIX milliseconds')
            ctd_t = datenum(datetime(ctd_t,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
        else
            disp('[EKPlot] timestamp of EK80 is in matlab serial time')
        end
        %ctd_t = datenum(datetime(ctd_t,"ConvertFrom","epochtime","TicksPerSecond",1e6)); %convert to datenum
        ctd_d = [ctd.global_indexer.depth]';
        flyerfile = 1;
        plotctd = 1;
    end

else
    plotctd = 0;
    ctd_t = 0;
    ctd_d = 0;
    ctd = 0;
    flyerfile = 0;
end

if ~isempty(eventdn)
    event_dn = eventdn;
    plotevt = 1;
else
    plotevt = 0;
    event_dn = 0;
end

chan = fieldnames(data);

if channel == 1
    lg = sprintf('[EKPlot] Plotting...Reading data from channel 1: %s ',chan{1});
    disp(lg)
    %chan = fieldnames(data);
    chan = chan(1);
elseif channel == 2
    lg = sprintf('[EKPlot] Plotting...Reading data from channel 2: %s ',chan{2});
    disp(lg)
    %chan = fieldnames(data);
    chan = chan(2);
else
    lg = sprintf('[EKPlot] Plotting...Reading data from all %i channels',length(chan));
    disp(lg)
end   

minr = range{1};
maxr = range{2};

if range{2} == 'inf'
    maxr = max([data.(chan{1}).range]);
    disp('[EKPlot] Plotting all ranges')
else
    disp('[EKPlot] Plotting with a range subset')
end

if ~isempty(timelength) %set null to plot all data
    if isdatetime(timelength) 
        mint = datenum(timelength(1));
        maxt = datenum(timelength(2));
        disp('[EKPlot] Plotting with a timesubset: detected datetime input')
    else
        mint = timelength(1);
        maxt = timelength(2);
        disp('[EKPlot] Plotting with a timesubset: detected datenum input')
    end
    TL = 1; %set to 1 if there is an interval
else
    TL = 0;
end

for n=1:length(chan)
    rEK = size(data.(chan{n}).range);
    if (rEK(1) > 1) && (rEK(2) > 1)
        warning('[EKPlot] range data in EK file is not (1xn) or (nx1)')
    elseif rEK(2) ~= 1
        start_ind = dsearchn((data.(chan{n}).range)', minr);
        end_ind = dsearchn((data.(chan{n}).range)', maxr);
    else
    start_ind = dsearchn(data.(chan{n}).range, minr);
    end_ind = dsearchn(data.(chan{n}).range, maxr);
    end
    
    TF = isfield(data.(chan{n}),'time') && ~isfield(data.(chan{n}),'vars'); %to check whether the data is parsed from EK80 or 60, returns 1 if EK/ES60
    if TF == 1 %ES/EK60 data struct
        ping_time_raw = data.(chan{n}).time;
        EK80flag = 0;
        if TL == 1 %if time interval is selected
            if length(ping_time_raw) > 1
                ping_time_raw = ping_time_raw';
            end
            ind_t1 = dsearchn(ping_time_raw, mint);
            ind_t2 = dsearchn(ping_time_raw, maxt);
            ind_ctd1 = dsearchn(ctd_t, mint);
            ind_ctd2 = dsearchn(ctd_t, maxt);
            ping_time = datenum(ping_time_raw(ind_t1:ind_t2));
            if ind_t2 == 1
                disp('[EKPlot] ERROR: Time frame selected is not within bounds')
            end
            if isfield(data.(chan{n}),'Sv')
                ping_data = data.(chan{n}).Sv(start_ind:end_ind,ind_t1:ind_t2);
            elseif isfield(data.(chan{n}),'TS')
                ping_data = data.(chan{n}).TS(start_ind:end_ind,ind_t1:ind_t2);
            end

        else %no time interval/all data is plotted
            ping_time = datenum(ping_time_raw);
            if isfield(data.(chan{n}),'Sv')
                ping_data = data.(chan{n}).Sv(start_ind:end_ind,:);
            elseif isfield(data.(chan{n}),'TS')
                ping_data = data.(chan{n}).TS(start_ind:end_ind,:);
            end
            ind_ctd1 = 1;
            ind_ctd2 = length(ctd_t);
        end
        
        for i = 1:length(ping_time)
            if ping_time(i) < ping_time(1)
                ping_time(i) = ping_time(i-1);
            end
        end
        
        ping_dt = datetime(ping_time,'ConvertFrom','datenum');
        %ping_data = data.(chan{n}).Sv(start_ind:end_ind,:);
        ping_range = data.(chan{n}).range(start_ind:end_ind);
        dstr = " ES/EK60 "; dstr2 = strcat(sprintf('%s_%s_',string(ping_dt(1),'MMddyy'),string(ping_dt(1),'HHmmss')),"ES60");
    else %EK80 data struct
        plotctd = 0;
        EK80flag = 1;
        if strcmp(data.(chan{n}).type,'PhysAng_alongship') || strcmp(data.(chan{n}).type,'PhysAng_athwartship')
            angleflag = 1;
        end

        if isfield(data.(chan{n}),'val2') == 1 %if this is reshaped ek80 data
            if isfield(data.(chan{n}).vars2,'timestamp') == 1 %EK80 with CTD timesync
                ping_time_raw = [data.(chan{n}).vars2.timestamp];
                if ping_time_raw > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
                    disp('[EKPlot] timestamp of EK80 is in epoch/UNIX milliseconds')
                    ping_time_raw = datenum(datetime(ping_time_raw,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
                else
                    disp('[EKPlot] timestamp of EK80 is in serial time')
                end
                if TL == 1 %EK80 with CTD timesync and time frame proccessed
                    
                    if length(ping_time_raw) > 1
                        ping_time_raw = ping_time_raw';
                    end
                    
                    ind_t1 = dsearchn(ping_time_raw, mint);
                    ind_t2 = dsearchn(ping_time_raw, maxt);
                    ping_time = datenum(ping_time_raw(ind_t1:ind_t2));
                    if ind_t2 == 1
                        disp('[EKPlot] ERROR: Time frame selected is not within bounds')
                    end
                    ping_range = data.(chan{n}).range(start_ind:end_ind);
                    ping_data = data.(chan{n}).val2(start_ind:end_ind,ind_t1:ind_t2);
                else %EK80 with CTD timesync and no time frame/all pings proccessed
                    ping_time = datenum(ping_time_raw);
                    %ping_data = data.(chan{n}).Sv(start_ind:end_ind,:);
                    ping_data = data.(chan{n}).val2(start_ind:end_ind,:);
                    ping_range = data.(chan{n}).range(start_ind:end_ind);
                end
                ping_dt = datetime(ping_time,'ConvertFrom','datenum');
                %ping_data = data.(chan{n}).val(start_ind:end_ind,:);
                %ping_range = data.(chan{n}).range(start_ind:end_ind);
                dstr = " EK80 "; dstr2 = strcat(sprintf('%s_%s_',string(ping_dt(1),'MMddyy'),string(ping_dt(1),'HHmmss')),"EK80");
            else %EK80 without CTD timesync
                ping_time_raw = [data.(chan{n}).vars2.timestamp_raw]; %Option without CTD
                if ping_time_raw > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
                    disp('[EKPlot] timestamp of EK80 is in epoch/UNIX milliseconds')
                    ping_time_raw = datenum(datetime(ping_time_raw,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
                else
                    disp('[EKPlot] timestamp of EK80 is in serial time')
                end
                if TL == 1 %EK80 without CTD timesync and time frame proccessed
                    if length(ping_time_raw) > 1
                        ping_time_raw = ping_time_raw';
                    end
                    ind_t1 = dsearchn(ping_time_raw, mint);
                    ind_t2 = dsearchn(ping_time_raw, maxt);
                    ping_time = datenum(ping_time_raw(ind_t1:ind_t2));
                    if ind_t2 == 1
                        disp('[EKPlot] ERROR: Time frame selected is not within bounds')
                    end
                    ping_range = data.(chan{n}).range(start_ind:end_ind);
                    ping_data = data.(chan{n}).val2(start_ind:end_ind,ind_t1:ind_t2);
                else %EK80 without CTD timesync and no time frame/all pings proccessed
                    ping_time = datenum(ping_time_raw);
                    %ping_data = data.(chan{n}).Sv(start_ind:end_ind,:);
                    ping_data = data.(chan{n}).val2(start_ind:end_ind,:);
                    ping_range = data.(chan{n}).range(start_ind:end_ind);
                end
                ping_dt = datetime(ping_time,'ConvertFrom','datenum');
                %ping_data = data.(chan{n}).val(start_ind:end_ind,:);
                %ping_range = data.(chan{n}).range(start_ind:end_ind);
                dstr = " EK80 "; dstr2 = strcat(sprintf('%s_%s_',string(ping_dt(1),'MMddyy'),string(ping_dt(1),'HHmmss')),"EK80");
            end
        else
            %EK80 original data size
            if isfield(data.(chan{n}).vars,'timestamp') == 1 %EK80 with CTD timesync
                ping_time_raw = [data.(chan{n}).vars.timestamp];
                if ping_time_raw > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
                    disp('[EKPlot] timestamp of EK80 is in epoch/UNIX milliseconds')
                    ping_time_raw = datenum(datetime(ping_time_raw,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
                else
                    disp('[EKPlot] timestamp of EK80 is in serial time')
                end
                if TL == 1 %EK80 with CTD timesync and time frame proccessed
                    
                    if length(ping_time_raw) > 1
                        ping_time_raw = ping_time_raw';
                    end
                    
                    ind_t1 = dsearchn(ping_time_raw, mint);
                    ind_t2 = dsearchn(ping_time_raw, maxt);
                    ping_time = datenum(ping_time_raw(ind_t1:ind_t2));
                    if ind_t2 == 1
                        disp('[EKPlot] ERROR: Time frame selected is not within bounds')
                    end
                    ping_range = data.(chan{n}).range(start_ind:end_ind);
                    ping_data = data.(chan{n}).val(start_ind:end_ind,ind_t1:ind_t2);
                else %EK80 with CTD timesync and no time frame/all pings proccessed
                    ping_time = datenum(ping_time_raw);
                    %ping_data = data.(chan{n}).Sv(start_ind:end_ind,:);
                    ping_data = data.(chan{n}).val(start_ind:end_ind,:);
                    ping_range = data.(chan{n}).range(start_ind:end_ind);
                end
                ping_dt = datetime(ping_time,'ConvertFrom','datenum');
                %ping_data = data.(chan{n}).val(start_ind:end_ind,:);
                %ping_range = data.(chan{n}).range(start_ind:end_ind);
                dstr = " EK80 "; dstr2 = strcat(sprintf('%s_%s_',string(ping_dt(1),'MMddyy'),string(ping_dt(1),'HHmmss')),"EK80");
            else %EK80 without CTD timesync
                ping_time_raw = [data.(chan{n}).vars.timestamp_raw]; %Option without CTD
                if ping_time_raw > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
                    disp('[EKPlot] timestamp of EK80 is in epoch/UNIX milliseconds')
                    ping_time_raw = datenum(datetime(ping_time_raw,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
                else
                    disp('[EKPlot] timestamp of EK80 is in serial time')
                end
                if TL == 1 %EK80 without CTD timesync and time frame proccessed
                    if length(ping_time_raw) > 1
                        ping_time_raw = ping_time_raw';
                    end
                    ind_t1 = dsearchn(ping_time_raw, mint);
                    ind_t2 = dsearchn(ping_time_raw, maxt);
                    ping_time = datenum(ping_time_raw(ind_t1:ind_t2));
                    if ind_t2 == 1
                        disp('[EKPlot] ERROR: Time frame selected is not within bounds')
                    end
                    ping_range = data.(chan{n}).range(start_ind:end_ind);
                    ping_data = data.(chan{n}).val(start_ind:end_ind,ind_t1:ind_t2);
                else %EK80 without CTD timesync and no time frame/all pings proccessed
                    ping_time = datenum(ping_time_raw);
                    %ping_data = data.(chan{n}).Sv(start_ind:end_ind,:);
                    ping_data = data.(chan{n}).val(start_ind:end_ind,:);
                    ping_range = data.(chan{n}).range(start_ind:end_ind);
                end
                ping_dt = datetime(ping_time,'ConvertFrom','datenum');
                %ping_data = data.(chan{n}).val(start_ind:end_ind,:);
                %ping_range = data.(chan{n}).range(start_ind:end_ind);
                dstr = " EK80 "; dstr2 = strcat(sprintf('%s_%s_',string(ping_dt(1),'MMddyy'),string(ping_dt(1),'HHmmss')),"EK80");
            end
        end
    end
    
    %% Flyer specific
    if EK80flag == 1 && flyerfile == 1
        ping_time2_idx_s = dsearchn(ctd_t,ping_time(1));
        ping_time2_idx_f = dsearchn(ctd_t,ping_time(end));
        timevec = ctd_t(ping_time2_idx_s:ping_time2_idx_f);
        ping_time_idx = dsearchn(timevec,ping_time');
        ping_data2 = NaN(length(ping_range),length(timevec));
        ping_data2(:,ping_time_idx) = ping_data;
        ping_time = timevec;
        ping_data = ping_data2;
        clear ctd timevec ping_data2
    end

    %% Angles

    if exist("angleflag")
        maxAng = max(ping_data,[],"all");
        minAng = min(ping_data,[],"all");
        crange(n,1) = ceil(minAng); 
        crange(n,2) = floor(maxAng);
        fprintf('[EKPlot] Angle data detected, plotting scale: %d to %d \n',crange(n,1),crange(n,2));
    end
    %% Start of Figure
    %ping_time2 = datetime(ping_time,'ConvertFrom','datenum');

    dtitle = string(ping_dt(1))+dstr;
    fig2 = figure(); set(fig2,'visible','on','PaperPositionMode','auto','PaperPosition',[0 0 20 10]);
    imagesc(ping_time, ping_range, ping_data, [crange(n,1) crange(n,2)]);
    %imagesc(timevec, ping_range, ping_data2, [crange(n,1) crange(n,2)]);
    if ~exist("angleflag")
        cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
    else
        colormap(redblue)
    end
    axis tight; shading flat;
    xticks('auto');yticks('auto');colorbar;
    dynamicDateTicks();
    setDateAxes(gca, 'XLim', [ping_time(1) max(ping_time)]);
    %title(['Dive',num2str(dive),' ES60 channel ',num2str(nchan(n)),'kHz'],'fontsize',20);
    %title(['7-8-21 Bermuda',' ES60',string(chan{n}),' kHz'],'fontsize',20);
    if exist('plt_title','var') == 1 && (isstring(plt_title)||ischar(plt_title)||iscellstr(plt_title))
        title(plt_title,'Interpreter','none')
    else
        title(dtitle+sprintf("%s kHz", chan{n}),'Interpreter','none')
    end
    xlabel('Time','fontsize',20);
    if ~strcmp(dstr, " EK80 ")
        ylabel('Depth (m)','fontsize',20);
    else
        ylabel('Horizontal Distance (m)','fontsize',20);
    end
    set(gca,'FontSize',20);
    if plotctd == 1
        hold on
        plot(ctd_t(ind_ctd1:ind_ctd2),ctd_d(ind_ctd1:ind_ctd2),'k','LineWidth',2)
        hold off
    end

    if plotevt == 1
        hold on
        if size(event_dn,2)<2
            if any(event_dn>700000)
                ln = 'over_range';
                disp('[EKPlot] Detected time event')
            elseif any(0<event_dn) && any(event_dn<10000)
                ln = 'over_time';
                disp('[EKPlot] Detected range event')
            end

            if strcmp(ln,'over_range') % continuous line over range
                for i = 1:length(event_dn)
                    plot([event_dn(i) event_dn(i)],[0 maxr],'--k','LineWidth',2)
                end
            elseif strcmp(ln,'over_time')
                for i = 1:length(event_dn)
                    plot([ping_time_raw(1) ping_time_raw(end)],[event_dn(i) event_dn(i)],'--k','LineWidth',2)
                end
            end
        elseif size(event_dn,2) == 2 % Draw a box
            rectangle('Position',[event_dn(1,1) event_dn(1,2) (event_dn(2,1)-event_dn(1,1)) (event_dn(2,2)-event_dn(1,2))],'LineWidth',2) %t1,rend,tend,rstart
        else %data not recognized
            error('[EKPlot] Event data is not known format')
        end
        hold off
    end

    if export1 == 1
        % Exporting
        fig2.WindowState = 'maximized';
        %set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
        %set(gcf, 'Toolbar', 'none', 'Menu', 'none');
        export_fig(strcat(dstr2+sprintf("%skHz.bmp", chan{n})));
        disp(sprintf('exporting plot: %s; to: %s',strcat(dstr2+sprintf("%skHz.bmp", chan{n})),pwd))
    end

end

end