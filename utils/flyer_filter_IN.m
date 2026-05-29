function svEK80_flyer_filt = flyer_filter_IN(datain, angle, cast_proc, crange, depth_interval, thres, r_start, r_end, plot_fig)

chk = fieldnames(datain);
if numel(fieldnames(datain)) > 1
    datain = rmfield(datain,chk{2});
end

fn = char(fieldnames(datain));
if strcmp(fn(1:4),'chan')
    [datain,cl,ci] = flyer_cast_idx(datain, 1); % obtain casts and fix the cast numbering
    datain = flyer_query_castData(datain, 1, ci, cl);
end

cast_list = fieldnames(datain);
for k=1:length(cast_list)
    cast_num(k) = str2double(cast_list{k}(2:end));
end

chan_data = string(fieldnames(datain.(cast_list{1})));
chan_ang = string(fieldnames(angle));

if ismember(chan_data,chan_ang)
    chan_id = find(chan_ang == chan_data);
else
    error('Channel between data and angle is not consistent!')
end

if isempty(cast_proc)
    cast_proc = cast_num;   
end

time = datetime([angle.(chan_data{chan_id}).vars.timestamp],"ConvertFrom","epochtime","TicksPerSecond",1e6);
range = [angle.((chan_data{chan_id})).range];
vars = [angle.((chan_data{chan_id})).vars];
ang_val = [angle.((chan_data{chan_id})).val];
depth = [vars.depth];

if ~isfield(vars,'cast_new')
    [angle,~,~] = flyer_cast_idx(angle, 1);
    vars = [angle.((chan_data{chan_id})).vars];
end

%% Check for angle data if its correct
if ~strcmp(angle.(chan_ang{1}).type,'PhysAng_alongship') && ~strcmp(angle.(chan_ang{1}).type,'PhysAng_athwartship')
    error('Angle data is not detected as an input')
else
    angleflag = 1;
end

