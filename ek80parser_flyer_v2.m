% 2026-5-6: New function to parse flyer quickly!
% 2026-5-11:Implement way to either save files or pass to workspace
% instead! For now it is simply save file

function ek80parser_flyer_v2(defaultPath, outpath, flyerpath, inject_environment, TVG_range_correction)

if ~isfolder(outpath)
    [~,~] = mkdir(outpath);
end

if ~isempty(flyerpath)
    flyer = load(flyerpath);
else
    error('[EK80Parser] flyerpath is not valid');
end

% these settings should be changed into input in the function!!
if isempty(inject_environment) || inject_environment ~= 1
    inject_environment = 0;
    fprintf('[EK80Parser] Using default environment data\n')
else
    inject_environment = 1;
    fprintf('[EK80Parser] Injecting environment parameters from flyer data\n')
end

if TVG_range_correction ~= 1 || isempty(TVG_range_correction)
    TVG_range_correction = 0;
else
    TVG_range_correction = 1;
    fprintf('[EK80Parser] TVG Range correction applied\n')
end

% Select raw data files
[fileNameList,filePath,~] = uigetfile('*.raw','Select raw EK80 files','MultiSelect','on',defaultPath);
if ~iscell(fileNameList)
    fileNameList = {fileNameList};
end
nFiles = length(fileNameList);

%global_counter = 0;
%prevTime = 0;

