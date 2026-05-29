function ezpcplot(datain,cl,camview,mark_size)

if isempty(mark_size)
    mark_size = 6;
end

f = figure('WindowState', 'maximized');
ax1 = axes;
pc = pcshow(datain, MarkerSize=mark_size, ColorSource="Intensity");
dynamicDateTicks();
setDateAxes(gca, 'XLim', [min(datain.Location(:,1)) max(datain.Location(:,1))]);
clim([cl(1) cl(2)]);

%alphaMask = datain < cl(1);
%alphaMask = double(alphaMask);
%pc.AlphaData = alphaMask;

zlim([0 500]);
ylim([0 100]);
set(ax1,'XDir','reverse','ZDir','reverse');
xlabel(ax1,'Time (UTC)','FontSize',14);
ylabel(ax1,'EK80 horizontal range (m)','FontSize',14);
%ylabel(ax1,'EK80 horizontal range (m)','FontSize',14,'Rotation',-30,'Position',[-226,46,536]);
zlabel(ax1,'flyer depth (m)','FontSize',14);
ax1.FontSize = 14;
ax1.DataAspectRatio = [0.5*diff(ax1.XLim), 2*diff(ax1.YLim), diff(ax1.ZLim)] / diff(ax1.YLim);
view(camview(1),camview(2))
%colormap('turbo')
cptcmap('EK60_2',ax1')

end