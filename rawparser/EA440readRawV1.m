function data = EK80readRawV3(fname,input_freq1,input_freq2)

% Reads an entire .raw file and returns the data in various variables
% in a structure.
%
% data=[];
%
%  Revised Perkins
%
%   Revised to work with partial data files
%     Newhall 2019

pingno = 0;
envCount = 1;
paramCount = 1;
inparamCount = 1;
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
        dglength = fread(fid,1,'int32');
        
        if feof(fid)
            break
        end
        
        header = cHeader;                % make a new header class
        header = header.read(fid);       % read method
        
        switch(header.type)
            case 'XML0'
                xml = cXML;
                xml = xml.read(fid, dglength-headerlength);
                xmldata = xmlreadstring(deblank(xml.text));
                xmldata = parseXML(xmldata);
                %                     disp(xmldata.Name)
                switch (xmldata.Name)
                    case 'Configuration'
                        configData = parseconfxmlstructwbat(xmldata); %2025-6-11: This parses all data in string format. EA440 is correct
                    case 'Environment'
                        e = parseenvxmlstruct(xmldata);
                        e.timestamp = header.datetime;
                        envData(envCount) = e;
                        envCount = envCount + 1;
                    case 'InitialParameter'
                        ip = parseINparamxmlstruct(xmldata);
                        % Assumes that this datagram always comes
                        % before its associated RAW3 datagram
                        for ii = 1:length(ip)
                            if ~channels.isKey(ip(ii).ChannelID)
                                channels(ip(ii).ChannelID) = channelNum;

                                % debugging....
                                fprintf('[EK80Parser] ip.ChannelID (hdr) %s\n',ip(ii).ChannelID);

                                channelsInverse(channelNum) = ip(ii).ChannelID;
                                
                            end
                            channel = channels(ip(ii).ChannelID);  % hash to get channel #

                            if channel == 1
                                pingno = pingno + 1;
                                no_reads = 1;
                            end

                            ip(ii).timestamp = header.datetimeunix*10^6;

                            %%%%% ------------------------------------------
                            % Perkins edit to load new EK80 files from AR10 or
                            % later
                            if isfield(ip(ii),'Frequency')
                                ip(ii).FrequencyEnd=ip(ii).Frequency;
                                ip(ii).FrequencyStart=ip(ii).Frequency;
                                ip(ii)=rmfield(ip(ii),'Frequency');
                                ip(ii)=orderfields(ip(ii),[1;2;9;10;3;4;5;6;7;8]);
                            end
                            %%%%%% ----------------------------------------

                            inparamData(channel, pingno) = ip(ii); %#ok<*AGROW>
                            channelNum = channelNum + 1;
                        end
                        inparamCount = inparamCount + 1;
                        channelNum = 1;
                    case 'Parameter'
            %%%% swap channel ID values so they're solely numeric
            xmldata.Children(1).Attributes(1).Value = xmldata.Children(1).Attributes(1).Value(5:10);
            
                        p = parseparamxmlstruct(xmldata);
                        % Assumes that this datagram always comes
                        % before its associated RAW3 datagram
                        if ~channels.isKey(p.ChannelID)
                            channels(p.ChannelID) = channelNum;
                            
                               % debugging....
                            fprintf('[EK80Parser] p.ChannelID (hdr) %s\n',p.ChannelID);
                            
                            channelsInverse(channelNum) = p.ChannelID;
                            channelNum = channelNum + 1;
                        end
                        channel = channels(p.ChannelID);  % hash to get channel #
                        if channel == 1
                            pingno = pingno + 1;
                            no_reads = 1;
                        end
                        
                        p.timestamp = header.datetimeunix*10^6;
                        
                        %%%%% ------------------------------------------
                        % Perkins edit to load new EK80 files from AR10 or
                        % later
                        if isfield(p,'Frequency')
                            p.FrequencyEnd=p.Frequency;
                            p.FrequencyStart=p.Frequency;
                            p=rmfield(p,'Frequency');
                            p=orderfields(p,[1;2;9;10;3;4;5;6;7;8]);
                        end
                        %%%%%% ----------------------------------------
                        
                        paramData(channel, pingno) = p; %#ok<*AGROW>
                        paramCount = paramCount + 1;
                    otherwise
                        disp(['Unknown XML datagram with toplevel element name of ' ...
                            xmldata.Name])
                end
            case 'FIL1'
                filter = cFilter1Data;
                filterData(filterCount) = filter.read(fid);
                filterCount = filterCount + 1;
            % case 'MRU0'
            %     mru = cMRUData;
            %     mru = mru.read(fid);
            %     mru.timestamp = header.datetime;
            %     mruData(mruCount) = mru.asStruct();
            %     mruCount = mruCount + 1;
            case 'RAW3'
                s = cSampleDataRAW3_AR13;     % New class for AR13 v3
                s = s.read(fid);
                s.timestamp = header.datetime;
                
                s.dR=envData(end).SoundSpeed * paramData(channel, end).SampleInterval/2;
                s.minRange=0;
                s.maxRange=length(s.complexsamples)*s.dR;
                %s.maxRange=size(s.complexsamples, 2)*s.dR;
                s.minCount = 1;
                s.maxCount = round(s.maxRange./s.dR);
                s.maxCount=min(s.maxCount,size(s.complexsamples, 2));
                s.count = s.maxCount - s.minCount + 1;
                
                s.timestampunix = header.datetimeunix * 10^6;
