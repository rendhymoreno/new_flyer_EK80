function ezimagesc_2plot(x1,y1,c1,x2,y2,c2,cmap_t,climits)

figure();
tiledlayout(4,1,'TileSpacing','compact');
nexttile;
h = imagesc(x1, y1, c1);
if strcmp(cmap_t,'EK60')
    cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
else
    colormap(cmap_t)
end
set(gca,'FontSize',14);
xlabel('alongship distance (m)')
ylabel('depth (m)')
set(h, 'AlphaData', ~isnan(c1))
set(gca,"YDir","reverse")
axis tight; shading flat;
xticks('auto');yticks('auto');
xlim([min(x1,[],"all") max(x1,[],"all")]); %69557.0234902080
%xlim([min(x1,[],"all") 69557.0234902080]);
ylim([min(y1,[],"all") max(y1,[],"all")]);
if ~exist('climits','var')
    clim([min(c1,[],'all') max(c1,[],'all')])
else
    clim([climits(1) climits(2)])
end

grid on;

nexttile;
h = imagesc(x2, y2, c2);
if strcmp(cmap_t,'EK60')
    cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
else
    colormap(cmap_t)
end
set(gca,'FontSize',14);
xlabel('alongship distance (m)')
ylabel('depth (m)')
set(h, 'AlphaData', ~isnan(c2))
set(gca,"YDir","reverse")
axis tight; shading flat;
xticks('auto');yticks('auto');colorbar;
xlim([min(x2,[],"all") max(x2,[],"all")]);
ylim([min(y1,[],"all") max(y1,[],"all")]);
if ~exist('climits','var')
    clim([min(c2,[],'all') max(c2,[],'all')])
else
    clim([climits(1) climits(2)])
end

grid on;
end