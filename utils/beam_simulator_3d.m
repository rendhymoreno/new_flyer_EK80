
function simulated_data = beam_simulator_3d(theta,ts,sl,nl,absco)

nl =10^(nl/10); % convert noise level to linear domain for convenience 

delta_theta = theta/1000;% degree increments for the cells

out_lin= zeros(1000,1000);% this is the out matrix for the signal excess solutions
weights= zeros(1,1000);% this is the beam area over range
V = zeros(1000,1000);% this is the out matrix for the signal excess solutions

for i = 1:1000
    for j = 1:1000
            
        r=j/10; % range in meters at j
        
        tl_spreading = 40*log10(r);% TL at range
        tl_absorption = 2*absco*r ; %TL at range        
        theta_loss=3*i*delta_theta/theta; 
        
        se=sl -tl_spreading-tl_absorption+ts-theta_loss; % calculate signal excess for cell ij
        
        if j==1
            r1=0;  % just establishing the range at j-1
        else
            r1=(j-1)/10;% just establishing the range at j-1 (should have just subtracted .1 but whatver)
        end
                
        h =  r - cosd(i*delta_theta)*r;
        V2 = 2*pi*r^2*h/3;
        
        h =  r1 - cosd(i*delta_theta)*r1;
        V1 = 2*pi*r1^2*h/3;
       

        volume_ij = (V2 - V1);
        V(i,j)=volume_ij;        
        
%         volume_ij = (((4/3*(pi*r^3))-(4/3*(pi*r1^3)))/((4/3*pi*1.05^3)-(4/3*pi*0.95^3)))*((i_rel*delta_theta^2/((180/pi)^2))/(4*pi));
%       
        out_lin(i,j) =(10.^(se./10))*volume_ij; 
        
    end
end

%calculate beam area for conversion to sv
r=0:.1:100
for i = 2:size(r,2)
    h =  r(i) - cosd(theta)*r(i);
    V2 = 2*pi*r(i)^2*h/3;

    h =  r(i-1) - cosd(theta)*r(i-1);
    V1 = 2*pi*r(i-1)^2*h/3;

    weights(i-1) = V2 - V1;
    
%       weights(i-1) = (4/3*pi*r(i)^3 - 4/3*pi*r(i-1)^3)*2*theta/360; 
%         weights(i-1) = (4/3*pi*r(i)^3 - 4/3*pi*r(i-1)^3)*((((2*theta)^2)/(180/pi)^2)/(4*pi));
%         weights(i-1) = (4/3*pi*r(i)^3 - 4/3*pi*r(i-1)^3)*((2*theta)^2)/41253;
%     weights(i-1) = (4/3*pi*r(i)^3 - 4/3*pi*r(i-1)^3)*((2*theta)^2/(360*180));
%     weights(i-1) = (4/3*pi*r(i)^3 - 4/3*pi*r(i-1)^3)*((2*theta)/(360));

end

r=.1:.1:100

%power calculation
simulated_data.rx=10.*log10((sum(out_lin)+nl));
%scattering volume calculation 
simulated_data.sv=(10.*log10((sum(out_lin)+nl )./weights));%+40.*log10(r)+2.*absco.*r;
simulated_data.weights =weights;
simulated_data.beam= 10.*log10(out_lin);
simulated_data.volume=V; 
% simulated_data.foo=x; 



% function simulated_data = beam_simulator_3d(theta,ts,sl,nl,absco)

% nl =10^(nl/10); % convert noise level to linear domain for convenience 
% 
% delta_theta = theta/499;% degree increments for the cells
% 
% out_lin= zeros(1000,1000);% this is the out matrix for the signal excess solutions
% weights= zeros(1,1000);% this is the beam area over range
% V = zeros(1000,1000);% this is the out matrix for the signal excess solutions
% 
% for i = 1:1000
%     for j = 1:1000
%         
%         i_rel = abs(i-500); % figure out which theta cell you are in        
%         r=j/10; % range in meters at j
%         
%         tl_spreading = 40*log10(r);% TL at range
%         tl_absorption = 2*absco*r ; %TL at range        
%         theta_loss=3*i_rel*delta_theta/theta; 
%         % theta_loss=0; 
% 
%         se=sl -tl_spreading-tl_absorption+ts-theta_loss; % calculate signal excess for cell ij
%         
%         if j==1
%             r1=0;  % just establishing the range at j-1
%         else
%             r1=(j-1)/10;% just establishing the range at j-1 (should have just subtracted .1 but whatver)
%         end
%                 
%         h =  r - cosd(i_rel*delta_theta)*r;
%         V2 = 2*pi*r^2*h/3;
%         
%         h =  r1 - cosd(i_rel*delta_theta)*r1;
%         V1 = 2*pi*r1^2*h/3;
%         
% %         h =  1.05 - cosd(i*delta_theta)*1.05;
% %         V2_at1 = 2*pi*1.05^2*h/3;
% %         h = .95 - cosd(i*delta_theta)*.95;
% %         V1_at1 = 2*pi*.95^2*h/3;        
% %         volume_ij = (V2 - V1)/(V2_at1-V1_at1);
% 
%         volume_ij = (V2 - V1);
%         V(i,j)=volume_ij;
%         
% %         volume_ij = (((4/3*(pi*r^3))-(4/3*(pi*r1^3)))/((4/3*pi*1.05^3)-(4/3*pi*0.95^3)))*((i_rel*delta_theta^2/((180/pi)^2))/(4*pi));
% %         volume_ij = (((4/3*(pi*r^3))-(4/3*(pi*r1^3)))/((4/3*pi*1.05^3)-(4/3*pi*0.95^3)))*(delta_theta^2/(360*180)); 
% %       
%         out_lin(i,j) =(10.^(se./10))*volume_ij; 
%         
%     end
% end
% 
% %calculate beam area for conversion to sv
% r=0:.1:100
% for i = 2:size(r,2)
%     h =  r(i) - cosd(theta)*r(i);
%     V2 = 2*pi*r(i)^2*h/3;
% 
%     h =  r(i-1) - cosd(theta)*r(i-1);
%     V1 = 2*pi*r(i-1)^2*h/3;
% 
%     weights(i-1) = V2 - V1;
%    
% end
% 
% r=.1:.1:100
% 
% %power calculation
% simulated_data.rx=10.*log10((sum(out_lin)+nl));
% %scattering volume calculation 
% simulated_data.sv=(10.*log10((sum(out_lin)+nl )./weights));%+40.*log10(r)+2.*absco.*r;
% simulated_data.weights =weights;
% simulated_data.beam= 10.*log10(out_lin);
% simulated_data.volume=V; 



