function data_vectors = get_alongtrack_var_vectors(data, scale_range, scale_depth, var)

vsz = length(data.vars);
X = zeros(vsz,1);
Y = zeros(vsz,1);
Z = zeros(vsz,1);
C = zeros(vsz,1);

if(exist('scale_range'))
    data.range = data.range*scale_range;
end

for i=1:length(data.vars)
    X(i) = data.vars(i).along_track;
    Y(i) = 0;
    Z(i) = data.vars(i).depth;
    C(i) = eval(strcat('data.vars(i).',var));
%     C(i) = data.vars(i).oxygen;
end

if(exist('scale_depth','var'))
    Z= Z*scale_depth;
end

data_vectors = [X, Y, Z, C];
