%
% [DT] = unixtime2datetime(unixtime)
% 
% unix time in seconds

function [DT] = unixtime2datetime(utime)

[Y,MO,D,H,MI,S] = unixtime2date(double(utime));
DT = datetime(Y,MO,D,int8(H),int8(MI),int8(floor((S))),mod(S,1)*1000);

