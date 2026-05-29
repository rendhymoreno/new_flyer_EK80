%% Parses EK80 raw data and timesync with ROV CTD
% formatted for renmoreno-desktop 4/12/2023
%for bermuda EK80 select all EK80 files (12 of them)
%need ctd struct .mat file output from ctdstructbuilder.m

function ek80parser_flyer(defaultPath, outpath, flyerpath, inject_environment, TVG_range_correction)

if ~isempty(flyerpath)
    flyer = load(flyerpath);
else
    error('[EK80Parser] flyerpath is not valid');
end

% these settings should be changed into input in the function!!
save_files =1;
save_index =1;
fileAppend='pings';
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
    fileNameList = {fileNameList};filePath;
end
nFiles = length(fileNameList);

global_counter = 0;
prevTime = 0;

% Read raw data files
for fileNumber = 1:nFiles
    fileName = fullfile(filePath,fileNameList{fileNumber});
    % The data file consists of both 70 and 200 kHz of data!
    data= EK80readRawV3(fileName);
    %Universal header data
    envirodata= data.environ;
    filterdata = data.filters;
    transdata = data.config.transceivers; %to lookup for impendance
    pingdata = data.echodata; % Now all data are loaded
    paramdata = data.param; % Now all data are loaded

    % New without using for loop across each ping!
    % global_counter = length of echodata and save into memory?
    % Match flyer time to echosounder time!
    % Convert both timestamps into row vectors so dsearchn works!
    ind = dsearchn(double(flyer.ek80_VBS_t_EK80_DATA.ek_timestamp), double([data.echodata.timestampunix]).');
    newTime=flyer.ek80_VBS_t_EK80_DATA.timestamp(ind);
    
    % 2026-5-6: Not implemented yet!
    % There might be "duplicate" timestamps. Previously, it compared this
    % timestamp to the previous, if similar then:
    % if(newTime == prevTime)
    %     newTime = newTime +  data.echodata(ping).timestampunix - [global_indexer(global_counter-1).timestamp_raw]; %just use regular timestamp and not raw
    % else
    %     prevTime = newTime;
    % end
    
    % Determine transducer channels and collect data based off of number of channels!
    % if(strcmp(pingdata.channelID,  data.config.transceivers.channels(1).ChannelID)==1)
    %     transdata_ch = transdata.channels(1); %for comparison with paramdata to determine index of pulse length
    %     transducerdata = transdata_ch.transducer; %using index of pulse length, gain and Sa correction can be chosen
    % else
    %     transdata_ch = transdata.channels(2); %for comparison with paramdata to determine index of pulse length
    %     transducerdata = transdata_ch.transducer; %using index of pulse length, gain and Sa correction can be chosen
    % end
    
    % Determine transducer channels and collect data based off of number of channels!
    % chan and transducerdata correspond and now are agnostic!
    chan = string({transdata.channels.ChannelID});
    transducer_cal = [transdata.channels.transducer];

    % inject environmental data
    % Now environmental data is interpolated for whole file for all channels!
    if(inject_environment == 1)
        envirodata.Temperature = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.temperature]),double(newTime), 'linear','extrap' );
        envirodata.Depth = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.pressure]),double(newTime), 'linear','extrap' );
        envirodata.SoundSpeed = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.soundVelocity]),double(newTime), 'linear','extrap' );
        envirodata.Salinity = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.salinity]),double(newTime), 'linear','extrap' );
    end
    
    % Seperate for each channel now?

    
    if(length(data.echodata)>1)
        ignored =0;
        for ping = 1 : length(data.echodata)
            global_counter = global_counter+1 ;
            if(ping == 1)
                file_start =global_counter;
                file_end = global_counter+length(data.echodata)-1;
            end

            %get corrected time, for environment overwrite
            ind = dsearchn(double(flyer.ek80_VBS_t_EK80_DATA.ek_timestamp), double(data.echodata(ping).timestampunix));
            newTime=flyer.ek80_VBS_t_EK80_DATA.timestamp(ind);

            %make header structs
            pingdata = data.echodata(ping);
            paramdata = data.param(ping);
            %envirodata= data.environ;
            %filterdata = data.filters;
            %transdata = data.config.transceivers;
            
            %correct for duplicate sequential timestamps
            if(newTime == prevTime)
                newTime = newTime +  data.echodata(ping).timestampunix - [global_indexer(global_counter-1).timestamp_raw]; %just use regular timestamp and not raw
            else
                prevTime = newTime;
            end
                        
            %assign transducer
            if(strcmp(pingdata.channelID,  data.config.transceivers.channels(1).ChannelID)==1)
                transdata_ch = transdata.channels(1); %for comparison with paramdata to determine index of pulse length
                transducerdata = transdata_ch.transducer; %using index of pulse length, gain and Sa correction can be chosen
            else
                transdata_ch = transdata.channels(2); %for comparison with paramdata to determine index of pulse length
                transducerdata = transdata_ch.transducer; %using index of pulse length, gain and Sa correction can be chosen
            end

             %inject environmental data
            if(inject_environment == 1)
                envirodata.Temperature = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.temperature]),double(newTime), 'linear','extrap' );
                envirodata.Depth = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.pressure]),double(newTime), 'linear','extrap' );
                envirodata.SoundSpeed = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.soundVelocity]),double(newTime), 'linear','extrap' );
                envirodata.Salinity = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.salinity]),double(newTime), 'linear','extrap' );
            end
                    
            procping=EstimateProcessedSampleData_doubletest(pingdata,transdata,transdata_ch,transducerdata, paramdata, filterdata, envirodata, TVG_range_correction);
            
            %append useful information
            procping.timestamp=newTime; %this is taken from flyer ctd timestamp
            procping.timestamp_raw=data.echodata(ping).timestampunix; %just regular timestamp not unix // taken from ek80 and use as comparison with ctd timestamp
            procping.channel=data.echodata(ping).channelID;
            procping.ping_global = global_counter;
            
            %assign ping to file output struct
            procdata(ping)=procping;
            
            %assign directory indSnex
            global_indexer(global_counter).ping_global=global_counter;
            global_indexer(global_counter).ping_local=ping;
            
            %assign global vars
            %temp=strfind(fileName, '\');
            %temp=temp(length(temp));
            %temp = fileName(temp+1:length(fileName)-4);
            temp = fileNameList{fileNumber};
            temp = temp(1:end-4);
            global_indexer(global_counter).file=temp;
            global_indexer(global_counter).var=fileAppend;
            global_indexer(global_counter).timestamp=newTime; %CTD timestamp
            global_indexer(global_counter).timestamp_raw=data.echodata(ping).timestampunix; %same as procping
            global_indexer(global_counter).channel=data.echodata(ping).channelID;
            global_indexer(global_counter).depth = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.pressure]),double(newTime), 'linear','extrap' );
            global_indexer(global_counter).temperature = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.temperature]),double(newTime), 'linear','extrap' );
            global_indexer(global_counter).TVGStart = procping.startTVG;
            global_indexer(global_counter).absorptionCoeff = procping.absorptionCoeff;
            global_indexer(global_counter).cast=1;            
            global_indexer(global_counter).depth = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.pressure]),double(newTime), 'linear','extrap' );
            global_indexer(global_counter).temperature = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.temperature]),double(newTime), 'linear','extrap' );
            global_indexer(global_counter).salinity = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.salinity]),double(newTime), 'linear','extrap' );
            global_indexer(global_counter).chlorophyll = interp1(double([flyer.ecopuck_data_t_ECOPUCK_DATA.timestamp]),  double([flyer.ecopuck_data_t_ECOPUCK_DATA.chl]),double(newTime), 'linear','extrap' );
            global_indexer(global_counter).oxygen = interp1(double([flyer.optode_data_t_OPTODE_DATA.timestamp]),  double([flyer.optode_data_t_OPTODE_DATA.O2Concentration]),double(newTime+7e6), 'linear','extrap' );
            global_indexer(global_counter).turbidity = interp1(double([flyer.ecopuck_data_t_ECOPUCK_DATA.timestamp]),  double([flyer.ecopuck_data_t_ECOPUCK_DATA.turb]),double(newTime), 'linear','extrap' );

            try
                global_indexer(global_counter).pot_density = interp1(double([flyer.sensor_data_proc.pot_density_time]),  double([flyer.sensor_data_proc.pot_density]),double(newTime), 'linear','extrap' );
            catch
                try
                    global_indexer(global_counter).pot_density = interp1(double([flyer.sensor_data_proc.density_time]),  double([flyer.sensor_data_proc.density]),double(newTime), 'linear','extrap' );
                catch
                    disp('[EK80Parser] no processed density');
                end
            end
            try
                global_indexer(global_counter).lat = interp1(double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.timestamp]),  double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.lat]),double(newTime), 'linear','extrap' );
                global_indexer(global_counter).lon = interp1(double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.timestamp]),  double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.lon]),double(newTime), 'linear','extrap' );
                global_indexer(global_counter).heading = interp1(double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.timestamp]),  double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.cmg]),double(newTime), 'linear','extrap' );
                global_indexer(global_counter).along_track = interp1(double([flyer.gps_processed_DATA.timestamp]),  double([flyer.gps_processed_DATA.ship_distance]),double(newTime), 'linear','extrap' );
                global_indexer(global_counter).soundspeed = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.soundVelocity]),double(newTime), 'linear','extrap' );

            catch
                disp('[EK80Parser] no gps data'); 
                global_indexer(global_counter).along_track= global_counter; 
            end
            global_indexer(global_counter).TVGStart = procping.startTVG;
            global_indexer(global_counter).absorptionCoeff = procping.absorptionCoeff;

        end
    else
        disp('[EK80Parser] Ignored single ping file');
        ignored =1;
    end
    
    %save mat file
    if(save_files == 1 && ignored == 0)
        %assignin('base',fileAppend,procdata(:, 1:length(procdata))); %this only works when not used inside a function
        pings = procdata(:, 1:length(procdata)); %use this instead when inside a function
        temp=strcat(outpath, temp);
        save(temp,fileAppend);
        evalin('base',['clear' sprintf(' %s',fileAppend)]);
    end
    clear procdata;
    disp(['[EK80Parser] Finished reading file ' int2str(fileNumber) ' of ' int2str(nFiles)]);
    
    
    % test plot to compare with v2
    %2026-5-7: Pretty similar for TS
    % Different for Sv though!
    chan = unique({procdata.channel});
    idx_ch70 = ismember({procdata.channel},chan{1});
    %idx_ch70 = ismember({procdata.channel},chan{2});
    temp_var = [procdata(idx_ch70).sv_pc];
    ezimagesc(1:size(temp_var,2),1:size(temp_var,1),temp_var,'EK60',[-80 -40])
    %}
end

% Test plot to compare

%

%assign dive cast numbers
casts=num2cell(makeflyercasts(flyer.flyer_controller_cmd_t_CTL_COMMAND, [global_indexer.timestamp]'));
[global_indexer.cast] = casts{:};

if(save_index == 1)
    temp=strcat(outpath, 'global_index');
    save(temp,'global_indexer');
end

end