load('D:\2023_MarcusLangseth\ES60\processed\syncedES60_sv.mat')
%test file: 10-06-23 ES60 from 280m (1460) to 700m (end)
dr = ch1_38.range(3)-ch1_38.range(2);
dt = 0.975; %ping interval in seconds
fs_u = 1/dt;
fs_v = 1/dr;
%ind_ti = 1100; %04:00:15
%ind_tf = 4835; %05:00:15
load("sv_snippet.mat");
t = 0:dt:dt*length(sv_example)-dt;
r = ch1_38.range(1460):dr:ch1_38.range(end);

%% asd
fig=figure(1)
imagesc(t, r, sv_example, [-85 -55]); 
cptcmap('EK60_2.cpt'); axis tight; shading flat; 
xticks('auto');yticks('auto');colorbar;

for i = 1:size(sv_example,1)
    for j = 1:size(sv_example,2)
        if sv_example(i,j) < -60
            sv(i,j) = 0;
        else
            sv(i,j) = sv_example(i,j);
            sv(i,j) = 1;
        end
    end
end

for k = 1:size(sv_example,2)
sv2(1,k) = sum(sv(:,k));
end



fig = figure(3)
plot(sv2)


sv2_f = fftshift(fft(sv2));
P2 = abs(sv2_f)/size(sv_example,1);
P1 = P2(1:size(sv_example,1)/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = fs_u/size(sv_example,1)*(0:(size(sv_example,1)/2));
fig = figure(2)
plot(f,P1)

for ii = 1:length([cursor_info1])
fpeaks(ii) = cursor_info1(ii).Position(1);
end
tpeaks = sort(1./fpeaks);


fig=figure(4)
imagesc(t, r, sv); 
cptcmap('EK60_2.cpt'); axis tight; shading flat; 
xticks('auto');yticks('auto');colorbar;

ny = size(sv_example,1);
nx = size(sv_example,2);
dfy = 1/(ny*dr);
dfx = 1/(nx*dt);
fy  = (-0.5/dr:dfy:(0.5/dr-1/(ny*dr)));
fx  = (-0.5/dt:dfx:(0.5/dt-1/(nx*dt)));
F = abs(fftshift(fft2(sv)));
F = abs(fftshift(fft2(sv_example)));
fig = figure(5)
imagesc(fx,fy,20*log10(F));
axis tight; colormap(gray); colorbar; shading flat



