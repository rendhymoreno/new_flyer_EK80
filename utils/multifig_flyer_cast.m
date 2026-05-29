function multifig_flyer_cast(datain, algin, athin, crange, rrange,depth_interval)

chan_data = fieldnames(datain);
chan_alg = fieldnames(algin);
chan_ath = fieldnames(athin);

if ~ismember(chan_data,chan_alg) && ~ismember(chan_data,chan_ath)
    error('Channel between data and angle is not consistent!')
else
    chan_id = find(ismember(chan_data,chan_alg) == 1);
end

% Parameterization
time = datetime([datain.(chan_data{chan_id}).vars.timestamp],"ConvertFrom","epochtime","TicksPerSecond",1e6);
range = [datain.((chan_data{chan_id})).range];
vars = [datain.((chan_data{chan_id})).vars];
alg_val = [algin.((chan_data{chan_id})).val];
ath_val = [athin.((chan_data{chan_id})).val];
sv_val = [datain.((chan_data{chan_id})).val];
depth = [vars.depth];
type = [datain.((chan_data{chan_id})).type];

if ~isempty(depth_interval)
    dep_idx = depth > depth_interval(1) & depth < depth_interval(2);
    alg_val = alg_val(:,dep_idx);
    ath_val = ath_val(:,dep_idx);
    depth = depth(dep_idx);
    sv_val = sv_val(:,dep_idx);
end

% Plotting

% plotting ranges
maxAng = max([max(alg_val,[],"all") max(ath_val,[],"all")]);
minAng = min([min(alg_val,[],"all") min(ath_val,[],"all")]);
crange_ang(1) = ceil(minAng);
crange_ang(2) = floor(maxAng);

if isempty(crange)
    crange = [-80 -40];
end

if isempty(rrange)
    rrange = [0 100];
end

f1 = figure();
t1 = tiledlayout(4,1,"TileSpacing","tight");
plttl = sprintf('Flyer profile dive time: %s, Cast %d',string(time(1)),unique([vars.cast_new]));
%title(t1,plttl);
t1.Title.String = plttl;
t1.Title.FontSize = 16;

ax1 = nexttile;
%imagesc(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"), range, val, [crange(1) crange(2)]);
a1 = pcolor(time, range, sv_val);
set(a1,'EdgeColor','none');
clim(ax1,[crange(1) crange(2)]);
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; %ax1.Colormap = cmap;
colormap(ax1,cmap);
set(ax1,'YDir','reverse');
axis tight;
ylim(ax1,[rrange(1) rrange(2)]);
ylabel(ax1,'Range (m)','fontsize',16);
set(ax1,'Xtick',[],'FontSize',16,'LineWidth',1);
cb1 = colorbar(ax1);
if strcmp(type,'sv_pc')
    cb1.Label.String = 'Sv dB ref 1m^3 at 70kHz';
elseif strcmp(type,'ts_pc')
    cb1.Label.String = 'TS dB ref 1m^2 at 70kHz';
end
cb1.Label.FontSize = 10;
cb1.Label.FontWeight = 'bold';
%title(ax1,'sv 70kHz');
%colorbar;

ax2 = nexttile;
%imagesc(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"), range, ang_plot, [crange_ang(1) crange_ang(2)]);
a2 = pcolor(time, range, alg_val);
clim(ax2,[crange_ang(1) crange_ang(2)]);
set(a2,'EdgeColor','none');
%ax2.Colormap = redblue;
colormap(ax2,redblue);
set(ax2,'YDir','reverse');
axis tight;
ylim(ax2,[rrange(1) rrange(2)]);
ylabel(ax2,'Range (m)','fontsize',16);
set(ax2,'Xtick',[],'FontSize',16,'LineWidth',1);
cb2 = colorbar(ax2); 
cb2.Label.String = 'Alongship Angle (deg)';
cb2.Label.FontSize = 10;
cb2.Label.FontWeight = 'bold';

%colorbar;

ax3 = nexttile;
%imagesc(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"), range, ang_plot, [crange_ang(1) crange_ang(2)]);
a3 = pcolor(time, range, ath_val);
clim(ax3,[crange_ang(1) crange_ang(2)]);
set(a3,'EdgeColor','none');
colormap(ax3,redblue);
set(ax3,'YDir','reverse');
axis tight;
ylim(ax3,[rrange(1) rrange(2)]);
ylabel(ax3,'Range (m)','fontsize',16);
set(ax3,'Xtick',[],'FontSize',16,'LineWidth',1);
cb3 = colorbar(ax3); 
cb3.Label.String = 'Athwartship Angle (deg)';
cb3.Label.FontSize = 10;
cb3.Label.FontWeight = 'bold';

ax4 = nexttile;
plot(time,depth,'Marker','.','MarkerSize',5,'Color',"black");
%plot(datetime(ang_t,"ConvertFrom","datenum","Format","HH:mm:ss.SSS"),dep_plot,'LineWidth',2,'Color',"black");
set(ax4,'YDir','reverse');
axis tight;
set(ax4,'FontSize',16,'LineWidth',1);
xlabel('Time (UTC)','fontsize',20);
ylabel('Depth (m)','fontsize',16);
lgd = legend(ax4,'Wire Flyer Position');
lgd.Location = 'southeast';

linkaxes([ax1,ax2,ax3,ax4],'x');
linkaxes([ax1,ax2,ax3],'y');

end