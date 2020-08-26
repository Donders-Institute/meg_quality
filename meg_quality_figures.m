d = dir('*.mat')

for i=1:numel(d)
  close all
  disp('----------------------------------------------------------------');
  disp(d(i).name);
  
  try  cfg = [];
    cfg.analyze = 'no';
    cfg.matfile = d(i).name;
    ft_qualitycheck(cfg)
  end
end
