% Example script for reading EK80 and ES60 data independently without needing CTD data:
% This code parses raw EK80 data and ES60 data, converts the raw power from both transducers into Sv
% Has the option of timesyncing EK80 and ES60 data if needed
% This script combines multiple scripts (Echolab for parsing EK60, cptcmap
% for echogram colormaps, and dynamicDateTicks.m and setDateAxes.m
% Worked on Matlab 2020b
% Rendhy Sapiie 2023

clear all;
%% add paths of all folders needed
cd(fileparts(matlab.desktop.editor.getActiveFilename)); %move matlab dir to current pwd
addpath(genpath(pwd)); %add all folders and subfolders of source code to path
addpath('D:\RMS\RMS_EK80_60'); %add all folders and subfolders of Bermuda EK80,ES60, and CTD datasets to path
%addpath('D:\2023_MarcusLangseth\ES60');
%addpath('D:\2023_MarcusLangseth\processed\'); %add folder path of all output files

%% read EK80 raw data installed on ROV and merge CTD timestamps into new structs (global_index.mat and ping data (three_ensemble-....mat)

ek80path = 'H:\Rendhy\2025_Hawaii_data\EA440\Data'; %path to raw EK80 data
ek80outpath = 'H:\Rendhy\2025_Hawaii_data\EA440\Data\processedFiles\'; %output folder of synced EK80-ROV data

%ek80path = 'D:\RMS_EK80_60_Processing\exampledataset\EK80';
%ek80outpath = 'D:\RMS_EK80_60_Processing\exampledataset\processedFiles';

ek80parser_noctd(ek80path, ek80outpath,1); %use to parse EK80 data without CTD

%% read ES60 raw data installed on ship, converts into Sv, and synchronizes the ES60 timestamp with EK80 timestamps into a new struct (syncedES60_sv.mat)

es60path = 'H:\Rendhy\2025_Hawaii_data\EA440\Data'; %ES60 raw data loc
es60out = 'H:\Rendhy\2025_Hawaii_data\EA440\Data\processedFiles\'; %ES60 file output struct
%ek80path = 'E:\2023_Bermuda\processed\global_index.mat'; %input EK80 data struct 
%tmsync = 1; %input tmsync = 1 to timesync ES60 and EK80 timestamps / null [] if not 
%es60parser_sv_withoutROV(tmsync,es60path,es60out,ek80path,{0 'inf'}); %use this to parse EK/ES60 data and timesync between ek80 and es60 data (need EK80 data!!)
es60parser_sv_withoutROV([],es60path,es60out,[],{0 'inf'}); %no timesync with EK80/just want to read ES60 data without loading EK80 data

%% plot ES60 Sv data
svES60 = load(es60out); %load ES60 Sv data
%plotEk_Echogram(svES60,{0 300},{'07-19-2023 02:47:10','07-19-2023 02:49:19'},[-77 -36; -74 -35])
plotEk_Echogram(svES60,{0 500},[],[-80 -50; -74 -35])
%plotEk_Echogram(svES60,{0 700},[],[-80 -39; -74 -35])

%% Extract Sv values from EK80 raw data (If you have EK80 data only)
index_type='cast'; %type of index used to query data
indexes='1:max([global_indexer.cast])'; %length of index (all data files will be processed)
svEK80 = playfunction_rms(ek80outpath, index_type, indexes, 'sv_pc') %query pulse compressed backscatter

%% plot EK80 Sv values
plotEk_Echogram(svEK80,{2 100},[],[-70 -40; -50 -20])

