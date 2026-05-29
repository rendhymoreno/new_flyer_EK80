%% mapping

%m_proj('UTM','long',[-64.89925 -64.526226],'lat',[32.22416 32.41596]);
% m_proj('utm','ellipse','grs80','zone',20,'lat',[32.233333 32.41596],...
%         'long',[-64.866667 -64.533333]); %-64.89925 -64.526226
m_proj('equidistant','lon',[-64.866667 -64.533333],'lat',[32.233333 32.41596]);
[CS,CH]=m_etopo2('contourf',[-3000:50:0],'edgecolor','none');
m_gshhs_h('patch',[.7 .7 .7],'edgecolor','none');
h1=m_line(-64.5665,32.318117,'marker','pentagram','color','r',...
          'linest','none','markerfacecolor','w','markersize',15,'markerfacecolor','w');
h4=m_line(-64.57542,32.31771,'marker','pentagram','color','r',...
          'linest','none','markerfacecolor','w','markersize',15,'markerfacecolor','w');
h2=m_line(-64.69638638115583,32.37099315190752,'marker','square','color','r',...%32.37099315190752, -64.69638638115583
          'linest','none','markerfacecolor','w','markersize',8,'markerfacecolor','black');
h3=m_line(-64.78413000211023,32.295039665145374,'marker','square','color','r',...%32.295039665145374, -64.78413000211023
          'linest','none','markerfacecolor','w','markersize',8,'markerfacecolor','black');
m_grid('linest','none','tickdir','out','box','fancy','fontsize',16);
%m_grid('tickdir','out','fontsize',12,'linest','none','xaxisloc','top','yaxisloc','right');
%m_utmgrid('xcolor','b','ycolor','b','linest','-'); 

colormap(m_colmap('water',128));  
%set(gca,'Color','w')
caxis([-3000 000]);
[ax,h]=m_contfbar([0.06 0.32],0.6,CS,CH,'endpiece','no','axfrac',0.01,'FontSize',13);
%ax.XTickLabel = flipud(ax.XTickLabel);
 %[.55 .75]
%xlabel(ax,'meters','color','k','FontSize',13);
m_ruler([.06 .36],.9,'tickdir','out','ticklen',[.007 .007],'FontSize',13);
%set(gca,'Color','w')

%title(ax,'meters')