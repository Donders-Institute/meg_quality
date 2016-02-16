function meg_quality_cronjob

% this function is running every night and computes some quality measures
% for each of the datasets that is found on odin.

try

clear all
clear global

% ensure that the script is executed in the right directory
cd /home/common/meg_quality

% ensure that the path is set to a fully clean version
restoredefaultpath
addpath /home/common/matlab/fieldtrip
ft_defaults

prefix  = '/mnt/megdata/meg/ACQ_Data/';
dataset = {};
day     = dir(sprintf('%s/20*',prefix));
day     = {day.name};

for i=1:length(day)
session = dir(sprintf('/mnt/megdata/meg/ACQ_Data/%s/*.ds', day{i}));
session = {session.name};
for j=1:length(session)
session{j} = fullfile(prefix, day{i}, session{j});
end
dataset = cat(2, dataset, session);
end

for i=1:length(dataset)

% determine the exportname that ft_qualitycheck would have used on a previous run
matfile = qualitycheck_exportname(dataset{i});

if ~exist(matfile, 'file')
fprintf('processing %s -> %s\n', dataset{i}, matfile);

try
cfg = [];
cfg.dataset = dataset{i};
cfg.analyze   = 'yes';
cfg.savemat   = 'yes';
cfg.visualize = 'yes';
cfg.saveplot  = 'yes';
ft_qualitycheck(cfg);
catch ME
warning('problem executing ft_qualitycheck');
disp(ME);
end % catch

else
fprintf('%s already exists\n', matfile);
end % processing

end % for all present datasets

catch ME
warning('problem executing meg_quality_cronjob');
disp(ME);
end

exit

