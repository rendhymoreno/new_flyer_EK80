% New Function for processing NOAA EK80 Ship data that is CW
function [ProcessedSampleData] = EstimateEK80CW(SampleData,transdata_ch,ChannelData, ParameterData, EnvironmentData, TVG_range_correction)
%% Declaration of global variables
ProcessedSampleData = struct('PhysAng_alongship',[],'PhysAng_athwartship',[], ...
    'sv_cw',[],'ts_cw',[],'dr',[],'minrange',[],'maxrange',[],'startTVG',[],'absorptionCoeff',[],...
    'f',[],'pulse_length',[],'Gain_nominal_dB',[],'BeamWidth_Minor_nominal',[],'BeamWidth_Major_nominal',[]);

%frequencyCenter=(ParameterData(1).FrequencyStart + ParameterData(1).FrequencyEnd)/2;
frequencyCenter=(ParameterData(1).FrequencyStart + ParameterData(1).FrequencyEnd)/2;
ProcessedSampleData.f = frequencyCenter;
cal = calParmEK80(transdata_ch,ParameterData,ChannelData,frequencyCenter);

% Will use these for calculating physical angles
angleS_minor_fc_lin = 10^(cal.angleS_minor_fc_log/10); %Linear alongship angle sensitivity
angleS_major_fc_lin = 10^(cal.angleS_major_fc_log/10); %Linear athwartship angle sensitivity

%% Create Power and Angle for CW

%if strcmp(ChannelData.BeamType,'1') && (nSectors==4) %beam type = 1 / 70 kHz transducer
%
%end

%% Create range vector and calculate TVG gain and BB Absorption
nSamples = length(SampleData.power_cw);
rangeVector = (0:nSamples-1)'*ParameterData.SampleInterval*EnvironmentData.SoundSpeed/2;
absorptionCoefficients = EstimateAbsorptionCoefficients(EnvironmentData,frequencyCenter);
%absorptionCoefficients = 0.01047;
% apply TVG range correction according to Echoview, echopype, and pyEcholab: r_corr = r_uncorr - c*tau/4
if TVG_range_correction == 1
    range_TVG = rangeVector - EnvironmentData.SoundSpeed*ParameterData.PulseDuration/4;
    range_TVG(range_TVG<0) = 0; %zero out negative values
else
    range_TVG = rangeVector;
end

startTvg = 1; %All values with ranges under 1m will be zero (log10(1) = 0)
tvg20 = zeros(length(range_TVG), 1);
tvg40 = zeros(length(range_TVG), 1);

for index = 1:length(range_TVG)
    if(range_TVG(index) > startTvg)
        tvg20(index) = 20*log10(range_TVG(index)) + 2*absorptionCoefficients*range_TVG(index);
        tvg40(index) = 40*log10(range_TVG(index)) + 2*absorptionCoefficients*range_TVG(index);
    else
        tvg20(index) = 0;
        tvg40(index) = 0;
    end
end


%% Sv(t) and TS (t) for CW and FM
peakGain_lin = 10^(cal.gain_nom/10); %lin form of nominal gain
%wavelength_fc = (EnvironmentData.SoundSpeed/frequencyCenter);
wavelength_nom = (EnvironmentData.SoundSpeed/cal.freq_nom);
%effBAngle_fc_lin = 10^(cal.effBAngle_fc_log/10); %lin form of 2 way beam angle
effBAngle_nom_lin = 10^(cal.effBAngle_nom_log/10);
beamW_minor_fc_lin = cal.beamW_minor_fc_lin;
beamW_major_fc_lin = cal.beamW_major_fc_lin;

% Gain compensation for BB mode based on Lars Code (CRIMAC) and echopype [calibrate_ek.py line 459]
fac_along = (abs(-cal.angleOff_minor_nom)/(beamW_minor_fc_lin/2))^2;
fac_athwart = (abs(-cal.angleOff_major_nom)/(beamW_major_fc_lin/2))^2;
B_theta_phi_m = 0.5 * 6.0206 * (fac_along + fac_athwart - 0.18 * fac_along * fac_athwart); %log form
%gain_BB = cal.gain_fc_log - B_theta_phi_m;
%gain_BB_lin = 10^(gain_BB/10);
%gain_BB_lin = 10^((cal.gain_nom+10*log10(frequencyCenter/cal.freq_nom))/10);

% TS
ProcessedSampleData.ts_cw = [SampleData.power_cw] + tvg40...
    - 10*log10(peakGain_lin^2*ParameterData.TransmitPower*wavelength_nom^2/(16*pi^2)); 

% Sv    
ProcessedSampleData.sv_cw = [SampleData.power_cw] + tvg20...
    - 10*log10(peakGain_lin^2*ParameterData.TransmitPower*wavelength_nom^2/(16*pi^2))...
    - 10*log10(EnvironmentData.SoundSpeed*(ParameterData.PulseDuration)*effBAngle_nom_lin/2)...
    - 2*cal.SaCorr_log;

%% Append Neccesary Values
ProcessedSampleData.absorptionCoeff=absorptionCoefficients;
ProcessedSampleData.startTVG=startTvg;
ProcessedSampleData.dr=diff(rangeVector(1:2));
ProcessedSampleData.minrange=min(rangeVector);
ProcessedSampleData.maxrange=max(rangeVector);
ProcessedSampleData.pulse_length = ParameterData.PulseDuration;
ProcessedSampleData.frequency_center = frequencyCenter;
ProcessedSampleData.frequency_nominal = cal.freq_nom;
ProcessedSampleData.Gain_nominal_dB = cal.gain_nom;
ProcessedSampleData.BeamWidth_Minor_nominal = cal.beamW_minor_nom;
ProcessedSampleData.BeamWidth_Major_nominal = cal.beamW_major_nom;
ProcessedSampleData.sample_interval = ParameterData.SampleInterval;