%                 s.highdatetime = header.highdatetime;
%                s.highdatetime_shifted = header.highdatetime_shifted;
%                s.lowdatetime = header.lowdatetime;
                
                sampleData(channel, pingno) = s.asStruct();
                sampleData(channel, pingno).timestamp = header.datetime;
                %sampleData(channel, pingno).timestampunix = header.datetimeunix * 10^6;
                %sampleData(channel, pingno).highdatetime = header.highdatetime;
                %sampleData(channel, pingno).highdatetime_shifted = header.highdatetime_shifted;
                %sampleData(channel, pingno).lowdatetime = header.lowdatetime;


                %ps2(1:s.count,pingno)=sum(s.complexsamples,2);
                ps(1:s.count,pingno)=sum(s.complexsamples,1); %what is the right format?
            % case 'NME0'
            %     nmea = cNMEA;           % new nmea class
            %     nmea = nmea.read(fid, dglength-headerlength);
            %     nmea.timestamp = header.datetime;
            %     nmeaData(nmeaCount) = nmea;
            %     nmeaCount = nmeaCount + 1;
            otherwise
                disp(['Unsupported datagram of type: ' header.type])
                fread(fid, dglength-headerlength);
        end
        fread(fid, 1, 'int32'); % the trailing datagram marker. Reads the next line?
    end
end

%CHANGE FILTER FOR SPLIT PING FLYER 
chan2ind = 0;
f(1, 1:2)=filterData(1,1:2); 
for i = 3:length(filterData)
    if(~strcmp(filterData(1).ChannelID, filterData(i).ChannelID))
        chan2ind= i;
        break
    end
end
if(~chan2ind==0)
    f(2, 1:2)=filterData(1,chan2ind:chan2ind+1);
end
filterData = f;


% 
% % Rearrange the filter structures, based on the channel number and the
% % filter stage.
% for i = 1:length(filterData)
%     % fix ChannelID to #
%     filterData(i).ChannelID = filterData(i).ChannelID(5:10);
%     
%     % debugging
%     % fprintf('filterData(%d).ChannelID: %s\n',i,filterData(i).ChannelID);
%     
%      % fixing partial files 2019
%     if ~isKey(channels,filterData(i).ChannelID)
%         data = [];
%         fprintf('\t Missing Key for channels.. Partial file?\n');
%         return
%     end
%     
%    
%     
%     channel = channels(filterData(i).ChannelID);
%     f(channel, filterData(i).Stage) = filterData(i);
% end
% filterData = f;

if ~exist('nmeaData', 'var')
    nmeaData = struct([]);
end

% remove [ 'mru', mruData,   ] from last line below

data = struct('echodata', sampleData, 'filters', filterData, ...
    'config', configData, 'environ', envData, ...
    'nmea', nmeaData, 'param', paramData, 'channelMap', channels, ...
    'channelIDs', (channelsInverse));

