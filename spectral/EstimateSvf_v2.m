% May 11 2026 -- RMS
% Make 
% function [f,svf] = EstimateSvf(ChannelData,PingData,ProcessedSampleData,svfParameters)
% This can be operated after parsing!!
% Dependencies:
% cal ~ remove ChannelData!
% wbtImpedanceRx (From transceiver);
% ParameterData (for freq start&end, pulse_duration, sample_interval, tx power)
% EnvironmentData (soundspeed for attenuation and calculating wavelen)
% txSignal
% Y_pc_avg (averaged across all channels)
% nsectors!
% range_vector (NxM)
% FFT Inputs:
% binOverlap  = 0.5;
% NFreq    = 500;
% minRange=5;
% maxRange=100; 

function [f,sv_range,svf_spec,svf_psd] = EstimateSvf_v2(cal, ParameterData, EnvironmentData, Y_pc_avg, ...
    range_vector, binOverlap, NFreq, range_interval, outOpt)

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

% Settings
if ~isempty(outOpt) & (strcmp(outOpt,'spectrogram')||strcmp(outOpt,'spec'))
    compute_spec = true;
else
    compute_spec = false;
end

% Global vars
minRange=range_interval(1);
maxRange=range_interval(end); 
nSectors = cal.nSectors;

% Calibration settings
nominalTransducerImpedance  = 75;
fNom = cal.freq_nom; %cal.freq_nom
psiNom = 10^(cal.effBAngle_nom_log/10); %linear form of cal.effBAngle_nom_log
gainNom = 10^(cal.gain_nom/10); %linear form of cal.gain_nom

% These values are all singular!
samplingFrequency = 1/ParameterData(1).SampleInterval; %fs_dec, only one value! 
f = linspace(cal.freq_min,cal.freq_max,NFreq)';
psi_f = psiNom * (fNom./f).^2; %Scaled to freq vector
gain_f = gainNom * (f./fNom).^2; %Scaled to freq vector

% matched filter convolutor
transmitAuto = conv(cal.txSignal,flipud(conj(cal.txSignal)))/norm(cal.txSignal)^2;
nTransmitAutoSamples = length(transmitAuto);

soundSpeed = EnvironmentData.SoundSpeed;
absorptionCoefficients = EstimateAbsorptionCoefficients(EnvironmentData,f); %(500x139)
lambda = soundSpeed'./f;
txPower = [ParameterData.TransmitPower];

sampleRange = ParameterData(1).SampleInterval*soundSpeed/2;
minSample = floor(minRange./sampleRange)+2;
maxSample = floor(maxRange./sampleRange)+2;

nBinSamples = pow2(ceil(log2(max(floor(2*[ParameterData.PulseDuration]*samplingFrequency), nTransmitAutoSamples))));
binTime = nBinSamples/samplingFrequency;
nSamplesOverlap = floor(binOverlap*nBinSamples);
windowFunction = cell2mat(arrayfun(@(x) hann(x),nBinSamples,'UniformOutput',false));
windowFunctionNorm = windowFunction./(vecnorm(windowFunction,2)./sqrt(nBinSamples));

nFFT = nBinSamples;

fftTxAutoTmp = cell2mat(arrayfun(@(x) fft(transmitAuto,x),nFFT,'UniformOutput',false)); 
fftTxAuto = FrequencyTransfer(fftTxAutoTmp,samplingFrequency,f); %size(500x1)
svRange = range_vector;

%windowedDataMat = [];
%prxWindows = [];
%svfWindow = NaN(length(f),length(soundSpeed));
%svf_psd = NaN(length(f),length(soundSpeed));
%svf = cell(1,length(soundSpeed));

