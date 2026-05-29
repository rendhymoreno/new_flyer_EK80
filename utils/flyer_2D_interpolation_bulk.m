% yscale = 10;
%dx = 10;
%dy = 0.1;
%dx = 10;
%dx = 10;
%alp_rad = 500;
function out = flyer_2D_interpolation_bulk(vectdata,yscale,dx,dy,alp_rad,paramN,plot_fig)

x = vectdata(:,1);
y = vectdata(:,3);
z = vectdata(:,4);
pxi = [x(1):dx:x(end)]';
pyi = min(y):dy:max(y);
z_n_i = isnan(z);
x(z_n_i) = []; y(z_n_i) = []; z(z_n_i) = [];
[xi,yi] = meshgrid(pxi,pyi*yscale);
%zi = griddata(x,y,z,xi,yi);
%DT = delaunayTriangulation(x,y*dy);
shp = alphaShape(x,y*yscale,alp_rad);
[tri,P] = alphaTriangulation(shp); %tri gives me vertices of triangle and P rows is the vertices. P is the index of X,Y values for every vertices
TR = triangulation(tri,P);

if ~isempty(plot_fig)
    figure()
    triplot(TR)
    hold on
    plot(x,y*yscale,'*');
    set(gca,'YDir','reverse')
    hold off
end

%points located inside alphashape
grd_shp = inShape(shp,xi,yi);
xi_g = xi;
yi_g = yi;
xi_g(~grd_shp) = NaN;
%yi_g(~grd_shp) = NaN;
[x_idx, y_idx] = find(~isnan(xi_g)); %This will map every lin index to matrix form

P_g = [xi(grd_shp) yi(grd_shp)];

% Triangles surrounding grid points
ID = pointLocation(TR,P_g(:,1),P_g(:,2));
vert_alpha = TR.ConnectivityList(ID,:);

%This is to plot 1st triangle and mesh points in triangle. This seems to
%capture the grid points correctly
% figure()
% trig1_idx = ID==ID(1); %First triangle
% xtrig1 = P_g(:,1);
% ytrig1 = P_g(:,2);
% %trig1 = ID(trig1_idx);
% triplot(TR)
% hold on
% triplot(TR.ConnectivityList(ID(1),:),TR.Points(:,1),TR.Points(:,2),'r')
% plot(xtrig1(trig1_idx),ytrig1(trig1_idx),'*');
% set(gca,'YDir','reverse')
% hold off

% However, the vertices location is incorrect based on the loc of the
    % original data. The vertices are correct, but the order is wrong! 
    % New indexing is made here to summon the correct Z index:
[~, allXIndices] = ismember(TR.Points(:,1), x);
vert_origin = allXIndices(TR.ConnectivityList(ID,:));

%Coordinates of each vertice with 
P1 = [TR.Points(vert_alpha(:,1),:)];
P2 = [TR.Points(vert_alpha(:,2),:)];
P3 = [TR.Points(vert_alpha(:,3),:)];

%Calculate distance from every grid point
PP1 = sqrt(sum([P1-P_g].*[P1-P_g],2));
PP2 = sqrt(sum([P2-P_g].*[P2-P_g],2));
PP3 = sqrt(sum([P3-P_g].*[P3-P_g],2));

%Inverse distance weighted average for z interpolation
param_c = vectdata(:,5:end);

for i=1:size(param_c,2)
    
    z = param_c(:,i);
    zi = ( z(vert_origin(:,1))./(PP1.*PP1) + z(vert_origin(:,2))./(PP2.*PP2) + z(vert_origin(:,3))./(PP3.*PP3) ) ...
        ./ (1./(PP1.*PP1) + 1./(PP2.*PP2) + 1./(PP3.*PP3));

    pzi = NaN(size(xi_g,1),size(xi_g,2));
    pzi(sub2ind(size(pzi), x_idx, y_idx)) = zi;
    out.(paramN{i+1}) = pzi;
end

figure();
imagesc(pxi/1000, pyi, out.temperature);
colormap(colorcet('L20'));
set(gca,"YDir","reverse")
axis tight; shading flat;
xticks('auto');yticks('auto');colorbar;
xlim([min(pxi,[],"all")/1000 max(pxi,[],"all")/1000]);
ylim([min(pyi,[],"all") max(pyi,[],"all")]);
%clim([-84 -42])
grid on;

end

