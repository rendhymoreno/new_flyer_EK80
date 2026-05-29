classdef cHeader
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        type
        datetime
        datetimeunix
        lowdatetime
        highdatetime
        highdatetime_shifted
    end
    
    methods
        function obj = read(obj,fid)
            obj.type = char(fread(fid,4,'char')');
            
            lowdatetime = fread(fid,1,'uint32=>uint64');
            highdatetime = fread(fid,1,'uint32=>uint64');
            
            obj.lowdatetime=lowdatetime;
            obj.highdatetime=highdatetime;
            obj.highdatetime_shifted= highdatetime*2^32;
            obj.datetime = NTTime2Mlab(double(highdatetime * 2^32 + lowdatetime));
            
            %obj.datetime = NTTime2Mlab(highdatetime *2^32 + lowdatetime);
            dv = datevec(obj.datetime);
            obj.datetimeunix = unixtime(dv(1), dv(2), dv(3), dv(4), dv(5), dv(6));
            
        end
    end
    
end

