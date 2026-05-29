function ek80parser_flyer_v2_parfor(defaultPath, outpath, flyerpath, inject_environment, TVG_range_correction)
    if ~isfolder(outpath); mkdir(outpath); end
    
    % 1. Memory Efficient Loading
    if isempty(flyerpath) || ~exist(flyerpath, 'file')
        error('[EK80Parser] flyerpath is not valid');
    end
    flyer = load(flyerpath); % Loaded as a struct for parfor transparency

    % Handle flag defaults
    inject_env = isequal(inject_environment, 1);
    tvg_corr = isequal(TVG_range_correction, 1);

    % Select raw data files
    [fileNameList, filePath] = uigetfile('*.raw', 'Select raw EK80 files', 'MultiSelect', 'on', defaultPath);
    if ~iscell(fileNameList); fileNameList = {fileNameList}; end
    nFiles = length(fileNameList);

    % 2. Pre-allocate Cell Array for Table Segments
    % Growing tables inside parfor is impossible; we collect chunks and vertcat later.
    tableChunks = cell(nFiles, 1);

    fprintf('[EK80Parser] Starting Parallel Processing...\n')
    tic
    %ppm = ParforProgressbar(nFiles);
    parfor fileNumber = 1:nFiles
        fileName = fullfile(filePath, fileNameList{fileNumber});
        
        % Read data (Assumes EK80readRawV3 is thread-safe)
        data = EK80readRawV3(fileName);
        
        % Extract necessary local variables from 'data'
        envirodata = data.environ;
        filterdata = data.filters;
        transdata = data.config.transceivers;
        pingdata = data.echodata;
        paramdata = data.param;
        wbt_impedance = str2double(transdata.Impedance);
        
        % Time matching
        raw_timestamps = [data.echodata.timestampunix].';
        ind = dsearchn(double(flyer.ek80_VBS_t_EK80_DATA.ek_timestamp), double(raw_timestamps));
        newTime = flyer.ek80_VBS_t_EK80_DATA.timestamp(ind);
        
        % Fix duplicates
        ind_duplicate = find(diff(ind) == 0) + 1;
        for ii = 1:length(ind_duplicate)
            idx = ind_duplicate(ii);
            newTime(idx) = newTime(idx) + (raw_timestamps(idx) - raw_timestamps(idx-1));
        end
        
        % Channel Logic
        chan = string(unique({pingdata.channelID}));
        transdata_ch = [transdata.channels];
        transducer_cal = [transdata_ch.transducer];
        filt_ch = arrayfun(@(x) x.ChannelID, filterdata, 'UniformOutput', false);

        % Inject Environment
        if inject_env
            envirodata.Temperature = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]), double([flyer.sbe49ctd_data_t_CTD_DATA.temperature]), double(newTime), 'linear', 'extrap');
            envirodata.Depth = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]), double([flyer.sbe49ctd_data_t_CTD_DATA.pressure]), double(newTime), 'linear', 'extrap');
            envirodata.SoundSpeed = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]), double([flyer.sbe49ctd_data_t_CTD_DATA.soundVelocity]), double(newTime), 'linear', 'extrap');
            envirodata.Salinity = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]), double([flyer.sbe49ctd_data_t_CTD_DATA.salinity]), double(newTime), 'linear', 'extrap');
            envirodata.timestamp = [data.echodata.timestamp].';
            envirodata.Acidity = envirodata.Acidity * ones(length(envirodata.timestamp), 1);
        end

        localTable = table();
        fndt = regexp(fileName, 'D\d{8}-T\d{6}', 'match', 'once');

        % Loop channels
        for j = 1:numel(chan)
            chan_str = regexp(chan(j), 'ES\d+', 'match', 'once');
            idx_chan = ismember({pingdata.channelID}, chan(j));
            tempTime = newTime(idx_chan);
            
            idx_filt_ch = contains(filt_ch, chan_str);
            temp_enviro = structfun(@(x) x(idx_chan), envirodata, 'UniformOutput', false);
            idx_trans = find(ismember({transdata_ch.ChannelID}, chan(j)));

            [procdata, pingtable] = EstimateProcessedSampleData_v2(pingdata(idx_chan), wbt_impedance, transdata_ch(idx_trans), ...
                transducer_cal(idx_trans), paramdata(idx_chan), filterdata(idx_filt_ch), temp_enviro, tvg_corr);
            
            ts_dt = datetime(tempTime, "ConvertFrom", 'epochtime', 'TicksPerSecond', 1e6, 'Format', 'dd-MMM-uuuu HH:mm:ss.SSS');
            procdata.time = ts_dt;

            % Save processed data (Transparent save)
            outfn = sprintf('%s_%s.mat', fndt, chan_str);
            fullOutPath = fullfile(outpath, outfn);
            save_parfor(fullOutPath, procdata);

            % Build Pingtable variables (Pre-calculate for memory)
            f_ctd = flyer.sbe49ctd_data_t_CTD_DATA;
            f_eco = flyer.ecopuck_data_t_ECOPUCK_DATA;
            
            depth = interp1(double([f_ctd.timestamp]), double([f_ctd.pressure]), double(tempTime), 'linear', 'extrap');
            chlor = interp1(double([f_eco.timestamp]), double([f_eco.chl]), double(tempTime), 'linear', 'extrap');
            oxy = interp1(double([flyer.optode_data_t_OPTODE_DATA.timestamp]), double([flyer.optode_data_t_OPTODE_DATA.O2Concentration]), double(tempTime+7e6), 'linear', 'extrap');
            turb = interp1(double([f_eco.timestamp]), double([f_eco.turb]), double(tempTime), 'linear', 'extrap');
            
            % Add variables to table
            pingtable.timestamp_datetime = ts_dt;
            pingtable.Channel = repmat(chan(j), height(pingtable), 1);
            pingtable.filename = repmat(string(fullOutPath), height(pingtable), 1);
            pingtable.depth = depth;
            pingtable.temperature = envirodata.Temperature(idx_chan);
            pingtable.salinity = envirodata.Salinity(idx_chan);
            pingtable.chlorophyll = chlor;
            pingtable.oxygen = oxy;
            pingtable.turbidity = turb;
            pingtable.casts = makeflyercasts(flyer.flyer_controller_cmd_t_CTL_COMMAND, tempTime).';
            
            % Handle Density (Wrapped in helper to keep parfor clean)
            pingtable = try_add_density(pingtable, flyer, tempTime);
            pingtable = try_add_gps(pingtable, flyer, tempTime);

            localTable = [localTable; pingtable];
        end
        tableChunks{fileNumber} = localTable;
        %pause(100/nFiles);
        %ppm.increment();
    end

    % 3. Post-Parallel: Combine and Finalize
    pingtbl_comb = vertcat(tableChunks{:});
    pingtbl_comb = sortrows(pingtbl_comb, 'timestamp_datetime');

    % Final Cast Indexing
    %flyer_cast_idx_v2(pingtbl_comb.depth, pingtbl_comb.casts, 50);

    % Save Table
    dt_now = datetime("now", 'Format', 'uuuuMMdd''-T''HHmmss');
    outfn = sprintf('%s_EK80Indexer.parquet', dt_now);
    parquetwrite(fullfile(outpath,outfn), pingtbl_comb);
    
    fprintf('[EK80 parser] Finished. Saved Indexer: %s in %.0f seconds\n', outfn, toc);
