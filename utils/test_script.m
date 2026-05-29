cast_id = fieldnames(svEK80_casts);
chan = string(fieldnames(svEK80_casts.(string((cast_id{1})))));
svEK80_casts_f = svEK80_casts;
log = cell(3,numel(cast_list));
for i = 1:numel(cast_list)
    try
        log{1,i} = sprintf('Filtering cast %d \n',cast_list(i));
        %disp(log);
        svEK80_tt = impulse_noise_filter(svEK80_casts.("C"+sprintf('%d',cast_list(i))),'EK80',1,40,2,7,0,105,'NaN',[],[],[]); %threshold works better with 7, 40 samples is hardcore/overkill
        svEK80_tn = transient_noise_filter(svEK80_tt,'EK80',1,40,3,5,0,105,25,7,'NaN',75,[]); % 20,10 is harsh (removes scatter up to 35 m) but clears up the impulse noise better
        svEK80_bn = background_noise_remove_RMS(svEK80_tn,'EK80',1,50,20,-127,1,10,[]);
        svEK80_thr = threshold_backscatter(svEK80_bn,'EK80',1,-125,-45,[],[]);
        log{2,i} = sprintf('Filtering cast %d successful \n',cast_list(i));
    catch err
        log{2,i} = sprintf('Filtering failed for cast %d; Moving to the next cast \n',cast_list(i));
        svEK80_thr = svEK80_casts_f.("C"+sprintf('%d',cast_list(i)));
        %disp(log);
    end
    cast_new = [svEK80_casts.("C"+sprintf('%d',cast_list(i))).(chan).vars.cast_new];
    svEK80_casts_f.(string(cast_id{i})).(chan) = svEK80_thr.(chan);
    svEK80_casts_f.(string(cast_id{i})).(chan).vars = svEK80_thr.(chan).vars;
    svEK80_casts_f.(string(cast_id{i})).(chan).val = svEK80_thr.(chan).val;
    for ii=1:length(cast_new)
        svEK80_casts_f.(string(cast_id{i})).(chan).vars(ii).cast_new = cast_new(ii);
    end
    log{3,i} = sprintf('Saved output for cast %d \n',cast_list(i));
    %disp(log);
end