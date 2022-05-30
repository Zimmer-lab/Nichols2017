%% MakePhasePlot
% ONLY PHASEPLOT image
clear all

cumsumOn = 0;

%If derivative, smoothing window size:
smoothingWin = 5;

% Do you want colours or only black?
onlyBlack = 0;

%%%%%%%
wbload;
load(strcat(pwd,'/Quant/QuiescentState.mat'));
load(strcat(pwd,'/Quant/wbPCAstruct.mat'));

ReversalRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
ReversalHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
ReversalFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;

Reversal = ReversalRISE | ReversalHIGH;

turnNeuron = {'SMDDL', 'SMDDR','SMDVL','SMDVR','RIVL','RIVR'}; %
stateName = {'Forward','Quiescence  ','Reversal','Turn'};

grey = [153 153 153]/255;

Cforward = [53 185 228]/255;
Creversal = [249 178 17]/255;
Cturn = [179 40 133]/255;
Cquiescence = [41 75 154]/255;

recessmap = [Cforward;Cquiescence;Creversal;Cturn;grey];

if cumsumOn
    % cumsum
    tpc1 = cumsum(pcsFullRange(:,1)); %pcsFullRange
    tpc2 = cumsum(pcsFullRange(:,2)); %pcsFullRange
    tpc3 = cumsum(pcsFullRange(:,3)); %pcsFullRange
    nameAdd = 'cumsum';
    
else
    % Derivative
    tpc1 = movingmean(pcsFullRange(:,1),smoothingWin); %pcsFullRange
    tpc2 = movingmean(pcsFullRange(:,2),smoothingWin); %pcsFullRange
    tpc3 = movingmean(pcsFullRange(:,3),smoothingWin); %pcsFullRange
    nameAdd = 'deriv';
end

colorm = double(2*ReversalRISE+QuiesceBout);
colorm(find(ReversalHIGH),1) = 2; %with red =3
colorm(find(ReversalFALL)) = 3; %with red =4
[NumFrames,~] = size(colorm);
grayColorm = (ones(NumFrames,1))+3; %with red =4

samplerate = wbstruct.fps;

%%
% Create figure
figure1 = figure;
hold on;
set(gcf, 'Position', get(0,'Screensize'));
set(gcf,'PaperPositionMode','auto');
set(0,'defaultAxesFontSize',16)

% Plot phase plot
subplot1 = subplot(1,1,1,'Parent',figure1,'PlotBoxAspectRatio',[1 1 1]);
set(gca, 'PlotBoxAspectRatio',[1 1 1])
set(0,'defaultAxesLineWidth',2)

%MAY NEED TO CHANGE!
%view(subplot1,[-17 24]);
view(subplot1,[-44 66]); %Let 31a

grid(subplot1,'on');
hold(subplot1,'all');

if onlyBlack
    %only black
    color_line3(tpc1,tpc2,tpc3,(ones(length(tpc1),1)),'LineWidth',2.5);
    colormap([0,0,0]);
    %ylim([-0.09,0.16])
    xlabel('PC1 ','FontSize',16);ylabel('PC2 ','FontSize',16);zlabel('PC3 ','FontSize',16);
    nameAdd2 ='_black';
else
    %colours
    color_line3(tpc1,tpc2,tpc3,colorm,'LineWidth',2.5);
    colormap(recessmap);
    caxis([0,5])
    nameAdd2 ='_colour';
end

if cumsumOn
    xlabel('cumsum(PC1) ');ylabel('cumsum(PC2) ');zlabel('cumsum(PC3) ');
else
    xlabel('PC1 ');ylabel('PC2 ');zlabel('PC3 ');
end

% ylim([-2,1]) %Pre 30a
% xlim([-0.7,3]) %Pre 30a
% zlim([-1,1]) %Pre 30a

%MAY NEED TO CHANGE!
%ylim([-1,1]) %Pre 30a
%xlim([-0.5,3.3]) %Let 31a
%ylim([min(tpc2),max(tpc2)]) %Let 31a deriv
ylim([-0.1,0.15]) %Let 31a deriv

grid on;

%State colour labeling %MAY NEED TO CHANGE!
%text(3.6, 0.9,stateName{(colorm(Frame)+1)},'Fontsize',16,'Color',recessmap((colorm(Frame)+1),:),'FontWeight','bold');
%31a 3.2, 1 %TS 4,3.5

filename = strcat(pwd,'/PhasPlotFig_',wbstruct.trialname,nameAdd,nameAdd2,'.tiff');
print('-dtiff','-r100', filename);
print (gcf,'-depsc', '-r200', sprintf(['PhasPlotFig_',wbstruct.trialname,nameAdd,nameAdd2,'.ai']));
close all
