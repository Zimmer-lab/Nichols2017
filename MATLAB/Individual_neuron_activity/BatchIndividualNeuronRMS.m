%% Batch IndividualNeuronRMS (also other analysis)
%use & in front of folder name to exclude that folder from analysis.

ResultsStructFilename = 'IndividualRMS_20160919_NonMotor_mean';
%options.NeuronIDs ={'RIS', 'RMED', 'RMEV', 'RMEL', 'RMER'};
options.NeuronIDs = {'AVAL','AVAR','RIML','RIMR','VB02','VA01','RIS','RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','AVBL','AVBR','RIBL','RIBR','URYDL','URYDR','URYVL','URYVR','OLQDL','OLQDR','OLQVL','OLQVR','ALA','RIVL','RIVR','AFDL','AFDR','RID','SIBVL','SIBVR','SIBDL','SIBDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','SMDDL','SMDDR','SMDVL','SMDVR','ASKL','ASKR'};
options.NeuronIDs = {'ALA','AFDL','AFDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','ASKL','ASKR'};
options.NeuronIDs = {'ALA'};
options.Analysis =@mean; %rms or mean etc.

%%%%%%%%%%%%%%%%% DON'T NEED TO CHANGE BELOW HERE %%%%%%%%%%%%%%%%%
MainDir = pwd;

FolderList = mywbGetDataFolders;
 
NumDataSets = length(FolderList);

BatchIndividAnalysis = struct;

BatchIndividAnalysis.NeuronIDs = options.NeuronIDs;
BatchIndividAnalysis.Analysis = options.Analysis;

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');
 
for i = 1:NumDataSets 
    
    load(ResultsStructFilename);

    cd(FolderList{i})
    
    IndividualNeuronRMS;
    
    NameBO1 = 'ExpID';
    NameBO2 = 'QuiescentAnalysis';
    NameBO3 = 'ActiveAnalysis';
    NeuronNum=1:length(options.NeuronIDs);
    
    BatchIndividAnalysis.(NameBO1){i}= wbstruct.trialname;
    BatchIndividAnalysis.(NameBO2)(:,i)= IndividualAnalysis.Quiescent(NeuronNum,1);
    BatchIndividAnalysis.(NameBO3)(:,i)= IndividualAnalysis.Active(NeuronNum,1);
    
    cd(MainDir)
    save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'BatchIndividAnalysis','dateRun'); 
    clearvars -except MainDir ResultsStructFilename FolderList NumDataSets BatchIndividAnalysis options %condition
    
end

%sort by active value in descendning order, reorders data.
[vals idx] =sort(nanmean(BatchIndividAnalysis.ActiveAnalysis'),'descend');

AxisSwapQui = BatchIndividAnalysis.QuiescentAnalysis';
AxisSwapAct = BatchIndividAnalysis.ActiveAnalysis';

BatchIndividAnalysis.QuiAnalysisSorted = AxisSwapQui(:,idx);
BatchIndividAnalysis.ActAnalysisSorted = AxisSwapAct(:,idx)
BatchIndividAnalysis.IDsSorted = (BatchIndividAnalysis.NeuronIDs(:,idx))

meanBatchIndividSortQ = nanmean(BatchIndividAnalysis.QuiAnalysisSorted);
meanBatchIndividSortA = nanmean(BatchIndividAnalysis.ActAnalysisSorted);

figure;bar(meanBatchIndividSortQ,'b')
ylim([0 1]);
figure;bar(meanBatchIndividSortA,'r')
ylim([0 1]);

dateRun = datestr(now);
save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'BatchIndividAnalysis','dateRun'); 

    clearvars -except BatchIndividAnalysis
