function examples(example_id)
	
	% Run example: examples(1);
	
	rng(0);
	figure('WindowState','Maximized');
	ax = gca;
	colormap(ax,'lines');
	hold(ax,'on');
	
	switch(example_id)
		case 1 % Bar plot - one group.
			Title = 'Bar - One Group';
			
			M = rand(5,1);
			H = bar(ax,M);
			X = cat(1,H(:).XEndPoints);
			Y = cat(1,H(:).YEndPoints);
			
			errorbar(ax,X',Y',0.05.*rand(size(X')),'Color','k','LineWidth',1.5,'LineStyle','none');
			
			set(ax,'FontSize',16); xlabel('Category'); ylabel('Count'); grid on; drawnow;
			
			stats = zeros(size(M,1),size(M,1),size(M,2),size(M,2));
			stats(2,5,1,1) = 1;
			stats(1,3,1,1) = 2;
			stats(4,5,1,1) = 3;
			stats(3,3,1,1) = 4;
			[stats_Y,stats_X1,stats_X2] = Plot_Stats(ax,stats);
			
			xlim([0.5,5.5]);
		case 2 % Patch (''hist'') - One Group.
			
			Title = 'Patch (''hist'') - One Group';
			
			M = transpose(normpdf(1:20,10,3)); % Create a normal distribution.
			
			H = bar(ax,M,'hist');
			X = squeeze(mean(cat(3,H(:).XData),1))';
			Y = squeeze(max(cat(3,H(:).YData),[],1))';
			
			errorbar(ax,X',Y',min([Y' ; 0.01.*rand(size(X'))]),'Color','k','LineWidth',1.5,'LineStyle','none');
			
			set(ax,'FontSize',16); xlabel('Category'); ylabel('Count'); grid on; drawnow;
			
			stats = zeros(size(M,1),size(M,1),size(M,2),size(M,2));
			stats(2,5,1,1) = 1;
			stats(1,10,1,1) = 2;
			stats(6,8,1,1) = 3;
			stats(4,7,1,1) = 4;
			stats(15,18,1,1) = 2;
			stats(17,18,1,1) = 1;
			stats(12,19,1,1) = 3;
			[stats_Y,stats_X1,stats_X2] = Plot_Stats(ax,stats);
			
			xlim([0.5,size(M,1)+0.5]);
		case 3 % Bar - multiple groups.
			
			Title = 'Bar - Multiple Groups';
			
			M = rand(5,4);
			H = bar(ax,M,'BarWidth',1);
			X = cat(1,H(:).XEndPoints);
			Y = cat(1,H(:).YEndPoints);
			hold on;
			errorbar(ax,X',Y',0.05.*rand(size(X')),'Color','k','LineWidth',1.5,'LineStyle','none');
			
			set(ax,'FontSize',16); xlabel('Category'); ylabel('Count'); grid on; drawnow;
			
			stats = zeros(size(M,1),size(M,1),size(M,2),size(M,2));
			stats(2,5,1,1) = 1;
			stats(1,3,1,2) = 2;
			stats(4,5,2,2) = 3;
			stats(3,3,1,3) = 4;
			stats(1,1,2,3) = 1;
			[stats_Y,stats_X1,stats_X2] = Plot_Stats(ax,stats);
			
		case 4 % Patch ('hist') - Multiple Groups.
			
			Title = 'Patch (''hist'') - Multiple Groups';
			
			M = rand(5,4);
			H = bar(ax,M,'hist');
			X = squeeze(mean(cat(3,H(:).XData),1))';
			Y = squeeze(max(cat(3,H(:).YData),[],1))';
			hold on;
			errorbar(ax,X',Y',0.05.*rand(size(X')),'Color','k','LineWidth',1.5,'LineStyle','none');
			
			set(ax,'FontSize',16); xlabel('Category'); ylabel('Count'); grid on; drawnow;
			
			stats = zeros(size(M,1),size(M,1),size(M,2),size(M,2));
			stats(2,5,1,1) = 1;
			stats(1,3,1,2) = 2;
			stats(4,5,2,2) = 3;
			stats(3,3,1,3) = 4;
			stats(1,1,2,3) = 1;
			[stats_Y,stats_X1,stats_X2] = Plot_Stats(ax,stats);
			
		case 5 % Patch (''hist'') - Negative Values.
			
			Title = 'Patch (''hist'') - Negative Values';
			
			M(:,:,1) = rand(5,4);
			M(:,:,2) = -rand(5,4);
			
			H = bar(ax,M(:,:,1),'hist');
			hold(ax,'on');
			H1 = bar(ax,M(:,:,2),'hist');
			
			X1 = squeeze(mean(cat(3,H(:).XData),1))';
			Y1 = squeeze(max(cat(3,H(:).YData),[],1))';
			X2 = squeeze(mean(cat(3,H1(:).XData),1))';
			Y2 = squeeze(min(cat(3,H1(:).YData),[],1))';
			
			errorbar(ax,X1',Y1',0.05.*rand(size(X1')),'Color','k','LineWidth',1.5,'LineStyle','none');
			errorbar(ax,X2',Y2',0.05.*rand(size(X2')),'Color','k','LineWidth',1.5,'LineStyle','none');
			
			set(ax,'FontSize',16); xlabel('Category'); ylabel('Count'); grid on; drawnow;
			
			ylim(ax,[-1.5,1.5]); hold(ax,'on');
			
			stats = zeros(size(M,1),size(M,1),size(M,2),size(M,2));
			stats(2,5,1,1) = 1;
			stats(1,3,1,2) = 2;
			stats(4,5,2,2) = 3;
			stats(3,3,1,3) = 4;
			stats(1,1,2,3) = 1;
			[stats_Y_1,stats_X1_1,stats_X2_1] = Plot_Stats(ax,stats,H);
			
			stats = zeros(size(M,1),size(M,1),size(M,2),size(M,2));
			stats(2,5,1,1) = 1;
			stats(1,3,1,2) = 2;
			stats(4,5,2,2) = 3;
			stats(3,3,1,3) = 4;
			[stats_Y_2,stats_X1_1,stats_X2_1] = Plot_Stats(ax,stats,H1);
			
			stats_Y = [stats_Y_1(:) ; stats_Y_2(:)]; % This is only used for setting ylim.
	end
	
	set(ax,'XTick',1:size(M,1));
	ylim(ax,1.05 .* [min([0;stats_Y(:)]),max(stats_Y(:))]);
	title(Title);
	legend(H,join([repmat("Group ",size(M,2),1),string((1:size(M,2))')]),'Location','Northeast');
end