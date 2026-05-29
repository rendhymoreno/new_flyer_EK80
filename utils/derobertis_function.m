function dsdata = derobertis_function(data, k_ping, l_range, max_noise)

%k_ping = # of pings TB averaged
%l_range = distance in m

casts = unique([data.vars.cast]);
dsdata=data;
for i = 1:length(casts)
    cast_index = [data.vars.cast] == casts(i);   
    start_ping= find(cast_index, 1, 'first');
    end_ping = find(cast_index, 1, 'last');
    
    index_pings = data.val(:, cast_index);
    absorption = unique([data.vars.absorptionCoeff]); 
    startTVG = unique([data.vars.TVGStart]);
    range_vec= data.range(:,1);
    tvg20_range=range_vec .*(range_vec > startTVG);
    tvg20_term= 20*log10(tvg20_range)  + 2*tvg20_range*absorption;
    tvg20_term(tvg20_term==-inf)=0;
    
    power_cal = index_pings - tvg20_term;
    power_cal = 10.^(power_cal./10);
    
    DEPTHS = [data.vars(cast_index).depth];
    
    %ping ds
    ls_k= 1:k_ping:size(index_pings,2)+1;
    if(ls_k(length(ls_k)) ~= size(index_pings,2)+1)
        ls_k(1+length(ls_k)) = size(index_pings,2)+1;
    end
    
    for j = 2:length(ls_k)
        val_ds(:, j-1)= mean(power_cal(:,ls_k(j-1):ls_k(j)-1),2, 'omitnan');
        DEPTHS_PING(j-1) = mean(DEPTHS(ls_k(j-1):ls_k(j)-1)); 
    end
    
    %range ds
    ls_l = min(range_vec):l_range:max(range_vec);
    if(ls_l(length(ls_l)) ~= max(range_vec))
        ls_l(1+length(ls_l)) = max(range_vec);
    end
    for(j=1:size(val_ds,2))
        ping_val_ds = val_ds(:,j);
        for h = 2:length(ls_l)
            rbin_index = range_vec > ls_l(h-1) & range_vec <= ls_l(h);
            if(j==1 && h==2)
%                 if(h==2)
%                     rbin_index_raw=rbin_index;
                    rbin_index(1)=1;
%                 else
%                     rbin_index_raw = rbin_index_raw + (h-1)*rbin_index;
%                 end
            end
            val_ds_kl(h-1,j)= mean(ping_val_ds(rbin_index), 'omitnan');
        end
    end
    
    noise_k =  min(val_ds_kl);
    noise_k =10*log10(noise_k);
    noise_k(noise_k > max_noise) = max_noise;    
    Sv_noise = noise_k +tvg20_term; 

    
    for j = 2:length(ls_k)
        pings_k =index_pings(:,ls_k(j-1):ls_k(j)-1);
%         snr = pings_k-repmat(Sv_noise(:,j-1),1,size(pings_k,2));
        pings_k = 10.^(pings_k./10);
        %       tvg_pings = repmat(tvg20_term,1,size(pings_k,2));
        %       tvg_pings = tvg_pings +  ones(size(pings_k)).*noise_k(j-1);
        tvg_pings = repmat(Sv_noise(:,j-1),1,size(pings_k,2));
        tvg_pings = 10.^(tvg_pings./10);
        Sv_corr = pings_k- tvg_pings;
        Sv_corr(Sv_corr < 0) = 0;
        Sv_corr = 10*log10(Sv_corr);
%         pings_k(pings_k == -inf) = -999;
        Sv_corr(Sv_corr == -inf) = nan;
        snr = Sv_corr - 10*log10(tvg_pings);

      if(j==2)
          out_snr = snr;
          out_pings = Sv_corr; 
      else
          out_snr = [out_snr snr];
          out_pings = [out_pings Sv_corr];
      end
      
          
      
%       figure
%       hist(10*log10(power_cal(:)), 100)
%       figure
%       hist(10*log10(val_ds(:)), 100)
%       title('valds')
      
      
%HERE
      %      noise_k(ls_k(j-1):ls_k(j)-1) 
%         val_ds(:, j-1)= mean(power_cal(:,ls_k(j-1):ls_k(j)-1),2);
    end
    [dsdata.val(:,start_ping:end_ping)] = out_pings;
    
    if(i==1)
        snr_all=out_snr;
       DEPTHS_ALL= DEPTHS_PING;
       noise_estimates = noise_k;
    else
        snr_all=[snr_all out_snr]; 
        DEPTHS_ALL= [DEPTHS_ALL DEPTHS_PING];
        noise_estimates = [noise_estimates noise_k]; 
    end
    
    clear val_ds_kl val_ds DEPTHS_PING 

%     for(j = 1:length(unique(rbin_index_raw)))
%        index_tvg = rbin_index_raw==j;  
%        ind_start= find(index_tvg,1, 'first');
%        ind_end=find(index_tvg,1, 'last');
%        Sv_noise(ind_start:ind_end)  = noise_k +  tvg20_term(index_tvg) ;
%     end
        
    %%range ds
%     Sv_noise_arith = 10.^(Sv_noise./10);
%     index_pings = 10.^(index_pings./10); 
%     diff_ping_noise= index_pings-Sv_noise_arith; 
%     diff_ping_noise(diff_ping_noise < 0) = 0; 
%     diff_ping_noise =10.*log10(diff_ping_noise);
%     diff_ping_noise(diff_ping_noise == -inf) = -999;

%      sv_cal = 10*log10(); 
%     [dsdata.val(:,start_ping:end_ping)] = out_snr; 

    
    

    
    disp(100*i/length(casts));
end

disp('DeRobertis Function Done')
% figure
% dsdata.noise=noise_estimates; 
% dsdata.depth=DEPTHS_ALL; 
% dsdata.snr=snr_all; 

% scatter(noise_estimates, DEPTHS_ALL);


