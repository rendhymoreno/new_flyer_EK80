function [stats_Y,stats_X1,stats_X2] = plot_stats(ax,stats,H)
	
	% This function adds statistical significance lines and asterisks to an existing plot.
	% Input arguments:
		% ax: handle of the axis containing the bar plot.
		% stats: a 4D matrix containing the number of stars for each possible pair.
			% stats(c1,c2,g1,g2) contains the # of stars for the comparison between bar c1 in group g1 and bar c2 in group g2.
		% H is a handle to a specific plot within ax. It should be used in case there are multiple plots within the same axis object.
	% Output arguments:
		% stats_Y,stats_X1,stats_X2 are matrices the same size as stats, and contain the y-value and x-values of each significance line (respectively).
	
	dy = 0.1 .* ax.YLim(2); % sum(abs(ax.YLim)); % Distance between significance bars.
	y_star = 0.1*dy; % Distance of stars from their significance bar.
	Star_Font_Size = 20;
	pval_Font_Size = 12;
	s = 1; % Default sign for y-data.
	MaxMin_Func = @(x) nanmax(x,[],1);
	txt_align = 'bottom';
	
	% Find x and y positions of the bars:
	if(nargin < 3 || isempty(H) || any(~ishandle(H)))
		H = findall(ax.Children,'Type','bar','-or','Type','patch'); % Find all bar/patch objects.
		H = flipud(H(:)); % The order of the objects is reversed in order to have the left-most group as the first.
	end
	
	if(nanmean([H(:).YData],'all') < 0)
		s = -1;
		dy = -dy;
		y_star = -3.5 * y_star;
		MaxMin_Func = @(x) nanmin(x,[],1);
	end
	
	switch(H(1).Type)
		case 'bar'
			X = cat(1,H(:).XEndPoints);
			Y = cat(1,H(:).YEndPoints);
		case 'patch'	
			X = squeeze(mean(cat(3,H(:).XData),1))';
			Y = squeeze(MaxMin_Func(cat(3,H(:).YData)))';
	end
	
	% Make sure rows of X & Y correspond to group, and columns to categories:
	if(size(X,2) ~= size(stats,1) || size(X,1) ~= size(stats,3))
		X = transpose(X);
		Y = transpose(Y);
	end
	
	% If error bars exist, change the y-values to the upper limit of the error bar:
	He = findall(ax.Children,'Type','ErrorBar'); % Find all error-bar objects.
	
	% Match error bars with data series (in case there are more error bars than bars):
	h = false(1,length(He));
	for i=1:length(He)
		
		Ye = He(i).YData;
		
		if(size(Ye,2) ~= size(stats,1))
			Ye = transpose(Ye);
		end
		
		if(any(ismember(Y,Ye,'rows')))
			h(i) = 1;
		end
	end
	He = He(h);
	
	if(~isempty(He))
		He = flipud(He(:)); % The order of the objects is reversed in order to have the left-most group as the first.
		
		if(s == 1)
			Ye = cat(1,He(:).YPositiveDelta);
		else
			Ye = cat(1,He(:).YNegativeDelta);
		end
		
		if(size(Ye,2) ~= size(stats,1) || size(Ye,1) ~= size(stats,3))
			Ye = transpose(Ye);
		end
		
		Y = Y + s.*Ye;
	end
	
	stats_Y = nan(size(stats)); % Set the y-value for each pair (or nan if there isn't any).
	stats_X1 = nan(size(stats)); % Set the first x-value for each pair (or nan if there isn't any).
	stats_X2 = nan(size(stats)); % Set the second x-value for each pair (or nan if there isn't any).
	
	for m=0:size(Y,2)-1 % Starting from pairs within the same category (m=0), then pairs in neighboring categories (m=1), etc.
		for c1=1:size(X,2)
			for c2=1:size(X,2)
				for g1=1:size(X,1)
					for g2=1:size(X,1)
						if(stats(c1,c2,g1,g2) > 0) % If a positive number of stars.
							if((c2-c1) == m)
								if(c1 == c2 && g1 ~= g2) % Pairs within the same category are treated differently.									
									V1 = squeeze(stats_Y(c1,c1,g1:g2,g1:g2)); % The bars for x-value of c1=c2, groups g1:g2.
									V2 = Y(g1:g2,c1); % The bars for x-value of c1=c2, groups g1:g2.
									
									stats_Y(c1,c1,g1,g2) = MaxMin_Func([V1(:) ; V2(:) ; Y(g1,c1) ; Y(g2,c1)]) + dy; % Add dy to the maximum of any y-value of these bars (bar, error-bar or significance bar).
									stats_X1(c1,c1,g1,g2) = X(g1,c1);
									stats_X2(c1,c1,g1,g2) = X(g2,c1);
								elseif(c1 ~= c2)
									
									V11 = squeeze(stats_Y(c1,:,g1:end,:)); % The bars for category c1, groups g1:end.
									V12 = squeeze(stats_Y(:,c1,:,g1:end)); % ".
									
									V21 = squeeze(stats_Y(:,c2,:,1:g2)); % The bars for category c2, groups 1:g2.
									V22 = squeeze(stats_Y(c2,:,1:g2,:)); % ".
									
									V31 = squeeze(stats_Y(c1+1:c2-1,:,:,:)); % All bars in between categories c1 and c2.
									V32 = squeeze(stats_Y(:,c1+1:c2-1,:,:)); % All bars in between categories c1 and c2.
									
									V13 = Y(g1:end,c1); % The bars for category c1, groups g1:end.
									V23 = Y(1:g2,c2); % The bars for category c2, groups 1:g2.
									V33 = Y(:,c1+1:c2-1); % All bars in between categories c1 and c2.
									
									V = MaxMin_Func([V11(:) ; V12(:) ; V13(:) ; V21(:) ; V22(:) ; V23(:) ; V31(:) ; V32(:) ; V33(:)]);
									
									stats_Y(c1,c2,g1,g2) = MaxMin_Func([V ; Y(g1,c1) ; Y(g2,c2)]) + dy; % Add dy to the maximum of any y-value of these bars (bar, error-bar or significance bar).
									stats_X1(c1,c2,g1,g2) = X(g1,c1);
									stats_X2(c1,c2,g1,g2) = X(g2,c2);
								end
							end
						end
					end
				end
			end
		end
	end
	
	hold(ax,'on');
	for i=1:numel(stats_Y)
		if(~isnan(stats_Y(i))) % If not NaN, plot the significance bar and the stars.
			x1 = stats_X1(i);
			x2 = stats_X2(i);
			y = stats_Y(i);
			Ns = stats(i); % # of stars.
			
			plot(ax,[x1,x2],[y,y],'k','LineWidth',1.5);
			
			if(Ns >= 1 && mod(Ns,1) == 0) % If a whole number >= 1, treat as the number of asterisks.
				text(ax,mean([x1,x2]),y+y_star,repmat('*',1,Ns),'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',Star_Font_Size,'LineStyle','-');
			else % Treat as p-value.
				text(ax,mean([x1,x2]),y+2*y_star,num2str(Ns),'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',pval_Font_Size);
			end
		end
	end
	
end