% Batch_awbStateTrans (awbStateTransExtract and awbStateTransNeur).
% Script to find given neuron transitions (rise or fall), within a
% given range and to compare state transitions to this point.

%use & in front of folder name to exclude that folder from analysis.
clear all

%noAN20140731b-j_noAN20151112a-b
ResultsStructFilename = 'StateTrans_AVALrisetriggered_0sTo1080s_15sThres_QFoff_';

%Note!!! The first neuron will be what the script triggers of.
Neurons = {'AVAL','AQR','AUAL','AUAR','URXL','URXR','IL2DL','IL2DR','RMGL','RMGR',...
    'AVAR','RIML','RIMR','AVEL','AVER','AIBL','AIBR','RIS','URYDL','URYDR','URYVL',...
    'URYVR','VA01','AVBL', 'AVBR','RIBL','RIBR','SIBDL','SIBDR','SIBVL','SIBVR',...
    'RIVL','RIVR','SMDDL','SMDDR','SMDVL','SMDVR','RMED','RMEV','RMEL','RMER','VB02'}';

%Neurons = {'URXL','URXR','AQR','AUAL','AUAR','AVAL','AVAR','RIML','RIMR','AVEL','AVER','AIBL','AIBR','VB02',}';
%Neurons = {'AVAL','AQR','AUAL','AUAR','URXL','URXR','RMGL','RMGR','AVAR','RIML','RIMR','AVEL','AVER','AIBL','AIBR','RIS','URYDL','URYDR','URYVL','URYVR', 'VA01', 'AVBL', 'AVBR','RIBL', 'RIBR','SIBDL','SIBDR','SIBVL','SIBVR', 'RIVL','RIVR','SMDDL','SMDDR','SMDVL','SMDVR','RMED','RMEV','RMEL','RMER','VB02',}';
%NeuronsIncluded CHECK

%For the triggered neuron would you like to trigger off the rise or fall?:
options.TrigNeuronPolarity = 1; %1 = Rise, 0 = Fall.

options.LowTime = 0;     % (seconds) range in which to look for the state
options.HighTime = 1080;    % transitions of the triggered neuron. Note that
% 0 will be corrected to be the first time point.

%Remove transitions that are more than X seconds away from the trigger neuron
options.ThresholdDistance = 15; %seconds. 10 is used in Kato et al.

%Would you like to specify a requirement of quiescence range prior to trigger neuron event:
options.priorQuiesceFlag = 0; %1 = On, 0 = Off
options.priorQuiesceSec = 20; %in seconds

%Determine negative polarity as in Kato et al. 2015 (based off PC1
%weights).
options.NegPolarity = {'RMED','RMEV','RMEL','RMER','RIS','VB02','SMDVL','SMDVR','SMDDL','SMDDR','RID','RIGL','RIGR','RIVL','RIVR','RIFL','RIFR','OLQDL','OLQDR','OLQVL','OLQVR','AVBL','AVBR','RIBL','RIBR','SIBVL','SIBVR','SIBDL','SIBDR'}';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
options.version.awbStateTransBatch = 'v4_20161019';
% added priorQuiesceFlag
% added RISE1 and RISE2 classification

% to implement: not include a recording if there is no trigger neuron.
% disp(strcat( StateTrans.Neurons{ii},' is not in this dataset'))
% include number of trigger neuron events per recording. OR TAKE other side
% neuron?

MainDir = pwd;
FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);
StateTransTriggered = struct;

NeuronsTMP = length(Neurons);
StateTransTriggered.TrigNeuRiseStartsSec = NaN(NumDataSets,50);
StateTransTriggered.priorTrigLow = NaN(NumDataSets,50);
StateTransTriggered.priorTrigQ = NaN(NumDataSets,50);

StateTransTriggered.ClosestRise = [];
StateTransTriggered.ClosestFall = [];


save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');


for iii = 1:NumDataSets %Number of Data Sets
    load(ResultsStructFilename);
    
    cd(FolderList{iii})
    
    awbStateTransExtract;
    awbStateTransNeu;
        
    StateTransTriggered.ExpID{iii}= wbstruct.trialname; %saves name of dataset included
    %Gets closestRise and ClosestFall of all neurons. Already converted to
    %seconds in awbStateTransNeu.
    
    if isfield(StateTrans,'ClosestRise');
        StateTransTriggered.ClosestRise= cat(2,StateTransTriggered.ClosestRise, StateTrans.ClosestRise);
        StateTransTriggered.ClosestFall= cat(2,StateTransTriggered.ClosestFall, StateTrans.ClosestFall);
        StateTransTriggered.TrigNeuRiseStartsSec(iii,:) = StateTrans.TrigNeuRiseStartsSec;
        StateTransTriggered.priorTrigLow(iii,1:length(StateTrans.priorTrigLow)) = StateTrans.priorTrigLow;
        StateTransTriggered.priorTrigQ(iii,1:length(StateTrans.priorTrigQ)) = StateTrans.priorTrigQ;
    end
    
    cd(MainDir)
    save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'StateTransTriggered','options');
    clearvars StateTrans wbstruct
    
