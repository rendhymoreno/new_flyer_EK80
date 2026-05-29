function out = echometrics(data,trans,channel,threshold,eventdn)

chan = fieldnames(data);
thres1 = threshold(1);
thres2 = threshold(2);
%datafilt = data;
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

if channel == 1
    lg = sprintf('[echometrics] Reading data from channel 1: %s ',chan{1});
    disp(lg)
    chan = chan(1);
elseif channel == 2
    lg = sprintf('[echometrics] Reading data from channel 2: %s ',chan{2});
    disp(lg)
    chan = chan(2);
else
    lg = sprintf('[echometrics] Reading data from all %i channels',length(chan));
    disp(lg)
end

for ch = 1:length(chan)
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        if isfield(data.(chan{ch}),'Sv')
            dataout_log = data.(chan{ch}).Sv;
            dataflag = 'Sv';
        elseif isfield(data.(chan{ch}),'TS')
            dataout_log = data.(chan{ch}).TS;
            dataflag = 'TS';
        end
        r = data.(chan{ch}).range;
        dr = r(2)-r(1);
        t = datetime([data.(chan{ch}).time],"ConvertFrom","datenum");
    elseif strcmp(trans,'EK80')
        dataout_log = [data.(chan{ch}).val];
        r = [data.(chan{ch}).range];
        dr = r(2)-r(1);
        %tt = NaN(size(dataout_log,2),1);
        t = [data.(chan{ch}).vars.timestamp];
        depth = [data.(chan{ch}).vars.depth]';
        if t(1,1) > 1e15 %format is epoch millisecs (flyer timestamp), convert to serial time
            t = datetime(t,"ConvertFrom","epochtime",'TicksPerSecond',1e6);
        else
            t = datetime(t,"ConvertFrom","datenum");
        end
        %datetime([data.(chan{ch}).time],"ConvertFrom","datenum");
        dataflag = [];
    end
if size(r,1) == 1
    r = r';
end
dataout_lin = 10.^(dataout_log/10);
out.Time = t';
%% Echostatistics Metric Calc 
% Add payload depth if EK80
if strcmp(trans,'EK80')
    out.depth = depth;
end

% Abundance / depth_integral (Sa)
integral = nansum(dataout_lin,1)*dr;
integral = 10*log10(integral);
integral(isinf(integral)) = NaN;
integral(integral<-900) = NaN;
out.Sa = integral';

% Density / sv_avg (MVBS)
avg = nanmean(dataout_lin);
avg = 10*log10(avg);
avg(isinf(avg)) = NaN;
avg(avg<-900) = NaN;
out.MVBS = avg';

% Location / Center of Mass (COM)
com = (nansum(dataout_lin.*r,1)) ./ (nansum(dataout_lin,1));
out.COM = com';

% Inertia / Spread or dispersion around center of mass
diff = (repmat(r,1,size(dataout_lin,2)) - com);
inertia = nansum((diff.^2).*dataout_lin,1) ./ (nansum(dataout_lin,1));
out.Inertia = inertia';

% Evenness / Equivalent Area
EA = (nansum(dataout_lin*dr,1).^2) ./ (nansum(dataout_lin.^2,1)*dr);
out.EA = EA';

% Aggregation / Index of aggregation
IA = (nansum(dataout_lin.^2,1)*dr) ./  (nansum(dataout_lin*dr,1).^2);
out.IA = IA';

% Proportion of area within threshold
mask_idx =  dataout_log > thres1 & dataout_log < thres2;
PA = nansum(mask_idx,1) / length(r);
out.PA = PA';
%% Append Tabel
tb1 = struct2table(out);
tb = table2timetable(tb1);
%% Cross-correlation between depth and Sa
% igtr_nrm = (integral - mean(integral))/std(integral);
% depth_nrm = (depth - mean(depth))/std(depth);
% depth_nrm = -1*depth_nrm;
% igtr_nrm2 = integral/max(integral);
% depth_nrm2 = depth/max(depth);
% plot(tb1.Time,depth_nrm2,tb1.Time,igtr_nrm2);
% plot(tb1.Time,depth_nrm,tb1.Time,igtr_nrm);
% [corr_values, lags] = xcorr(depth_nrm, igtr_nrm);
% [corr_values, lags] = xcorr(-1*depth, integral,'normalized');
% %[max_corr, max_corr_idx] = max(corr_values);
% [max_corr, max_corr_index] = max(abs(corr_values));
% lag_at_max_corr = lags(max_corr_index);
% 
% disp(['Magnitude of correlation: ', num2str(max_corr)]);
% disp(['Maximum correlation at lag ', num2str(lag_at_max_corr)]);
% figure;
% stem(lags, corr_values);
% xlabel('Lag');
% ylabel('Cross-correlation');
% title('Cross-correlation between the signals');
%% Get indexes for every event
% Chop events that are outside data
event_idx = event_dn > min(t) & event_dn < max(t);
event_dn = event_dn(event_idx);

