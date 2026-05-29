function [fig,s] = st_analysis(stdata,thres_min,thres_max,eventdn)

chan = fieldnames(stdata);
% if ~isempty(thres)
%      thres_min = thres(1);
%      thres_max = thres(2);
% %     stdata = threshold(stdata,'EK80',1,thres_min,thres_max,[],[]);  %50 thres too hard
% end
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

tt = datetime([stdata.(chan{1}).vars.timestamp],"ConvertFrom","datenum");
rr = [stdata.(chan{1}).range];
c = [stdata.(chan{1}).val];
dr = rr(2)-rr(1);
depth = [stdata.(chan{1}).vars.depth]';
climits = [min(c,[],"all") max(c,[],"all")];

for ii = 1:length(thres_min)
    if thres_min(ii) == 0 && thres_max(ii) == 0
        thres_min(ii) = min(c,[],"all");
        thres_max(ii) = max(c,[],"all");
    end
end

[X,Y] = meshgrid(tt,rr);
Z = ones(length(rr),length(tt));
c2_1 = c;
c2_2 = c;
c2_3 = c;
c2_4 = c;
c2_5 = c;

[pdf_temp_ori,x_temp_ori]=pdf_perso_rms(c2_1(:),25); %Generate pdf from histogram
%[pdf_temp_thres,x_temp_thres]=pdf_perso_rms(c2(:),25); 

mask_1 = c > thres_min(1) & c < thres_max(1);
c2_1(~mask_1) = NaN;
pdf_mask_1 = x_temp_ori>thres_min(1) & x_temp_ori<thres_max(1);

mask_2 = c > thres_min(2) & c < thres_max(2);
c2_2(~mask_2) = NaN;
pdf_mask_2 = x_temp_ori>thres_min(2) & x_temp_ori<thres_max(2);

mask_3 = c > thres_min(3) & c < thres_max(3);
c2_3(~mask_3) = NaN;
pdf_mask_3 = x_temp_ori>thres_min(3) & x_temp_ori<thres_max(3);

mask_4 = c > thres_min(4) & c < thres_max(4);
c2_4(~mask_4) = NaN;
pdf_mask_4 = x_temp_ori>thres_min(4) & x_temp_ori<thres_max(4);

mask_5 = c > thres_min(5) & c < thres_max(5);
c2_5(~mask_5) = NaN;
pdf_mask_5 = x_temp_ori>thres_min(5) & x_temp_ori<thres_max(5);

ctotal = {c2_1 c2_2 c2_3 c2_4 c2_5};
%% Echostatistics
% Add payload depth if EK80
% if strcmp(trans,'EK80')
%     out.depth = depth;
% end

for ii = 1:length(ctotal)
    % Abundance / depth_integral (Sa)
    dataout_lin = 10.^(ctotal{1,ii}/10);
    integral = nansum(dataout_lin,1)*dr;
    integral = 10*log10(integral);
    integral(isinf(integral)) = NaN;
    integral(integral<-900) = NaN;
    integral_c{1,ii} = integral;
    %out.Sa = integral';

    % Density / sv_avg (MVBS)
    avg = nanmean(dataout_lin);
    avg = 10*log10(avg);
    avg(isinf(avg)) = NaN;
    avg(avg<-900) = NaN;
    avg_c{1,ii} = avg;
    %out.MVBS = avg';

    % Location / Center of Mass (COM)
    com = (nansum(dataout_lin.*rr,1)) ./ (nansum(dataout_lin,1));
    com_c{1,ii} = com;
    %out.COM = com';

    % Inertia / Spread or dispersion around center of mass
    diff = (repmat(rr,1,size(dataout_lin,2)) - com);
    inertia = nansum((diff.^2).*dataout_lin,1) ./ (nansum(dataout_lin,1));
    inertia_c{1,ii} = inertia;
    %out.Inertia = inertia';

    % Number of targets
    ntargets = ~isnan(dataout_lin);
    ntargets_ping = sum(ntargets,1);
    ntargets_c{1,ii} = ntargets_ping;
