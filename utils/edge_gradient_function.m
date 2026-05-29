function edge_gradient_data = edge_gradient_function(z, phys_var, med_k, loess_percent, depth_window)

counter =0;
for i=1:max([z.vars.cast])
    
    if( length([z.vars(([z.vars.cast] == i)).depth]) > 5)
        ncast = i;
        callstring  = '[z.vars(([z.vars.cast] == ncast)).';
        depths =[z.vars(([z.vars.cast] == ncast)).depth];
        
        %N2 code
        if(~strcmp(phys_var, "none"))
            if(strcmp(phys_var, 'n2')==1)
                try
                    pot_density=[z.vars(([z.vars.cast] == ncast)).pot_density];
                catch
                    sal=[z.vars([z.vars.cast] == ncast).salinity];
                    temp=[z.vars([z.vars.cast] == ncast).temperature];
                    cons_temp = gsw_CT_from_t(sal,temp , depths);
                    pot_density=gsw_rho(sal, cons_temp, depths);
                end
                [depth_sort, depth_sort_index]= sort(depths);
                pot_density_sorted = pot_density(depth_sort_index);
                pot_density_sorted_spline= csaps(depth_sort, pot_density_sorted,.2,depth_sort);
                try
                    pot_dens_deriv= fnder(spline(depth_sort, pot_density_sorted),1);
                catch
                    [depth_sort, trimindex]= unique(depth_sort);
                    pot_density_sorted = pot_density_sorted(trimindex);
                    pot_dens_deriv= fnder(spline(depth_sort, pot_density_sorted),1);
                end
                pot_dens_deriv=ppval(pot_dens_deriv, depths);
                n2 =(9.8./pot_density).* pot_dens_deriv;
                %                 n2 =csaps(depth_sort, n2,.5, depth_sort);
                n2 =csaps(depths, n2,.5, depths);
                raw_phys = n2;
                norm_phys = (n2-min(n2))/(max(n2)-min(n2));
            else
                if(strcmp(phys_var, 'spice'))
                    sal=[z.vars([z.vars.cast] == ncast).salinity];
                    temp=[z.vars([z.vars.cast] == ncast).temperature];
                    cons_temp = gsw_CT_from_t(sal,temp , depths);
                    spice = gsw_spiciness0(sal, cons_temp);
                    raw_phys=spice;
                    norm_phys=(spice-min(spice))/(max(spice)-min(spice));
                else
                    raw_phys=eval(strcat(callstring, phys_var,']'));
                    norm_phys = (eval(strcat(callstring, phys_var,']')) - min(eval(strcat(callstring, phys_var,']'))))...
                        /(max(eval(strcat(callstring, phys_var,']')))-min(eval(strcat(callstring, phys_var,']'))));
                end
            end
        end
        if(length([z.val(([z.vars.cast] == ncast))]) > med_k*2)
            filt_scatter= medfilt1([z.val(([z.vars.cast] == ncast))],med_k,'omitnan','truncate');
        else
            filt_scatter= [z.val(([z.vars.cast] == ncast))];
        end
        
        %             filt_scatter= medfilt1([z.val(([z.vars.cast] == ncast))],med_k,'omitnan','truncate');
        norm_scatter = ( filt_scatter- min(filt_scatter))/ (max(filt_scatter)- min(filt_scatter));
        %             norm_scatter=filt_scatter; %
        
        %Scattering Derivatives
