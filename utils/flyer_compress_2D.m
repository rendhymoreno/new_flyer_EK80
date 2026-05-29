function dataout = flyer_compress_2D(datain,ch,met,cmpr)

%plotEk_Echogram_Niskin(svEK80,1,[],[],{0 'inf'},[],[-77 -36],'Original',[])
chan = fieldnames(datain);
val_log = [datain.(chan{ch}).val];

if strcmp(cmpr,'999')
    val_log(isnan(val_log)) = -999;
    disp('Empty cells are converted into -999 dB')
elseif strcmp(cmpr,'NaN') | strcmp(cmpr,'nan')
    val_log(val_log == -999) = NaN;
    disp('Empty cells are NaNs and not considered for averaging')
end

%met = 'avg';
if strcmp(met,'avg')
    val_lin = 10.^(val_log/10);
    avgping_lin = mean(val_lin,1,"omitmissing");
    avgping = 10*log10(avgping_lin);
    disp('metric is mean')
elseif strcmp(met,'max')
    avgping = max(val_log,[],1);
    disp('metric is max')
elseif strcmp(met,'med')
    avgping = median(val_log,1,"omitmissing");
    disp('metric is median')
end

dataout = datain;
%dataout.(chan{ch}).range = ones(size(val_log,1),1);
dataout.(chan{ch}).range = 10;
dataout.(chan{ch}).val = avgping;

fprintf('[2D Compression] 3-D EK data has been compressed\n')
end