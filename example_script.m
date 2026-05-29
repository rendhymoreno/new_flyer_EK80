% Example script:
% Scenario: A split-beam EK80 echosounder is mounted facing forward on a ROV, and a different ES60 system is
% mounted facing downward on ship. ROV has a seabird CTD. 
% This code reads the ROV depth position from the CTD, parses raw EK80 data and ES60 data, converts the raw power from both transducers into Sv
% This script combines multiple scripts (Echolab for parsing EK60, cptcmap
% for echogram colormaps, and dynamicDateTicks.m and setDateAxes.m
% Works for Matlab 2020b
% Rendhy Sapiie 2023

clear all;
%% add paths of all folders needed
cd(fileparts(matlab.desktop.editor.getActiveFilename)); %move matlab dir to current pwd
addpath(genpath(pwd)); %add all folders and subfolders of source code to path
addpath('E:\RMS_EK80_60_Processing'); %add all folders and subfolders of Bermuda EK80,ES60, and CTD datasets to path
addpath('E:\RMS_EK80_60_Processing\exampledataset\processedFiles'); %add folder path of all output files

%% read ctd files
ctdin = 'E:\RMS_EK80_60_Processing\exampledataset\CTD\SBE39plus_REEL_DRIFTER_ROV_2021_07_08.cnv';
ctdout = 'E:\RMS_EK80_60_Processing\exampledataset\processedFiles\20210708ctd.mat';
ctdformat = 'binary';
ctdstructbuilder(ctdin,ctdout,ctdformat);
ctd = load(ctdout); %bermuda ctd files

%% read EK80 raw data installed on ROV and merge CTD timestamps into
%new structs (global_index.mat and ping data (three_ensemble-....mat)
ek80path = 'E:\RMS_EK80_60_Processing\exampledataset\EK80'; %path to raw EK80 data
ek80outpath = 'E:\RMS_EK80_60_Processing\exampledataset\processedFiles\'; %output folder of synced EK80-ROV data
ek80parser(ek80path, ek80outpath, ctdout);

%% read ES60 raw data installed on ship, converts into Sv, and synchronizes the ES60 timestamp with 
%EK80-ROV CTD timestamps into a new struct (syncedES60_sv.mat)
es60path = 'E:\RMS_EK80_60_Processing\exampledataset\ES60'; %ES60 raw data loc
es60out = 'E:\RMS_EK80_60_Processing\exampledataset\processedFiles\syncedES60_sv.mat'; %ES60 file output struct
rovinpath = 'E:\RMS_EK80_60_Processing\exampledataset\processedFiles\global_index.mat'; %input synced EK80-ROV data struct 
es60parser_sv_withROV(es60path,es60out,rovinpath);

%% plot ES60 data with ROV overlay
svES60 = load(es60out); %load ES60 Sv data
plotES60_ROV_Echogram(svES60,rovinpath,{0 'inf'},[-75 -39; -80 -40]);

%% Extract Sv values from EK80 raw data
index_type='cast'; %type of index used to query data
indexes='1:max([global_indexer.cast])'; %length of index (all data files will be processed)
svEK80 = playfunction_rms(ek80outpath, index_type, indexes, 'sv_pc') %query pulse compressed backscatter

%% plot EK80 Sv values
plotEk_Echogram(svEK80,{2 30},[-85 -65; -85 -65])

