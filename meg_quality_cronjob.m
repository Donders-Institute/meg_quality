function meg_quality_cronjob

% MEM 12gb
% WALLTIME 18:00:00

% this function is running every night and computes some quality measures
% for each of the new MEG datasets

try
  %%
  clear global
  
  global ft_default
  ft_default.showcallinfo = 'no';
  ft_warning on
  ft_notice off
  ft_info   off
  ft_debug  off
  
  % ensure that the path is set to a fully clean version
  restoredefaultpath
  addpath /home/common/matlab/fieldtrip
  ft_defaults
  
  addpath /project/3055020.02/code
  
  % this is where the raw data is located
  prefix  = '/project/3055020.01/raw/2021';
  
  % this is where the results will end up
  cd /project/3055020.02/2021
  
  %%
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
  
  %%
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
        cfg.visualize = 'no';
        cfg.saveplot  = 'no';
        ft_qualitycheck(cfg);
      catch ME
        warning('problem executing ft_qualitycheck');
        disp(ME);
        for j=1:numel(ME.stack)
          disp(ME.stack(j));
        end
      end % catch
      
    else
      fprintf('%s already exists\n', matfile);
    end % processing
    
  end % for all present datasets
  
catch ME
  warning('problem executing ft_qualitycheck');
  disp(ME);
  for j=1:numel(ME.stack)
    disp(ME.stack(j));
  end
end

disp('COMPLETED');
exit
