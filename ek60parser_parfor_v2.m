function ek60parser_parfor_v2(inp,beamModechange,gps_flag)

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

% Pre-allocate sliced outputs for parfor
fileData(nFiles)   = struct();   % per-file Sv/time/range/cal etc.
fileGps(nFiles)    = struct();   % per-file gps, if used
hasGps             = false(nFiles,1);

ppm = ParforProgressbar(nFiles);%

parfor fileNumber = 1:nFiles
    try
        fileName = fullfile(dir_data,fileNameList{fileNumber});

        if isempty(beamModechange)
            [header, rawData] = readEKRaw(fileName,'gpssource',{'INGGA','GPGGA'},'Frequencies',[18000 38000]);
        else
            [header, rawData] = readEKRaw(fileName,'allowmodechange','true');
        end

        calParms = readEKRaw_GetCalParms(header, rawData);
        data_sv = readEKRaw_Power2Sv(rawData, calParms);
        nchan = [data_sv.config.frequency]/1000;

        % Store per-file channel data
        nchan_local = numel(data_sv.pings);
        fileData(fileNumber).nchan   = nchan_local;
        fileData(fileNumber).cal     = calParms;
        fileData(fileNumber).freq_kHz = [data_sv.config.frequency]/1000;

        % pre-allocate cells for this file
        fileData(fileNumber).Sv   = cell(1,nchan_local);
        fileData(fileNumber).time = cell(1,nchan_local);
        fileData(fileNumber).range = cell(1,nchan_local);

        for jj = 1:nchan_local
            fileData(fileNumber).Sv{jj}    = data_sv.pings(jj).Sv;
            fileData(fileNumber).time{jj}  = data_sv.pings(jj).time;
            fileData(fileNumber).range{jj} = data_sv.pings(jj).range;
        end
        
        if any(strcmp(fieldnames(rawData),'gps'))
        %if exist('gps_flag','var')
            len_gps = max(size(rawData.gps.time));
            len_ping = max(size(rawData.pings(1).time));
            % Basically, if gps is shorter than pings then just exit!
            if len_gps > len_ping
                [rawData.gps.lon,rawData.gps.lat] = sync_gps_ekping(rawData);
                rawData.gps.time = [rawData.pings(1).time];
            end
            fileGps(fileNumber).gps = rawData.gps;
            hasGps(fileNumber) = true;
            %gpsStruct = [gpsStruct; rawData.gps];
        end

    catch ME
        fprintf('Error proc file: %s due to %s\n',fileNameList{fileNumber},ME.message);
    end

    pause(100/nFiles);
    ppm.increment();

end

% Run for each channel

colStart = 1;
nchan = fileData.freq_kHz;

for jj = 1:numel(nchan)
    [rng_sz,r_idx] = max(arrayfun(@(x) numel(x.range{jj}),fileData(1:end)));
    t_sz = sum(arrayfun(@(x) numel(x.time{jj}),fileData(1:end)));

    % 2) Preallocate final arrays
    sv_agg = NaN(rng_sz, t_sz, 'like', fileData(1).Sv{1});  % preserve type
    dt_agg = NaN(1, t_sz);                                  % datetime row vector

    % 3) Fill in blocks
    colStart = 1;

    for ii = 1:nFiles
        tempsv = fileData(ii).Sv{jj};      % [r_i x t_i]
        tempdt = fileData(ii).time{jj};    % 1 x t_i or t_i x 1

        [r_i, t_i] = size(tempsv);
        colEnd = colStart + t_i - 1;

        % pad to rng_sz and assign in one shot
        block = NaN(rng_sz, t_i, 'like', tempsv);
        block(1:r_i, :) = tempsv;

        sv_agg(:, colStart:colEnd) = block;
        dt_agg(colStart:colEnd)    = tempdt(:).';

        colStart = colEnd + 1;
    end

    ek6080.("ch"+sprintf('%d_%d',jj,nchan(jj))).Sv = sv_agg;
    ek6080.("ch"+sprintf('%d_%d',jj,nchan(jj))).time = dt_agg;
    ek6080.("ch"+sprintf('%d_%d',jj,nchan(jj))).cal = [fileData(1).cal(jj)]; % Check for 2 channels
    ek6080.("ch"+sprintf('%d_%d',jj,nchan(jj))).range = [fileData(r_idx).range{jj}]';  

end

gps_lat = arrayfun(@(x) vertcat(x.gps.lat),fileGps(1:end),'UniformOutput',false);
gps_lon = arrayfun(@(x) vertcat(x.gps.lon),fileGps(1:end),'UniformOutput',false);
gps_t = arrayfun(@(x) vertcat(datetime(x.gps.time,"ConvertFrom","datenum")),fileGps(1:end),'UniformOutput',false);

% Making sure all cell contents have simiar structure
gps_lat = cellfun(@(x) x(:).', gps_lat, 'UniformOutput', false);
gps_lon = cellfun(@(x) x(:).', gps_lon, 'UniformOutput', false);
gps_t = cellfun(@(x) x(:).', gps_t, 'UniformOutput', false);

%gps_lat = cell2mat( cellfun(@(x) x(:), gps_lat, 'UniformOutput', false) );

if size(gps_t{1},1) == 1
    gps_tbl = timetable(horzcat(gps_t{:}).',horzcat(gps_lat{:}).',horzcat(gps_lon{:}).','VariableNames',{'lat','lon'});
else
    gps_tbl = timetable(vertcat(gps_t{:}),vertcat(gps_lat{:}),vertcat(gps_lon{:}),'VariableNames',{'lat','lon'});
end

ek6080.gps = gps_tbl;

%% Generate time synced ES60 Sv struct data with EK80
% 
% for ii = 1:length(nchan)
%     ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).Sv = index.("chan"+sprintf('%d',ii)).Sv;
%     ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).range = [index.("chan"+sprintf('%d',ii)).range]';
%     ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).time = index.("chan"+sprintf('%d',ii)).time;
%     ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).cal = calParms(ii);
% end
% 
% if ~isempty(fileGps)
%     %gps_tbl = struct2table(gpsStruct);
%     gps_tbl = [];
%     for i=1:height(gpsStruct)
%         gps_tbl = [gps_tbl; struct2table(gpsStruct(i))];
%     end
%     ek6080.gps = gps_tbl;
%     %disp('[EK60 Parser] Saving gps data into struct');
% end

%save(outfname,'-struct','ek6080');
out_info = whos('ek6080');
out_sz = [out_info.bytes]/(1024)^3;
fname = fullfile(dir_out,append(dstr,'_ek60_sv.mat'));

% If file is under 2GB save as compressed .mat, else save as v7.3
if out_sz < 2
    save(fname, '-fromstruct', ek6080);
else
    save(fname, '-fromstruct', ek6080, '-v7.3');
end

fprintf('[EK60 Parser] EK60 Parsing %s is completed\n', dstr);
end