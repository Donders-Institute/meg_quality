% This script investigates some data that contains a reported artifact by
% Bob Bramson, early 2022, specifically it analyses some data that has been
% collected by Miranda and Uriel, as per the instruction of the CTF
% engineers
%
% 20220222, J.M.Schoffelen, DCCN 

%%
datadir = '/project/3055020.01/raw/';
year    = '2022';

date     = '20220216';
datasets = {'emptyroom_Noise_20220216_01.ds'
            'emptyroom_Noise_20220216_02.ds'
            'emptyroom_Noise_20220216_03.ds'
            'emptyroom_Noise_20220216_05.ds'
            'emptyroom_Noise_20220216_06.ds'
            'emptyroom_Noise_20220216_07.ds'
            'emptyroom_Noise_20220216_08.ds'};

for k = 1:numel(datasets)
  D{k,1} = fullfile(datadir, year, date, datasets{k});
end
n = numel(D);

date     = '20220221';
datasets = {'emptyroom_Noise_20220221_01.ds';
            'emptyroom_Noise_20220221_02.ds'};

for k = 1:numel(datasets)
  D{k+n,1} = fullfile(datadir, year, date, datasets{k});
end

% this is the description that was given by Miranda about the datasets 
description = {'Fs 1200: door closed with noise';
  'Fs 12000: door closed with noise';
  'Fs 12000: door open at 90 degrees';
  'Fs 12000: door closed, dewar supine';
  'Fs 1200: door closed, dewar supine';
  'undescribed situation';
  'Fs 1200: door closed, dewar at 15 degrees';
  'Fs 1200: door closed with noise';
  'Fs 1200: all cables removed except oxygen sensor'};


%%

% The morphology of the artifact is a (high frequency) peak in the
% spectrum, with 2 flanking peaks at +/- 50 Hz, which reflect a beat with
% the powerline fluctuations. The centre frequency changes over time, is
% usually of sufficiently high frequency to make it disappear with a
% lowpassfilter with a cutoff that does not affect physiological
% frequencies. However, sometimes the peak (likely reflecting a beat
% between two system clocks) is drifting into lower frequencies. There, 
% the spectral peak even wraps around 0. The spatial distribution of the
% artifact does not suggest a far away source, which make 3d order
% gradient balancing useless. A generic solution might be to use PCA
% (based on the MEG channels), where the strategy would be to sensitize
% the data for the drifting artifact, requiring a per segment peak
% detection. This leads to the following steps: 1) read in the data in
% chunks of 5 s (focus on MLT and MRT which seem anecdotally most often
% affected), 2) do spectral transformation, 3) detect the peak using the
% +/- 50 Hz morphology, 4) read in all MEG data, 5) band-pass filter with
% optimized frequency band per trial, 6) PCA, 7) identify to-be-rejected
% topographies, 8) store the identified topographies to-be-used on the
% data-of-interest.


