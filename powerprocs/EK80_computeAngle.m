function [PhysAng_alongship, PhysAng_athwartship] = EK80_computeAngle(Y_pc,ChannelData,nSectors,cal)

if strcmp(ChannelData.BeamType,'1') && (nSectors==4) %beam type = 1 / 70 kHz transducer
    %Original Calculation for Angle from Anderson 2021
    complexFore         = sum(Y_pc(:,3:4),2)/2;
    complexAft          = sum(Y_pc(:,1:2),2)/2;
    complexStarboard    = (Y_pc(:,1) + Y_pc(:,4))/2;
    complexPort         = sum(Y_pc(:,2:3),2)/2;
    
    % Based on Anderson 2023
    PhaseAngleData_alongship    = complexFore.*conj(complexAft);
    PhaseAngleData_athwartship  = complexStarboard.*conj(complexPort);
    ElecAngleData_alongship    = atan2(imag(PhaseAngleData_alongship),real(PhaseAngleData_alongship)); %atan2 range [-pi pi] in rad
    ElecAngleData_athwartship    = atan2(imag(PhaseAngleData_athwartship),real(PhaseAngleData_athwartship)); %atan2 range [-pi pi] in rad
    PhysAng_alongship = asind(ElecAngleData_alongship/cal.angleS_minor_fc_lin); %degrees; angle sensitivity broadband
    PhysAng_athwartship = asind(ElecAngleData_athwartship/cal.angleS_major_fc_lin); %degrees; angle sensitivity broadband

elseif strcmp(ChannelData.BeamType,'17') && (nSectors==3) %beam type 17 / 3 quadrants: 200 kHz transducer
    % Quadrant data: source from Simrad EK80 Interface Manual Pg. 219 and pyEcholab EK80.py line 3055
    
    if strcmp(ChannelData.BeamType,'17')
        % This is 200kHz transducer that Croman uses
        trx_strb = Y_pc(:,1); 
        trx_port = Y_pc(:,2);
        trx_fore = Y_pc(:,3);
    else
       % Transducer with 3 sectors and center element.
        % Average the sectors with center. Y_pc(:,4) = center element
        trx_strb = (Y_pc(:,1) + Y_pc(:,4))/2;
        trx_port = (Y_pc(:,2) + Y_pc(:,4))/2;
        trx_fore = (Y_pc(:,3) + Y_pc(:,4))/2;

    end
    
    % Electrical Angle Calculation: Source pyEcholab line 3055
    % atan2 can also use angle in matlab!
    PhaseAngleData_alongship    = trx_fore.*conj(trx_strb);
    PhaseAngleData_athwartship  = trx_fore.*conj(trx_port);
    x = atan2(imag(PhaseAngleData_alongship),real(PhaseAngleData_alongship)); %atan2 range [-pi pi] in rad
    y = atan2(imag(PhaseAngleData_athwartship),real(PhaseAngleData_athwartship));
    ElecAngleData_alongship    = (x+y)/sqrt(3);
    ElecAngleData_athwartship  = y-x;
    % Physical Angle Calculation: Source pyEcholab line 3055 (Does not do asind?)
    % Anderson 2023 does asind!
    PhysAng_alongship  = asind(ElecAngleData_alongship/cal.angleS_minor_fc_lin);
    PhysAng_athwartship = asind(ElecAngleData_alongship/cal.angleS_major_fc_lin);
    
    % %% Angle calculation source: Simrad EK80 Interface Manual Pg. 219 
    % % Alongship angle calculations in rad
    % y1_x = real(trx_strb).*imag(trx_fore) - real(trx_fore).*imag(trx_strb);
    % x1_x = real(trx_fore).*real(trx_strb) + imag(trx_fore).*imag(trx_strb);
    % y2_x = real(trx_port).*imag(trx_fore) - real(trx_fore).*imag(trx_port);
    % x2_x = real(trx_fore).*real(trx_port) + imag(trx_fore).*imag(trx_port);
    % % Athwartship angle calculations in rad
    % y1_y = real(trx_port).*imag(trx_fore) - real(trx_fore).*imag(trx_port);
    % x1_y = real(trx_fore).*real(trx_port) + imag(trx_fore).*imag(trx_port);
    % y2_y = real(trx_strb).*imag(trx_fore) - real(trx_fore).*imag(trx_strb);
    % x2_y = real(trx_fore).*real(trx_strb) + imag(trx_fore).*imag(trx_strb);
    % % Electrical angle data in rad from -pi to pi
    % ElecAngleData_alongship    = atan2(y1_x, x1_x) + atan2(y2_x, x2_x);
    % ElecAngleData_athwartship  = atan2(y1_y, x1_y) - atan2(y2_y, x2_y);
    % % Physical angle data in degrees
    % ProcessedSampleData.PhysAng_alongship       = asind(ElecAngleData_alongship/(sqrt(3)*angleS_minor_fc_lin));
    % ProcessedSampleData.PhysAng_athwartship     = asind(ElecAngleData_alongship/angleS_major_fc_lin);
end

end