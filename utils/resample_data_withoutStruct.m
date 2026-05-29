function [t_res, r_res, y, Xnum_j, Xnum_i] = resample_data_withoutStruct(data_x, data_y, data_val, ping_samples, depth_samples, logdata)

if ~isempty(logdata)
    data_val = 10.^(data_val/10);
    %disp('Data is converted to linear scale');
else
    %disp('Data is linear');
end

d = data_x;
dt = seconds(d(2)-d(1));
if isdatetime(d)
    d = datenum(d);
    %disp('Converted to datetime');
end
r = repmat(data_y,1,size(data_val,2));
dr = r(2)-r(1);
fprintf('[Resample Data] Resampling data with bin size of %0.3fm (%i depth samples) and %0.3fseconds (%i ping samples)\n',...
                dr*depth_samples,depth_samples,dt*ping_samples, ping_samples);

%% Calculating near range boundary samples (R(i,j) in Echoview)
R = zeros(size(r,1)+1,size(r,2)); %size of R(j,i) will always be r(j+1,i)
for i=1:size(r,2)
    for j=1:size(r,1)
        if j == size(r,1)
            R(j+1,i) = r(j,i);
        else
            R(j+1,i) = (r(j+1,i) + r(j,i))/2;
        end
    end
end

%% Calculating near boundary distance ping samples (D(i,j) in Echoview)
D = zeros(size(d,1),size(d,2)+1); %size of D(j,i) will always be d(j,i+1)
D(1,1) = d(1,1);
for j=1:size(d,1)
    for i=1:size(d,2)
        if i == size(d,2)
            D(j,i+1) = d(j,i) + (d(j,i)-D(j,i));
        else
            D(j,i+1) = (d(j,i+1) + d(j,i))/2;
        end
    end
end
%lg = sprintf('[Resample Data] Finished calculating boundary of samples in range and pings/time');
%disp(lg)

