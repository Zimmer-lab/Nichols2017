%% awbActivityDistFQR
% similar to awbActivityDist but seperates between forward and quiescent
% rather than active and quiescent.

% script to bin data into 1 second bins and then run a histogram on this.
clear all

%xcentres = (0:0.06:3.5);

% xcentres = (-0.5:0.05:3.5);
% logon = 0;

%LOG!
xcentres = logspace(-4,0.7); %logspace(-3,0.7)
logon = 1;
saveflag = 0;
SubplotSaveflag =1;

%Neurons = {'AVAL','AVAR','RIML','RIMR','VB02','VA01','RIS','RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','AVBL','AVBR','RIBL','RIBR','URYDL','URYDR','URYVL','URYVR','OLQDL','OLQDR','OLQVL','OLQVR','ALA','RIVL','RIVR','AFDL','AFDR','RID','SIBVL','SIBVR','SIBDL','SIBDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','SMDDL','SMDDR','SMDVL','SMDVR','ASKL','ASKR'};
%Neurons ={'URXL','URXR','IL2DL','IL2DR', 'AUAL','AUAR','RMGL','RMGR'};
%Neurons ={'RIS','RMED','RMEV','RIML','AVBL'};
Neurons ={'SMDVL','SMDVR'};

ResultsStructFilename = 'ActivityDistFQR_FFL_RRH';

FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

%Make dynamic names for datasets
inputData ={};
for nn = 1:length(Neurons)
    inputData{nn} = strcat(Neurons{nn});
end

%preallocate matrices
for neuNum = 1:length(Neurons);
    BinnedQuiesce.(inputData{neuNum}) = nan(length(xcentres),NumDataSets);
    BinnedForward.(inputData{neuNum}) = nan(length(xcentres),NumDataSets);
    BinnedReverse.(inputData{neuNum}) = nan(length(xcentres),NumDataSets);
end

MainDir = pwd;

for recNum = 1:NumDataSets %Folder loop
    
    cd(FolderList{recNum});
    wbload;
    
    % load QuiesceState
    awbQuiLoad
    
    % calculates quiescent and active range
    calculateQuiescentRange
    
    for neuNum = 1:length(Neurons)
        %get neuron trace
        Trace = wbgettrace(Neurons{neuNum});
        if ~isnan(Trace)
            % Get quiescent or active trace
            QuTrace = Trace(rangeQ);
            ForTrace = Trace(RangeForwardFL);
            RevTrace = Trace(RangeReversalRH);
            
            %get histogram for neuron in Quiescent states and normalise by the number
            %of timepoints
            if ~isempty(QuTrace)
            BinnedQuiesce.(inputData{neuNum})(:,recNum) = (histc(QuTrace,xcentres))/(length(rangeQ));
            else
                BinnedQuiesce.(inputData{neuNum})(:,recNum) = nan(length(xcentres),1);
            end
            %get for Active states
            BinnedForward.(inputData{neuNum})(:,recNum) = (histc(ForTrace,xcentres))/(length(ForTrace));
            BinnedReverse.(inputData{neuNum})(:,recNum) = (histc(RevTrace,xcentres))/(length(RevTrace));
            
        end
    end
    cd(MainDir)
end
%% Plotting
grey = [0.4,0.4,0.4];
set(0,'DefaultAxesFontSize',10)

if SubplotSaveflag
    fig = figure;
    spf =1;
else
    spf =0;
end


for neuNum = 1:length(Neurons)
    if spf %Subplot:
        subplot(6,9,neuNum)
%         if neuNum >= 24
%             neuNum =neuNum+1;
%         end
    else %Single:
        fig = figure;
    end
    
    if logon
        inputD = {BinnedQuiesce,BinnedForward,BinnedReverse};
        colorsT= {'b','k','r'};
        for stateT = 1:length(colorsT)
            %gets n
            n = min(sum(~isnan(inputD{1, stateT}.(inputData{2}))'));
            
            strRange1ALL = (nanstd(inputD{stateT}.(inputData{neuNum})')/sqrt(n))';
            mnRange1ALL = nanmean(inputD{stateT}.(inputData{neuNum})');
            hold on
            
            pl = errorbar(xcentres,nanmean(inputD{stateT}.(inputData{neuNum})'),strRange1ALL);
            set(pl,'Color',colorsT{stateT})
            ax = get(fig,'CurrentAxes');
            set(ax,'XScale','log')
            set(gca,'Layer','top','XTick',[10^-2,10^-1,10^0,10^1]);%,'XTickLabel', {'300','600','900'});
            title(inputData{neuNum})
        end
    else
        figure; plot(xcentres,nanmean(BinnedQuiesce.(inputData{neuNum})'),'b')
        hold on
        plot(xcentres,nanmean(BinnedForward.(inputData{neuNum})'),'k')
        hold on
        plot(xcentres,nanmean(BinnedReverse.(inputData{neuNum})'),'r')
        title(inputData{neuNum})
    end
    
    %set(gca,'FontSize',12)
    %xlabel('DeltaF/F_0', 'FontSize',12);
    %ylabel('Fraction', 'FontSize',12);
    box on;
    set(gca,'TickDir', 'out');
    xlim([0.01 10]);
    ylim([0 0.35]);
    
    if saveflag == 1;
        hold on;
        x0=100; y0=100; width=250; height=200;
        set(gcf,'units','points','position',[x0,y0,width,height])
        set(gcf,'PaperPositionMode','auto')
        print (gcf,'-depsc', '-r300', sprintf([inputData{neuNum},'_ActDistFQR_FFL_RRH.ai']));
    end
end

if SubplotSaveflag == 1;
    hold on;
    set(gcf, 'Position', get(0,'Screensize'));
    set(gcf,'PaperPositionMode','auto')
    print (gcf,'-depsc', '-r300', sprintf('npr1PreLet_ActDistFQR_FFL_RRH.ai'));
end
%% find distances
distances = nan(NumDataSets,length(Neurons));

for neuNum = 1:length(Neurons)
    for recNum = 1:NumDataSets
        distancesFQ(recNum,neuNum) = sum(cumsum(BinnedForward.(inputData{neuNum})(:,recNum)) - cumsum(BinnedQuiesce.(inputData{neuNum})(:,recNum)));
        distancesFR(recNum,neuNum) = sum(cumsum(BinnedForward.(inputData{neuNum})(:,recNum)) - cumsum(BinnedReverse.(inputData{neuNum})(:,recNum)));
        distancesRQ(recNum,neuNum) = sum(cumsum(BinnedReverse.(inputData{neuNum})(:,recNum)) - cumsum(BinnedQuiesce.(inputData{neuNum})(:,recNum)));
    end
    %     yaxe = ones(NumDataSets,1);
    %     figure; scatter(yaxe,(distances(:,neuNum)));
    %     title(inputData{neuNum})
    
end

clearvars -except distancesRQ distancesFQ distancesFR distances BinnedReverse BinnedForward BinnedQuiesce...
    NumDataSets Neurons xcentres inputData ResultsStructFilename

dateRun = datestr(now);
save(([strcat(pwd,'/',ResultsStructFilename) '.mat']), 'BinnedReverse','BinnedForward','BinnedQuiesce',...
    'Neurons','distancesRQ', 'distancesFQ', 'distancesFR', 'distances','dateRun','xcentres');
