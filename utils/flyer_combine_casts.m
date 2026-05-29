%Only works with 1 channel
function outdata = flyer_combine_casts(data)

cast_id = fieldnames(data);
ncast = numel(cast_id);
fprintf('[Combine casts] The number of casts detected is %d \n',ncast);
chan = string(fieldnames(data.(string((cast_id{1})))));
fprintf('[Combine casts] Detected channel: %s \n',chan);
outdata.(chan) = data.(string(cast_id{1})).(chan);

for i =1:ncast
    if i==1
        vars2 = [data.((string(cast_id{i}))).(chan).vars];
        vars = [];
        num_t(i) = length(vars2);
        val(:,i:num_t) = [data.((string(cast_id{i}))).(chan).val];
        vars2 = [vars2,vars];
    else
        vars = [data.((string(cast_id{i}))).(chan).vars];
        num_t(i) = length(vars);
        val(:,(sum(num_t,"all")-num_t(i)+1):sum(num_t,"all")) = [data.((string(cast_id{i}))).(chan).val];
        vars2 = [vars2,vars];
    end
    
end

outdata.(chan).vars = vars2;
outdata.(chan).val = val;
fprintf('[Combine casts] All casts are combined into the output file! \n');
end