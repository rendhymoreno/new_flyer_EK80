%% ROV ctd struct generator
% This will read CTD files from either binary format (.asc/.cnv/etc..) or
% tab/space/comma delimited (.txt/.csv/etc..) and output the ctd data as
% .mat struct
% Var Inputs: 
% ctdPath = 'path + filename of ctd file input'
% outFname = 'path + filename of ctd struct output'
% inFormat = file format (e.g. 'binary' or 'delimited') see below
% plot = 'on' if you want to plot the ctd depth over time, otherwise leave
% empty

function ctdstructbuilder(ctdPath,outFname,inFormat,plt)

%ctdPath = 'D:\ONR2023\Bermuda\July2021\2021-07-08\ctd_07-08-2021\SBE39plus_REEL_DRIFTER_ROV_2021_07_08.cnv'; %dir input
%ctdPath = 'F:\EK80_Solomons\starOddi\PEAVA_EK80_ME20_062719.txt';
%outFname = 'F:\EK80_Solomons\starOddi\PEAVA_062719'; %dir and fname of output

%% specific for Bermuda Star ODDI / if file is binary/non-standard format

if strcmp(inFormat,'binary')
opt = {'CollectOutput',true};
out = {};
cflg = 0;
fidctd = fopen(ctdPath,'r');
while ~strcmp(cflg,'*END*')
    cflg = fgetl(fidctd);
end
while ~feof(fidctd)
    out(end+1) = textscan(fidctd,'%f%f%f%f',opt{:});
end
fclose(fidctd);
ctd.temperature = out{1}(:,1);
ctd.pressure = out{1}(:,2);
ctd.time_loc = datenum(2021,1,1)-1+out{1}(:,3); %conversion from julian day (2021,1,1) to date
rovt_utc =[];
for z = 1:length(ctd.time_loc)
    rovt_utc(z) = addtodate(ctd.time_loc(z),3,"hour");
end
ctd.time_utc = rovt_utc';
ctd.conductivity = out{1}(:,4);

save(outFname,'-struct','ctd');

%specific for starODDI Solomons 2019 format .txt tab delimited (3 columns: dt / temp / depth) / dt = local_time
elseif strcmp(inFormat,'solomons')
fidctd = fopen(ctdPath,'r');
out = textscan(fidctd,'%s%f%f', 'delimiter', '\t'); % tab delimited
fclose(fidctd);
ctd.temperature = out{2};
ctd.pressure = out{3};
ctd_timeloc = datetime(out{1},'InputFormat','M/dd/yy HH:mm:ss','TimeZone','Pacific/Guadalcanal');
ctd.time_loc = datenum(ctd_timeloc);
ctd_timeloc.TimeZone = 'Z';
ctd.time_utc = datenum(ctd_timeloc);
save(outFname,'-struct','ctd');

%specific for StarODDI excel time
elseif strcmp(inFormat,'tabODDI')
fidctd = fopen(ctdPath,'r');
out = textscan(fidctd,'%f%f%f', 'delimiter', '\t'); % tab delimited
fclose(fidctd);
ctd.temperature = out{2};
ctd.pressure = out{3};
ctd_timeloc = datetime(out{1},'ConvertFrom','excel');
%ctd.time_loc = datenum(ctd_timeloc);
ctd.time_utc = datenum(ctd_timeloc);
save(outFname,'-struct','ctd');
end

%% Optional Plot
fig2 = figure();
plot(datetime(ctd.time_utc,'ConvertFrom',"datenum"), ctd.pressure)
set(gca,'YDir','reverse');
title('CTD ROV time vs depth');
disp('Finished reading CTD file');
end