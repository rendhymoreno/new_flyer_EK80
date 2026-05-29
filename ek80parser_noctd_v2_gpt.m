function ek80parser_noctd_v2_gpt(defaultPath, outpath, TVG_range_correction)
% -------------------------------------------------------------------------
% Faster EK80 parser – works on many large .raw files.
%   * pre‑allocates structs
%   * uses a containers.Map for channel lookup (O(1) per ping)
%   * writes results directly to .mat files via matfile (no RAM blow‑up)
%   * optional parfor over files (requires Parallel Computing Toolbox)
% -------------------------------------------------------------------------

% ----------- USER SETTINGS -------------------------------------------------
save_files   = true;           % write per‑file .mat files
save_index   = true;           % write global_index.mat at the end
fileAppend   = 'pings';
% -------------------------------------------------------------------------

% ---- pick the raw files --------------------------------------------------
[fileNameList, filePath] = uigetfile('*.raw','Select EK80 .raw files', ...
                                    'MultiSelect','on', defaultPath);
if ~iscell(fileNameList), fileNameList = {fileNameList}; end
fileNames = fullfile(filePath, fileNameList);
nFiles    = numel(fileNames);

% ---- (optional) compute #pings per file for a global counter ------------
% This is a lightweight pass that only reads the header.
numPingsPerFile = zeros(1,nFiles);
for f = 1:nFiles
    d = EK80readRawV3(fileNames{f});
    numPingsPerFile(f) = numel(d.echodata);
end
offset = [0, cumsum(numPingsPerFile)];   % offset(i) = first global index of file i

% ---- Parallel processing over files --------------------------------------
ppm = ParforProgressbar(nFiles);

parfor f = 1:nFiles                     % <-- comment out “parfor” to run serially
    fileName = fileNames{f};
    [~,fileStem,~] = fileparts(fileName);     % e.g. EK80_20210708_001

    % ---- read raw file --------------------------------------------------
    data = EK80readRawV3(fileName);
    nPings = numel(data.echodata);
    if nPings < 2
        warning('File %s contains only one ping – skipped', fileName);
        continue;
    end

    % ---- build channel → transceiver lookup map -------------------------
    transdata = data.config.transceivers;      % all transceivers
    chanMap = containers.Map('KeyType','char','ValueType','any');
    for ii = 1:numel(transdata)
        for jj = 1:numel(transdata(ii).channels)
            chID = char(transdata(ii).channels(jj).ChannelID);
            chanMap(chID) = [ii jj];
        end
    end

    % ---- pre‑allocate the output structs --------------------------------
    procdata = struct('timestamp_raw',cell(1,nPings), ...
                      'channel',       [], ...
                      'ping_global',   [], ...
                      'startTVG',      [], ...
                      'absorptionCoeff', [], ...
                      'TVGStart',      [], ...
                      'cast',          [] );
    % Global indexer (only fields you really need)
    global_indexer = struct('ping_global',   [], ...
                            'ping_local',    [], ...
                            'file',          [], ...
                            'var',           [], ...
                            'timestamp_raw', [], ...
                            'channel',       [], ...
                            'TVGStart',      [], ...
                            'absorptionCoeff', [], ...
                            'cast',          [] );

    % ---- open a matfile for on‑disk writing -----------------------------
    matFileName = fullfile(outpath, [fileStem '.mat']);
    m = matfile(matFileName,'Writable',true);
    m.procdata(1,nPings) = struct();   % allocate on‑disk

    % ---- loop over pings ------------------------------------------------
    for ping = 1:nPings
        % ----- get ping‑specific data ------------------------------------
        pingdata   = data.echodata(ping);
        paramdata  = data.param(ping);
        envirodata = data.environ;                 % constant per file
        filterdata = data.filters;                  % constant per file

        % ----- find the correct transceiver -------------------------------
        if isKey(chanMap, pingdata.channelID)
            idx = chanMap(pingdata.channelID);     % [transIdx channelIdx]
            transCh = transdata(idx(1)).channels(idx(2));
            transducer = transCh.transducer;
        else
            error('Channel %s not found in map', pingdata.channelID);
        end

        % ----- process the ping (your own function) ----------------------
        procping = EstimateEK80CW(pingdata, transCh, transducer, ...
                                  paramdata, envirodata, TVG_range_correction);
        procping.timestamp_raw = pingdata.timestamp;
        procping.channel        = pingdata.channelID;
        procping.ping_global    = offset(f) + ping;   % global ID

        % ----- fill the per‑ping struct ----------------------------------
        procdata(ping) = procping;                  % in‑memory copy
        m.procdata(1,ping) = procping;              % on‑disk copy (fast)

        % ----- fill the global indexer ----------------------------------
        gi = offset(f) + ping;
        global_indexer(gi).ping_global   = gi;
        global_indexer(gi).ping_local    = ping;
        global_indexer(gi).file          = fileStem;
        global_indexer(gi).var           = fileAppend;
        global_indexer(gi).timestamp_raw = pingdata.timestamp;
        global_indexer(gi).channel       = pingdata.channelID;
        global_indexer(gi).TVGStart      = procping.startTVG;
        global_indexer(gi).absorptionCoeff = procping.absorptionCoeff;
        global_indexer(gi).cast          = 1;
    end

    % ---- optionally delete the huge in‑memory copy (keep only the matfile) --
    %{
    if save_files
        clear procdata;      % free RAM; the data lives on disk in `m`
    end
    %}

    % --------------------------------------------------------------------
    % Return the per‑file global indexer for later concatenation
    % --------------------------------------------------------------------
    if save_index
        global_indexer_cell{f} = global_indexer; %#ok<PFOUS>
    end
    pause(100/nBins);
    % increment counter to track progress
    ppm.increment();
    %fprintf('Finished file %d/%d : %s\n', f, nFiles, fileStem);
end   % <--- end parfor

% ---- concatenate and save the global indexer ----------------------------
if save_index
    % Remove empty cells (files that were skipped)
    global_indexer_cell = global_indexer_cell(~cellfun('isempty',global_indexer_cell));
    global_indexer = cat(2, global_indexer_cell{:});
    save(fullfile(outpath,'global_index.mat'),'global_indexer');
end
end