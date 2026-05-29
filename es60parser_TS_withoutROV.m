% Simple EK/ES60 parser without ROV/CTD data based on EchoLab code
% This is run after ek80parser as it needs global_index.mat from that code
% [ek6080.mat] = es60parser_TS_withROV(defaultPath,outfname,globalindexPath,range)
% INPUT:
% defaultPath = string ''; ES60 raw data path
% outfname = string ''; ES60 data struct output path + filename
% globalindexPath = string ''; %input EK80 data struct path (from ek80parser_noctd)
% range = EK/ES60 range values cell array {1x2} {min_range max_range} or {min_range 'inf'} to get all range values
% Rendhy Sapiie

function es60parser_TS_withoutROV(tmsync,defaultPath,outfname,globalindexPath,range)
%addpath(genpath('F:\Echolab')); %Echolab directory [REQUIRED]
addpath(genpath('D:\Echolab')); %Echolab directory [REQUIRED]

%outfname = 'F:\ONR2023\bermudaek80mat\syncedES60_TS';
%defaultPath = 'F:\ONR2023\Bermuda\July2021\2021-07-08\d20210708\ES60'; %ES60 Bermuda data loc
%ctdout = 'F:\ONR2023\july2021_data\20210708ctd.mat'; %no need!!!!
%globalindexPath = 'F:\ONR2023\bermudaek80mat\global_index';
%% Load synced EK80 data

if nargin < 5 || isempty(tmsync) && isempty(globalindexPath)
EK80 = 0;
tmsync = 0;
fprintf('[EK60 Parser] No EK80 timesync has been chosen\n');
%dstr = [globalindexPath,'has been loaded'];
else
EK80 = load(globalindexPath);
fprintf('[EK60 Parser] EK80 timesync option has been selected\n');
end

% Select .raw ES/EK60 data files
[fileNameList,filePath,~] = uigetfile('*.raw','Select .raw files','MultiSelect','on',defaultPath);
if ~iscell(fileNameList)
    fileNameList = {fileNameList};filePath;
end

% Select .out ES/EK60 optional data files
%[fileNameList2,filePath2,~] = uigetfile('*.out','Select .out files','MultiSelect','on',defaultPath);
%if ~iscell(fileNameList2)
%    fileNameList2 = {fileNameList2};filePath2
%end

%% Rawparsing and data proccessing mostly from echolab
nFiles = length(fileNameList);
fprintf('[EK60 Parser] Reading %i files\n',nFiles);
ping0_x = zeros(1,2);
ping0_y = zeros(1,2);
ping1_x = zeros(1,2);

