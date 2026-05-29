%% Background noise removal (De Robertis et al 2008)
% add in channel selection
% P(i,j) = original backscatter data matrix where:
% i = ping number of original data
% j = depth sample of original data
% note: notation of i,j does not mean i = rows and j = columns.
% M = # of samples in depth of window
% N = # of pings of window
% Pm(k,l) = mean Power averaged window matrix; this represents the average
%   backscatter over the moving window with horizontal size N and vertical size N.
%   This matrix estimates the "background noise" from averages of
%   backscatter of samples in the window. 
% k = window index in x-direction (represents the central ping number N/2 of the original data; where if k == 1, 
%   then k represents the index of the first window, mapped to the N/2th ping of the original data).
%   Mathematically this can be written: Pm(k = 1, l = 1) = P(i = N/2, all depth samples in window M)
%   Another way to see it is k == 2 is the second window in the x-direction
%   and represents P(i = N/2+1, all depth samples in window M)
% l = window index in the y-direction (depth direction). The index can be
%   interpretted as the window number for a certain ping in the y-direction.
%   Example: l = 1 means the first window that covers samples from the surface up to M. l = 2 is the second window under it 
%   that covers depth from samples M+1 to  2*M and so forth. The windows
%   does not overlap in the y-direction unless the last window where M size does
%   not match the remaining original samples number.

function svfiltered = background_noise_remove_RMS(svdata,trans,channel,depth_samples,ping_samples,max_noise,SNR,min_SNR,plot_fig)

chan = fieldnames(svdata);
if channel == 1
    fprintf('[BN Filter] Reading data from channel 1: %s \n',chan{1});
    chan = chan(1);
elseif channel == 2
    fprintf('[BN Filter] Reading data from channel 2: %s \n',chan{2});
    chan = chan(2);
else
    fprintf('[BN Filter] Reading data from all %i channels\n',length(chan));
end

