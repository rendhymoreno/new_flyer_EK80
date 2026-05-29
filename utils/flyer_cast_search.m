function castnum = flyer_cast_search(datain,ch,timeq)
    
    chan = fieldnames(datain);
    vars = [datain.(chan{ch}).vars];
    cast_dt = datetime([vars.timestamp],"ConvertFrom","epochtime","TicksPerSecond",1e6)';
    cast_dn = datenum(cast_dt);

    if ~iscell(timeq)
        timeq_dn = datenum([timeq]);
    else
        timeq_dn = datenum([timeq{:}]);
    end
    
    idx_s = dsearchn(cast_dn,timeq_dn');

    if isfield(vars,'cast_new')
        castnum = [vars(idx_s).cast_new];
    else
        castnum = [vars(idx_s).cast];
    end
    
end