for n=1:length(cast_proc)
    if n==1
        fprintf('Detected %d casts',length(cast_proc))
        fprintf(': %s\n',join(string(cast_proc)));
        
    end
    cast_plt_idx = ~ismember(cast_num,cast_proc(n));
    cast_proc2 = cast_list(cast_plt_idx);
    data_proc = rmfield(datain,cast_proc2);
    if n==1
        svEK80_flyer_filt = data_proc;
    end
    %data_proc = flyer_combine_casts(data_proc); %Do this in the end

    %% Parse angle cast and depth data

    c_idx = ismember([vars.cast_new],cast_proc(n));
    ang_proc = ang_val(:,c_idx);
    ang_t = time(c_idx);
    dep_proc = depth(c_idx);
    val_cast = data_proc.(sprintf('C%d',cast_proc(n))).(chan_data).val;
    vars2 = [vars(c_idx)];
    idx_proc = find(c_idx == 1); %Index of casts

    try
        if ~isempty(depth_interval)
            d_idx = dep_proc > depth_interval(1) & dep_proc < depth_interval(2);
            %c_idx = c_idx & c_idx_2; %intersect between depth and cast
            ang_proc = ang_proc(:,d_idx);
            ang_t = ang_t(d_idx);
            dep_proc = dep_proc(d_idx);
            val = val_cast(:,d_idx);
            vars2 = [vars(c_idx)];
            idx_proc_d = find(d_idx == 1); %Index of casts; This maps directly to data_proc indexes
        end

        %% Calculate angle average
        ang_avg = mean(ang_proc,1);

        %% Reformat struct for Val and Angle based on queries / useless??
        data_ang.(chan_data) = angle.(chan_data); %useless
        data_ang.(chan_data).val = ang_proc; %useless
        data_ang.(chan_data).vars = vars2; %useless
        out_filt = val; %Final output / whole data for cast
        % data_filt = data_proc;
        % data_filt.(chan_data).val = val;

        %% Figure
        if exist("angleflag")
            maxAng = max(ang_proc,[],"all");
            minAng = min(ang_proc,[],"all");
            crange_ang(1) = ceil(minAng);
            crange_ang(2) = floor(maxAng);
            fprintf('Angle data detected, plotting scale: %d to %d \n',crange_ang(1),crange_ang(2));
        end

        if plot_fig == 1
            figure();
            tiledlayout(3,1,"TileSpacing","tight");

            ax1 = nexttile;
            %a1 = pcolor(ang_t, range, ang_proc);
            a1 = imagesc(ang_t, range, ang_proc);
            caxis([crange_ang(1) crange_ang(2)]);
            %set(a1,'EdgeColor','none');
            %ax2.Colormap = redblue;
            colormap(ax1,redblue);
            set(gca,'YDir','reverse');
            axis tight;
            ylim([0 100]);
            set(gca,'Xtick',[],'FontSize',16,'LineWidth',1);
            %cb2 = colorbar(ax2);
            colorbar;

            ax2 = nexttile;
            plot(ang_t,ang_avg,'LineWidth',2,'Color',"black");
            axis tight;
            set(gca,'Xtick',[],'FontSize',16,'LineWidth',1);

            ax3 = nexttile;
            [peakValues,peak_idx] = findpeaks(-(ang_avg),ang_t,'MinPeakProminence',0.5);
            plot(ang_t,-(ang_avg),'LineWidth',2,'Color',"black");
            hold on;
            % xp = ang_t(peak_idx)
            % yp = -1*(ang_avg(peak_idx));
            plot(peak_idx, peakValues, 'rv', 'LineWidth', 0.5, 'MarkerSize', 8);
            axis tight;
            %xticks('auto');yticks('auto');
            xlabel('Time','fontsize',20);
            set(gca,'FontSize',16);

            linkaxes([ax1,ax2,ax3],'x');
            linkaxes([ax2,ax3],'y');

        end
        %% Obtain values surrounding peaks and format into new struct
        [peakValues,peak_idx] = findpeaks(-(ang_avg),ang_t,'MinPeakProminence',0.5);
        peak_idx_data = ismember(ang_t,peak_idx);
        peak_num = numel(peak_idx);
        fprintf('Processing Cast %d and detected %d impulses\n',cast_proc(n),peak_num)

        for ii = 1:peak_num
            fprintf('Processing Cast %d impulse %d/%d \n',cast_proc(n),ii,peak_num)
            idx_s = (find(ang_t == peak_idx(ii)) - 5);
            idx_f = (find(ang_t == peak_idx(ii)) + 5);
            idx_c = find(ang_t == peak_idx(ii));
            if idx_s < 1
                idx_s = 1;
            elseif idx_f >= numel(ang_t)
                idx_f = numel(ang_t);
            end
            %pk_ctr_idx = [(find(ang_t == peak_idx(i)) - 5):1:(find(ang_t == peak_idx(i)) + 5)];
            q = findchangepts(ang_avg(idx_s:idx_f),MaxNumChanges=2);
            if isempty(q)
                warning('Find changepoints could not find 2 change points. Increasing to 3')
                q = findchangepts(ang_avg(idx_s:idx_f),MaxNumChanges=3);
                
                if isempty(q)
                    %figure();findpeaks(-1*ang_avg(idx_s:idx_f),'Threshold',0.1);
                    [~,q] = findpeaks(-1*ang_avg(idx_s:idx_f),'Threshold',0.1);
                    fprintf('Using findpeaks for Impulse %d out of %d in cast %d \n',ii,peak_num,cast_proc(n));
                end
            end
                
            IN_val = ang_proc(:,idx_s:idx_f);
            IN_t = ang_t(idx_s:idx_f);
            [IN_t_res, IN_r_res, IN_val_res,Xj,Xi] = resample_data_withoutStruct(IN_t, range, IN_val, 1, 40, []);
            datain_IN = IN_val_res; %Overlap name with datain as input
            data_out = IN_val;
            rw = IN_r_res;
            tw = IN_t_res;
            hardcore = 0;
            method = 'NaN';
            %% Range indexing
            r_index = rw >= r_start & rw <= r_end;
            Xj = Xj(r_index,:); %Xj needs to be indexed for the exclude depths
            datain_IN = datain_IN(r_index,:);
            %% Algorithm
            %imax = size(datain,2); %Change to size of q
            imax = size(q,1); %Change to size of q
            jmax = size(datain_IN,1);
            %i_start = 1+ping_window; %Change this to q(1)
            i_start = q(1); %Change this to q(1)
            %i_end = imax-ping_window; %Change to q(end)
            i_end = q(end); %Change to q(end)
            cond1 = zeros(jmax,imax);
            mask_array = false(size(data_out,1),size(data_out,2));
            q_idx = ~ismember([1:size(datain_IN,2)],[q(1):q(end)]);
            for i = i_start:i_end
                for j = 1:jmax

                    cond1(j,i) = abs((datain_IN(j,i) - mean(datain_IN(j,q_idx),'omitmissing'))) > thres;

                    if cond1(j,i) && strcmp(method,'NaN')
                        if j ~= jmax %everything else
                            %if ~hardcore == 1
                            %    data_out(Xj(j,:),Xi(:,i)) =  NaN;
                            %else
                            %    data_out((min(Xj,[],"all"):max(Xj,[],"all")),Xi(:,i)) =  NaN; %whole ping will be erased
                            %end
                            data_out(Xj(j,:),Xi(:,i)) =  NaN;
                            mask_array(Xj(j,:),Xi(:,i)) = 1;
                        else %When j=jmax (there will be a NaN at the last depth sample from resampled data)
                            if ~hardcore == 1
                                j_ind = sum(~isnan(Xj(j,:)));
                                data_out(Xj(j,1:j_ind),Xi(:,i)) =  NaN;
                                mask_array(Xj(j,1:j_ind),Xi(:,i)) = 1;
                            elseif any(hardcore == 1) && (sum(cond1(:,i)) > floor((hrd_thres/100)*jmax)) %if 10% of total range samples have NaNs then the whole ping will be removed
                                %j_ind = sum(~isnan(Xj(j,:)));
                                data_out((min(Xj,[],"all"):max(Xj,[],"all")),Xi(:,i)) =  NaN; %whole ping will be erased
                                mask_array((min(Xj,[],"all"):max(Xj,[],"all")),Xi(:,i)) = 1;
                            end
                        end
                        %elseif cond1 && cond2 && strcmp(method,'mean') %not yet implemented!!
                        %    noise(j,i) = mean(
                    end
                end
            end


            %% Appending output and plotting
            if hardcore == 2
                new_mask = INF_Remove_Gaps(mask_array,hrd_thres);
                mask_array = new_mask;
                data_out(new_mask) = NaN;
            end

            ping_aff = sum(any(isnan(data_out)));
            data_aff = sum(isnan(data_out),"all")*100/(size(data_out,2)*(size(data_out,1)));
            %fprintf('[IN Filter] Impulse noise detected on %0.2f%% of total pings and %0.2f%% of total data was removed\n',...
            %    ping_aff*100/size(data_out,2),data_aff);

            idx_removed = isnan(data_out);
            temp = out_filt(:,idx_s:idx_f);
            temp(idx_removed) = NaN;
            out_filt(:,idx_s:idx_f) = temp;
        end
        %disp('Filtered 1 cast')
        svEK80_flyer_filt.(sprintf('C%d',cast_proc(n))) = data_proc.(sprintf('C%d',cast_proc(n)));
        val_cast(:,idx_proc_d) = out_filt;
        svEK80_flyer_filt.(sprintf('C%d',cast_proc(n))).(chan_data).val = val_cast;
        samp_win = [100, 80, 60, 40, 20];
        for ii=1:5
            if ii == 1
                in_out = svEK80_flyer_filt.(sprintf('C%d',cast_proc(n)));
            end
            in_in = in_out;
            in_out = impulse_noise_filter(in_in,'EK80',1,samp_win(ii),2,7,0,105,'NaN','remove_gap',5,[]); %100 good
        end
        %svEK80_flyer_IN = impulse_noise_filter(svEK80_flyer_filt.(sprintf('C%d',cast_proc(n))),'EK80',1,40,2,7,0,105,'NaN','remove_gap',5,[]);
        svEK80_flyer_filt.(sprintf('C%d',cast_proc(n))).(chan_data).val = in_out.(chan_data).val;
        fprintf('Filtered IN for cast: %d\n',cast_proc(n));
    catch err
        %disp(err.identifier);
        fprintf('%s for line: %d \n',err.message,err.stack(end).line);
        fprintf('Filtering failed for cast %d; Moving to the next cast \n',cast_proc(n));
        %data_proc = rmfield(datain,cast_proc2);
        svEK80_flyer_filt.(sprintf('C%d',cast_proc(n))) = data_proc.(sprintf('C%d',cast_proc(n)));
        %svEK80_flyer_filt = rmfield(svEK80_flyer_filt,sprintf('C%d',cast_proc(n)));
    end
end

% Converting cast data to EK data struct 
svEK80_flyer_filt = flyer_combine_casts(svEK80_flyer_filt); % Combine the seperated casts into one datafile
data_proc = flyer_combine_casts(data_proc); % Combine the seperated casts into one datafile

if plot_fig == 1
    plotEk_Echogram_Niskin(svEK80_flyer_filt,1,[],[],{0 'inf'},[],[-70 -39],'EK80 filtered',[]);
    plotEk_Echogram_Niskin(data_proc,1,[],[],{0 'inf'},[],[-70 -39],'EK80 original',[]);
    %plotEk_Echogram_Niskin(svEK80_flyer_IN,1,[],[],{0 'inf'},[],[-70 -39],'EK80 original',[]);
end

%{
figure()
%a1 = pcolor(datetime(IN_t_res,"ConvertFrom","datenum"), IN_r_res, IN_val_res);
a1 = imagesc(datetime(IN_t_res,"ConvertFrom","datenum"), IN_r_res, IN_val_res);
caxis([crange_ang(1) crange_ang(2)]);
%set(a1,'EdgeColor','none');
%ax2.Colormap = redblue;
colormap(redblue);
set(gca,'YDir','reverse');
axis tight;
ylim([0 100]);
set(gca,'FontSize',16,'LineWidth',1);
%cb2 = colorbar(ax2);
colorbar;

figure
findchangepts(ang_avg(idx_s:idx_f),MaxNumChanges=2)

figure()
%a1 = pcolor(IN_t(q(1):q(2)), range, IN_val(:,q(1):q(2)));
%a1 = imagesc(IN_t(q(1):q(2)), range, IN_val(:,q(1):q(2)));
a1 = imagesc(IN_t, range, IN_val);
caxis([crange_ang(1) crange_ang(2)]);
%set(a1,'EdgeColor','none');
%ax2.Colormap = redblue;
colormap(redblue);
set(gca,'YDir','reverse');
axis tight;
ylim([0 100]);
set(gca,'FontSize',16,'LineWidth',1);
%cb2 = colorbar(ax2);
colorbar;


figure()
imagesc(ang_t, range, out_filt,[crange(1) crange(2)]);
%caxis([crange(1) crange(2)]);
%set(a1,'EdgeColor','none');
%ax2.Colormap = redblue;
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
% colormap(redblue);
set(gca,'YDir','reverse');
axis tight;
ylim([0 100]);
set(gca,'FontSize',16,'LineWidth',1);
%cb2 = colorbar(ax2);
colorbar;

figure()
imagesc(ang_t, range, val,[crange(1) crange(2)]);
%caxis([crange(1) crange(2)]);
%set(a1,'EdgeColor','none');
%ax2.Colormap = redblue;
cmap = cptcmap('EK60_2.cpt'); cmap(1,:) = [1 1 1]; colormap(cmap);
% colormap(redblue);
set(gca,'YDir','reverse');
axis tight;
ylim([0 100]);
set(gca,'FontSize',16,'LineWidth',1);
%cb2 = colorbar(ax2);
colorbar;
%}
end

%end



