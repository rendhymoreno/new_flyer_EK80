%% sync ES60 and EK80 data (in this case specific for ES60 38khz and EK80 38kHz)
% Future work: make agnostic; find a solution for longer ES60 (resample
% vars/pad-in NaNs); also add option of down-scalling the array!!
function synceddata = synctime2ESEK(es60,chan_es60,ek80,chan_ek80,ctdflag)
%ctdflag = 1;
ch_es60 = fieldnames(es60);
ch_ek80 = fieldnames(ek80);
fprintf('[Sync ES60 & EK80] Reading ES60 channel: %s and EK80 data channel: %s \n',ch_es60{chan_es60},ch_ek80{chan_ek80});

if chan_es60 > length(ch_es60) || chan_ek80 > length(ch_es60)
    error('[Sync ES60 & EK80] Channel selected is not available in ES60 or EK80 data')
end

if isfield(es60.(ch_es60{chan_es60}),'Sv')
    dataflag = 'Sv';
    valES60 = es60.(ch_es60{chan_es60}).Sv;
    size_es60 = size(es60.(ch_es60{chan_es60}).Sv);
elseif isfield(es60.(ch_es60{chan_es60}),'TS')
    dataflag = 'TS';
    size_es60 = size(es60.(ch_es60{chan_es60}).TS);
    valES60 = es60.(ch_es60{chan_es60}).TS;
else
    error('[Sync ES60 & EK80] Field for ES60 is not Sv nor TS!\n');
end

%size_es60 = size(es60.chanES60.Sv);
size_ek80 = size(ek80.(ch_ek80{chan_ek80}).val);
%len_es60_t = length(svES60.ch1_38.time);
%len_ek80_t = length(svEK80.chan38.vars);

est = [es60.(ch_es60{chan_es60}).time];
if ctdflag == 1
    ekt = [ek80.(ch_ek80{chan_ek80}).vars.timestamp]; %ctd timestamp
else
    ekt = [ek80.(ch_ek80{chan_ek80}).vars.timestamp_raw]; %noctd timestamp
end

