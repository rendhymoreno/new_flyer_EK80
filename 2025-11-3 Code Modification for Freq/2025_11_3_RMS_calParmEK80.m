%% Obtain calibration parameters and calculate at center frequency for BB and CW 
% cal = calParmEK80(transdata_ch,ParameterData,ChannelData,frequencyCenter)
% units lin: angle sensitivity, beamwidth 
% units log: gain, Sa, effective beam width
% Source: Echoview and Lars code (L223):
% https://github.com/CRIMAC-WP4-Machine-learning/CRIMAC-Raw-To-Svf-TSf/blob/abd01f9c271bb2dbe558c80893dbd7eb0d06fe38/Core/EK80DataContainer.py#L247
% RMS 2024

function cal = calParmEK80(transdata_ch,ParameterData,ChannelData,frequencyCenter)

cal.freq_nom = str2double(ChannelData.Frequency);
PDList = str2double(strsplit(transdata_ch.PulseDuration,';')); %Pulse duration lookup table (EK80 despite CW/BB will still use the CW pulse duration lookup table)
BB_idx = dsearchn(PDList',ParameterData.PulseDuration); %search for index from the PD lookup table
cal.angleS_minor_nom = str2double(ChannelData.AngleSensitivityAlongship); %nominal angle sensitivity alongship
cal.angleS_major_nom = str2double(ChannelData.AngleSensitivityAthwartship); %nominal angle sensitivity athwartship
gain_list = str2double(strsplit(ChannelData.Gain,';')); %Gain lookup table
cal.gain_nom = gain_list(BB_idx); %peak gain at nominal freq
cal.beamW_minor_nom = str2double(ChannelData.BeamWidthAlongship); %nominal 3dB beam angle alongship
cal.beamW_major_nom = str2double(ChannelData.BeamWidthAthwartship); %nominal 3dB beam angle athwartship
cal.angleOff_minor_nom = ChannelData.AngleOffsetAlongship; %nominal angle offset alongship
cal.angleOff_major_nom = str2double(ChannelData.AngleOffsetAthwartship); %nominal angle offset athwartship
cal.effBAngle_nom_log = str2double(ChannelData.EquivalentBeamAngle); %nominal effective beam angle
SaCorr_list = str2double(strsplit(ChannelData.SaCorrection,';')); %Sa lookup table
cal.SaCorr_log = SaCorr_list(BB_idx); %Sa lookup table
cal.beamtype = str2double(ChannelData.BeamType);
cal.freq_nom = str2double(ChannelData.Frequency);

%Calculate at center frequency for BB in log form(Specifically since no "varied gain" exists in the calibration file)
cal.effBAngle_fc_log = cal.effBAngle_nom_log+20*log10(cal.freq_nom/frequencyCenter);
cal.beamW_minor_fc_lin = cal.beamW_minor_nom*cal.freq_nom/frequencyCenter;
cal.beamW_major_fc_lin = cal.beamW_major_nom*cal.freq_nom/frequencyCenter;
cal.angleS_minor_fc_log = 10*log10(cal.angleS_minor_nom)+20*log10(frequencyCenter/cal.freq_nom);
cal.angleS_major_fc_log = 10*log10(cal.angleS_major_nom)+20*log10(frequencyCenter/cal.freq_nom);
if max(gain_list) == min(gain_list) %If no varying gain was detected
    cal.gain_fc_log = cal.gain_nom+20*log10(frequencyCenter/cal.freq_nom);
end

end