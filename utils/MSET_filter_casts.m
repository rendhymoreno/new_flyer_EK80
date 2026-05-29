function [dataout,log] = MSET_filter_casts(datain,ch,cast_list) 

fn = fieldnames(datain);
fn = char(fn{1});
plot_fig = 0;
if strcmp(fn(1:4),'chan')
    chan = fieldnames(datain);
    if ch == 1
        fprintf('[Cast Bulk Filter] Reading data from channel 1: %s \n',chan{1});
        chan = chan(1);
    elseif ch == 2
        fprintf('[Cast Bulk Filter] Reading data from channel 2: %s \n',chan{2});
        chan = chan(2);
    else
        fprintf('[Cast Bulk Filter] Reading data from all %i channels\n',length(chan));
    end
    if sum(ismember(fieldnames(datain.(fn).vars),'cast_new')) == 0
        [datain,cl,ci] = flyer_cast_idx(datain, 1); % obtain casts and fix the cast numbering
        datain = flyer_query_castData(datain, 1, ci, cl);
    else
        datain = flyer_query_castData(datain, 1, [], []);
    end
    cast_id = fieldnames(datain);
else
    chan = string(fieldnames(datain.(string((cast_id{1})))));
end

log = cell(3,numel(cast_list));

for ii = 1:length(chan)
    for i = 1:numel(cast_list)

        try
            %in_out = impulse_noise_filter(datain.("C"+sprintf('%d',cast_list(i))),'EK80',1,40,2,5,0,105,'NaN',[],[],[]); %threshold works better with 7, 40 samples is hardcore/overkill
            %tn = transient_noise_filter(datain.("C"+sprintf('%d',cast_list(i))),'EK80',1,20,20,20,0,105,25,7,'NaN',120,[]); %20,10,5 depth:120
            bn = background_noise_remove_RMS(datain.("C"+sprintf('%d',cast_list(i))),'EK80',1,50,20,-127,[],10,[]);
            %plotEk_Echogram_Niskin(datain.("C"+sprintf('%d',cast_list(i))),1,[],[],{0 'inf'},[],[-80 -40],'EK80 filt',[]);
            %plotEk_Echogram_Niskin(bn,1,[],[],{0 'inf'},[],[-80 -40],'EK80 filt',[]);
            thr = threshold_backscatter(bn,'EK80',1,-125,-45,[],[]);
            log{2,i} = sprintf('Filtering cast %d successful \n',cast_list(i));
            disp(log{2,i});

            outdata.("C"+sprintf('%d',cast_list(i))) = datain.("C"+sprintf('%d',cast_list(i)));
            outdata.("C"+sprintf('%d',cast_list(i))).(chan{ii}) = thr.(chan{ii});
            outdata.("C"+sprintf('%d',cast_list(i))).(chan{ii}).vars = thr.(chan{ii}).vars;
            outdata.("C"+sprintf('%d',cast_list(i))).(chan{ii}).val = thr.(chan{ii}).val;

            log{3,i} = sprintf('Saved output for cast %d \n',cast_list(i));
            disp(log{3,i});
        catch err
            log{2,i} = sprintf('Filtering failed for cast %d; Moving to the next cast \n',cast_list(i));
            %data_thr = outdata.("C"+sprintf('%d',cast_list(i)));
            outdata.("C"+sprintf('%d',cast_list(i))) = datain.("C"+sprintf('%d',cast_list(i)));
            disp(log{2,i});
        end

        %disp(log);
    end
end

dataout = flyer_combine_casts(outdata);
%datain = flyer_combine_casts(datain);
log = cell2table(log);

if plot_fig == 1
    plotEk_Echogram_Niskin(datain.("C"+sprintf('%d',cast_list(i))),1,[],[],{0 'inf'},[],[-80 -40],'EK80 orig',[]);
    plotEk_Echogram_Niskin(dataout,1,[],[],{0 'inf'},[],[-80 -40],'EK80 filt',[]);
    %plotEk_Echogram_Niskin(svEK80_flyer_IN,1,[],[],{0 'inf'},[],[-70 -39],'EK80 original',[]);
end

end