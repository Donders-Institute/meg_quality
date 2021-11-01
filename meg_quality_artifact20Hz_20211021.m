% This script computes the power spectra for the empty room recordings, and
% creates a PDF for a quick overview, displaying the sensor averaged, log
% transformed spectra, specifically for the test recordings that Uriel and
% JM did on 20211021 to identify the cause of the 20 Hz (+harmonics)
% artifact
%
% 20211022, J.M.Schoffelen, DCCN 

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

for k = 1:numel(datasets)
  cfg = [];
  cfg.dataset = datasets{k};
  hdr = ft_read_header(cfg.dataset);
  
  % quick and dirty 5 second chunks
  N = hdr.nSamples*hdr.nTrials;
  trl = [1:3000:(N-5999);6000:3000:N]';
  trl(:,3) = 0;
  
  % let's go for about 10 minutes of data, or less
  cfg.trl = trl(1:min(size(trl,1),12*10),:);
  cfg.channel = 'MEG';
  cfg.demean  = 'yes';
  cfg.continuous = 'yes';
  data = ft_preprocessing(cfg);
  
  S = [];
  for kk = 1:numel(data.trial)
    S(:,kk) = std(data.trial{kk},[],2);
  end
  S = S./std(S,[],2);
 
  cfg = [];
  cfg.method = 'mtmfft';
  cfg.output = 'pow';
  cfg.foilim = [0 200];
  cfg.taper = 'hanning';
  cfg.trials = find(mean(S)<2);
  freq(k) = ft_freqanalysis(cfg, data);
end

freq = freq([1 2 3 5]);
titles = {'all off' 'camera on' 'camera+speaker on' 'speaker on'};
figure;
for k = 1:4
  subplot(2,2,k); plot(freq(k).freq,mean(log10(freq(k).powspctrm))); title(titles{k},'interpreter','none'); ylim([-30 -27]);
end
exportgraphics(gcf,'emptyroom_spectra_20211021.pdf','ContentType','vector');