end

%% Helper Functions for Parfor Transparency

function save_parfor(fname, procdata)
    save(fname, 'procdata');
end

function pt = try_add_density(pt, flyer, tempTime)
    try
        if isfield(flyer.sensor_data_proc, 'pot_density')
            val = interp1(double([flyer.sensor_data_proc.pot_density_time]), double([flyer.sensor_data_proc.pot_density]), double(tempTime), 'linear', 'extrap');
            pt.pot_density = val;
        end
    catch
        % Silent skip
    end
end

function pt = try_add_gps(pt, flyer, tempTime)
    try
        f_gps = flyer.gps_gprmc_t_GPS_GPRMC_DATA;
        pt.lat = interp1(double([f_gps.timestamp]), double([f_gps.lat]), double(tempTime), 'linear', 'extrap');
        pt.lon = interp1(double([f_gps.timestamp]), double([f_gps.lon]), double(tempTime), 'linear', 'extrap');
        pt.heading = interp1(double([f_gps.timestamp]), double([f_gps.cmg]), double(tempTime), 'linear', 'extrap');
        pt.along_track = interp1(double([flyer.gps_processed_DATA.timestamp]), double([flyer.gps_processed_DATA.ship_distance]), double(tempTime), 'linear', 'extrap');
    catch
        % Silent skip
    end
end