% This script investigates some data that contains a reported artifact by
% Bob Bramson, early 2022
%
% 20220124, J.M.Schoffelen, DCCN 

datadir = '/project/3055020.01/raw/';
year = '2022';
date = '20220121';

d = dir(fullfile(datadir,year,date,'emptyroom*04.ds'));
dataset = fullfile(d.folder, d.name);

cfg = [];
cfg.dataset = dataset;
hdr = ft_read_header(cfg.dataset);

% quick and dirty 5 second chunks
N = hdr.nSamples*hdr.nTrials;
trl = [1:12000:(N-11999);12000:12000:N]';
trl(:,3) = 0;

cfg.trl = trl(1:2:end,:);%(1:min(size(trl,1),12*10),:);
cfg.channel = 'MEG';
cfg.demean  = 'yes';
cfg.continuous = 'yes';
data = ft_preprocessing(cfg);

cfg.channel = 'MEGREF';
megref = ft_preprocessing(cfg);
% 
% cfg.channel = 'EEG';
% eeg = ft_preprocessing(cfg);
% 
% cfg.channel = hdr.label(match_str(hdr.chantype, 'adc'));
% adc = ft_preprocessing(cfg);

S = [];
Seeg = [];
Sadc = [];
Sref = [];
for kk = 1:numel(data.trial)
  S(:,kk) = std(ft_preproc_highpassfilter(data.trial{kk},12000,200,[],'but'),[],2);
%   Seeg(:,kk) = std(eeg.trial{kk},[],2);
%   Sadc(:,kk) = std(adc.trial{kk},[],2);
%   Sref(:,kk) = std(megref.trial{kk},[],2);
end

% discard the last chunk of trials, which almost always contain an
% end-of-recording clip
% S = S(:, 1:end-5);
% Seeg = Seeg(:, 1:end-5);
% Sadc = Sadc(:, 1:end-5);
% Sref = Sref(:, 1:end-5);
% %S = S./std(S,[],2);
 
% visualize a 'moving median' of the channel specific std (over 5 s
% chunks), which removes the spikes.
figure;plot((1:size(S,2)).*5,(ft_preproc_medianfilter(S,9)));
xlabel('time (s)'); ylabel('MEG signal std per 5 s')

% figure;plot((1:size(S,2)).*5,(ft_preproc_medianfilter(Seeg,9)));
% xlabel('time (s)'); ylabel('EEG signal std per 5 s')
% 
% figure;plot((1:size(S,2)).*5,(ft_preproc_medianfilter(Sadc,9)));
% xlabel('time (s)'); ylabel('adc signal std per 5 s')
% 
% figure;plot((1:size(S,2)).*5,(ft_preproc_medianfilter(Sref,9)));
% xlabel('time (s)'); ylabel('MEGREF signal std per 5 s')

cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.foilim = [0 3000];
cfg.taper = 'hanning';
%cfg.tapsmofrq = 0.6;
cfg.keeptrials = 'yes';
cfg.trials = 1:size(S,2);
freq = ft_freqanalysis(cfg, data);
freqref = ft_freqanalysis(cfg, megref);

% compute the ratio between 'trials' 20-80 and 160-220
p1 = squeeze(mean(freq.powspctrm(1:100,:,:)));
p2 = squeeze(mean(freq.powspctrm(151:250,:,:)));

figure;plot(freq.freq, log10(p1)-log10(p2));
xlabel('frequency (Hz)'); ylabel('power ratio');

figure;plot(freq.freq, log10(p1));
xlabel('frequency (Hz)'); ylabel('log10(power)');
figure;plot(freq.freq, log10(p2));
xlabel('frequency (Hz)'); ylabel('log10(power)');

% compute the ratio between 'trials' 20-80 and 160-220
p1 = squeeze(mean(freqref.powspctrm(1:100,:,:)));
p2 = squeeze(mean(freqref.powspctrm(151:250,:,:)));

figure;plot(freq.freq, log10(p1)-log10(p2));
xlabel('frequency (Hz)'); ylabel('power ratio');

figure;plot(freq.freq, log10(p1));
xlabel('frequency (Hz)'); ylabel('log10(power)');
figure;plot(freq.freq, log10(p2));
xlabel('frequency (Hz)'); ylabel('log10(power)');

% it seems in this case also present at the reference signals
cfgsel.trials = 1:100;
data = ft_selectdata(cfgsel, data);
megref = ft_selectdata(cfgsel, megref);

data = ft_appenddata([], data, megref);

cfg = [];
cfg.gradient = 'G3BR';
dataclean = ft_denoise_synthetic(cfg, data);

cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.foilim = [0 3000];
cfg.taper = 'hanning';
cfg.channel = 'MEG';
freqclean = ft_freqanalysis(cfg, dataclean);
figure;plot(freq.freq, log10(freqclean.powspctrm));
xlabel('frequency (Hz)'); ylabel('log10(power)');
% conclusion 3D order gradient does not work here.