function out = EK80_load_files(chan_choice,var_n,indexer)
% filenames to load
%param options:
% 'power_cw'
% 'power_pc'
% 'PhysAng_alongship'
% 'PhysAng_athwartship'
% 'sv_pc'
% 'ts_pc'
% 'sv_cw'
% 'ts_cw'

% inputs:
%chan_choice = '70';
%var_n = {'sv_pc','PhysAng_alongship','PhysAng_athwartship'};

tic;
% Validate input
options = {'power_cw', 'power_pc', 'PhysAng_alongship', 'PhysAng_athwartship', ...
               'sv_pc', 'ts_pc', 'sv_cw', 'ts_cw'};

for i=1:length(var_n)
    validatestring(var_n{i}, options);
end

% Determine files to process based on input
fn_uniq = unique(indexer.filename);
fn_idx = contains(fn_uniq,['ES' chan_choice]);
fn_load = fn_uniq(fn_idx);
chan = unique(indexer.Channel);
chan_idx = contains(chan,['ES' chan_choice]);
ch_idx = ismember(indexer.Channel,chan(chan_idx));

if isempty(fn_load)
    error('Files to be loaded do not exist!')
end

var_n = horzcat(var_n,'range');
num_files = length(fn_load);
num_vars = length(var_n);
data_collector = cell(num_files, num_vars);

for ii = 1:num_files
    try
    % Load just 'procdata'
    load(fn_load{ii});
    
    % Extract each required variable for this file
    for jj = 1:num_vars
        this_var = var_n{jj};
        
        % This is the fast way to "flatten" a field from a struct array
        % into a single cell, then into an array
        data_collector{ii, jj} = [procdata.(this_var)];
    end
    catch ME
        fprintf('Error proc file: %s due to %s\n',fn_load{ii},ME.message);
    end
end

% Final Concatenation
% Now we merge the rows of our cell matrix for each variable
out = struct();
for jj = 1:num_vars
    out.(var_n{jj}) = [data_collector{:, jj}]; 
end

out.cal = procdata.cal;
% Add in the vars stuff and remove useless fields
out.vars = indexer(ch_idx,[7,1:3,10:21]);

elp_time = toc;
fprintf('[EK80 load] Loaded %d/%d files in %.0f sec\n',ii,num_files,elp_time);
