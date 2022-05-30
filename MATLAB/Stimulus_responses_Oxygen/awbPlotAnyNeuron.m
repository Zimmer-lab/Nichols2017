%% awbPlotAnyNeuron
%Script for finding and plotting individual neurons from wbstruct

y1 = 2.8; %Y limit for Mean

saveFlag = 1;

Neurons = {'AUAL','AUAR', 'RMGL', 'RMGR'};

TimePeriod = [0 1080]; %(in seconds)

%%
% FolderList = mywbGetDataFolders;
% NumDataSets = length(FolderList);
% Maindir = pwd;

% for recNum = 1:NumDataSets %Folder loop
%     cd(FolderList{recNum});
%     awbPlotAnyNeuron
%     cd(Maindir)
% end


for ii = 1:length(Neurons)
    % Neuron = 'AUAL';
    Neuron = Neurons{ii};
    
    %%%%%%%%%%%%%%%%% DON'T NEED TO CHANGE BELOW HERE %%%%%%%%%%%%%%%%%
    wbload;
    
    Trace = wbgettrace(Neuron);
    
    experimentName = wbstruct.trialname;
    
    SaveName = [Neuron,'_',experimentName,'_full_.ai'];
    
    if isnan(Trace)
        disp(['no: ',Neuron])
    else
        %%
        figure; set(gcf, 'Renderer', 'painters');
        grey = [0.4,0.4,0.4];
        hold on;
        plot(wbstruct.tv,Trace,'k');
        
        xlim(TimePeriod);%[350 420]
        ylim([-0.4 y1]);
        set(gca,'FontSize',18)
        xlabel('Time (s)', 'FontSize',18);
        ylabel('\DeltaF/F0', 'FontSize',18);
        
        line('XData', [360 360], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
        line('XData', [720 720], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
        set(gcf,'position',[1,2,700,300]);
        set(gca,'TickDir', 'out');
        box on;
        title([Neuron,experimentName],'FontSize',12)
        
        hold on;
        x0=10;
        y0=10;
        width=700; %700 %350
        height=250;
        set(gcf,'units','points','position',[x0,y0,width,height])
        %%
        if saveFlag == 1;
            set(gcf,'PaperPositionMode','auto')
            print (gcf,'-depsc', '-r300', sprintf(SaveName));
        end
    end
end