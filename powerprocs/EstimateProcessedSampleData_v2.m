% 2026-5-6 -- RMS
% Accomodates processing multiple pings at once
% Works for flyer data/complex samples. Not tested on EA440 or ship EK80 CW

function [ProcessedSampleData,tabledata] = EstimateProcessedSampleData_v2(SampleData,wbt_impedance,transdata_ch,ChannelData, ParameterData, FilterData, EnvironmentData, TVG_range_correction)
% output contains:
% 1st output (struct)
% ping processed data (matrix form): Y_pc_avg (pulse compressed data averaged across all sectors, 
% power_pc, all angle data, sv_pc, ts_pc, svf
% Singular tabulated/struct data: cal, svf_param
% 2nd output (table):
% soundspeed for each ping
% absorption for each ping
% pulse length for each ping
% minrange and maxrange
% dr

%% Declaration of global variables
% ProcessedSampleData = struct('power_cw',[],'power_pc',[],'PhysAng_alongship',[],'PhysAng_athwartship',[],'sv_pc',[], ...
%     'ts_pc',[],'sv_cw',[],'ts_cw',[],'dr',[],'minrange',[],'maxrange',[],'startTVG',[],'absorptionCoeff',[],...
%     'svf',[],'f',[],'pulse_length',[],'frequency_center',[],'frequency_nominal',[],'Gain_nominal_dB',[], 'Gain_fc_dB',[],...
%     'BeamWidth_Minor_nominal',[],'BeamWidth_Major_nominal',[],'BeamWidth_Minor_fc',[],'BeamWidth_Major_fc',[]);

ProcessedSampleData = struct('Y_pc_avg',[],'power_pc',[],'PhysAng_alongship',[],'PhysAng_athwartship',[],'sv_pc',[], ...
    'ts_pc',[],'cal',[],'svf_param',[],'range',[]);

% tabledata = struct('Y_pc_avg',[],'power_pc',[],'PhysAng_alongship',[],'PhysAng_athwartship',[],'sv_pc',[], ...
%     'ts_pc',[],'cal',[],'svf_param',[]);

frequencyCenter=(ParameterData(1).FrequencyStart + ParameterData(1).FrequencyEnd)/2;
fs = 1.5e6; %Default value taken from Simrad manuaal
nominalTransducerImpedance  = 75; %Nominal value sourced from Demer 2017, pyEcholab [EK80.py], and echopype [cal_params.py] (2024)
%wbtImpedanceRx = wbt_impedance; 
cal = calParmEK80(transdata_ch,ParameterData,ChannelData,frequencyCenter);
cal.wbtImpedanceRx = wbt_impedance;
wbtImpedanceRx = wbt_impedance;

%% Create range vector for subsetting in EK80 range
% Environment sound speed is unique for each ping!
% 2026-5-11:This is to subset based on range subset! Not Implemented!

nSamples = min([SampleData.maxCount]);

% If sample size not equal across range then subset based on min sample size
if nSamples < max([SampleData.maxCount])
    SampleData = subsetSamples(SampleData,'complexsamples',100);
end
rangeVector = (0:nSamples-1)'*ParameterData(1).SampleInterval.*([EnvironmentData.SoundSpeed].')/2;
ProcessedSampleData.range = rangeVector;

%rsub_idx = rangeVector >= range_subset(1) & rangeVector < range_subset(2);
%idx_range_min = min(all(rsub_idx,2));
%idx_range_max = min(all(rsub_idx,2));
%% Create Transmit Signal, Pulse Compressed Signals, and Power and Angle for BB and CW (complex data)
% Only using the first value of SampleData since assumed similar
transmitSignal = CreateTransmitSignal(FilterData, ParameterData, fs); %y_mf
cal.txSignal = transmitSignal;

% Weird issue with EA440 data samples which are inverted to EK80. Transpose so similar to EK80.
% 2026-5-11: I think this only works with single ping data
% if size(SampleData(1).complexsamples,1) < size(SampleData(1).complexsamples,2) 
%     SampleData.complexsamples = transpose(SampleData.complexsamples);
% end

% Pre-allocate outputs for speed
nSectors = min(size(SampleData(1).complexsamples)); % Use min 
cal.nSectors = nSectors;
Y_pc = zeros(max(size(SampleData(1).complexsamples)),nSectors);
Y_pc_avg = zeros(max(size(SampleData(1).complexsamples)),length(SampleData));
PhysAng_alongship = zeros(size(Y_pc_avg));
PhysAng_athwartship = zeros(size(Y_pc_avg));
Y_pc_file = cell(1,length(SampleData));

