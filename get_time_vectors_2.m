%fixed the data.range to only read (1xn) or (nx1) range data (trickle down
%from playfuncion.m that redundantly adds range columns
%added the option of reading whether data has corrected depth or not
%removed dumb variable names to make the function fully independent
%RMS 8/19/2023
function data_vectors = get_time_vectors_2(data, minp, maxp, scale_range, scale_depth, tri_min_depth, tri_max_depth)

%minP / maxP = ping values??
pings = 1:length(data.vars2);
vsz = size(data.range,1)*length(data.vars2); %total amount of points (x*y)
X = zeros(vsz,1); %time
Y = zeros(vsz,1); %EK80 range
Z = zeros(vsz,1); %flyer depth
C = zeros(vsz,1); %ping data

rN = size(data.range,1); %number of data points for single ping

if(exist('scale_range','var'))
    data.range = data.range*scale_range; %???
end

for i=1:length(data.vars2) %columns of vars/number of pings
    ind =[(i-1) *rN + 1 : 1 : i*rN];
    try
        %X(ind) = data.vars(i).timestamp * ones(rN,1); %what is alongtrack in vars?
        X(ind) = pings * ones(rN,1);
    catch
        X(ind) = i * ones(rN,1);
    end
    %Y(ind) = data.range(:,i); %this still assumes range is not (:,1)!!!! 
    Y(ind) = data.range(:);
    if isfield(data.vars,'depth_corrected')
        Z(ind) = ones(rN,1)*data.vars(i).depth_corrected;
        if i == 1
            disp('detected depth_correction in struct: using depth corrected values!')
        end
    else
        Z(ind) = ones(rN,1)*data.vars2(i).depth;
        if i == 1
            disp('using original CTD depth!')
        end
    end
    C(ind) = data.val2(1:rN,i );
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
disp('EK80 Vectorization done')