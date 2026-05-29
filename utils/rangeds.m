function data = rangeds(indata, minrange, maxrange, binsize)

data=indata;
if(size(unique(data.range(2,:)),1))
    static_range= 1;
else
    static_range=0;
end
for i = 1 : size(data.range,2)
    ping_range = data.range(:,i);
    ping_data = data.val(:,i);
    
    if(~strcmp(indata.type,'athwartship') & ~strcmp(indata.type,'alongship'))
        ping_data = 10.^(ping_data ./10);
    end
    
    start_ind = dsearchn(ping_range, minrange);
    end_ind = dsearchn(ping_range, maxrange);
    
    ping_data = ping_data(start_ind:end_ind);
    ping_range =ping_range(start_ind:end_ind);   
    
    if(binsize > 0)
        ls = minrange:binsize:maxrange;
        if(ls(length(ls)) ~= maxrange)
            ls(1+length(ls)) = maxrange;
        end
        
        for j = 2:length(ls)
            index = ping_range > ls(j-1) & ping_range <= ls(j);
            ping_data_index =ping_data(index);
            ping_data_index(ping_data_index ==0) = NaN;
            if(~strcmp(indata.type,'athwartship') &  ~strcmp(indata.type,'alongship'))
                value(j-1,i) = 10.*log10(mean(ping_data_index,1, 'omitnan'));
            else
                value(j-1,i) = mean(ping_data_index,1, 'omitnan');
            end
            if(static_range==1)
                if(i==1)
                    range(j-1,i)= mean(ping_range(index),1, 'omitnan');
                end
            else
                range(j-1,i)= mean(ping_range(index),1, 'omitnan');
            end
        end
    else
        if(~strcmp(indata.type,'athwartship') &  ~strcmp(indata.type,'alongship'))
            value(:,i) =10.*log10(ping_data);
        else
            value(j-1,i) = ping_data;
        end
        range(:,i) =ping_range;
    end
    if(mod(i, 100)==0)
        display(100*i/size(data.range,2));
    end
end

if(static_range==1)
    range=repmat(range, size(range,2), size(value, 2));
end
data.val=value;
data.range=range;
data.range_avg = strcat(num2str(minrange), ',', num2str(maxrange), ',', num2str(binsize));


disp('Range DS Done')



%old way
%     ls= 1:ds:length(ping_range);
%     if(ls(length(ls)) ~= length(ping_range))
%         ls(1+length(ls)) = length(ping_range);
%     end
%
%     for(j = 2:length(ls))
%         value(j-1,i)= mean(ping_data(ls(j-1):ls(j)),1);
%         range(j-1,i) =mean(ping_range(ls(j-1):ls(j)),1);
%     end