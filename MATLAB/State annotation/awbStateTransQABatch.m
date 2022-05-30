% Batch_awbStateTransNeQA (awbStateTransExtract and awbStateTransNeuQA).
% Script to find state transitions (active to quiescent and
% compare state transitions to this point. Then run awbStateTransPlot

%use & in front of folder name to exclude that folder from analysis.
clear all

%noAN20140731b-j_noAN20151112a-b
ResultsStructFilename = 'TESTStateTrans_QAtriggered_0sTo3500s_15sThres_QFon_TEST';

Neurons = {'AVAL','AQR','AUAL','AUAR','URXL','URXR','IL2DL','IL2DR','RMGL','RMGR',...
    'AVAR','RIML','RIMR','AVEL','AVER','AIBL','AIBR','RIS','URYDL','URYDR','URYVL',...
    'URYVR','VA01','AVBL', 'AVBR','RIBL','RIBR','SIBDL','SIBDR','SIBVL','SIBVR',...
    'RIVL','RIVR','SMDDL','SMDDR','SMDVL','SMDVR','RMED','RMEV','RMEL','RMER','VB02'}';

%For the triggered neuron would you like to trigger off the rise or fall?:
options.TrigNeuronPolarity = 1; %1 = Rise, 0 = Fall.

options.LowTime = 0;     % (seconds) range in which to look for the state
options.HighTime = 1080;    % transitions of the triggered neuron. Note that 
                            % 0 will be corrected to be the first time point.
                            
%Remove transitions that are more than X seconds away from the trigger neuron
options.ThresholdDistance = 15; %seconds. 10 is used in Kato et al.

%Would you like to specify a requirement of quiescence range prior to trigger neuron event:
options.priorQuiesceFlag = 1; %1 = On, 0 = Off
options.priorQuiesceSec = 20; %in seconds
options.thresholdSeconds = 20; %in seconds min seconds of state on each side of a transition

%Determine negative polarity as in Kato et al. 2015 (based off PC1
%weights).
options.NegPolarity = {'RMED','RMEV','RMEL','RMER','RIS','VB02','SMDVL','SMDVR','SMDDL','SMDDR','RID','RIGL','RIGR','RIVL','RIVR','RIFL','RIFR','OLQDL','OLQDR','OLQVL','OLQVR','AVBL','AVBR','RIBL','RIBR','SIBVL','SIBVR','SIBDL','SIBDR'}';
                            
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
options.version.awbStateTransQABatch = 'v1_20160405'; 
%Based of awbStateTransBatch 'v3_20160323'

% to implement: not include a recording if there is no trigger neuron.
% disp(strcat( StateTrans.Neurons{ii},' is not in this dataset'))
% include number of trigger neuron events per recording.

MainDir = pwd;
 
FolderList = mywbGetDataFolders;
 
NumDataSets = length(FolderList);

StateTransQATriggered = struct;

NeuronsTMP = length(Neurons);

StateTransQATriggered.TrigNeuTransStartsSec_Qui2Act = NaN(NumDataSets,50);
StateTransQATriggered.TrigNeuTransStartsSec_Act2Qui = NaN(NumDataSets,50);

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');

for iii = 1:NumDataSets %Number of Data Sets    
    load(ResultsStructFilename);

    cd(FolderList{iii})
    
    awbStateTransNeuQA;

    StateTransQATriggered.ExpID{iii}= wbstruct.trialname; %saves name of datasets included
    %Gets closestRise and ClosestFall of all neurons. Already converted to
    %seconds in awbStateTransNeuQA.
    suffixes = {'ClosestRise_Act2Qui','ClosestFall_Act2Qui','ClosestFallEnd_Act2Qui','ClosestRise_Qui2Act','ClosestFall_Qui2Act', 'ClosestFallEnd_Qui2Act'};
    for bb = 1:6
        NameO4 = suffixes{bb};
        if ~isfield(StateTransQATriggered, NameO4);
            StateTransQATriggered.(NameO4) = [];
        end
    end
    
    if isfield(StateTrans,'ClosestRise_Act2Qui');
       StateTransQATriggered.ClosestRise_Act2Qui= cat(2,StateTransQATriggered.ClosestRise_Act2Qui, StateTrans.ClosestRise_Act2Qui);
       StateTransQATriggered.ClosestFall_Act2Qui= cat(2,StateTransQATriggered.ClosestFall_Act2Qui, StateTrans.ClosestFall_Act2Qui);
       StateTransQATriggered.ClosestFallEnd_Act2Qui= cat(2,StateTransQATriggered.ClosestFallEnd_Act2Qui, StateTrans.ClosestFallEnd_Act2Qui);
       StateTransQATriggered.TrigNeuTransStartsSec_Act2Qui(iii,1:length(StateTrans.AtoQtransition)) = StateTrans.AtoQtransition;
    end
    if isfield(StateTrans,'ClosestRise_Qui2Act');
       StateTransQATriggered.ClosestRise_Qui2Act= cat(2,StateTransQATriggered.ClosestRise_Qui2Act, StateTrans.ClosestRise_Qui2Act);
       StateTransQATriggered.ClosestFall_Qui2Act= cat(2,StateTransQATriggered.ClosestFall_Qui2Act, StateTrans.ClosestFall_Qui2Act);
       StateTransQATriggered.ClosestFallEnd_Qui2Act= cat(2,StateTransQATriggered.ClosestFallEnd_Qui2Act, StateTrans.ClosestFallEnd_Qui2Act);
       StateTransQATriggered.TrigNeuTransStartsSec_Qui2Act(iii,1:length(StateTrans.QtoAtransition)) = StateTrans.QtoAtransition;
    end    
    
%     TransIndicesAtoQ{iii,:} = AtoQtransition/wbstruct.fps; %in seconds
%     TransIndicesQtoA{iii,:} = QtoAtransition/wbstruct.fps;

    cd(MainDir)
    save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'StateTransQATriggered', 'options','Neurons'); 
    clearvars StateTrans wbstruct
    
end
clearvars bb bbb dataSet i idx3 idx4 iii iiii iiiii Qoptions QuiesceBout instQuiesce RiseStarts FallStarts NameO1 NameO2 NameO3 NameO4 NeuronsTMP

StateTransQATriggered.Neurons= Neurons(:,1);
suffixes = {'ClosestRise_Act2Qui','ClosestFall_Act2Qui','ClosestFallEnd_Act2Qui','ClosestRise_Qui2Act','ClosestFall_Qui2Act', 'ClosestFallEnd_Qui2Act'};
suffixes2 = {'ClosestTransArise_Act2Qui','ClosestTransAfall_Act2Qui','ClosestTransArise_Qui2Act','ClosestTransAfall_Qui2Act'};
suffixes3 = {'ClosestTransArise_Qui2Act_evoked','ClosestTransArise_Qui2Act_Astart', 'ClosestTransArise_Qui2Act_Bstart'};
 
% for aa = 1:4;
%     NameO3 = suffixes{aa};
%     figure; imagesc(StateTransQATriggered.(NameO3))
%     set(gca,'YTick',1:length(StateTransQATriggered.Neurons),'YTickLabel',StateTransQATriggered.Neurons)
%     %colormap(bluewhitered(256)), colorbar
% end

clearvars -except Neurons StateTransQATriggered options ResultsStructFilename
