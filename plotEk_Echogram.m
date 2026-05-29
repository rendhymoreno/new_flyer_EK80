% Simple Echogram Plotting EK80/60 data
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
% crange = Sv thresholding limits for n-channels(nx2) [min_crange_ch1 max_crange_ch1 ; min_crange_chN max_crange_chN]
% Rendhy Sapiie 2023

function plotEk_Echogram(data,range,timelength,crange)

disp('Plotting...');
chan = fieldnames(data);
minr = range{1};
maxr = range{2};
if range{2} == 'inf'
    maxr = max([data.(chan{1}).range]);
end

if ~isempty(timelength) %set null to plot all data
    t = datetime(timelength,'InputFormat','MM-dd-yyyy HH:mm:ss');
    mint = datenum(t(1));
    maxt = datenum(t(2));
    TL = 1; %set to 1 if there is an interval
else
    TL = 0;
end

for n=1:length(chan)
    rEK = size(data.(chan{n}).range);
    if (rEK(1) > 1) && (rEK(2) > 1)
        warning('range data in EK file is not (1xn) or (nx1)')
    elseif rEK(2) ~= 1
        start_ind = dsearchn((data.(chan{n}).range)', minr);
        end_ind = dsearchn((data.(chan{n}).range)', maxr);
    else
    start_ind = dsearchn(data.(chan{n}).range, minr);
    end_ind = dsearchn(data.(chan{n}).range, maxr);
    end
    
    TF = isfield(data.(chan{n}),'time'); %to check whether the data is parsed from EK80 or 60, returns 1 if EK/ES60
    if TF == 1 %ES/EK60 data struct
        ping_time_raw = data.(chan{n}).time;
        
        if TL == 1
            if length(ping_time_raw) > 1
            ping_time_raw = ping_time_raw';
            end
            ind_t1 = dsearchn(ping_time_raw, mint);
            ind_t2 = dsearchn(ping_time_raw, maxt);
            ping_time = datenum(ping_time_raw(ind_t1:ind_t2));
            if ind_t2 == 1
                disp('ERROR: Time frame selected is not within bounds')
            end
            ping_data = data.(chan{n}).Sv(start_ind:end_ind,ind_t1:ind_t2);           
        else
            ping_time = datenum(ping_time_raw);
            ping_data = data.(chan{n}).Sv(start_ind:end_ind,:);
        end
        
        for i = 1:length(ping_time)
            if ping_time(i) < ping_time(1)
                ping_time(i) = ping_time(i-1);
            end
        end
        
        ping_dt = datetime(ping_time,'ConvertFrom','datenum');
        %ping_data = data.(chan{n}).Sv(start_ind:end_ind,:);
        ping_range = data.(chan{n}).range(start_ind:end_ind);
        dstr = " ES/EK60 ";
    else %EK80 data struct
        if isfield(data.(chan{n}).vars,'timestamp') == 1 %EK80 with CTD timesync
        ping_time_raw = [data.(chan{n}).vars.timestamp];
           if TL == 1 %EK80 with CTD timesync and time frame proccessed
               
            if length(ping_time_raw) > 1
            ping_time_raw = ping_time_raw';
            end   
            
            ind_t1 = dsearchn(ping_time_raw, mint);
            ind_t2 = dsearchn(ping_time_raw, maxt);
            ping_time = datenum(ping_time_raw(ind_t1:ind_t2));
            if ind_t2 == 1
                disp('ERROR: Time frame selected is not within bounds')
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
        dstr = " EK80 ";
        else %EK80 without CTD timesync
            ping_time_raw = [data.(chan{n}).vars.timestamp_raw]; %Option without CTD
            if TL == 1 %EK80 without CTD timesync and time frame proccessed
                if length(ping_time_raw) > 1
                 ping_time_raw = ping_time_raw';
                end
                ind_t1 = dsearchn(ping_time_raw, mint);
                ind_t2 = dsearchn(ping_time_raw, maxt);
                ping_time = datenum(ping_time_raw(ind_t1:ind_t2));
                if ind_t2 == 1
                disp('ERROR: Time frame selected is not within bounds')
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
            dstr = " EK80 ";
        end
    end
    
    dtitle = datestr(ping_dt(1))+dstr;
    fig2 = figure(); set(fig2,'visible','on','PaperPositionMode','auto','PaperPosition',[0 0 20 10]);
    imagesc(ping_time, ping_range, ...
        ping_data, [crange(n,1) crange(n,2)]); cptcmap('EK60_2.cpt'); axis tight; shading flat; 
        xticks('auto');yticks('auto');colorbar; 
        dynamicDateTicks(); 
        setDateAxes(gca, 'XLim', [ping_time(1) max(ping_time)]);
        %title(['Dive',num2str(dive),' ES60 channel ',num2str(nchan(n)),'kHz'],'fontsize',20);
        %title(['7-8-21 Bermuda',' ES60',string(chan{n}),' kHz'],'fontsize',20);
        title(dtitle+sprintf("%s kHz", chan{n}),'Interpreter','none')
        xlabel('Time','fontsize',20); ylabel('Depth (m)','fontsize',20);
        set(gca,'FontSize',20);
        

end

end