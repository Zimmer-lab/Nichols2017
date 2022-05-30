%% awbPhasePlot
clear all 

wbload;
load(strcat(pwd,'/Quant/QuiescentState.mat'));
load(strcat(pwd,'/Quant/wbPCAstruct.mat'));

%fwdrun=wbFourStateTraceAnalysis(wbstruct,'useSaved','VB02')==2;
ReversalRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
ReversalHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
ReversalFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;

Reversal = ReversalRISE | ReversalHIGH;

turnNeuron = {'SMDDL', 'SMDDR','SMDVL','SMDVR','RIVL','RIVR'}; %

turn = NaN(length(wbstruct.simple.tv),1,length(turnNeuron));
for ii = 1:length(turnNeuron)
    if sum(strcmp([wbstruct.simple.ID{:}], turnNeuron{ii})) == 1;
        turn(:,:,ii) = wbFourStateTraceAnalysis(wbstruct,'useSaved',turnNeuron{ii})==2;
    end
end
turnAll = nansumD(turn,3)';


paleblue = [0.8  0.93  1]; %255
blue = [0 0 204]/255; %255

forestgreen = [0 153 0]/255;
burntorange = [225 115 0]/255;
burntorange2 = [255 180 0]/255;
yellow = [255 240 102]/255;
purple = [76 0 103]/255;
red = [200 20 0]/255;
turquoise = [0 153 153]/255;

recessmap = [turquoise;blue;red;burntorange2;purple];
%recessmap = wbstruct.simple.tv;

tpc1 = cumsum(pcsFullRange(:,1));
tpc2 = cumsum(pcsFullRange(:,2));
tpc3 = cumsum(pcsFullRange(:,3));

% colorm = double(2*Reversal+QuiesceBout);
% colorm(find(turnAll),1)=3;

colorm = double(2*ReversalRISE+QuiesceBout);
colorm(find(ReversalHIGH),1)=3;
colorm(find(ReversalFALL)) = 4;

%%
PhasePlotFig = figure;

axes1 = axes('Parent',PhasePlotFig,'PlotBoxAspectRatio',[1 1 1],...
    'DataAspectRatio',[2 2 2],...
    'CameraViewAngle',20,...
    'CameraUpVector',[0.5 0.5 0.5],...
    'CameraTarget',[0 0 0],...
    'CameraPosition',[-10 -10 20]);

% axes1 = axes('Parent',PhasePlotFig,'PlotBoxAspectRatio',[1 1 1],...
%     'DataAspectRatio',[2 2 2],...
%     'CameraViewAngle',20,...
%     'CameraUpVector',[0.230986952119629 0.634631435137328 1.88252170491764],...
%     'CameraTarget',[0 0 0],...
%     'CameraPosition',[-7.88564653385373 -21.6656357895638 8.27144513232708]);


color_line3(tpc1,tpc2,tpc3,colorm,'LineWidth',1);
xlabel('cumsum(PC1)');ylabel('cumsum(PC2)');zlabel('cumsum(PC3)');
%colorm = wbstruct.simple.tv;
colormap(recessmap);
title(wbstruct.trialname)
xlabel('TPC1', 'FontSize',16);ylabel('TPC2', 'FontSize',16);zlabel('TPC3', 'FontSize',16);
%xlim([-1.5,3])
%ylim([-1.5,1.5]) %let 31a
ylim([-2,2]) %Pre 30a
%zlim([-1,2.5]) %Pre 30a

%xlim([floor(min(tpc1)),ceil(max(tpc1))])
%ylim([floor(min(tpc2)),ceil(max(tpc2))])
%zlim([floor(min(tpc3)),ceil(max(tpc3))])

%axis tight
set(gca, 'PlotBoxAspectRatio',[1 1 1])%, 'XTick',[-4,-3,-2,-1])
set(PhasePlotFig,'Position', [200 200 600 400]);

grid on;
cameratoolbar;

print(PhasePlotFig,'FQ3RColouredPhasePlotFigure.ai','-depsc')
