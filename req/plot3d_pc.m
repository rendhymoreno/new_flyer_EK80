% Plot3d_pc.m
% Plot 3D Pointcloud data
% Need Computer Vision Toolbox
% fixed the error where the EK80 data randomly changes it's scale. This has
% to do with the ax1 and ax2 dataaspectratio. Fixed by leaving both of
% these changes at the bottom of code

function [f,ax1,ax2,cb1,hlink] = plot3d_pc(pc_ES60,pc_EK80,CLimits_ES60,CLimits_EK80,EK80_range_limit,ES60_depth_limit,camView,plt_export)

if isempty(EK80_range_limit)
    EK80_range_limit(1) = 0;
    EK80_range_limit(2) = max(pc_EK80.Location(:,2));
end

if isempty(ES60_depth_limit)
    ES60_depth_limit(1) = 0;
    ES60_depth_limit(2) = max(pc_ES60.Location(:,3));
end

if isempty(camView)
    camView(1) = 170;
    camView(1) = 10;
end

f = figure('WindowState', 'maximized');
ax1 = axes;
ax1 = pcshow(pc_ES60, ColorSource="Intensity");
dynamicDateTicks();
setDateAxes(gca, 'XLim', [min(pc_ES60.Location(:,1)) max(pc_ES60.Location(:,1))]);
caxis([CLimits_ES60(1) CLimits_ES60(2)]);
zlim([ES60_depth_limit(1) ES60_depth_limit(2)])
if ~isempty(EK80_range_limit)
    ylim([EK80_range_limit(1) EK80_range_limit(2)])
end

set(ax1,'XDir','reverse','ZDir','reverse');
xlabel(ax1,'Time (UTC)','FontSize',14);
ylabel(ax1,'EK80 horizontal range (m)','FontSize',14);
%ylabel(ax1,'EK80 horizontal range (m)','FontSize',14,'Rotation',-30,'Position',[-226,46,536]);
zlabel(ax1,'Depth (m)','FontSize',14);
ax1.FontSize = 14;

hold on
ax2 = axes;
ax2 = pcshow(pc_EK80, MarkerSize=40, ColorSource="Intensity");
%ax2 = pcviewer(ps1, ColorSource="Intensity");
dynamicDateTicks();
setDateAxes(gca, 'XLim', [min(pc_ES60.Location(:,1)) max(pc_ES60.Location(:,1))]);
set(ax2,'XDir','reverse','ZDir','reverse');
%zlim([0 500])
%ylim([0 98])
zlim([ES60_depth_limit(1) ES60_depth_limit(2)])
if ~isempty(EK80_range_limit)
    ylim([EK80_range_limit(1) EK80_range_limit(2)])
end
caxis([CLimits_EK80(1) CLimits_EK80(2)]);
%hlink = linkprop([ax1, ax2], {'CameraUpVector','CameraPosition','CameraTarget'});
%hlink = linkprop([ax1, ax2], {'X','Z',});
hlink = linkprop([ax1, ax2], {'XLim','ZLim','Position','view','CameraUpVector', 'CameraPosition', ...
    'CameraTarget'});
setappdata(gcf, 'StoreTheLink', hlink);

ax2.Visible = 'off';
ax2.XTick = [];
ax2.YTick = [];
%set(ax2.Children,'visible','off') %sets plot2 to be invisible
view(camView(1),camView(2))

ax1.DataAspectRatio = [0.5*diff(ax1.XLim), 2*diff(ax1.YLim), diff(ax1.ZLim)] / diff(ax1.YLim);
ax2.DataAspectRatio = [0.5*diff(ax2.XLim), 2*diff(ax2.YLim), diff(ax2.ZLim)] / diff(ax2.YLim);
colormap(ax1,flipud('gray'))
%cptcmap('EK500',ax1)
cptcmap('EK60_2',ax2')

cb1 = colorbar(ax1,'Location','south','Position',[0.8000 0.9100 0.1500 0.0215]); %left bottom width height [0.74 0.1 0.03 0.815] / [0.8000 0.6000 0.1500 0.0215]
cb2 = colorbar(ax2,'Location','south','Position',[0.5500 0.9100 0.1500 0.0215]); %[0.8000 0.5000 0.1500 0.0215] %[0.84 0.1 0.03 0.815] / [0.8000 0.5000 0.1500 0.0215]
cb1.Ticks = [-77 floor((-77-36)/2) -36];
cb2.Ticks = [-77 floor((-77-36)/2) -36];
%cb2.Ticks = [-95 -80 -65];

cb1.AxisLocation = 'out';
cb2.AxisLocation = 'out';
cb2.Label.String = 'EK80 Sv (dB ref 1m^-1)';
cb1.Label.String = 'Sv (dB ref 1m^-1)';
cb1.FontSize = 16;
cb2.FontSize = 16;
cb1.Color = 'w';
cb2.Color = 'w';
%}

