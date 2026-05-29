% Remove gaps between IN detected samples for every ping
%
function  new_mask = INF_Remove_Gaps(mask,prcnt_thres)

pings = size(mask,2);
samples = size(mask,1);
thres_cells = floor(prcnt_thres*samples/100);
%for i = 1:pings
new_mask = mask;
for i = 1:pings
    [~,pos] = findpeaks(double(new_mask(:,i)));
    for ii = 1:length(pos)-1
        dist_peak(ii) = pos(ii+1)-pos(ii);
        if dist_peak(ii) < thres_cells
            new_mask(pos(ii):pos(ii+1),i) = true;
        end
    end
end

end

