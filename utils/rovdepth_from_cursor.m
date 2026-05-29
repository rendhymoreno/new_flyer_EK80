
function rovdepth_from_cursor(cursor_data,EK80path,es60,es60_chan,outpath)
%load position data
%load('E:\2023_Bermuda\processed\payload_pos_raw.mat');
%load('E:\2023_Bermuda\processed\global_index.mat');
%ctdFname = 'E:\2023_Bermuda\processed\ctd_interpolation.mat'; %interpolated
%ctdFname = 'E:\2023_Bermuda\processed\7182023_payload.mat'; %StarODDI

ch_es60 = fieldnames(es60);
fprintf('[Sync ES60 & EK80] Reading ES60 channel: %s \n',ch_es60{es60_chan});

if es60_chan > length(ch_es60)
    error('[Sync ES60 & EK80] Channel selected is not available in ES60 data')
end

load(EK80path);
load(cursor_data);
[x, x_index] = unique(payload_pos_raw(:,1));
y = payload_pos_raw(:,2);
t_start = es60.(ch_es60{es60_chan}).time(1);
t_end = es60.(ch_es60{es60_chan}).time(end);
F = griddedInterpolant(x,y(x_index));

sizet = length([global_indexer.timestamp]);
xq = linspace(t_start,t_end,sizet);
yq = F(xq);

if ~strcmp(outpath(end),'\')
    ctdFname = append(outpath,'\ctd_interpl.mat');
else
    ctdFname = append(outpath,'ctd_interpl.mat');
end

ctd_interp.time_utc = xq';
ctd_interp.pressure = yq';
save(ctdFname,'-struct','ctd_interp');

%optional plot of new interpolated values
%fig2 = figure();
%plot(xq, yq,'.')
%hold on
%plot(x,y,'ro')
%set(gca,'YDir','reverse');
%title('interpolated ROV time vs depth');

plotEk_Echogram_Niskin(svES60,ctdFname,[],{0 300},[],[-77 -36; -74 -35])
%plotEk_Echogram_Niskin(svEK80,[],event_dn,{0 'inf'},[],[-80 -60; -50 -30])
%hold on
%for i = 1:length(event_dn)
%    plot([event_dn(i) event_dn(i)],[0 300],'--k','LineWidth',1.5)
%end

end