for ch = 1:length(chan) %do for all channels
    fprintf('[BN Filter] Processing channel: %s\n',chan{ch});
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        sv_data = svdata.(chan{ch}).Sv;
        c = svdata.(chan{ch}).cal.soundvelocity;
        alpha = svdata.(chan{ch}).cal.absorptioncoefficient;
        tau = svdata.(chan{ch}).cal.pulselength;
        if size(svdata.(chan{ch}).range,1) == 1
            range = repmat(svdata.(chan{ch}).range',1,size(sv_data,2));
        else
            range = repmat(svdata.(chan{ch}).range,1,size(sv_data,2));
        end
        %range = svdata.(chan{ch}).range;
        tvg_start = 1;
        dataflag = 'Sv';
    elseif strcmp(trans,'EK80') %unfinished!!
        if strcmp(svdata.(chan{ch}).type,'ts_pc')
            sv_data = svdata.(chan{ch}).val;
            fprintf('[BN Filter] Detected EK80 FM TS data at channel: %s\n',chan{ch});
            dataflag = 'TS';
        elseif strcmp(svdata.(chan{ch}).type,'sv_pc')
            sv_data = svdata.(chan{ch}).val;
            fprintf('[BN Filter] Detected EK80 FM SV data at channel: %s\n',chan{ch});
            dataflag = 'Sv';
        else
            error('EK80 data format is unknown')
        end

        c = mean([svdata.(chan{ch}).vars.soundspeed]);
        alpha = unique([svdata.(chan{ch}).vars.absorptionCoeff]);
        tau = svdata.(chan{ch}).cal.pulse_length; %effective pulse length???
        range = repmat([svdata.(chan{ch}).range],1,size(sv_data,2));
        tvg_start = svdata.(chan{ch}).vars.TVGStart;
    else
        error('input data is not from a known format');
    end
    
    %% conversion to power from paper
    %compute tvg term
    r_tvg = zeros(size(sv_data,1),size(sv_data,2));
    for i = 1:size(sv_data,2)
        for j = 1:size(sv_data,1)
            if range(j,i) < tvg_start %all range values under ct/2 will not have TVG applied
                r_tvg(j,i) = 1; %remember that log10(1) = 0!!!
            else
                r_tvg(j,i) = range(j,i) - (tau*(c/4));
                if r_tvg(j,i) < 0
                    r_tvg(j,i) = 1;
                end
            end
        end
    end
    
    if strcmp(dataflag,'TS')
        P = sv_data - (40*log10(r_tvg)) + 2*alpha.*r_tvg;
    else
        P = sv_data - (20*log10(r_tvg)) + 2*alpha.*r_tvg;
    end

    P = 10.^(P/10); %converted from log to linear form
    fprintf('[BN Filter] Converted Sv/TS to Linear Power\n');
    %% start of averaging window of P in linear form
    k_max = (size(sv_data,2)-ping_samples)+1; %total number of windows in the x-direction/pings
    l_max = ceil(size(sv_data,1)/depth_samples); %  the number of windows in depth/last window index in y-direction
    
    Pm = zeros(l_max,k_max);
    
    for k=1:k_max
        for l=1:l_max
            if l == 1 %for 1st window in depth
                j_start = 1; j_end = depth_samples;
                i_start = k; i_end = k+ping_samples-1;
                %Pm(l,k) = 10*log10(sum((10.^P(j_start:j_end,i_start:i_end))/10,"all","omitnan")/(ping_samples*depth_samples));
                Pm(l,k) = sum(P(j_start:j_end,i_start:i_end),"all","omitnan")/(ping_samples*depth_samples);
            elseif l == l_max %for last window in depth
                j_start = size(sv_data,1)-depth_samples+1; j_end = size(sv_data,1);
                i_start = k; i_end = k+ping_samples-1;
                %Pm(l,k) = 10*log10(sum((10.^P(j_start:j_end,i_start:i_end))/10,"all","omitnan")/(ping_samples*depth_samples));
                Pm(l,k) = sum(P(j_start:j_end,i_start:i_end),"all","omitnan")/(ping_samples*depth_samples);
            else %everything else
                %j_start = l*depth_samples+1; j_end = depth_samples+l*depth_samples; %wrong!!!
                j_start = (l-1)*depth_samples+1; j_end = l*depth_samples;
                i_start = k; i_end = k+ping_samples-1;
                Pm(l,k) = sum(P(j_start:j_end,i_start:i_end),"all","omitnan")/(ping_samples*depth_samples);
            end
        end
        
        if k == floor(k_max/2) || k == k_max
            fprintf('[BN Filter] computed noise for ping %d out of %d\n',k,k_max);
        end
    end
    
    %% Noise matrix [Noise(k)] and reshaping into Noise(i):
    % We need to reshape noise(k) into noise(i) [from window to actual ping data]!
    % Remember that noise level for [all pings < N/2] will be equal to Pm(k=1) and
    % noise level for pings from [Last ping - N/2 to Last Ping] will be equal
    % to Pm(k=end). Therefore, the noise matrix will be reshaped to get all
    % the representative noise values of pings from the original sample data.
    Pm = 10*log10(Pm); %convert Pm into log form (dB)
    noise = min(Pm); %Noise(k)
    for kk = 1:length(noise)
        if noise(kk) > max_noise
            noise(kk) = max_noise;
        end
    end
    
    noise_reshape = zeros(size(sv_data)); %new noise matrix with similar size to original data
    for ii = 1:size(sv_data,1)
        if ping_samples == 2 %special case if N is 2 samples (highly unlikely)
            noise_reshape(ii,ceil(ping_samples/2):ceil(ping_samples/2)+length(noise)-1) = noise(1:end);
            noise_reshape(ii,1) = noise(1);
            noise_reshape(ii,(end-ceil(ping_samples/2)):end) = noise(end);
        end
        if mod(ping_samples,2) ~= 0 %if N is odd number
            noise_reshape(ii,ceil(ping_samples/2):ceil(ping_samples/2)+length(noise)-1) = noise(1:end);
            noise_reshape(ii,1:ceil(ping_samples/2)-1) = noise(1);
            noise_reshape(ii,(end-floor(ping_samples/2)):end) = noise(end);
        else %if N is even
            noise_reshape(ii,ping_samples/2:(ping_samples/2)+length(noise)-1) = noise(1:end);
            noise_reshape(ii,1:(ping_samples/2)-1) = noise(1);
            noise_reshape(ii,(end-(ping_samples/2))+1:end) = noise(end);
        end
    end
    fprintf('[BN Filter] Reshaped noise values from moving window matrix into sample space matrix\n');
    %% Conversion of Noise into Sv_noise, remove noise from the original data, and calculate SNR
    sv_noise = noise_reshape + (20*log10(r_tvg)) + 2*alpha.*r_tvg;
    sv_noise = 10.^(sv_noise/10); %linear form
    sv_data = 10.^(sv_data/10); %linear form
    % Removing noise from original data
    
    sv_corr = sv_data-sv_noise;
    sv_corr(sv_corr<0) = nan; %to avoid complex numbers
    sv_corr = 10*log10(sv_corr); %log form
    fprintf('[BN Filter] Background Noise has been removed by Sv_data-Sv_Noise (%0.1f%%)\n',...
        sum(isnan(sv_corr),"all")*100/numel(sv_data));
    idx_nan = isnan(sv_corr);
    sv_corr(idx_nan) = -999;

    % SNR
    if SNR == 1
        SNR = sv_corr-(10*log10(sv_noise)); %log form
        SNR(SNR<=min_SNR) = NaN;
        idx_snr = isnan(SNR);
        sv_corr(idx_snr) = -999;
        fprintf('[BN Filter] samples detected with SNR<%0.2f set to -999 dB. %0.1f%% of data removed in total \n',...
            min_SNR,(sum(idx_snr,"all")*100)/numel(sv_data))
    end

    % save
    if strcmp(trans,'ES60') || strcmp(trans,'EK60')
        svfiltered.(chan{ch}) = svdata.(chan{ch});
        svfiltered.(chan{ch}).Sv = sv_corr;
        %svfiltered.(chan{ch}).range = svdata.(chan{ch}).range;
        %svfiltered.(chan{ch}).time = svdata.(chan{ch}).time;
        %svfiltered.(chan{ch}).cal = svdata.(chan{ch}).cal;
        %svfiltered.(chan{ch}).snr = SNR;
        fprintf('[BN Filter] Output saved for channel %s\n',chan{ch});
    elseif strcmp(trans,'EK80')
        svfiltered.(chan{ch}) = svdata.(chan{ch});
        svfiltered.(chan{ch}).val = sv_corr;
        %svfiltered.(chan{ch}).snr = SNR;
        fprintf('[BN Filter] Output saved for channel %s\n',chan{ch});
    end
    
    %plot
    if plot_fig == 1
        lg = sprintf('[%s] Original Data',(chan{ch}));
        plotEk_Echogram_Niskin(svdata,ch,[],[],{0 'inf'},[],[-77 -36],lg,[]);
        lg = sprintf('[%s] BN Filtered',(chan{ch}));
        plotEk_Echogram_Niskin(svfiltered,ch,[],[],{0 'inf'},[],[-77 -36],lg,[]);
    end
end

end





