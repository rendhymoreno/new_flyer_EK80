%breakEKOut  Break up ES60 .out files so 
%   breakEKOut(inFile, outFile, rawData) 
%       creates a new, shorter, .out file that contains data defined by the
%       time span of the provided rawData structure.
%
%   Unlike ER60 .bot files, ES60 .out files are not generated for each .raw
%   file that is recorded. In some cases these .out files can be gigabytes
%   in size and create headaches during processing. This function can be used
%   to chop up large .out files into more manageable sizes.
%
%   Note that the original .out file is not modified in any way.
%
%   REQUIRED ARGUMENTS:
%
%            inFile:    The full path to the existing .out file that will be
%                       broken up.
%
%           outFile:    The full path to the new shorter .out file that will
%                       be created.
%
%           rawData:    The echolab rawData structure. The resulting output file
%                       will contain data that spans the same timeframe as the
%                       data in this structure.

function breakEKOut(inFile, outFile, rawData)

%  declare globals
global MATLAB_NT_TIME_OFFSET HEADER_LEN CONF_HEADER_LEN XCVR_HEADER_LEN

%  define constants
HEADER_LEN = 12;                %  Bytes in datagram header
CONF_HEADER_LEN = 516;          %  Bytes in CON0 general configuration data
XCVR_HEADER_LEN = 320;          %  Bytes in CON0 per transceiver configuration data

%  define the global MATLAB to NT time offset which is the number of 100
%  nano-second intervals from MATLAB's serial time reference point of
%  Jan 1 0000 00:00:00 to NT time's reference point of Jan 1 1601 00:00:00
MATLAB_NT_TIME_OFFSET = datenum(1601, 1, 1, 0, 0, 0) * 864000000000;


%  open file for reading
fid = fopen(inFile, 'r');
if (fid==-1)
    [pathstr, name, ext] = fileparts(inFile);
    warning('readEKRaw:IOError', 'Could not open input out file for reading: %s%s',name,ext);
    return;
end

%  open file for reading
foid = fopen(outFile, 'w');
if (foid==-1)
    [pathstr, name, ext] = fileparts(outFile);
    warning('readEKRaw:IOError', 'Could not open output out file for writing: %s%s',name,ext);
    return;
end

%  set timeRange based on rawData time values
timeRange = [rawData.pings(1).time(1) rawData.pings(1).time(end)];

%  read file header
[config, frequencies] = readEKRaw_ReadHeader(fid);

%  write the header to our new file
writeEKRaw_WriteHeader(foid, config.header, rawData);

%  read entire file, processing individual datagrams
while (true)
    
    %  read the datagram length
    len = fread(fid, 1, 'int32', 'l');
    %  check if we're at the end of the file
    if (feof(fid))
        break;
    end

    %  read datagram header
    [dgType, dgTime] = readEKRaw_ReadDgHeader(fid, 0);

        if (dgTime < timeRange(1))
            %  skip data before our desired time range
            fread(fid, len - HEADER_LEN, 'uchar', 'l');
            fread(fid, 1, 'int32', 'l');
           
        elseif (dgTime >= timeRange(1))
             %  copy data within our time range
            data = fread(fid, len - HEADER_LEN, 'uchar', 'l');
            fread(fid, 1, 'int32', 'l');
            
            fwrite(foid, len, 'int32', 'l');
            writeEKRaw_WriteDgHeader(foid, dgType, dgTime)
            fwrite(foid, data, 'uchar', 'l');
            fwrite(foid, len, 'int32', 'l');

        elseif (dgTime > timeRange(2))
            %  break out if we're beyond out time range
            break;
        end
end

%  close the files.
fclose(fid);
fclose(foid);


            