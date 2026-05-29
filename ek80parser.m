%% Parses EK80 raw data and timesync with ROV CTD
% formatted for renmoreno-desktop 4/12/2023
%for bermuda EK80 select all EK80 files (12 of them)
%need ctd struct .mat file output from ctdstructbuilder.m

function ek80parser(defaultPath, outpath, ctdstructpath, inject_environment, TVG_range_correction)

%outpath = 'F:\ONR2023\bermudaek80mat\'; %output of mat files
%defaultPath = 'F:\ONR2023\Bermuda\July2021\2021-07-08\d20210708\EK80\'; %default path of EK80 files

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

if ~isempty(ctdstructpath)
   %ctd = load(ctdstructpath);
    if isstring(ctdstructpath) || ischar(ctdstructpath)
        ctd = load(ctdstructpath);
    else
        ctd = ctdstructpath;
    end
else %2025-4-23: changed error to warning since I think it can run without ctd data
    warning('[EK80Parser] Must have CTD file to run. Use ek80parser.m for parsing without CTD/flyer files');
end

save_files =1;
save_index =1;
fileAppend='pings';
%inject_environment = 0;

% Select raw data files
[fileNameList,filePath,~] = uigetfile('*.raw','Select raw EK80 files','MultiSelect','on',defaultPath);
if ~iscell(fileNameList)
    fileNameList = {fileNameList};filePath
end
nFiles = length(fileNameList);
global_counter = 0;
prevTime = 0;

% Read raw data files
for fileNumber = 1:nFiles,
    fileName = fullfile(filePath,fileNameList{fileNumber});
    data= EA440readRawV1(fileName);
    %Universal header data
    envirodata= data.environ;
    filterdata = data.filters;
    transdata = data.config.transceivers; %to lookup for impendance
    if(length(data.echodata)>1)
        ignored =0;
        for ping = 1 : length(data.echodata)
            global_counter = global_counter+1 ;
            if(ping == 1)
                file_start =global_counter;
                file_end = global_counter+length(data.echodata)-1;
            end
            
            %get corrected time, for environment overwrite %%NO NEED TO DO THIS!!
            %ind = dsearchn(double(ctd.time_utc), double(data.echodata(ping).timestamp));
            %newTime=ctd.time_utc(ind);
            newTime= double(data.echodata(ping).timestamp);

            %make header structs
            pingdata = data.echodata(ping);
            paramdata = data.param(ping);
            %envirodata= data.environ;
            %filterdata = data.filters;

            %correct for duplicate sequential timestamps
            if(newTime == prevTime)
                newTime = newTime +  data.echodata(ping).timestamp - [global_indexer(global_counter-1).timestamp]; %just use regular timestamp and not raw
            else
                prevTime = newTime;
            end
                        
            %assign transducer
            if(strcmp(pingdata.channelID,  data.config.transceivers.channels(1).ChannelID)==1)
                transdata_ch = transdata.channels(1);
                transducerdata = data.config.transceivers.channels(1).transducer;
            else
                transdata_ch = transdata.channels(2); %for comparison with paramdata to determine index of pulse length
                transducerdata = data.config.transceivers.channels(2).transducer;
            end

             %inject environmental data
            if(inject_environment == 1)
                envirodata.Temperature = interp1(double([ctd.time_utc]),  double([ctd.temperature]),double(newTime), 'linear','extrap' ); %if data is within bounds that it is not extrapolated but intrapolated
                envirodata.Depth = interp1(double([ctd.time_utc]),  double([ctd.pressure]),double(newTime), 'linear','extrap' );
                %envirodata.SoundSpeed = interp1(double([ctd.time_utc]),  double([flyer.sbe49ctd_data_t_CTD_DATA.soundVelocity]),double(newTime), 'linear','extrap' );
                %envirodata.Salinity = interp1(double([ctd.time_utc]),  double([flyer.sbe49ctd_data_t_CTD_DATA.salinity]),double(newTime), 'linear','extrap' );
            end
                    
            procping=EstimateProcessedSampleData_doubletest(pingdata,transdata,transdata_ch,transducerdata, paramdata, filterdata, envirodata, TVG_range_correction);
            
            %append useful information
            procping.timestamp=newTime; %this is taken from ctd timestamp
            procping.timestamp_raw=data.echodata(ping).timestamp; %just regular timestamp not unix // taken from ek80 and use as comparison with ctd timestamp
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
            global_indexer(global_counter).timestamp=newTime; %CTD timestamp
            global_indexer(global_counter).timestamp_raw=data.echodata(ping).timestamp; %same as procping
            global_indexer(global_counter).channel=data.echodata(ping).channelID;
            global_indexer(global_counter).depth = interp1(double([ctd.time_utc]),  double([ctd.pressure]),double(newTime), 'linear','extrap' );
            global_indexer(global_counter).temperature = interp1(double([ctd.time_utc]),  double([ctd.temperature]),double(newTime), 'linear','extrap' );
            global_indexer(global_counter).TVGStart = procping.startTVG;
            global_indexer(global_counter).absorptionCoeff = procping.absorptionCoeff;
            global_indexer(global_counter).cast=1;
            global_indexer(global_counter).soundspeed = envirodata.SoundSpeed;
        end
    else
        disp('ignored single ping file');
        ignored =1;
    end
    
    %save mat file
    if(save_files == 1 && ignored == 0)
        %assignin('base',fileAppend,procdata(:, 1:length(procdata)));
        pings = procdata(:, 1:length(procdata));
        temp=strcat(outpath, temp);
        save(temp,fileAppend);
        evalin('base',['clear' sprintf(' %s',fileAppend)]);
    end
    clear procdata; clear pings;
    disp(['[EK80Parser] Finished reading file ' int2str(fileNumber) ' of ' int2str(nFiles)]);
end

%assign dive cast numbers
if(save_index == 1)
    temp=strcat(outpath, 'global_index');
    save(temp,'global_indexer');
end

end