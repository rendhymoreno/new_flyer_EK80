function castnumbers = makeflyercasts(flyer_controller_cmd_t_CTL_COMMAND, timestamp)
ind = dsearchn(double(flyer_controller_cmd_t_CTL_COMMAND.timestamp), double(timestamp));

updwn = flyer_controller_cmd_t_CTL_COMMAND.updwn(ind);
mode = flyer_controller_cmd_t_CTL_COMMAND.ctl_mode(ind);

prev = updwn(1);
counter=1;
castnumbers(1) = counter;
for(i = 2:length(updwn))
    if(updwn(i) == prev)
        castnumbers(i) =  counter;
    elseif(mode(i) == 6)
        counter=counter+1;
        castnumbers(i) = counter;
    else
        castnumbers(i) = counter;        
    end
    prev=updwn(i);  
    %disp(100*i/length(updwn))
end
