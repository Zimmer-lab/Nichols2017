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


PhasePlotFig = figure;
%subplot(1,2,1);
color_line3(tpc1,tpc2,tpc3,colorm,'LineWidth',2.5);
xlabel('cumsum(PC1)');ylabel('cumsum(PC2)');zlabel('cumsum(PC3)');
%colorm = wbstruct.simple.tv;
colormap(recessmap);
title(wbstruct.trialname)

grid on;
cameratoolbar;

saveas(PhasePlotFig,['FQ3RColouredPhasePlot',wbstruct.trialname])


% subplot(1,2,2);
% color_line3((pcsFullRange(:,1)),(pcsFullRange(:,2)),(pcsFullRange(:,3)),colorm,'LineWidth',2.5);
% xlabel('PC1');ylabel('PC2');zlabel('PC3');
% grid on;
% cameratoolbar;

%% Speed in colour
Variance = 60;

awbPCspeed

recessmap = allPCspeed;

PhasePlotFig2 = figure;
color_line3(tpc1,tpc2,tpc3,recessmap,'LineWidth',2.5);
xlabel('cumsum(PC1)');ylabel('cumsum(PC2)');zlabel('cumsum(PC3)');
%caxis([0,1])
colormap jet
grid on;
cameratoolbar;
title(wbstruct.trialname)

saveas(PhasePlotFig2,['SpeedColouredPhasePlot',wbstruct.trialname])

% figure
% color_line3((pcsFullRange(:,1)),(pcsFullRange(:,2)),(pcsFullRange(:,3)),recessmap,'LineWidth',2.5);
% xlabel('PC1');ylabel('PC2');zlabel('PC3');
% grid on;
% colormap(flipud(jet))

cameratoolbar;