% Will process each raw data file!
tic
for fileNumber = 1:nFiles
    fileName = fullfile(filePath,fileNameList{fileNumber});
    % The data file consists of both 70 and 200 kHz of data!
    data= EK80readRawV3(fileName);
    % Universal header data
    envirodata= data.environ;
    filterdata = data.filters;
    transdata = data.config.transceivers; %to lookup for impendance
    pingdata = data.echodata;
    paramdata = data.param; 
    wbt_impedance = str2double(transdata.Impedance);

    % Match flyer time to echosounder time!
    % Convert both timestamps into row vectors so dsearchn works!
    ind = dsearchn(double(flyer.ek80_VBS_t_EK80_DATA.ek_timestamp), double([data.echodata.timestampunix]).');
    newTime=flyer.ek80_VBS_t_EK80_DATA.timestamp(ind);
    
    % There might be "duplicate" timestamps in newTime since it searches for the nearest index. 
    % If there is a similar index, then indices of the repeated value are calced using:
    ind_duplicate = find(diff(ind)==0)+1;

    if ~isempty(ind_duplicate)
        for ii=1:length(ind_duplicate)
            newTime(ind_duplicate(ii)) = newTime(ind_duplicate(ii)) + ...
                (data.echodata(ind_duplicate(ii)).timestampunix - data.echodata(ind_duplicate(ii)-1).timestampunix);
        end
    end
    
    % Determine transducer channels and collect data based off of number of channels!
    % chan and transducerdata correspond and now are agnostic!
    chan = string(unique({pingdata.channelID})); %string({transdata.channels.ChannelID});
    transdata_ch = [transdata.channels];
    transducer_cal = [transdata_ch.transducer];
    filt_ch = arrayfun(@(x) x.ChannelID, filterdata, 'UniformOutput', false);

    % inject environmental data
    % Now environmental data is interpolated for whole file for all channels!
    if(inject_environment == 1)
        envirodata.Temperature = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.temperature]),double(newTime), 'linear','extrap' );
        envirodata.Depth = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.pressure]),double(newTime), 'linear','extrap' );
        envirodata.SoundSpeed = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.soundVelocity]),double(newTime), 'linear','extrap' );
        envirodata.Salinity = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.salinity]),double(newTime), 'linear','extrap' );
        envirodata.timestamp = [data.echodata.timestamp].';
        envirodata.Acidity =  envirodata.Acidity*ones(length(envirodata.timestamp),1);
    end
    
    % Loop and process data for each channel: data will be saved seperately for each channel per each file

    idx_chan = false(numel(chan),length(pingdata));
    if fileNumber==1
        pingtbl_comb = [];
    end
    channelID = string({pingdata.channelID});
    Temperature = envirodata.Temperature;
    Salinity = envirodata.Salinity;

    for j=1:numel(chan)
        chan_str = regexp(chan(j), 'ES\d+', 'match', 'once'); %channel freq string
        idx_chan(j,:) = ismember({pingdata.channelID},chan(j)); %This determines indices for given channel
        tempTime = newTime(idx_chan(j,:));
        % Determines index of filter to use:
        %idx_filt_ch = ismember(filt_ch,chan(j)); % Originally worked, but failed because sometimes chname in filter is wrong
        idx_filt_ch = contains(filt_ch, chan_str); % alternative
        temp_enviro = structfun(@(x) x(idx_chan(j,:)), envirodata, 'UniformOutput', false);
        idx_trans = find(ismember({transdata_ch.ChannelID},chan(j)));
        % transdata is only used for impedence!
        % procping = EstimateProcessedSampleData_doubletest(pingdata(idx_chan(j,:)),wbt_impedance,transdata_ch(j),...
        %     transducer_cal(j), paramdata(idx_chan(j,:)), filterdata(idx_filt_ch), temp_enviro, TVG_range_correction);

        [procdata,pingtable] = EstimateProcessedSampleData_v2(pingdata(idx_chan(j,:)),wbt_impedance,transdata_ch(idx_trans),...
            transducer_cal(idx_trans), paramdata(idx_chan(j,:)), filterdata(idx_filt_ch), temp_enviro, ...
            TVG_range_correction);

        ts_dt = datetime(tempTime,"ConvertFrom",'epochtime','TicksPerSecond',1e6,'Format','dd-MMM-uuuu HH:mm:ss.SSS');
        procdata.time = ts_dt;
        % ezimagesc(procdata.time,procdata.range(:,1),procdata.sv_pc,'EK60',[-80 -40]);

        % Save the processed ping data into file
        
        fndt = regexp(fileName, 'D\d{8}-T\d{6}', 'match', 'once');
        outfn = sprintf('%s_%s.mat',fndt,chan_str);
        save(fullfile(outpath,outfn),"procdata");
        
        % Add flyer variables to the pingtable
        depth = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.pressure]),double(tempTime), 'linear','extrap' );
        chlorophyll = interp1(double([flyer.ecopuck_data_t_ECOPUCK_DATA.timestamp]),  double([flyer.ecopuck_data_t_ECOPUCK_DATA.chl]),double(tempTime), 'linear','extrap' );
        % Oxygen has a 7e6 time offset?
        oxygen = interp1(double([flyer.optode_data_t_OPTODE_DATA.timestamp]),  double([flyer.optode_data_t_OPTODE_DATA.O2Concentration]),double(tempTime+7e6), 'linear','extrap' );
        turbidity = interp1(double([flyer.ecopuck_data_t_ECOPUCK_DATA.timestamp]),  double([flyer.ecopuck_data_t_ECOPUCK_DATA.turb]),double(tempTime), 'linear','extrap' );
        casts=makeflyercasts(flyer.flyer_controller_cmd_t_CTL_COMMAND, tempTime);

        % Calcs potential density depending on type of input! 
        try
            pot_density = interp1(double([flyer.sensor_data_proc.pot_density_time]),  double([flyer.sensor_data_proc.pot_density]),double(tempTime), 'linear','extrap' );
            pingtable = addvars(pingtable, pot_density, 'NewVariableNames', "pot_density");
        catch
            try
                pot_density = interp1(double([flyer.sensor_data_proc.density_time]),  double([flyer.sensor_data_proc.density]),double(tempTime), 'linear','extrap' );
                pingtable = addvars(pingtable, pot_density, 'NewVariableNames', "pot_density");
            catch
                disp('[EK80Parser] no processed density');
            end
        end
        
        % Grabs ship data incase exists
        try
            lat = interp1(double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.timestamp]),  double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.lat]),double(tempTime), 'linear','extrap' );
            lon = interp1(double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.timestamp]),  double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.lon]),double(tempTime), 'linear','extrap' );
            heading = interp1(double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.timestamp]),  double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.cmg]),double(tempTime), 'linear','extrap' );
            along_track = interp1(double([flyer.gps_processed_DATA.timestamp]),  double([flyer.gps_processed_DATA.ship_distance]),double(tempTime), 'linear','extrap' );
            pingtable = addvars(pingtable, lat, 'NewVariableNames', "lat");
            pingtable = addvars(pingtable, lon, 'NewVariableNames', "lon");
            pingtable = addvars(pingtable, heading, 'NewVariableNames', "heading");
            pingtable = addvars(pingtable, along_track, 'NewVariableNames', "along_track");
        catch
            disp('[EK80Parser] no gps data');
        end

        % Appending all variables to table
        %pingtable = addvars(pingtable, string(ts_dt), 'NewVariableNames', "timestamp_string",'Before',1);
        pingtable = addvars(pingtable, ts_dt, 'NewVariableNames', "timestamp_datetime",'Before',1);
        pingtable = addvars(pingtable, channelID(idx_chan(j,:)).', 'NewVariableNames', "Channel",'Before',2);
        pingtable = addvars(pingtable, repmat(string(fullfile(outpath,outfn)),length(ts_dt),1), 'NewVariableNames', "filename",'Before',3);
        %pingtable = addvars(pingtable, [data.echodata.timestamp].', 'NewVariableNames', "timestamp_ek_raw",'Before',1);
        pingtable = addvars(pingtable, depth, 'NewVariableNames', "depth");
        pingtable = addvars(pingtable, Temperature(idx_chan(j,:)), 'NewVariableNames', "temperature");
        pingtable = addvars(pingtable, Salinity(idx_chan(j,:)), 'NewVariableNames', "salinity");
        pingtable = addvars(pingtable, chlorophyll, 'NewVariableNames', "chlorophyll");
        pingtable = addvars(pingtable, oxygen, 'NewVariableNames', "oxygen");
        pingtable = addvars(pingtable, turbidity, 'NewVariableNames', "turbidity");
        pingtable = addvars(pingtable, casts.', 'NewVariableNames', "casts");

        % Append table for all channels
        if isempty(pingtbl_comb)
            pingtbl_comb = pingtable;
        else
            pingtbl_comb = [pingtbl_comb; pingtable];
        end
        clear pingtable;
        % Display progress
        elpsetm = toc;
        fprintf('[EK80 parser file %d/%d] Saved %s channel data in %.0f seconds\n',...
            fileNumber,nFiles,chan_str,elpsetm);
    end
    
    % Reorder table based on datetime!
    pingtbl_comb = sortrows(pingtbl_comb, 'timestamp_datetime');

end

% Fix cast numbering!
% 2026-5-11: Not implemented!
%flyer_cast_idx_v2(depth,casts);
%flyer_cast_idx_v2(pingtbl_comb.depth,pingtbl_comb.casts,50);

% Save table
dt_now = datetime("now",'Format','uuuuMMdd''-T''HHmmss');
outfn = sprintf('%s_EK80Indexer.parquet',dt_now);
parquetwrite(outfn,pingtbl_comb);
elpsetm = toc;

fprintf('[EK80 parser] Saved indexer file: %s in %.0f seconds\n',...
        outfn,elpsetm);
end
    