function dsdata = pingds(data, mindepth, maxdepth, ds)

casts = unique([data.vars.cast]);
counter=0;
var_names = fieldnames(data.vars);

for i = 1:length(casts)
    castindex = [data.vars.cast] == casts(i);
    depthindex = [data.vars.depth] >= mindepth & [data.vars.depth] <= maxdepth;
    castindex = and(castindex, depthindex);
    survivedpings = sum(castindex);
    
    if(survivedpings >= ds)
        
        cast_pings = data.val(:, castindex);
%         if(strcmp(indata.type,'sv_pc') || strcmp(indata.type,'sv_cw') || strcmp(indata.type,'ts_cw') || strcmp(indata.type,'ts_pc') || strcmp(indata.type,'power_pc') || strcmp(indata.type,'power_cw'))
            cast_pings = 10.^(cast_pings ./10);
%         end
        cast_ranges = data.range(:, castindex);
        cast_vars = data.vars(:, castindex);
        
        if(ds == 1)
            val_ds(:,counter+1:counter+length(cast_vars))=10.*log10(cast_pings);
            range_ds(:,counter+1:counter+length(cast_vars))=cast_ranges;
            vars_ds(:,counter+1:counter+length(cast_vars))=cast_vars;
            counter = counter + length(cast_vars);
        else
            
            ls= 1:ds:length(cast_vars);
            if(ls(length(ls)) ~= length(cast_vars))
                ls(1+length(ls)) = length(cast_vars);
            end
            
            for j = 2:length(ls)
%                 if(strcmp(indata.type,'sv_pc') || strcmp(indata.type,'sv_cw') || strcmp(indata.type,'ts_cw') || strcmp(indata.type,'ts_pc') || strcmp(indata.type,'power_pc') || strcmp(indata.type,'power_cw'))
                    val_ds(:,counter+ j-1)= 10.*log10(mean(cast_pings(:,ls(j-1):ls(j)),2));
%                 else
%                     val_ds(:,counter+ j-1)= mean(cast_pings(:,ls(j-1):ls(j)),2);
%                 end
                range_ds(:,counter+ j-1)= mean(cast_ranges(:,ls(j-1):ls(j)),2);
                
                for h = 1:length(var_names)
                    temp_var = eval(strcat('transpose([cast_vars(ls(j-1):ls(j)).', var_names{h},'])'));
                    vars_ds(counter + j-1).(var_names{h}) = mean(temp_var,1);
                end
            end
            
            counter=counter+length(ls)-1;
        end
        disp(100*i/length(casts))
    end
end

dsdata= data;
dsdata.ping_avg = strcat(num2str(mindepth),',',num2str(maxdepth),',', num2str(ds));

if(exist('val_ds', 'var'))
    dsdata.val = val_ds;
    dsdata.range = range_ds;
    dsdata.vars = vars_ds;
else
    disp('no changes to data made using ping ds settings');
end



% function dsdata = pingds(data, mindepth, maxdepth, ds)
% 
% casts = unique([data.vars.cast]);
% counter=0;
% var_names = fieldnames(data.vars);
% 
% for i = 1:length(casts)
%     castindex = [data.vars.cast] == casts(i);
%     depthindex = [data.vars.depth] >= mindepth & [data.vars.depth] <= maxdepth;
%     castindex = and(castindex, depthindex);
%     survivedpings = sum(castindex);
%     
%     if(survivedpings >= ds)
%         
%         cast_pings = data.val(:, castindex);
%         cast_ranges = data.range(:, castindex);
%         cast_vars = data.vars(:, castindex);
%         
%         if(ds == 1)
%             val_ds(:,counter+1:counter+length(cast_vars))=cast_pings;
%             range_ds(:,counter+1:counter+length(cast_vars))=cast_ranges;
%             vars_ds(:,counter+1:counter+length(cast_vars))=cast_vars;
%             counter = counter + length(cast_vars);
%         else            
%             
%             ls= 1:ds:length(cast_vars);            
%             if(ls(length(ls)) ~= length(cast_vars))
%                 ls(1+length(ls)) = length(cast_vars);
%             end
%             
%             for j = 2:length(ls)
%                 val_ds(:,counter+ j-1)= mean(cast_pings(:,ls(j-1):ls(j)),2);
%                 range_ds(:,counter+ j-1)= mean(cast_ranges(:,ls(j-1):ls(j)),2);
%                 
%                 for h = 1:length(var_names)
%                     temp_var = eval(strcat('transpose([cast_vars(ls(j-1):ls(j)).', var_names{h},'])'));
%                     vars_ds(counter + j-1).(var_names{h}) = mean(temp_var,1);
%                 end
%             end  
%             
%             counter=counter+length(ls)-1;
%         end
%         disp(100*i/length(casts))
%     end
% end
% 
% dsdata= data;
% dsdata.ping_avg = strcat(num2str(mindepth),',',num2str(maxdepth),',', num2str(ds)); 
% 
% if(exist('val_ds', 'var'))
%     dsdata.val = val_ds;
%     dsdata.range = range_ds;
%     dsdata.vars = vars_ds;
% else
%    disp('no changes to data made using ping ds settings');  
% end
