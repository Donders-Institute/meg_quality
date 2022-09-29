% This script computes the power spectra for the empty room recordings, and
% creates a PDF for a quick overview, displaying the sensor averaged, log
% transformed spectra. 
%
% 20211022, J.M.Schoffelen, DCCN 

datadir = '/project/3055020.01/raw/';
cd(datadir);
[dum,list] = system('ls -d */*/empty*.ds');
files = tokenize(list, char(10));

datasets = cell(numel(files),1);
for k = 1:numel(files)
  datasets{k,1} = fullfile(datadir, files{k});
end

freq = cell(1,numel(datasets));
for k = 1:numel(datasets)
  try
    cfg = [];
    cfg.dataset = datasets{k};
    hdr = ft_read_header(cfg.dataset);

    % quick and dirty 5 second chunks
    N = hdr.nSamples*hdr.nTrials;
    trl = [1:3000:(N-5999);6000:3000:N]';
    trl(:,3) = 0;

    % let's go for about 10 minutes of data, or less
    cfg.trl        = trl(1:min(size(trl,1),12*10),:);
    cfg.channel    = 'MEG';
    cfg.demean     = 'yes';
    cfg.continuous = 'yes';
    data           = ft_preprocessing(cfg);

    % another quick and dirty trick, to identify outlier chunks
    S = [];
    for kk = 1:numel(data.trial)
      S(:,kk) = std(data.trial{kk},[],2);
    end
    S = (S-mean(S,2))./std(S,[],2);

    cfg        = [];
    cfg.method = 'mtmfft';
    cfg.output = 'pow';
    cfg.foilim = [0 200];
    cfg.taper  = 'hanning';
    cfg.trials = find(mean(S)<2); % subselection of chunks
    freq{k}    = ft_freqanalysis(cfg, data);
  end
end

sel  = ~cellfun('isempty', freq);
freq = freq(sel);
datasets = datasets(sel);

nperpage = 16;
ny = floor(sqrt(nperpage));
nx = ceil(sqrt(nperpage));
npage = ceil(numel(freq))/nperpage;
count = 0;
for m = 1:npage
  figure;
  for k = 1:nperpage
    count = count + 1;
    if count>numel(freq)
      continue;
    end
    [p, f] = fileparts(datasets{count});
    f = tokenize(f, '_');
    f = f{end-1};
    subplot(ny,nx,k);plot(freq{count}.freq,mean(log10(freq{count}.powspctrm))); title(f,'interpreter','none'); ylim([-30 -27.5]);
    drawnow;
  end
  if m>1
    exportgraphics(gcf,'emptyroom_spectra.pdf','ContentType','vector','Append',true);
  else
    exportgraphics(gcf,'emptyroom_spectra.pdf','ContentType','vector');
  end
end
