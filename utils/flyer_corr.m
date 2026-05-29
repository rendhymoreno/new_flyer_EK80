function crr_out = flyer_corr(x,y,c1,c2)

j_win = [(1:length(y))-3; (1:length(y)); (1:length(y))+3]';
j_win((j_win(:,1) < 1),1) = 1;
j_win((j_win(:,3) > length(y)),3) = length(y);
i_win = [(1:length(x))-3; (1:length(x)); (1:length(x))+3]';
i_win((i_win(:,1) < 1),1) = 1;
i_win((i_win(:,3) > length(x)),3) = length(x);

[m, n] = size(c1);
crr_out = zeros(m,n);
%%
parfor i=1:n
    for j=1:m
        window_EK = c1(j_win(j,1):j_win(j,3), i_win(i,1):i_win(i,3));
        window_param = c2(j_win(j,1):j_win(j,3), i_win(i,1):i_win(i,3));
        
        % Reshape windows to vectors
        window_EK = window_EK(:);
        window_param = window_param(:);

        crr_out(j,i) = corr(window_EK, window_param);

        % temp = corrcoef(z_EK(j_win(j,1):j_win(j,3),i_win(j,1):i_win(j,3)),...
        %     z_oxy(j_win(j,1):j_win(j,3),i_win(j,1):i_win(j,3)));
        %crr(j,i) = temp(1,2);
    end
end

% Print progress
fprintf('[BN Filter] computed noise for all pings\n');

%ezimagesc(x_EK,y_EK,crr,colorcet('D01A'),[-1 1])
end