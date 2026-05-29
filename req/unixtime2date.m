%[year,month,day,hours,minutes,second] = unixtime2date(unix_time)
function [year,month,day,hours,minutes,second] = unixtime2date(unix_time);

days_since_1970 = unix_time/(3600*24); 
day_number = days_since_1970 + 719529;
[year,month,day,hours,minutes,second] = datevec(day_number);
