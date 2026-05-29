%%
%{
j_idx = zeros(J_max,1);
i_idx = zeros(I_max,1);
ctr_wj = ceil(0.5*sample_window); %index of center ping in window
ctr_wi = ceil(0.5*ping_window); %index of center ping in window
for i = 1:1000
    for j = 1:J_max
        j_start = j; j_end = j+sample_window-1;
        i_start = i; i_end = i+ping_window-1;
        ctr_j = 0.5*(j_end-j_start)+j_start; %depth index of center ping in resampled moving window (J,I)
        ctr_i = 0.5*(i_end-i_start)+i_start; %ping index of center ping in resampled moving window (J,I)
        win_samples = data_ind(j_start:j_end,i_start:i_end);
        win_samples(ctr_wj,ctr_wi) = NaN; %excluding the center sample
        v_mn = prctile(win_samples,percentile,"all","Method","exact");
        cond1(j,i) = (data_ind(ctr_j,ctr_i) - v_mn > thres);
                if cond1(j,i) && strcmp(method,'NaN')
                    
                    data_out(Xj(ctr_j,:),Xi(:,ctr_i)) =  NaN; %replace the center sample of context window [data_ind(ctr_j,ctr_i)]...
                                                                %and corresponding real samples [data_out(Xj=ctr_j,Xi=ctr_i)] to nan
                    %elseif cond1 && cond2 && strcmp(method,'mean') %not yet implemented!!
                    %    noise(j,i) = mean(
                end
    end
    if i == floor(I_max/4) || i == floor(I_max/2) || i == floor(I_max*3/4) || i == I_max
        fprintf('[TN Filter] computed noise for ping %d out of %d\n',i,I_max);
    end
    
end
%}
%%
% Preallocate arrays
ctr_wj = ceil(sample_window / 2);
ctr_wi = ceil(ping_window / 2);
cond1 = false(J_max, 1000);

% Create indexing vectors
i_idx = 1:1000;
j_idx = 1:J_max;
[I_idx, J_idx] = meshgrid(i_idx, j_idx);

j_start = J_idx;
j_end = J_idx + sample_window - 1;
i_start = I_idx;
i_end = I_idx + ping_window - 1;

ctr_j = 0.5 * (j_end - j_start) + j_start;
ctr_i = 0.5 * (i_end - i_start) + i_start;
tic
for i = 1:1000
    for j=1:J_max
        win_samples = data_ind(j_start(j):j_end(j), i_start(i):i_end(i));
        win_samples(ctr_wj, ctr_wi, :) = NaN;
        v_mn = prctile(win_samples(:), percentile, 'Method', 'exact');
        cond1(j,i) = (data_ind(ctr_j(j), ctr_i(i)) - v_mn > thres);
        if cond1(j,i) && strcmp(method,'NaN')
            data_out(Xj(ctr_j(j),:),Xi(:,ctr_i(i))) =  NaN; %replace the center sample of context window [data_ind(ctr_j,ctr_i)]...
            %and corresponding real samples [data_out(Xj=ctr_j,Xi=ctr_i)] to nan
        %elseif cond1 && cond2 && strcmp(method,'mean') %not yet implemented!!
        % noise(j,i) = mean(
        end
    end
end
toc
% Apply NaN replacement
nan_idx = cond1 & strcmp(method, 'NaN');
data_out(Xj(ctr_j(nan_idx), :), Xi(:, ctr_i(nan_idx))) = NaN;

% Display progress
progress_points = [floor(I_max/4), floor(I_max/2), floor(I_max*3/4), I_max];
if any(i_idx == progress_points)
    fprintf('[TN Filter] computed noise for ping %d out of %d\n', i_idx, I_max);
end