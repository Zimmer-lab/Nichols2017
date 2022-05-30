%% 
% This script runs across all recordings in a folder/condition and extracts
% the Quiescent state (QuiesceBout). It then plots a heatmap for each
% recording.

clear all

MainDir = pwd;

FolderList = mywbGetDataFolders;
 
NumDataSets = length(FolderList);

AllFractionQ = [];
AlliFractionQ = [];

%save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');

iTV = 0:0.27:1079.73;

for ii = 1:NumDataSets %Folder loop
    
    cd(FolderList{ii})
    wbload
    cd('Quant')
    load('QuiescentState.mat');
    
    
    AllFractionQ{ii} = QuiesceBout(:,1);
    
    AlliFractionQ(ii,1:length(iTV)) = interp1(wbstruct.tv,double(QuiesceBout(:,1)),iTV,'nearest');
    
    cd(MainDir)
    clearvars QuiesceBout 
    
end

AlliFractionActive = abs(AlliFractionQ-1);

%%

miTV = iTV/60;

[r,c] =size(AlliFractionActive);

figure('Color',[1 1 1]);
cm = [0.1289,0.3984,0.6719;1,1,1];
colormap(cm) %colorcube
yaxis = [0:r];
imagesc(iTV,yaxis,AlliFractionActive);

xlabel('Time (seconds)','FontSize',12);
ylabel('Recording #','FontSize',12);

xlim([0 1080]);
ylim([0.5, (r+0.5)]);

hold on

line('XData', [360 360], 'YData', [0 (length(AlliFractionActive)+0.5)],'color','k','LineStyle', '-')
line('XData', [720 720], 'YData', [0 (length(AlliFractionActive)+0.5)],'color','k','LineStyle', '-')

hold on;
x0=10;
y0=10;
width=600;
height=150;
set(gcf,'units','points','position',[x0,y0,width,height])

set(gcf,'PaperPositionMode','auto')
print (gcf,'-depsc', '-r300', sprintf('FAheatmap.ai'));