end

%% Getting Events

event_idx = event_dn > min(tt) & event_dn < max(tt);
event_dn = event_dn(event_idx);

if ~isempty(eventdn)
    event_dnum = datenum(event_dn);
    t_dnum = datenum(tt);
    idx_evt = dsearchn(t_dnum',event_dnum);
    evt(:,1) = idx_evt;
    evt(1:end-1,2) = idx_evt(2:end)-1;
    evt(end,2) = length(tt);
end

%% Integral Sa
integral = integral_c{1,1};
integral_avg = movmean(integral,30);
nan_idx = ~isnan(integral_avg);
integral_avg = integral_avg(nan_idx);
t_com = tt(1:length(integral_avg));

%int_loess = smooth(1:length(integral),integral,'rloess');
%plot(1:length(integral),integral,'b.',1:length(integral),int_loess,'r-')

int_med = movmedian(integral,30,'omitnan');

[X_reg,Y_reg,Rsq,~,~] = regress_fit(1:length(integral_avg), integral_avg);
xlim([1 length(integral)]);
hold on
plot(1:length(integral),int_med,'k','LineWidth',2)
%plot(1:length(integral_avg),integral_avg,'k','LineWidth',2)
for i = 2:length(event_dn)
    plot([evt(i) evt(i)],[min(integral) max(integral)],'-.','LineWidth',1,'Color','#583D3D')
end
xticks([1; evt(2:end,1); length(integral)]);
xticklabels([datestr([event_dn; max(tt)],'HH:MM:SS')]);
h=get(gca,'Children');
uistack(h(7),'up',2); %moves polyfit a level higher
legend("95% CI", "Sa", "Sa moving avg", "polyfit 10th-deg", "LI-Block")
xlabel(['Time (UTC)']);
ylabel(['Sa (dB re 1m^-2 m^-3)']);

%% Number of targets
ntargets = ntargets_c{1,1};
ntargets_avg = movmean(ntargets,20);
nan_idx = ~isnan(ntargets_avg);
ntargets_avg = ntargets_avg(nan_idx);
t_com = tt(1:length(ntargets_avg));

[X_reg,Y_reg,Rsq,~,~] = regress_fit(1:length(ntargets_avg), ntargets(1:length(ntargets_avg)));
xlim([1 length(ntargets)]);
hold on
plot(1:length(ntargets_avg),ntargets_avg,'k','LineWidth',2)
for i = 2:length(event_dn)
    plot([evt(i) evt(i)],[min(ntargets) max(ntargets)],'-.','LineWidth',1,'Color','#583D3D')
end
xticks([1; evt(2:end,1); length(ntargets)]);
xticklabels([datestr([event_dn; max(tt)],'HH:MM:SS')]);
h=get(gca,'Children');
uistack(h(7),'up',2); %moves polyfit a level higher
legend("95% CI", "ntargets", "ntargets moving avg", "polyfit 10th-deg", "LI-Block")
xlabel(['Time (UTC)']);
ylabel(['ntargets (m^-2)']);

%% COM
%com(com > 49.7 & com < 50) = NaN;
for ii = 1:length(com_c)
    com = com_c{1,ii};
    com_avg = movmean(com,3);
    nan_idx = ~isnan(com_avg);
    com_avg = com_avg(nan_idx);
    t_com = tt(1:length(com_avg));

    %xlim([1 length(com)]);
    [X_reg,Y_reg,Rsq,~,~] = regress_fit(1:length(com_avg), com(1:length(com_avg)));
    hold on
    plot(1:length(com_avg),com_avg,'k','LineWidth',2)
    for i = 2:length(event_dn)
        plot([evt(i) evt(i)],[min(com) max(com)],'-.','LineWidth',1,'Color','#583D3D')
    end
    xticks([1; evt(2:end,1); length(com)]);
    xticklabels([datestr([event_dn; max(tt)],'HH:MM:SS')]);
    h=get(gca,'Children');
    %uistack(h(8),'up',2); %moves polyfit a level higher
    legend("95% CI", "COM", "COM moving avg", "polyfit 10th-deg", "LI-Block")
    xlabel(['Time (UTC)']);
    ylabel(['Depth (m)']);
end

% Taking COM from seperate groups for a single dataset
%all targets
com = com{1,1};
COM_1_45 = com(evt(1,1):evt(1,2));
COM_2_5 = com(evt(2,1):evt(2,2));
COM_3_45 = com(evt(3,1):evt(3,2));
COM_4_0 = com(evt(4,1):evt(4,2));
COM_5_45 = com(evt(5,1):evt(5,2));

%groups = {sa_45_1, sa_5_2, sa_45_3, sa_0_4, sa_45_5};
groups = {COM_1_45, COM_2_5, COM_3_45, COM_4_0, COM_5_45};
lht_on = [COM_1_45 COM_3_45 COM_5_45];
lht_off = [COM_2_5 COM_4_0];

max_dim = max(cellfun(@length, groups));
Ycombined_com = NaN(max_dim,5);
for i = 1:numel(groups)
    Ycombined_com(1:length(groups{i}), i) = groups{i};
end

[p,h] = ranksum(lht_on, lht_off)

[p,tb_st,stats_kr] = kruskalwallis(Ycombined_com);
[c,m] = multcompare(stats_kr,"CriticalValueType","hsd");
tbl1 = array2table(c,"VariableNames", ...
     ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"])

%% Multifigure
nrow = 2*length(thres_min);
%sp_idx_top = [9:1:(10+2*n_param+n_param-1)];
asu = figure();
subplot(nrow,4,1:8)
ss = scatter3(X(:), Y(:), Z(:),9,c2_1(:),'filled','square');
clim([climits]);
axis tight; %shading flat;
view(2)
set(gca,'YDir','reverse','XLim',[tt(1) tt(end)])
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap); %colorbar;
ttl = sprintf('Targets with TS: %0.1f to %0.1f',thres_min,thres_max);
hold on
for i = 2:length(event_dn)
    h = plot([X(1,evt(i)) X(1,evt(i))],[min(Y(:)) max(Y(:))],'-.','LineWidth',2,'Color','black');
    uistack(h,'top');
end
ax = gca;
ax.SortMethod = 'childorder';
hold off
%ylabel('Horizontal Range (m)');

ax1=gca;
ax2 = axes('Position', get(ax1, 'Position'),'Color', 'none');
set(ax2, 'XAxisLocation', 'top','YAxisLocation','Right');
ax2.XAxis = matlab.graphics.axis.decorator.DatetimeRuler;
set(ax2, 'XLim', get(ax1, 'XLim'),'YLim', get(ax1, 'YLim')); % set the same Limits and Ticks on ax2 as on ax1;
set(ax2, 'XTick', get(ax1, 'XTick'), 'YTick', get(ax1, 'YTick'));
set(ax1,"Visible","on")
ax2.YTick = [];
ax1.XTickLabel = [];
set(ax2,'FontSize',14)
set(ax1,'FontSize',14)

subplot(nrow,4,[9:11,13:15]) %[9:10,13:14]
ss = scatter3(X(:), Y(:), Z(:),9,c2_2(:),'filled','square');
clim([climits]);
axis tight; %shading flat;
view(2)
set(gca,'YDir','reverse','XLim',[tt(1) tt(end)],'FontSize',14)
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap); %colorbar;
ttl = sprintf('Targets with TS: %0.1f to %0.1f',thres_min(2),thres_max(2));
title(ttl)
%ylabel('Horizontal Range (m)');
ax1 = gca;
ax1.XTick = [];
hold on;
for i = 2:length(event_dn)
    h = plot([X(1,evt(i)) X(1,evt(i))],[min(Y(:)) max(Y(:))],'-.','LineWidth',2,'Color','black');
    uistack(h,'top');
