% have to change variables in plotEK!!!!!
clear all;
%% add paths of all folders needed
cd(fileparts(matlab.desktop.editor.getActiveFilename)); %move matlab dir to current pwd
addpath(genpath(pwd)); %add all folders and subfolders of source code to path
addpath(genpath('H:\Rendhy\RMS_EK80_60')); %add all folders and subfolders of Bermuda EK80,ES60, and CTD datasets to path
addpath(genpath('H:\Rendhy\2023_MSET')); %add folder path of all output files
%addpath('E:\2023_MSET\processed'); %add folder path of all output files

%% read EK80 raw data 
ek80path = 'H:\Rendhy\2023_MSET\MGL23-Flyer\20231010_193035\EK80\post'; %path to raw EK80 data
ek80outpath = 'H:\Rendhy\2023_MSET\processed\Oct102023\'; %output folder of synced EK80-ROV data
MergedFlyer = 'H:\Rendhy\2023_MSET\MGL23-Flyer\20231010_193035\20231010_193035_merged.mat'; %merged flyer path
inject_environment = 1;
TVG_range_correction = 1;
ek80parser_flyer(ek80path, ek80outpath, MergedFlyer, inject_environment,TVG_range_correction); %use to parse EK80 data without CTD

%% read ES60 raw data installed on ship, converts into Sv, and synchronizes the ES60 timestamp with 
%EK80-ROV CTD timestamps into a new struct (syncedES60_sv.mat)
%Flyer timestamps are in microsec (1e-6) epoch/unix time
es60path = 'H:\Rendhy\2023_MSET\ES60\11102023'; %ES60 raw data loc
es60out = 'H:\Rendhy\2023_MSET\processed\Oct112023\syncedES60.mat'; %ES60 file output struct
ek80path = 'H:\Rendhy\2023_MSET\processed\Oct112023\global_index.mat'; %input EK80 data struct 
tmsync = 1; %input tmsync = 1 to timesync ES60 and EK80 timestamps / null [] if not 
es60parser_sv_withoutROV(tmsync,es60path,es60out,ek80path,{0 'inf'}); %use this to parse EK/ES60 data and "crop" between ek80 and es60 data (need EK80 data!!)
%es60parser_sv_withoutROV([],es60path,es60out,[],{0 'inf'});
ctdflag = 1;
%% Filtering
svES60 = load(es60out); %load ES60 Sv data
svES60 = fix_ES60_timestamp(svES60); %remove odd timestamps
svES60 = chop_EK60_EK80(svES60,[0 500],[]);
%svES60_38_thres = threshold_backscatter(svES60,'ES60',1,-125,-50,'tvt',1);
svES60_38_IN = impulse_noise_filter(svES60,'ES60',1,60,2,10,0,500,'NaN',1,10,1); %Using hardcore mode works better
%svES60_38_AN = attenuation_noise_filter(svES60_38_IN,'ES60',1,40,50,301,50,8,'NaN',[]);
svES60_38_TN = transient_noise_filter(svES60_38_IN,'ES60',1,30,5,70,150,500,15,7,'NaN',[],1); %need to add if sample window max length then error! 
svES60_38_BN = background_noise_remove_RMS(svES60_38_TN,'ES60',1,50,20,-135,1,1,1); %default 50, 20, -125
svES60_38_thres = threshold_backscatter(svES60_38_BN,'ES60',1,-135,-20,'tvt',1);
svES60_filt = residual_noise_filter(svES60_38_thres,'ES60',1,0,500,5,1); %Too Harsh

[svES60_filt_rs] = resample_weighted_mean(svES60_filt,'ES60',1,3600, 250, []);
%% plot ES60 data with flyer overlay
plotEk_Echogram_Niskin(svES60_filt,1,ek80path,[],{0 500},[],[-77 -36],[],[])
plotEk_Echogram_Niskin(svES60,1,[],[],{0 500},[],[-77 -36],[],[])
plotEk_Echogram_Niskin(svES60_filt_rs,1,[],[],{0 500},[],[-77 -36],[],[])
%% Plotting with time subset!
tend = datenum(datetime(svES60.ch1_38.time(end),"ConvertFrom","datenum")); 
tstart = datenum(datetime(svES60.ch1_38.time(end),"ConvertFrom","datenum")-duration([2 0 0]));
svES60_chop = chop_EK60(svES60_filt,[],[tstart tend]);
%plotEk_Echogram_Niskin(svES60,1,[],[],{0 'inf'},[tstart tend],[-77 -36],[],[]) %with time subset!
fig = plotEk_Echogram_Niskin(svES60_chop,1,[],[],{0 'inf'},[],[-77 -36],[],[]); 
%plotEk_Echogram_Niskin(data,channel,ctdpath,eventdn,range,timelength,crange,plt_title,export1)
%plotEk_Echogram_Niskin(svES60_filt,ek80path,[],{0 500},[],[-77 -36; -74 -35],[])
%plotEk_Echogram_Niskin(svES60,[],[],{0 500},[],[-77 -36; -74 -35],1)

