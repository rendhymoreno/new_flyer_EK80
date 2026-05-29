function [trk_fin,svEK80_out] = sync_gps2EKping(svEK80,gps_trk)

chan = fieldnames(svEK80);
% Remove double timestamps (Hawaii 12-May-2025 had some)
gps_trk = unique(gps_trk);

for ii=1:length(chan)
    fprintf('[Sync GPS for EK] Processing Chan %d %s\n',ii,chan{ii})
    time_dt = datetime([svEK80.(chan{ii}).vars.timestamp],"ConvertFrom","datenum","TimeZone","UTC");
    %range_ea = [sv_20250505.(chan{ch}).range];

    % Finding nearest index of gps time to EK time and subset the GPS track
    idx_s = find(gps_trk.Time == interp1(gps_trk.Time,gps_trk.Time,time_dt(1),'nearest'));
    idx_f = find(gps_trk.Time == interp1(gps_trk.Time,gps_trk.Time,time_dt(end),'nearest'));
    gps_trk_ek = gps_trk(idx_s:idx_f,:);

    % Linear interpolation of GPS to match timestamp of EK using Retime
    trk_fin = retime(gps_trk_ek,time_dt,'linear');

    if nargout>1
        %disp('[Sync GPS for EK] EK80 struct detected, will add GPS data to vars')
        if ii==1
            svEK80_out = svEK80;
        end
        
        vars = svEK80.(chan{ii}).vars;
        for i=1:numel(vars)
            vars(i).datetime = time_dt(i);
            vars(i).lon = trk_fin.lon(i);
            vars(i).lat = trk_fin.lat(i);
        end

        svEK80_out.(chan{ii}).vars = vars;
    end
end
% Time range?
%tr_ea = timerange("5-May-2025 03:46:28","5-May-2025 05:28:43");
%trk_ea_sub = trk_552025_ea2(tr_ea,:);

end