end
ax = gca;
ax.SortMethod = 'childorder';
hold off

subplot(nrow,4,[12,16]) %[11:12,15:16]
b = bar(x_temp_ori(~pdf_mask_2),pdf_temp_ori(~pdf_mask_2));
hold on
bar(x_temp_ori(pdf_mask_2),pdf_temp_ori(pdf_mask_2),'FaceColor','red');
xlim([x_temp_ori(1) x_temp_ori(end)]);
xticks([unique(round(x_temp_ori))]);
%xlabel('Target Strength'); 
%ylabel('pdf'); 
ax1 = gca;
ax1.XTick = [];
set(ax1, 'YAxisLocation','Right','FontSize',12);
%legend('Single targets','Single targets thresholded')
%ttl2 = sprintf('PDF of single targets with TS threshold: %0.1f tp %0.1f',thres_min,thres_max);
%title(ttl2)

subplot(nrow,4,[17:19,21:23])
ss = scatter3(X(:), Y(:), Z(:),9,c2_3(:),'filled','square');
clim([climits]);
axis tight; %shading flat;
view(2)
set(gca,'YDir','reverse','XLim',[tt(1) tt(end)],'FontSize',14)
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap); %colorbar;
ttl = sprintf('Targets with TS: %0.1f to %0.1f',thres_min(3),thres_max(3));
title(ttl)
ylabel('Horizontal Range (m)');
ax1 = gca;
ax1.XTick = [];
hold on
for i = 2:length(event_dn)
    h = plot([X(1,evt(i)) X(1,evt(i))],[min(Y(:)) max(Y(:))],'-.','LineWidth',2,'Color','black');
    uistack(h,'top');
