function [ProcessedSampleData] = EstimateProcessedSampleData_doubletest_old(SampleData,ChannelData, ParameterData, FilterData, EnvironmentData)
% 'sprange',[],'svrange',[], 
% ProcessedSampleData = struct('power',[],'power_pc',[],'alongship',[],'athwartship',[],'sp',[],'sv',[], 'ts',[],'epl',[],'dr',[],'minrange',[],'maxrange',[]);
%ProcessedSampleData = struct('power_cw',[],'power_pc',[],'alongship',[],'athwartship',[],'sv_pc',[], 'ts_pc',[],'sv_cw',[], 'ts_cw',[],'dr',[],'minrange',[],'maxrange',[], 'roffset', [], 'epl', [],'epl_cw', [], 'powercal_pc', [],'powercal_cw', []);
ProcessedSampleData = struct('power_cw',[],'power_pc',[],'alongship',[],'athwartship',[],'sv_pc',[], 'ts_pc',[],'sv_cw',[], 'ts_cw',[],'dr',[],'minrange',[],'maxrange',[], 'roffset', [], 'epl', [],'epl_cw', [], 'startTVG', [],'absorptionCoeff', [],'svf', [], 'f', []);

frequencyCenter=(ParameterData(1).FrequencyStart + ParameterData(1).FrequencyEnd)/2;
nominalTransducerImpedance  = 75;
wbtImpedanceRx              = 10800;

%match transducer filter data
if(size(FilterData,1) > 1)
    if(contains(FilterData(1,1).ChannelID,ChannelData.TransducerName))
        FilterData=FilterData(1, 1:2);
    elseif(contains(FilterData(2,1).ChannelID,ChannelData.TransducerName))
        FilterData=FilterData(2,1:2);
    else
        disp('FilterData does not match channelID');
    end
end
transmitSignal = CreateTransmitSignal(FilterData, ParameterData, 1/ParameterData.SampleInterval);
% transmitSignal = transmitSignal/max(abs(transmitSignal));

nSectors = size(SampleData(1).complexsamples,2);
ProcessedSampleData.power = nSectors*(abs(double(sum(SampleData.complexsamples,2))/nSectors)/(2*sqrt(2))).^2 * ((wbtImpedanceRx+nominalTransducerImpedance)/wbtImpedanceRx)^2 * 1/nominalTransducerImpedance;
% ProcessedSampleData.power = double(pow); 
% ProcessedSampleData.power = 10*log10(ProcessedSampleDataata.power);

pulseCompressedData = conv2(flipud(conj(transmitSignal)),1,SampleData.complexsamples)/norm(transmitSignal)^2;
pulseCompressedData = pulseCompressedData(length(transmitSignal):end,:);
 

ProcessedSampleData.power_pc = nSectors*(abs(double(sum(pulseCompressedData,2)/nSectors))/(2*sqrt(2))).^2 * ((wbtImpedanceRx+nominalTransducerImpedance)/wbtImpedanceRx)^2 * 1/nominalTransducerImpedance;
% ProcessedSampleData.power_pc = double(power_pc); 
% power_pc=double(power_pc); 

if (nSectors==4)
    complexFore         = sum(pulseCompressedData(:,3:4),2)/2;
    complexAft          = sum(pulseCompressedData(:,1:2),2)/2;
    complexStarboard    = (pulseCompressedData(:,1) + pulseCompressedData(:,4))/2;
    complexPort         = sum(pulseCompressedData(:,2:3),2)/2;
    
    PowerAngleData.alongship    = angle( complexFore.*conj(complexAft)) *180/pi;
    PowerAngleData.athwartship  = angle( complexStarboard.*conj(complexPort)) *180/pi;
    
    ProcessedSampleData.alongship       = PowerAngleData.alongship  / (str2num(ChannelData.AngleSensitivityAlongship) *frequencyCenter/str2num(ChannelData.Frequency));
    ProcessedSampleData.athwartship     = PowerAngleData.athwartship  / (str2num(ChannelData.AngleSensitivityAthwartship) *frequencyCenter/str2num(ChannelData.Frequency));
