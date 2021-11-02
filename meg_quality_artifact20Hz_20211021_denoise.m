% This script computes the power spectra for the empty room recordings,
% demonstrates how to use ft_denoise_synthetic, or ft_denoise_pca to
% alleviate the artifacts
%
% 20211102, J.M.Schoffelen, DCCN 

datadir = '/project/3055020.01/raw/';
year = '2021';
date = '20211021';
d = dir(fullfile(datadir,year,date,'*test*.ds'));

datasets = cell(numel(d),1);
for k = 1:numel(d)
  datasets{k,1} = fullfile(d(k).folder, d(k).name);
end

% 01: everything off
% 02: camera on
% 03: speaker on + camera on
% 04: speaker on + camera on + sound on speaker
% 05: speaker on + camera off

k = 2;

cfg = [];
cfg.dataset = datasets{k};
hdr = ft_read_header(cfg.dataset);

% quick and dirty 5 second chunks
N = hdr.nSamples*hdr.nTrials;
trl = [1:3000:(N-5999);6000:3000:N]';
trl(:,3) = 0;

% let's go for about 10 minutes of data, or less
cfg.trl = trl(1:min(size(trl,1),12*10),:);
cfg.channel = {'MEG' 'MEGREF'};
cfg.demean  = 'yes';
cfg.continuous = 'yes';
data = ft_preprocessing(cfg);

% this is needed, because there's some chunk of bad data in this recording
S = [];
for kk = 1:numel(data.trial)
  S(:,kk) = std(data.trial{kk},[],2);
end
S = S./std(S,[],2);

cfg = [];
cfg.trials = find(mean(S)<2);
data = ft_selectdata(cfg, data);

cfg = [];
cfg.gradient = 'G3BR';
data_G3BR = ft_denoise_synthetic(cfg, data);

% ft_denoise_pca has a few knobs to turn. For this reason, and because it
% is an adaptive algorithm that depends on the data (i.e. when there's a
% brain in the machine, it's possible that signals of neural origin are
% suppressed as well, if there's no truncation, also: strong artifacts at
% the reference channels will have an impact on the estimated weights
cfg = [];
%cfg.truncate = 25; 
data_pca = ft_denoise_pca(cfg, data);

cfg = [];
cfg.method  = 'mtmfft';
cfg.output  = 'pow';
cfg.foilim  = [0 200];
cfg.taper   = 'hanning';
cfg.channel = 'MEG';

freq      = ft_freqanalysis(cfg, data);
freq_G3BR = ft_freqanalysis(cfg, data_G3BR);
freq_pca  = ft_freqanalysis(cfg, data_pca);


figure;
subplot(2,2,1); plot(freq.freq,mean(log10(freq.powspctrm))); title('original','interpreter','none'); ylim([-30 -27]);
subplot(2,2,2); plot(freq_G3BR.freq,mean(log10(freq_G3BR.powspctrm))); title('G3BR','interpreter','none'); ylim([-30 -27]);
subplot(2,2,3); plot(freq_pca.freq,mean(log10(freq_pca.powspctrm))); title('pca','interpreter','none'); ylim([-30 -27]);



cfg = [];
cfg.layout = 'CTF275_helmet.mat';
cfg.xlim   = [19.9 20.1];
cfg.figure = 'gca';

cfglog = [];
cfglog.operation = 'log10';
cfglog.parameter = 'powspctrm';

figure;
subplot(2,2,1); ft_topoplotER(cfg, ft_math(cfglog, freq));
subplot(2,2,2); ft_topoplotER(cfg, ft_math(cfglog, freq_G3BR));
subplot(2,2,3); ft_topoplotER(cfg, ft_math(cfglog, freq_pca));

%exportgraphics(gcf,'emptyroom_spectra_20211021.pdf','ContentType','vector');
