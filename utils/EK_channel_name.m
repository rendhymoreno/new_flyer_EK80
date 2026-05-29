function [chname,chnum] = EK_channel_name(tempsv)

fieldn = fieldnames(tempsv);
numStr = regexp(fieldn, '\d+$', 'match');    % gives index and also the freqs
idx_not_empty = ~cellfun(@isempty, numStr); %index of data
chnum = str2double([numStr{:}]);                  % flatten one level
chname = fieldn(idx_not_empty);

end