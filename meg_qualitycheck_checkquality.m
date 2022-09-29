% This script sets up ft_qualitycheck for a single run, this is used to
% profile (and optimize) the function's behavior
% 20211116, J.M.Schoffelen, DCCN 

% ft_qualitycheck runs a for loop across 10-s chunks of data. As a
% consequence a lot of time is spent on bookkeeping (amble) computations,
% which are not going to be used later on anyhow, so switch this off
global ft_default;
ft_default.trackmeminfo  = 'no';
ft_default.tracktimeinfo = 'no';
ft_default.trackdatainfo = 'no';
ft_default.showcallinfo  = 'no';
ft_default.checkconfig   = 'no';

% avoid too much pollution to the screen output
ft_info once
ft_warning once
ft_notice once

datadir = '/project/3055020.01/raw/';
year = '2021';
date = '20211021';
d = dir(fullfile(datadir,year,date,'*.ds'));

datasets = cell(numel(d),1);
for k = 1:numel(d)
  datasets{k,1} = fullfile(d(k).folder, d(k).name);
end
dataset = datasets{1};

cfg                 = [];
cfg.dataset         = dataset;
cfg.trialfun        = 'ft_trialfun_general';
cfg.trialdef.length = 10;
cfg.continuous      = 'yes';
cfg = ft_definetrial(cfg);
trl = cfg.trl;

cfg = [];
cfg.dataset  = dataset;
cfg.trl      = trl(1:50,:);%(1:200,:); % run only 50 chunks for now
cfg.saveplot = 'none';
cfg.feedback = 'none';
ft_qualitycheck(cfg);

