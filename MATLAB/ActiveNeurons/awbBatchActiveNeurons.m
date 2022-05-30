%Batch version of ActiveNeurons
% This is a script that calculates what neuron fraction is active based on
% two indicators of activity:
% 1. that the neuron has changes over a certain threshold (derivative)
% 2. that the neuron is above a baseline threshold

%use & in front of folder name to exclude that folder from analysis.
clear all;

ResultsStructFilename = 'ActiveNeurons_60sBins_0-007Deriv'; %This structure will be saved in the top folder.

%Bin size in seconds
options.BinSize = 60; %make 1080 evenly divisable by this value, i.e. 20, 30, 60

%Thresholds:
options.DerivThreshold = 0.007; %0.005

options.FThreshold = 0.5; %0.5

%%
options.version.awbBatchActiveNeurons = 'v1_20160323';
MainDir = pwd;
FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');
 
for ii = 1:NumDataSets %Folder loop
    
    load(ResultsStructFilename);

    cd(FolderList{ii})
    
    awbActiveNeurons; %runs for individual datasets.
    awbActiveNeuronsQA; 
    
    % IDs of neurons active during Q.
    [~, col] = find(~isnan(RecordingFractionActiveQuiBins));
    
    allIdNum = nan(length(col),100);
    for aaa = 1:length(col)
        [~,idNum] = find(SingleActiveNeurons(col(aaa),:));
        allIdNum(aaa,1:length(idNum))= idNum;
    end
    if ~isempty(allIdNum)
        uniqueNums(:,1) = unique(allIdNum);
        uniqueNums(isnan(uniqueNums(:,1)),:)=[];
        quiActiceIDs(ii, 1:length(uniqueNums)) = wbstruct.simple.ID(uniqueNums);
    end
    clearvars uniqueNums

    % saves name of dataset included
    ActiveNeurons.ExpID{ii}= wbstruct.trialname; 
    
    ActiveNeurons.Fraction(ii,:)= IndividualActiveNeurons;
    ActiveNeurons.QuiFraction(ii,1) = nanmean(RecordingFractionActiveQuiBins);
    ActiveNeurons.ActFraction(ii,1) = nanmean(RecordingFractionActiveActBins);
    
    cd(MainDir)
    dateRun = datestr(now);
    save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'ActiveNeurons','dateRun','options', 'quiActiceIDs'); 

    clearvars SingleActiveNeurons
end
clearvars FolderList IndividualActiveNeurons MainDir NumDataSets ResultsStructFilename dateRun ii wbstruct idx2 uniqueNums idNum allIdNum col ans aaa  


figure; bar(mean(ActiveNeurons.Fraction));
% mean(ActiveNeurons.QuiFraction)
% mean(ActiveNeurons.ActFraction)
% 
% nanmean(ActiveNeurons.QuiFraction)
% nanmean(ActiveNeurons.ActFraction)


