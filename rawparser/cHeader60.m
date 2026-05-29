classdef cHeader60
    %UNTITLED3 EK60 Header file
    %   Added config properties (taken from Echolab to this header)
    
    properties
        type
        datetime
        datetimeunix
        lowdatetime
        highdatetime
        highdatetime_shifted
        surveyname
        transectname
        soundername
        spare
        transceivercount
    end
    
    methods
        function obj = read(obj,fid)
            obj.type = char(fread(fid,4,'char')'); 
            
            lowdatetime = fread(fid,1,'uint32=>uint64');
            highdatetime = fread(fid,1,'uint32=>uint64');
            
            obj.surveyname = char(fread(fid,128,'uchar', 'l')');
            obj.transectname = char(fread(fid,128,'uchar', 'l')');
            obj.soundername = char(fread(fid,128,'uchar', 'l')');
            obj.spare = char(fread(fid,128,'uchar', 'l')');
            obj.transceivercount = fread(fid,1,'int32', 'l');
            
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