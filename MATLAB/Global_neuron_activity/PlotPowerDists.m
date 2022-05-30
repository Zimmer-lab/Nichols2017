%% This script will plot the RMS distributions of all neurons from many datasets. First BatchawbPowerDist must be run.

%xcentres = (0:0.03:1.4); %For binning and x axis of histograms.
xcentres = PowerDistributions.bins; %(0:0.06:1.4);

cumsum1= cumsum(mean(PowerDistributions.BinnedQuiesceAnalysed));
cumsum2= cumsum(mean(PowerDistributions.BinnedActiveAnalysed));
% 
figure;plot(xcentres,cumsum1,'b',xcentres,cumsum2,'r')
% 
% figure;plot(xcentres,mean(PowerDistributions.BinnedQuiesceAnalysed_npr1Let),'b',xcentres,mean(PowerDistributions.BinnedActiveAnalysed_npr1Let),'r')
% figure;plot(xcentres,mnRange1ALL+strRange1ALL,xcentres,mnRange1ALL-strRange1ALL);
% hold on;
%mnRange1ALL2 = mean(NeuronResponse.(NameO4),2);

grey = [0.4,0.4,0.4];
lightblue = [0.5  0.5  1];
peach = [1 0.5 0.5];

mnRange1Quiesce = mean(PowerDistributions.BinnedQuiesceAnalysed);
strRange1Quiesce = std((PowerDistributions.BinnedQuiesceAnalysed'),0,2)/sqrt(9);
strRange1Quiesce = strRange1Quiesce';

mnRange1Active = mean(PowerDistributions.BinnedActiveAnalysed);
strRange1Active = std((PowerDistributions.BinnedActiveAnalysed'),0,2)/sqrt(9);
strRange1Active = strRange1Active';

figure; set(gcf, 'Renderer', 'painters');

jbfill(xcentres,mnRange1Quiesce+strRange1Quiesce,mnRange1Quiesce-strRange1Quiesce,lightblue,lightblue,0,0.3);
hold on;
jbfill(xcentres,mnRange1Active+strRange1Active,mnRange1Active-strRange1Active,peach,peach,0,0.3);
hold on;
h1=plot(xcentres,mnRange1Quiesce,'b');
hold on;
h2=plot(xcentres,mnRange1Active,'r');
hold on;


set(h1, 'LineWidth', 2); 
set(h2, 'LineWidth', 2); 
set(gca,'TickDir', 'out');
ylim([0 0.5]);
xlim([0 1.4]);


%%%
figure; set(gcf, 'Renderer', 'painters');

jbfill(xcentres,mnRange1Quiesce+strRange1Quiesce,mnRange1Quiesce-strRange1Quiesce,lightblue,lightblue,0,0.3);
hold on;
jbfill(xcentres,mnRange1Active+strRange1Active,mnRange1Active-strRange1Active,peach,peach,0,0.3);
[ax1,h3,h4]=plotyy(xcentres,mnRange1Quiesce,xcentres,cumsum1);
hold on;
[ax2,h5,h6]=plotyy(xcentres,mnRange1Active,xcentres,cumsum2);
%set(h1,'LineWidth', 2); 
set(h3,'Color','b'); 
set(h4,'Color','b'); 
set(h3, 'LineWidth', 2); 
set(h4, 'LineWidth', 1); 

set(gca,'TickDir', 'out');
% ylim([0 0.5]);
% xlim([0 1.4]);
YColor= [1 1 1];
%xlabel('Time (s)', 'FontSize',16);
%ylabel('DeltaF/F0', 'FontSize',16);
%set(h2,'LineWidth', 2); 
set(ax2,'YColor','k'); 
set(h5,'Color','r'); 
set(h6,'Color','r'); 
set(h5, 'LineWidth', 2); 
set(h6, 'LineWidth', 1); 
line('XData', [0.21 0.21], 'YData', [-1 8], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)
line('XData', [0 1.5], 'YData', [0.315 0.315], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)
line('XData', [0 1.5], 'YData', [0.448 0.448], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)