for fileNumber = 1:nFiles
    fileName = fullfile(filePath,fileNameList{fileNumber});
    %fileName2 = fullfile(filePath2,fileNameList2{fileNumber});
    [header, rawData] = readEKRaw(fileName);
    calParms = readEKRaw_GetCalParms(header, rawData);
    %[header, botData] = readEKOut(fileName2, calParms, rawData, ...
    %'ReturnRange', true);
    %data_sv = readEKRaw_Power2Sv(rawData, calParms);
    data_ts = readEKRaw_Power2Sp(rawData, calParms);
    nchan = [data_ts.config.frequency]/1000;
   
    if (fileNumber == 1)
        for j = 1:length(nchan)
            %index.("chan"+sprintf('%d', asu(j))) = data.pings(j);
            index.("chan"+sprintf('%d',j)) = data_ts.pings(j);
            ping0_x(j) = size(index.("chan"+sprintf('%d',j)).TS,1); % previous ping length in range 
            ping0_y(j) = size(index.("chan"+sprintf('%d',j)).TS,2); % previous ping quantity
        end
    else                        
        for k = 1:length(nchan)
            ping1_x(k) = size(data_ts.pings(k).TS,1); %current ping length
            
            if ping1_x(k) > ping0_x(k) %current file has ping length > previous file
                %tt = zeros(1,length(data.pings(k).time)); %unresolved yet
                %TSn = zeros(ping1_x(k),ping0_y(k));
                nm = NaN(ping1_x(k),ping0_y(k));
                nm(1:ping0_x(k),:) = index.("chan"+sprintf('%d',k)).TS; %shaping new matrix w/ nans and previous values
                %nm(1:ping0_x(k),:) = data.pings(k).TS;
                index.("chan"+sprintf('%d',k)).TS = nm; %changed the previous values into nan array w/ modified dimensions
                tt = data_ts.pings(k).time;
                TSn = data_ts.pings(k).TS; %the current value for this time
            elseif ping1_x(k) < ping0_x(k) %current file has ping length < previous file
                tt = zeros(1,length(data_ts.pings(k).time));
                TSn = zeros(ping0_x(k),size(data_ts.pings(k).TS,2));
                nm = NaN(ping0_x(k),size(data_ts.pings(k).TS,2));
                nm(1:ping1_x(k),:) = data_ts.pings(k).TS;
                tt = data_ts.pings(k).time;
                TSn = nm;
            else %equal
                tt = zeros(1,length(data_ts.pings(k).time));
                TSn = zeros(size(data_ts.pings(k).TS,1),size(data_ts.pings(k).TS,2));
                tt = data_ts.pings(k).time;
                TSn = data_ts.pings(k).TS;
            end
            index.("chan"+sprintf('%d',k)).time = horzcat(index.("chan"+sprintf('%d',k)).time,tt);
            index.("chan"+sprintf('%d',k)).TS = horzcat(index.("chan"+sprintf('%d',k)).TS,TSn);
            ping0_x(k) = size(index.("chan"+sprintf('%d',k)).TS,1); % previous ping length in range 
            ping0_y(k) = size(index.("chan"+sprintf('%d',k)).TS,2); % previous ping quantity
            
        end
    end
fprintf('[EK60 Parser] File %i out of %i has been processed into TS\n',fileNumber,nFiles);
end


%% Generate time synced ES60 TS struct data with EK80
%minr = 0;
%maxr = ceil(max([rov.global_indexer.depth])) + 30; %limits ES60 range dependent on ROV max depth + 30m
%maxr = 170; 
minr = range{1};
maxr = range{2};
if range{2} == 'inf'
    maxr = max([index.chan1.range]);
end

if tmsync ~= 1

for ii = 1:length(nchan)
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).TS = index.("chan"+sprintf('%d',ii)).TS;
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).range = [index.("chan"+sprintf('%d',ii)).range]';
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).time = index.("chan"+sprintf('%d',ii)).time;
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).cal = calParms(ii);
end

else %timesync is on

for ii = 1:length(nchan)
r_es70_s = dsearchn(index.("chan"+sprintf('%d',ii)).range, minr);
r_es70_f = dsearchn(index.("chan"+sprintf('%d',ii)).range, maxr);
trovek80_s = EK80.global_indexer(1).timestamp;
trovek80_f = EK80.global_indexer(end).timestamp;

if trovek80_s > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time 
    disp('timestamp of EK80 is in epoch milliseconds')
    trovek80_s = datenum(datetime(trovek80_s,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
    trovek80_f = datenum(datetime(trovek80_f,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
end

i_es60_s(ii) = dsearchn([index.("chan"+sprintf('%d',ii)).time]', trovek80_s); %problem cannot find index????
i_es60_f(ii) = dsearchn([index.("chan"+sprintf('%d',ii)).time]', trovek80_f);
if i_es60_s(ii) && i_es60_f(ii) == 1
    error('Timesync did not work')
end
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).TS = index.("chan"+sprintf('%d',ii)).TS(r_es70_s:r_es70_f,i_es60_s:i_es60_f);
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).range = [index.("chan"+sprintf('%d',ii)).range(r_es70_s:r_es70_f)]';
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).time = index.("chan"+sprintf('%d',ii)).time(:,i_es60_s:i_es60_f);
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).cal = calParms(ii);
end

end

save(outfname,'-struct','ek6080');
fprintf('[EK60 Parser] EK60 Parsing is completed\n');
end