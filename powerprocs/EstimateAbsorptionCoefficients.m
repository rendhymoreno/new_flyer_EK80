function [absorptionCoefficients] = EstimateAbsorptionCoefficients(EnvironmentData,frequency)
%ESTIMATEABSORPTIONCOEFFICIENTS Estimaets absorption coefficients in dB/m
%
% CALL: [absorptionCoefficients] = EstimateAbsorptionCoefficients(EnvironmentData,frequency)
%
% Inputs:
%   EnvironmentData        = 
%   frequency              = 
%
% Outputs:
%   absorptionCoefficients = 
%
% Description:
%
%
%
% Examples(s):
%   [absorptionCoefficients] = EstimateAbsorptionCoefficients(EnvironmentData,frequency)
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

narginchk(2,2);
nargoutchk(0,1);

f   = frequency/1e3; %size (500x1)
t   = [EnvironmentData.Temperature]; %size (139x1)
s   = [EnvironmentData.Salinity]; %size (139x1)
d   = [EnvironmentData.Depth]; %size (139x1)
ph  = [EnvironmentData.Acidity]; %size (139x1)
c   = [EnvironmentData.SoundSpeed]; %size (139x1)

a1 = (8.86./c).*10.^(0.78*ph-5); %size (139x1)
p1 = 1;
f1 = 2.8*(s/35).^0.5.*10.^(4-1245./(t+273)); %size (139x1)

a2 = 21.44.*(s./c).*(1+0.025*t); %size (139x1)
p2 = 1 - 1.37e-4*d + 6.62e-9.*d.^2; %size (139x1)
f2 = 8.17*10.^(8-1990./(t+273))./(1+0.0018*(s-35)); %size (139x1)

p3 = 1 - 3.83e-5*d + 4.9e-10*d.^2; %size (139x1)

a3l = 4.937e-4 - 2.59e-5*t + 9.11e-7*t.^2 - 1.5e-8*t.^3; %size (139x1)
a3h = 3.964e-4 - 1.146e-5*t + 1.45e-7*t.^2 - 6.5e-10*t.^3; %size (139x1)
a3 = a3l.*(t<=20) + a3h.*(t>20); %size (139x1)

% Original
%a = f.^2.*( a1.*p1.*f1./(f1.^2+f.^2) + a2.*p2.*f2./(f2.^2+f.^2) + a3.*p3 );
f_row = f.';      % 1x500, implicit expansion with 139x1 below
den1 = f1.^2 + f_row.^2;   % 139x1 vs 1x500 -> 139x500
den2 = f2.^2 + f_row.^2;   % 139x500

term1 = a1.*p1.*f1 ./ den1;          % 139x500
term2 = a2.*p2.*f2 ./ den2;          % 139x500
term3 = a3.*p3;                        % 139x1, will expand
a = (f_row.^2).*(term1+term2+term3);  % 139x500
absorptionCoefficients = (a.')/1e3;
