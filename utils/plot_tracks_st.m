function plot_tracks_st(st_data,ststruct,tt,eventdn,plt_type)


chan = fieldnames(st_data);

if ~isempty(eventdn)
    plotevt = 1;
    if isdatetime(eventdn)
        event_dn = eventdn;
    else
        event_dn = datetime(eventdn,"ConvertFrom","datenum");
    end
else
    plotevt = 0;
    event_dn = 0;
end

tt_samples = tt.target_id;
tt_pings = tt.target_ping_number;
time = datetime([st_data.(chan{1}).vars.timestamp],"ConvertFrom","datenum");
range = [st_data.(chan{1}).range];
r_idx_st = [ststruct.idx_r];
%X_idx = pings(singletargetdata.Ping_number);
c_t = st_data.(chan{1}).val;
[X,Y] = meshgrid(time,range);
Z = zeros(length(range),length(time));
X = X(:); Y=Y(:); Z=Z(:); c_t=c_t(:);

%% Events
event_idx = event_dn > min(time) & event_dn < max(time);
event_dn = event_dn(event_idx);

if ~isempty(eventdn)
    event_dnum = datenum(event_dn);
    t_dnum = datenum(time);
    idx_evt = dsearchn(t_dnum',event_dnum);
    evt(:,1) = idx_evt;
    evt(1:end-1,2) = idx_evt(2:end)-1;
    evt(end,2) = length(time);
end

%% Track gradient
ping = [1:length(time)];
grad = zeros(length(tt_samples),1);
y = zeros(length(tt_samples),1);
x = zeros(length(tt_samples),1);
XQ = NaN(length(range),length(time));
YQ = NaN(length(range),length(time));
U = NaN(length(range),length(time));
V = NaN(length(range),length(time));
grad_range_start = zeros(length(tt_samples),1);
grad_ping_end = zeros(length(tt_samples),1);
for ii = 1:length(tt_samples)
    %for direct grad calc
    R_val = r_idx_st(tt_samples{ii});
    y(ii,1) = range(R_val(end))-range(R_val(1));
    idx_v = R_val(1);
    %t_val = time(tt_pings{ii});
    t_val = ping(tt_pings{ii});
    %x(ii,1) = seconds(t_val(end)-t_val(1));
    x(ii,1) = ping(t_val(end)-t_val(1));
    idx_u = tt_pings{ii}(1);
    grad(ii,1) = y(ii)/x(ii);
    grad_range_start(ii,1) = idx_v;
    grad_ping_end(ii,1) = ping(t_val(end));
    %for quiver
    XQ(idx_v,idx_u) = ping(tt_pings{ii}(1));
    YQ(idx_v,idx_u) = range(R_val(1));
    U(idx_v,idx_u) = ping(tt_pings{ii}(end))-ping(tt_pings{ii}(1));
    V(idx_v,idx_u) = y(ii,1);
end

% Seperating tracks according to groups

msk1 = grad_ping_end < evt(2,1);
msk2 = grad_ping_end > evt(2,1) & grad_ping_end < evt(3,1);
msk3 = grad_ping_end > evt(3,1) & grad_ping_end < evt(4,1);
msk4 = grad_ping_end > evt(4,1) & grad_ping_end < evt(5,1);
msk5 = grad_ping_end > evt(5,1);

r_grp1 = range(grad_range_start(msk1));
r_grp2 = range(grad_range_start(msk2));
r_grp3 = range(grad_range_start(msk3));
r_grp4 = range(grad_range_start(msk4));
r_grp5 = range(grad_range_start(msk5));

v_grp1 = grad(msk1);
v_grp2 = grad(msk2);
v_grp3 = grad(msk3);
v_grp4 = grad(msk4);
v_grp5 = grad(msk5);
v_cell = {v_grp1, v_grp2, v_grp3, v_grp4, v_grp5};


% max_dim = max(cellfun(@length, groups));
% Ycombined_v = NaN(max_dim,5);
% for i = 1:numel(groups)
%     Ycombined_v(1:length(groups{i}), i) = groups{i};
% end
% Statistics
v_g_mat = combine_unequal_data(v_cell);
v_g_tbl = array2table(v_g_mat);
v_g_tbl.Properties.VariableNames = ["T0: L45%","T1: L5%",...
    "T2: L45%","T3: L0%","T4: L45%"];
v_g_tbl_long = stack(v_g_tbl,1:5,'NewDataVariableName','Velocity','IndexVariableName','Light group');
%v_g_tbl_long = rmmissing(v_g_tbl_long);
light_g = categorical(v_g_tbl_long.("Light group"));
G = groupsummary(v_g_tbl_long,"Light group","mean");
colors = ["red","blue","green","orange","purple"];
%% Boxplot between groups
figure();
ax = axes;
for bb=1:5
    hold on
    % boxchart(v_g_tbl_long.("Light group"),v_g_tbl_long.Velocity,'JitterOutliers','on',...
    %   'MarkerStyle','.','BoxWidth',0.7,'Notch','on','BoxFaceColor',colors);
    c = cell(height(v_g_tbl(:,bb)),1);
    c(:) = {v_g_tbl.Properties.VariableNames{bb}};
    gname = categorical(c);
    boxchart(gname,table2array(v_g_tbl(:,bb)),'JitterOutliers','on','MarkerStyle','.','BoxWidth',0.7,...
        'MarkerSize',10,'LineWidth',1.5);
    set(ax,'FontSize',14);
    
    hold off
    if bb == 5
        hold off;
        xlabel('Time blocks with light intensity levels');
        ylabel('Velocity (m/s)');
        set(gcf,'color','w')
    end
end

% stats = zeros(5,5,1,1); %
% stats(4,5,1,1) = 3;
% [stats_Y,stats_X1,stats_X2] = plot_stats(b,stats);
[h,p,ci,stats] = ttest2(v_grp1,v_grp2)
%% Correlation with depth
idx_r_20 = range(grad_range_start) < 20;
r_20 = grad_range_start(idx_r_20);
r_20 = range(r_20);
v_20 = grad(idx_r_20);
idx_r_40 = range(grad_range_start) > 20 & range(grad_range_start) < 40; 
r_40 = grad_range_start(idx_r_40);
r_40 = range(r_40);
v_40 = grad(idx_r_40);
idx_r_60 = range(grad_range_start) > 40 & range(grad_range_start) < 60;
r_60 = grad_range_start(idx_r_60);
r_60 = range(r_60);
v_60 = grad(idx_r_60);
idx_r_80 = range(grad_range_start) > 60 & range(grad_range_start) < 80;
r_80 = grad_range_start(idx_r_80);
r_80 = range(r_80);
v_80 = grad(idx_r_80);
idx_r_100 = range(grad_range_start) > 80 & range(grad_range_start) < 100;
r_100 = grad_range_start(idx_r_100);
r_100 = range(r_100);
v_100 = grad(idx_r_100);

r_total = {r_20 r_40 r_60 r_80 r_100};
%groups = {v_grp1, v_grp2, v_grp3, v_grp4, v_grp5};
r_g = combine_unequal_data(r_total);
v_total = {v_20 v_40 v_60 v_80 v_100};
v_g = combine_unequal_data(v_total);
mu_grad = mean(grad);
med_grad = median(grad);
% Hist Targets
edges = [-0.4 -0.3:0.02:0.3 0.4];
grad_pos = grad > 0;
grad_neg = grad < 0;
prc_pos = sum(grad_pos,[])*100/length(grad);
prc_neg = sum(grad_neg,[])*100/length(grad);
histogram(grad,edges,'Normalization','percentage')
set(gca,'FontSize',16)
xlabel('Target velocity (m/s)'); ylabel('Percentage (%)')
pos = sprintf(' \\mu = %.3f\n med = %.3f\n Vel(+) = %0.1f%%\n Vel(-) = %0.1f%%\n',...
    mu_grad,med_grad,prc_pos,prc_neg);
t1 = text(0.2, 8, pos, 'Color', 'r', ...
    'FontWeight', 'bold', 'FontSize', 12);
%% Histogram and Correlation over depth
tiledlayout(5,4)
for sp=1:5
    nexttile([1 3])
    xf = r_g(:,sp);
    yf = v_g(:,sp);
    xf(isnan(xf)) = [];
    yf(isnan(yf)) = [];
    muu = mean(yf);
    [rho,p] = corr(xf,yf);
    scatter(xf,yf,4,'filled')
    rhot = sprintf('R = %.4f\n', rho);
    t1 = text(xf(1), 0.3, rhot, 'Color', 'r', ...
    	'FontWeight', 'bold', 'FontSize', 10);
    set(gca,'FontSize',12)
    if sp==3
        ylabel('Velocity (m/s)','FontSize',16);
    elseif sp==5
        xlabel('Distance from transducer (m)','FontSize',16);
    end
    coefficients = polyfit(xf, yf, 1);
    xFit = linspace(min(xf), max(xf), length(xf));
    yFit = polyval(coefficients , xFit);
    hold on; % Set hold on so the next plot does not blow away the one we just drew.
    plot(xFit, yFit, 'r-', 'LineWidth', 2); % Plot fitted line.
    grid on;
    hold off;
    nexttile
    edges = [-0.5 -0.3:0.05:0.3 0.5];
    histogram(yf,edges,'Normalization','percentage');
    set(gca,'FontSize',12,'YAxisLocation','right')
    grid on;
    if sp==3
        ylabel('Percentage Counts (%)','FontSize',16);
    elseif sp==5
        xlabel('Target velocity (m/s)','FontSize',14);
    end
    yl = ylim;
    %sMean = sprintf('\\mu = %.3f\n  Med = %.3f', muu, med);
    sMean = sprintf('\\mu = %.3f\n', muu);
    % Position the text 90% of the way from bottom to top.
    t2 = text(0.070, 0.85*yl(2), sMean, 'Color', 'r', ...
    	'FontWeight', 'bold', 'FontSize', 10);
end
%%
[h,p,ci,stats] = ttest2(v_grp1,v_grp2)

corrplot(rv)
scatter(r_20,v_20);
scatter(r_grp5,v_grp5);
[R,P] = corrcoef(r_20,v_20)
[R,P] = corrcoef(r_grp1,v_grp1)
[rho,pval] = corr(r_20,v_20);
% %this is for simple plotting
% mask_grad_0 =  grad == 0;
% mask_grad_down =  grad > 0; %positive grad is going down in depth
% mask_grad_up =  grad < 0;
%% Simple plot of tracks 
if strcmp(plt_type,'simple')
    figure()
    ax1 = nexttile;
    %subplot(nrow,4,1:8)
    scatter3(X, Y, Z,4,c_t,'filled','square');
    %ss = imagesc(time, range, c_t);
    %clim([climits]);
    axis tight; %shading flat;
    view(2)
    set(gca,'YDir','reverse','XLim',[time(1) time(end)],'FontSize',16)
    ylabel('Horizontal range (m)');
    xlabel('Time (UTC)');
    cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(ax1,cmap); cb=colorbar;
    cb.Label.String = 'Target Strength dB ref 1 m^2';
    xtt = [1; evt(2:end-1,1); length(time)];
    xttform = time(xtt);
    xticks([xttform]);
    xtickformat('HH:mm:ss');
    %set(gca,'XTickLabels',[]);
    %ttl = sprintf('Targets with TS: %0.1f to %0.1f',thres_min,thres_max);
    hold on
    for i=1:length(tt_samples)
        Y_idx = r_idx_st(tt_samples{i});
        plot(time([tt_pings{i}]),range(Y_idx),"LineWidth",4,"Color","black")
    end
    for i = 2:length(event_dn)
        plot([time(evt(i)) time(evt(i))],[min(range) max(range)],'-.','LineWidth',3,'Color','black')
    end
end
%% Complex scatter + colored track plot
if strcmp(plt_type,'colored_track')
    figure()
    cd = flipud(gray); % take your pick (doc colormap)
    cd = interp1(linspace(min(c_t),max(c_t),length(cd)),cd,c_t); % map color to y values
    scatter3(X, Y, Z,4,cd,'filled','square');
    axis tight; %shading flat;
    view(2)
    set(gca,'YDir','reverse','XLim',[time(1) time(end)],'FontSize',16)
    ylabel('Horizontal range (m)');
    xlabel('Time (UTC)');
    xtt = [1; evt(2:end-1,1); length(time)];
    xttform = time(xtt);
    xticks([xttform]);
    xtickformat('HH:mm:ss');
    %colormap(flipud(gray)); cb=colorbar;
    %cb.Label.String = 'Target Strength dB ref 1 m^2';
    %ttl = sprintf('Targets with TS: %0.1f to %0.1f',thres_min,thres_max);
    % cd = uint8(cd'*255); % need a 4xN uint8 array
    % cd(4,:) = 255; % last column is transparency

    hold on
    cmap_red_blue = redblue(256);
    for i=1:length(tt_samples)
        tic
        Y_idx = r_idx_st(tt_samples{i});
        xx = time([tt_pings{i}]);
        yy = range(Y_idx);
        zz = ones(length(Y_idx),1)*(grad(i));
        surface([xx(:) xx(:)],[yy(:) yy(:)],[zz(:) zz(:)],...
            'FaceColor', 'none', ...    % Don't bother filling faces with color
            'EdgeColor', 'interp', ...  % Use interpolated color for edges
            'LineWidth', 2);
        clim([-0.1 0.1]);
        colormap(cmap_red_blue)
        view(2);
        cb = colorbar;
        cb.Label.String = 'velocity (m/s)';
        %drawnow
        if i == round(length(tt_samples)/4) || i == round(length(tt_samples)/2) || i == round(3*length(tt_samples)/4)
            fprintf('plotted %0.1f%% in %0.1f seconds \n',round(i*100/length(tt_samples)),toc);
        end
    end
    
    for i = 2:length(event_dn)
        plot([time(evt(i)) time(evt(i))],[min(range) max(range)],'-.','LineWidth',3,'Color','black')
    end
    %h=get(gca,'Children');
    %uistack(h(end),'top');
    %uistack(h(end),'up',2);
end
%Works but color is inconsistent
    % Y_idx = r_idx_st(tt_samples{i});
    % h = plot(time([tt_pings{i}]),range(Y_idx),"LineWidth",4);
    % drawnow
    % set(h.Edge,'ColorBinding','interpolated','ColorData',cd);

% Works but flat color
% for i=1:length(tt_samples)
%     Y_idx = r_idx_st(tt_samples{i});
%     if mask_grad_up(i) == 1 %red
%         plot(time([tt_pings{i}]),range(Y_idx),"LineWidth",4,"Color",[0.49321 0.01963 0.00955]);
%     elseif mask_grad_down(i) == 1 %blue
%         plot(time([tt_pings{i}]),range(Y_idx),"LineWidth",4,"Color","blue");
%     elseif mask_grad_0(i) == 1  
%         plot(time([tt_pings{i}]),range(Y_idx),"LineWidth",4,"Color",[0.63323 0.99195 0.23937]);
%     end
% end

%% Quiver
if strcmp(plt_type,'quiver_track')
    [X2,Y2] = meshgrid(ping,range);
    %figure(); %set(fig2,'visible','on','PaperPositionMode','auto','PaperPosition',[0 0 20 10]);
    %s = imagesc(ping, range, c_t);
    ss = scatter(X2(:),Y2(:),3,c_t,'filled','square');
    axis tight; %shading flat;
    %view(2)
    set(gca,'YDir','reverse','XLim',[ping(1) ping(end)])
    %cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
    colormap(flipud(gray))
    colorbar;
    %ttl = sprintf('Targets with TS: %0.1f tp %0.1f',thres_min,thres_max);
    xlabel('Time (UTC)'); ylabel('Horizontal Range (m)');
    %title(ttl)
    hold on
    quiver(XQ,YQ,U,V,0,'LineWidth',1,'Color','Red','MarkerSize',6) %'MaxHeadSize',0.2
    set(gca,"YDir","reverse")
    % for i=1:length(tt_samples)
    %     Y_idx = r_idx_st(tt_samples{i});
    %     plot(ping([tt_pings{i}]),range(Y_idx),"LineWidth",2,"Color","blue")
    % end

end

end