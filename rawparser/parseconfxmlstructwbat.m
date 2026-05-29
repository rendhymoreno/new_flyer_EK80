% Parse Configuration XML data to a Configuration Matlab structure
% Simrad, Lars Nonboe Andersen, 10/10-13

function confdata = parseconfxmlstructwbat(xmldata)

% force WBAT-esque systems that have one transceiver but switch between
% different transducers to have a single transceiver despite having two
% names...

%wbatnames = 1;  % replace length(names with this;
% also replaced transceivers(j).channels****  with transceivers.channels(j)

% Header

headeridx = find(strcmp({xmldata.Children.Name},'Header'));
headerxml = xmldata.Children(headeridx);

nattributes = length(headerxml.Attributes);

for i = 1:nattributes,
    header.(headerxml.Attributes(i).Name) = headerxml.Attributes(i).Value;
end

transceiversidx = find(strcmp({xmldata.Children.Name},'Transceivers'));
transceiversxml = xmldata.Children(transceiversidx);

ntransceivers = length(transceiversxml.Children);

for i = 1:ntransceivers,
   transceiverxml = transceiversxml.Children(i);
   transceivers(i).id =  transceiverxml.Name;
   nattributes = length(transceiverxml.Attributes);
   for j = 1:nattributes,
       transceivers(i).(transceiverxml.Attributes(j).Name) = transceiverxml.Attributes(j).Value;
   end
   
   channelsxml = transceiverxml.Children;
   nchannels = length(channelsxml.Children);
   channels = [];
   for j = 1:nchannels,
       channelxml = channelsxml.Children(j);
       channels(j).Name = channelxml.Name;
       nattributes = length(channelxml.Attributes);
       for k = 1:nattributes,
           channels(j).(channelxml.Attributes(k).Name) = channelxml.Attributes(k).Value;
       end
       
       transducer = [];
       transducerxml = channelxml.Children;
       nattributes = length(transducerxml.Attributes);
       for m = 1:nattributes,
           transducer.(transducerxml.Attributes(m).Name) = transducerxml.Attributes(m).Value;
       end
       channels(j).transducer = transducer;
   end
   transceivers(i).channels = channels;
end  

% Everything comes through as text, so convert selected numerical
% fields into text

%Fake simulation
%{
if length(transceivers) > 1
    if isempty(input_freq1) && isempty(input_freq2)
        error('Detected more than 1 transceiver, must input maximum of two channels to parse!')
    end

    input_freq1 = 38;
    input_freq2 = 200;
    freq_num = zeros(length(transceivers),1);
    for ii = 1:length(transceivers)
        freq_str = transceivers(ii).channels.ChannelIdShort;
        freq_str = freq_str(3:4);
        if strcmp(freq_str,'20')
            freq_str = '200';
        elseif strcmp(freq_str,'12')
            freq_str = '70';
        end
        freq_num(ii) = str2double(freq_str);
    end

    idx_trans1 = find(freq_num == input_freq1);
    idx_trans2 = find(freq_num == input_freq2);
    transceivers = transceivers(idx_trans1); %main WBT
    transceivers.channels(2) = [transceivers(idx_trans2).channels];
end
%}
%% assign wbatnames based on tranceiver
for ii=1:length(transceivers)
    temp_tsc = transceivers(ii);
    wbatnames = strrep([temp_tsc.TransceiverName],' ','');%strrep(c,' ','')

    for j = 1:length(transceivers(ii).channels)
        names = fieldnames(transceivers(ii).channels(j));

        %%% for WBAT systems, have one transceiver, but two channels for the
        %%% different frequencies/transducers so forcing it to only have 1
        %%% transceiver here

        for k = 1:size(wbatnames,1)
            if sum(strcmp(names{k}, {'Name', 'ChannelId', 'transducer', 'ChannelIDShort'})) == 0

                %if sum(strcmp(names{k}, {'Name', 'ChannelIdLong', 'transducer', 'ChannelID'})) == 0
                transceivers(ii).channels(j).(names{k}) = str2num(transceivers(ii).channels(j).(names{k}));
            end
        end

        names = fieldnames(transceivers(ii).channels(j).transducer);
        for k = 1:size(wbatnames,1)
            if ~strcmp(names{k}, 'TransducerName')
                transceivers(ii).channels(j).transducer.(names{k}) ...
                    = str2double(transceivers(ii).channels(j).transducer.(names{k}));
            end
        end
    end

end

confdata.header = header;
confdata.transceivers = transceivers;

%wbatnames = tranceiver name 


%{
for j = 1:length(transceivers.channels)
    names = fieldnames(transceivers.channels(j));

    %%% for WBAT systems, have one transceiver, but two channels for the
    %%% different frequencies/transducers so forcing it to only have 1
    %%% transceiver here

    for k = 1:wbatnames
        if sum(strcmp(names{k}, {'Name', 'ChannelId', 'transducer', 'ChannelIDShort'})) == 0

            %if sum(strcmp(names{k}, {'Name', 'ChannelIdLong', 'transducer', 'ChannelID'})) == 0
            transceivers.channels(j).(names{k}) = str2num(transceivers.channels(j).(names{k}));
        end
    end



    names = fieldnames(transceivers.channels(j).transducer);
    for k = 1:wbatnames
        if ~strcmp(names{k}, 'TransducerName')
            transceivers.channels(j).transducer.(names{k}) ...
                = str2num(transceivers.channels(j).transducer.(names{k}));
        end
    end
end

confdata.header = header;
confdata.transceivers = transceivers;
%}
