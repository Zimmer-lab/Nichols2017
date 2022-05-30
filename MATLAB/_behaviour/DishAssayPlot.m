%% DishAssay Plotting

[r, c] = size(AllSpeed);
tv = 1:5:1200;
Recordings = 1:1:r;

figure;imagesc(tv,Recordings,AllWakeState)
title('WakeState','Color','k')
xlabel('Time (s)');
line('XData', [600 600], 'YData', [0 r+0.5], 'color', 'k', 'LineStyle', '-')
ylabel('Worm','Color','k','FontSize',12);
set(gca, 'XColor', 'k');
set(gca, 'YColor', 'k');
set(gca,'Color',[1 1 1]);

figure;imagesc(tv,Recordings,AllMotionState)
title('MotionState','Color','k')
xlabel('Time (s)');
line('XData', [600 600], 'YData', [0 r+0.5], 'color', 'k', 'LineStyle', '-')
ylabel('Worm','Color','k','FontSize',12);
set(gca, 'XColor', 'k');
set(gca, 'YColor', 'k');
set(gca,'Color',[1 1 1]);


figure;imagesc(tv,Recordings,AllSpeed)
title('Speed','Color','k')
xlabel('Time (s)');
line('XData', [600 600], 'YData', [0 r+0.5], 'color', 'k', 'LineStyle', '-')
ylabel('Worm','Color','k','FontSize',12);
set(gca, 'XColor', 'k');
set(gca, 'YColor', 'k');
set(gca,'Color',[1 1 1]);
caxis([0 0.2])


%%

conditions = {AllWakeState, AllMotionState};
conditionsName = {'WakeState', 'MotionState'};
for i = 1:2;
    figure;
    hold on
    plot(tv,mean(conditions{i}),'r')
    title(['Fraction Awake ',conditionsName{i}],'Color','k')
    xlabel('Time (s)');
    line('XData', [600 600], 'YData', [0 1], 'color', 'k', 'LineStyle', '-')
    ylabel('Fraction Awake','Color','k','FontSize',12);
    set(gca, 'XColor', 'k');
    set(gca, 'YColor', 'k');
    set(gca,'Color',[1 1 1]);
end



figure;
hold on
plot(tv,mean(AllSpeed),'b')
title('Speed ','Color','k')
xlabel('Time (s)');
line('XData', [600 600], 'YData', [0 0.15], 'color', 'k', 'LineStyle', '-')
ylabel('Fraction Awake','Color','k','FontSize',12);
set(gca, 'XColor', 'k');
set(gca, 'YColor', 'k');
set(gca,'Color',[1 1 1]);


figure;
hold on
plot(tv,mean(AllEccen),'r')
title('Eccentricity ','Color','k')
xlabel('Time (s)');
line('XData', [600 600], 'YData', [0 0.002], 'color', 'k', 'LineStyle', '-')
ylabel('Fraction Awake','Color','k','FontSize',12);
set(gca, 'XColor', 'k');
set(gca, 'YColor', 'k');
set(gca,'Color',[1 1 1]);