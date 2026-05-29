%
function plot_simple_bathy(lon_bty, lat_bty, z_bty)

f1 = figure();
imagesc(lon_bty, lat_bty, z_bty);
ax1 = gca;
shading flat;
axis xy equal tight;
clim([-1000 1000]);
%min_lon = min(temp_gps_lon)
%xlim([round(min(temp_gps.lon))-1 round(max(temp_gps.lon))+1]);
%ylim([min(temp_gps.lat)-1 max(temp_gps.lat)+1]);
colormap(ax1,cmocean('topo'));
cb2 = colorbar(ax1,"southoutside"); cb2.Label.String = 'Elevation (m)';
%title('GEBCO bathymetry')
xlabel('Longitude')
ylabel('Latitude')
% hold on
% plot(temp_gps.lon,temp_gps.lat,'LineWidth',2,'Color','red')
% p_str = plot(temp_gps.lon(1),temp_gps.lat(1),'LineWidth',2,'Color','red','Marker','+');
% f_str = plot(temp_gps.lon(end),temp_gps.lat(end),'LineWidth',2,'Color','red','Marker','+');
% p_lbl = text(temp_gps.lon(1),temp_gps.lat(1),'start','Color','red','FontSize',10);
% f_lbl = text(temp_gps.lon(end),temp_gps.lat(end),'end','Color','red','FontSize',10);

end
