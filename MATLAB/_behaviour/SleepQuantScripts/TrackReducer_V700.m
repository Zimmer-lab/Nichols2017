clearvars -except MainDir FolderList NumDataSets i

close all; clc;
histogramBinning     = 100;
TrackLengthThreshold = 700;


%fileName = 'N2_O2_10.0_20121104_40worms_Z4_X6_11040852_tracks_als.mat';
path = './';

files = dir(strcat(path,'\*als.mat'));
for i = 1 : numel(files)
   
    fileName = files(i).name;
    
    fprintf('Loading ...[%d - %d] %s \n',i,numel(files),fileName);
    load(fileName);
  
subplot(121);
hist([Tracks.NumFrames],histogramBinning);

subplot(122);
Tracks = Tracks([Tracks.NumFrames] > TrackLengthThreshold);
hist([Tracks.NumFrames],histogramBinning);
size(Tracks);

title(sprintf('%s',fileName));

% saveas(gcf,  strcat(fileName(1:end-4),'_R_als.fig'), 'fig')
% % saveas(gcf,  strcat(fileName(1:end-4),'_reduced_als.ai'), 'ai')
% print (gcf, '-dpdf', '-r300',  strcat(fileName(1:end-4),'_R_als.pdf'));
% print (gcf, '-depsc', '-r300',  strcat(fileName(1:end-4),'_R_als.ai'));


save( strcat(fileName(1:end-4),'_R_als.mat'));

end

