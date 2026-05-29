% Plotting EK/ES60 data with ROV path overlay
% Dependencies: 
% (1) dynamicDateTicks.m and setDateAxes.m: (https://www.mathworks.com/matlabcentral/fileexchange/27075-intelligent-dynamic-date-ticks)
% (2) cptcmap and EK60 colormap from ESP3 (add to path). Tutorial on how to
% change directory of cptcmap: open cptcmap.m and change cptcpath to the
% path where cptcmap.m is. Ensure the colormap 'EK60_2.cpt' is in the same
% directory
%
% INPUT:
% data = ES60 data struct (with field names as channels)
% rovpath = string ''; directory to synced EK80-ROV CTD global_index.mat
% range = EK60 range values cell array {1x2} {min_range max_range} or {min_range 'inf'} to get all range values
% crange = Sv thresholding limits for n-channels(nx2) [min_crange_ch1 max_crange_ch1 ; min_crange_chN max_crange_chN]
% Rendhy Sapiie 2023

function plotES60_ROV_Echogram(data,rovpath,range,crange)

disp('Plotting...');
chan = fieldnames(data);
minr = range{1};
maxr = range{2};
if range{2} == 'inf'
    maxr = max([data.(chan{1}).range]);
end

rov = load(rovpath);
rovt_utc = [rov.global_indexer.timestamp];
rovd = [rov.global_indexer.depth];


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
    
    start_ind = dsearchn((data.(chan{n}).range)', minr);
    end_ind = dsearchn((data.(chan{n}).range)', maxr);
    ping_time_raw = data.(chan{n}).time;
    ping_time = datenum(ping_time_raw);
    ping_dt = datetime(ping_time,'ConvertFrom','datenum');
    ping_data = data.(chan{n}).Sv(start_ind:end_ind,:);
    ping_range = data.(chan{n}).range(start_ind:end_ind);
    
    fig2 = figure(); set(fig2,'visible','on','PaperPositionMode','auto','PaperPosition',[0 0 20 10]);
    imagesc(ping_time, ping_range, ...
        ping_data, [crange(n,1) crange(n,2)]); cptcmap('EK60_2.cpt'); axis tight; shading flat; 
        xticks('auto');yticks('auto');colorbar; dynamicDateTicks();
        setDateAxes(gca, 'XLim', [ping_time(1) ping_time(end)]);
        %title(['Dive',num2str(dive),' ES60 channel ',num2str(nchan(n)),'kHz'],'fontsize',20);
        %title(['7-8-21 Bermuda',' ES60',string(chan{n}),' kHz'],'fontsize',20);
        title(sprintf("ES60 %s kHz", chan{n}),'Interpreter','none')
        xlabel('Time','fontsize',20); ylabel('Depth (m)','fontsize',20);
        set(gca,'FontSize',20);
        
    hold on;  
    plot(rovt_utc,rovd,'k','LineWidth',1.5);  %ROV track

end

end