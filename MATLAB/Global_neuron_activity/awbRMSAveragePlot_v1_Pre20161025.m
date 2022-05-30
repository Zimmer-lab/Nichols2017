%% awbAnalysisAverage
% works on loaded RMSaverage

%min-max

AnalysisAverage.Average


figure('Color',[1 1 1]);
imagesc(AnalysisAverage.Average')
wbMpColorbarHandle =colorbar;
ylabel(wbMpColorbarHandle,'Mean','Fontsize', 12);
wbMpColorbarHandle
ylabel('Recording #','Fontsize', 12);
xlabel('Time (min)','Fontsize', 12);
set(gca,'Fontsize',12)
colormap jet

hold on

line('XData', [6.5 6.5], 'YData', [0 (length(AnalysisAverage.Average)+0.5)],'color','k','LineStyle', '-')
line('XData', [12.5 12.5], 'YData', [0 (length(AnalysisAverage.Average)+0.5)],'color','k','LineStyle', '-')
%RMSaverage or AnalysisAverage
hold on;
x0=10;
y0=10;
width=600;
height=150;
set(gcf,'units','points','position',[x0,y0,width,height])

% set(gcf,'PaperPositionMode','auto')
% print (gcf,'-depsc', '-r300', sprintf('MeanAverages.ai'));

