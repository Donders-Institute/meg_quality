% This script investigates the quality of the headcoil positioning
% J.M.Schoffelen, DCCN 

%%
datadir = '/project/3055020.01/raw/';
year    = '2022';
%year    = '2021';

pwdir = pwd;
cd(fullfile(datadir, year));
d = dir('*/*.ds');
cd(pwdir);

[ftver, ftdir] = ft_version;
cd(fullfile(ftdir, 'private'));

delta = nan(numel(d),9);
for k = 1:numel(d)
  k
  fname = fullfile(d(k).folder,d(k).name,strrep(d(k).name,'ds','hc'));
  try
    hc = read_ctf_hc(fname);
    tmp  = [hc.dewar.nas-hc.standard.nas hc.dewar.lpa-hc.standard.lpa hc.dewar.rpa-hc.standard.rpa];
    delta(k,:) = tmp;
  end
end
D = sqrt(sum(delta.^2,2));

%% list the files for which the above failed, these may be true datasets, if the name starts with 'sub'
failed  = ~isfinite(D);
dfailed = d(failed); 
faileddatasets = {dfailed.name}';

selfailed = startsWith(faileddatasets, 'sub');
dfailed   = dfailed(selfailed);
for k = 1:numel(dfailed)
  system(sprintf('du -hs %s/%s',dfailed(k).folder,dfailed(k).name));
end

% concluion so far: the failed ones that start with 'sub' are aborted
% datasets, because the total size is < 8 MB

%% list the files which have the hc dewar coordinates expressed as standard, these are probably emptyroom or test datasets
zerodiff  = D==0;
dzerodiff = d(zerodiff);
zerodiffdatasets = {d(zerodiff).name}';
selzerodiff = startsWith(zerodiffdatasets, 'sub');
dzerodiff   = dzerodiff(selzerodiff);
for k = 1:numel(dzerodiff)
  system(sprintf('du -hs %s/%s',dzerodiff(k).folder,dzerodiff(k).name));
end

% this dataset is not empty, it contains a few 100 MB worth of data, but
% the sensor positions are off. However, it's a pilot dataset from the
% Martin group. Don't know what to do with this, but I tend to ignore for
% now

%%
sel = ~failed & ~zerodiff;

dsel = d(sel);
Dsel = D(sel);
deltasel = delta(sel, :);

%% select outliers of the above selection, based on some heuristic
outliers = any(deltasel>median(deltasel)+1.5.*iqr(deltasel,1), 2);

dcheck = dsel(outliers);
Dcheck = Dsel(outliers);
deltacheck = deltasel(outliers, :);

sel = startsWith({dcheck.name}, 'sub');
dcheck = dcheck(sel);
Dcheck = Dcheck(sel);
deltacheck = deltacheck(sel, :);

figure;
imagesc(deltacheck);
% based on the image, I think that [10 14 24 25] need further inspection
% the other ones are probably based on the z-coordinate of the nasion being
% higher up (in dewar space) than the ~-27 coordinate in standard space. I
% don't think that this is an issue

{dcheck([10 14 24 25]).name}'
% 14, 24 and 25 are datasets that were created when the issue that
% escalated this script occurred (i.e. with Rao, Rober and Uriel in the
% MEG-lab). This only leaves 10 for further inspection, which given the
% project number is a pilot for the Hagoort group. BTW the sensors are 

