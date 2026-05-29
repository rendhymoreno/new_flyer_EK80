% function [f,svf] = EstimateSvf(ChannelData,PingData,ProcessedSampleData,svfParameters)

function [f,sv_range,svf] = RMS_EstimateSvf_2025113(ChannelData, ParameterData,wbtImpedanceRx,EnvironmentData, transmitSignal, pulseCompressedData,range_vector)


%ESTIMATESVF Estimate Sv(f) for a depth range
%
% CALL: [f,svf] = EstimateSvf(ChannelData,PingData,ProcessedSampleData,svfParameters)
%
% Inputs:
%   PingData         =
%   BasicProcessedData  = 
%   svfParameters       =
%
% Outputs:
%   svf = 
%
% Description:
%
%
%
% Examples(s):
%   [f,svf] = EstimateSvf(ChannelData,PingData,ProcessedSampleData,svfParameters)
%
% References:
%
%
% Created by Lars Nonboe Andersen
%
%
%
% Copyright (c) 2021 Kongsberg Maritime
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.
% ---------------------------------------------------------------------------

% narginchk(4,4);
% nargoutchk(0,2);

% Setttings

binOverlap  = 0.5;

nFrequencyPoints    = 1000;

% minRange  = svfParameters.minRange;
% maxRange  = svfParameters.maxRange;
minRange=0;
maxRange=70; 

% WBT

nominalTransducerImpedance  = 75;
% wbtImpedanceRx              = ChannelData.Impedance;
%wbtImpedanceRx              = 5400; %10800, but 120kHz is 5400

TransducerData      = ChannelData;
% EnvironmentData     = PingData.EnvironmentData;
% ParameterData       = PingData.ParameterData;

fNom            = str2num(TransducerData.Frequency);
psiNom          = 10^(str2num(TransducerData.EquivalentBeamAngle)/10);
gainTable       = double(TransducerData.Gain);
gainNom         = 10^(gainTable(end)/10);

samplingFrequency   = 1/ParameterData(1).SampleInterval;
f                   = linspace(ParameterData(1).FrequencyStart,ParameterData(1).FrequencyEnd,nFrequencyPoints)';

% if ~isfield(TransducerData,'Calibration')
%     TransducerData.Calibration = [];
% end

psi_f   = psiNom * (fNom./f).^2;
% if isempty(TransducerData.CalibrationData)
    gain_f = gainNom * (f./fNom).^2;
% else
%     CalibrationParameters = InterpolateCalibrationParameters(ChannelData.Transducer.CalibrationData,f);
%     gain_f  = 10.^(CalibrationParameters.gain/10);
% end

% transmitSignal          = ProcessedSampleData.transmitSignal;
transmitAuto            = conv(transmitSignal,flipud(conj(transmitSignal)))/norm(transmitSignal)^2;
nTransmitAutoSamples    = length(transmitAuto);

soundSpeed              = EnvironmentData(1).SoundSpeed;
absorptionCoefficients  = EstimateAbsorptionCoefficients(EnvironmentData,f);
lambda                  = soundSpeed(1)./f;
txPower                 = ParameterData.TransmitPower;

% nSectors            = size(ProcessedSampleData.complexSamples.PC,2);
nSectors            = size(pulseCompressedData,2);

sampleRange         = ParameterData(1).SampleInterval*soundSpeed/2;
minSample           = 1; %floor(minRange/sampleRange)+2;
maxSample           = length(range_vector);%floor(maxRange/sampleRange)+2;

nBinSamples         = pow2(ceil(log2(max(floor(2*ParameterData(1).PulseDuration*samplingFrequency), nTransmitAutoSamples))));
binTime             = nBinSamples/samplingFrequency;

nSamplesOverlap     = floor(binOverlap*nBinSamples);

windowFunction      = hann(nBinSamples);
windowFunctionNorm  = windowFunction./(norm(windowFunction,2)/sqrt(nBinSamples));

nFFT                = nBinSamples;

fftTxAutoTmp        = fft(transmitAuto,nFFT);
fftTxAuto           = FrequencyTransfer( fftTxAutoTmp,samplingFrequency,f );

% svRange             = ProcessedSampleData.svRange;
svRange=range_vector; 
% complexSumSpread    = sum(ProcessedSampleData.complexSamples.PC,2)/nSectors .* svRange;
complexSumSpread    = sum(pulseCompressedData,2)/nSectors .* svRange;

svfPingSum          = [];
nBins               = 0;

binStartSample      = minSample;
binStopSample       = binStartSample + nBinSamples-1;

lastBin = false;

windowedDataMat = [];
prxWindows = [];
svfWindows = [];

while (~lastBin)
    nBins = nBins+1;

    if (binStopSample < maxSample)
        complexSamples  = complexSumSpread(binStartSample:binStopSample);
        windowedData    = complexSamples.*windowFunctionNorm;
    else
        binStopSample                       = maxSample;
        lastBin                            = true;
        complexSamplesTmp                   = complexSumSpread(binStartSample:binStopSample);
        nLastBinSamples                     = length(complexSamplesTmp);
        binTime                             = nLastBinSamples/samplingFrequency;

        windowFunction                      = hann(nLastBinSamples);
        windowFunctionNorm                  = windowFunction./(norm(windowFunction,2)/sqrt(nLastBinSamples));
        windowedData                        = zeros(nBinSamples,1);
        windowedData(1:nLastBinSamples)     = complexSamplesTmp.*windowFunctionNorm;
    end 

    binCenterSample = binStartSample + floor((binStopSample - binStartSample)/2);

    fftWindowTmp    = fft(windowedData,nFFT);
    fftWindow       = FrequencyTransfer( fftWindowTmp,samplingFrequency,f );
    
    fftWindowNorm   = fftWindow./fftTxAuto;
    pfftWindow      = nSectors * (abs(fftWindowNorm)/(2*sqrt(2))).^2 * (1/nominalTransducerImpedance) * ( (nominalTransducerImpedance+wbtImpedanceRx)/wbtImpedanceRx )^2;
    svfWindow(:,nBins)       = 10*log10(pfftWindow) + 2*absorptionCoefficients.*svRange(binCenterSample) - 10*log10( txPower .* lambda.^2 .* soundSpeed .* binTime .* psi_f .* gain_f.^2 ./ (32*pi^2) );
    
    if isempty(svfPingSum)
        svfPingSum = 10.^(svfWindow(:,nBins)/10);
    else
        svfPingSum = svfPingSum + 10.^(svfWindow(:,nBins)/10);
    end
    
    
    %binStartSample  = binStartSample + (nBinSamples-nSamplesOverlap);
    binStartSample  = binStartSample + 1;
    binStopSample   = binStartSample + nBinSamples-1;
    sv_range(nBins) = svRange(binCenterSample);
end

svf = 10*log10(svfPingSum /nBins);

%% 
%{
figure()
imagesc(f/1000,sv_range,svfWindow')
axis tight
clim([-80 -30])
%}
end
    