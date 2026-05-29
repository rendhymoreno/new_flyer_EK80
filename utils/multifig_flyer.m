function fig = multifig_flyer(datain, angle, cast_plot, crange, depth_interval)

cast_list = fieldnames(datain);
if ismember(cast_list,"C1")
    for k=1:length(cast_list)
        cast_num(k) = str2double(cast_list{k}(2:end));
    end
%else
    %cast_num = 
end

chan_data = string(fieldnames(datain.(cast_list{1})));
chan_ang = string(fieldnames(angle));

if ismember(chan_data,chan_ang)
    chan_id = find(chan_ang == chan_data);
else
    error('Channel between data and angle is not consistent!')
end

cast_plt_idx = ~ismember(cast_num,cast_plot);
cast_plot2 = cast_list(cast_plt_idx);
data_plt = rmfield(datain,cast_plot2);
data_plt = flyer_combine_casts(data_plt);

time = datenum(datetime([angle.(chan_data{chan_id}).vars.timestamp],"ConvertFrom","epochtime","TicksPerSecond",1e6));
range = [angle.((chan_data{chan_id})).range];
vars = [angle.((chan_data{chan_id})).vars];
ang_val = [angle.((chan_data{chan_id})).val];
depth = [vars.depth];

if ~isfield(vars,'cast_new')
    [angle,~,~] = flyer_cast_idx(angle, 1);
    vars = [angle.((chan_data{chan_id})).vars];
end

%% Check for angle data if its correct
if ~strcmp(angle.(chan_ang{1}).type,'PhysAng_alongship') && ~strcmp(angle.(chan_ang{1}).type,'PhysAng_athwartship')
    error('Angle data is not detected as an input')
else
    angleflag = 1;
end

%% Parse angle cast and depth data
c_idx = ismember([vars.cast_new],cast_plot);
ang_plot = ang_val(:,c_idx);
ang_t = time(c_idx);
dep_plot = depth(c_idx);
val = data_plt.(chan_data{1}).val;

if ~isempty(depth_interval)
    c_idx_2 = dep_plot > depth_interval(1) & dep_plot < depth_interval(2);
    %c_idx = c_idx & c_idx_2; %intersect between depth and cast
    ang_plot = ang_plot(:,c_idx_2);
    ang_t = ang_t(c_idx_2);
    dep_plot = dep_plot(c_idx_2);
    val = val(:,c_idx_2);
end

%% Figure

if exist("angleflag")
        maxAng = max(ang_plot,[],"all");
        minAng = min(ang_plot,[],"all");
        crange_ang(1) = ceil(minAng); 
        crange_ang(2) = floor(maxAng);
        fprintf('[EKPlot] Angle data detected, plotting scale: %d to %d \n',crange_ang(1),crange_ang(2));
end

%% Start of Figure
%ping_time2 = datetime(ping_time,'ConvertFrom','datenum');

%dtitle = string(ping_dt(1))+dstr;
fig = figure()
tiledlayout(4,1,"TileSpacing","tight");

