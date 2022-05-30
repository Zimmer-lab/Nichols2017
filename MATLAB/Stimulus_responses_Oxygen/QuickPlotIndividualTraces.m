%% Plotting tools for oxygen repsonse neurons.
condition = 'N2Let';
PlotRange = (300:800);

saveFlag = 1;

SaveName = [condition,'_IL2_individual_thin.ai'];

%% Option 1:
[~,recNum] = size(NeuronResponse.(condition).rawF);

figure;
for ii = 1:recNum
    subplot(recNum/2,2,ii)
    plot(NeuronResponse.tv',NeuronResponse.(condition).rawF(:,ii));
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

%% Option 2: All on same plot

[~,foundNeu] = size(NeuronResponse.(condition).deltaFOverF_bc);
[recordingNum,~] = size(NeuronResponse.(condition).cumnNeuronsPerRecording);
paired = diff([0;NeuronResponse.(condition).cumnNeuronsPerRecording]);
y1=-0.399;
h1=foundNeu;
PlotRanget = PlotRange*5;
figure;

forestgreen = [0 153 0]/255;
burntorange = [225 115 0]/255;
nextPairedNeu = 0;
counterpaired = 1;
colorcount = 1;
colors = {'r','b',burntorange,forestgreen};

for jj = 1:foundNeu;
    if nextPairedNeu == 1;
        hold on;
        plot(NeuronResponse.tv(1,PlotRanget),(NeuronResponse.(condition).deltaFOverF_bc(PlotRanget,jj)+(h1 -jj)),'Color',colors{colorcount});
        nextPairedNeu = 0;
        counterpaired = counterpaired+1;
        colorcount = colorcount +1;
    elseif paired(counterpaired)>1
        hold on;
        plot(NeuronResponse.tv(1,PlotRanget),(NeuronResponse.(condition).deltaFOverF_bc(PlotRanget,jj)+(h1 -jj)),'Color',colors{colorcount});

        nextPairedNeu = 1;
    else
        hold on;
        plot(NeuronResponse.tv(1,PlotRanget),(NeuronResponse.(condition).deltaFOverF_bc(PlotRanget,jj)+(h1 -jj)),'k');
        counterpaired = counterpaired+1;
    end
end

set(gca,'FontSize',12)
xlabel('Time (s)', 'FontSize',12);
ylabel('DeltaF/F_0', 'FontSize',12);
box on;

hold on;
x0=10;
y0=10;
width=400; %600, legend 700; thin=
height=400;
set(gcf,'units','points','position',[x0,y0,width,height])

line('XData', [360 360], 'YData', [-1 h1+2], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)
line('XData', [720 720], 'YData', [-1 h1+2], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)
set(gca,'TickDir', 'out');
xlim([min(PlotRange),max(PlotRange)]);
%ylim([-0.4 h1]);
ylim([-0.4 16]);
ylim([-0.4 10]);
%ylim([0.6 11]);
ylim([-0.4 11]);


title(condition, 'FontSize',12)

if saveFlag == 1;
    set(gcf,'PaperPositionMode','auto')
    print (gcf,'-depsc', '-r300', sprintf(SaveName));
end
