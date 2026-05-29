%% Remove -999 and convert into NaN
% svNaN = svES60_filt.ch1_38.Sv;
% svNaN(svNaN==-999) = NaN;
% svES60_filt_NaN = svES60_filt;
% svES60_filt_NaN.ch1_38.Sv = svNaN;
% vect_es60_38_nan = ES60_XYZC_Vector(svES60_filt_NaN.ch1_38);
% export_pointcloud(vect_es60_38_nan, 'E:\2023_MSET\processed\Oct52023\','es60_38k_100523_NaNs');

%pc_ES60.Intensity(isnan(pc_ES60.Intensity)) = -999;
pc_EK80.Intensity(pc_EK80.Intensity == -999) = NaN; %EK80 still a lot of white spaces!

%% Check for distribution
svES60_val = svES60_filt.ch1_38.Sv;
svES60_val(svES60_val==-999) = NaN;
edges = [-125:1:-50];
histogram(svES60_val(:,2),edges)

plotEk_Echogram_Niskin(svEK80,1,[],[],{0 'inf'},[],[-77 -36],'Original',[])
svEK80_val = svEK80.chan70.val;
svEK80_val(svEK80_val==-999) = NaN;
met = 'avg';
if strcmp(met,'avg')
    avgping = mean(svEK80_val,1,"omitmissing");
    disp('metric is mean')
elseif strcmp(met,'max')
    avgping = max(svEK80_val,[],1);
    disp('metric is max')
elseif strcmp(met,'med')
    avgping = median(svEK80_val,1,"omitmissing");
    disp('metric is median')
end

svEK80_comp = svEK80;
svEK80_comp.chan70.range = svEK80.chan70.range(1);
svEK80_comp.chan70.val = avgping;
svEK80_comp = threshold_backscatter(svEK80_comp,'EK80',1,-77,-36,[],[]);  %50 thres too hard
vect_ek80_70_comp = get_time_vectors(svEK80_comp.chan70,'2D'); %Time vectors is adapted for both dimensions
export_pointcloud(vect_ek80_70_comp, 'E:\2023_MSET\processed\Oct92023\','ek80_70k_100923_compAVG_t');
disp('Converted to pointcloud')

%% pointcloud load and plot
%pc_EK80 = pcread('E:\2023_MSET\processed\Oct52023\ek80_70k_100523_compMED_t.ply');
pc_EK80 = pcread('E:\2023_MSET\processed\Oct92023\ek80_70k_100923_compAVG_t.ply');
pc_ES60 = pcread('E:\2023_MSET\processed\Oct52023\es60_38k_100523_filt_nosync.ply');

f = figure('WindowState', 'maximized');
ax1 = axes;
ax1 = pcshow(pc_EK80, ColorSource="Intensity");
dynamicDateTicks();
setDateAxes(gca, 'XLim', [min(pc_EK80.Location(:,1)) max(pc_EK80.Location(:,1))]);
caxis([-77 -36]);
zlim([0 500]);
ylim([0 98])
set(ax1,'XDir','reverse','ZDir','reverse');
xlabel(ax1,'Time (UTC)','FontSize',14);
ylabel(ax1,'EK80 horizontal range (m)','FontSize',14);
%ylabel(ax1,'EK80 horizontal range (m)','FontSize',14,'Rotation',-30,'Position',[-226,46,536]);
zlabel(ax1,'flyer depth (m)','FontSize',14);
ax1.FontSize = 14;
ax1.DataAspectRatio = [0.5*diff(ax1.XLim), 2*diff(ax1.YLim), diff(ax1.ZLim)] / diff(ax1.YLim);
view(180,0)
cptcmap('EK60_2',ax1')

[f2,ax1,ax2,cb] = plot3d_pc(pc_ES60,pc_EK80,[-77 -36],[-77 -36],[0 0.0001],[0 500],[170 0],[]);
cam_3D_change(ax1,ax2,170,1);