function ezscatter3(x,y,c,cmap_t,climits,x_form)

if nargin == 1
    fn = fieldnames(x);
    x = datetime([x.(fn{1}).vars.timestamp],"ConvertFrom","epochtime",TicksPerSecond=1e6);
    y = [x.(fn{1}).vars.range];
    c = [x.(fn{1}).val];

elseif nargin == 2 
    if ischar(y)
        cmap_t = y;
    elseif isa(c,"double") & length(c)==2
        climits = c;
    end

    fn = fieldnames(x);
    datain = x;
    x = datetime([datain.(fn{1}).vars.timestamp],"ConvertFrom","epochtime",TicksPerSecond=1e6);
    y = [datain.(fn{1}).range];
    c = [datain.(fn{1}).val];

elseif nargin == 3
    cmap_t = y;
    climits = c;
    fn = fieldnames(x);
    datain = x;
    if any(ismember(fieldnames(datain.(fn{1})),'val'))
        x = datetime([datain.(fn{1}).vars.timestamp],"ConvertFrom","epochtime",TicksPerSecond=1e6);
        y = [datain.(fn{1}).range];
        c = [datain.(fn{1}).val];
    else
        x = datetime([datain.(fn{1}).time],"ConvertFrom","datenum");
        y = [datain.(fn{1}).range];
        if any(ismember(fieldnames(datain.(fn{1})),'Sv'))
            c = [datain.(fn{1}).Sv];
        elseif any(ismember(fieldnames(datain.(fn{1})),'TS'))
            c = [datain.(fn{1}).TS];
        end
    end
end

if exist('x_form','var')
    if strcmp(x_form,'time')
        tmp = datetime(x,'ConvertFrom','datenum');
        x = tmp;
    end
end

[X,Y] = meshgrid(x,y);
Z = zeros(length(x),length(y));
X = X(:); Y=Y(:); Z=Z(:); c=c(:);

figure();
scatter3(X, Y, Z,4,c,'filled','square');
view(2)
%set(h,'EdgeColor','none');
if strcmp(cmap_t,'EK60')
    cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
else
    colormap(cmap_t)
end
%set(gca, 'AlphaData', ~isnan(c))
set(gca,"YDir","reverse")
axis tight; shading flat;
xticks('auto');yticks('auto');
cb1 = colorbar;
cb1.Label.String = 'Target Strength (dB)';
xlim([min(x,[],"all") max(x,[],"all")]);
ylim([min(y,[],"all") max(y,[],"all")]);
if ~exist('climits','var')
    clim([min(c,[],'all') max(c,[],'all')])
else
    clim([climits(1) climits(2)])
end

grid on;
xlabel('Time (UTC)');
ylabel('Range (m)');

end