%% BatchawbReversals
% This script measures the number of reversals through the number of AVA
% rises
% use & in front of folder name to exclude that folder from analysis.
clear all

ResultsStructFilename = 'Reversals_3m_Bins';

BinSize = 180; %(in seconds)

FullRecordingLength = 1080; %(in seconds)

%%
MainDir = pwd;
 
FolderList = mywbGetDataFolders;
 
NumDataSets = length(FolderList);

BatchReversals = struct;

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');
 
for ii = 1:NumDataSets %Number of Data Sets
    
    load(ResultsStructFilename);

    cd(FolderList{ii})
    
    awbReversals;      
    
    % saves name of dataset included 
    BatchReversals.ExpID{ii}= wbstruct.trialname; 
    
    % Already converted to seconds in awbReversals.
    if ~isfield(BatchReversals, 'Reversals');
        BatchReversals.Reversals = [];
    end
    if isfield(BatchReversals, 'Reversals');
       BatchReversals.Reversals= cat(1,BatchReversals.Reversals, IndividualReversals);
    end    

    cd(MainDir)
    save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'BatchReversals'); 
    clearvars StateTrans wbstruct IndividualReversals
    
end

dateRun = datestr(now);
options.BinSize = BinSize;
options.FullRecordingLength = FullRecordingLength;

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'BatchReversals','dateRun', 'options');

figure; plot(BatchReversals.Reversals')
figure; plot(mean(BatchReversals.Reversals))