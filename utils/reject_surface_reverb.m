function data = reject_surface_reverb(datain, tri_min_depth, tri_max_depth)
data= datain;
subset_index=[data.vars.depth] > tri_min_depth & [data.vars.depth] < tri_max_depth; %flyer depth
subset_data= data.val(:,subset_index);
subset_range= data.range(:,subset_index);
subset_depth= [data.vars(subset_index).depth]; 
shallow_ind=[data.vars.depth] < tri_min_depth ;
[data.val(:, shallow_ind)]=nan; %sets all values under min flyer depth to NaN

if(~isempty(subset_data))
    for i=1:size(subset_data,1)
        for j=1:size(subset_data,2)
            if(subset_depth(j) > tri_min_depth & subset_depth(j) < tri_max_depth)
                if(subset_range(i,j) > calc_surface_rejection(tri_min_depth,tri_max_depth, subset_depth(j))) %determines the depth where reverbs hit the surface depending on position of flyer depth and ek80 range (larger range => larger area ensonified)
                    out_val(i,j) =  nan;
                else
                    out_val(i,j) = subset_data(i,j);
                end
            end
        end
        
        if(mod(i, 50)==0)
            disp(100*i/size(data.val,1));
        end
    end
    [data.val(:, subset_index)]=out_val;
end
data.surf_rej = strcat(num2str(tri_min_depth),',', num2str(tri_max_depth));
disp('Reject Surface Reverb Done')







