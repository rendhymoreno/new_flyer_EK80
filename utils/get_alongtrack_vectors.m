function data_vectors = get_alongtrack_vectors(data, minp, maxp, scale_range, scale_depth, tri_min_depth, tri_max_depth)

%minP / maxP = ping values??
vsz = size(data.range,1)*length(data.vars); %total amount of points (x*y)
X = zeros(vsz,1); %alongtrack distance??
Y = zeros(vsz,1); %EK80 range
Z = zeros(vsz,1); %flyer depth
C = zeros(vsz,1); %ping data

rN = size(data.range,1); %number of data points for single ping

if(exist('scale_range','var'))
    data.range = data.range*scale_range; %???
end

for i=1:length(data.vars) %columns of vars/number of pings
    ind =[(i-1) *rN + 1 : 1 : i*rN];
    try
        X(ind) = data.vars(i).along_track * ones(rN,1); %what is alongtrack in vars?
    catch
        X(ind) = i * ones(rN,1);
    end
    Y(ind) = data.range(:,i); 
    Z(ind) = ones(rN,1)*data.vars(i).depth;
    C(ind) = data.val(1:rN,i );
end

if(exist('scale_depth','var'))
    Z= Z*scale_depth;
end

if(exist('maxp', 'var'))
    cindex = C > minp & C < maxp;
    X=X(cindex);
    Y=Y(cindex);
    Z=Z(cindex);
    C=C(cindex);
end

if(exist('tri_max_depth', 'var'))
    survived_pings = zeros(vsz,1);
    for i=1:length(X)
        survived_pings(i) = Y(i) < scale_range*calc_surface_rejection(tri_min_depth,tri_max_depth, Z(i)/scale_depth);
    end
    survived_pings = logical(survived_pings);
    
    X = X(survived_pings);
    Y = Y(survived_pings);
    Z = Z(survived_pings);
    C = C(survived_pings);
end

data_vectors = [X, Y, Z, C];