end

StateTransTriggered.Neurons= Neurons(:,1);

%% DATA transformation
% Replace rises with falls for negative polarity neurons.

StateTransTriggered.ClosestTrans = StateTransTriggered.ClosestRise;
clearvars bbb
for bbb = 1:length(StateTransTriggered.Neurons);
    % if you can find StateTransTriggered.Neurons{bbb} in
    % options.NegPolarity replace the ClosestRise with the ClosestFall for
    % that neuron.
    matches =strfind(options.NegPolarity,StateTransTriggered.Neurons{bbb});
    Truematch = any(horzcat(matches{:}));
    if Truematch > 0;
        StateTransTriggered.ClosestTrans(bbb,:) = StateTransTriggered.ClosestFall(bbb,:);
    end
end

% Remove transitions that are more than X seconds away from the trigger neuron
% transition.
[idx3, idx4]= size(StateTransTriggered.ClosestTrans);
StateTransTriggered.ClosestTransThres= StateTransTriggered.ClosestTrans;
aaa=1;
for aaa= 1:idx3;
    indices = find((abs(StateTransTriggered.ClosestTrans))>options.ThresholdDistance);
    StateTransTriggered.ClosestTransThres(indices) = NaN;
end
clearvars indices aaa

% Remove neurons data when there is less than a N of 3
aaa=1;
for aaa= 1:idx3;
    if sum(~isnan(StateTransTriggered.ClosestTransThres(aaa,:)),2) < 3;
        StateTransTriggered.ClosestTransThres(aaa,1:idx4) =NaN;
    end
end
clearvars indices aaa bbb

StateTransTriggered.NeuronsNeg =StateTransTriggered.Neurons;
% Rename negative polarity neurons
for bbb = 1:length(StateTransTriggered.Neurons);
    % if you can find StateTransTriggered.Neurons{bbb} in
    % options.NegPolarity add a "-" to end of name
    matches =strfind(options.NegPolarity,StateTransTriggered.Neurons{bbb});
    Truematch = any(horzcat(matches{:}));
    if Truematch > 0;
        StateTransTriggered.NeuronsNeg(bbb,:) = strcat(StateTransTriggered.NeuronsNeg(bbb,:),'-');
    else
        StateTransTriggered.NeuronsNeg(bbb,:) = strcat(StateTransTriggered.NeuronsNeg(bbb,:),'+');
        
    end
end

%% Save
dateRun = datestr(now);
save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'StateTransTriggered','dateRun', 'options');

