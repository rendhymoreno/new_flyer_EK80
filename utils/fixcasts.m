function corrected_data = fixcasts(data, tolerance)

casts = unique([data.vars.cast]);

for i = 1:length(casts)
    
    castindex = [data.vars.cast] == casts(i);
    npings = sum(castindex);
    
    start_index = find(castindex == 1, 1, 'first');
    end_index = find(castindex == 1, 1, 'last');
    
    if (npings < tolerance)
        try
            overwrite = num2cell(transpose(casts(i-1) * ones(npings,1)));
            [data.vars(start_index:end_index).cast] = overwrite{:};
        catch
            disp('fix cast error...')
        end
        
    end
end

corrected_data= data;
disp('Fix Cast Data Done')



%%%OLD VERSION WHERE 70 AND 200 BEHAVE DIFFERENTLY 
% 
% function corrected_data = fixcasts(data, tolerance)
% chan70 = 'EKA 264029-0F ES70-18CD';
% 
% channel = data.channel;
% casts = unique([data.vars.cast]);
% 
% for i = 1:length(casts)
%     
%     castindex = [data.vars.cast] == casts(i);
%     npings = sum(castindex);
%     
%     start_index = find(castindex == 1, 1, 'first');
%     end_index = find(castindex == 1, 1, 'last');
%     
%     if (npings < tolerance)
%         if(~strcmp(channel, chan70))
%             try
%                 overwrite = num2cell(transpose(casts(i-1) * ones(npings,1)));
%                 [data.vars(start_index:end_index).cast] = overwrite{:};
%             catch
%                 disp('70khx fix cast error...')
%             end
%         else
%             try
%                 overwrite = num2cell(transpose(casts(i+1) * ones(npings,1)));
%                 [data.vars(start_index:end_index).cast] = overwrite{:};
%             catch
%                 disp('created new cast number, tail');
%                 overwrite = num2cell(transpose(casts(i)+1 * ones(npings,1)));
%                 [data.vars(start_index:end_index).cast] = overwrite{:};
%             end
%         end
%     end
% end
% 
% corrected_data= data;