close all;

HeatMapScale = [-0.2 1.8];%

DiffTag = false; SmoothWin = 5;

Method = 'cov'; %'corr' or 'cov'

MatScaleFac = 0.5;

AllDeltaF = wbstruct.deltaFOverF_bc;

AllDeltaF(:,wbstruct.exclusionList) = [];

AllDeltaF=AllDeltaF';

NanList = sum(isnan(AllDeltaF),2);

AllDeltaF=AllDeltaF(NanList==0,:);



TimeVec = wbstruct.tv';

if DiffTag
    
    Dt = diff(TimeVec);
    
    AllDeltaF = moving_average(AllDeltaF,SmoothWin,2);
    
    AllDeltaF = diff(AllDeltaF,1,2)./(Dt*Dt');
    
    TimeVec = TimeVec(2:end);
    
end

[NumTracks, NumFrames] = size(AllDeltaF);


if strcmp(Method,'corr')
    
    SortMatrix = corrcoef(AllDeltaF');
    
elseif strcmp(Method,'cov')
    
    SortMatrix = cov(AllDeltaF');
    
end


TreeFig = figure;

[H,T,outperm]=dendrogram(linkage(SortMatrix),NumTracks);

close;


AllDeltaFClustered = AllDeltaF(outperm,:);

NeuronIds = 1:NumTracks;

%%
%HeatMapScale = [min(AllDeltaF(:))*0.5, max(AllDeltaF(:))*0.5];

HeatMapFig2 = figure('Position', [50 0 1500 NumTracks * 15]);

imagesc(TimeVec, 1:NumTracks, AllDeltaFClustered, HeatMapScale)

set(gca,'yticklabel',NeuronIds(outperm),'YTick',1:NumTracks);

wbMpColorbarHandle = colorbar;

ylabel(wbMpColorbarHandle,'DF / F0');

xlabel('Time (s)');

title('neurons clustered according to R matrix');

line('XData', [360 360], 'YData', [0 (length(NeuronIds)+0.5)],'color','k','LineStyle', '-')
line('XData', [720 720], 'YData', [0 (length(NeuronIds)+0.5)],'color','k','LineStyle', '-')

x0=10;
y0=10;
width=550;
height=300;
set(gcf,'units','points','position',[x0,y0,width,height])

%% Annika manuscript figure


HeatMapFig2 = figure('Position', [50 0 1500 NumTracks * 15],'Color',[1 1 1]);

imagesc(TimeVec, 1:NumTracks, AllDeltaFClustered, HeatMapScale)
set(gca,'yticklabel',NeuronIds(outperm),'YTick',1:NumTracks);

wbMpColorbarHandle =colorbar;
ylabel(wbMpColorbarHandle,'DF / F0','Fontsize', 12);
wbMpColorbarHandle
ylabel('Neuron #','Fontsize', 12);
xlabel('Time (s)','Fontsize', 12);
set(gca,'Fontsize',12)
title('neurons clustered according to R matrix');

line('XData', [360 360], 'YData', [0 (length(NeuronIds)+0.5)],'color','k','LineStyle', '-')
line('XData', [720 720], 'YData', [0 (length(NeuronIds)+0.5)],'color','k','LineStyle', '-')

hold on;
x0=10;
y0=10;
width=600;
height=300;
set(gcf,'units','points','position',[x0,y0,width,height])

set(gcf,'PaperPositionMode','auto')
print (gcf,'-depsc', '-r300', sprintf('HeatmapCov.ai'));

%%
SortMatrixClustered = SortMatrix(outperm,outperm);

if strcmp(Method,'cov')

    CovarianceMatrixScale = [min(SortMatrixClustered(:))*MatScaleFac, max(SortMatrixClustered(:))*MatScaleFac];
    
elseif strcmp(Method,'corr')
    
    CovarianceMatrixScale = [-1 1];
    
end

%CovarianceMatrixScale = [-0.0001 0.0001]; %[-1000,1000];

CovFig = figure('Position', [50 0 1500 1500]);

imagesc(SortMatrixClustered, CovarianceMatrixScale);

axis image;

set(gca,'yticklabel',NeuronIds(outperm),'YTick',1:NumTracks);

set(gca,'xticklabel',NeuronIds(outperm),'XTick',1:NumTracks);

ylabel('neuron ID');

xlabel('neuron ID');

CorrMtrxpColorbarHandle = colorbar;

ylabel(CorrMtrxpColorbarHandle,'-');

title('--- matrix');



 %figure; plot(TimeVec,AllDeltaF(5,:),'b');hold on; plot(TimeVec,AllDeltaF(72,:),'r');plot(TimeVec,AllDeltaF(85,:),'g');