for ii=1:length(soundSpeed)
    % The problem now is that this reads only one "ping".
    %pulseCompressedData = Y_pc_avg{ii};
    % This seems to only require averaged Y_pc????
    %nSectors            = min(size(pulseCompressedData,2));
    %complexSumSpread    = sum(pulseCompressedData,2)/nSectors .* svRange;

    %pulseCompressedData = Y_pc_avg(:,ii);
    complexSumSpread    = Y_pc_avg .* svRange;
    svfPingSum          = [];
    nBins               = 0;
    binStartSample      = minSample(ii);
    binStopSample       = binStartSample + nBinSamples(ii)-1;
    lastBin = false;
    binStopSamplefile = binStopSample;

    while (~lastBin)
        nBins = nBins+1;

        if (binStopSamplefile < maxSample(ii))
            temp_complexSamples = complexSumSpread(:,ii);
            complexSamples  = temp_complexSamples(binStartSample:binStopSamplefile);
            windowedData    = complexSamples.*windowFunctionNorm(:,ii);
        else
            binStopSamplefile                       = maxSample(ii);
            lastBin                            = true;
            temp_complexSamples = complexSumSpread(:,ii);
            complexSamplesTmp                   = temp_complexSamples(binStartSample:binStopSamplefile);
            nLastBinSamples                     = length(complexSamplesTmp);
            binTime(ii)                            = nLastBinSamples/samplingFrequency;

            windowFunctiontmp                      = hann(nLastBinSamples);
            windowFunctionNormtmp                  = windowFunctiontmp./(norm(windowFunctiontmp,2)/sqrt(nLastBinSamples));
            windowedData                        = zeros(nBinSamples(ii),1);
            windowedData(1:nLastBinSamples)     = complexSamplesTmp.*windowFunctionNormtmp;
        end

        binCenterSample = binStartSample + floor((binStopSamplefile - binStartSample)/2);

        fftWindowTmp    = fft(windowedData,nFFT(ii));
        fftWindow       = FrequencyTransfer(fftWindowTmp,samplingFrequency,f );

        fftWindowNorm   = fftWindow./fftTxAuto;
        temp_svrange = svRange(:,ii);
        pfftWindow      = nSectors*(abs(fftWindowNorm)/(2*sqrt(2))).^2 * (1/nominalTransducerImpedance) * ...
            ((nominalTransducerImpedance+cal.wbtImpedanceRx)/cal.wbtImpedanceRx)^2;

        % This is the Sv(f) spectrogram
        if compute_spec
            svfWindow(:,nBins) = 10*log10(pfftWindow) + 2*absorptionCoefficients(:,ii).*temp_svrange(binCenterSample)...
                - 10*log10( txPower(ii) .* lambda(:,ii).^2 .* soundSpeed(ii) .* binTime(ii) .* psi_f .* gain_f.^2 ./ (32*pi^2) );

            if isempty(svfPingSum)
                svfPingSum = 10.^(svfWindow(:,nBins)/10);
            else
                svfPingSum = svfPingSum + 10.^(svfWindow(:,nBins)/10);
            end
            sv_range(nBins) = temp_svrange(binCenterSample);

        else
            % Only compute
            svfWindow = 10*log10(pfftWindow) + 2*absorptionCoefficients(:,ii).*temp_svrange(binCenterSample)...
                - 10*log10( txPower(ii) .* lambda(:,ii).^2 .* soundSpeed(ii) .* binTime(ii) .* psi_f .* gain_f.^2 ./ (32*pi^2) );

            if isempty(svfPingSum)
                svfPingSum = 10.^(svfWindow/10);
            else
                svfPingSum = svfPingSum + 10.^(svfWindow/10);
            end

        end

        binStartSample  = binStartSample + (nBinSamples(ii)-nSamplesOverlap(ii));
        binStopSamplefile   = binStartSample + nBinSamples(ii)-1;
        % binStartSample  = binStartSample + 1;
        % binStopSamplefile   = binStartSample + nBinSamples(ii)-1;

    end

    if compute_spec
        svf_spec{ii} = svfWindow;
    else
        svf_spec = [];
        sv_range = [];
    end

    svf_psd(:,ii) = 10*log10(svfPingSum /nBins); %Pingsum? This must be PSD spectrum!
            
        %{
        temp_svf = svf{139};
        figure()
        %imagesc(f/1000,sv_range,temp_svf.') %Spectrogram
        imagesc(1:139,f/1000,svf_psd.') %LTSA analogy
        axis tight
        clim([-80 -30])
        %}
end

end
    