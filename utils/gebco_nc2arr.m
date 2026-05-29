function [lon_bty,lat_bty,z_bty] = gebco_nc2arr(ncfile)

%ncfile = '/home/padres/Xilinx/rendhy/test_ek60/data/bathy/GEBCO_20-45N_-75--60_10c0e7cbfe40/gebco_2025_n45.0_s20.0_w-80.0_e-65.0.nc';
%ncinfo(ncfile)

% Typical GEBCO 2D NetCDF variable names:
lon_var = 'lon';      % sometimes 'x' or 'longitude'
lat_var = 'lat';      % sometimes 'y' or 'latitude'
z_var   = 'elevation';% sometimes 'z' or 'height'

lon_bty = ncread(ncfile, lon_var);       % 1D longitude array [degrees_east]
lat_bty = ncread(ncfile, lat_var);       % 1D latitude array [degrees_north]
z_bty  = ncread(ncfile, z_var);         % 2D elevation array [meters]
z_bty = double(z_bty)';

end