% end
else 
    complexFore         = pulseCompressedData(:,3);
    complexAft          = sum(pulseCompressedData(:,1:2),2)/2;
    complexStarboard    = pulseCompressedData(:,2);
    complexPort         = pulseCompressedData(:,1);
    
    PowerAngleData.alongship    = angle( complexFore.*conj(complexAft)) *180/pi;
    PowerAngleData.athwartship  = angle( complexStarboard.*conj(complexPort)) *180/pi;
    
    ProcessedSampleData.alongship       = PowerAngleData.alongship  / (str2num(ChannelData.AngleSensitivityAlongship) *frequencyCenter/str2num(ChannelData.Frequency));
    ProcessedSampleData.athwartship     = PowerAngleData.athwartship  / (str2num(ChannelData.AngleSensitivityAthwartship) *frequencyCenter/str2num(ChannelData.Frequency));
end

%Fliplr fixed feb 28th 2020, check effective pulse length
autoCorrelationTransmitSignal = conv(transmitSignal,flipud(conj(transmitSignal)))/norm(transmitSignal)^2;
autoCorrelationTransmitSignalPower = (abs(autoCorrelationTransmitSignal).^2);
effectivePulselLength  = ParameterData.SampleInterval * sum(autoCorrelationTransmitSignalPower) / max(autoCorrelationTransmitSignalPower);

transmitSignalPower = abs(transmitSignal).^2;
effectivePulselLength_CW  = ParameterData.SampleInterval * sum(transmitSignalPower) / max(transmitSignalPower);

nSamples = length(ProcessedSampleData.power_pc);
rangeVector = (0:nSamples-1)'*ParameterData.SampleInterval*EnvironmentData.SoundSpeed/2;
absorptionCoefficients = EstimateAbsorptionCoefficients(EnvironmentData,frequencyCenter);
tvgDelay = ParameterData.PulseDuration * EnvironmentData.SoundSpeed/2;
startTvg = max(tvgDelay, 1);
tvg20 = zeros(length(rangeVector), 1);
tvg40 = zeros(length(rangeVector), 1);

tvg20RangeVector = rangeVector;

for index = 1:length(rangeVector)
    if(rangeVector(index) > startTvg)
        tvg20(index) = 20*log10(tvg20RangeVector(index)) + 2*absorptionCoefficients*tvg20RangeVector(index);
        tvg40(index) = 40*log10(rangeVector(index)) + 2*absorptionCoefficients*rangeVector(index);
    else
        tvg20(index) = 0;
        tvg40(index) = 0;
    end
end

gainTable = str2num(ChannelData.Gain);
gain=gainTable(end);
% peakgain = 10^((gain+20*log10(frequencyCenter/str2num(ChannelData.Frequency)))/10); 
peakgain = 26.5; 
gain =26.5;

% %SPECTRAL DATA
% n_multiple=10;
% nfft=1024;
% n_start=2000; 
% 
% auto_tx=conv(transmitSignal,flipud(conj(transmitSignal)))/norm(transmitSignal)^2;
% pc_rangecompd = tvg20RangeVector.*sum(pulseCompressedData,2)/nSectors;
% 
% n=size(auto_tx,1)*n_multiple;
% wind=hann(n);
% wind_adj=wind./(norm(wind)/sqrt(n))';
% power_n=pc_rangecompd(n_start:n_start+n-1,:);
% spectral=fft(power_n.*wind_adj,nfft);
% spectral= spectral./(fft(repelem(auto_tx, n_multiple), nfft));
% % spectral= spectral./(fft(repelem(abs(auto_tx), n_multiple), nfft));
% spectral(isinf(spectral))=[];
% spectral = abs(fft(spectral, nfft));
% sv_f=nSectors*(10.*log10(spectral)/(2*sqrt(2))).^2 * ((wbtImpedanceRx+nominalTransducerImpedance)/wbtImpedanceRx)^2 * 1/nominalTransducerImpedance;
% ProcessedSampleData.spectral_sv=sv_f- 10*log10(ParameterData.TransmitPower*(EnvironmentData.SoundSpeed/frequencyCenter)^2*EnvironmentData.SoundSpeed/(32*pi^2))...
%     - 2*(gain + 20*log10(frequencyCenter/str2num(ChannelData.Frequency))) - 10*log10(effectivePulselLength) - (str2num(ChannelData.EquivalentBeamAngle) + 20*log10(str2num(ChannelData.Frequency)/frequencyCenter));
% spectral = spectral/sum(spectral);
% ProcessedSampleData.spectral = spectral;

