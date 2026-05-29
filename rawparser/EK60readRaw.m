%The raw EK/ES60 Parser --still in progress

function data = EK60readRaw(fname)

pingno = 0;
envCount = 1;
paramCount = 1;
nmeaCount = 1;
mruCount = 1;
filterCount = 1;
headerlength = 12;

% initialize hash tables
channels = containers.Map;
channelsInverse = containers.Map('KeyType', 'int32', 'ValueType', 'char');

channelNum = 1;
minRange=[];maxRange=[];
fid = fopen(fname,'r');

if (fid == -1)
    error(['Could not open file: ' fname]);
else
    while(1)
        dglength = fread(fid,1,'int32'); %length of header block
        
        if feof(fid)
            break
        end
        
        header = cHeader60;                % make a new header class / same like EK80
        header = header.read(fid);       % reads header type and datetime of file
    end
end
        