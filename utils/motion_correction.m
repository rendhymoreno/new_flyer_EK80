%% Motion correction for circular transducer echosounder data
% from Dunford 2005, Correcting echo-integration data for transducer motion
% Output: 
% pwr_corrected = Power corrected data where the main assumption is transmit and receive
%   occurs at different pointing directions due to movement of the system
%   (roll and pitch). This algorithm corrects backscatter values only, and
%   not geometry to the transducer. The maximum allowed angle deviation is Y,
%   where Y is equal to the major/minor axis 3db angle. Values that have
%   passed this threshold are removed. 
% Inputs:
% pwr_data = (matrix) raw power from echosounder data
% major_minor_angle3db = (scalar) in simrad systems typically called beamwidth alongship
%   and beamwidth athwartship. Since it is a circular transducer, these
%   angles should be similar
% rollpitch_data (matrix) = matrix of roll and pitch velocity/angle data
%   (typically from accelerometers (accel) or ship motion data (angle/vel) or Star-Oddi (angle) with timestamps).
%   Has a dependency of another function that subsets the roll and pitch
%   data to the echogram. This data will be converted to roll and pitch
%   angles at transmission and reception of the echosounder
% 
% more info: check Dunford 2005 and echoview documentation 
% https://support.echoview.com/WebHelp/How_To/Use_The_Motion_Correction_Operator/Using_the_motion_correction_operator.htm
% https://support.echoview.com/WebHelp/Windows_And_Dialog_Boxes/Dialog_Boxes/Variable_Properties_Dialog_Box/Operator_Pages/Motion_correction_(Dunford_method).htm
% Rendhy Moreno Sapiie Dec 2023


%function pwr_corr = motion_correction(pwr_data, major_minor_angle3db, rollpitch_data)


pwr = pwr_data.power;
r = pwr_data.range;
c = pwr_data.Calparm.Soundspeed;
tt = pwr_data.time; %check format of timestamp
tr = tt + 2*r/c;
a = major_minor_angle3db;
rp_t = rollpitch_data.timenum;
roll = rollpitch_data.roll;
pitch = rollpitch_data.pitch;



x = sin(Y)/sin(a/2);
k = 0.17083*x^5 - 0.39660*x^4 + 0.53851*x^3 + 0.13764*x^2 + 0.039645*x + 1;
pwr_corr = pwr + 10*log10(k);

%end