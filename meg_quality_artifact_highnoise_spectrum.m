% This function create a spectrum (over time) for the full bandwidth of the
% specified recording, for the MRT/MLT channels, to get a glimpse of the by
% now infamous high frequency walking artifact. It is the same code that is
% used in a few other scripts that were written to create a PDF-file for
% many recordings at once
%
% 20220317, J.M.Schoffelen, DCCN

dataset   = '/data/20220414/sub004ses03_3035001.02_20220414_01.ds';
tapsmofrq = 1;
duration  = []; % use the default
trials    = []; % use the default

%% 1) read in subset of data for artifact peak detection
cfg = [];
cfg.dataset = dataset;
hdr = ft_read_header(cfg.dataset);

% quick and dirty 5 second chunks
if isempty(duration)
  if hdr.Fs==1200
    duration = 5;
  else
    duration = 2; % memory wise more efficient
  end
end
nn = duration.*hdr.Fs;

N        = hdr.nSamples*hdr.nTrials;
trl      = [1:nn:(N-nn+1);nn:nn:N]';
trl(:,3) = 0;

if isempty(trials)
  ntrl = size(trl,1);
  if ntrl>51
    sel = ceil(linspace(1,ntrl-1,51));
    trl = trl(sel(1:end-1),:);
  end
elseif isequal(trials, 'all')
  % compute all trials
else
  trl = trl(trials,:);
end

cfg.trl = trl;
cfg.channel    = {'MLT' 'MRT'};%'MEG';
cfg.demean     = 'yes';
cfg.continuous = 'yes';
cfg.dftfilter  = 'yes';
cfg.hpfilter   = 'yes';
cfg.hpfreq     = 0.5;
cfg.hpfilttype = 'firws';
cfg.usefftfilt = 'yes';
data = ft_preprocessing(cfg);

tim  = data.sampleinfo(:,1)./data.fsample + data.time{1}(ceil(numel(data.time{1})/2));

%% 2) spectral transformation
cfg = [];
cfg.method     = 'mtmfft';
cfg.output     = 'pow';
cfg.foilim     = [0 hdr.Fs./2];
cfg.keeptrials = 'yes';
cfg.tapsmofrq  = tapsmofrq;
freq = ft_freqanalysis(cfg, data);

% show what it looks like
close all;
figure; imagesc(freq.freq,  tim, squeeze(mean(log10(freq.powspctrm),2)));
xlabel('frequency (Hz)');
ylabel('time (s)');
[f,p,e] = fileparts(dataset);
title(p, 'interpreter', 'none');
drawnow
