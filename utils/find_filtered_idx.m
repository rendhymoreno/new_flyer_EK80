function rem_idx = find_filtered_idx(datain,chnum)

% Sv data: removed data is -999
chan = fieldnames(datain);

%dt_raw = [datain.(chan{chnum}).vars.timestamp];
%dt = datetime(dt_raw,"ConvertFrom","epochtime","TicksPerSecond",1e6);
valEK80 = [datain.(chan{chnum}).val];
%range = [svEK80_final_thr.(chan{chnum}).range];
rem_idx = (valEK80 == -999) | isnan(valEK80);

end