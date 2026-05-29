load('E:\2023_Bermuda\processed\vect_ek80_38.mat');
load('E:\2023_Bermuda\processed\vect_es60_38.mat');

export_pointcloud(vect_ek80_38, 'E:\2023_Bermuda\processed\','ek80_38k');
export_pointcloud(vect_es60_38, 'E:\2023_Bermuda\processed\','es60_38k');

%% Pointcloud plot
ps1 = pcread('E:\2023_Bermuda\processed\ek80_38k.ply');
ps2 = pcread('E:\2023_Bermuda\processed\es60_38k.ply');
%ps1.Intensity = ps1.Intensity-3;
%%

fig2u3d(gca,'berak', '-pdf')
%%

f = figure();
ax1 = axes;
ax1 = pcshow(ps2); 
%colorbar; 
caxis([-77 -36]); 
zlim([0 300])
ylim([0 100])
%cptcmap('EK60_2');
set(ax1,'XDir','reverse','ZDir','reverse'); 
xlabel(ax1,'ping number','FontSize',14); ylabel(ax1,'EK80 range (m)','FontSize',14); zlabel(ax1,'sled depth (m)','FontSize',14); 
ax1.DataAspectRatio = [0.5*diff(ax1.XLim), diff(ax1.YLim), diff(ax1.ZLim)] / diff(ax1.YLim);
ax1.FontSize = 14;

hold on
ax2 = axes;
ax2 = pcshow(ps1);  
set(ax2,'XDir','reverse','ZDir','reverse'); 
%cptcmap('EK60_2');
zlim([0 300])
%ylim([0 100])
caxis([-85 -65]);
ax2.DataAspectRatio = [0.5*diff(ax2.XLim), diff(ax2.YLim), diff(ax2.ZLim)] / diff(ax2.YLim);
%ax2.DataAspectRatio = [diff(ax2.XLim), diff(ax2.YLim), diff(ax2.ZLim)] / diff(ax2.YLim);


%hlink = linkprop([ax1, ax2], {'CameraUpVector','CameraPosition','CameraTarget'});
hlink = linkprop([ax1, ax2], {'XLim','ZLim','Position','view'});

ax2.Visible = 'off';
ax2.XTick = [];
ax2.YTick = [];

view(150,20)

cptcmap('EK500',ax1)
cptcmap('EK60_2',ax2')

cb1 = colorbar(ax1,'Position',[0.05 0.1 0.03 0.815]); 
cb2 = colorbar(ax2,'Position',[0.84 0.1 0.03 0.815]);
cb2.Label.String = 'EK80 Sv (dB ref 1m^-1)';
cb1.Label.String = 'ES60 Sv (dB ref 1m^-1)';
cb1.FontSize = 16;
cb2.FontSize = 16;
cb1.Color = 'w';
cb2.Color = 'w';

%% video
OptionZ.FrameRate=60;OptionZ.Duration=60;OptionZ.Periodic=true;
CaptureFigVid([150,10;220,10;150,10;150,60;150,-30;180,0;180,90;180,0],'WellMadeVid',OptionZ)
%colorbar; caxis([-77 -36]); cptcmap('EK500');
%colorbar; caxis([-85 -65]); cptcmap('EK60_2');

%cb1 = colorbar(ax,'Position',[0.81 0.1 0.03 0.815])
%cb2 = colorbar(ax2,'Position',[0.81 0.1 0.03 0.815])
%% scatter3 with pointcloud
ax2 = axes; %ES60 first
scatter3(ps2.Location(:,1),ps2.Location(:,2),ps2.Location(:,3),1,ps2.Intensity(:,1),"filled","Marker","square",...
    'MarkerFaceAlpha',1,'MarkerEdgeAlpha',1);
axis tight; colorbar; 
set(gca,'XDir','reverse','ZDir','reverse'); %mandatory
caxis([-77 -36]); %clim([-75 -40]) for EK500 / ([-75 -65]) for monochrome / clim for matlab 2022b caxis for lower
ylim([0 100]); 
zlim([0 500]); 
xlabel('ping number'); ylabel('EK80 range (m)'); zlabel('ROV depth (m)'); 
%xticks([0:200:1800]);
cptcmap('EK500',ax2);
%colormap(ax2,flipud(gray)) %greysc inv
%colormap(ax2,'gray') %

view(150,30); %view from ES60 viewpoint;
%view(170,30); %optional view
%view(180,0); %view ES60 depth profile
%view(180,90); %top view EK80

ax1 = axes('Position', ax2.Position); %EK80 part
scatter3(ps1.Location(:,1),ps1.Location(:,2),ps1.Location(:,3),1,ps1.Intensity(:,1),"filled","Marker","square"); 
%ss = scatter3(vect_ek80_38(:,1),vect_ek80_38(:,2),vect_ek80_38(:,3),3,vect_ek80_38(:,4),"filled","Marker","square");
axis tight; colorbar; set(gca,'XDir','reverse','ZDir','reverse'); 
zlim([0 500]); %mandatory
caxis([-85 -65]); cptcmap('EK60_2',ax1); hold on;
ax1.Visible = 'off';
ax1.XTick = [];
ax1.YTick = [];

%for zz = 1:length(lht_dn) %EK80 lights
%plot3(timex_80(zz,:),timey_80(zz,:),timez_80(zz,:),'r','LineWidth',1.5); %use k for ES500 cmap or m for greyscale
%set(gca,'XDir','reverse','ZDir','reverse'); axis tight; %mandatory
%%lgd = legend(ax1.Children(1),'Light off 1');
%%lgd.FontSize = 14;
%end

%for zz = 1:length(lht_dn) %ES60 lights
%plot3(timex_60(zz,:),timey_60(zz,:),timez_60(zz,:),'r','LineWidth',1.5); %use k for ES500 cmap or m for greyscale
%set(gca,'XDir','reverse','ZDir','reverse'); axis tight; %mandatory
%%lgd = legend(ax1.Children(1),'Light off 1');
%%lgd.FontSize = 14;
%end

%lgd = legend({'','2','3','4','5','6','7'},'AutoUpdate','off');
%lgd.FontSize = 14;
%lgd.Location = 'southeast';

% payload depth
%plot3(berak,zeros(1,1807),[sv.chan70.vars.depth],'k','LineWidth',1.5); %use k for ES500 cmap or m for greyscale
%set(gca,'XDir','reverse','ZDir','reverse'); axis tight; %mandatory
%%lgd = legend(ax1.Children(1),'ROV Track');
%%lgd.FontSize = 14;

hLink = linkprop([ax2,ax1],{'XLim','ZLim','Position','view'});
setappdata(gcf,'StoreTheLink',hLink);
cb1 = colorbar(ax1,'Position',[0.81 0.1 0.03 0.815]); % [left bottom width height]
%cb1 = colorbar(ax1); % [left bottom width height]
cb2 = colorbar(ax2,'Position',[0.91 0.1 0.03 0.815]);
cb1.Label.String = 'EK80 Sv (dB ref 1m^-1)';
cb2.Label.String = 'ES60 Sv (dB ref 1m^-1)';
cb1.FontSize = 16;
cb2.FontSize = 16;
%ax2.XTick = 0:100:1800;
%ax2.YTick = [0,2:2:40];
ax2.Position = [0.1    0.1100    0.7    0.8];
axis('tight')
ax2.TickDir = 'out';
ax2.FontSize = 18;
zlim([0 300])

%% Plotting in 3D Scatter (only EK80 38 and ES60 38) 
%Restructing plot for overview (3D overview)

ax2 = axes; %ES60 first
scatter3(ps2.Location(:,1),vect_es60_38(:,2),vect_es60_38(:,3),1,vect_es60_38(:,4),"filled","Marker","square");
axis tight; colorbar; 
set(gca,'XDir','reverse','ZDir','reverse'); %mandatory
caxis([-77 -36]); %clim([-75 -40]) for EK500 / ([-75 -65]) for monochrome / clim for matlab 2022b caxis for lower
ylim([0 100]); 
zlim([0 500]); 
xlabel('ping number'); ylabel('EK80 range (m)'); zlabel('ROV depth (m)'); 
%xticks([0:200:1800]);
cptcmap('EK500',ax2);
%colormap(ax2,flipud(gray)) %greysc inv
%colormap(ax2,'gray') %

view(150,30); %view from ES60 viewpoint;
%view(170,30); %optional view
%view(180,0); %view ES60 depth profile
%view(180,90); %top view EK80

ax1 = axes('Position', ax2.Position); %EK80 part
scatter3(vect_ek80_38(:,1),vect_ek80_38(:,2),vect_ek80_38(:,3),3,vect_ek80_38(:,4),"filled","Marker","square",...
    'MarkerFaceAlpha',.5,'MarkerEdgeAlpha',.5); 
%ss = scatter3(vect_ek80_38(:,1),vect_ek80_38(:,2),vect_ek80_38(:,3),3,vect_ek80_38(:,4),"filled","Marker","square");
axis tight; colorbar; set(gca,'XDir','reverse','ZDir','reverse'); 
zlim([0 500]); %mandatory
caxis([-85 -65]); cptcmap('EK60_2',ax1); hold on;
ax1.Visible = 'off';
ax1.XTick = [];
ax1.YTick = [];

%for zz = 1:length(lht_dn) %EK80 lights
%plot3(timex_80(zz,:),timey_80(zz,:),timez_80(zz,:),'r','LineWidth',1.5); %use k for ES500 cmap or m for greyscale
%set(gca,'XDir','reverse','ZDir','reverse'); axis tight; %mandatory
%%lgd = legend(ax1.Children(1),'Light off 1');
%%lgd.FontSize = 14;
%end

%for zz = 1:length(lht_dn) %ES60 lights
%plot3(timex_60(zz,:),timey_60(zz,:),timez_60(zz,:),'r','LineWidth',1.5); %use k for ES500 cmap or m for greyscale
%set(gca,'XDir','reverse','ZDir','reverse'); axis tight; %mandatory
%%lgd = legend(ax1.Children(1),'Light off 1');
%%lgd.FontSize = 14;
%end

%lgd = legend({'','2','3','4','5','6','7'},'AutoUpdate','off');
%lgd.FontSize = 14;
%lgd.Location = 'southeast';

% payload depth
%plot3(berak,zeros(1,1807),[sv.chan70.vars.depth],'k','LineWidth',1.5); %use k for ES500 cmap or m for greyscale
%set(gca,'XDir','reverse','ZDir','reverse'); axis tight; %mandatory
%%lgd = legend(ax1.Children(1),'ROV Track');
%%lgd.FontSize = 14;

hLink = linkprop([ax2,ax1],{'XLim','ZLim','Position','view'});
setappdata(gcf,'StoreTheLink',hLink);
cb1 = colorbar(ax1,'Position',[0.81 0.1 0.03 0.815]); % [left bottom width height]
%cb1 = colorbar(ax1); % [left bottom width height]
cb2 = colorbar(ax2,'Position',[0.91 0.1 0.03 0.815]);
cb1.Label.String = 'EK80 Sv (dB ref 1m^-1)';
cb2.Label.String = 'ES60 Sv (dB ref 1m^-1)';
cb1.FontSize = 16;
cb2.FontSize = 16;
%ax2.XTick = 0:100:1800;
%ax2.YTick = [0,2:2:40];
ax2.Position = [0.1    0.1100    0.7    0.8];
axis('tight')
ax2.TickDir = 'out';
ax2.FontSize = 18;
zlim([0 300])
