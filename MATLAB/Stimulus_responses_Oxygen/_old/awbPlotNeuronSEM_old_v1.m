%% awbPlottingSEM
%Script for plotting the indivdual curves and mean with SE for subsets of a
%NeuronResponse struct. 

condition = 'N2PreLet'; %i.e.npr1Post

%condition2 = 'N2Let'; %can plot against a second condition, otherwise
%comment out.

y1 = 2.8; %Y limit for Mean

saveFlag = 0;

%%%%%%%%%%%%%%%%% DON'T NEED TO CHANGE BELOW HERE %%%%%%%%%%%%%%%%%

NameO3 = char(strcat('ExdeltaFOverF_',condition));

[~,n] = size(NeuronResponse.(NameO3));

mnRange1ALL = mean(NeuronResponse.(NameO3),2);

strRange1ALL = std(NeuronResponse.(NameO3),0,2)/sqrt(n);


if exist('condition2') <0.5;
    figure; plot(NeuronResponse.tv',NeuronResponse.(NameO3));
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

    xlim([0 1080]);
    ylim([-0.4 y1]);
    set(gca,'FontSize',16)
    xlabel('Time (s)', 'FontSize',16);
    ylabel('\DeltaF/F0', 'FontSize',16);
    width=400;
    height=200;
    line('XData', [360 360], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
    line('XData', [720 720], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
    set(gcf,'position',[1,2,700,300]);
    set(gca,'TickDir', 'out');
    box on;
    %line('XData', [0 3], 'YData', [-1 2.5], 'color', 'k', 'LineStyle', '-')
    %line('XData', [3 0], 'YData', [-1 2.5], 'color', 'k', 'LineStyle', '-')
    title(condition)

    
else
    NameO4 = char(strcat('ExdeltaFOverF_',condition2));

    %figure; plot(NeuronResponse.tv',NeuronResponse.(NameO4));

    [~,n] = size(NeuronResponse.(NameO4));

    mnRange1ALL2 = mean(NeuronResponse.(NameO4),2);

    strRange1ALL2 = std(NeuronResponse.(NameO4),0,2)/sqrt(n);
    
    figure; 
    grey = [0.4,0.4,0.4];
    %jbfill(NeuronResponse.tv',mnRange1ALL2+strRange1ALL2,mnRange1ALL2-strRange1ALL2,grey,grey,0,0.3);
    hold on;
    plot(NeuronResponse.tv',mnRange1ALL,'k');
    hold on;
    plot(NeuronResponse.tv',mnRange1ALL2,'r');

    xlim([0 1080]);
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
    
    hold on;
    x0=10;
    y0=10;
    width=700; %600, legend 700
    height=150;
    set(gcf,'units','points','position',[x0,y0,width,height])

end

clearvars -except NeuronResponse;

if saveFlag == 1;
    set(gcf,'PaperPositionMode','auto')
    print (gcf,'-depsc', '-r300', sprintf('QuiesceNeurons2.ai'));
end