end
ax = gca;
ax.SortMethod = 'childorder';
hold off

subplot(nrow,4,[20,24])
b = bar(x_temp_ori(~pdf_mask_3),pdf_temp_ori(~pdf_mask_3));
hold on
bar(x_temp_ori(pdf_mask_3),pdf_temp_ori(pdf_mask_3),'FaceColor','red');
xlim([x_temp_ori(1) x_temp_ori(end)]);
xticks([unique(round(x_temp_ori))]);
%xlabel('Target Strength'); 
ylabel('pdf'); 
ax1 = gca;
set(ax1, 'YAxisLocation','Right','FontSize',12);
ax1.XTick = [];

subplot(nrow,4,[25:27,29:31])
ss = scatter3(X(:), Y(:), Z(:),9,c2_4(:),'filled','square');
clim([climits]);
axis tight; %shading flat;
view(2)
set(gca,'YDir','reverse','XLim',[tt(1) tt(end)],'FontSize',14)
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap); %colorbar;
ttl = sprintf('Targets with TS: %0.1f to %0.1f',thres_min(4),thres_max(4));
title(ttl)
%xlabel('Time (UTC)');
ax1 = gca;
ax1.XTick = [];
hold on
for i = 2:length(event_dn)
    h = plot([X(1,evt(i)) X(1,evt(i))],[min(Y(:)) max(Y(:))],'-.','LineWidth',2,'Color','black');
    uistack(h,'top');
end
ax = gca;
ax.SortMethod = 'childorder';
hold off

subplot(nrow,4,[28,32])
b = bar(x_temp_ori(~pdf_mask_4),pdf_temp_ori(~pdf_mask_4));
hold on
bar(x_temp_ori(pdf_mask_4),pdf_temp_ori(pdf_mask_4),'FaceColor','red');
xlim([x_temp_ori(1) x_temp_ori(end)]);
xticks([unique(round(x_temp_ori))]);
%xlabel('Target Strength'); 
%ylabel('pdf'); 
ax1 = gca;
set(ax1, 'YAxisLocation','Right','FontSize',12);
ax1.XTick = [];

