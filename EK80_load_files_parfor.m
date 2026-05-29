function out = EK80_load_files_parfor(chan_choice, var_n, indexer)
% EK80_LOAD_FILES Optimized for memory and parallel processing
tic;

% 1. Validate & Setup
options = {'power_cw', 'power_pc', 'PhysAng_alongship', 'PhysAng_athwartship', ...
           'sv_pc', 'ts_pc', 'sv_cw', 'ts_cw', 'range'};
var_n = unique([var_n, {'range'}], 'stable'); 
for i = 1:length(var_n)
    validatestring(var_n{i}, options);
end

% 2. Filter Files
fn_uniq = unique(indexer.filename);
fn_load = fn_uniq(contains(fn_uniq, ['ES' chan_choice]));

if isempty(fn_load)
    error('Files to be loaded do not exist!');
end

num_files = length(fn_load);
num_vars = length(var_n);

% 3. Parallel Processing
% We use a cell array to store results from each worker
data_collector = cell(num_files, 1);

% Pre-extract cal data (assuming it's consistent or we take from the first)
% If 'cal' is needed from every file, move it inside the loop.
first_file = load(fn_load{1}, 'procdata');
cal_template = first_file.procdata(1).cal;

%ppm = ParforProgressbar(num_files);

parfor ii = 1:num_files
    try
        % Use matfile() to access file without loading everything into RAM
        m = matfile(fn_load{ii});

        % Load ONLY the procdata struct
        % Note: matfile allows partial loading, but since procdata is often
        % an array of structs, we load it once per file.
        temp_struct = m.procdata;

        % Internal storage for this specific file's variables
        file_vars = struct();
        for jj = 1:num_vars
            this_var = var_n{jj};
            % Efficiently flatten the struct array field
            file_vars.(this_var) = [temp_struct.(this_var)];
        end

        data_collector{ii} = file_vars;
        %pause(100/num_files);
        %ppm.increment();
    catch ME
        fprintf('Error proc file: %s due to %s\n',fn_load{ii},ME.message);
    end
end

% 4. Efficient Concatenation
out = struct();
for jj = 1:num_vars
    this_var = var_n{jj};
    % Concatenate across all files for this variable
    out.(this_var) = horzcat(cellfun(@(x) x.(this_var), data_collector, 'UniformOutput', false));
    out.(this_var) = [out.(this_var){:}];
end

% 5. Finalize Metadata
out.cal = cal_template;
chan = unique(indexer.Channel);
chan_idx = contains(chan, ['ES' chan_choice]);
ch_idx = ismember(indexer.Channel, chan(chan_idx));
out.vars = indexer(ch_idx, [7, 1:3, 10:21]);

elp_time = toc;
fprintf('[EK80 load] Loaded %d files in %.0f sec\n', num_files, elp_time);
end