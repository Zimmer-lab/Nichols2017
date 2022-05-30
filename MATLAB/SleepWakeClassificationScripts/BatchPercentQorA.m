%% BatchPercentQorA
%use & in front of folder name to exclude that folder from analysis.

clear all;

ResultsStructFilename = 'FractionQorA_20161111_180sBins'; %This structure will be saved in the top folder.

BinSize = 180; %(in seconds)
FullRecordingLength = 1080; %(in seconds)

%%

MainDir = pwd;

FolderList = mywbGetDataFolders;
 
NumDataSets = length(FolderList);

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');
 
for ii = 1:NumDataSets %Folder loop
    
    load(ResultsStructFilename);

    cd(FolderList{ii})
    
    PercentQorA; %runs for individual datasets.
    
    % saves name of dataset included
    FractionQorA.ExpID{ii}= wbstruct.trialname; 
    
    %PercentQorA.PercentQ(ii,:)= IndividualPercentQ;
    FractionQorA.FractionA(ii,:)= IndividualFractionA;

    cd(MainDir)
    dateRun = datestr(now);
    save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'FractionQorA','dateRun'); 
    
end
clearvars FolderList FullRecordingLength IndividualFractionA IndividualPercentQ MainDir NumDataSets Qoptions QuiesceBout ResultsStructFilename dateRun ans ii wbstruct instQuiesce 

figure; bar(mean(FractionQorA.FractionA));
