% data = svES60;
% chan = fieldnames(data);
% channel = 1;
% depthfile = load(payload_depth);
% threshold = -60;
% plot_fig = 1;
% depth_band = 3;

function data_filt = payload_scatter_filter(data,channel,depthfile,depth_band,threshold,plot_fig)

if isstring(depthfile) || ischar(depthfile)
    depthfile = load(depthfile);
else
    depthfile;
end

if isfield(depthfile,'time_utc') %Bermuda "corrected depth"
    payload_depth = depthfile.pressure;
    payload_t = depthfile.time_utc;
    fprintf('[Payload Scatter Filter] Detected StarOddi Depth Input\n');
elseif isfield(depthfile,'global_indexer') %Flyer file with "corrected depth"
    payload_depth = [depthfile.global_indexer.depth];
    payload_t = [depthfile.global_indexer.timestamp];
    fprintf('[Payload Scatter Filter] Detected Flyer Depth Input\n');
elseif size(depthfile,2) == 2
    depthfile = sortrows(depthfile);
    payload_t = depthfile(:,1);
    payload_depth = depthfile(:,2);
end

chan = fieldnames(data);
if channel == 1
    lg = sprintf('[Payload Scatter Filter] Reading data from channel 1: %s ',chan{1});
    disp(lg)
    chan = chan(1);
elseif channel == 2
    lg = sprintf('[Payload Scatter Filter] Reading data from channel 2: %s ',chan{2});
    disp(lg)
    chan = chan(2);
else
    lg = sprintf('[Payload Scatter Filter] Reading data from all %i channels',length(chan));
    disp(lg)
end


for n=1:length(chan)
    r = data.(chan{n}).range;
    dr = r(2)-r(1);
    rbin = ceil(depth_band/dr);
    t = data.(chan{n}).time';

    if isfield(data.(chan{n}),'Sv')
        datain = data.(chan{n}).Sv;
        dataflag = 'Sv';
    elseif isfield(data.(chan{n}),'TS')
        datain = data.(chan{n}).TS;
        dataflag = 'TS';
    end

    %% Range indexing and filtering
    %Subset t
    tsb_m = t > payload_t(1) & t < payload_t(end);
    tsb_idx = find(tsb_m==1);
    t = t(tsb_m);
    t_index = dsearchn(payload_t,t);

    %filtered = zeros(size(datain,1),size(datain,2));
    for i = 1:length(t)
        p_d = payload_depth(t_index(i));
        r_index = dsearchn(r',p_d);
        if r_index-rbin > 0
            r_index = r_index-rbin:1:r_index+rbin;
        elseif r_index+rbin > length(r)
            r_index = r_index-rbin:1:length(r);
        elseif r_index-rbin < 0
            r_index = 1:1:r_index+rbin;
        end
        %filtered(r_index,i) = datain(r_index,i);
        filtered = datain(r_index,tsb_idx(i));
        filtered(filtered > threshold) = NaN;
        datain(r_index,tsb_idx(i)) = filtered;
    end

    data_filt.(chan{n}) = data.(chan{n});
    if strcmp(dataflag,'Sv')
        data_filt.(chan{n}).Sv = datain;
    else
        data_filt.(chan{n}).TS = datain;
    end
    
    fprintf('[Payload Scatter Filter] Removed payload scatter noise\n');

    if plot_fig == 1
        %plotEk_Echogram_Niskin(data,channel,ctdpath,eventdn,range,timelength,crange,plt_title,export1)
        plotEk_Echogram_Niskin(data,n,[],[],{0 'inf'},[],[-77 -36; -74 -35],'Original Data',[])
        plotEk_Echogram_Niskin(data_filt,n,[],[],{0 'inf'},[],[-77 -36; -74 -35],'Payload backscatter filtered',[])
    end

end

end