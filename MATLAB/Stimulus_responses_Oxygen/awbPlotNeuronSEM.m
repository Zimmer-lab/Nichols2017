%% awbPlottingSEM
%Script for plotting the indivdual curves and mean with SE for subsets of a
%NeuronResponse struct. 

condition = 'npr1PreLet'; %i.e.npr1Post

%condition2 = 'N2Let'; %can plot against a second condition, otherwise
%comment out.

y1 = 2.8; %Y limit for Mean

saveFlag = 1;

SaveName = 'AQR_allMean20pc_';

dataToPlot ='deltaFOverF_mean20pc'; %'deltaFOverF_mean20pc';

%Moving the non responders from FullURXresponses20160421
%NeuronResponse.ExdeltaFOverF_N2LetSelect = NeuronResponse.ExdeltaFOverF_N2Let(:,[1,2,6:10,14:18]);

%%%%%%%%%%%%%%%%% DON'T NEED TO CHANGE BELOW HERE %%%%%%%%%%%%%%%%%
SaveName = [SaveName,'_',condition,'.ai'];

[~,n] = size(NeuronResponse.(condition).(dataToPlot));

mnRange1ALL = mean(NeuronResponse.(condition).(dataToPlot),2);

strRange1ALL = std(NeuronResponse.(condition).(dataToPlot),0,2)/sqrt(n);


if exist('condition2') <0.5;
    figure; plot(NeuronResponse.tv',NeuronResponse.(condition).(dataToPlot));
    title(condition)

    figure; set(gcf, 'Renderer', 'painters');
    grey = [0.4,0.4,0.4];
    jbfill(NeuronResponse.tv',mnRange1ALL+strRange1ALL,mnRange1ALL-strRange1ALL,grey,grey,0,0.3);
    %fill(mnRange1ALL+strRange1ALL,mnRange1ALL-strRange1ALL,'r');
    %fill(FullURXresponses20150624ZIM504Let.tv',mnRange1ALL+strRange1ALL,grey)
    hold on;
    %'Color',,'LineWidth',0.1
    %plot(FullURXresponses20150624ZIM504Let.tv,mnRange1ALL-strRange1ALL,'color',[0.4,0.4,0.4],'LineWidth',0.1);

    plot(NeuronResponse.tv',mnRange1ALL,'k');

    xlim([300 800]);
    ylim([-0.4 y1]);
    set(gca,'FontSize',18)
    xlabel('Time (s)', 'FontSize',18);
    ylabel('\DeltaF/F0', 'FontSize',18);

    line('XData', [360 360], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
    line('XData', [720 720], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
    set(gcf,'position',[1,2,700,300]);
    set(gca,'TickDir', 'out');
    box on;
    title(condition)
    
    hold on;
    x0=10;
    y0=10;
    width=700; 
    height=250;
    set(gcf,'units','points','position',[x0,y0,width,height])

    
else
    [~,n] = size(NeuronResponse.(condition2).(dataToPlot));

    mnRange1ALL2 = mean(NeuronResponse.(condition2).(dataToPlot),2);
    strRange1ALL2 = std(NeuronResponse.(condition2).(dataToPlot),0,2)/sqrt(n);
    
    figure; 
    grey = [0.4,0.4,0.4];
    hold on;
    plot(NeuronResponse.tv',mnRange1ALL,'k');
    hold on;
    plot(NeuronResponse.tv',mnRange1ALL2,'r');

    xlim([300 800]);
    ylim([-0.4 y1]);
    set(gca,'FontSize',12)
    xlabel('Time (s)', 'FontSize',12);
    ylabel('DeltaF/F0', 'FontSize',12);
    width=800;
    height=400;
    line('XData', [360 360], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
    line('XData', [720 720], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
    set(gcf,'position',[1,2,1500,400]);
    title(horzcat(condition,' vs ', condition2))
   
end

if saveFlag == 1;
    set(gcf,'PaperPositionMode','auto')
    print (gcf,'-depsc', '-r300', sprintf(SaveName));
end

clearvars -except NeuronResponse;

