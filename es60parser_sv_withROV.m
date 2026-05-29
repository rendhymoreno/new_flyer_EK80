% Simple EK/ES60 parser based on EchoLab code
% This is run after ek80parser as it needs global_index.mat from that code
% Rendhy Sapiie
%formatted for renmoreno-desktop 4/12/2023

function es60parser_sv_withROV(defaultPath,outfname,globalindexPath)
addpath(genpath('F:\Echolab')); %Echolab directory [REQUIRED]

%outfname = 'F:\ONR2023\bermudaek80mat\syncedES60_sv';
%defaultPath = 'F:\ONR2023\Bermuda\July2021\2021-07-08\d20210708\ES60'; %ES60 Bermuda data loc
%ctdout = 'F:\ONR2023\july2021_data\20210708ctd.mat'; %no need!!!!
%globalindexPath = 'F:\ONR2023\bermudaek80mat\global_index';
%% Load synced EK80 and ROV ctd data

rov = load(globalindexPath);
dstr = [globalindexPath,'has been loaded'];
    
% Select .raw ES/EK60 data files
[fileNameList,filePath,~] = uigetfile('*.raw','Select .raw files','MultiSelect','on',defaultPath);
if ~iscell(fileNameList)
    fileNameList = {fileNameList};filePath
end

% Select .out ES/EK60 optional data files
%[fileNameList2,filePath2,~] = uigetfile('*.out','Select .out files','MultiSelect','on',defaultPath);
%if ~iscell(fileNameList2)
%    fileNameList2 = {fileNameList2};filePath2
%end

%% Rawparsing and data proccessing mostly from echolab
nFiles = length(fileNameList);
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
    data = readEKRaw_Power2Sv(rawData, calParms);
    nchan = [data.config.frequency]/1000;
   
    if (fileNumber == 1)
        for j = 1:length(nchan)
            %index.("chan"+sprintf('%d', asu(j))) = data.pings(j);
            index.("chan"+sprintf('%d',j)) = data.pings(j);
            ping0_x(j) = size(index.("chan"+sprintf('%d',j)).Sv,1); % previous ping length in range 
            ping0_y(j) = size(index.("chan"+sprintf('%d',j)).Sv,2); % previous ping quantity
        end
    else                        
        for k = 1:length(nchan)
            ping1_x(k) = size(data.pings(k).Sv,1); %current ping length
            
            if ping1_x(k) > ping0_x(k) %current file has ping length > previous file
                %tt = zeros(1,length(data.pings(k).time)); %unresolved yet
                %svn = zeros(ping1_x(k),ping0_y(k));
                nm = NaN(ping1_x(k),ping0_y(k));
                nm(1:ping0_x(k),:) = index.("chan"+sprintf('%d',k)).Sv; %shaping new matrix w/ nans and previous values
                %nm(1:ping0_x(k),:) = data.pings(k).Sv;
                index.("chan"+sprintf('%d',k)).Sv = nm; %changed the previous values into nan array w/ modified dimensions
                tt = data.pings(k).time;
                svn = data.pings(k).Sv; %the current value for this time
            elseif ping1_x(k) < ping0_x(k) %current file has ping length < previous file
                tt = zeros(1,length(data.pings(k).time));
                svn = zeros(ping0_x(k),size(data.pings(k).Sv,2));
                nm = NaN(ping0_x(k),size(data.pings(k).Sv,2));
                nm(1:ping1_x(k),:) = data.pings(k).Sv;
                tt = data.pings(k).time;
                svn = nm;
            else %equal
                tt = zeros(1,length(data.pings(k).time));
                svn = zeros(size(data.pings(k).Sv,1),size(data.pings(k).Sv,2));
                tt = data.pings(k).time;
                svn = data.pings(k).Sv;
            end
            index.("chan"+sprintf('%d',k)).time = horzcat(index.("chan"+sprintf('%d',k)).time,tt);
            index.("chan"+sprintf('%d',k)).Sv = horzcat(index.("chan"+sprintf('%d',k)).Sv,svn);
            ping0_x(k) = size(index.("chan"+sprintf('%d',k)).Sv,1); % previous ping length in range 
            ping0_y(k) = size(index.("chan"+sprintf('%d',k)).Sv,2); % previous ping quantity
            
        end
    end

end


%% Generate time synced ES60 Sv struct data with EK80 and ROV CTD
minr = 0;
maxr = ceil(max([rov.global_indexer.depth])) + 30; %limits ES60 range dependent on ROV max depth + 30m
%maxr = 170; 

for ii = 1:length(nchan)
r_es70_s = dsearchn(index.("chan"+sprintf('%d',ii)).range, minr);
r_es70_f = dsearchn(index.("chan"+sprintf('%d',ii)).range, maxr);
trovek80_s = rov.global_indexer(1).timestamp;
trovek80_f = rov.global_indexer(end).timestamp;
i_es60_s(ii) = dsearchn([index.("chan"+sprintf('%d',ii)).time]', trovek80_s);
i_es60_f(ii) = dsearchn([index.("chan"+sprintf('%d',ii)).time]', trovek80_f);
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).Sv = index.("chan"+sprintf('%d',ii)).Sv(r_es70_s:r_es70_f,i_es60_s:i_es60_f);
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).range = [index.("chan"+sprintf('%d',ii)).range(r_es70_s:r_es70_f)]';
ek6080.("ch"+sprintf('%d_%d',ii,nchan(ii))).time = index.("chan"+sprintf('%d',ii)).time(:,i_es60_s:i_es60_f);
end

save(outfname,'-struct','ek6080');
end