for k = 1:numel(D)
  dataset = D{k};

  %% 1) read in subset of data for artifact peak detection
  cfg = [];
  cfg.dataset = dataset;
  hdr = ft_read_header(cfg.dataset);

  % quick and dirty 5 second chunks
  if hdr.Fs==1200
    nn = hdr.Fs.*5;
  else
    nn = hdr.Fs.*2; % memory wise more efficient
  end

  N        = hdr.nSamples*hdr.nTrials;
  trl      = [1:nn:(N-nn+1);nn:nn:N]';
  trl(:,3) = 0;
  trl = trl(1:2:end,:);

  cfg.trl = trl;
  cfg.channel = 'MEG';%{'MLT' 'MRT'};%'MEG';
  cfg.demean  = 'yes';
  cfg.continuous = 'yes';
  cfg.dftfilter = 'yes';
  cfg.hpfilter  = 'yes';
  cfg.hpfreq    = 0.5;
  cfg.hpfilttype = 'firws';
  cfg.usefftfilt = 'yes';
  data = ft_preprocessing(cfg);

  %% 2) spectral transformation
  cfg        = [];
  cfg.method = 'mtmfft';
  cfg.output = 'pow';
  cfg.foilim = [0 hdr.Fs./2];
  cfg.keeptrials = 'yes';
  cfg.tapsmofrq  = 1;
  freq       = ft_freqanalysis(cfg, data);

  % show what it looks like
  figure; imagesc(freq.freq, 10*(1:numel(freq.cumtapcnt)), squeeze(mean(log10(freq.powspctrm),2)));
  xlabel('frequency (Hz)');
  ylabel('time (s)');

  %% 3) detect peak to be used for PCA preprocessing
  pow   = squeeze(mean(log10(freq.powspctrm),2));
  pow   = imgaussfilt(pow, 2); % requires imageprocessing toolbox
  freqs = freq.freq;
  n     = numel(freqs);

  % make reference signal for cross-correlation
  sel   = nearest(freqs, [0 50]);
  sel   = [sel diff(sel)+sel(2)]; % three 'peaks' 50 Hz apart
  ref   = zeros(1, max(sel));
  ref(sel) = 1;
  ref   = [zeros(1,(n-numel(ref))/2) ref zeros(1,(n-numel(ref))/2)];
  ref   = convn(ref, hanning(20)', 'same');
  ref   = ref-mean(ref);
  for m = 1:size(pow,1)
    pow_ = pow(m,:) - mean(pow(m,:));
    [X(m,:), lags] = xcorr(pow_, ref, 'coeff');
  end
  X = imgaussfilt(X, 2); % filter once more
  for m = 1:size(X,1)
    [dummy, M(m,1)] = max(X(m,:));
  end
  M = M - (n-1)./2;

  figure; hold on;
  imagesc(pow);
  plot(M, 1:size(pow,1), 'wo');
  axis xy; axis tight

  bpfreq = freqs(M)' + repmat([-5 5], [numel(M) 1]);

  %% 4) read in the MEG data (now all channels)
  cfg = [];
  cfg.dataset = dataset;
  cfg.trl = trl;
  cfg.channel = 'MEG';
  cfg.demean  = 'yes';
  cfg.continuous = 'yes';
  data = ft_preprocessing(cfg);

  try
  %% 5) bandpass filter per trial
  dataorig = data;
  for m = 1:numel(data.trial)
    data.trial{m} = ft_preproc_bandpassfilter(data.trial{m}, hdr.Fs, bpfreq(m,:), [], 'firws', [], [], [], [], [], [], 1);
  end
  end

  %% 6) PCA
  cfg          = [];
  cfg.method   = 'pca';
  cfg.cellmode = 'yes';
  comp         = ft_componentanalysis(cfg, data);

  V = zeros(numel(comp.label), numel(comp.trial));
  for m = 1:numel(comp.trial)
    V(:,m) = var(comp.trial{m},[],2);
  end
  figure;plot(log10(mean(V,2)),'o');
  ylabel('variance (T^2)');
  xlabel('component #');

  cfg = [];
  cfg.component = 1:4;
  cfg.layout = 'CTF275_helmet.mat';
  cfg.zlim = 'maxabs';
  ft_topoplotIC(cfg, comp);
  exportgraphics(gcf, 'emptyroom_analysis_20220223.pdf', 'Append', true);

  %% 7) reject components and evaluate the effect
  Vm = mean(V, 2)';
  Vm = Vm./Vm(1);
  cfg = [];
  cfg.component = find(Vm>0.01); % this may be specific to the dataset
  data = ft_rejectcomponent(cfg, comp, dataorig);

  cfg        = [];
  cfg.method = 'mtmfft';
  cfg.output = 'pow';
  cfg.foilim = [0 hdr.Fs./2];
  cfg.keeptrials = 'yes';
  cfg.tapsmofrq  = 1;
  freqorig   = ft_freqanalysis(cfg, dataorig);
  freq       = ft_freqanalysis(cfg, data);

  % show what it looks like
  figure; imagesc(freq.freq, 2*(nn./hdr.Fs)*(1:numel(freq.cumtapcnt)), squeeze(mean(log10(freqorig.powspctrm),2)));
  xlabel('frequency (Hz)');
  ylabel('time (s)');
  abc = caxis;
  title(sprintf('%s pre cleaning, %s', D{k}(end-13:end-3), description{k}), 'interpreter', 'none');
  exportgraphics(gcf, 'emptyroom_analysis_20220223.pdf', 'Append', true);

  figure; imagesc(freq.freq, 2*(nn./hdr.Fs)*(1:numel(freq.cumtapcnt)), squeeze(mean(log10(freq.powspctrm),2)));
  xlabel('frequency (Hz)');
  ylabel('time (s)');
  caxis(abc);
  title(sprintf('%s post cleaning', D{k}(end-13:end-3)), 'interpreter', 'none');
  exportgraphics(gcf, 'emptyroom_analysis_20220223.pdf', 'Append', true);

  figure; hold on
  sel = match_str(data.label, 'MLT32');
  plot(dataorig.time{1}, dataorig.trial{1}(sel,:));
  plot(data.time{1}, data.trial{1}(sel,:));
  xlim([0.5 1.5]);
  xlabel('time (s)');
  ylabel('MEG amplitude (T)');
  title(sprintf('%s channel MLT32', D{k}(end-13:end-3)), 'interpreter', 'none');
  exportgraphics(gcf, 'emptyroom_analysis_20220223.pdf', 'Append', true);

  clear data dataorig freq comp X M
  close all
end

