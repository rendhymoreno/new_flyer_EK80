function n2_data = calculate_n2(data_in)

n2_data=data_in; 
casts=unique([data_in.vars.cast]);

for i=1:length(casts)
    depths=[data_in.vars([data_in.vars.cast] == casts(i)).depth];
    sal=[data_in.vars([data_in.vars.cast] == casts(i)).salinity];
    temp=[data_in.vars([data_in.vars.cast] == casts(i)).temperature];
    
    ncast=casts(i);
    
    depths =[data_in.vars(([data_in.vars.cast] == ncast)).depth];
    
    try
        pot_density=[data_in.vars(([data_in.vars.cast] == ncast)).pot_density];
    catch
        sal=[data_in.vars([data_in.vars.cast] == ncast).salinity];
        temp=[data_in.vars([data_in.vars.cast] == ncast).temperature];
        cons_temp = gsw_CT_from_t(sal, temp, depths);
        pot_density=gsw_rho(sal, cons_temp, depths);
    end
    [depth_sort, depth_sort_index]= sort(depths);
    pot_density_sorted = pot_density(depth_sort_index);
%     pot_density_sorted_spline= csaps(depth_sort, pot_density_sorted,.2,depth_sort);
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
    
    n2=num2cell(n2);
    [n2_data.vars([n2_data.vars.cast] == ncast).n2]=n2{:};
    
end
