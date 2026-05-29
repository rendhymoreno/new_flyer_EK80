plt_dir = 'E:\2023_MSET\processed\plot_Brennan\fig files\';
plt_out = plt_dir; %'E:\2023_MSET\processed\plot_Brennan\';

%read all fig files
fName = dir(fullfile(plt_dir,'*.fig'));
ftitle = {fName.name};
%ftitle = ftitle(1:length(ftitle)-4);
%fcomplete = {fullfile(plt_dir,fName.name)};
n = length(ftitle);

%load fig files
for i = 1:n
    fileName = ftitle{i};
    fnext = fileName(1:length(fileName)-4);
    fcomplete = fullfile(plt_dir,fileName);
    asu = openfig(fcomplete)
    asu.Position = [1 1 924 1003]; %change to half width
    xtickangle(25);
    t = xlim;
    t = datetime(t,"ConvertFrom","datenum");
    plt_title = sprintf('ES60 38kHz / %s - %s UTC', t(1),t(2));
    title(plt_title);
    xlabel('Time (UTC)');
    asu.Color = 'w';
    export_fig(append(plt_out,fnext),'-bmp','-nocrop');
    fprintf('Saved figure %i out of %i in %s\n',i,n,plt_out)
end