if plt_export == 1
    f.WindowState = 'maximized';
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    set(gcf, 'Toolbar', 'none', 'Menu', 'none');
    plt_title = "\"+string(datetime("now","Format","ddMMuuuu_HHmmss"))+"_scatter.bmp";
    export_fig(strcat(pwd,plt_title), '-bmp');
    %fprintf('exporting plot: %s; to: %s\n',strcat(dstr2+sprintf("%skHz.bmp", chan{n})),pwd);
end

end

%% Old Code
%{
%% pt plot
% Need Computer Vision Toolbox
% fixed the error where the EK80 data randomly changes it's scale. This has
% to do with the ax1 and ax2 dataaspectratio. Fixed by leaving both of
% these changes at the bottom of code
f = figure('WindowState', 'maximized');
ax1 = axes;
ax1 = pcshow(ps2, ColorSource="Intensity"); 
dynamicDateTicks(); 
setDateAxes(gca, 'XLim', [min(ps2.Location(:,1)) max(ps2.Location(:,1))]);
caxis([-77 -36]); 
zlim([0 500])
ylim([0 98])
set(ax1,'XDir','reverse','ZDir','reverse'); 
xlabel(ax1,'ping number','FontSize',14); 
ylabel(ax1,'EK80 horizontal range (m)','FontSize',14); 
%ylabel(ax1,'EK80 horizontal range (m)','FontSize',14,'Rotation',-30,'Position',[-226,46,536]); 
zlabel(ax1,'flyer depth (m)','FontSize',14); 
ax1.FontSize = 14;

hold on
ax2 = axes;
ax2 = pcshow(ps1, ColorSource="Intensity"); 
%ax2 = pcviewer(ps1, ColorSource="Intensity");  
dynamicDateTicks(); 
setDateAxes(gca, 'XLim', [min(ps2.Location(:,1)) max(ps2.Location(:,1))]);
set(ax2,'XDir','reverse','ZDir','reverse'); 
zlim([0 500])
ylim([0 98])
caxis([-77 -36]);
%hlink = linkprop([ax1, ax2], {'CameraUpVector','CameraPosition','CameraTarget'});
hlink = linkprop([ax1, ax2], {'XLim','ZLim','Position','view'});

ax2.Visible = 'off';
ax2.XTick = [];
ax2.YTick = [];
%set(ax2.Children,'visible','off') %sets plot2 to be invisible
view(170,10)

ax1.DataAspectRatio = [0.5*diff(ax1.XLim), 2*diff(ax1.YLim), diff(ax1.ZLim)] / diff(ax1.YLim);
ax2.DataAspectRatio = [0.5*diff(ax2.XLim), 2*diff(ax2.YLim), diff(ax2.ZLim)] / diff(ax2.YLim);
cptcmap('EK500',ax1)
cptcmap('EK60_2',ax2')

cb1 = colorbar(ax1,'Location','south','Position',[0.8000 0.9100 0.1500 0.0215]); %left bottom width height [0.74 0.1 0.03 0.815] / [0.8000 0.6000 0.1500 0.0215]
%cb2 = colorbar(ax2,'Location','south','Position',[0.8000 0.5000 0.1500 0.0215]); %[0.84 0.1 0.03 0.815] / [0.8000 0.5000 0.1500 0.0215]
cb1.Ticks = [-77 floor((-77-36)/2) -36];
%cb2.Ticks = [-77 floor((-77-36)/2) -36];
%cb2.Ticks = [-95 -80 -65];

cb1.AxisLocation = 'out';
%cb2.AxisLocation = 'out';
%cb2.Label.String = 'EK80 Sv (dB ref 1m^-1)';
cb1.Label.String = 'Sv (dB ref 1m^-1)';
cb1.FontSize = 16;
%cb2.FontSize = 16;
cb1.Color = 'w';
%cb2.Color = 'w';


% Exporting 
%run colormapeditor before exporting!! change the 1st value to pure white
plt_title = "\"+string(datetime("now","Format","ddMMuuuu_HHmmss"))+"_scatter.bmp";
export_fig(strcat(pwd,plt_title), '-bmp');

%}
