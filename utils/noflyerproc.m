clear all;
addpath(genpath('C:\Users\bgras\Desktop\flyer_code'));

% flyer = load('C:\Users\bgras\Desktop\flyer_data\EK80_Processed\endeavor_dive2_ultradouble\20190923_224315_merged.mat');
outpath ='C:\Users\bgras\Desktop\tank_cal\out\';
% outpath='C:\Users\bgras\Desktop\lars_sub\out\';
save_files =1;
save_index =1;
fileAppend='pings';
inject_environment = 0;
defaultPath = 'C:\Users\bgras\Desktop\flyer_data\Flyer_Cruise_Data\Endeavor\Dive2';

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

            
            %make header structs
            pingdata = data.echodata(ping);
            paramdata = data.param(ping);
            envirodata= data.environ;
            filterdata = data.filters;
            
            
            %assign transducer
            if(strcmp(pingdata.channelID,  data.config.transceivers.channels(1).ChannelID)==1)
                transducerdata = data.config.transceivers.channels(1).transducer;
            else
                transducerdata = data.config.transceivers.channels(2).transducer;
            end
            

        
            procping=EstimateProcessedSampleData_doubletest(pingdata,transducerdata, paramdata, filterdata, envirodata);


            
            %append useful information
            procping.timestamp=data.echodata(ping).timestampunix;
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
            global_indexer(global_counter).timestamp=data.echodata(ping).timestampunix;
            global_indexer(global_counter).channel=data.echodata(ping).channelID;
            
       
 
         
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
        assignin('base',fileAppend,procdata(:, 1:length(procdata)));
        temp=strcat(outpath, temp);
        save(temp,fileAppend);
        evalin('base',['clear' sprintf(' %s',fileAppend)]);
    end
    clear procdata;
    disp(['Finished reading file ' int2str(fileNumber) ' of ' int2str(nFiles)]);
end

%assign dive cast numbers


if(save_index == 1)
    temp=strcat(outpath, 'global_index');
    save(temp,'global_indexer');
end
