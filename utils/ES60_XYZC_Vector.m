function data_vectors = ES60_XYZC_Vector(data)

%ensure all range and time are formatted 1xn!!!!!

pings = 1:length(data.time);
%time = datetime(data.time,"ConvertFrom","datenum");
vsz = length(data.range)*length(data.time); %total amount of points (x*y)

X = zeros(vsz,1); %ping number / time
Y = zeros(vsz,1); %no value / Y = 0
Z = zeros(vsz,1); %ES60 range
C = zeros(vsz,1); %ping data

rN = length(data.range); %number of data points for single ping

for i=1:length(data.time) %columns of vars/number of pings
    ind =[(i-1) *rN + 1 : 1 : i*rN];
    try
        %X(ind) = data.vars(i).timestamp * ones(rN,1); %what is alongtrack in vars?
        %X(ind) = pings * ones(rN,1); %adapted from bermudaplayfunction
        X(ind) = data.time(i); %adapted from bermudaplayfunction
    catch
        X(ind) = i * ones(rN,1);
    end
    %Y(ind) = 0
    Z(ind) = data.range(:);
    C(ind) = data.Sv(1:rN,i );
end

data_vectors = [X, Y, Z, C];
disp('[ES60 Vectorization] Completed')