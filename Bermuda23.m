% have to change variables in plotEK!!!!!
clear all;
%% add paths of all folders needed
cd(fileparts(matlab.desktop.editor.getActiveFilename)); %move matlab dir to current pwd
addpath(genpath(pwd)); %add all folders and subfolders of source code to path
addpath('E:\RMS_EK80_60\'); %add all folders and subfolders of Bermuda EK80,ES60, and CTD datasets to path
addpath('E:\2023_Bermuda\'); %add folder path of all output files
%% read niskin ctd files
ctdin = 'E:\2023_Bermuda\Dive3_7182023\StarOddi\Payload\J1580\7182023_Payload_Dive3.txt';
ctdout = 'E:\2023_Bermuda\processed\7182023_payload.mat';
ctdformat = 'tabODDI';
ctdstructbuilder(ctdin,ctdout,ctdformat);
ctd = load(ctdout); %bermuda ctd files
ctdflag = 1;

% Align corrected depth with original depth file
depthfile = 'E:\2023_Bermuda\processed\ctd_interpl.mat';
corr_depth = load(depthfile);
d_corr = corr_depth.pressure;
t_corr = corr_depth.time_utc;
d_real = ctd.pressure;

t_real = datetime(ctd.time_utc,"ConvertFrom","datenum");
%offset depth and time
abv_0_idx = d_real <= 0;
abv_0 = d_real(abv_0_idx);
offset_d = mean(abv_0);
offset_t = seconds(18);
%correction
d_real_off = d_real+abs(offset_d) + 0.23; %0.23 is estimate from graph
t_real_off = t_real - offset_t;
%plot
plot(t_real,d_real,datetime(t_corr,"ConvertFrom","datenum"),d_corr);
hold on
plot(t_real_off,d_real_off,'k')
set(gca,"YDir","reverse")
ctd_corrected_2 = ctd;
ctd_corrected_2.pressure = d_real_off;
ctd_corrected_2.time_utc = datenum(t_real_off);
%% read EK80 raw data installed on ROV and merge CTD timestamps into
%new structs (global_index.mat and ping data (three_ensemble-....mat)
ek80path = 'E:\2023_Bermuda\Dive3_7182023\EK80\38khz'; %path to raw EK80 data
ek80outpath = 'E:\2023_Bermuda\processed\dive3_bermuda\'; %output folder of synced EK80-ROV data
inject_environment = [];
tvgrangecorr = 1;
ek80parser(ek80path, ek80outpath, ctd_corrected_2,inject_environment,tvgrangecorr); %using corrected depth now
%ek80parser_noctd
%% read ES60 raw data installed on ship, converts into Sv, and synchronizes the ES60 timestamp with 
%EK80-ROV CTD timestamps into a new struct (syncedES60_sv.mat)
es60path = 'E:\2023_Bermuda\Dive3_7182023\ES60'; %ES60 raw data loc
es60out = 'E:\2023_Bermuda\processed\syncedES60_sv_dive2.mat'; %ES60 file output struct
rovinpath = 'E:\2023_Bermuda\processed\global_index.mat'; %input synced EK80-ROV data struct 
tmsync = 1; %input tmsync = 1 to timesync ES60 and EK80 timestamps / null [] if not 
es60parser_sv_withoutROV([],es60path,es60out,[],{0 'inf'}); %use this to parse EK/ES60 data and timesync between ek80 and es60 data (need EK80 data!!)
%es60parser_sv_withoutROV([],es60path,es60out,[],{0 'inf'});

%% Read payload events timestamps

event_dt = [datetime(2023,07,18,23,59,58) %winch in water @20m, lights at 1
            %datetime(2023,07,19,00,00,47) %winch turned off to see es60
            datetime(2023,07,19,00,03,44) %lights turned on to 10
            %datetime(2023,07,19,00,12,24) %winch off reached 205m
            %datetime(2023,07,19,00,36,37) %winch on lights 10
            %datetime(2023,07,19,00,40,46) %reached 110 waiting for 140m to pass us
            datetime(2023,07,19,00,44,37) %boat engine off, about to perform low light exp
            datetime(2023,07,19,00,56,31) %boat engine on/winch off soon
            %datetime(2023,07,19,01,02,57) %reached 90m
            datetime(2023,07,19,01,04,27) %light turned to 45 (experiment light)
            %datetime(2023,07,19,01,07,19) %seems like attraction?
            datetime(2023,07,19,01,10,58) %lights down to 5
            %datetime(2023,07,19,01,13,32) % possibility of layer approaching us
            datetime(2023,07,19,01,15,49) %light to 45
            datetime(2023,07,19,01,20,24) %lights off
            %datetime(2023,07,19,01,24,11) %layer below does seem to come up to payload depth
            datetime(2023,07,19,01,26,40) %lights turned on to 45
            %datetime(2023,07,19,01,28,21) % layers seems to disperse!
            %datetime(2023,07,19,01,33,09) % Going up to 35m
            %datetime(2023,07,19,01,33,17) %winch moving to 35m & layer seems to dispersed completely
            %datetime(2023,07,19,01,36,22) %winch reached 35 and winch off
            %datetime(2023,07,19,01,38,15) %layer at 35 growing strong. layer below payload dissapeared
            %datetime(2023,07,19,01,40,21) %layer at 35 is dispersing / merging with a new layer at 90m
            datetime(2023,07,19,01,47,31)]; %turning off lights
            %datetime(2023,07,19,01,50,21)]; %turning on lights to 20 
event_dn = datenum(event_dt); %datenum format

% % Niskin bottle path
% niskin_t = {'07-18-2023 23:07:00','07-18-2023 23:15:09';
%             '07-18-2023 23:26:30','07-18-2023 23:35:00';
%             '07-19-2023 00:24:00','07-19-2023 00:35:29';
%             '07-19-2023 02:27:10','07-19-2023 02:38:19';
%             '07-19-2023 02:45:40','07-19-2023 02:49:30';};

%% Events dive 2
event_dt_d2 = [datetime('17-Jul-2023 0:51:14') %light 5
               datetime('17/07/2023 0:56:53') %light 20
               datetime('17/07/2023 1:17:20') %light 40
               datetime('17/07/2023 1:20:34') %engine off
               datetime('17/07/2023 1:24:59') %light 5
               datetime('17/07/2023 1:33:57') %light 45
               datetime('17/07/2023 1:37:39') %light 5
               datetime('17/07/2023 1:51:26') %engine on ship move
               datetime('17/07/2023 1:55:57') %engine off
               datetime('17/07/2023 2:13:20')]; %light 1]
event_dn_d2 = datenum(event_dt_d2);
%% plot ES60 data with ROV overlay
svES60 = load(es60out); %load ES60 Sv data
svES60 = fix_ES60_timestamp(svES60); %remove odd timestamps
%svES60 = chop_EK60_EK80(svES60,[4 499],[]); %Dive 3 4-499
%svES60 = chop_EK60_EK80(svES60,[4 499],[datetime('17-Jul-2023 00:51:04') datetime('17-Jul-2023 2:22:48')]); %Dive 2 4-499
svES60 = chop_EK60_EK80(svES60,[4 499],[datetime('18-Jul-2023 23:59:50') datetime('19-Jul-2023 2:00:00')]); %Dive 2 4-499
%svES60_blur = conv_filter(svES60,'ES60',1,3,'average',1);
svES60 = impulse_noise_filter(svES60,'ES60',1 ,15,2,12,0,500,'NaN',[],[],1); %Not using hardcore mode works better
svES60_wn = winch_noise_filter(svES60,1,0,500,425,9,1);
svES60_na = remove_nan(svES60_wn,'ES60');
svES60_b = background_noise_remove_RMS(svES60,'ES60',1,15,10,-125,1,7 ,1); %Dive 3 BN -132 SNR 0.1 %default 50, 20, -125
svES60_f = payload_scatter_filter(svES60_na,1,depthfile,3,-60,[]);
svES60_f = remove_nan(svES60_f,'ES60');
svES60_t = threshold_backscatter(svES60_b,'ES60',1,-130,-42,'tvt',1); %-45 original
svES60_r = residual_noise_filter(svES60_b,'ES60',1,0,500,7,1); %Too Harsh
svES60_final = impulse_noise_filter(svES60_r,'ES60',1,15,2,12,400,500,'NaN',[],[]); %Not using hardcore mode works better
svES60_38 = remove_nan(svES60_final,'ES60');
svES60_blur = conv_filter(svES60_r,'ES60',1,3,'average',1);
% Chop light experiments
svES60_38_exp = chop_EK60_EK80(svES60_38,[],[datetime(2023,07,19,01,04,27) datetime(2023,07,19,01,33,17)]); %Dive 3 4-499
svES60_38_blur_exp = chop_EK60_EK80_EK80(svES60_blur,[],[datetime(2023,07,19,01,04,27) datetime(2023,07,19,01,33,17)]); %Dive 3 4-499

% Plot
plotEk_Echogram_Niskin(svES60,1,[],event_dn,{0 500},[],[-77 -36; -77 -36],' ',[]) %Plot with corrected path and events all channels
plotEk_Echogram_Niskin(svES60_38,1,[],[],{0 500},[],[-77 -36; -77 -36],' ',[]) %Simple plot with 1 channels
plotEk_Echogram_Niskin(svES60_38,1,depthfile,400,{0 500},[],[-75 -39; -77 -36],[],[]) %Simple plot with 1 channel with range event
plotEk_Echogram_Niskin(svES60_38,1,ctd_corrected_2,[],{0 500},[],[-75 -39; -77 -36],[],[]) %Simple plot with 1 channel with range event
%plotEk_Echogram_Niskin(svES60_filt,1,ek80path,[],{0 500},[],[-77 -36],[],[])

%% Echometrics
load('E:\2023_Bermuda\processed\svES60_dive3_38kHz_filtered.mat');
tes = resample_weighted_mean(svES60_38,'ES60',1,2,1,1);
svES60_38_exp = chop_EK60_EK80(tes,[],[datetime(2023,07,19,01,04,27) datetime(2023,07,19,01,33,17)]);
%echometrics_svES60_38 = echometrics(svES60_blur,'ES60',1,[-130 -40],[]);
%echometrics_svES60_38 = echometrics(svES60_38,'ES60',1,[-130 -40],[]);
% Experiment layer
echometrics_svES60_38 = echometrics(svES60_38_exp,'ES60',1,[-130 -40],event_dt);
echometrics_svES60_38 = echometrics(svES60_38_blur_exp,'ES60',1,[-130 -40],event_dt);
%% Extract Sv values from EK80 raw data
index_type='cast'; %type of index used to query dataasu = []
indexes='1:max([global_indexer.cast])'; %length of index (all data files will be processed)
svEK80 = playfunction_rms(ek80outpath, index_type, indexes, 'sv_pc'); %query pulse compressed backscatter %'PhysAng_alongship'  'PhysAng_athwartship'
%svEK80_2 = playfunction_rms(ek80outpath, index_type, indexes, 'sv_pc2') %query pulse compressed backscatter
%svEK80 = playfunction_rms(ek80outpath, index_type, indexes, 'power_pc'); %query pulse compressed backscatter
%% plot EK80 Sv values %now plotEK_echogram is obsolete, change with plotEK_echogram_niskin!!!!!
plotEk_Echogram_Niskin(TSEK80,1,[],[],{0 100},[],[-70 -40],[],[]) %TS
plotEk_Echogram_Niskin(svEK80_blur,1,[],[],{0 100},[],[-77 -41],[],[])
plotEk_Echogram_Niskin(svEK80_dec,1,[],[],{0 100},[],[-77 -41],[],[])

%% FIltering EK80
% Harsh filter:
% filt_inp_hard = threshold(svEK80,'EK80',1,-55,0,[],[]);
% [thresf,mask1] = impulse_noise_filter(filt_inp_hard,'EK80',1,40,2,12,0,100,'NaN',[],[]);
% filt_inp_soft = threshold(svEK80,'EK80',1,-70,0,[],[]);
% [thresf,mask2] = impulse_noise_filter(filt_inp_hard,'EK80',1,40,2,12,0,100,'NaN',[],[]);
% mask_f = mask1.*mask2;
% 
% svEK80_filt = svEK80;
% val = svEK80.chan38.val;
% val(mask1) = -999;
% svEK80_filt.chan38.val = val;
% 
% svEK80_filt = svEK80;
% val = svEK80.chan38.val;
% val(mask2) = -999;
% svEK80_filt.chan38.val = val;
% plotEk_Echogram_Niskin(svEK80_filt,1,[],[],{0 100},[],[-77 -41],[],[])
% plotEk_Echogram_Niskin(svEK80_f,1,[],[],{0 100},[],[-77 -41],[],[])

svEK80 = impulse_noise_filter(svEK80,'EK80',1,40,2,8,0,100,'NaN','remove_gap',5,[]);
%svEK80_f = impulse_noise_filter(svEK80,'EK80',1,40,2,8,0,100,'NaN',[],[],1);
svEK80 = background_noise_remove_RMS(svEK80,'EK80',1,50,20,-125,1,0.1,[]);
svEK80 = threshold_backscatter(svEK80,'EK80',1,-125,-40,'tvt',[]);  %50 thres too hard
svEK80 = residual_noise_filter(svEK80,'EK80',1,0,100,3,1); %Too Harsh
svEK80_blur = conv_filter(svEK80,'EK80',1,3,'average',1);
svEK80_res = resample_weighted_mean(svEK80_r, 'EK80',1, 3, 2, 1);
svEK80_exp = chop_EK60_EK80(svEK80_r,[],[datetime(2023,07,19,01,04,27) datetime(2023,07,19,01,33,17)]);

%% TS EK80
% Extract TS values from EK80 raw data
index_type='cast'; %type of index used to query dataasu = []
indexes='1:max([global_indexer.cast])'; %length of index (all data files will be processed)
TSEK80 = playfunction_rms(ek80outpath, index_type, indexes, 'ts_pc');
ang_along = playfunction_rms(ek80outpath, index_type, indexes, 'PhysAng_alongship');
ang_athwart = playfunction_rms(ek80outpath, index_type, indexes, 'PhysAng_athwartship');
%% Single Target Tracking EK80
TSEK80_i = impulse_noise_filter(TSEK80,'EK80',1,40,2,8,0,100,'NaN','remove_gap',5,[]);
%svEK80_f = impulse_noise_filter(svEK80,'EK80',1,40,2,8,0,100,'NaN',[],[],1);
TSEK80_b = background_noise_remove_RMS(TSEK80_i,'EK80',1,50,20,-125,1,0.1,[]);
TSEK80_t = threshold(TSEK80_b,'EK80',1,-125,0,[],[]);  %50 thres too hard
TSEK80_r = residual_noise_filter(TSEK80_t,'EK80',1,0,100,3,[]); %Too Harsh
%TSEK80_blur = conv_filter(TSEK80_r,'EK80',1,3,'average',1);
%TSEK80_res = resample_weighted_mean(TSEK80_r, 'EK80',1, 2, 1, []); %Need to change to accomodate vars
TSEK80_exp = chop_EK60_EK80(TSEK80_r,[],[datetime(2023,07,19,01,04,27) datetime(2023,07,19,01,33,17)]);
ang_along = chop_EK60_EK80(ang_along,[],[datetime(2023,07,19,01,04,27) datetime(2023,07,19,01,33,17)]);
ang_athwart = chop_EK60_EK80(ang_athwart,[],[datetime(2023,07,19,01,04,27) datetime(2023,07,19,01,33,17)]);
plotEk_Echogram_Niskin(TSEK80_exp,1,[],[],{0 100},[],[-77 -41],[],[])

alongship = ang_along.chan38.val;
athwartship = ang_athwart.chan38.val;
load('E:\2023_Bermuda\processed\dive3_bermuda\alongship_data_chopped.mat');
load('E:\2023_Bermuda\processed\dive3_bermuda\athwartship_data_chopped.mat');
load('E:\2023_Bermuda\processed\dive3_bermuda\TSEK80_chopped_filt.mat');
[TSEK80_targets,singletargetdata] = single_targets(TSEK80_exp,'EK80',alongship,athwartship,[0 100],[-70 0],6,[0.5 1.5],...
    7,2,2); %std angle 1 beam comp 7 %less conservative: thres -70, beam 14
plotEk_Echogram_Niskin(TSEK80_exp,1,[],[],{0 100},[],...
    [-70 -30],[],[]); %min(TSEK80_targets.chan38.val,[],'all') -60 max(TSEK80_targets.chan38.val,[],'all')
plotEk_Echogram_Niskin(TSEK80_targets,1,[],[],{0 100},[],[-50 -28],[],[]);
st_analysis(TSEK80_targets,[0; -70; -55; -47; -40],[0; -55; -47; -40; -30],event_dt);
target_tracks=track_targets_angular_RMS(TSEK80_targets,singletargetdata);
for ii = 1:numel(target_tracks.target_id)
    pnum(ii) = numel(target_tracks.target_ping_number{ii});
end
max(pnum)
plot_tracks_st(TSEK80_targets,singletargetdata,target_tracks,event_dt,'colored_track');
%% Echostatistics EK80
svEK80_dec = reject_pings_payload_depth(svEK80_exp,1);
%svEK80_decblur = conv_filter(svEK80_dec,'EK80',1,3,'average',1);
plotEk_Echogram_Niskin(svEK80_dec,1,[],[],{0 100},[],[-77 -41],[],[])
plotEk_Echogram_Niskin(svEK80_exp,1,[],[],{0 100},[],[-77 -41],[],[])
echometrics_svEK80_38 = echometrics(svEK80_dec,'EK80',1,[-130 -40],event_dt);
echometrics_svEK80_38 = echometrics(svEK80_blur,'EK80',1,[-130 -40],event_dt);

%% Creating new Payload path from interpolation (NEED TO INCORPORATE INTERPOLATION LENGTH TO FOLLOW WHICH IS LONGER (ES60vsEK80)
% 
%for ii = 1:length(cursor_info)
%payload_pos_raw(ii,:) = cursor_info(ii).Position;
%end

%load position data
load('E:\2023_Bermuda\processed\payload_pos_raw.mat');
load('E:\2023_Bermuda\processed\global_index.mat');
%ctdFname = 'E:\2023_Bermuda\processed\ctd_interpolation.mat'; %interpolated
%ctdFname = 'E:\2023_Bermuda\processed\7182023_payload.mat'; %StarODDI

[x, x_index] = unique(payload_pos_raw(:,1));
y = payload_pos_raw(:,2);
t_start = svES60.ch1_38.time(1);
t_end = svES60.ch1_38.time(end);
F = griddedInterpolant(x,y(x_index));

sizet = length([global_indexer.timestamp]);
xq = linspace(t_start,t_end,sizet);
yq = F(xq);

ctd_interp.time_utc = xq';
ctd_interp.pressure = yq';
save(ctdFname,'-struct','ctd_interp');

%optional plot of new interpolated values
%fig2 = figure();
%plot(xq, yq,'.')
%hold on
%plot(x,y,'ro')
%set(gca,'YDir','reverse');
%title('interpolated ROV time vs depth');

%plotEk_Echogram_Niskin(svES60,ctdFname,[],{0 300},[],[-77 -36; -74 -35])
plotEk_Echogram_Niskin(svEK80,[],event_dn,{0 'inf'},[],[-80 -60; -50 -30])
%hold on
%for i = 1:length(event_dn)
%    plot([event_dn(i) event_dn(i)],[0 300],'--k','LineWidth',1.5)
%end

%% sync ES60 and EK80 data (in this case specific for ES60 38khz and EK80 38kHz)
% Future work: make agnostic; find a solution for longer ES60 (resample
% vars/pad-in NaNs); also add option of down-scalling the array!!

size_es60 = size(svES60.ch1_38.Sv);
size_ek80 = size(svEK80.chan38.val);
%len_es60_t = length(svES60.ch1_38.time);
%len_ek80_t = length(svEK80.chan38.vars);

est = [svES60.ch1_38.time];
if ctdflag == 1
    ekt = [svEK80.chan38.vars.timestamp]; %ctd timestamp
else
    ekt = [svEK80.chan38.vars.timestamp_raw]; %noctd timestamp
end

if size_es60(2)<size_ek80(2)
    n = size_es60(2); %resample the shorter es60 to longer ek80
    for ii = 1:n
        ind_ek80_t(ii) = dsearchn(ekt', est(ii)); %this maps values of EK80 timestamp to ES60 timestamp.
    end
    new_est = ekt; %time vector for ES60 is changed into the EK80 now
    new_sv_es60 = NaN(size_es60(1),size_ek80(2)); %ES60 Sv reshaped to the new time vector, but Sv and range values remain
    for jj = 1:size_es60(2) %for every time vector in the original ES60
        new_sv_es60(:,ind_ek80_t(jj)) = svES60.ch1_38.Sv(:,jj);
    end
    svES60.ch1_38.Sv = new_sv_es60;
    svES60.ch1_38.time = new_est;
    disp('Finished timesyncing and resizing ES60 data into EK80 length!!')
else %% No solution yet, need to think about this later
    n = size_ek80(2); %resample the shorter ek80 to longer es60
    for ii = 1:n
        ind_es60_t(ii) = dsearchn(est', ekt(ii));
    end
    new_ekt = est;
    new_sv_ek80 = NaN(size_ek80(1),size_es60(2)); %EK80 Sv reshaped to the new time vector, but Sv and range values remain
    for jj = 1:size_ek80(2) %for every time vector in the original EK80
        new_sv_ek80(:,ind_es60_t(jj)) = svEK80.chan38.val(:,jj);
    end
    svEK80.chan38.val = new_sv_ek80;
    if ctdflag == 1
        svEK80.chan38.vars.timestamp = new_ekt;     %need to think about changing this because the length of timestamp 
    else                                            %will affect the length of other variables in vars
        svEK80.chan38.vars.timestamp_raw = new_ekt; %(solution: make sure ES60 
    end
    disp('Finished timesyncing and resizing EK80 data into ES60 length!!')
end

%% Plugging in new corrected depths into EK80 struct %its a mess because need to plug in the interpolated CTD into EK80
%plug new CTD into EK80 data (assuming EK80 is not upsized!! If EK80 needs
%to be upsized then this will not work and ctd values need to be
%interpolated

ctdFname = 'E:\2023_Bermuda\processed\ctd_interpolation.mat';
ctd_interp = load(ctdFname);
ekt = [svEK80.chan38.vars.timestamp];
%for dsearchn columns must be same dimension!! make this into function
%this finds index of timestamps of new ctdi data that matches the EK80
%timestamp 
if size(ctd_interp.time_utc,2) > 1 && size(ekt,2) == 1
    indctdi = dsearchn(ctd_interp.time_utc',ekt);
elseif size(ctd_interp.time_utc,2) > 1 && size(ekt,2) > 1 %|| size(ctd_interp.time_utc,2) == 1 && size(ekt,1) == 1
    indctdi = dsearchn(ctd_interp.time_utc',ekt');
elseif size(ctd_interp.time_utc,2) == 1 && size(ekt,2) > 1
    indctdi = dsearchn(ctd_interp.time_utc,ekt');
else
    indctdi = dsearchn(ctd_interp.time_utc,ekt);
end

n_depth_ek80 = ctd_interp.pressure(indctdi);

for kk=1:length(n_depth_ek80)
    svEK80.chan38.vars(kk).depth_corrected = n_depth_ek80(kk);
end
disp('depth correction has been applied')

%% vectorization (optimized albeit EK80 and ES60 vectorization is seperate)

svEK80_38 = svEK80.chan38;
vect_ek80_38 = get_time_vectors(svEK80_38);
vect_es60_38 = ES60_XYZC_Vector(svES60_38.ch1_38);

export_pointcloud(vect_ek80_38, 'E:\2023_Bermuda\processed\dive3_bermuda\','ek80_38k_dive3_nosync');
export_pointcloud(vect_es60_38, 'E:\2023_Bermuda\processed\dive3_bermuda\','es60_38k_dive3_nosync');

%% Plotting pc
pc_EK80 = pcread('E:\2023_Bermuda\processed\dive3_bermuda\ek80_38k_dive3_nosync.ply');
pc_ES60 = pcread('E:\2023_Bermuda\processed\dive3_bermuda\es60_38k_dive3_nosync.ply');
[f2,ax1,ax2,cb,hlink] = plot3d_pc(pc_ES60,pc_EK80,[-77 -36],[-77 -36],[0 98],[0 500],[170 0],[]);
cam_3D_change(ax1,ax2,210,30); %click both layers then you can zoom
ax1.CameraTarget = [(ans(1)-datenum(minutes(15))) 0 150]; %this is to shift the camera around
zoom = [datenum(datetime(2023,07,19,01,04,27)) datenum(datetime(2023,07,19,01,33,17))]; %crop

%% Plotting in 3D Scatter (only EK80 38 and ES60 38) 
%Restructing plot for overview (3D overview)

ax2 = axes; %ES60 first
scatter3(vect_es60_38(:,1),vect_es60_38(:,2),vect_es60_38(:,3),1,vect_es60_38(:,4),"filled","Marker","square");
axis tight; colorbar; 
set(gca,'XDir','reverse','ZDir','reverse'); %mandatory
caxis([-77 -36]); %clim([-75 -40]) for EK500 / ([-75 -65]) for monochrome / clim for matlab 2022b caxis for lower
ylim([0 100]); 
zlim([0 500]); 
xlabel('ping number'); ylabel('EK80 range (m)'); zlabel('ROV depth (m)'); 
%xticks([0:200:1800]);
cptcmap('EK500',ax2);
%colormap(ax2,flipud(gray)) %greysc inv
%colormap(ax2,'gray') %

view(150,30); %view from ES60 viewpoint;
%view(170,30); %optional view
%view(180,0); %view ES60 depth profile
%view(180,90); %top view EK80

ax1 = axes('Position', ax2.Position); %EK80 part
%scatter3(vect_ek80_38(:,1),vect_ek80_38(:,2),vect_ek80_38(:,3),3,vect_ek80_38(:,4),"filled","Marker","square",...
%    'MarkerFaceAlpha',.8,'MarkerEdgeAlpha',.8); 
ss = scatter3(vect_ek80_38(:,1),vect_ek80_38(:,2),vect_ek80_38(:,3),3,vect_ek80_38(:,4),"filled","Marker","square");
axis tight; colorbar; set(gca,'XDir','reverse','ZDir','reverse'); 
zlim([0 500]); %mandatory
caxis([-85 -65]); cptcmap('EK60_2',ax1); hold on;
ax1.Visible = 'off';
ax1.XTick = [];
ax1.YTick = [];

%for zz = 1:length(lht_dn) %EK80 lights
%plot3(timex_80(zz,:),timey_80(zz,:),timez_80(zz,:),'r','LineWidth',1.5); %use k for ES500 cmap or m for greyscale
%set(gca,'XDir','reverse','ZDir','reverse'); axis tight; %mandatory
%%lgd = legend(ax1.Children(1),'Light off 1');
%%lgd.FontSize = 14;
%end

%for zz = 1:length(lht_dn) %ES60 lights
%plot3(timex_60(zz,:),timey_60(zz,:),timez_60(zz,:),'r','LineWidth',1.5); %use k for ES500 cmap or m for greyscale
%set(gca,'XDir','reverse','ZDir','reverse'); axis tight; %mandatory
%%lgd = legend(ax1.Children(1),'Light off 1');
%%lgd.FontSize = 14;
%end

%lgd = legend({'','2','3','4','5','6','7'},'AutoUpdate','off');
%lgd.FontSize = 14;
%lgd.Location = 'southeast';

% payload depth
%plot3(berak,zeros(1,1807),[sv.chan70.vars.depth],'k','LineWidth',1.5); %use k for ES500 cmap or m for greyscale
%set(gca,'XDir','reverse','ZDir','reverse'); axis tight; %mandatory
%%lgd = legend(ax1.Children(1),'ROV Track');
%%lgd.FontSize = 14;

hLink = linkprop([ax2,ax1],{'XLim','ZLim','Position','view'});
setappdata(gcf,'StoreTheLink',hLink);
cb1 = colorbar(ax1,'Position',[0.81 0.1 0.03 0.815]); % [left bottom width height]
%cb1 = colorbar(ax1); % [left bottom width height]
cb2 = colorbar(ax2,'Position',[0.91 0.1 0.03 0.815]);
cb1.Label.String = 'EK80 Sv (dB ref 1m^-1)';
cb2.Label.String = 'ES60 Sv (dB ref 1m^-1)';
cb1.FontSize = 16;
cb2.FontSize = 16;
%ax2.XTick = 0:100:1800;
%ax2.YTick = [0,2:2:40];
ax2.Position = [0.1    0.1100    0.7    0.8];
axis('tight')
ax2.TickDir = 'out';
ax2.FontSize = 18;
zlim([0 300])



