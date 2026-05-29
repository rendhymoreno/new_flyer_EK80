% function data_vectors = get_localtrack_vectors(glob_ind, data, minp, maxp, scale_range, scale_depth, tri_min_depth, tri_max_depth)
function data_vectors = get_localtrack_vectors(data, minp, maxp, scale_range, scale_depth, tri_min_depth, tri_max_depth)

vsz = size([data.range],1)*length([data.vars]);
X = zeros(vsz,1);
Y = zeros(vsz,1);
Z = zeros(vsz,1);
C = zeros(vsz,1);

rN = size(data.range,1);

if(exist('tri_max_depth', 'var'))
    data=reject_surface_reverb(data, tri_min_depth,tri_max_depth);
end
if(exist('scale_range', 'var'))
    data.range = data.range*scale_range;
end

% [ping_x,ping_y] = ll2xy([data.vars.lat],[data.vars.lon],glob_ind(1).lat,glob_ind(1).lon);
% [ping_x,ping_y] = ll2xy(medfilt1([data.vars.lat],10),medfilt1([data.vars.lon],10),data.vars(1).lat,data.vars(1).lon);
[ping_x,ping_y] = ll2xy([data.vars.lat],[data.vars.lon],data.vars(1).lat,data.vars(1).lon);

heading = medfilt1([data.vars.heading],10);

for i=1:length(data.vars)
%     R = rotz( (-([data.vars(i).heading] - 90) - 90)  );
    R = rotz( (-(heading(i) - 90) - 90)  );

    ping_xy_local = R*[data.range(:,i)';zeros(size(data.range(:,i)))';zeros(size(data.range(:,i)))'];
    ind =(i-1)*rN + 1 : 1 : i*rN;
    X(ind) = ping_x(i)+ping_xy_local(1,:)';
    Y(ind) = ping_y(i)+ping_xy_local(2,:)';
    Z(ind) = ones(rN,1)*data.vars(i).depth;
    C(ind) = data.val(1:rN, i);
end

if(exist('maxp', 'var'))
    cindex = C > minp & C < maxp;
    X=X(cindex);
    Y=Y(cindex);
    Z=Z(cindex);
    C=C(cindex);
end

if(exist('scale_depth','var'))
    Z= Z*scale_depth;
end

data_vectors = [X, Y, Z, C];
