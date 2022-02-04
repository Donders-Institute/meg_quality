% This script investigates some data that contains a reported artifact by
% Bob Bramson, early 2022
%
% 20220203, J.M.Schoffelen, DCCN 

%%
datadir = '/project/3055020.01/raw/';
year = '2022';

date     = '20220203';
dataset1 = 'sub004ses03run03_3023009.06_20220203_01.ds'; % heeft continu artifact
dataset2 = 'sub004ses04run01_3023009.06_20220203_01.ds'; % variance over time zakt af indien lpfiltered
dataset1 = fullfile(datadir,year,date,dataset1);
dataset2 = fullfile(datadir,year,date,dataset2);

date     = '20220127';
dataset3 = 'sub004ses02run3_3023009.06_20220127_01.ds'; % deze zou schoon zijn na filteren
dataset3 = fullfile(datadir,year,date,dataset3);

%%
datasets = {dataset1 dataset2 dataset3};
for k = 1:numel(datasets)
  cfg = [];
  cfg.dataset = datasets{k};
  hdr = ft_read_header(cfg.dataset);

  % quick and dirty 5 second chunks
  N        = hdr.nSamples*hdr.nTrials;
  trl      = [1:6000:(N-5999);6000:6000:N]';
  trl(:,3) = 0;

  cfg.trl = trl(1:2:end,:);%(1:min(size(trl,1),12*10),:);
  cfg.channel = 'MLT11';%'MEG';
  cfg.demean  = 'yes';
  cfg.continuous = 'yes';
  data = ft_preprocessing(cfg);

  cfg        = [];
  cfg.method = 'mtmfft';
  cfg.output = 'pow';
  cfg.foilim = [0 600];
  cfg.taper  = 'hanning';
  cfg.keeptrials = 'yes';
  freq{k}    = ft_freqanalysis(cfg, data);
end

%%
figure; imagesc(freq{1}.freq, 10*(1:numel(freq{1}.cumtapcnt)), log10(squeeze(freq{1}.powspctrm(:,1,:)))); xlabel('frequency (Hz)'); ylabel('time (s)'); title(dataset1(39:54),'interpreter','none');
figure; imagesc(freq{2}.freq, 10*(1:numel(freq{2}.cumtapcnt)), log10(squeeze(freq{2}.powspctrm(:,1,:)))); xlabel('frequency (Hz)'); ylabel('time (s)'); title(dataset2(39:54),'interpreter','none');
figure; imagesc(freq{3}.freq, 10*(1:numel(freq{3}.cumtapcnt)), log10(squeeze(freq{3}.powspctrm(:,1,:)))); xlabel('frequency (Hz)'); ylabel('time (s)'); title(dataset3(39:54),'interpreter','none');

%%
% load data from dataset2
cfg = [];
cfg.dataset = datasets{2};
hdr = ft_read_header(cfg.dataset);

% quick and dirty 5 second chunks
N        = hdr.nSamples*hdr.nTrials;
trl      = [1:6000:(N-5999);6000:6000:N]';
trl(:,3) = 0;

cfg.trl = trl(1:2:end,:);%(1:min(size(trl,1),12*10),:);
cfg.channel = {'MEG' 'MEGREF'};
cfg.demean  = 'yes';
cfg.continuous = 'yes';
data = ft_preprocessing(cfg);

%%
% the spectral artifact is a drifting peak that shifts from 45-55 in the
% first chunk to 275-285 in the last chunk
bplow  = linspace(40,270,128);
bphigh = linspace(60,290,128);
for k = 1:numel(data.trial)
  tmp = ft_preproc_bandpassfilter(data.trial{k}, 1200, [bplow(k) bphigh(k)], [], 'firws');
  S(:,k) = std(tmp, [], 2);
end

%%
F        = [];
F.label  = data.label;
F.powspctrm    = S;
F.dimord = 'chan_freq';
F.time   = (bplow+bphigh)./2;

cfg = [];
cfg.layout = 'CTF275_helmet.mat';
cfg.parameter = 'powspctrm';
ft_topoplotER(cfg, F);
% the spatial topography is quite constant over frequency, with a hotspot
% in MLT32

%%

cfg = [];
cfg.gradient = 'G3BR';
data_g3br = ft_denoise_synthetic(cfg, data);

cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.foilim = [0 600];
cfg.taper = 'hanning';
cfg.keeptrials = 'yes';
cfg.channel = 'MLT32';
freq_g3br = ft_freqanalysis(cfg, data_g3br);

figure; imagesc(freq{2}.freq, 10*(1:numel(freq{2}.cumtapcnt)), log10(squeeze(freq_g3br.powspctrm(:,1,:)))); xlabel('frequency (Hz)'); ylabel('time (s)'); title(dataset2(39:54),'interpreter','none');
% third order gradient balancing does not help here
clear data_g3br

% is the artifact visible on the references? -> yes
cfg.channel = 'MEGREF';
freqref = ft_freqanalysis(cfg, data);
figure; imagesc(freq{2}.freq, 10*(1:numel(freq{2}.cumtapcnt)), log10(squeeze(freqref.powspctrm(:,15,:)))); xlabel('frequency (Hz)'); ylabel('time (s)'); title(dataset2(39:54),'interpreter','none');

% is it perhaps out of phase with the sensors? -> no clear indication that
% this is the case. Perhaps the artifact's source is close by?
figure;plot(data.time{1}, zscore(data.trial{1}(15,:))); 
hold on;plot(data.time{1}, zscore(data.trial{1}(138,:))); xlim([1 1.2]);

figure;plot(data.time{1}, zscore(data.trial{1}(100:120,:), 0, 2)); xlim([1 1.2]);

%%
% do a PCA on filtered data:
cfg = [];
cfg.channel = 'MEG';
datameg = ft_selectdata(cfg, data);

% the spectral artifact in this dataset is a drifting peak that shifts from 45-55 in the
% first chunk to 275-285 in the last chunk
bplow  = linspace(40,270,128);
bphigh = linspace(60,290,128);
for k = 1:numel(datameg.trial)
  datameg.trial{k} = ft_preproc_bandpassfilter(datameg.trial{k}, 1200, [bplow(k) bphigh(k)], [], 'firws');
end

% memory problems require downsampling, or cell mode processing -> JM
% hacked ft_componentanalysis for now
cfg = [];
cfg.method = 'pca';
cfg.cellmode = 'yes';
comp = ft_componentanalysis(cfg, datameg);

cfgsel = [];
cfgsel.channel = 'MEG';

cfg = [];
cfg.component = [1 2];
dataclean     = ft_rejectcomponent(cfg, comp, ft_selectdata(cfgsel, data));

cfg        = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.foilim = [0 600];
cfg.taper  = 'hanning';
cfg.keeptrials = 'yes';
cfg.channel = 'MLT32';
freqclean   = ft_freqanalysis(cfg, dataclean);
freqdirty   = ft_freqanalysis(cfg, data);
figure; imagesc(freqdirty.freq, 10*(1:numel(freqdirty.cumtapcnt)), log10(squeeze(freqdirty.powspctrm(:,1,:)))); xlabel('frequency (Hz)'); ylabel('time (s)'); title(dataset2(39:54),'interpreter','none');
figure; imagesc(freqclean.freq, 10*(1:numel(freqclean.cumtapcnt)), log10(squeeze(freqclean.powspctrm(:,1,:)))); xlabel('frequency (Hz)'); ylabel('time (s)'); title(dataset2(39:54),'interpreter','none');

%%
% evaluate whether this strategy will also work for the other dataset


