%MaxBeamComp=4; %Beam Pattern Correction in dB 
%pulse length lower thres
%pulse length higher thres
%MaxStdMinAxisAngle=0.6; %Alongship ST Deviation of angle 0-45 deg
%MaxStdMajAxisAngle=0.6;%Athwatship ST Deviation of angle 0-45 deg
function [dataoutStruct,single_targets] = single_targets(data,trans,alongship,athwartship,range,tsrange,PLDL,normpl,MaxBeamComp,MaxStdMinAxisAngle,MaxStdMajAxisAngle)

if ~isempty(range)
    minr = range(1); %min TS Thres
    maxr = range(2); %max TS thres
    %rdec = 1;
end

if ~isempty(tsrange)
    min_TS = tsrange(1); %min TS Thres
    max_TS = tsrange(2); %max TS thres
else
    min_TS = -70; %min TS Thres
    max_TS = 0; %max TS thres
end

if isempty(PLDL)
    PLDL =6;
end

if ~isempty(normpl)
    MinNormPL=normpl(1); %pulse length lower thres
    MaxNormPL=normpl(2); %pulse length higher thres
else
    MinNormPL=0.7; %pulse length lower thres
    MaxNormPL=1.5; %pulse length higher thres
end

if isempty(MaxBeamComp)
    MaxBeamComp =6;
end

if isempty(MaxStdMinAxisAngle)
    MaxStdMinAxisAngle =6;
end

if isempty(MaxStdMajAxisAngle)
    MaxStdMajAxisAngle =6;
end

% Parsing data from trans

% thres1 = threshold(1);
% thres2 = threshold(2);
%datafilt = data;
% if ~isempty(eventdn)
%     plotevt = 1;
%     if isdatetime(eventdn)
%         event_dn = eventdn;
%     else
%         event_dn = datetime(eventdn,"ConvertFrom","datenum");
%     end
% else
%     plotevt = 0;
%     event_dn = 0;
% end

chan = fieldnames(data);
for ch = 1:length(chan)
if strcmp(trans,'ES60') || strcmp(trans,'EK60')
    if isfield(data.(chan{ch}),'Sv')
        error('[ST] Data has to be TS with physical angle data!')
    elseif isfield(data.(chan{ch}),'TS')
        datain_log = data.(chan{ch}).TS;
        dataflag = 'TS';
    end
    r = data.(chan{ch}).range;
    dr = r(2)-r(1);
    t = datetime([data.(chan{ch}).time],"ConvertFrom","datenum");