subplot(nrow,4,[33:35,37:39])
ss = scatter3(X(:), Y(:), Z(:),9,c2_5(:),'filled','square');
clim([climits]);
axis tight; %shading flat;
view(2)
set(gca,'YDir','reverse','XLim',[tt(1) tt(end)],'FontSize',14)
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap); %colorbar;
ttl = sprintf('Targets with TS: %0.1f to %0.1f',thres_min(5),thres_max(5));
title(ttl)
xlabel('Time (UTC)');
ax1 = gca;
%ax1.XTick = [];
hold on
for i = 2:length(event_dn)
    h = plot([X(1,evt(i)) X(1,evt(i))],[min(Y(:)) max(Y(:))],'-.','LineWidth',2,'Color','black');
    uistack(h,'top');
end
ax = gca;
ax.SortMethod = 'childorder';
hold off

subplot(nrow,4,[36,40])
b = bar(x_temp_ori(~pdf_mask_5),pdf_temp_ori(~pdf_mask_5));
hold on
bar(x_temp_ori(pdf_mask_5),pdf_temp_ori(pdf_mask_5),'FaceColor','red');
xlim([x_temp_ori(1) x_temp_ori(end)]);
xttk = [unique(round(x_temp_ori))];
%xttk2 = xttk;
%xttk2(1:3:end) = [];
%xttk = xttk(1):2:xttk(end);
xticks([xttk(1):4:xttk(end)]); %[unique(round(x_temp_ori))]
%xticklabels(xttk2);
xlabel('Target Strength'); 
%ylabel('pdf'); 
ax1 = gca;
set(ax1, 'YAxisLocation','Right','FontSize',12);
%ax1.XTick = [];

%% Contour plot
% %ss = scatter3(X(:), Y(:), Z(:),1,c2_1(:),"square");
% %[X,Y] = meshgrid(tt,rr);
% [X1,Y1] = meshgrid([1:length(tt)],rr);
% contourf(X1,Y1,c2_1,25)
% clim([climits]);
% axis tight; %shading flat;
% view(2)
% set(gca,'YDir','reverse')
% cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap); %colorbar;
% ttl = sprintf('Targets with TS: %0.1f to %0.1f',thres_min,thres_max);
%%
%{
figure(); %set(fig2,'visible','on','PaperPositionMode','auto','PaperPosition',[0 0 20 10]);  
s = imagesc(tt, rr, c2_1, climits);
axis tight; %shading flat;
view(2)
set(gca,'YDir','reverse','XLim',[tt(1) tt(end)])
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap); colorbar;
ttl = sprintf('Targets with TS: %0.1f tp %0.1f',thres_min,thres_max);
xlabel('Time (UTC)'); ylabel('Horizontal Range (m)');
title(ttl)

figure(); %set(fig2,'visible','on','PaperPositionMode','auto','PaperPosition',[0 0 20 10]);  
%ss = scatter3(X(:), Y(:), Z, c2(:));
ss = scatter3(X(:), Y(:), Z(:),0.5,c2_1(:),"square");
clim([climits]);
axis tight; %shading flat;
view(2)
set(gca,'YDir','reverse','XLim',[tt(1) tt(end)])
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap); colorbar;
ttl = sprintf('Targets with TS: %0.1f tp %0.1f',thres_min,thres_max);
xlabel('Time (UTC)'); ylabel('Horizontal Range (m)');
title(ttl)

figure()
b = bar(x_temp_ori(~pdf_mask_1),pdf_temp_ori(~pdf_mask_1));
hold on
bar(x_temp_ori(pdf_mask_1),pdf_temp_ori(pdf_mask_1),'FaceColor','red');
xlim([x_temp_ori(1) x_temp_ori(end)]);
xticks([unique(round(x_temp_ori))]);
xlabel('Target Strength'); ylabel('probability density function'); 
legend('Single targets','Single targets thresholded')
ttl2 = sprintf('PDF of single targets with TS threshold: %0.1f tp %0.1f',thres_min(1),thres_max(1));
title(ttl2)
%}
end