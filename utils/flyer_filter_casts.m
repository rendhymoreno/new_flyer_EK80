function [dataout,log] = flyer_filter_casts(datain,angle,ch,cast_list,in_method) 

fn = fieldnames(datain);
fn = char(fn{1});

if strcmp(fn(1:4),'chan')
    chan = fieldnames(datain);
    if ch == 1
        fprintf('[IN Filter] Reading data from channel 1: %s \n',chan{1});
        chan = chan(1);
    elseif ch == 2
        fprintf('[IN Filter] Reading data from channel 2: %s \n',chan{2});
        chan = chan(2);
    else
        fprintf('[IN Filter] Reading data from all %i channels\n',length(chan));
    end

    [datain,cl,ci] = flyer_cast_idx(datain, 1); % obtain casts and fix the cast numbering
    datain = flyer_query_castData(datain, 1, ci, cl);
    cast_id = fieldnames(datain);
else
    chan = string(fieldnames(datain.(string((cast_id{1})))));
end

log = cell(3,numel(cast_list));

for ii = 1:length(chan)
    for i = 1:numel(cast_list)

        try
            log{1,i} = sprintf('Filtering cast %d \n',cast_list(i));
            disp(log{1,i});
            if strcmp(in_method,'iter')
            %samp_win = [100, 80, 60, 40, 20]; %FOr 70 works well
            samp_win = [500, 300, 200, 140, 100]; %FOr 200
            for jj=1:5
                if jj == 1
                    in_out = datain.("C"+sprintf('%d',cast_list(i)));
                end
                in_in = in_out;
                in_out = impulse_noise_filter(in_in,'EK80',1,samp_win(jj),2,5,0,105,'NaN',[],[],[]); %100 good
            end
            elseif strcmp(in_method,'single')
                in_out = impulse_noise_filter(datain.("C"+sprintf('%d',cast_list(i))),'EK80',1,40,2,5,0,105,'NaN',[],[],[]); %threshold works better with 7, 40 samples is hardcore/overkill
            end
            %data_TN = transient_noise_filter(in_out,'EK80',1,40,3,5,0,105,25,7,'NaN',0,[]); % 20,10 is harsh (removes scatter up to 35 m) but clears up the impulse noise better
            %data_surf = flyer_filter_Surface(data_TN, angle, cast_list, [-77 -45], 'kmeans', []); %svEK80_flyer_surf
            data_BN = background_noise_remove_RMS(in_out,'EK80',1,40,20,-125,1,10,[]);
            data_thr = threshold_backscatter(data_BN,'EK80',1,-70,-45,[],[]);
            log{2,i} = sprintf('Filtering cast %d successful \n',cast_list(i));
            disp(log{2,i});

            outdata.("C"+sprintf('%d',cast_list(i))) = datain.("C"+sprintf('%d',cast_list(i)));
            %cast_new = [datain.("C"+sprintf('%d',cast_list(i))).(chan).vars.cast_new];
            outdata.("C"+sprintf('%d',cast_list(i))).(chan{ii}) = data_thr.(chan{ii});
            outdata.("C"+sprintf('%d',cast_list(i))).(chan{ii}).vars = data_thr.(chan{ii}).vars;
            outdata.("C"+sprintf('%d',cast_list(i))).(chan{ii}).val = data_thr.(chan{ii}).val;

            % for ii=1:length(cast_new)
            %     outdata.(string(cast_id{i})).(chan).vars(ii).cast_new = cast_new(ii);
            % end
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
log = cell2table(log);

end
% plotEk_Echogram_Niskin(datain.("C"+sprintf('%d',cast_list(i))),1,[],[],{0 'inf'},[],[-77 -45],'Original',[]);
% plotEk_Echogram_Niskin(data_IN,1,[],[],{0 'inf'},[],[-77 -45],'IN single',[]); 
% plotEk_Echogram_Niskin(in_out,1,[],[],{0 'inf'},[],[-77 -45],'Iterative IN',[]);
% plotEk_Echogram_Niskin(data_TN,1,[],[],{0 'inf'},[],[-77 -45],'TN',[]);