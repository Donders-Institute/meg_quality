% This script investigates some data that contains a reported artifact by
% Bob Bramson, early 2022, specifically it analyses some data that has been
% collected by Miranda and Uriel, as per the instruction of the CTF
% engineers
%
% 20220310, J.M.Schoffelen, DCCN 

%%
datadir = '/project/3055020.01/raw/';
%year    = '2022';
year    = '2021';

pwdir = pwd;
cd(fullfile(datadir, year));
d = dir('*/*.ds');
cd(pwdir);

for k = 1:numel(d)
  D{k,1} = fullfile(d(k).folder, d(k).name);
end
n = numel(D);

%%

for k = 1:numel(D)
  dataset = D{k};

  try
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
  
  ntrl = size(trl,1);
  if ntrl>51
    sel = ceil(linspace(1,ntrl-1,51));
    trl = trl(sel(1:end-1),:);
  end

  cfg.trl = trl;
  cfg.channel = {'MLT' 'MRT'};%'MEG';
  cfg.demean  = 'yes';
  cfg.continuous = 'yes';
  cfg.dftfilter = 'yes';
  cfg.hpfilter  = 'yes';
  cfg.hpfreq    = 0.5;
  cfg.hpfilttype = 'firws';
  cfg.usefftfilt = 'yes';
  data = ft_preprocessing(cfg);

  tim  = data.sampleinfo(:,1)./data.fsample + data.time{1}(ceil(numel(data.time{1})/2));

  %% 2) spectral transformation
  cfg        = [];
  cfg.method = 'mtmfft';
  cfg.output = 'pow';
  cfg.foilim = [0 hdr.Fs./2];
  cfg.keeptrials = 'yes';
  cfg.tapsmofrq  = 1;
  freq       = ft_freqanalysis(cfg, data);

  % show what it looks like
  close all;
  figure; imagesc(freq.freq,  tim, squeeze(mean(log10(freq.powspctrm),2)));
  xlabel('frequency (Hz)');
  ylabel('time (s)');
  [f,p,e] = fileparts(dataset);
  title(p, 'interpreter', 'none');
  drawnow;

  %exportgraphics(gcf, 'datasweep2022_20220310.pdf', 'Append', true);
  exportgraphics(gcf, 'datasweep2021_20220310.pdf', 'Append', true);
  end

end
% 
%   %% 3) detect peak to be used for PCA preprocessing
%   pow   = squeeze(mean(log10(freq.powspctrm),2));
%   pow   = imgaussfilt(pow, 2); % requires imageprocessing toolbox
%   freqs = freq.freq;
%   n     = numel(freqs);
% 
%   % make reference signal for cross-correlation
%   sel   = nearest(freqs, [0 50]);
%   sel   = [sel diff(sel)+sel(2)]; % three 'peaks' 50 Hz apart
%   ref   = zeros(1, max(sel));
%   ref(sel) = 1;
%   ref   = [zeros(1,(n-numel(ref))/2) ref zeros(1,(n-numel(ref))/2)];
%   ref   = convn(ref, hanning(20)', 'same');
%   ref   = ref-mean(ref);
%   for m = 1:size(pow,1)
%     pow_ = pow(m,:) - mean(pow(m,:));
%     [X(m,:), lags] = xcorr(pow_, ref, 'coeff');
%   end
%   X = imgaussfilt(X, 2); % filter once more
%   for m = 1:size(X,1)
%     [dummy, M(m,1)] = max(X(m,:));
%   end
%   M = M - (n-1)./2;
% 
%   figure; hold on;
%   imagesc(pow);
%   plot(M, 1:size(pow,1), 'wo');
%   axis xy; axis tight
% 
%   bpfreq = freqs(M)' + repmat([-5 5], [numel(M) 1]);
% 
%   %% 4) read in the MEG data (now all channels)
%   cfg = [];
%   cfg.dataset = dataset;
%   cfg.trl = trl;
%   cfg.channel = 'MEG';
%   cfg.demean  = 'yes';
%   cfg.continuous = 'yes';
%   data = ft_preprocessing(cfg);
% 
%   try
%   %% 5) bandpass filter per trial
%   dataorig = data;
%   for m = 1:numel(data.trial)
%     data.trial{m} = ft_preproc_bandpassfilter(data.trial{m}, hdr.Fs, bpfreq(m,:), [], 'firws', [], [], [], [], [], [], 1);
%   end
%   end
% 
%   %% 6) PCA
%   cfg          = [];
%   cfg.method   = 'pca';
%   cfg.cellmode = 'yes';
%   comp         = ft_componentanalysis(cfg, data);
% 
%   V = zeros(numel(comp.label), numel(comp.trial));
%   for m = 1:numel(comp.trial)
%     V(:,m) = var(comp.trial{m},[],2);
%   end
%   figure;plot(log10(mean(V,2)),'o');
%   ylabel('variance (T^2)');
%   xlabel('component #');
% 
%   cfg = [];
%   cfg.component = 1:4;
%   cfg.layout = 'CTF275_helmet.mat';
%   cfg.zlim = 'maxabs';
%   ft_topoplotIC(cfg, comp);
%   exportgraphics(gcf, 'emptyroom_analysis_20220228.pdf', 'Append', true);
% 
%   %% 7) reject components and evaluate the effect
%   Vm = mean(V, 2)';
%   Vm = Vm./Vm(1);
%   cfg = [];
%   cfg.component = find(Vm>0.01); % this may be specific to the dataset
%   data = ft_rejectcomponent(cfg, comp, dataorig);
% 
%   cfg        = [];
%   cfg.method = 'mtmfft';
%   cfg.output = 'pow';
%   cfg.foilim = [0 hdr.Fs./2];
%   cfg.keeptrials = 'yes';
%   cfg.tapsmofrq  = 1;
%   freqorig   = ft_freqanalysis(cfg, dataorig);
%   freq       = ft_freqanalysis(cfg, data);
% 
%   % show what it looks like
%   figure; imagesc(freq.freq, 2*(nn./hdr.Fs)*(1:numel(freq.cumtapcnt)), squeeze(mean(log10(freqorig.powspctrm),2)));
%   xlabel('frequency (Hz)');
%   ylabel('time (s)');
%   abc = caxis;
%   title(sprintf('%s pre cleaning, %s', D{k}(end-13:end-3), description{k}), 'interpreter', 'none');
%   exportgraphics(gcf, 'emptyroom_analysis_20220228.pdf', 'Append', true);
% 
%   figure; imagesc(freq.freq, 2*(nn./hdr.Fs)*(1:numel(freq.cumtapcnt)), squeeze(mean(log10(freq.powspctrm),2)));
%   xlabel('frequency (Hz)');
%   ylabel('time (s)');
%   caxis(abc);
%   title(sprintf('%s post cleaning', D{k}(end-13:end-3)), 'interpreter', 'none');
%   exportgraphics(gcf, 'emptyroom_analysis_20220228.pdf', 'Append', true);
% 
%   figure; hold on
%   sel = match_str(data.label, 'MLT32');
%   plot(dataorig.time{1}, dataorig.trial{1}(sel,:));
%   plot(data.time{1}, data.trial{1}(sel,:));
%   xlim([0.5 1.5]);
%   xlabel('time (s)');
%   ylabel('MEG amplitude (T)');
%   title(sprintf('%s channel MLT32', D{k}(end-13:end-3)), 'interpreter', 'none');
%   exportgraphics(gcf, 'emptyroom_analysis_20220228.pdf', 'Append', true);
% 
%   clear data dataorig freq comp X M
%   close all
% end