[f,svf]= EstimateSvf(ChannelData, ParameterData,EnvironmentData, transmitSignal, pulseCompressedData,rangeVector);
ProcessedSampleData.svf=svf;
ProcessedSampleData.f=f;

% TS
ProcessedSampleData.ts_pc = 10*log10(ProcessedSampleData.power_pc ) + tvg40 - 10*log10(peakgain^2 * ParameterData.TransmitPower*(EnvironmentData.SoundSpeed/frequencyCenter)^2/(16*pi^2)); 
ProcessedSampleData.ts_cw = 10*log10(ProcessedSampleData.power) + tvg40 - 10*log10(peakgain^2 * ParameterData.TransmitPower*(EnvironmentData.SoundSpeed/frequencyCenter)^2/(16*pi^2)); 
% Sv    
ProcessedSampleData.sv_pc = 10*log10(ProcessedSampleData.power_pc )  + tvg20 - 10*log10(ParameterData.TransmitPower*(EnvironmentData.SoundSpeed/frequencyCenter)^2*EnvironmentData.SoundSpeed/(32*pi^2))...
    - 2*(gain + 20*log10(frequencyCenter/str2num(ChannelData.Frequency))) - 10*log10(effectivePulselLength) - (str2num(ChannelData.EquivalentBeamAngle) + 20*log10(str2num(ChannelData.Frequency)/frequencyCenter));
ProcessedSampleData.sv_cw = 10*log10(ProcessedSampleData.power )  + tvg20 - 10*log10(ParameterData.TransmitPower*(EnvironmentData.SoundSpeed/frequencyCenter)^2*EnvironmentData.SoundSpeed/(32*pi^2))...
    - 2*(gain + 20*log10(frequencyCenter/str2num(ChannelData.Frequency))) - 10*log10(effectivePulselLength_CW) - (str2num(ChannelData.EquivalentBeamAngle) + 20*log10(str2num(ChannelData.Frequency)/frequencyCenter));

%ProcessedSampleData.powercal_pc =  10*log10(ProcessedSampleData.power_pc )   - 10*log10(ParameterData.TransmitPower*(EnvironmentData.SoundSpeed/frequencyCenter)^2*EnvironmentData.SoundSpeed/(32*pi^2))...
 %   - 2*(gain + 20*log10(frequencyCenter/str2num(ChannelData.Frequency))) - 10*log10(effectivePulselLength) - (str2num(ChannelData.EquivalentBeamAngle) + 20*log10(str2num(ChannelData.Frequency)/frequencyCenter));
%ProcessedSampleData.powercal_cw = 10*log10(ProcessedSampleData.power )   - 10*log10(ParameterData.TransmitPower*(EnvironmentData.SoundSpeed/frequencyCenter)^2*EnvironmentData.SoundSpeed/(32*pi^2))...
 %   - 2*(gain + 20*log10(frequencyCenter/str2num(ChannelData.Frequency))) - 10*log10(effectivePulselLength_CW) - (str2num(ChannelData.EquivalentBeamAngle) + 20*log10(str2num(ChannelData.Frequency)/frequencyCenter));

 ProcessedSampleData.absorptionCoeff=absorptionCoefficients;
 ProcessedSampleData.startTVG=startTvg;


