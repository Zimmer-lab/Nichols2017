
% need to load QuiescenceSec.mat
[r,c] =size(AllMotionState);
TV = [20:5:1185];

QHeatMap = figure('Position',[20 300 600 150]);
%axes1 = axes('Parent',QHeatMap);
% axes1 = axes;
% hold(axes1,'on');

cm = [0.1289,0.3984,0.6719;1,1,1];
colormap(cm) %colorcube
yaxis = [0.5:(r+0.5)];
imagesc(TV,yaxis,AllMotionState(:,4:237));
%caxis([0 1]);

% vline(360, 'k', '-');
% vline(720, 'k', '-');

xlabel('Time (seconds)','FontSize',12);
ylabel('Worm #','FontSize',12);
title('WT starved noStim','FontSize',12);
set(gca,'Layer','top','XTick',[300 600 900],'XTickLabel',...
    {'300','600','900'});
set(gca,'Layer','top','YTick',[5 10 15 20 25],'YTickLabel',...
    {'5', '10', '15', '20', '25'});
xlim([20 1185]);
ylim([0, (r+1)]);
line('XData', [600 600], 'YData', [0.5, (r+0.5)],'color','k','LineStyle', '-')
box on

set(gcf,'PaperPositionMode','auto')
print (gcf,'-depsc', '-r300', sprintf('heatmap.ai'));


% invert matrix to get correct color scheme
% Quiescence(Quiescence == 0) = 2;
% Quiescence(Quiescence == 1) = 0;
% Quiescence(Quiescence == 2) = 1;
% 
% Quiescence(Quiescence == 0) = 0.7344;

% input color scale number
% WT fasted:0.3906
% WT starved: 0.7344
% WT starved noStim: 0.1094
% daf2 fasted: 0.25
