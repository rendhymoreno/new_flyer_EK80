function data_out = calculate_run_length(data_in, thresh, min_length, med_k)
data_out=data_in;
% average_run_length = zeros(1, size(data_in.val,2));
% total_runs = zeros(1, size(data_in.val,2));
casts=unique([data_in.vars.cast]);
counter=0; 

for i=1:size(casts,2)
    cast_vals=[data_in.val(:,[data_in.vars.cast] == casts(i))];
    for j=1:size(cast_vals,2)
        counter=counter+1;
        ping_vals=cast_vals(:,j);
        ping_vals=medfilt1(ping_vals,med_k);
        ping_vals= ping_vals >= thresh;

        track=0;
        run_length=0;
        target_n=0;
        for k = 1:size(ping_vals,1)
            if(ping_vals(k)==1 & track==0)
                track = 1;
                run_length =1;
            elseif(ping_vals(k)==1 & track == 1 & k < size(ping_vals,1))
                run_length=run_length+1;
            elseif(ping_vals(k)==0 & track == 1)
                track =0;
                if(run_length > min_length)
                    target_n=target_n+1;
                    run_lengths(target_n) = run_length;
                end
                run_length =0;
            elseif(ping_vals(k)==1 & track == 1 &  k == size(ping_vals,1) & run_length > min_length)
                target_n=target_n+1;
                run_lengths(target_n) = run_length;
            end
        end

        if(exist("run_lengths",'var'))
%             average_run_length(counter)=mean(run_lengths);
%             total_runs(counter)=size(run_lengths,2);
            data_out.vars(counter).average_run_length=mean(run_lengths);
           data_out.vars(counter).total_runs=size(run_lengths,2);
            data_out.vars(counter).run_lengths=run_lengths;
        else 
%             average_run_length(counter)=0;
%             total_runs(counter)=0;
            data_out.vars(counter).average_run_length=0;
            data_out.vars(counter).total_runs=0;
            data_out.vars(counter).run_lengths=0;

        end
        
        clear run_lengths; 
    end
end

% average_run_length = num2cell(average_run_length);
% total_runs=num2cell(total_runs);
% 
% [data_out.vars.average_run_length] = average_run_length{:};
% [data_out.vars.total_runs] = total_runs{:};

