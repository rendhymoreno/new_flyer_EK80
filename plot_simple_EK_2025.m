function plot_simple_EK_2025(x,y,c,h_int,ftype,y_limits)

if strcmp(ftype,'seperate')
    figure('Position',[71   352   976   610]);
end

if isempty(y_limits)
    y_limits = [0 1000];
end

%f1 = figure('Position',[71   352   976   610],'Visible','off');
imagesc(x,y,c)
ax1 = gca;
cek = cptcmap('EK60_2.cpt'); cek(1,:) = [1 1 1]; colormap(ax1,cek);
axis tight; shading flat;
clim([-100 -50]); ylim([y_limits(1) y_limits(2)]);
cb1 = colorbar(ax1);
xtick_n = dateshift(x(1),"start","hour"):hours(h_int):dateshift(x(end),"end","hour");
set(gca,"FontWeight","bold","FontSize",10,'XTick',xtick_n);
xtickformat('HH:mm');
xlabel('Time (UTC)'); ylabel('Depth (m)'); cb1.Label.String = 'Sv dB re m^-1'; cb1.Label.Interpreter = 'none';
%outfn = fname(1:end-4);
%exportgraphics(gca,[outfn '.png'],'Resolution',300);
%ytickformat('d-MMM-yy')
%xsecondarylabel('Visible','off');

end