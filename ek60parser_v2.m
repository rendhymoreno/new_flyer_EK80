% Simple EK/ES60 parser without ROV/CTD data based on EchoLab code
% This is run after ek80parser as it needs global_index.mat from that code
% [ek6080.mat] = es60parser_sv_withROV(defaultPath,outfname,globalindexPath,range)
% INPUT:
% defaultPath = string ''; ES60 raw data path
% outfname = string ''; ES60 data struct output path + filename
% globalindexPath = string ''; %input EK80 data struct path (from ek80parser_noctd)
% range = EK/ES60 range values cell array {1x2} {min_range max_range} or {min_range 'inf'} to get all range values
% Rendhy Sapiie

function ek60parser_v2(inp,beamModechange,gps_flag)

% Load synced EK80 data

% Select .raw ES/EK60 data files
if (ischar(inp) | isstring(inp))  & isfolder(inp)
    [fileNameList,filePath,~] = uigetfile('*.raw','Select .raw files','MultiSelect','on',inp);
    if ~iscell(fileNameList)
        fileNameList = {fileNameList};filePath;
    end
elseif istimetable(inp)
    fileNameList = inp.filename;
end

dstr = string(inp.Time(1),"uuuuMMdd");
dir_data = inp.foldername{1};
dir_out = fullfile(dir_data,'proc');
fprintf('[EK60 parser] Reading table of date %s\n',dstr);

% Make folder output
if ~exist('dir_out','dir')
    mkdir(dir_out);
end

%% Rawparsing and data proccessing mostly from echolab

nFiles = length(fileNameList);
%fprintf('[EK60 Parser] Reading %i files\n',nFiles);
ping0_x = zeros(1,2);
ping0_y = zeros(1,2);
ping1_x = zeros(1,2);

gpsStruct = []; 

for fileNumber = 1:nFiles
    try
        fileName = fullfile(dir_data,fileNameList{fileNumber});
        %fileName2 = fullfile(filePath2,fileNameList2{fileNumber});
        if isempty(beamModechange)
            [header, rawData] = readEKRaw(fileName,'gpssource',{'INGGA','GPGGA'},'Frequencies',[18000 38000]);
        else
            [header, rawData] = readEKRaw(fileName,'allowmodechange','true');
        end
        calParms = readEKRaw_GetCalParms(header, rawData);
        data_sv = readEKRaw_Power2Sv(rawData, calParms);
        nchan = [data_sv.config.frequency]/1000;

        if exist('gps_flag','var')
            len_gps = max(size(rawData.gps.time));
            len_ping = max(size(rawData.pings(1).time));
            % Basically, if gps is shorter than pings then just exit!
            if len_gps > len_ping
                [rawData.gps.lon,rawData.gps.lat] = sync_gps_ekping(rawData);
                rawData.gps.time = [rawData.pings(1).time];
            end

            gpsStruct = [gpsStruct; rawData.gps];
        end

        if (fileNumber == 1)
            for j = 1:length(nchan)
                %index.("chan"+sprintf('%d', asu(j))) = data.pings(j);
                index.("chan"+sprintf('%d',j)) = data_sv.pings(j);
                ping0_x(j) = size(index.("chan"+sprintf('%d',j)).Sv,1); % previous ping length in range
                ping0_y(j) = size(index.("chan"+sprintf('%d',j)).Sv,2); % previous ping quantity
            end
        else
            for k = 1:length(nchan)
                ping1_x(k) = size(data_sv.pings(k).Sv,1); %current ping length

                if ping1_x(k) > ping0_x(k) %current file has ping length > previous file
                    %tt = zeros(1,length(data.pings(k).time)); %unresolved yet
                    %svn = zeros(ping1_x(k),ping0_y(k));
                    nm = NaN(ping1_x(k),ping0_y(k));
                    nm(1:ping0_x(k),:) = index.("chan"+sprintf('%d',k)).Sv; %shaping new matrix w/ nans and previous values
                    %nm(1:ping0_x(k),:) = data.pings(k).Sv;
                    index.("chan"+sprintf('%d',k)).Sv = nm; %changed the previous values into nan array w/ modified dimensions
                    tt = data_sv.pings(k).time;
                    svn = data_sv.pings(k).Sv; %the current value for this time
                elseif ping1_x(k) < ping0_x(k) %current file has ping length < previous file
                    tt = zeros(1,length(data_sv.pings(k).time));
                    svn = zeros(ping0_x(k),size(data_sv.pings(k).Sv,2));
                    nm = NaN(ping0_x(k),size(data_sv.pings(k).Sv,2));
                    nm(1:ping1_x(k),:) = data_sv.pings(k).Sv;
                    tt = data_sv.pings(k).time;
                    svn = nm;
                else %equal
                    tt = zeros(1,length(data_sv.pings(k).time));
                    svn = zeros(size(data_sv.pings(k).Sv,1),size(data_sv.pings(k).Sv,2));
                    tt = data_sv.pings(k).time;
                    svn = data_sv.pings(k).Sv;
                end
                index.("chan"+sprintf('%d',k)).time = horzcat(index.("chan"+sprintf('%d',k)).time,tt);
                index.("chan"+sprintf('%d',k)).Sv = horzcat(index.("chan"+sprintf('%d',k)).Sv,svn);
                ping0_x(k) = size(index.("chan"+sprintf('%d',k)).Sv,1); % previous ping length in range
                ping0_y(k) = size(index.("chan"+sprintf('%d',k)).Sv,2); % previous ping quantity

            end
        end
        fprintf('[EK60 Parser] File %i out of %i has been processed into Sv\n',fileNumber,nFiles);

    catch ME
        fprintf('Error proc file: %s due to %s\n',fileNameList{fileNumber},ME.message);
    end

end


%% Generate time synced ES60 Sv struct data with EK80

for ii = 1:length(nchan)
    ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).Sv = index.("chan"+sprintf('%d',ii)).Sv;
    ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).range = [index.("chan"+sprintf('%d',ii)).range]';
    ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).time = index.("chan"+sprintf('%d',ii)).time;
    ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).cal = calParms(ii);
end

if ~isempty(gpsStruct)
    %gps_tbl = struct2table(gpsStruct);
    gps_tbl = [];
    for i=1:height(gpsStruct)
        gps_tbl = [gps_tbl; struct2table(gpsStruct(i))];
    end
    ek6080.gps = gps_tbl;
    %disp('[EK60 Parser] Saving gps data into struct');
end

%save(outfname,'-struct','ek6080');
out_info = whos('ek6080');
out_sz = [out_info.bytes]/(1024)^3;
fname = fullfile(dir_out,append(dstr,'_ek60_sv.mat'));

% If file is under 2GB save as compressed .mat, else save as v7.3
if out_sz < 2e9
    save(fname, '-fromstruct', ek6080);
else
    save(fname, '-fromstruct', ek6080, '-v7.3');
end


fprintf('[EK60 Parser] EK60 Parsing %s is completed\n', dstr);
end