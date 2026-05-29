% playfunction_rms: function to call out processed ping data (only one per function, if more parameters are needed call out this function as necessary)
% OUTPUT = queried processed data (power_cw,power_pc, alongship, athwardship, sv_pc,
% ts_pc, sv_cw, ts_cw, svf, f, or rawPower)
% INPUT:
% globalindPath = 'string'; dir path/folder of the global index.mat
% index_type = 'string'; determine which data you want based on the type of index (see in global_index.mat), e.g., 'ping_local' or 'ping_global'
% indexes = 'string;; the indexes that will be processed, e.g., '1:max([global_indexer.cast])' 
% will process all the data from cast 1 to max(cast)
% param = 'string'; the type of parameter that will be outputted, e.g., if
% you want pulse compressed backscatter than param = 'sv_pc'

function procdata = playfunction_rms(globalindPath, index_type, indexes, param)

load(strcat(globalindPath, 'global_index.mat'));
% flyer = load(flyer);
% outdirectory = 'H:\PointClouds\';

ch_dict = {'EKA 264029-0F ES70-18CD'; 
           'EKA 264029-70 ES200-7CDK-Split';
           'EKA 264029-07 ES38-18DK-Split';
           'EKA 279928-0F ES70-18CD';
           'EKA 279928-70 ES200-7CDK-Split'};

ch_data = unique({global_indexer.channel})';

for i = 1:length(ch_data)
    for j = 1:length(ch_dict)
        idx(i,j) = strcmp(ch_dict{j},ch_data{i});
    end
end

for k=1:length(ch_data)
if ch_data{k}(17) == '3'
    channel_38 = char(ch_dict(idx(k,:)));
elseif ch_data{k}(17) == '7'
    channel_70 = char(ch_dict(idx(k,:)));
elseif ch_data{k}(17) == '2'
    channel_200 = char(ch_dict(idx(k,:)));
end
end

%Process 38 kHz
if exist('channel_38','var') == 1
if(sum((strcmp({global_indexer.channel}, channel_38))) > 0)
    if(isstring(indexes) || ischar(indexes))
        data = generate_data(global_indexer, index_type, eval(indexes), channel_38, param, globalindPath);
    else
        data = generate_data(global_indexer, index_type, indexes, channel_38, param, globalindPath);
    end
    procdata.chan38 =  data;
    disp('Generated 38 kHz Data')
end
end

%Process 70 kHz
if exist('channel_70','var') == 1
if(sum((strcmp({global_indexer.channel}, channel_70))) > 0)
    if(isstring(indexes) || ischar(indexes))
        data = generate_data(global_indexer, index_type, eval(indexes), channel_70, param, globalindPath);
    else
        data = generate_data(global_indexer, index_type, indexes, channel_70, param, globalindPath);
    end
    procdata.chan70 =  data;
    disp('Generated 70 kHz Data')
end
end

% Process 200 kHz
if exist('channel_200','var') == 1
if( ~strcmp(param, 'power_pc4') && sum((strcmp({global_indexer.channel}, channel_200))) > 0)
    if(isstring(indexes) || ischar(indexes))
        data = generate_data(global_indexer, index_type, eval(indexes), channel_200, param, globalindPath);
    else
        data = generate_data(global_indexer, index_type, indexes, channel_200, param, globalindPath);
    end
    procdata.chan200 =  data;
    disp('Generated 200 kHz Data')
end
end

end