elseif strcmp(trans,'EK80')
    if ~strcmp(data.(chan{ch}).type,'ts_pc')
        error('[ST] Data has to be TS with physical angle data!')
    else
        if isstruct(alongship) %then likely athwartship is struct as well
            alongship = alongship.(chan{ch}).val;
            athwartship = athwartship.(chan{ch}).val;
        end
        
        datain_log = [data.(chan{ch}).val];
        BW_along = data.(chan{ch}).cal.BW_Minor_fc;
        BW_athwart = data.(chan{ch}).cal.BW_Major_fc;
        samp_interval = data.(chan{ch}).cal.sample_interval;
        c = mean([data.(chan{ch}).vars.soundspeed]);
        t_eff = data.(chan{ch}).cal.t_eff;
        r = [data.(chan{ch}).range];
        %tt = NaN(size(dataout_log,2),1);
        t = [data.(chan{ch}).vars.timestamp];
        %depth = [data.(chan{ch}).vars.depth]';
        if t(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
            t = datetime(t,"ConvertFrom","epochtime",'TicksPerSecond',1e6);
        else
            t = datetime(t,"ConvertFrom","datenum");
        end
        %datetime([data.(chan{ch}).time],"ConvertFrom","datenum");
        
        if size(alongship,2)==size(athwartship,2) && size(alongship,1)==size(athwartship,1)
            along = alongship;
            athwart = athwartship;
        else
            error('[Single target detection] Sizes of Physical angle alongship and athwartship are not similar!')
        end

        if size(along,2)==size(datain_log,2) && size(along,1)==size(datain_log,1)
            fprintf('[Single target detection] Detected TS, alongship, and athwartship angles at the same size. Performing Calculations\n')
        else
            error('[Single target detection] Sizes of Physical angle alongship and athwartship are not similar to TS data!')
        end
    end
end

if size(r,1) == 1
    r = r';
end

if isempty(range)
    minr = 0;
    maxr = max(r);
end

% Sample shuffling 
%idx_r=idx_r_tot;
Idx_samples_lin_tot=reshape(1:size(datain_log,1)*size(datain_log,2),size(datain_log,1),size(datain_log,2));
%Idx_samples_lin=Idx_samples_lin_tot(idx_r,idx_pings);
Range = repmat(r,1,size(datain_log,2));
idx_r_tot = 1:size(datain_log,1);

% Thresholding and range
range_mask = r >= minr & r < maxr;
idx_r_min = find(range_mask, 1, 'first');
thres_mask = datain_log > min_TS & datain_log < max_TS;
fprintf('[Single target detection] Masking TS values outside range: [%i-%i m] and TS: [%i-%i dB]\n',minr,maxr,min_TS,max_TS);
%dataout_log = dataout_log(range_mask,:);
datain_log(~range_mask,:) = NaN; 
datain_log(~thres_mask) = NaN;
%dataout_log = dataout_log(thres_mask);
along(~range_mask,:) = NaN;
athwart(~range_mask,:) = NaN;
along(~thres_mask) = NaN;
athwart(~thres_mask) = NaN;
%along = along(range_mask,:);
% athwart = athwart(range_mask,:);

% SIMRAD BEAM COMPENSATION
simradBeamComp = simradBeamCompensation(BW_along, BW_athwart, along, athwart); %Does for all pings

% Calculating Samples
dt = samp_interval;
dr = dt*c/2;
Np_t = double(floor(t_eff/dt));
%t_eff = t_eff/4; %????
%Np_t = ceil(Np_t/4); %???

nb_samples = size(datain_log,1);
% [T,N]=trans_obj.get_pulse_Teff(idx_ping);
N=repmat(Np_t,nb_samples,1);
idx_r = [1:nb_samples];
Np=min(N(1),numel(idx_r)-2);
% T=T(1); %no division by 4

% Peak finding
dataout = datain_log;
dataout(dataout==-999) = NaN;
dataout(dataout < min_TS - MaxBeamComp) = min_TS - MaxBeamComp;

f_peak_func = @(x) findpeaks(x,...
    'MinPeakHeight',min_TS-MaxBeamComp,...
    'WidthReference','halfprom',...
    'MinPeakDistance',Np);
idx_peaks_lin = [];
width_peaks = [];

tic;
if any(dataout>min_TS-MaxBeamComp,'all')
    [~,idx_peaks_lin_tmp,width_peaks_tmp ,~] = f_peak_func(dataout(:));
    idx_peaks_lin  =[idx_peaks_lin_tmp];
    width_peaks = [width_peaks_tmp];
end

% [~,idx_peaks_lin,width_peaks ,~] = findpeaks(dataout(:),...
%                 'MinPeakHeight',min_TS-MaxBeamComp,...
%                 'WidthReference','halfprom',...
%                 'MinPeakDistance',(MaxNormPL*Np_t),...
%                 'MinPeakWidth',(MinNormPL*Np_t*2),...
%                 'MaxPeakWidth',(MaxNormPL*Np_t*3));

fprintf('[Single target detection] Completed in %0.1f secs \n',toc);
%idx_peaks_lin is a single vector that is indexes of targets
%width_peaks is a single vector as well
%dt = samp_interval;
%dr = dt*c/2;
Np_t = double(floor(t_eff/dt));
t_eff = t_eff/4; %????
%Np_t = ceil(Np_t/4); %???

%dt=trans_obj.get_params_value('SampleInterval',idx_ping(1));
%dr=dt*mean(trans_obj.get_soundspeed(idx_r))/2;

%[Teff,Neff]=trans_obj.get_pulse_comp_Teff(idx_ping(1)); %Same like before
%[T,N]=trans_obj.get_pulse_length(idx_ping(1));
%T = data.(chan{1}).cal.pulse_length;
Teff = t_eff;
Neff = Np_t;
width_peaks = (Neff+1)*ones(size(idx_peaks_lin));
nb_targets = numel(idx_peaks_lin);
max_pulse_length = 2*nanmax(width_peaks);
samples_targets_comp=nan(max_pulse_length,nb_targets);
samples_targets_along=nan(max_pulse_length,nb_targets);
samples_targets_athwart=nan(max_pulse_length,nb_targets);

for itt=1:nb_targets
    idx_pulse=idx_peaks_lin(itt)-width_peaks(itt):idx_peaks_lin(itt)+width_peaks(itt);
    idx_pulse(idx_pulse<=0)=[];
    idx_pulse(idx_pulse>numel(dataout))=[];
    samples_targets_comp(1:numel(idx_pulse),itt)=simradBeamComp(idx_pulse);
    samples_targets_along(1:numel(idx_pulse),itt)=along(idx_pulse);
    samples_targets_athwart(1:numel(idx_pulse),itt)=athwart(idx_pulse);
end

comp=simradBeamComp(idx_peaks_lin);
std_along = nanstd(samples_targets_along,0,1);
std_athwart = nanstd(samples_targets_athwart,0,1);

idx_rem=comp(:)'>MaxBeamComp|std_along>MaxStdMinAxisAngle|std_athwart>MaxStdMajAxisAngle|...
    dataout(idx_peaks_lin)'+comp(:)'<min_TS|...
    dataout(idx_peaks_lin)'+comp(:)'>max_TS;

idx_peaks_lin(idx_rem)=[];
width_peaks(idx_rem)=[];
fprintf('[Single target detection] Detected %i targets (%0.2f%% of data). Saving output\n',...
    length(idx_peaks_lin),length(idx_peaks_lin)*100 / (size(datain_log,1)*size(datain_log,2)) );
idx_samples=rem(idx_peaks_lin,size(dataout,1));
idx_samples(idx_samples==0)=nb_samples;
Idx_samples_lin = repmat([1:size(datain_log,1)]',1,size(datain_log,2));
idx_samples_lin=Idx_samples_lin(idx_peaks_lin);
Ping = repmat(1:size(dataout,2),size(dataout,1),1);
idx_ping=Ping(idx_peaks_lin);
Target_range_min=Range(idx_peaks_lin)'-width_peaks'/2*dr;
Target_range_max=Range(idx_peaks_lin)'+width_peaks'/2*dr;
dataout_TS_comp = NaN(size(dataout,1),size(dataout,2));
TS_comp=dataout(idx_peaks_lin)'+simradBeamComp(idx_peaks_lin)';
%% Saving results
single_targets  = init_st_struct_rms(numel(idx_peaks_lin));
single_targets.TS_comp=TS_comp;
single_targets.TS_uncomp=dataout(idx_peaks_lin)';
single_targets.Target_range=Range(idx_peaks_lin)';
single_targets.idx_r= (idx_r_tot(idx_samples)+idx_r_min-1)';
single_targets.Target_range_min=Target_range_min;
single_targets.Target_range_max=Target_range_max;
single_targets.Angle_minor_axis=along(idx_peaks_lin)';
single_targets.Angle_major_axis=athwart(idx_peaks_lin)';
single_targets.Ping_number=idx_ping';
single_targets.time=t(idx_ping)';
single_targets.idx_target_lin=idx_samples_lin;
single_targets.pulse_env_before_lin=width_peaks'/2*dt;
single_targets.pulse_env_after_lin=width_peaks'/2*dt;
single_targets.PulseLength_Normalized_PLDL=width_peaks';
single_targets.TargetLength=width_peaks';

for ii=1:length(idx_samples)
   idx_x = idx_ping(ii);
   idx_min = dsearchn(Range(:,idx_x),Target_range_min(ii));
   idx_max = dsearchn(Range(:,idx_x),Target_range_max(ii));
   idx_y = [idx_samples(ii)];
   if idx_y > idx_min & idx_y < idx_max
       idx_y = [idx_min:idx_max];
   elseif idx_y > idx_min
       idx_y = [idx_min:idx_y];
   else
       idx_y = [idx_samples(ii)];
   end
   %dataout_TS_uncomp(idx_y,idx_x) = dataout(idx_y,idx_x); %uncomp TS
   dataout_TS_comp(idx_y,idx_x) = TS_comp(ii); %comp TS
end

%% Saving targets into a TS struct
dataoutStruct = data;
dataoutStruct.(chan{ch}).val = dataout_TS_comp;

%% Old Code
% comp=simradBeamComp(idx_peaks_lin);
% idx_rem = comp > MaxBeamComp;
% idx_peaks_lin(idx_rem)=[]; %removes values
% width_peaks(idx_rem)=[];
% 
% idx_samples_lin = Idx_samples_lin_tot(idx_peaks_lin);
% idx_samples=rem(idx_peaks_lin,size(dataout,1)); %Indexes of "range samples"
% idx_samples(idx_samples==0)=size(dataout,1); %nb_samples = size(dataout,1)
% Ping = repmat(1:size(dataout,2),size(dataout,1),1);
% idx_pings=Ping(idx_peaks_lin); %????
% 
% dataout_TS_uncomp = NaN(size(dataout,1),size(dataout,2));
% dataout_TS_comp = NaN(size(dataout,1),size(dataout,2));
% TS_comp=dataout(idx_peaks_lin)'+simradBeamComp(idx_peaks_lin)';
% 
% Target_range_min=Range(idx_peaks_lin)'-width_peaks'/2*dr;
% Target_range_max=Range(idx_peaks_lin)'+width_peaks'/2*dr;

% for ii=1:length(idx_samples)
%    idx_x = idx_pings(ii);
%    idx_min = dsearchn(Range(:,idx_x),Target_range_min(ii));
%    idx_max = dsearchn(Range(:,idx_x),Target_range_max(ii));
%    idx_y = [idx_samples(ii)];
%    if idx_y > idx_min & idx_y < idx_max
%        idx_y = [idx_min:idx_max];
%    elseif idx_y > idx_min
%        idx_y = [idx_min:idx_y];
%    else
%        idx_y = [idx_samples(ii)];
%    end
%    dataout_TS_uncomp(idx_y,idx_x) = dataout(idx_y,idx_x); %uncomp TS
%    dataout_TS_comp(idx_y,idx_x) = TS_comp(ii); %comp TS
%    % idx_min = dsearchn(Range(:,idx_x),Target_range_min(ii));
%    % idx_max = dsearchn(Range(:,idx_x),Target_range_max(ii));
% end

% %% Saving results
% %Saving targets into a TS struct
% dataoutStruct = data;
% dataoutStruct.(chan{ch}).val = dataout_TS_comp;
% %dataoutStruct.(chan{ch}).val2 = dataout_TS_uncomp;
% %dataoutStruct.(chan{ch}).type = 'val: ts_pc_comp; val2: ts_pc_uncomp';
% 
% %Saving single target information into long vector format
% single_targets.time=t(idx_pings)';
% single_targets.timestamp=datenum(t(idx_pings))';
% single_targets.TS_comp=TS_comp; %Compensated by beam model
% single_targets.TS_uncomp=dataout(idx_peaks_lin)'; %Original TS
% single_targets.Target_range=Range(idx_peaks_lin)'; %Original Range of target??
% single_targets.Target_range_disp=Range(idx_peaks_lin)'+c*t_eff/2; %Range of the peak of the target?
% single_targets.idx_r= (idx_r_tot(idx_samples)+idx_r_min-1)'; %idx_r_tot = [1,2,...,length(r)], idx_r_min = index of rmin (1 if rmin = 0)
% single_targets.Target_range_min=Target_range_min; %start range of target
% single_targets.Target_range_max=Target_range_max; %end range of target
% single_targets.StandDev_Angles_Minor_Axis=zeros(size(idx_peaks_lin))'; %not calculated 
% single_targets.StandDev_Angles_Major_Axis=zeros(size(idx_peaks_lin))'; %not calculated
% single_targets.Angle_minor_axis=along(idx_peaks_lin)'; %alongship angles
% single_targets.Angle_major_axis=athwart(idx_peaks_lin)'; %athwart angles
% single_targets.Ping_number=idx_pings'; %ping number
% single_targets.nb_valid_targets=numel(idx_samples_lin)'; %total number of valid targets
% single_targets.idx_target_lin=idx_samples_lin; %indexes of sample targets
% single_targets.pulse_env_before_lin=width_peaks'/2*dt; %seconds before peak
% single_targets.pulse_env_after_lin=width_peaks'/2*dt; %secs after peak
% single_targets.Transmitted_pulse_length=t_eff*ones(size(idx_peaks_lin')); %effective pulse length/4 in secs
% single_targets.PulseLength_Normalized_PLDL=width_peaks'; %


end

end
