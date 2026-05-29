classdef cMRUData
    %  cMRUData
    %      New class for RMS 2025
    
    properties
        timestamp % [Matlab time number of ping]
        heave
        roll
        pitch
        heading
    end
    
    methods
        function x = asStruct(obj)
            x = struct(...
                'timestamp', obj.timestamp, ...
                'heave', obj.heave, ...
                'roll', obj.roll, ...
                'pitch', obj.pitch, ...
                'heading', obj.heading );                
        end
        
        function obj = read(obj,fid)
            %obj.channelID               = deblank(fread(fid,128,'*char')');
            obj.heave                = fread(fid,1,'float32'); % meters
            obj.roll                   = fread(fid,1,'float32'); % degrees
            obj.pitch                  = fread(fid,1,'float32'); % degrees
            obj.heading                   = fread(fid,1,'float32'); % degrees
        end
        
    end
    
end