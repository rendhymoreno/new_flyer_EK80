addpath(genpath('E:\RMS_EK80_60')); %add all folders and subfolders of Bermuda EK80,ES60, and CTD datasets to path
addpath(genpath('E:\EK80_freq_test')); %add folder path of all output files

%%

%ek80path = 'E:\EK80_freq_test\'; %path to raw EK80 data
%ek80outpath = 'E:\EK80_freq_test\'; %output folder of synced EK80-ROV data
ek80path = 'E:\2023_MSET\MGL23-Flyer\20231005_214229\processed';
ek80outpath = 'E:\2023_MSET\processed\Oct52023\2026_5_11';
MergedFlyer = 'E:\2023_MSET\MGL23-Flyer\20231005_214229\20231005_214229_merged.mat'; %merged flyer path
inject_environment = 1;
TVG_range_correction = 1;
%range_subset = [0 100];

%ek80parser_noctd(ek80path, ek80outpath, TVG_range_correction);
ek80parser_flyer(ek80path, ek80outpath, MergedFlyer, inject_environment, TVG_range_correction)
% New parser
ek80parser_flyer_v2(ek80path, ek80outpath, MergedFlyer, inject_environment, TVG_range_correction);
% This works!!
ek80parser_flyer_v2_parfor(ek80path, ek80outpath, MergedFlyer, inject_environment, TVG_range_correction);
%% Load files
% Old
% ek80outpath = 'H:\Rendhy\2023_MSET\processed\Oct9_early\';
% index_type='cast'; %type of index used to query data
% indexes='1:max([global_indexer.cast])'; %length of index (all data files will be processed)
% svEK80 = playfunction_rms(ek80outpath, index_type, indexes, 'sv_pc');

% New: Read parquet file -- most recent
ek80outpath = 'E:\2023_MSET\processed\Oct52023\';
parfiles = dir(fullfile(ek80outpath, "*.parquet"));
[~, idx] = max([parfiles.datenum]);
latestFile = fullfile(parfiles(idx).folder, parfiles(idx).name);
indexer = parquetread(latestFile);

% Maybe EK80_load_files directly loads indexer inside function?
chan_choice = '70';
var_n = {'sv_pc','PhysAng_alongship','PhysAng_athwartship'};
EK80 = EK80_load_files(chan_choice,var_n,indexer); %Loading 126 files: 128 sec

EK80 = EK80_load_files_parfor(chan_choice,var_n,indexer); %Loading 126 files: 132 sec


