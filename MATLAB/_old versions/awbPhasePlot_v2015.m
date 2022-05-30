%% awbPhasePlot
wbload;
load([strcat(pwd,'/Quant/QuiescentState.mat')]);

fwdrun=wbFourStateTraceAnalysis(wbstruct,'useSaved','VB02')==2;
Reversal1=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
Reversal2=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;

Reversal = Reversal1 | Reversal2;

% figure;
% plot(vb02, 'b');
% hold on;
% plot(aval, 'r');
% hold on;
% plot(smddl, 'g');
% h2= plot((QuiesceBout), 'k');
% h3=plot((instQuiesce-0.1), 'r');
% set(h2, 'LineWidth', 3); 
% set(h3, 'LineWidth', 3); 

%%

tpc1 = cumsum(wbPCAstruct.pcsFullRange(:,1));
tpc2 = cumsum(wbPCAstruct.pcsFullRange(:,2));
tpc3 = cumsum(wbPCAstruct.pcsFullRange(:,3));

PhasePlotFig = figure;
subplot(1,2,1);
color_line3(cumsum(wbPCAstruct.pcsFullRange(:,1)),cumsum(wbPCAstruct.pcsFullRange(:,2)),cumsum(wbPCAstruct.pcsFullRange(:,3)),double(2*Reversal+QuiesceBout));
xlabel('cumsum(PC1)');ylabel('cumsum(PC2)');zlabel('cumsum(PC3)');

subplot(1,2,2);
color_line3((wbPCAstruct.pcsFullRange(:,1)),(wbPCAstruct.pcsFullRange(:,2)),(wbPCAstruct.pcsFullRange(:,3)),double(2*Reversal+QuiesceBout));
xlabel('PC1');ylabel('PC2');zlabel('PC3');
grid on;
cameratoolbar;