% This script investigates some data that contains a reported artifact by
% Bob Bramson, early 2022
%
% 20220119, J.M.Schoffelen, DCCN 

datadir = '/project/3055020.01/raw/';
year = '2022';
date = '20220111';

d = dir(fullfile(datadir,year,date,'sub000*.ds'));
dataset = fullfile(d.folder, d.name);

cfg = [];
cfg.dataset = dataset;
hdr = ft_read_header(cfg.dataset);

% quick and dirty 5 second chunks
N = hdr.nSamples*hdr.nTrials;
trl = [1:6000:(N-5999);6000:6000:N]';
trl(:,3) = 0;

cfg.trl = trl;%(1:min(size(trl,1),12*10),:);
cfg.channel = 'MEG';
cfg.demean  = 'yes';
cfg.continuous = 'yes';
data = ft_preprocessing(cfg);

cfg.channel = 'EEG';
eeg = ft_preprocessing(cfg);

cfg.channel = hdr.label(match_str(hdr.chantype, 'adc'));
adc = ft_preprocessing(cfg);

S = [];
Seeg = [];
Sadc = [];
for kk = 1:numel(data.trial)
  S(:,kk) = std(data.trial{kk},[],2);
  Seeg(:,kk) = std(eeg.trial{kk},[],2);
  Sadc(:,kk) = std(adc.trial{kk},[],2);
end

% discard the last chunk of trials, which almost always contain an
% end-of-recording clip
S = S(:, 1:end-5);
Seeg = Seeg(:, 1:end-5);
Sadc = Sadc(:, 1:end-5);
%S = S./std(S,[],2);
 
% visualize a 'moving median' of the channel specific std (over 5 s
% chunks), which removes the spikes.
figure;plot((1:size(S,2)).*5,(ft_preproc_medianfilter(S,9)));
xlabel('time (s)'); ylabel('MEG signal std per 5 s')

figure;plot((1:size(S,2)).*5,(ft_preproc_medianfilter(Seeg,9)));
xlabel('time (s)'); ylabel('EEG signal std per 5 s')

figure;plot((1:size(S,2)).*5,(ft_preproc_medianfilter(Sadc,9)));
xlabel('time (s)'); ylabel('adc signal std per 5 s')

cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.foilim = [0 600];
cfg.taper = 'dpss';
cfg.tapsmofrq = 0.6;
cfg.keeptrials = 'yes';
cfg.trials = 1:size(S,2);
freq = ft_freqanalysis(cfg, data);

% compute the ratio between 'trials' 20-80 and 160-220
p1 = squeeze(median(freq.powspctrm(20:80,:,:)));
p2 = squeeze(median(freq.powspctrm(160:220,:,:)));

figure;plot(freq.freq, p2./p1);
xlabel('frequency (Hz)'); ylabel('power ratio');

% there is a prominent increase in the power of the higher
% harmonics of the power line, given the multitaper settings used above, it
% is strongest at 150.6 Hz, and of course there's a lot of rubbish > 200,
% and beyond the cutoff of the analog filter
ix = nearest(freq.freq, 200);
iy = nearest(freq.freq, 300);
figure;plot((1:size(S,2)).*5, log10(mean(freq.powspctrm(:,:,ix:iy),3)));
xlabel('time (s)'); ylabel('log10 power [200-300] Hz');
