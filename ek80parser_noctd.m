%% Parses EK80 raw data and timesync with ROV CTD
% formatted for renmoreno-desktop 4/12/2023
%for bermuda EK80 select all EK80 files (12 of them)
%need ctd struct .mat file output from ctdstructbuilder.m

function ek80parser_noctd(defaultPath, outpath, TVG_range_correction)

%outpath = 'F:\ONR2023\bermudaek80mat\'; %output of mat files
%defaultPath = 'F:\ONR2023\Bermuda\July2021\2021-07-08\d20210708\EK80\'; %default path of EK80 files

%ctd = load(ctdstructpath);
save_files =1;
save_index =1;
fileAppend='pings';
inject_environment = 0;

% Select raw data files
[fileNameList,filePath,~] = uigetfile('*.raw','Select raw EK80 files','MultiSelect','on',defaultPath);
if ~iscell(fileNameList)
    fileNameList = {fileNameList};filePath
end
nFiles = length(fileNameList);
global_counter = 0;
prevTime = 0;

% Read raw data files
for fileNumber = 1:nFiles
    try
        fileName = fullfile(filePath,fileNameList{fileNumber});
        data = EK80readRawV3(fileName);
        % Segment data based on lon/lat boundary 
        % if any(([data.lon] < lon_boundary) | )
        % continue; %goes to the next file immediately
        envirodata= data.environ; %ping specific
        filterdata = data.filters; %ping specific
        transdata = data.config.transceivers; %takes all transceivers!

        % Get transducer name from transceiver
        ch_num = 1;
        for ii=1:length(transdata)
            for jj=1:length(data.config.transceivers(ii).channels)
                chan_n{ch_num} = string(data.config.transceivers(ii).channels(jj).ChannelID); % string of all channels in tranceiver!
                tstd_idx{ch_num} = [ii jj]; % [transceiver_idx channel_idx]
                ch_num =  ch_num+1;
            end
        end

        % Start reading each ping!
        if(length(data.echodata)>1)
            ignored =0;
            for ping = 1 : length(data.echodata)
                global_counter = global_counter+1 ;
                if(ping == 1)
                    file_start =global_counter;
                    file_end = global_counter+length(data.echodata)-1;
                end

                % make header structs
                pingdata = data.echodata(ping); %ping specific
                paramdata = data.param(ping); %ping specific

                % assign transducer -- modify to read from all transceivers!
                if any(ismember(string(chan_n), pingdata.channelID))
                    trc_idx = ismember(string(chan_n), pingdata.channelID)==1; %idx where
                    ch_idx = tstd_idx{trc_idx};

                    transdata_ch = transdata(ch_idx(1)).channels(ch_idx(2));
                    transducerdata = transdata_ch.transducer;
                else
                    error('Transceiver Channel and Transducer name is mismatched!');
                end

                % Old code
                %{
            if(strcmp(pingdata.channelID,  data.config.transceivers.channels(1).ChannelID)==1)
                transdata_ch = transdata.channels(1);
                transducerdata = data.config.transceivers.channels(1).transducer;
            else
                transdata_ch = transdata.channels(2); %for comparison with paramdata to determine index of pulse length
                transducerdata = data.config.transceivers.channels(2).transducer;
            end
                %}

                %procping=EstimateProcessedSampleData_doubletest(pingdata,transdata,transdata_ch,transducerdata, paramdata, filterdata, envirodata, TVG_range_correction);
                procping=EstimateEK80CW(pingdata,transdata_ch,transducerdata, paramdata, envirodata, TVG_range_correction);
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
                %global_indexer(global_counter).timestamp=newTime; %CTD timestamp
                global_indexer(global_counter).timestamp_raw=data.echodata(ping).timestamp; %same as procping
                global_indexer(global_counter).channel=data.echodata(ping).channelID;
                %global_indexer(global_counter).depth = interp1(double([ctd.time_utc]),  double([ctd.pressure]),double(newTime), 'linear','extrap' );
                %global_indexer(global_counter).temperature = interp1(double([ctd.time_utc]),  double([ctd.temperature]),double(newTime), 'linear','extrap' );
                global_indexer(global_counter).TVGStart = procping.startTVG;
                global_indexer(global_counter).absorptionCoeff = procping.absorptionCoeff;
                global_indexer(global_counter).cast=1;
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
        disp(['Finished reading file ' int2str(fileNumber) ' of ' int2str(nFiles)]);

    catch ME
        fprintf('Error processing %s: %s\n', fileName, ME.message);
    end

end

%assign dive cast numbers
if(save_index == 1)
    temp=strcat(outpath, 'global_index');
    save(temp,'global_indexer');
end

end