%% Only works with 1 channel!!
function outdata = flyer_query_castData(data, channel, cast_index, castQuery)

chan = fieldnames(data);
%fprintf('[Cast query] Parsing cast: %d\n',castQuery);
if channel == 1
    lg = sprintf('[Cast query] Reading data from channel 1: %s ',chan{1});
    disp(lg)
    chan = chan(1);
elseif channel == 2
    lg = sprintf('[Cast query] Reading data from channel 2: %s ',chan{2});
    disp(lg)
    chan = chan(2);
else
    lg = sprintf('[Cast query] Reading data from all %i channels',length(chan));
    disp(lg)
end

for ch = 1:length(chan)
    vars = [data.(chan{ch}).vars];
    range = [data.(chan{ch}).range];
    depth = [data.(chan{ch}).vars.depth];
    val = [data.(chan{ch}).val];
    
    if isfield(vars,'cast_new')
        casts_data = [vars.cast_new];
        fprintf('[Cast query] Cast numbers are fixed. Will use cast_new as index \n');
    else
        casts_data = [vars.cast];
        fprintf('[Cast query] cast_new not available in struct. Will use default cast numbers \n');
    end

    cast_id = unique(casts_data);
    
    if isempty(cast_index)
        fprintf('[Cast query] Cast indexes are not provided, will calculate indexes \n');
        for ii = 1:length(cast_id)
            cast_idx = (casts_data==cast_id(ii));
            cast_idx2 = find(cast_idx==1);
            cast_index(1,ii) = cast_idx2(1);
            cast_index(2,ii) = cast_idx2(end);
            %flyer_casts.(chan{ch}).("C"+sprintf('%d',cast_id(i))).global_idx = cast_idx2;
        end
    else
        fprintf('[Cast query] Cast indexes are provided as input \n');
    end
    
    if isempty(castQuery)
        %fprintf('[Cast query] Cast indexes are not provided, will calculate indexes \n');
        castQuery = cast_id;
    end
    
    if numel(cast_id) ~= size(cast_index,2)
        error('[Cast query] Could not calculate indexes!')
    end

    c = 1;
    for i = 1:length(castQuery)
        try
            check_query = ismember(cast_id,castQuery(i));
            if any(check_query)
                %fprintf('[Cast query] Cast %d exists, will proceed to query\n',castQuery(i));
                idx_query = find(check_query);
                vars2 = vars(cast_index(1,idx_query):cast_index(2,idx_query));
                val2 = val(:,cast_index(1,idx_query):cast_index(2,idx_query));
                outdata.("C"+sprintf('%d',castQuery(i))).(chan{ch}) = data.(chan{ch});
                outdata.("C"+sprintf('%d',castQuery(i))).(chan{ch}).vars = vars2;
                outdata.("C"+sprintf('%d',castQuery(i))).(chan{ch}).val = val2;
                fprintf('[Cast query] Saving cast %d into output. Processing next cast \n',castQuery(i));
                c = c+1;
            else
                error('[Cast query] The cast requested does not exist!');
            end
        catch err
            if strcmp(err.message,'[Cast query] The cast requested does not exist!')
                %i=i;
                fprintf('[Cast query] The cast requested (%d) does not exist! Proceeding with the next cast\n',castQuery(i));
            else
                rethrow(err);
            end
        end
    end

end
c = c-1;
fprintf('[Cast query] Data is seperated into %d individual casts\n',c);
end