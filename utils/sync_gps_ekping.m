% FUnction to greatly reduce gps data and align it to the ping time. 
function [lon_tx,lat_tx] = sync_gps_ekping(tempsv,chnum)
        
    fieldn = fieldnames(tempsv);
    gps_fn = ismember(fieldn,'gps');
    temp_gps = tempsv.(fieldn{gps_fn});

    if istimetable(temp_gps)
        gps_t = temp_gps.Time;
    else
        gps_t = datetime(temp_gps.time,"ConvertFrom",'datenum');
    end
    
    % Collect ping timestamps
    % we can assume tx times of different transducers are very close /  similar, 
    % therefore only one timestamp is needed!
    
    % Check if the input is derived Sv file or raw. 
    if ~any(strcmp(fieldn,'config'))
        [chname,~] = EK_channel_name(tempsv);
        temp_dt = datetime(tempsv.(chname{chnum}).time,"ConvertFrom","datenum");
    else %This is for raw derived EK60
        temp_dt = datetime([tempsv.pings(1).time],"ConvertFrom","datenum");
    end

    lat_tx = interp1(gps_t, temp_gps.lat, temp_dt, 'linear', 'extrap');
    lon_tx = interp1(gps_t, temp_gps.lon, temp_dt, 'linear', 'extrap');

    %Use this only if you need gps per channel!

    %{
    if ~any(strcmp(fieldn,'config')) % This is a derived Sv file
        [chname,~] = EK_channel_name(tempsv);

        for j=1:length(chname) % For each channel
            temp_dt = datetime(tempsv.(chname{j}).time,"ConvertFrom","datenum");

            % Interpolate gps to align with echotimes
            % Make new lat lon vectors based on ping times (Use this for plotting gps!)
            lat_tx.(chname{j}) = interp1(gps_t, temp_gps.lat, temp_dt, 'linear', 'extrap');
            lon_tx.(chname{j}) = interp1(gps_t, temp_gps.lon, temp_dt, 'linear', 'extrap');
        end

    else % This is a raw file
        % we can assume tx times of different transducers are very close /  similar, therefore only one timestamp is needed.
        
        temp_dt = datetime([tempsv.pings(1).time],"ConvertFrom","datenum");
        lat_tx = interp1(gps_t, temp_gps.lat, temp_dt, 'linear', 'extrap');
        lon_tx = interp1(gps_t, temp_gps.lon, temp_dt, 'linear', 'extrap');
    end
    %}

end