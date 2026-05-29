% Simple ES60 script that reads raw data,converts into Sv, and generates an echogram
% Data source used in this example is from the exampledataset included in sourcecode
% Works for Matlab 2020b
% Rendhy Sapiie 2023

clear all;
%% add paths of all folders needed
cd(fileparts(matlab.desktop.editor.getActiveFilename)); %move matlab dir to current pwd
addpath(genpath(pwd)); %add all folders and subfolders of source code to path
addpath(genpath('E:\RMS_EK80_60')); %add path of source code
addpath(genpath('E:\2023_MSET\')); %add path of all data files

%% read ES60 raw data and compute volume backscatter (Just ES60 data without EK80 or ROV information)
tmsync = []; %No timesync w/ EK80 needed
ek80_index = []; %No EK80 data needed
es60path = 'E:\RMS_EK80_60\exampledataset\ES60\'; %ES60 raw data folder location
es60out = 'E:\RMS_EK80_60\exampledataset\processedFiles\syncedES60_sv.mat'; %Output path and filename of processed raw data
ranges = {0 'inf'}; %Extract all ES60 ranges 
es60parser_sv_withoutROV(tmsync,es60path,es60out,ek80_index,ranges); %Parsing and conversion algorithm

%% Loading the processed ES60 data and apply corrections
svES60 = load(es60out); %load ES60 Sv data output
svES60 = fix_ES60_timestamp(svES60); %mandatory to fix errors in processed data

%% Generating echograms
channel = []; %Plot all ES60 channels; set to 1 to only plot channel 1 (38khz) || 2 to plot channel 2 (200khz)
ctdpath = []; %No ctd data
eventdn = []; %No events
range = {0 'inf'}; %Plot for all ranges in the data
timelength = []; %Plot for all pings in the data
crange = [-77 -36; -74 -35]; %colorbar ranges for 2 channels (dB ref 1m^-1)
plt_title = 'Simple ES60 Sv echogram';
export1 = []; %this is to export a high quality figure. Set to 1 to export figure, [] if no export needed
plotEk_Echogram_Niskin(svES60,channel,ctdpath,eventdn,range,timelength,crange,plt_title,export1); %plotting function