if ekt > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
    disp('[Sync ES60 & EK80] timestamp of EK80 is in epoch/UNIX milliseconds\n')
    ekt = datenum(datetime(ekt,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
end

if size_es60(2)<size_ek80(2)
    synceddata = es60;
    n = size_es60(2); %resample the shorter es60 to longer ek80
    for ii = 1:n
        ind_ek80_t(ii) = dsearchn(ekt', est(ii)); %this maps values of EK80 timestamp to ES60 timestamp.
    end
    new_est = ekt; %time vector for ES60 is changed into the EK80 now
    new_es60 = NaN(size_es60(1),size_ek80(2)); %ES60 Sv reshaped to the new time vector, but Sv and range values remain
    for jj = 1:size_es60(2) %for every time vector in the original ES60
        new_es60(:,ind_ek80_t(jj)) = valES60(:,jj);
    end
    if strcmp(dataflag,'Sv')
        synceddata.(ch_es60{chan_es60}).Sv = new_es60;
    elseif strcmp(dataflag,'TS')
        synceddata.(ch_es60{chan_es60}).TS = new_es60;
    end
    synceddata.(ch_es60{chan_es60}).time = new_est;
    %syncdata = es60;
    disp('[Sync ES60 & EK80] Finished timesyncing and resizing ES60 data into EK80 length!!')
else
    synceddata = ek80;
    fields = fieldnames(ek80.chan70.vars);
    n = size_ek80(2); %resample the shorter ek80 to longer es60
    for ii = 1:n
        ind_es60_t(ii) = dsearchn(est', ekt(ii)); %every timestamp of ek80 ref to es60
    end
    new_ekt = est;
    new_ek80 = NaN(size_ek80(1),size_es60(2)); %EK80 Sv reshaped to the new time vector, but Sv and range values remain
    new_depth = NaN(1,size_es60(2));
    new_temp = NaN(1,size_es60(2));
    new_TVGstart = NaN(1,size_es60(2));
    new_abscoef = NaN(1,size_es60(2));
    new_cast = NaN(1,size_es60(2));
    new_salinity = NaN(1,size_es60(2));
    new_chloro = NaN(1,size_es60(2));
    new_oxy = NaN(1,size_es60(2));
    new_turb = NaN(1,size_es60(2));
    new_potdens = NaN(1,size_es60(2));
    new_lat = NaN(1,size_es60(2));
    new_lon = NaN(1,size_es60(2));
    new_heading = NaN(1,size_es60(2));
    new_along = NaN(1,size_es60(2));
    new_ss = NaN(1,size_es60(2));

    for jj = 1:size_ek80(2) %for every time vector in the original EK80
        new_ek80(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).val(:,jj);
        new_depth(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{3});
        new_temp(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{4});
        new_TVGstart(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{5});
        new_abscoef(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{6});
        new_cast(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{7});
        new_salinity(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{8});
        new_chloro(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{9});
        new_oxy(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{10});
        new_turb(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{11});
        new_potdens(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{12});
        new_lat(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{13});
        new_lon(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{14});
        new_heading(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{15});
        new_along(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{16});
        new_ss(:,ind_es60_t(jj)) = ek80.(ch_ek80{chan_ek80}).vars(jj).(fields{17});
    end

    synceddata.(ch_ek80{chan_ek80}).val = new_ek80;

    for kk = 1:size_es60(2)
        if ctdflag == 1
            synceddata.(ch_ek80{chan_ek80}).vars(kk).timestamp = new_ekt(kk);  %need to think about changing this because the length of timestamp
        else          %will affect the length of other variables in vars
            synceddata.(ch_ek80{chan_ek80}).vars(kk).timestamp_raw = new_ekt(kk); %(solution: make sure ES60
        end
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{3}) = new_depth(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{4}) = new_temp(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{5}) = new_TVGstart(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{6}) = new_abscoef(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{7}) = new_cast(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{8}) = new_salinity(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{9}) = new_chloro(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{10}) = new_oxy(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{11}) = new_turb(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{12}) = new_potdens(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{13}) = new_lat(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{14}) = new_lon(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{15}) = new_heading(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{16}) = new_along(kk);
        synceddata.(ch_ek80{chan_ek80}).vars(kk).(fields{17}) = new_ss(kk);
    end
    disp('[Sync ES60 & EK80] Finished timesyncing and resizing EK80 data into ES60 length!!')
end

end

%% Old Version
%{
% Future work: make agnostic; find a solution for longer ES60 (resample
% vars/pad-in NaNs); also add option of down-scalling the array!!
ctdflag = 1;
size_es60 = size(svES60.ch1_38.Sv);
size_ek80 = size(svEK80.chan70.val);
%len_es60_t = length(svES60.ch1_38.time);
%len_ek80_t = length(svEK80.chan38.vars);

est = [svES60.ch1_38.time];
if ctdflag == 1
    ekt = [svEK80.chan70.vars.timestamp]; %ctd timestamp
else
    ekt = [svEK80.chan70.vars.timestamp_raw]; %noctd timestamp
end

if ekt > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time 
  disp('timestamp of EK80 is in epoch/UNIX milliseconds')
  ekt = datenum(datetime(ekt,"ConvertFrom","epochtime",'TicksPerSecond',1e6));
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
else 
    n = size_ek80(2); %resample the shorter ek80 to longer es60
    for ii = 1:n
        ind_es60_t(ii) = dsearchn(est', ekt(ii)); %every timestamp of ek80 ref to es60
    end
    new_ekt = est;
    new_sv_ek80 = NaN(size_ek80(1),size_es60(2)); %EK80 Sv reshaped to the new time vector, but Sv and range values remain
    new_depth = NaN(1,size_es60(2));
    for jj = 1:size_ek80(2) %for every time vector in the original EK80
        new_sv_ek80(:,ind_es60_t(jj)) = svEK80.chan70.val(:,jj);
    end
    for jj = 1:size_ek80(2) %for every time vector in the original EK80
        new_depth(:,ind_es60_t(jj)) = svEK80.chan70.vars(jj).depth;
    end
    svEK80.chan70.val2 = new_sv_ek80;
    for kk = 1:size_es60(2)
      if ctdflag == 1
        svEK80.chan70.vars2(kk).timestamp = new_ekt(kk);  %need to think about changing this because the length of timestamp 
        else          %will affect the length of other variables in vars
        svEK80.chan70.vars2(kk).timestamp_raw = new_ekt(kk); %(solution: make sure ES60 
      end
        svEK80.chan70.vars2(kk).depth = new_depth(kk);
    end
%{
    if ctdflag == 1
        svEK80.chan70.vars2.timestamp = new_ekt;     %need to think about changing this because the length of timestamp 
    else                                            %will affect the length of other variables in vars
        svEK80.chan70.vars2.timestamp_raw = new_ekt; %(solution: make sure ES60 
    end
%}
    disp('Finished timesyncing and resizing EK80 data into ES60 length!!')
end
%}