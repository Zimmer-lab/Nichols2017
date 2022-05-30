
condition = 'N2Let';

saveFlag = 0;

SaveName = [condition,'_URX_individual_.ai'];

%%

NameO3 = char(strcat('ExdeltaFOverF_',condition));
[~,recNum] = size(NeuronResponse.(NameO3));

figure;
for ii = 1:recNum
    subplot(recNum/2,2,ii)
    plot(NeuronResponse.tv',NeuronResponse.(NameO3)(:,ii));
    axis tight
    line('XData', [360 360], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
    line('XData', [720 720], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
end
hold on;
x0=10;
y0=10;
width=1400;
height=2000;
set(gcf,'units','points','position',[x0,y0,width,height])

ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');

text(0.5, 1,condition,'HorizontalAlignment','center','VerticalAlignment', 'top','FontSize',30)

if saveFlag == 1;
    set(gcf,'PaperPositionMode','auto')
    print (gcf,'-depsc', '-r300', sprintf(SaveName));
end