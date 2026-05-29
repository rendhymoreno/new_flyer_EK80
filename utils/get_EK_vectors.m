%fixed the data.range to only read (1xn) or (nx1) range data (trickle down
%from playfuncion.m that redundantly adds range columns
%added the option of reading whether data has corrected depth or not
%removed dumb variable names to make the function fully independent
%RMS 8/19/2023
function [data_vectors,param_c] = get_EK_vectors(data, dimen, param_x, param_c)

if strcmp(dimen,'3D') || ~strcmp(dimen,'2D')
        %Y(ind) = data.range(:);
        fprintf('[vectorization] Vectorized echosounder data is 3-D\n')
    else
        %Y = zeros(vsz,1); %EK80 range
        fprintf('[vectorization] Vectorized echosounder data is 2-D\n')
end

%minP / maxP = ping values??
if strcmp(param_x,'ping')
    param = 1:length(data.vars);
    fprintf('[vectorization] The X-axis selected is ping number! \n')
elseif strcmp(param_x,'time')
    param = [data.vars.timestamp];
    if param(1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
        disp('[EK80 vectorization] timestamp of EK80 is in epoch/UNIX milliseconds\n')
        param = datenum(datetime(param,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
    end
    fprintf('[vectorization] The X-axis selected is in datenum timestamps! \n')
elseif strcmp(param_x,'dist')
    param = [data.vars.along_track];
    %if param(1) ~= 0
    %    param = param - param(1);
    %end
    fprintf('[vectorization] The X-axis selected is along track distance! \n')
end

varN = fieldnames(data.vars);
varN = {'EK' varN{[4 8:12]}};

if strcmp(param_c,'all')
    param_c = {varN{:}};
    fprintf('[EK80 vectorization] Appending multiple param_c: %s \n',param_c{:});
end

varN_out = ismember(varN,param_c);

if isempty(varN_out) & isempty(param_c)
    param_c = 'EK';
end

vsz = size(data.range,1)*length(data.vars); %total amount of points (x*y)
X = zeros(vsz,1); %time
Y = zeros(vsz,1); %EK80 range
Z = zeros(vsz,1); %flyer depth
C = zeros(vsz,sum(varN_out)); %ping data

rN = size(data.range,1); %number of data points for single ping

if(exist('scale_range','var'))
    data.range = data.range*scale_range; %???
end

for i=1:length(data.vars) %columns of vars/number of pings
    ind =[(i-1) *rN + 1 : 1 : i*rN];
    try
        %X(ind) = data.vars(i).timestamp * ones(rN,1); %what is alongtrack in vars?
        X(ind) = param(i); %what is alongtrack in vars?
        %X(ind) = pings * ones(rN,1);
    catch
        X(ind) = i * ones(rN,1);
    end
    %Y(ind) = data.range(:,i); %this still assumes range is not (:,1)!!!!
    
    %if strcmp(dimen,'3D') || ~strcmp(dimen,'2D')
        Y(ind) = data.range(:);
        %fprintf('[vectorization] Vectorized echosounder data is 3-D\n')
    %end

    if isfield(data.vars,'depth_corrected')
        Z(ind) = ones(rN,1)*data.vars(i).depth_corrected;
        if i == 1
            disp('detected depth_correction in struct: using depth corrected values!')
        end
    else
        Z(ind) = ones(rN,1)*data.vars(i).depth;
        if i == 1
            disp('using original CTD depth!')
        end
    end
    
    if sum(varN_out) == 1
        if strcmp(param_c,'EK')
            C(ind) = data.val(1:rN,i );
        elseif strcmp(param_c,'temperature')
            C(ind) = [data.vars(1:rN,i ).temperature];
        elseif strcmp(param_c,'salinity')
            C(ind) = [data.vars(1:rN,i ).salinity];
        elseif strcmp(param_c,'chlorophyll')
            C(ind) = [data.vars(1:rN,i ).chlorophyll];
        elseif strcmp(param_c,'oxygen')
            C(ind) = [data.vars(1:rN,i ).oxygen];
        elseif strcmp(param_c,'turbidity')
            C(ind) = [data.vars(1:rN,i ).turbidity];
        elseif strcmp(param_c,'pot_density')
            C(ind) = [data.vars(1:rN,i ).pot_density];
        
        end
    elseif sum(varN_out) > 1
        if strcmp(param_c{1},'EK')
            C(ind,1) = data.val(1:rN,i );
            C(ind,2:end) = cell2mat(struct2cell(rmfield(data.vars(1:rN,i ), setdiff(fieldnames(data.vars), param_c(2:end))))');
            %fprintf('[EK80 vectorization] Appending multiple parameters: %s \n',param_c);
        else
            C(ind,:) = cell2mat(struct2cell(rmfield(data.vars(1:rN,i ), setdiff(fieldnames(data.vars), param_c(2:end))))');
            %fprintf('[EK80 vectorization] Appending multiple param_c: %s \n',param_c);
        end
    end
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
disp('[EK80 vectorization] Completed')