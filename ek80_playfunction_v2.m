% playfunction_rms: function to call out processed ping data (only one per function, if more parameters are needed call out this function as necessary)
% OUTPUT = queried processed data (power_cw,power_pc, alongship, athwardship, sv_pc,
% ts_pc, sv_cw, ts_cw, svf, f, or rawPower)
% INPUT:
% globalindPath = 'string'; dir path/folder of the global index.mat
% index_type = 'string'; determine which data you want based on the type of index (see in global_index.mat), e.g., 'ping_local' or 'ping_global'
% indexes = 'string'; the indexes that will be processed, e.g., '1:max([global_indexer.cast])' 
% will process all the data from cast 1 to max(cast)
% param = 'string'; the type of parameter that will be outputted, e.g., if
% you want pulse compressed backscatter than param = 'sv_pc'

function ek80_playfunction_v2(globalindPath, index_type, indexes, param, freq_inp)

load(strcat(globalindPath, 'global_index.mat'));
ch_data = unique({global_indexer.channel})';
ch_freq_num = cellfun(@(s) str2double(regexp(s,'(?<=ES)\d+','match','once')),ch_data);

if ~exist('fullfile(globalindPath,param)','dir')
    mkdir(fullfile(globalindPath,param));
end

% Datetime
time_dt = datetime([global_indexer.timestamp_raw],"ConvertFrom","datenum","Format","uuuu-MMM-dd HH:mm:ss.SSS");

% Segment dates / Maybe not necessary? Segment later!!

sur_dates = unique(dateshift(time_dt,"start","day")).';
% Find index of global indexer based on day
tr_d = (time_dt >= sur_dates) & (time_dt < (sur_dates + day(1)));
tr_d = tr_d';

% Channel segment
%ppm = ParforProgressbar(size(tr_d,2));
for ii=1:size(tr_d,2)
    
    tsub_fproc = global_indexer(tr_d(:,ii));
    
    for jj=1:length(freq_inp)
        freq_inp_idx = ismember(ch_freq_num,freq_inp(jj));
        freq_sub_i = ismember({tsub_fproc.channel},ch_data{freq_inp_idx});
        temp_fproc = tsub_fproc(freq_sub_i);
        data = generate_data(temp_fproc, index_type, 1, ch_data{freq_inp_idx}, param, globalindPath); %Generate data can be parfored!
        fieldn = sprintf('chan_%s',string(ch_freq_num(freq_inp_idx)));
        dstr = datestr(sur_dates(ii),'yyyy-mm-dd');
        fname = fullfile(globalindPath,param,[dstr '_' param '_' fieldn '.mat']);
        save(fname, '-fromstruct', data);
        %pause(100/nJobs);
        %ppm.increment();

        fprintf('[EK80 Parameter] Generated %.0f kHz Data of dates [%.0f / %.0f]\n',freq_inp(jj),ii,size(tr_d,2));
    end
end

end