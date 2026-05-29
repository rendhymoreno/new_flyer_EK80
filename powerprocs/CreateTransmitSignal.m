% function [transmitSignal] = CreateTransmitSignal(PingData)
% 2024 March: RMS normalized the ideal transmitted signal prior to filter
% and decimation following Andersen 2023 eq 3 pg 320
% 2026-4-9: Double check if convolution is full!

function [transmitSignal_norm] = CreateTransmitSignal(Filters, ParameterData, sampleFrequency)

%CREATETRANSMITSIGNAL Create EK80 transmit signal
%
% CALL: [transmitSignal] = CreateTransmitSignal(PingData)
%
% Inputs:
%   PingData        = 
%
% Outputs:
%   transmitSignal = 
%
% Description:
%
%
%
% Examples(s):
%   [transmitSignal] = CreateTransmitSignal(PingData)
%

% References:
%
%
% Created by Lars Nonboe Andersen
%
%
%
% Copyright (c) 2015 Kongsberg Maritime
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.
% ---------------------------------------------------------------------------

% narginchk(1,1);
% nargoutchk(0,1);

%sampleFrequency     = 1.5e6;
% sampleFrequency = 1/PingData.param(1).SampleInterval;
% Filters = PingData.filters;
% ParameterData   = PingData.param;

% Check if pulse duration varies across time!
pd_list = unique([ParameterData.PulseDuration]);

if any(size(pd_list) >1)
    % 2026-5-6: Not implemeneted for multiple PD!
    pulse_duration = pd_list;
    %idx_pd = ismember([ParameterData.PulseDuration], pd_list);
    %idx_pd = arrayfun(@(x) ismember(x,pd_list),[ParameterData.PulseDuration]);
else
    pulse_duration = pd_list;
    slope = unique([ParameterData.Slope]);
end

% Time vector
nSamples = floor(pd_list*sampleFrequency);
timeVector  = 1/sampleFrequency*(0:nSamples-1)';

%Ben
%  a = sqrt((ParameterData.TransmitPower/4) * (2*75));

% Shaping
nShapingSamples = floor(slope*nSamples);
windowFunction  = hann(2*nShapingSamples);
shapingWindow   = [windowFunction(1:nShapingSamples); ones(nSamples-2*nShapingSamples,1); windowFunction(nShapingSamples+1:end)];

transmitSignal = chirp(timeVector,ParameterData(1).FrequencyStart,pulse_duration,ParameterData(1).FrequencyEnd).*shapingWindow;
transmitSignal_norm = transmitSignal / max(transmitSignal);
%Ben
%  transmitSignal=a.*transmitSignal; 

% FPGA and PC Filters and decimation
% wvtool(transmitSignal)
for filterStage = 1:2
    %transmitSignal  = conv(transmitSignal,Filters(filterStage).FilterData);
    %transmitSignal  = downsample(transmitSignal,Filters(filterStage).Decimation);
    transmitSignal_norm  = conv(transmitSignal_norm,Filters(filterStage).FilterData); %2026-4-9: I think should be full? Previously was same!
    transmitSignal_norm  = downsample(transmitSignal_norm,Filters(filterStage).Decimation);
    
% wvtool(transmitSignal)
end
% wvtool(abs(transmitSignal))
end
