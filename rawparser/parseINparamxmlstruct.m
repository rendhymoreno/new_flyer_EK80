% Parse Parameter XML data to a Parameter Matlab structure

function paramdata = parseINparamxmlstruct(xmldata)

if strcmp(xmldata.Name,'InitialParameter')
    nchildren = length(xmldata.Children.Children);
else
    error('This is not a Initial Parameter variable found in a EA440 struct')
end

for i = 1:nchildren
    %nchannel = length(xmldata.Children(i).Children);
    nattributes = length(xmldata.Children.Children(i).Attributes);
    for j = 1:nattributes
        name = xmldata.Children.Children(i).Attributes(j).Name;
        paramdata(i).(name) = xmldata.Children.Children(i).Attributes(j).Value;
        if sum(strcmp(xmldata.Children.Children(i).Attributes(j).Name, {'ChannelID','PingId'})) == 0
            paramdata(i).(name) = str2double(paramdata(i).(name));
        end
    end
end