%         scat_deriv1= gradient( medfilt1(norm_scatter, 10, 'omitnan', 'truncate'));
                    scat_deriv1= gradient(norm_scatter);
        scat_deriv1_norm= (scat_deriv1- min(scat_deriv1))/(max(scat_deriv1)- min(scat_deriv1));
        %             scat_deriv1_norm = scat_deriv1;%
        smooth_deriv1= smooth(scat_deriv1_norm, loess_percent,'loess')';
        %             smooth_deriv1=filter(B,1,scat_deriv1_norm);
        scat_deriv2= gradient(smooth_deriv1);
        %             scat_deriv2= smooth(scat_deriv2, .15, 'loess');
        scat_deriv2_norm= (scat_deriv2- min(scat_deriv2))/(max(scat_deriv2)- min(scat_deriv2));
        %             scat_deriv2_norm = scat_deriv2;%
        
        max_index = floor(median(find(norm_scatter==max(norm_scatter, [],'omitnan'))));
        if(~isnan(max_index))            
            if(~strcmp(phys_var, "none"))
                peak_scatter = [norm_scatter(max_index), depths(max_index), norm_phys(max_index)];
            else
                peak_scatter = [norm_scatter(max_index), depths(max_index), 0];
            end
                       
            depths_above = (depths < depths(max_index) & depths > depths(max_index)-100);
            depths_below = (depths > depths(max_index) & depths < depths(max_index)+100 );
            
            %Physical Derivatives
            if(~strcmp(phys_var, "none"))
                phys_deriv1= gradient( medfilt1(norm_phys, 3, 'omitnan', 'truncate'));
                phys_deriv1_norm= (phys_deriv1- min(phys_deriv1))/(max(phys_deriv1)- min(phys_deriv1));
                %             phys_deriv1_norm =phys_deriv1;
                phys_smooth_deriv1= smooth(phys_deriv1_norm, 0.1,'loess')';
                phys_deriv2= gradient(phys_smooth_deriv1);
                phys_deriv2_norm= (phys_deriv2- min(phys_deriv2))/(max(phys_deriv2)- min(phys_deriv2));
                
                max_index_phys = floor(median(find(norm_phys==max(norm_phys))));
                peak_phys = [norm_scatter(max_index_phys), depths(max_index_phys), norm_phys(max_index_phys)];
                depths_above_phys = (depths < depths(max_index_phys));
                depths_below_phys = (depths > depths(max_index_phys));
            else
                depths_above_phys=1;
                depths_below_phys=1;
            end
            
            %FIND EDGES
            if( sum(depths_above) >0 & sum(depths_below) >0 & sum(depths_above_phys) >0 & sum(depths_below_phys) >0)
                max_deriv_above= find(scat_deriv2_norm==max(scat_deriv2_norm(depths_above)));
                max_deriv_below= find(scat_deriv2_norm==max(scat_deriv2_norm(depths_below)));
                if(~strcmp(phys_var, "none"))
                    upper_edge = [norm_scatter(max_deriv_above), depths(max_deriv_above), norm_phys(max_deriv_above)];
                    lower_edge = [norm_scatter(max_deriv_below), depths(max_deriv_below),  norm_phys(max_deriv_below)];
                else
                    upper_edge = [norm_scatter(max_deriv_above), depths(max_deriv_above),0];
                    lower_edge = [norm_scatter(max_deriv_below), depths(max_deriv_below),  0];
                end
                depths_above_bw = depths < depths(max_index) & depths > upper_edge(2);
                depths_below_bw = depths > depths(max_index) & depths < lower_edge(2);
                
                if(~strcmp(phys_var, "none"))
                    max_deriv_above_phys= find(phys_deriv2_norm==max(phys_deriv2_norm(depths_above_phys)));
                    max_deriv_below_phys= find(phys_deriv2_norm==max(phys_deriv2_norm(depths_below_phys)));
                    upper_edge_phys = [norm_scatter(max_deriv_above_phys), depths(max_deriv_above_phys), norm_phys(max_deriv_above_phys)];
                    lower_edge_phys = [norm_scatter(max_deriv_below_phys), depths(max_deriv_below_phys),  norm_phys(max_deriv_below_phys)];
                    depths_above_bw_phys = depths < depths(max_index_phys) & depths > upper_edge_phys(2);
                    depths_below_bw_phys = depths > depths(max_index_phys) & depths < lower_edge_phys(2);
                else
                    depths_below_bw_phys=1;
                    depths_above_bw_phys=1;
                end
                
                if(sum(depths_above_bw) >0 & sum(depths_below_bw) >0 & sum(depths_below_bw_phys) >0 & sum(depths_above_bw_phys) >0 )
                    counter = counter+1;
                    
                    % Find 10 percent Scatter edges
                    upper_10 = peak_scatter(1) -(.9*(peak_scatter(1) - upper_edge(1)));
                    lower_10 = peak_scatter(1) - (.9*(peak_scatter(1) - lower_edge(1)));
                    [foo, upper_10_ind]= min(abs(norm_scatter(depths_above_bw) - upper_10));
                    [foo, lower_10_ind]= min(abs(norm_scatter(depths_below_bw) - lower_10));
                    % clear foo
                    depths_above_depth=depths(depths_above_bw);
                    depths_below_depth=depths(depths_below_bw);
                    upper_10_depth =depths_above_depth(upper_10_ind);
                    lower_10_depth =depths_below_depth(lower_10_ind);
                    upper_10_ind_all= find(depths==upper_10_depth);
                    lower_10_ind_all= find(depths==lower_10_depth);
                    upper_10_vals = [norm_scatter(upper_10_ind_all) depths(upper_10_ind_all)];
                    lower_10_vals = [norm_scatter(lower_10_ind_all) depths(lower_10_ind_all)];
                    
                    % Find 10 percent Physical edges
                    if(~strcmp(phys_var, "none"))
                        upper_10_phys = peak_phys(3) -(.9*(peak_phys(3) - upper_edge_phys(3)));
                        lower_10_phys = peak_phys(3) - (.9*(peak_phys(3) - lower_edge_phys(3)));
                        [foo, upper_10_ind_phys]= min(abs(norm_phys(depths_above_bw_phys) - upper_10_phys));
                        [foo, lower_10_ind_phys]= min(abs(norm_phys(depths_below_bw_phys) - lower_10_phys));
                        
                        depths_above_depth_phys=depths(depths_above_bw_phys);
                        depths_below_depth_phys=depths(depths_below_bw_phys);
                        upper_10_depth_phys =depths_above_depth_phys(upper_10_ind_phys);
                        lower_10_depth_phys =depths_below_depth_phys(lower_10_ind_phys);
                        upper_10_ind_all_phys= find(depths==upper_10_depth_phys);
                        lower_10_ind_all_phys= find(depths==lower_10_depth_phys);
                        upper_10_vals_phys = [norm_phys(upper_10_ind_all_phys) depths(upper_10_ind_all_phys)];
                        lower_10_vals_phys = [norm_phys(lower_10_ind_all_phys) depths(lower_10_ind_all_phys)];
                    end
                    %                    
                    
                    %WATERFALL FIGURES
                    offset = 2;
                    %                     if(strcmp(z.va
                    figure(1)
                    hold on
                    title('Scatter')
                    plot(norm_scatter+counter/offset, [z.vars(([z.vars.cast] == ncast)).depth])
                    scatter(upper_edge(1)+counter/offset, upper_edge(2),5, 'r','filled')
                    scatter(lower_edge(1)+counter/offset, lower_edge(2),5,'r','filled')
                    scatter(peak_scatter(1)+counter/offset, peak_scatter(2),10,'black','filled')
                    set(gca, 'YDir','reverse')
                    
                    if(~strcmp(phys_var, "none"))
                        figure(2)
                        hold on
                        % subplot(1,3,2)
                        % hold on
                        title(phys_var)
                        plot(norm_phys+counter/offset, [z.vars(([z.vars.cast] == ncast)).depth])
                        scatter(upper_edge_phys(3)+counter/offset, upper_edge_phys(2),5,'r','filled')
                        scatter(lower_edge_phys(3)+counter/offset, lower_edge_phys(2),5,'r','filled')
                        scatter(peak_phys(3)+counter/offset, peak_phys(2),10,'b','filled')
                        scatter(norm_phys(max_index)+counter/offset, peak_scatter(2),10,'black','filled')
                        set(gca, 'YDir','reverse')
                    end
                    
                    sal=[z.vars([z.vars.cast] == ncast).salinity];
                    temp=[z.vars([z.vars.cast] == ncast).temperature];
                    cons_temp = gsw_CT_from_t(sal,temp , depths);
                    spice = gsw_spiciness0(sal, cons_temp);
                    
                    figure(3)
                    hold on
                    title('Spice')
                    plot(spice+counter/offset, depths);
                    scatter(spice(max_index)+counter/offset, peak_scatter(2),10,'black', 'filled')
                    set(gca, 'YDir','reverse')                    
                    
                    upper_gradient = abs((peak_scatter(1)-upper_10_vals(1))/(peak_scatter(2)-upper_10_vals(2)));
                    lower_gradient = abs((peak_scatter(1)-lower_10_vals(1))/(peak_scatter(2)-lower_10_vals(2)));
                    layer_shape = upper_gradient/peak_scatter(1) -lower_gradient/peak_scatter(1)
                    layer_shape_all(counter)=layer_shape;
                    
                    vars=[z.vars(([z.vars.cast] == ncast))];
                    %NEW PHYS GRAD
                    if(~strcmp(phys_var, "none"))
                        phys_upper_gradient = abs((peak_phys(3)-upper_10_vals_phys(1))/(peak_phys(2)-upper_10_vals_phys(2)));
                        phys_lower_gradient = abs((peak_phys(3)-lower_10_vals_phys(1))/(peak_phys(2)-lower_10_vals_phys(2)));
                        phys_layer_shape = phys_upper_gradient/peak_phys(3) -phys_lower_gradient/peak_phys(3)
                        phys_layer_shape_all(counter)=phys_layer_shape;
                        peak_depth_phys(counter) = peak_phys(2);
                        upper_edge_depth_phys(counter) =  upper_edge_phys(2);
                        lower_edge_depth_phys(counter) =  lower_edge_phys(2);
                        peak_phys_raw(counter) = raw_phys(max_index_phys);
                        peak_alongtrack_phys(counter)=vars(max_index_phys).along_track;
                    end
                    
                    
                    o2_peak = vars(max_index).oxygen;
                    o2_upper=vars(max_deriv_above).oxygen;
                    o2_lower=vars(max_deriv_below).oxygen;                                      
                    
                    depth_shape(counter) =((peak_scatter(2)-upper_edge(2))/  lower_edge(2)-(peak_scatter(2)));
                    peak_depth (counter) = peak_scatter(2);
                    peak_cast(counter)=i;
                    
                    vals=[z.val(([z.vars.cast] == ncast))];
                    peak_val(counter)= vals(max_index);
                    
                    peak_oxygen(counter) = vars(max_index).oxygen;
                    peak_alongtrack(counter)=vars(max_index).along_track;
                    upper_edge_depth(counter) =  upper_edge(2);
                    lower_edge_depth(counter) =  lower_edge(2);
                    upper_edge_oxygen(counter) =  vars(max_deriv_above).oxygen;
                    lower_edge_oxygen(counter) =  vars(max_deriv_below).oxygen;
                    spice_maxscatter(counter)=spice(max_index);
                    
                    if(~strcmp(phys_var, "none"))
                        scatter_above= vals(depths < peak_phys(2) & depths >= peak_phys(2)-10);
                        scatter_below= vals(depths > peak_phys(2) & depths <= peak_phys(2)+10);
                        scatter_above_depths = depths(depths < peak_phys(2) & depths >= peak_phys(2)-depth_window);
                        scatter_below_depths = depths(depths > peak_phys(2) & depths <= peak_phys(2)+depth_window);
                        %                 scatter_above = 10.^(scatter_above ./10);
                        %                 scatter_below = 10.^(scatter_below ./10);
                        %                 scatter_above= 10.*log10(mean(scatter_above));
                        %                 scatter_below= 10.*log10(mean(scatter_below));
                        scatter_above= mean(scatter_above);
                        scatter_below= mean(scatter_below);
                        scatter_difference(counter)=scatter_above-scatter_below;
                        try
                            scatter_above_depth_range(counter)= range(scatter_above_depths);
                        catch
                            scatter_above_depth_range(counter)=nan;
                        end
                        try
                            scatter_below_depth_range(counter)= range(scatter_below_depths);
                        catch
                            scatter_below_depth_range(counter)= nan;
                        end
                    end
                    
                    
                end
            end
        end
    end
    %     end
end
figure(1)
hold off
if(~strcmp(phys_var, "none"))
    figure(2)
    hold off
end
figure(3)
hold off


edge_gradient_data.layer_shapes = layer_shape_all;
edge_gradient_data.layer_depths = peak_depth;
edge_gradient_data.layer_casts= peak_cast;
edge_gradient_data.layer_oxygen= peak_oxygen;
edge_gradient_data.layer_scatter = peak_val;
edge_gradient_data.layer_alongtrack=peak_alongtrack;
edge_gradient_data.upper_edge_depth= upper_edge_depth;
edge_gradient_data.lower_edge_depth = lower_edge_depth;
edge_gradient_data.phys_var=phys_var;
if(~strcmp(phys_var, "none"))
    edge_gradient_data.phys_layer_shapes= phys_layer_shape_all;
    edge_gradient_data.phys_layer_depths= peak_depth_phys;
    edge_gradient_data.phys_upper_edge_depth=upper_edge_depth_phys;
    edge_gradient_data.phys_lower_edge_depth=lower_edge_depth_phys;
    edge_gradient_data.phys_layer_value=peak_phys_raw;
    edge_gradient_data.phys_alongtrack = peak_alongtrack_phys;
    edge_gradient_data.scatter_difference=scatter_difference;
    edge_gradient_data.scatter_above_depth_range=scatter_above_depth_range;
    edge_gradient_data.scatter_below_depth_range=scatter_below_depth_range;
end

