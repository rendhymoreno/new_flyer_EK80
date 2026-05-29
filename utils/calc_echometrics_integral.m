function [out_i, out_avg, out_com, out_inertia] = calc_echometrics_integral(x,y,z)

r = y;
dr = r(2)-r(1);
dataout_lin = 10.^(z/10);
integral = nansum(dataout_lin,1)*dr;
integral = 10*log10(integral);
integral(isinf(integral)) = NaN;
integral(integral<-900) = NaN;
out_i = integral;

% Density / sv_avg (MVBS)
avg = nanmean(dataout_lin);
avg = 10*log10(avg);
avg(isinf(avg)) = NaN;
avg(avg<-900) = NaN;
out_avg = avg;

% Location / Center of Mass (COM)
com = (nansum(dataout_lin.*r',1)) ./ (nansum(dataout_lin,1));
out_com = com;

% Inertia / Spread or dispersion around center of mass
diff = (repmat(r',1,size(dataout_lin,2)) - com);
inertia = nansum((diff.^2).*dataout_lin,1) ./ (nansum(dataout_lin,1));
out_inertia = inertia;

end