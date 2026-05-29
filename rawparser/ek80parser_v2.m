%% Parses EK80 raw data from conventional ship mounted systems
% 2025 - RMS
% 2025-12-17: Need to modify!!

function ek80parser_v2(defaultPath, outpath, TVG_range_correction)

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
    fileName = fullfile(filePath,fileNameList{fileNumber});

    % Read unassorted EK80 data
    data = EK80readRawV3(fileName);

    envirodata= data.environ; %ping specific
    filterdata = data.filters; %ping specific
    transdata = data.config.transceivers; %takes all transceivers!
    pingdata = data.echodata;
    paramdata = data.param;

    % Get transducer name from transceiver
    ch_num = 1;
    for ii=1:length(transdata)
        for jj=1:length(data.config.transceivers(ii).channels)
            chan_n{ch_num} = string(data.config.transceivers(ii).channels(jj).ChannelID); % string of all channels in tranceiver!
            tstd_idx{ch_num} = [ii jj]; % [transceiver_idx channel_idx]
            ch_num =  ch_num+1;
        end
    end
    
    % Determine if complex or CW
    if isempty(data.echodata(1).complexsamples)
        dtype = 'cw';
        fprintf('[EK80 Parser] Datatype is CW\n');
    else
        dtype = 'complex';
        fprintf('[EK80 Parser] Datatype is complex/FM\n');
    end

    % Start sorting data based on each channel
    for i=1:numel(chan_n)
        temp_chan = chan_n{i};
        ch_full = string({pingdata.channelID});
        ch_idx = ismember(ch_full,temp_chan);
        ping_ch = pingdata(ch_idx);
        param_ch = paramdata(ch_idx);
        time_mt = [ping_ch.timestamp];
        %datatype = unique(ping_ch.datatype);
        %offset = unique([ping_ch.offset]);
        %mincount = min([ping_ch.minCount]);
        maxcount = max([ping_ch.maxCount]);
        %minrange = min([ping_ch.minRange]);
        %maxrange = max([ping_ch.maxRange]);
        
        % Pad each ping so they are equal length
        % Set all array lengths
        if strcmp(dtype,'cw')
            new_rx = NaN(maxcount,length(time_mt));
            new_alg = NaN(maxcount,length(time_mt));
            new_ath = NaN(maxcount,length(time_mt));
            new_cpx = NaN(1,length(time_mt));
        else
            new_rx = NaN(1,length(time_mt));
            new_alg = NaN(1,length(time_mt));
            new_ath = NaN(1,length(time_mt));
            new_cpx = NaN(maxcount,length(time_mt));
        end

        for j=1:numel(ping_ch) 
            temp_samp_rx = [ping_ch(j).power_cw];
            temp_samp_alg = [ping_ch(j).alg_ele];
            temp_samp_ath = [ping_ch(j).ath_ele];
            temp_samp_cpx = [ping_ch(j).complexsamples];
            new_rx(1:(ping_ch(j).maxCount),j) = temp_samp_rx;
            new_alg(1:(ping_ch(j).maxCount),j) = temp_samp_alg;
            new_ath(1:(ping_ch(j).maxCount),j) = temp_samp_ath;
            new_cpx(1:(ping_ch(j).maxCount),j) = temp_samp_cpx;
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

            procping=EstimateProcessedSampleData_doubletest(pingdata,transdata,transdata_ch,transducerdata, paramdata, filterdata, envirodata, TVG_range_correction);
            procping.timestamp_raw=data.echodata(ping).timestamp; %just regular timestamp not unix // taken from ek80 and use as comparison with ctd timestamp
            procping.channel=data.echodata(ping).channelID;
            procping.ping_global = global_counter;

            %assign ping to file output struct
            procdata(ping)=procping;

        end
    end
end