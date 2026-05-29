%This is a test function but does not have full functionality yet!
function pitch_roll_staroddi(fname,outpath)
%fname = 'E:\2023_Bermuda\Dive3_7182023\StarOddi\Payload\7182023_DIve3_testdata.txt';
%outFname = 'E:\2023_Bermuda\Dive3_7182023\StarOddi\Payload\7182023_DIve3_testdata.mat';
fid = fopen(fname,'rt');
head_char = fgets(fid);
hd_dmter = sprintf('\t');
N = numel(strfind(head_char,hd_dmter)) + 1;
head = strtrim(strsplit(head_char,'\t'));
msg = sprintf('Detected %u parameters in file: %s',N,strtrim(head_char));
disp(msg)
%frewind(fid);
%%

fmtdata = '%f';
for ii = 1:N-1
    fmtdata = append(fmtdata,'%f');
end

data = textscan(fid,fmtdata, 'delimiter', '\t'); % tab delimited
fclose(fid);

data_ind = {'Date & Time';
    'Temp(°C)';
    'Depth(m)';
    'Tilt-X(°)';
    'Tilt-Y(°)';
    'Tilt-Z(°)';
    'EAL';
    'Comp.Head(°)';
    'Comp.4p(°)';
    'Inclination(°)';
    'Mag.vec(nT)';
    'Roll(°)'};

n_head = {'timeexcel', 'temp', 'depth', 'tiltx', 'tilty','tiltz',...
    'EAL','heading','comp4p','inclination','magvecNT','roll'};

%%
for j = 1:N
    for i = 1:12
        if strcmp(head(j),data_ind(i))
            idx = strcmp(head(j),data_ind);
            ctd.(n_head{idx}) = data{j};
        end
    end
end
%%
if isfield(ctd, 'timeexcel') && ~isempty(ctd.timeexcel)
    ctd.timedt = datetime(ctd.timeexcel,'ConvertFrom','excel');
    ctd.timenum = datenum(datetime(ctd.timeexcel,'ConvertFrom','excel'));
    %ctd.time_utc = datenum(ctd_timeloc);
end

%%
%if mode == 'rollpitch'
%    rmfield
%end
if strcmp(outpath(end),'\')
    outpath = outpath(1:end-1);
end
save(append(outpath,'\pitch_roll_data.mat'),'-struct','ctd');

msg = sprintf('CTD .mat file has been saved in %s',append(outpath,'\pitch_roll_data.mat'));
disp(msg)

end