if ~isempty(eventdn)
    event_dnum = datenum(event_dn);
    t_dnum = datenum(t);
    idx_evt = dsearchn(t_dnum',event_dnum);
    evt(:,1) = idx_evt;
    evt(1:end-1,2) = idx_evt(2:end)-1;
    evt(end,2) = length(t);
end

sa_45_1 = table2array(tb1(evt(1,1):evt(1,2),2));
sa_5_2 = table2array(tb1(evt(2,1):evt(2,2),2));
sa_45_3 = table2array(tb1(evt(3,1):evt(3,2),2));
sa_0_4 = table2array(tb1(evt(4,1):evt(4,2),2));
sa_45_5 = table2array(tb1(evt(5,1):evt(5,2),2));

COM_45_1 = table2array(tb1(evt(1,1):evt(1,2),4));
COM_5_2 = table2array(tb1(evt(2,1):evt(2,2),4));
COM_45_3 = table2array(tb1(evt(3,1):evt(3,2),4));
COM_0_4 = table2array(tb1(evt(4,1):evt(4,2),4));
COM_45_5 = table2array(tb1(evt(5,1):evt(5,2),4));
% h1 = swtest(grp1)
% h2 = swtest(grp2) %not normal
% h3 = swtest(grp3) %not normal
% h4 = swtest(grp4)
% h5 = swtest(grp5)
%x = [grp1; grp2; grp3; grp4; grp5];
%% COM Stats and fig
% Moving average
com(com > 49.7 & com < 50) = NaN;
com_avg = movmean(com,10);
nan_idx = ~isnan(com_avg);
com_avg = com_avg(nan_idx);
t_com = t(1:length(com_avg));

xlim([1 length(com)]);
[X_reg,Y_reg,Rsq,~,~] = regress_fit(1:length(com_avg), com(1:length(com_avg)));
hold on
plot(1:length(com_avg),com_avg,'k','LineWidth',2)
for i = 2:length(event_dn)
    plot([evt(i) evt(i)],[min(com) max(com)],'-.','LineWidth',1,'Color','#583D3D')
end
xticks([1; evt(2:end,1); length(com)]);
xticklabels([datestr([event_dn; max(t)],'HH:MM:SS')]);
h=get(gca,'Children');
uistack(h(7),'up',2); %moves polyfit a level higher
legend("95% CI", "COM", "COM moving avg", "polyfit 10th-deg", "LI-Block")
xlabel(['Time (UTC)']);
ylabel(['Depth (m)']);

%% Inertia Stats and fig
% Moving average
inertia_avg = movmean(inertia,10);
nan_idx = ~isnan(inertia_avg);
inertia_avg = inertia_avg(nan_idx);
t_com = t(1:length(inertia_avg));

[X_reg,Y_reg,Rsq,~,~] = regress_fit(1:length(inertia_avg), inertia(1:length(inertia_avg)));
xlim([1 length(inertia)]);
hold on
plot(1:length(inertia_avg),inertia_avg,'k','LineWidth',2)
for i = 2:length(event_dn)
    plot([evt(i) evt(i)],[min(inertia) max(inertia)],'-.','LineWidth',1,'Color','#583D3D')
end
xticks([1; evt(2:end,1); length(inertia)]);
xticklabels([datestr([event_dn; max(t)],'HH:MM:SS')]);
h=get(gca,'Children');
uistack(h(7),'up',2); %moves polyfit a level higher
legend("95% CI", "inertia", "inertia moving avg", "polyfit 10th-deg", "LI-Block")
xlabel(['Time (UTC)']);
ylabel(['Inertia (m^-2)']);

%% Sa Stats and fig
integral_avg = movmean(integral,10);
nan_idx = ~isnan(integral_avg);
integral_avg = integral_avg(nan_idx);
t_com = t(1:length(integral_avg));

[X_reg,Y_reg,Rsq,~,~] = regress_fit(1:length(integral_avg), integral(1:length(integral_avg)));
xlim([1 length(integral)]);
hold on
plot(1:length(integral_avg),integral_avg,'k','LineWidth',2)
for i = 2:length(event_dn)
    plot([evt(i) evt(i)],[min(integral) max(integral)],'-.','LineWidth',1,'Color','#583D3D')
end
xticks([1; evt(2:end,1); length(integral)]);
xticklabels([datestr([event_dn; max(t)],'HH:MM:SS')]);
h=get(gca,'Children');
uistack(h(7),'up',2); %moves polyfit a level higher
legend("95% CI", "Sa", "Sa moving avg", "polyfit 10th-deg", "LI-Block")
xlabel(['Time (UTC)']);
ylabel(['Sa (dB re 1m^-2 m^-3)']);

%% To be saved for processing in R
Y_reg_res = NaN(1,length(com));
Y_reg_res(1:length(X_reg)) = Y_reg;
%
groups = {sa_45_1, sa_5_2, sa_45_3, sa_0_4, sa_45_5};
groups = {COM_45_1, COM_5_2, COM_45_3, COM_0_4, COM_45_5};
max_dim = max(cellfun(@length, groups));
Ycombined_com = NaN(max_dim,5);
for i = 1:numel(groups)
    Ycombined_com(1:length(groups{i}), i) = groups{i};
end

filename = 'E:\2023_Bermuda\processed\Dive3_combined_grp_com.csv';
writematrix(Ycombined_com, filename); % Write the data to a CSV file
%% Misc Stats test in Matlab
% lht_on = [sa_45_1;sa_45_3;sa_45_3];
% lht_off = [sa_5_2;sa_0_4];
% xx = [lht_on; lht_off];
% g1 = repmat({'Lights on 45%: t0'},length(grp1),1);
% g2 = repmat({'Lights on 5%: t1'},length(grp2),1);
% g3 = repmat({'Lights on 45%: t2'},length(grp3),1);
% g4 = repmat({'Lights on 0%: t3'},length(grp4),1);
% g5 = repmat({'Lights on 45%: t4'},length(grp5),1);
% g = [g1; g2; g3; g4; g5];
% g11 = repmat({'lights on'},length(lht_on),1);
% g22 = repmat({'lights off'},length(lht_off),1);
% gg = [g11; g22];
% boxplot(xx,gg)
% boxplot(x,g)
% 
% [p,h] = ranksum(lht_on, lht_off)
% [p,tb_st,stats_kr] = kruskalwallis(Ycombined);
% [c,m] = multcompare(stats_kr,"CriticalValueType","hsd");
% tbl1 = array2table(c,"VariableNames", ...
%     ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"])

% [p,stats] = mackskill(Ycombined,1);
% [row light_group backscatter] = find(sparse(Ycombined)); 
% lab = ceil(row/565);  % 3, since there are 3 repetitions
% response = backscatter; treatment = lab; block = enrichment;
% [p stats] = mackskill(response,treatment,block)
%% Figure
%calculating subplot indexes
%tb1 = tb1(:,1:8);
n_param = size(tb1,2)-1;
sp_size = 3+n_param; %2+n_param;
sp_idx = [10:1:(10+2*n_param+n_param-1)]; %[7:1:(7+2*n_param+n_param-1)]

%plotting the figure
fig2 = figure(); %set(fig2,'visible','on','PaperPositionMode','auto','PaperPosition',[0 0 20 10]);
subplot(sp_size,3,1:9); %subplot(sp_size,3,1:6);
imagesc(tb.Time,r,dataout_log,[-77 -37])
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
ylim([0 500]);
xlim([min(t) max(t)]);
xticks(t(1):minutes(5):t(end))
axis tight; 
set(gca,'Xtick',[],'FontSize',16,'LineWidth',1);

if plotevt == 1
    hold on
    for i = 1:length(event_dn)
        plot([event_dn(i) event_dn(i)],[r(1) r(end)],'--k','LineWidth',2)
    end
    X = tb1.Time;
    Y = tb1.COM;
    plot(X,Y,'k','LineWidth',2)
    %plot(X,Y_reg_res,"magenta",'LineWidth',2)
    hold off
end

j = 1;
for i = 1:3:length(sp_idx)
    subplot(sp_size,3,sp_idx(i):sp_idx(i)+2);
    X = tb1(:,1).Variables;
    Y = tb1(:,1+j).Variables;
    %vname = string(tb1(:,1+j).Properties.VariableNames);
    plot(X,Y)
    axis tight; grid on;
    xlim([min(t) max(t)]);
    lbl = char(tb1(:,1+j).Properties.VariableNames);
    if ~strcmp(lbl,'depth')
        set(gca,'FontSize',16,'LineWidth',1);
    else
        set(gca,'FontSize',16,'LineWidth',1,'YDir','reverse');
    end
    ylabel(lbl);
    if plotevt == 1
        hold on
        for ii = 1:length(event_dn)
            plot([event_dn(ii) event_dn(ii)],[min(Y) max(Y)],'--k','LineWidth',2)
        end
        hold off
    end
    if j < n_param
        h = gca;
        h.XAxis.Visible = 'off';
        xticks(min(X):minutes(5):max(X))
        %set(gca,'Xtick',[]);
        j = j+1;
    else
        hold off;
        xlabel('Time (UTC)');
        xtickformat("HH:mm")
        xticks(min(X):minutes(5):max(X))
        xtickangle(20)
    end
end

% if strcmp(trans,'EK80')
%     hold on        
%     plot(tb.Time,depth,)
% end


% subplot(8,3,10:12);
% plot(tb.Time,tb.MVBS)
% axis tight
% xlim([min(t) max(t)])

%% Second figure
%fig1

figure(); %set(fig2,'visible','on','PaperPositionMode','auto','PaperPosition',[0 0 20 10]);
imagesc(tb.Time,r,dataout_log,[-77 -37])
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
ylim([0 500]);
xlim([min(t) max(t)]);
xticks(t(1):minutes(5):t(end))
ylabel('Depth (m)');
axis tight;
set(gca,'Xtick',[],'FontSize',13,'LineWidth',1);
hold on
for i = 1:length(event_dn)
    plot([event_dn(i) event_dn(i)],[r(1) r(end)],'-.k','LineWidth',2)
end

%fig 2
regress_fit(1:length(com_avg), com(1:length(com_avg)));
xlim([1 length(com)]);
hold on
plot(1:length(com_avg),com_avg,'k','LineWidth',2)
for i = 1:length(event_dn)
    plot([evt(i) evt(i)],[min(com) max(com)],'-.','LineWidth',1,'Color','#583D3D')
end
xticks([1; evt(2:end,1); length(com)]);
xticklabels([datestr([event_dn; t(end)],'HH:MM:SS')]);
h=get(gca,'Children');
uistack(h(7),'up',2); %moves polyfit a level higher
legend("95% CI", "COM", "COM moving avg", "polyfit 10th-deg", "LI-Block")
%xlabel(['Time (UTC)']);
ylabel(['Depth (m)']);
set(gca,'FontSize',16,"YDir","reverse");
set(gca,'Xtick',[],'FontSize',16);
%set(gca,'Xtick',[],'FontSize',14,'LineWidth',1);

%fig 3
[X_reg,Y_reg,Rsq,~,~] = regress_fit(1:length(inertia_avg), inertia(1:length(inertia_avg)));
xlim([1 length(inertia)]);
hold on
plot(1:length(inertia_avg),inertia_avg,'k','LineWidth',2)
for i = 1:length(event_dn)
    plot([evt(i) evt(i)],[min(inertia) max(inertia)],'-.','LineWidth',1,'Color','#583D3D')
end
xticks([1; evt(2:end,1); length(inertia)]);
xticklabels([datestr([event_dn; t(end)],'HH:MM:SS')]);
h=get(gca,'Children');
uistack(h(7),'up',2); %moves polyfit a level higher
legend("95% CI", "inertia", "inertia moving avg", "polyfit 10th-deg", "LI-Block")
xlabel(['Time (UTC)']);
ylabel(['Inertia (m^-^2)']);
set(gca,'FontSize',16);

%Combining all
figlist=get(groot,'Children');
%figlist = sort(figlist);
newfig=figure;
tcl=tiledlayout(newfig,"vertical");
tcl.TileSpacing = 'tight';

figure(figlist(3));
ax=gca;
ax.Parent=tcl;
ax.Layout.Tile=1;
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
%ylim([0 100]);
%xlim([min(t) max(t)]);
%xticks(t(1):minutes(5):t(end))
set(gca,'Xtick',[],'FontSize',14,'LineWidth',1);

figure(figlist(1));
ax=gca;
ax.Parent=tcl;
ax.Layout.Tile=3;
set(gca,'FontSize',14,'LineWidth',1);

figure(figlist(2));
ax=gca;
ax.Parent=tcl;
ax.Layout.Tile=2;
set(gca,'Xtick',[],'FontSize',14,'LineWidth',1);


end

end