ProcessedSampleData.power_pc=10*log10(ProcessedSampleData.power_pc); 
ProcessedSampleData.power_cw = 10*log10(ProcessedSampleData.power); 

ProcessedSampleData.epl = effectivePulselLength; 
ProcessedSampleData.epl_cw = effectivePulselLength_CW; 
ProcessedSampleData.dr=diff(rangeVector(1:2));
ProcessedSampleData.minrange=min(rangeVector);
ProcessedSampleData.maxrange=max(rangeVector);
ProcessedSampleData.roffset = tvgDelay/2;
















%
%
%
%
% if (~isempty(SampleData))
%
%     % Power and Angle
%
%     if strcmp(ChannelData.TransceiverType,'GPT')
%         % GPT
%
%         % Estimate power and angle
%         PowerAngleData.power        = SampleData.power;
%         PowerAngleData.alongship    = SampleData.alongship;
%         PowerAngleData.athwartship  = SampleData.athwartship;
%
%     else
%         % WBT
%
%         nominalTransducerImpedance  = 75;
%         wbtImpedanceRx              = 5e3;
%
%         transmitSignal = CreateTransmitSignal(PingData);
%
%         % Perform pulse compression if FM
%         if (~ParameterData.pulseForm)
%             % CW
%             complexSamples = SampleData.complexSamples;
%         else
%             % FM
%             pulseCompressedData = conv2(flipud(conj(transmitSignal)),1,PingData.SampleData.complexSamples)/norm(transmitSignal)^2;
%             pulseCompressedData = pulseCompressedData(length(transmitSignal):end,:);
%
%             complexSamples  = pulseCompressedData;
%         end
%
%         % Estimate power and angle
%         nSectors = size(SampleData.complexSamples,2);
%         PowerAngleData.power = nSectors*(abs(sum(complexSamples,2)/nSectors)/(2*sqrt(2))).^2 * ((wbtImpedanceRx+nominalTransducerImpedance)/wbtImpedanceRx)^2 * 1/nominalTransducerImpedance;
%
%         if (nSectors==4)
%             complexFore         = sum(complexSamples(:,3:4),2)/2;
%             complexAft          = sum(complexSamples(:,1:2),2)/2;
%             complexStarboard    = (complexSamples(:,1) + complexSamples(:,4))/2;
%             complexPort         = sum(complexSamples(:,2:3),2)/2;
%
%             PowerAngleData.alongship    = angle( complexFore.*conj(complexAft)) *180/pi;
%             PowerAngleData.athwartship  = angle( complexStarboard.*conj(complexPort)) *180/pi;
%         elseif (nSectors==1)
%             % Single beam
%             PowerAngleData.alongship    = 0*complexSamples;
%             PowerAngleData.athwartship  = 0*complexSamples;
%         else
%             error('Sector configuration not supported')
%         end
%
%     end
%
%     ProcessedSampleData
%
%     % Sp and Sv
%
%     % Estimate effective pulse duration
%     if strcmp(ChannelData.TransceiverType,'GPT')
%         % GPT
%
%         effectivePulselLength = ParameterData.pulseLength;
%     else
%         %WBT
%
%         if (~PingData.ParameterData.pulseForm)
%             % CW
%             transmitSignalPower = abs(transmitSignal).^2;
%             effectivePulselLength  = ParameterData.sampleInterval * sum(transmitSignalPower) / max(transmitSignalPower);
%         else
%             autoCorrelationTransmitSignal = conv(transmitSignal,flipud(conj(transmitSignal)))/norm(transmitSignal)^2;
%             autoCorrelationTransmitSignalPower = (abs(autoCorrelationTransmitSignal).^2);
%             effectivePulselLength  = ParameterData.sampleInterval * sum(autoCorrelationTransmitSignalPower) / max(autoCorrelationTransmitSignalPower);
%         end
%     end
%
%     nSamples = length(PowerAngleData.power);
%     rangeVector = (0:nSamples-1)'*ParameterData.sampleInterval*EnvironmentData.soundSpeed/2;
%
%     absorptionCoefficients = EstimateAbsorptionCoefficients(EnvironmentData,ParameterData.frequencyCenter);
%
%     % Do not apply TVG before transmit pulse has finished and range > 1 m
%     tvgDelay = ParameterData.pulseLength * EnvironmentData.soundSpeed/2;
%     startTvg = max(tvgDelay, 1);
%     tvg20 = zeros(length(rangeVector), 1);
%     tvg40 = zeros(length(rangeVector), 1);
%     if (~PingData.ParameterData.pulseForm)
%         % CW
%         tvg20RangeVector = rangeVector - EnvironmentData.soundSpeed*ParameterData.pulseLength/4;
%     else
%         % FM
%             tvg20RangeVector = rangeVector;
%     end
%
%     for index = 1:length(rangeVector)
%         if(rangeVector(index) > startTvg)
%             tvg20(index) = 20*log10(tvg20RangeVector(index)) + 2*absorptionCoefficients*tvg20RangeVector(index);
%             tvg40(index) = 40*log10(rangeVector(index)) + 2*absorptionCoefficients*rangeVector(index);
%         else
%             tvg20(index) = 0;
%             tvg40(index) = 0;
%         end
%     end
%
%     pulseLengthTable = str2num(ChannelData.PulseLength);
%     gainTable       = str2num(ChannelData.Transducer.Gain);
%     if (~PingData.ParameterData.pulseForm)
%         % CW
%         pulseLengthIndex = dsearchn(pulseLengthTable,ParameterData.pulseLength);
%         gain = gainTable(pulseLengthIndex);
%     else
%         % FM
%         gain = gainTable(end);
%     end
%
%     % Sp
%     sp = 10*log10(PowerAngleData.power)  + tvg40 - 10*log10(ParameterData.transmitPower*(EnvironmentData.soundSpeed/ParameterData.frequencyCenter)^2/(16*pi^2)) - 2*(gain + 20*log10(ParameterData.frequencyCenter/str2num(ChannelData.Transducer.Frequency)));
%
%     % Sv
%     sv = 10*log10(PowerAngleData.power)  + tvg20 - 10*log10(ParameterData.transmitPower*(EnvironmentData.soundSpeed/ParameterData.frequencyCenter)^2*EnvironmentData.soundSpeed/(32*pi^2)) - 2*(gain + 20*log10(ParameterData.frequencyCenter/str2num(ChannelData.Transducer.Frequency))) - 10*log10(effectivePulselLength) - (str2num(ChannelData.Transducer.EquivalentBeamAngle) + 20*log10(str2num(ChannelData.Transducer.Frequency)/ParameterData.frequencyCenter));
%
%
%     % Create ProcessedSampleData structure
%     ProcessedSampleData.range           = rangeVector;
%     ProcessedSampleData.power           = PowerAngleData.power;
%     ProcessedSampleData.alongship       = PowerAngleData.alongship  / (str2num(ChannelData.Transducer.AngleSensitivityAlongship) * ParameterData.frequencyCenter/str2num(ChannelData.Transducer.Frequency));
%     ProcessedSampleData.athwartship     = PowerAngleData.athwartship  / (str2num(ChannelData.Transducer.AngleSensitivityAthwartship) * ParameterData.frequencyCenter/str2num(ChannelData.Transducer.Frequency));
%     ProcessedSampleData.spRange         = rangeVector;
%     ProcessedSampleData.sp              = sp;
%     ProcessedSampleData.svRange         = tvg20RangeVector;
%     ProcessedSampleData.sv              = sv;
% end