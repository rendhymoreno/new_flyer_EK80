es60out{1} = 'E:\2023_MSET\processed\08102023_mset.mat'; %ES60 file output struct
es60out{2} = 'E:\2023_MSET\processed\09102023_mset.mat'; %ES60 file output struct
es60out{3} = 'E:\2023_MSET\processed\10102023_mset.mat'; %ES60 file output struct
es60out{4} = 'E:\2023_MSET\processed\11102023_mset.mat'; %ES60 file output struct
es60out{5} = 'E:\2023_MSET\processed\12102023_mset.mat'; %ES60 file output struct
plt_out = 'E:\2023_MSET\processed\plot_Brennan\';
fnext = 'longES60';

for i = 1:5
    svES60 = load(es60out{i}); %load ES60 Sv data
    svES60 = fix_ES60_timestamp(svES60); %remove odd timestamps
    svES60 = chop_EK60(svES60,[0 500],[]);
    svES60 = impulse_noise_filter(svES60,'ES60',1,60,2,10,100,500,'NaN',1,[]);
    svES60 = background_noise_remove_RMS(svES60,'ES60',1,50,20,-127,0.1,[]);
    svES60 = threshold(svES60,'ES60',1,-125,-50,'tvt',[]);
    svES60 = residual_noise_filter(svES60,'ES60',1,250,500,3,[]); %Too Harsh
    %svES60 = resample_weighted_mean(svES60, 'ES60', 1, 50, 1, []);
    dt = datetime(svES60.ch1_38.time,"ConvertFrom","datenum");
    stname = sprintf('data%i',i);
    ES60.(stname) = svES60.ch1_38;
    ES60.(stname).time2 = dt;
    fprintf('File %i out of 5 has been completed\n',i)   
end
clear('svES60')
range = ES60.data1.range;

fig2 = figure(); set(fig2,'visible','on','PaperPositionMode','auto','PaperPosition',[0 0 20 10]);
imagesc(ES60.data1.time2, range, ES60.data1.Sv, [-77 -36]);
hold on;
imagesc(ES60.data2.time2, range, ES60.data2.Sv, [-77 -36]);
imagesc(ES60.data3.time2, range, ES60.data3.Sv, [-77 -36]);
imagesc(ES60.data4.time2, range, ES60.data4.Sv, [-77 -36]);
imagesc(ES60.data5.time2, range, ES60.data5.Sv, [-77 -36]);
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
axis tight; shading flat;
xticks('auto');yticks('auto');colorbar;
%dynamicDateTicks();
%setDateAxes(gca, 'XLim', [ES60.data1.time(1) max(ES60.data5.time)]);
set(gca,'FontSize',20);
title('ES60 38kHz: Oct 8-13 2023')
ylabel(colorbar,'Sv (db re 1 m^{-1})','FontSize',20,'Rotation',270);
xlabel('Time (UTC)')
ylabel('Depth (m)')
ylim([0 400]);
xtickangle(20);
fig2.Color = 'w';
export_fig(append(plt_out,fnext),'-bmp','-nocrop');




