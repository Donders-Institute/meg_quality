% This script computes the power spectra for the empty room recordings, while
% a rapid frequency tagging protocol was running
%
% 20211102, J.M.Schoffelen, DCCN 

datadir = '/project/3055020.01/raw/';
year = '2021';
date = '20211014';
d = dir(fullfile(datadir,year,date,'emptyroom*.ds'));

datasets = cell(numel(d),1);
for k = 1:numel(d)
  datasets{k,1} = fullfile(d(k).folder, d(k).name);
end

% sort 1-12
[srt,ix] = sort([d.datenum]);
d = d(ix);
datasets = datasets(ix);

% 1. MEG + licht aan
% 2. MEG + taak  +licht aan
% 3. MEG  + beamer + licht uit 
% 4. MEG + taak + beamer + licht uit
% 5. MEG + beamer + licht aan  
% 6. MEG  + taak + beamer + licht aan 
% 7. MEG + taak + beamer afgedekt + licht aan 
% 8. MEG + taak + audio + licht aan
% 9. MEG + taak + beamer + audio + licht aan 
% 10. MEG + taak + beamer + audio + eyetracking + licht aan (mijn opstelling)
% 
% EXTRA 
% 11. MEG + taak + beamer + audio + eyetracking + licht uit 
% 12. Empty room met Jan Mathijs

k = 11;
cfg                         = [];
cfg.dataset                 = datasets{k};
cfg.trialfun                = 'ft_trialfun_general'; % this is the default
cfg.trialdef.eventtype      = 'UPPT001';  %'frontpanel trigger'
cfg.trialdef.eventvalue     = [81:241]; % the value of the stimulus trigger
cfg.trialdef.prestim        = 1; % in seconds
cfg.trialdef.poststim       = 3; % in seconds
cfg                         = ft_definetrial(cfg);

cfg.continuous = 'yes';
cfg.channel                 = {'MEG'};
data                   = ft_preprocessing(cfg);
 
cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.foilim = [0 200];
cfg.taper = 'hanning';
freq = ft_freqanalysis(cfg, data);

figure;
plot(freq.freq,mean(log10(freq.powspctrm))); title('RFT experiment','interpreter','none'); ylim([-30 -27]);
