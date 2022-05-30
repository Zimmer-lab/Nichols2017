%% awbPhasePlot
wbload;
load(strcat(pwd,'/Quant/QuiescentState.mat'));
load(strcat(pwd,'/Quant/wbPCAstruct.mat'));

fwdrun=wbFourStateTraceAnalysis(wbstruct,'useSaved','VB02')==2;
Reversal1=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
Reversal2=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
Reversal = Reversal1 | Reversal2;

turnNeuron = {'SMDDL', 'SMDDR', 'SMDVL','SMDVR','RIVL','RIVR'};
turn = NaN(length(wbstruct.simple.tv),1,length(turnNeuron));
for ii = 1:length(turnNeuron)
    if sum(strcmp([wbstruct.simple.ID{:}], turnNeuron{ii})) == 1;
        turn(:,:,ii) = wbFourStateTraceAnalysis(wbstruct,'useSaved',turnNeuron{ii})==2;
    end
end
turnAll = nansumD(turn,3)';

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

tpc1 = cumsum(pcsFullRange(:,1));
tpc2 = cumsum(pcsFullRange(:,2));
tpc3 = cumsum(pcsFullRange(:,3));

PhasePlotFig = figure;
%subplot(1,2,1);
color_line3(cumsum(pcsFullRange(:,1)),cumsum(pcsFullRange(:,2)),cumsum(pcsFullRange(:,3)),double(2*Reversal+QuiesceBout));
xlabel('cumsum(PC1)');ylabel('cumsum(PC2)');zlabel('cumsum(PC3)');
grid on;
cameratoolbar;

% subplot(1,2,2);
% color_line3((pcsFullRange(:,1)),(pcsFullRange(:,2)),(pcsFullRange(:,3)),double(2*Reversal+QuiesceBout));
% xlabel('PC1');ylabel('PC2');zlabel('PC3');
% grid on;
% cameratoolbar;