%% Extract Sv values from EK80 raw data
index_type='cast'; %type of index used to query data
indexes='1:max([global_indexer.cast])'; %length of index (all data files will be processed)
ek80outpath = 'E:\2023_MSET\processed\';
%ek80outpath = 'E:\2023_MSET\processed\Ben\';
svEK80 = playfunction_rms(ek80outpath, index_type, indexes, 'sv_pc'); %query pulse compressed backscatter
load('H:\Rendhy\2023_MSET\processed\Oct92023\svEK80.mat');
load('H:\Rendhy\2023_MSET\processed\Oct92023\svES60_filtered.mat');
subset_1 = datetime("09-Oct-2023 22:32:05");
subset_2 = datetime("09-Oct-2023 23:13:51");
svEK80_subset = chop_EK60_EK80(svEK80,[],[subset_1 subset_2]);
svEK80 = impulse_noise_filter(svEK80,'EK80',1,40,2,10,0,100,'NaN',[],[],[]);
%svEK80_70_AN = attenuation_noise_filter(svEK80,'EK80',1,80,90,50,50,8,'NaN',[]);
svEK80 = transient_noise_filter(svEK80,'EK80',1,40,3,11,0,100,25,7,'NaN',75,[]);
svEK80 = background_noise_remove_RMS(svEK80,'EK80',1,50,20,-127,0.1,[]);
svEK80 = threshold(svEK80,'EK80',1,-125,-50,'tvt',[]);
%svES80_filt = residual_noise_filter(svEK80,'EK80',1,0,100,3,1); %Too Harsh
%% plot EK80 Sv values %now plotEK_echogram is obsolete, change with plotEK_echogram_niskin!!!!!
ek80globpath = 'E:\2023_MSET\processed\global_index.mat';
plotEk_Echogram_Niskin(svEK80_subset,1,[],[],{0 'inf'},[],[-70 -39],'Original',[])
plotEk_Echogram_Niskin(svEK80_70_IN,1,ek80globpath,[],{0 'inf'},[],[-70 -39],'Filtered EK80',[])
plotEk_Echogram_Niskin(svES60_filt,1,ek80path,[],{0 'inf'},[],[-77 -36],'Raw ES60 Data',[])
%% sync ES60 and EK80 data (in this case specific for ES60 38khz and EK80 38kHz)
EK80sync = synctime2ESEK(svES60,1,svEK80,1,1); % Not really needed now!!
%% Remove -999 and convert into NaN
% svNaN = svES60_filt.ch1_38.Sv;
% svNaN(svNaN==-999) = NaN;
% svES60_filt_NaN = svES60_filt;
% svES60_filt_NaN.ch1_38.Sv = svNaN;
% vect_es60_38_nan = ES60_XYZC_Vector(svES60_filt_NaN.ch1_38);
% export_pointcloud(vect_es60_38_nan, 'E:\2023_MSET\processed\Oct52023\','es60_38k_100523_NaNs');

%pc_ES60.Intensity(isnan(pc_ES60.Intensity)) = -999;
pc_EK80.Intensity(pc_EK80.Intensity == -999) = NaN; %EK80 still a lot of white spaces!
f = figure('WindowState', 'maximized');
ax1 = axes;
ax1 = pcshow(pc_EK80, ColorSource="Intensity");
dynamicDateTicks();
setDateAxes(gca, 'XLim', [min(pc_EK80.Location(:,1)) max(pc_EK80.Location(:,1))]);
caxis([-77 -36]);
zlim([0 500]);
ylim([0 98])
set(ax1,'XDir','reverse','ZDir','reverse');
xlabel(ax1,'ping number','FontSize',14);
ylabel(ax1,'EK80 horizontal range (m)','FontSize',14);
%ylabel(ax1,'EK80 horizontal range (m)','FontSize',14,'Rotation',-30,'Position',[-226,46,536]);
zlabel(ax1,'flyer depth (m)','FontSize',14);
ax1.FontSize = 14;
ax1.DataAspectRatio = [0.5*diff(ax1.XLim), 2*diff(ax1.YLim), diff(ax1.ZLim)] / diff(ax1.YLim);
view(170,0)

%% vectorization (optimized albeit EK80 and ES60 vectorization is seperate)
%vect_ek80_70 = get_time_vectors_2(svEK80.chan70); %Not needed anymore
vect_ek80_70 = get_time_vectors(svEK80.chan70);
vect_es60_38 = ES60_XYZC_Vector(svES60_filt.ch1_38);
export_pointcloud(vect_ek80_70, 'E:\2023_MSET\processed\Oct52023\','ek80_70k_100523_filt_nosync');
export_pointcloud(vect_es60_38, 'E:\2023_MSET\processed\Oct52023\','es60_38k_100523_filt_nosync');
pc_ES60 = pcread('E:\2023_MSET\processed\Oct52023\es60_38k_100523_NaNs.ply');


%% Scatter plots work no problem!! But Heavy
fig = plot3d_scatter(vect_es60_38,vect_ek80_70,[-77 -36],[-77 -36],[0 98],[0 500],[170 10]);
%% pointcloud load and plot
pc_EK80 = pcread('E:\2023_MSET\processed\Oct52023\ek80_70k_100523_filt_nosync.ply');
pc_ES60 = pcread('E:\2023_MSET\processed\Oct52023\es60_38k_100523_filt_nosync.ply');
[f2,ax1,ax2,cb] = plot3d_pc(pc_ES60,pc_EK80,[-77 -36],[-77 -36],[0 98],[0 500],[170 0],[]);
cam_3D_change(ax1,ax2,170,10);