s_idx = length(transmitSignal);
for jj=1:length(SampleData)
    
    % This is to fix a weird EA440 issue where the samples are inverted compared to standard EK80
    if size(SampleData(1).complexsamples,1) < size(SampleData(1).complexsamples,2)
        temp_samples = transpose(SampleData(jj).complexsamples);
    else
        temp_samples = SampleData(jj).complexsamples;
    end

    for ii = 1:nSectors
        tmp = conv(temp_samples(:,ii),conj(flipud(transmitSignal)),"full")/(norm(transmitSignal)^2);
        Y_pc(:,ii) = tmp(s_idx:end);
    end
    Y_pc_file{jj} = Y_pc;
    Y_pc_avg(:,jj) = sum(Y_pc,2)/nSectors;
    [PhysAng_alongship(:,jj), PhysAng_athwartship(:,jj)] = EK80_computeAngle(Y_pc,ChannelData,nSectors,cal);
end

% Results are consistent for each column/ping
power_pc = nSectors*(abs(Y_pc_avg)/(2*sqrt(2))).^2 * ((wbtImpedanceRx+nominalTransducerImpedance)/wbtImpedanceRx)^2 * 1/nominalTransducerImpedance;
power_pc(power_pc == 0) = 1e-20;

% Saving into output struct
ProcessedSampleData.Y_pc_avg = Y_pc_avg;
ProcessedSampleData.power_pc = power_pc;
ProcessedSampleData.PhysAng_alongship = PhysAng_alongship;
ProcessedSampleData.PhysAng_athwartship = PhysAng_athwartship;

%% Calculate Effective Pulse length for BB and CW
%Fliplr fixed feb 28th 2020, check effective pulse length
% ParameterData.SampleInterval = 1/fs_decimated !!!!!!
fs_dec = fs; 
for ii = 1:length(FilterData)
    fs_dec = fs_dec/FilterData(ii).Decimation; %Or equivalent to fs_dec = 1/ParameterData.SampleInterval; from pyEcholab (simrad_signal_proc.py line 125)
end

autoCorrelationTransmitSignal = conv(transmitSignal,flipud(conj(transmitSignal)))/norm(transmitSignal)^2;
autoCorrelationTransmitSignalPower = abs(autoCorrelationTransmitSignal).^2;
effectivePulselLength  = sum(autoCorrelationTransmitSignalPower) / (max(autoCorrelationTransmitSignalPower)*fs_dec);
%effectivePulselLength  = ParameterData.SampleInterval * sum(autoCorrelationTransmitSignalPower) / max(autoCorrelationTransmitSignalPower);

transmitSignalPower = abs(transmitSignal).^2;
% 2026-5-6 Only use the first Sample Interval since it will not change across channel!
effectivePulselLength_CW  = ParameterData(1).SampleInterval * sum(transmitSignalPower) / max(transmitSignalPower);

%% Create range vector and calculate TVG gain and BB Absorption
% Environment sound speed is unique for each ping!
%nSamples = length(ProcessedSampleData.power_pc);
%rangeVector = (0:nSamples-1)'*ParameterData(1).SampleInterval.*([EnvironmentData.SoundSpeed].')/2;

absorptionCoefficients = EstimateAbsorptionCoefficients(EnvironmentData,frequencyCenter);

