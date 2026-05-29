function depth_track = interp_ek_tracks(lon_bty,lat_bty,z_bty,lon_ek,lat_ek)

% Make grid of bathymetry
[lon_g,lat_g] = meshgrid(lon_bty,lat_bty);

% Interpolate tracks

depth_track = interp2(lon_g, lat_g, abs(z_bty), lon_ek, lat_ek, 'linear');

end