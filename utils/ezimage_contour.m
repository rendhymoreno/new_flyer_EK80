function ezimage_contour(x,y,c1,c2,c_level,climits,cmap_t)

figure();
[X,Y] = meshgrid(x,y);
imagesc(x,y,c1);
if strcmp(cmap_t,'EK60')
    cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
else
    colormap(cmap_t)
end

set(gca,"YDir","reverse")
axis tight; shading flat;
xticks('auto');yticks('auto');colorbar;
clim([climits(1) climits(2)])
grid on;
hold on
[C,h] = contour(X,Y,c2,c_level,'k','LabelFormat','%0.1f');
clabel(C,h,'FontSize',8,'Color','red','FontWeight','bold','LabelSpacing',1500);
%contour(Xoxy,Yoxy,z_oxy,4,'k');

end