% apply TVG range correction according to Echoview, echopype, and pyEcholab: r_corr = r_uncorr - c*tau/4
if TVG_range_correction == 1
    % Assumed Pulse duration does not vary!
    range_TVG = rangeVector - ([EnvironmentData.SoundSpeed].')*ParameterData(1).PulseDuration/4;
    range_TVG(range_TVG<0) = 0; %zero out negative values
else
    range_TVG = rangeVector;
end

startTvg = 1; %All values with ranges under 1m will be zero (log10(1) = 0)

idx_rtvg = range_TVG < startTvg;
tvg20 = 20*log10(range_TVG) + 2*range_TVG.* absorptionCoefficients;
tvg40 = 40*log10(range_TVG) + 2*range_TVG.* absorptionCoefficients;
tvg20(idx_rtvg) = 0;
tvg40(idx_rtvg) = 0;

%% Sv(f) calculation: Need to Check and Clarify
% Works for multiple pings!
%[f,svf]= EstimateSvf_v2(ChannelData,ParameterData,EnvironmentData,transmitSignal,Y_pc_avg,rangeVector);

svf_param.binOverlap = 0.5;
svf_param.NFreq = 1000;
svf_param.range_interval = [0 100];
[f,~,~,svf]= EstimateSvf_v2(cal, ParameterData, EnvironmentData, Y_pc_avg, rangeVector,...
    svf_param.binOverlap, svf_param.NFreq, svf_param.range_interval,[]);

ProcessedSampleData.svf=svf;
ProcessedSampleData.f=f;
ProcessedSampleData.svf_param = svf_param;
%% Sv(t) and TS (t) for CW and FM
peakGain_lin = 10^(cal.gain_nom/10); %lin form of nominal gain
wavelength_fc = (EnvironmentData.SoundSpeed/frequencyCenter);
wavelength_nom = (EnvironmentData.SoundSpeed/cal.freq_nom);
effBAngle_fc_lin = 10^(cal.effBAngle_fc_log/10); %lin form of 2 way beam angle
effBAngle_nom_lin = 10^(cal.effBAngle_nom_log/10);
beamW_minor_fc_lin = cal.beamW_minor_fc_lin;
beamW_major_fc_lin = cal.beamW_major_fc_lin;

% Gain compensation for BB mode based on Lars Code (CRIMAC) and echopype [calibrate_ek.py line 459]
fac_along = (abs(-cal.angleOff_minor_nom)/(beamW_minor_fc_lin/2))^2;
fac_athwart = (abs(-cal.angleOff_major_nom)/(beamW_major_fc_lin/2))^2;
B_theta_phi_m = 0.5 * 6.0206 * (fac_along + fac_athwart - 0.18 * fac_along * fac_athwart); %log form
gain_BB = cal.gain_fc_log - B_theta_phi_m;
%gain_BB_lin = 10^(gain_BB/10);
%gain_BB_lin = 10^((cal.gain_nom+10*log10(frequencyCenter/cal.freq_nom))/10);

% For debug
%{
AA = 10*log10(ProcessedSampleData.power_pc); %same
BB = tvg40; %different for last ping
CC = ones(nSamples,1)*(10*log10(([ParameterData.TransmitPower]).*(wavelength_fc.').^2/(16*pi^2))); %difflast ping
DD = 2*gain_BB; %same
EE = tvg20; %diff last ping
FF = ones(nSamples,1)*(10*log10(([EnvironmentData.SoundSpeed].')*effectivePulselLength*effBAngle_fc_lin/2)); %diff last ping
out = {AA '10*log10(ProcessedSampleData.power_pc )';BB 'tvg40';CC '10*log10(ParameterData.TransmitPower*wavelength_fc^2/(16*pi^2))';...
    DD '2*gain_BB';EE 'tvg20';FF '10*log10(EnvironmentData.SoundSpeed*effectivePulselLength*effBAngle_fc_lin/2)'};
%}

% TS
% Assume transmit power does not change!
ProcessedSampleData.ts_pc = 10*log10(ProcessedSampleData.power_pc ) + ...
    tvg40 - ones(nSamples,1)*(10*log10(([ParameterData.TransmitPower]).*(wavelength_fc.').^2/(16*pi^2))) - 2*gain_BB; 

% ProcessedSampleData.ts_cw = 10*log10(ProcessedSampleData.power) + tvg40...
%     - 10*log10(peakGain_lin^2*ParameterData.TransmitPower*wavelength_nom^2/(16*pi^2)); 

%ezimagesc(1:length(ParameterData),rangeVector(:,1),ProcessedSampleData.ts_pc,'EK60',[-80 -40])

% Sv 
%sv_temp = AA + EE - CC - FF - DD;
ProcessedSampleData.sv_pc = 10*log10(ProcessedSampleData.power_pc) + tvg20...
    - ones(nSamples,1)*(10*log10(([ParameterData.TransmitPower]).*(wavelength_fc.').^2/(16*pi^2)))...
    - ones(nSamples,1)*(10*log10(([EnvironmentData.SoundSpeed].')*effectivePulselLength*effBAngle_fc_lin/2))...
    - 2*gain_BB;

% ProcessedSampleData.sv_cw = 10*log10(ProcessedSampleData.power) + tvg20...
%     - 10*log10(peakGain_lin^2*ParameterData.TransmitPower*wavelength_nom^2/(16*pi^2))...
%     - 10*log10(EnvironmentData.SoundSpeed*effectivePulselLength_CW*effBAngle_nom_lin/2)...
%     - 2*cal.SaCorr_log;

%temp_var = [ProcessedSampleData.sv_pc];
%ezimagesc(1:size(temp_var,2),1:size(temp_var,1),temp_var,'EK60',[-80 -40])
%% Append Neccesary Values

% 2nd output (table):
% soundspeed for each ping
% absorption for each ping
% pulse length for each ping
% minrange and maxrange

tabledata = table([EnvironmentData.SoundSpeed],absorptionCoefficients.',[ParameterData.PulseDuration].',...
    diff(rangeVector(1:2,:)).',min(rangeVector).',max(rangeVector).');
tabledata.Properties.VariableNames = {'soundspeed','absorptionCoeff','pulse_length','dr','minrange','maxrange'};   

ProcessedSampleData.cal = cal;

    function S = subsetSamples(S,fieldN,samplesize)
        for k = 1:numel(S)
            S(k).(fieldN) = S(k).(fieldN)(1:samplesize, :);
        end
    end

end