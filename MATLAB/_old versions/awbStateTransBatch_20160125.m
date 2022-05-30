% Batch_awbStateTrans (awbStateTransExtract and awbStateTransNeur).
% Script to find given neuron transitions (rise or fall), within a 
% given range and to compare state transitions to this point.

%use & in front of folder name to exclude that folder from analysis.
clear all

ResultsStructFilename = 'StateTrans_AVArisetriggered_360sTo370s_10sThres_noAN20140731b-j_noAN20151112a-b';

%Note!!! The first neuron will be what the script triggers of.
Neurons = {'AVAL','AQR','AUAL','AUAR','URXL','URXR','RMGL','RMGR','AVAR','RIML','RIMR','AVEL','AVER','AIBL','AIBR','RIS','URYDL','URYDR','URYVL','URYVR', 'VA01', 'AVBL', 'AVBR','RIBL', 'RIBR','SIBDL','SIBDR','SIBVL','SIBVR', 'RIVL','RIVR','SMDDL','SMDDR','SMDVL','SMDVR','RMED','RMEV','RMEL','RMER','VB02',}'; 

% 'AQR','AUAL','AUAR','URXL','URXR','RMGL','RMGR',
%NeuronsIncluded CHECK

%For the triggered neuron would you like to trigger off the rise or fall?:
options.TrigNeuronPolarity = 1; %1 = Rise, 0 = Fall.

options.LowTime = 360;     % (seconds) range in which to look for the state
options.HighTime = 370;    % transitions of the triggered neuron. Note that 
                            % 0 will be corrected to be the first time point.
                            
%Remove transitions that are more than X seconds away from the trigger neuron
options.ThresholdDistance = 10; %seconds. 10 is used in Kato et al.

%Determine negative polarity as in Kato et al. 2015 (based off PC1
%weights).
options.NegPolarity = {'RMED','RMEV','RMEL','RMER','RIS','VB02','SMDVL','SMDVR','SMDDL','SMDDR','RID','RIGL','RIGR','RIVL','RIVR','RIFL','RIFR','OLQDL','OLQDR','OLQVL','OLQVR','AVBL','AVBR','RIBL','RIBR','SIBVL','SIBVR','SIBDL','SIBDR'}';
                            
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
options.version.awbStateTransBatch = 'v2_20160125';

% to implement: not include a recording if there is no trigger neuron.
%disp(strcat( StateTrans.Neurons{ii},' is not in this dataset'))

%include number of trigger neuron events per recording.

%disclude if event of a neuron is too far? i.e. threshold?

MainDir = pwd;
 
FolderList = mywbGetDataFolders;
 
NumDataSets = length(FolderList);

StateTransTriggered = struct;

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');

NeuronsTMP = length(Neurons);
 
for iii = 1:NumDataSets %Number of Data Sets    
    load(ResultsStructFilename);

    cd(FolderList{iii})
    
    awbStateTransExtract;
    awbStateTransNeu;

    NameO1 = 'ExpID';              

    StateTransTriggered.(NameO1){iii}= wbstruct.trialname; %saves name of dataset included
    %Gets closestRise and ClosestFall of all neurons. Already converted to
    %seconds in awbStateTransNeu.
    if ~isfield(StateTransTriggered, 'ClosestRise');
        StateTransTriggered.ClosestRise = [];
    end
    if ~isfield(StateTransTriggered, 'ClosestFall');
        StateTransTriggered.ClosestFall = [];
    end
    if isfield(StateTrans,'ClosestRise');
       StateTransTriggered.ClosestRise= cat(2,StateTransTriggered.ClosestRise, StateTrans.ClosestRise);
       StateTransTriggered.ClosestFall= cat(2,StateTransTriggered.ClosestFall, StateTrans.ClosestFall);
    end    

    cd(MainDir)
    save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'StateTransTriggered'); 
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
