% This script investigates some data that contains a reported artifact by
% Bob Bramson, early 2022, it analyses all data collected in the past few
% weeks (while the power supply was replaced and something with the fans),
% to give an impression that the artifact is still there
%
% 20220413, J.M.Schoffelen, DCCN 

%%
datadir = '/project/3055020.01/raw/';
year    = '2022';
%year    = '2021';

pwdir = pwd;
cd(fullfile(datadir, year));
d = dir('*/*.ds');
cd(pwdir);

for k = 1:numel(d)
  D{k,1} = fullfile(d(k).folder, d(k).name);
end

%take the measurements from March/April 2022
sel = contains(D, '202203') | contains(D, '202204');
D = D(sel);
n = numel(D);

%%

for k = 1:numel(D)
  dataset = D{k};

  try
    meg_quality_artifact_highnoise_spectrum(dataset);
    %exportgraphics(gcf, 'datasweep2022_20220413.pdf', 'Append', true);
    %close all
  end
end