%crange = [-100 -70];
ax1 = nexttile;
%imagesc(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"), range, val, [crange(1) crange(2)]);
a1 = pcolor(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"), range, val);
set(a1,'EdgeColor','none');
caxis([crange(1) crange(2)]);
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; %ax1.Colormap = cmap;
colormap(ax1,cmap);
set(gca,'YDir','reverse');
axis tight;
ylim([0 100]);
set(gca,'Xtick',[],'FontSize',16,'LineWidth',1);
%cb1 = colorbar(ax1);
colorbar;

ax2 = nexttile;
%imagesc(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"), range, ang_plot, [crange_ang(1) crange_ang(2)]);
a2 = pcolor(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"), range, ang_plot);
caxis([crange_ang(1) crange_ang(2)]);
set(a2,'EdgeColor','none');
%ax2.Colormap = redblue;
colormap(ax2,redblue);
set(gca,'YDir','reverse');
axis tight;
ylim([0 100]);
set(gca,'Xtick',[],'FontSize',16,'LineWidth',1);
%cb2 = colorbar(ax2); 
colorbar;

ax3 = nexttile;
plot(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"),dep_plot,'Marker','.','MarkerSize',5,'Color',"black");
%plot(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"),dep_plot,'LineWidth',2,'Color',"black");
set(gca,'YDir','reverse');
axis tight;
%xticks('auto');yticks('auto');
%xlabel('Time','fontsize',20);
set(gca,'Xtick',[],'FontSize',16,'LineWidth',1);
%set(gca,'FontSize',16);

ax4 = nexttile;
%this is angle over fixed depth
%plot(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"),ang_plot(7357,1:end),'Marker','.','MarkerSize',5,'Color',"black");
%this is mean angle over ping
ang_avg = mean(ang_plot,1);
plot(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"),ang_avg,'LineWidth',2,'Color',"black");
%set(gca,'YDir','reverse');
axis tight;
%xticks('auto');yticks('auto');
xlabel('Time','fontsize',20);
set(gca,'FontSize',16);

linkaxes([ax1,ax2,ax3,ax4],'x');
linkaxes([ax1,ax2],'y');

% this is the large impulse noise
figure()
tiledlayout(5,1,"TileSpacing","tight");
nexttile
hist(ang_val(:,165)) % 04:58:21.653
nexttile
hist(ang_val(:,166)) % 04:58:20.787
nexttile
hist(ang_val(:,167)) % 04:58:22.516
nexttile
hist(ang_val(:,168)) % close to the surface
nexttile
hist(ang_val(:,169)) % value that seems normal

%Smaller impulse noise

tiledlayout(4,1,"TileSpacing","tight");
nexttile
hist(ang_val(:,117)) % 04:58:21.653
nexttile
hist(ang_val(:,118)) % 04:58:20.787
nexttile
hist(ang_val(:,119)) % 04:58:22.516
nexttile
hist(ang_val(:,181)) % close to the surface

%gradient of avg angle
grad = diff(ang_avg);
grad = [NaN grad];
tiledlayout(3,1,"TileSpacing","tight");

ax5 = nexttile
a4 = pcolor(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"), range, ang_plot);
caxis([crange_ang(1) crange_ang(2)]);
set(a4,'EdgeColor','none');
%ax2.Colormap = redblue;
colormap(ax5,redblue);
set(gca,'YDir','reverse');
axis tight;
ylim([0 100]);
set(gca,'Xtick',[],'FontSize',16,'LineWidth',1);
%cb2 = colorbar(ax2); 
colorbar;

nexttile
plot(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"),ang_avg,'LineWidth',2,'Color',"black");
axis tight;
set(gca,'Xtick',[],'FontSize',16,'LineWidth',1);

nexttile
plot(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"),-(ang_avg),'LineWidth',2,'Color',"black");
findpeaks(-(ang_avg),ang_t_dt,'MinPeakProminence',0.5,'Annotate','extents')
axis tight;
%xticks('auto');yticks('auto');
xlabel('Time','fontsize',20);
set(gca,'FontSize',16);

ang_t_dt = datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS");
%ts = duration(diff(ang_t_dt),"Format","ss.SSS");
t_fft = seconds(ang_t_dt - repmat(ang_t_dt(1),1,length(ang_t_dt)));
ts = seconds(diff(ang_t_dt));
tstats = [mean(ts) std(ts)];

% Y = nufft(ang_avg,t_fft);
% n = length(t_fft);
% f = (0:n-1)/n;
% figure()
% plot(f,abs(Y));

% This is the large and wide impulse difference
seconds(datetime('04:56:57.510',"Format","HH:mm:ss.SSS")-datetime('04:57:38.629',"Format","HH:mm:ss.SSS"));
seconds(datetime('04:57:38.629',"Format","HH:mm:ss.SSS")-datetime('04:58:21.653',"Format","HH:mm:ss.SSS"));
% This is the small impulse difference
seconds(datetime('04:57:22.693',"Format","HH:mm:ss.SSS")-datetime('04:58:04.627',"Format","HH:mm:ss.SSS"));
seconds(datetime('04:58:04.627',"Format","HH:mm:ss.SSS")-datetime('04:58:46.692',"Format","HH:mm:ss.SSS"));


end
