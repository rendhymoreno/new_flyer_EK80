function fig = plot3d_scatter(vect_ES60,vect_EK80,CLimits_ES60,CLimits_EK80,EK80_range_limit,ES60_depth_limit,camView,plt_export)

fig = figure();
ax2 = axes; %ES60 first
scatter3(vect_ES60(:,1),vect_ES60(:,2),vect_ES60(:,3),1,vect_ES60(:,4),"filled","Marker","square");
%scatter3(ps2.Location(:,1),ps2.Location(:,2),ps2.Location(:,3),1,ps2.Intensity,"filled","Marker","square");
axis tight; colorbar; 
dynamicDateTicks();
setDateAxes(gca, 'XLim', [min(vect_ES60(:,1)) max(vect_ES60(:,1))]);
set(gca,'XDir','reverse','ZDir','reverse'); %mandatory
caxis([CLimits_ES60(1) CLimits_ES60(2)]); %clim([-75 -40]) for EK500 / ([-75 -65]) for monochrome / clim for matlab 2022b caxis for lower
ylim([EK80_range_limit(1) EK80_range_limit(2)]); 
zlim([ES60_depth_limit(1) ES60_depth_limit(2)]); 
xlabel('ping number'); ylabel('EK80 range (m)'); zlabel('ROV depth (m)'); 
%xticks([0:200:1800]);
cptcmap('EK500',ax2);
%colormap(ax2,flipud(gray)) %greysc inv
%colormap(ax2,'gray') %

view(camView(1),camView(2)); %view from ES60 viewpoint;
%view(170,30); %optional view
%view(180,0); %view ES60 depth profile
%view(180,90); %top view EK80

ax1 = axes('Position', ax2.Position); %EK80 part
scatter3(vect_EK80(:,1),vect_EK80(:,2),vect_EK80(:,3),3,vect_EK80(:,4),"filled","Marker","square");
axis tight; colorbar; set(gca,'XDir','reverse','ZDir','reverse'); 
dynamicDateTicks();
setDateAxes(gca, 'XLim', [min(vect_ES60(:,1)) max(vect_ES60(:,1))]);
zlim([ES60_depth_limit(1) ES60_depth_limit(2)]); %mandatory
caxis([CLimits_EK80(1) CLimits_EK80(2)]); cptcmap('EK60_2',ax1); hold on;
ax1.Visible = 'off';
ax1.XTick = [];
ax1.YTick = [];

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
%zlim([0 300])

end

%% Old Code
%{
ax2 = axes; %ES60 first
%scatter3(vect_es60_38(:,1),vect_es60_38(:,2),vect_es60_38(:,3),1,vect_es60_38(:,4),"filled","Marker","square");
scatter3(ps2.Location(:,1),ps2.Location(:,2),ps2.Location(:,3),1,ps2.Intensity,"filled","Marker","square");
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
scatter3(vect_ek80_70(:,1),vect_ek80_70(:,2),vect_ek80_70(:,3),3,vect_ek80_70(:,4),"filled","Marker","square");
axis tight; colorbar; set(gca,'XDir','reverse','ZDir','reverse'); 
zlim([0 500]); %mandatory
caxis([-100 -80]); cptcmap('EK60_2',ax1); hold on;
ax1.Visible = 'off';
ax1.XTick = [];
ax1.YTick = [];

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
%}