%% Mapping from sample to kernel space
    %I_max = (size(data_val,2)-ping_samples)+1; %taken from derobertis! (WRONG!!!)
    I_max = ceil(size(data_val,2)/ping_samples); %total number of windows in the x-direction/pings
    J_max = ceil(size(data_val,1)/depth_samples); %  the number of windows in depth/last window index in y-direction
    
    % Initialize R2 and D2 matrices
    R2 = zeros(J_max, I_max);
    D2 = zeros(1, I_max);
    
    % Update R2 matrix
    %R2(1,:) = r(1,:); %WRONG
    %R2(J_max,:) = r(end,:); %WRONG
    %R2(2:J_max-1,:) = r(idx_j, :); %WRONG
    R2(1,:) = r(1); %different size left (always lower) than right (full data size) except if no resample in ping direction
    R2(J_max,:) = r(end); %different size left (always lower) than right (full data size) in ping direction
    idx_j = 1:depth_samples:size(r,1);
    idx_j = idx_j(2:end-1);
    R2(2:J_max-1,:) = repmat(r(idx_j)',1,I_max);
    
    % Update D2 matrix
    D2(1) = d(1,1); %different size left (always lower) than right (full data size) in ping direction
    D2(I_max) = d(1,end); %different size left (always lower) than right (full data size) in ping direction
    idx_i = 1:ping_samples:size(d,2);
    idx_i = idx_i(2:end-1);
    D2(2:I_max-1) = d(1,idx_i);
    
    % lg = sprintf('[Resample Data] Finished calculating boundary of output kernel samples in range and pings/time');
    %disp(lg)
    %% Calculating weighted mean for each kernel
    y = zeros(J_max,I_max);
    Xnum_j = zeros(J_max,depth_samples);
    Xnum_i = zeros(ping_samples,I_max);
    tic
    for I=1:I_max
        for J=1:J_max
            if J == 1 %for 1st window in depth
                j_start = 1; j_end = depth_samples;

                if I == 1
                    i_start = I; i_end = I+ping_samples-1;
                elseif I == I_max
                    i_start = (I_max-1)*ping_samples+1; i_end = size(data_val,2);
                else
                    i_start = (I-1)*ping_samples+1; i_end = I*ping_samples;
                end

                w1 = min(R(j_start+1:j_end+1,i_start:i_end),R2(J+1,I)) - max(R(j_start:j_end,i_start:i_end),R2(J,I));
                if I~=I_max
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I+1)) - max(D(1,i_start:i_end),D2(1,I));
                else
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I)) - max(D(1,i_start:i_end),D2(1,I));
                end
                w = w1.*w2;
                y(J,I) = sum(w.*data_val(j_start:j_end,i_start:i_end),"all","omitnan")/sum(w,"all","omitnan");
                Xnum_j(J,1:(j_end-j_start+1)) = [j_start:j_end];
                Xnum_i(1:(i_end-i_start+1),I) = [i_start:i_end];
            elseif J == J_max %for last window in depth
                j_start = (J_max-1)*depth_samples+1; j_end = size(data_val,1);

                if I == 1
                    i_start = I; i_end = I+ping_samples-1;
                elseif I == I_max
                    i_start = (I_max-1)*ping_samples+1; i_end = size(data_val,2);
                else
                    i_start = (I-1)*ping_samples+1; i_end = I*ping_samples;
                end

                w1 = min(R(j_start+1:j_end+1,i_start:i_end),R2(J,I)) - max(R(j_start:j_end,i_start:i_end),R2(J,I)); %find out about this (incorrect right now)
                if I~=I_max
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I+1)) - max(D(1,i_start:i_end),D2(1,I));
                else
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I)) - max(D(1,i_start:i_end),D2(1,I));
                end
                w = w1.*w2;
                y(J,I) = sum(w.*data_val(j_start:j_end,i_start:i_end),"all","omitnan")/sum(w,"all","omitnan");
                Xnum_j(J,1:(j_end-j_start+1)) = [j_start:j_end];
                Xnum_i(1:(i_end-i_start+1),I) = [i_start:i_end];
            else %everything else
                j_start = (J-1)*depth_samples+1; j_end = J*depth_samples;

                if I == 1
                    i_start = I; i_end = I+ping_samples-1;
                elseif I == I_max
                    i_start = (I_max-1)*ping_samples+1; i_end = size(data_val,2);
                else
                    i_start = (I-1)*ping_samples+1; i_end = I*ping_samples;
                end

                w1 = min(R(j_start+1:j_end+1,i_start:i_end),R2(J+1,I)) - max(R(j_start:j_end,i_start:i_end),R2(J,I));
                if I~=I_max
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I+1)) - max(D(1,i_start:i_end),D2(1,I));
                else
                    w2 = min(D(1,i_start+1:i_end+1),D2(1,I)) - max(D(1,i_start:i_end),D2(1,I));
                end
                w = w1.*w2;
                y(J,I) = sum(w.*data_val(j_start:j_end,i_start:i_end),"all","omitnan")/sum(w,"all","omitnan");
                Xnum_j(J,1:(j_end-j_start+1)) = [j_start:j_end];
                Xnum_i(1:(i_end-i_start+1),I) = [i_start:i_end];
            end
        end
        if I == floor(I_max/2) || I == I_max
            %lg = sprintf('[Resample Data] Applying Weighted Mean: resampled data for ping %d out of %d',I,I_max);
            %disp(lg)
        end
    end
    fprintf('[Resample Data] Completed in %0.1f secs \n',toc)
    %% Appending output values into struct
    Xnum_j(Xnum_j == 0) = NaN; %remove index that is 0
    Xnum_i(Xnum_i == 0) = NaN; %remove index that is 0
    
    if ~isempty(logdata)
        y(y==0)=nan; %to remove log10(0) errors
        ylog = 10*log10(y); %Convert back to log
        ylog(imag(ylog) ~= 0) = NaN; %set all imag parts to zero (strange error)
        %disp('Data is converted back to log scale')
    end
    
    dr_values = diff(R2(:, 1)); % Calculate dr for all elements in R2
    r_res = zeros(1,size(dr_values,1)+1); % Initialize r_res with the first value
    dr_values(1) = dr_values(1)/2; % Set 1st value
    r_res(1:end-1) = cumsum(dr_values); % Calculate cumulative sum to obtain the final result
    r_res(end) = R2(end,1); % Set final value

    if ping_samples ~= 1
        dt_values = diff(D2(1,:));
        t_res = zeros(1,size(dt_values,2)+1);
        dt_values(1) = D2(1,1) + dt_values(1)/2;
        t_res(1:end-1) = cumsum(dt_values);
        t_res(end) = D2(end,1);
    else
        t_res = D2;
    end

end
