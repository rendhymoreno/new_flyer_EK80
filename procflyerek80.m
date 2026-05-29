clear all;
 
cd(fileparts(matlab.desktop.editor.getActiveFilename));

%POPULATE THESE
%path to code base
addpath(genpath(pwd));
%path to flyer merged file
%flyer = load(strcat(pwd,'\testdataset\20190923_224315_merged.mat'));
flyer = load('E:\2023_MSET\MGL23-Flyer\20231009_203523\20231009_203523_merged.mat');
%path to save directory 
outpath ='E:\2023_MSET\processed\Ben\';

save_files =1;
save_index =1;
fileAppend='pings';
inject_environment = 0;

%defaultPath = strcat(pwd,'\testdataset');
defaultPath = strcat('E:\2023_MSET\MGL23-Flyer\20231009_203523\EK80\post');

% Select raw data files
[fileNameList,filePath,~] = uigetfile('*.raw','Select raw files','MultiSelect','on',defaultPath);
if ~iscell(fileNameList)
    fileNameList = {fileNameList};filePath
end
nFiles = length(fileNameList);

global_counter = 0;
prevTime = 0;

% Read raw data files
for fileNumber = 1:nFiles,
    fileName = fullfile(filePath,fileNameList{fileNumber});
    data= EK80readRawV3(fileName);
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
            envirodata= data.environ;
            filterdata = data.filters;
            
            %correct for duplicate sequential timestamps
            if(newTime == prevTime)
                newTime = newTime +  data.echodata(ping).timestampunix - [global_indexer(global_counter-1).timestamp_raw];
            else
                prevTime = newTime;
            end
            
            %assign transducer
            if(strcmp(pingdata.channelID,  data.config.transceivers.channels(1).ChannelID)==1)
                transducerdata = data.config.transceivers.channels(1).transducer;
            else
                transducerdata = data.config.transceivers.channels(2).transducer;
            end
            
            %inject environmental data
            if(inject_environment == 1)
                envirodata.Temperature = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.temperature]),double(newTime), 'linear','extrap' );
                envirodata.Depth = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.pressure]),double(newTime), 'linear','extrap' );
                envirodata.SoundSpeed = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.soundVelocity]),double(newTime), 'linear','extrap' );
                envirodata.Salinity = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.salinity]),double(newTime), 'linear','extrap' );
            end
            
            %proc power calculations
            procping=EstimateProcessedSampleData_doubletest_old(pingdata,transducerdata, paramdata, filterdata, envirodata);
            
            %append useful information
            procping.timestamp=newTime;
            procping.timestamp_raw=data.echodata(ping).timestampunix;
            procping.channel=data.echodata(ping).channelID;
            procping.ping_global = global_counter;
            
            %assign ping to file output struct
            procdata(ping)=procping;
            
            %assign directory indSnex
            global_indexer(global_counter).ping_global=global_counter;
            global_indexer(global_counter).ping_local=ping;
            
            %assign global vars
            temp=strfind(fileName, '\');
            temp=temp(length(temp));
            temp = fileName(temp+1:length(fileName)-4);
            global_indexer(global_counter).file=temp;
            global_indexer(global_counter).var=fileAppend;
            global_indexer(global_counter).timestamp=newTime;
            global_indexer(global_counter).timestamp_raw=data.echodata(ping).timestampunix;
            global_indexer(global_counter).channel=data.echodata(ping).channelID;            
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
                    disp('no processed density');
                end
            end
            try
                global_indexer(global_counter).lat = interp1(double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.timestamp]),  double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.lat]),double(newTime), 'linear','extrap' );
                global_indexer(global_counter).lon = interp1(double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.timestamp]),  double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.lon]),double(newTime), 'linear','extrap' );
                global_indexer(global_counter).heading = interp1(double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.timestamp]),  double([flyer.gps_gprmc_t_GPS_GPRMC_DATA.cmg]),double(newTime), 'linear','extrap' );
                global_indexer(global_counter).along_track = interp1(double([flyer.gps_processed_DATA.timestamp]),  double([flyer.gps_processed_DATA.ship_distance]),double(newTime), 'linear','extrap' );
                global_indexer(global_counter).soundspeed = interp1(double([flyer.sbe49ctd_data_t_CTD_DATA.timestamp]),  double([flyer.sbe49ctd_data_t_CTD_DATA.soundVelocity]),double(newTime), 'linear','extrap' );

            catch
                disp('no gps data'); 
                global_indexer(global_counter).along_track= global_counter; 
            end
            global_indexer(global_counter).TVGStart = procping.startTVG;
            global_indexer(global_counter).absorptionCoeff = procping.absorptionCoeff;

            %chirp settings etc.  
%             global_indexer(global_counter).FrequencyEnd = paramdata.FrequencyEnd;
%             global_indexer(global_counter).FrequencyStart = paramdata.FrequencyStart;
%             global_indexer(global_counter).PulseDuration = paramdata.PulseDuration;
%             global_indexer(global_counter).PulseForm = paramdata.PulseForm;
%             global_indexer(global_counter).SampleInterval = paramdata.SampleInterval;
%             global_indexer(global_counter).Slope = paramdata.Slope;
%             global_indexer(global_counter).TransmitPower = paramdata.TransmitPower;
%             global_indexer(global_counter).Decimation1 = filterdata(1,1).Decimation;
%             global_indexer(global_counter).Decimation2 = filterdata(1,2).Decimation;
%             global_indexer(global_counter).FilterData1 = filterdata(1,1).FilterData;
%             global_indexer(global_counter).FilterData2 = filterdata(1,2).FilterData;
        end
    else
        disp('ignored single ping file');
        ignored =1;
    end
    
    %save mat file
    if(save_files == 1 && ignored == 0)
        assignin('base',fileAppend,procdata(:, 1:length(procdata)));
        temp=strcat(outpath, temp);
        save(temp,fileAppend);
        evalin('base',['clear' sprintf(' %s',fileAppend)]);
    end
    clear procdata;
    disp(['Finished reading file ' int2str(fileNumber) ' of ' int2str(nFiles)]);
end

%assign dive cast numbers
casts=num2cell(makeflyercasts(flyer.flyer_controller_cmd_t_CTL_COMMAND, [global_indexer.timestamp]'));
[global_indexer.cast] = casts{:};

if(save_index == 1)
    temp=strcat(outpath, 'global_index');
    save(temp,'global_indexer');
end
