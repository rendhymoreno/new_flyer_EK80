%  This is a simple script to compare GPS times to the recording PC time
%  to try to determine how many seconds the recording PC time is off
%  from GPS time.

%  specify full path to raw file
rawFile = 'data\L0424-D20060717-T134427-ES60.raw';

%  read in raw file - extract only the raw GPGGA datagrams.
%  this will fail if the vessel GPS doesn't emit GGA datagrams so
%  you may need to add other talker/sentence elements to the
%  UserNMEA cell array.
disp('Reading .raw file...');
[header, data] = readEKRaw(rawFile, 'GPSOnly', true, 'UserNMEA', {'GPGGA', 'GPGLL'});

%  this is the computer clock time in GMT as a MATLAB datenum
computerTime = data.NMEA.GPGGA.time(1);

%  get the MDY from the computer clock since GPS doesn't store it
%  obviously this can fail on day rollover so you'll need to figure out
%  a clever way to handle that.
computerDate =  datestr(computerTime, 'mm-dd-yyyy');

%  extract the HHMMSS from the GPS string. If you need to process
%  different talker/sentence strings you will need to put branching
%  code here to handle the various cases
GPS_HMS = data.NMEA.GPGGA.string{1}(8:13);

%  lastly build a full GPS time string
GPSTimeString = [computerDate, ' ', GPS_HMS];
%  and convert to MATLAB dantenum
GPSTime = datenum(GPSTimeString, 'mm-dd-yyyy HHMMSS');

%  calculate the offset in MATLAB time
timeOffset = computerTime - GPSTime;

%  MATLAB time is number of DAYS since a fixed point so we
%  need to convert to seconds
timeOffset = timeOffset * 60 * 60 * 24;

%  display the results
if (timeOffset >= 0)
    disp(['Computer is ahead ' num2str(timeOffset) ' seconds.']);
else
    disp(['Computer is behind ' num2str(-timeOffset) ' seconds.']);
end
