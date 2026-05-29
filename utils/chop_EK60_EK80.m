function dataout = chop_EK60_EK80(data,rangevector,timevector,varargin)
%data
chan = fieldnames(data);
if isfield(data.(chan{1}),'Sv')
    trans = 'EK60';
else
    trans = 'EK80';
end

rflag = 1;
tflag = 1;

if exist(varargin,'var') & strcmp(varargin{1},'casts') & ~isempty(varargin{2})
    fn = char(fieldnames(data));
    fn = char(fn(1,1:end));
    if strcmp(fn(1:4),'chan')
        [datain,~,~] = flyer_cast_idx(data, 1);
        datain = flyer_query_castData(datain, 1, [], []);
    end
    cast_list = fieldnames(datain);
    for k=1:length(cast_list)
        cast_num(k) = str2double(cast_list{k}(2:end));
    end
    cast_plt_idx = ~ismember(cast_num,varargin{2});
    cast_proc2 = cast_list(cast_plt_idx);
    data_proc = rmfield(datain,cast_proc2);
    data = flyer_combine_casts(data_proc);
    chan = fieldnames(data);
    cflag = 1;
else
    cflag = 0;
end

if ~isempty(rangevector)
    min_r = rangevector(1);
    max_r = rangevector(2);
    fprintf('[Chop EK60/EK80] Removing values outside of range %i and %i\n',min_r,max_r)

else
    rflag = 0;
end

if ~isempty(timevector)
    if isdatetime(timevector)
        fprintf('[Chop EK60/EK80] Removing values outside %s to %s\n',timevector(1),timevector(2))
        min_t = datenum(timevector(1));
        max_t = datenum(timevector(2));
    else
        min_t = timevector(1);
        max_t = timevector(2);
        dt_t = datetime(timevector,"ConvertFrom","datenum");
        fprintf('[Chop EK60/EK80] Removing values outside %s to %s\n',dt_t(1),dt_t(2))
    end
else
    tflag = 0;
end

if rflag ~= 0 || tflag ~= 0 || cflag ~= 0
 
    for ch = 1:length(chan)
        if strcmp(trans,'EK60')
            datain = data.(chan{ch}).Sv;
            range = data.(chan{ch}).range;
            time = data.(chan{ch}).time;
            cal = data.(chan{ch}).cal;
        elseif strcmp(trans,'EK80')
            datain = data.(chan{ch}).val;
            range = [data.(chan{ch}).range]';
            time = [data.(chan{ch}).vars.timestamp];
            time_dn = datenum(datetime(time,"ConvertFrom","epochtime","TicksPerSecond",1e6));
            vars = [data.(chan{ch}).vars];
            if ch == 1
                dataout = data;
            end
        end

        if tflag ~= 0
            if strcmp(trans,'EK80')
                ind_t1 = dsearchn(time_dn', min_t);
                ind_t2 = dsearchn(time_dn', max_t);
            else
                ind_t1 = dsearchn(time', min_t);
                ind_t2 = dsearchn(time', max_t);
            end
        else
            ind_t1 = 1;
            ind_t2 = length(time);
        end

        if rflag ~= 0
            ind_r1 = dsearchn(range', min_r);
            ind_r2 = dsearchn(range', max_r);
        else
            ind_r1 = 1;
            ind_r2 = length(range);
        end
        if strcmp(trans,'EK60')
            dataout.(chan{ch}).range = range(ind_r1:ind_r2);
            dataout.(chan{ch}).time = time(ind_t1:ind_t2);
            dataout.(chan{ch}).Sv = datain(ind_r1:ind_r2,ind_t1:ind_t2);
            dataout.(chan{ch}).cal = cal;
            fprintf('[Chop EK60/EK80] Finished reshaping channel: %s\n',chan{ch})
        else
            new_vars = [vars(ind_t1:ind_t2)];
            dataout.(chan{ch}).vars = new_vars;
            dataout.(chan{ch}).val = datain(ind_r1:ind_r2,ind_t1:ind_t2);
            dataout.(chan{ch}).range = range(ind_r1:ind_r2)';
            fprintf('[Chop EK60/EK80] Finished reshaping channel: %s\n',chan{ch})
        end
    end
else
    error('[Chop EK60/EK80] Chopping cannot be done due to unknown input')
end

end