%% Plotting average with standard error
stdTrans = (nanstd(StateTransTriggered.ClosestTransThres'))'/sqrt(sum(not(isnan(StateTransTriggered.ClosestTransThres)),2)); %calculates standard error
averagedTrans = nanmean(StateTransTriggered.ClosestTransThres')'; %calculates average

%sort by active value in decendning order, reorders data.
[~, idx] =sort(averagedTrans,'descend');
AxisSwap = averagedTrans';

TransSorted = AxisSwap(:,idx);
TransSorted=TransSorted';

Neurons2 =StateTransTriggered.NeuronsNeg';
NeuronsSorted = Neurons2(:,idx);

steTrans2 =stdTrans';
FullSorted2 = steTrans2(:,idx);
FullSorted2 =FullSorted2';

%plots
figure;barh(TransSorted);
hold on
herrorbar(TransSorted,1:length(Neurons2),-FullSorted2(1:length(Neurons2),1), FullSorted2(1:length(Neurons2),1));
set(gca,'YTick',1:length(NeuronsSorted),'YTickLabel',NeuronsSorted)
%ylim([0 ]);
xlim([-20 20]);


% %% Plotting histograms
% % Xaxis = -50:0.5:50;
% % figure; hist(StateTransTriggered.ClosestTrans(4,:),Xaxis);
% % set(get(gca,'child'),'FaceColor','none','EdgeColor','r');
% % hold on;
% % hist(StateTransTriggered.ClosestTransThres(16,:),Xaxis);
%
% FullSorted1 =StateTransTriggered.ClosestTransThres';
% FullSorted2 = FullSorted1(:,idx);
% FullSorted2 =flipud(FullSorted2');
% FlippedNeuronsSorted = fliplr(NeuronsSorted);
%
% Xaxis = -20:0.3:20;
% [idx5, ~]=size(FullSorted2);
% fignum=1;
% %idx5 =14;
% figure;
% hold on;
% for fignum = 15:idx5;
%     histplot = hist(FullSorted2(fignum,:),Xaxis);
%     histplot = histplot/(sum(~isnan(FullSorted2(fignum,:)),2));
%     subplot(idx5-14,1,fignum-14); bar(histplot);
%     if fignum < idx5
%       set(gca,'XTick',[]);
%     else
%       set(gca,'XTick',1:6.7:length(histplot),'XTickLabel',-20:2:20)
%     end
%     xlim([0, length(histplot)]);
%     ylim([0, 0.5]);
%     ylabel(FlippedNeuronsSorted(1,fignum));
%     set(get(gca,'YLabel'),'Rotation',0)
% end
%
% %counts should be normalised to number of neuron events.

% %% Scatter plot
% averagedTrans = nanmean(StateTransTriggered.ClosestTransThres')'; %calculates average
%
% %sort by active value in decendning order, reorders data.
% [~, idx] =sort(averagedTrans,'descend');
% AxisSwap = averagedTrans';
%
% TransSorted = AxisSwap(:,idx);
% TransSorted=TransSorted';
%
% Neurons2 =StateTransTriggered.NeuronsNeg';
% NeuronsSorted = Neurons2(:,idx);
%
% IndivUnsorted = StateTransTriggered.ClosestTransThres'; %StateTransTriggered.ClosestTrans';
% IndivSorted = IndivUnsorted(:,idx);
% IndivSorted=IndivSorted';
%
% figure;
% hold on
% iiii =1;
% for iiii = 1:length(StateTransTriggered.ClosestTransThres);
%     %plot(IndivSorted(1:18,iiii),1:length(Neurons));
%     scatter(IndivSorted(1:length(StateTransTriggered.NeuronsNeg),iiii),1:length(StateTransTriggered.NeuronsNeg));
%     hold on
% end
% set(gca,'YTick',1:length(NeuronsSorted),'YTickLabel',NeuronsSorted)
% xlim([-20 20]);
% line([0 0],[0 27],'LineStyle','-')

%% Box plot
medianTrans = nanmedian(StateTransTriggered.ClosestTransThres')'; %calculates average

%sort by active value in decendning order, reorders data.
[~, idx] =sort(medianTrans,'descend');
AxisSwap = medianTrans';

TransMedSorted = AxisSwap(:,idx);
TransMedSorted=TransMedSorted';

Neurons2 =StateTransTriggered.NeuronsNeg';
NeuronsMedSorted = Neurons2(:,idx);

IndivUnsortedMed = StateTransTriggered.ClosestTransThres'; %StateTransTriggered.ClosestTrans';
IndivSortedMed = IndivUnsortedMed(:,idx);
IndivSortedMed=IndivSortedMed';
clearvars AxisSwap medianTrans Neurons2 IndivUnsortedMed

figure
boxplot(IndivSortedMed', NeuronsMedSorted, 'orientation', 'horizontal')

%% Heatplot
toPlot =StateTransTriggered.ClosestTransThres;
NeuronsPlot = Neurons;
NeuronNum = length(Neurons);

figure;
set(0,'DefaultFigureColormap',cbrewer('div','RdBu',64));
heatmap(toPlot, 1:length(toPlot), NeuronsPlot, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true, 'MinColorValue', -15, 'MaxColorValue', 15); %'TickAngle', 45,'TickFontSize', 6

% %%
%    X=StateTransTriggered.ClosestTransThres;
%    X(isnan(X)) = -20 ;
%
%    SortMatrix = corrcoef(X);
%    figure;imagesc(SortMatrix);
%
%    [NumTracks, ~] = size(StateTransTriggered.ClosestTransThres);
%
%    [H,T,outperm]=dendrogram(linkage(SortMatrix),NumTracks);
%   AllDeltaFClustered = StateTransTriggered.ClosestTransThres(outperm,:);
%    figure; imagesc(AllDeltaFClustered)
%rng(1); % For reproducibility
%[idx,C] = kmeans(StateTransTriggered.ClosestTransThres,3);

% clearvars i idx idx3 idx4 iii bbb stdTrans steTrans2 FallStarts NeuronsMedSorted...
%     NeuronsSprted QuiesceBout instQuiesce Qoptions HighFrame LowFrame Truematch
clearvars -except StateTransTriggered options Neurons ResultsStructFilename