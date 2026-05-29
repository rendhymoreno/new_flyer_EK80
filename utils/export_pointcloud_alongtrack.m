function export_pointcloud_alongtrack(plotdata, minp, maxp, scalerange)

vsz = size(plotdata.range,1)*length(plotdata.vars);
X = zeros(vsz,1); 
Y = zeros(vsz,1); 
Z = zeros(vsz,1); 
C = zeros(vsz,1); 

rN = size(plotdata.range,1);
pN = size(plotdata.range,2); 

for i=1:length(plotdata.vars)
    ind =[(i-1) *rN + 1 : 1 : i*rN];
    X(ind) = plotdata.vars(i).along_track * ones(rN,1);
    Y(ind) = plotdata.range(:,i);
    Z(ind) = ones(rN,1)*plotdata.vars(i).depth; 
    C(ind) = plotdata.val(1:rN,i );
end

survived_pings = zeros(vsz,1); 
for i=1:length(X)
        survived_pings(i) = Y(i) < reject_surface_reverb(8,45, Z(i));
end
survived_pings = logical(survived_pings);

X = X(survived_pings);
Y = Y(survived_pings);
Z = Z(survived_pings);
C = C(survived_pings);  
 

Y=Y*10;
Z=Z*10;
location = [X, Y, Z];
Cnorm = normalize(C,'range')*256; 

ptcloud = pointCloud(location, 'Intensity', Cnorm);
pcwrite(ptcloud, 'C:\Users\Ben\Desktop\pc_cutoffmore.ply');
