clc;clear all;close all;
addpath(genpath('stp_glm'))

% simulating pre and postsynaptic responses ...
T=100;

% TM parameters [D F U f]

% true_params = [ 1.7 .02 .7  .05]; % strong depression
% true_params = [.5  .05 .5  .05];%  depression
% true_params = [.2  .2  .25 .3];% facilitation/depression
% true_params = [.05 .5  .15 .15];% facilitation
true_params = [.05 1 .01  .1];% strong facilitation

[Tpre, Tpost] = LIFoutput(T,20,50,true_params,1);
population{1}=Tpre;
population{2}=Tpost;

%% tm-glm
delay = [70 200]; % approximate length of the coupling and history filters in ms
nfilt = [6 5]; % number of filters to estimate coupling and history filters
dt=.001;
[param_bta, est_params, optimres]= ...
    stp_tmglm(population,T,'dt',dt,'delay',delay,'nfilt',nfilt,'nrestart',1);

%% gblm
S = double(getSpkMat(population,dt,T,1));
theta = ...
    stp_gblm(S(1,:),S(2,:),'delay',delay,'nfilt',nfilt,'numCV',4,'toleranceValue',5);

%% plot
figure,
subplot(3,3,1)
plot((est_params(5)*optimres(1).bta_path(end,2:nfilt(1)+1)*optimres(1).coupling.basis))
title('coupling filter');xlim([0 100]);
xlabel('ms')
subplot(3,3,2)
plot((optimres(1).bta_path(end,nfilt(1)+2:end)*optimres(1).hist.basis))
title('history filter')
xlabel('ms')

[corr,~] = corr_fast(Tpre, Tpost,-.01,.1,110);
subplot(3,3,4)
bar(linspace(-.01,.1,110),corr,'k');xlim([-.01 .1]);
title('cross-correlation pre/post')
xlabel('sec')
ylabel('firing rate (hz)')

[corr,~] = corr_fast(Tpost, Tpost,-.1,.1,200);
subplot(3,3,5)
bar(linspace(-.1,.1,200),corr,'k');xlim([-.1 .1]);
title('auto-correlation - post')
xlabel('sec')
ylabel('firing rate (hz)')

[V_est,current_est,t] = markram_response(est_params(1:4)');
[V,current] = markram_response(true_params);
% [V,current,t] = markram_response([.05 1 .01  .1]);
subplot(3,3,3);hold on
plot(t,current_est)
plot(t,current,'r')
title('markram response - current')
legend('estimated','true')
xlabel('sec')
ylabel('nAmp')

subplot(3,3,6);hold on
plot(t,1e3*V_est(1:length(t)))
plot(t,1e3*V(1:length(t)),'--r')
title('markram response - voltage')
xlabel('sec')
ylabel('mV')

[corr_sim_short,corr_sim_long] = short_hist(Tpre,Tpost,-.005,.05,150);
t=linspace(-5,50,150);
subplot(3,3,7)
bar(t,corr_sim_long,'k');xlim([0 50]);
yl1 = ylim;
title('splitxcorr - recovered')
xlabel('ms')
ylabel('firing rate (hz)')

subplot(3,3,8)
bar(t,corr_sim_short,'k');xlim([0 50]);ylim(yl1)
title('splitxcorr - burst')
xlabel('ms')
ylabel('firing rate (hz)')

subplot(3,3,9)
plot((theta.modif_fxn'));xlim([0 1000])
title('modification function')
xlabel('ms')
ylabel('modification weight')