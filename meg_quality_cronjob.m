function meg_quality_cronjob

% MEM 8gb
% WALLTIME 8:00:00

% this function is running every night and computes some quality measures
% for each of the new MEG datasets

try
  
  clear all
  clear global
  
  % ensure that the script is executed in the right directory
  cd /project/3010102.04/quality
  
  % ensure that the path is set to a fully clean version
  restoredefaultpath
  addpath /home/common/matlab/fieldtrip
  addpath /project/3010102.04/scripts/meg_quality
  ft_defaults
  
  % ensure that the data is read from the correct location
  prefix  = '/project/3010102.04/raw';
  
  dataset = {};
  day     = dir(sprintf('%s/20*',prefix));
  day     = {day.name};
  
  for i=1:length(day)
    session = dir(sprintf('%s/%s/*.ds', prefix, day{i}));
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

