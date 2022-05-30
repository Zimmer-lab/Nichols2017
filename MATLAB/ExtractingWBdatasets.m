%Saving datasubset
MainDir = pwd;

FolderList = mywbGetDataFolders; %to exclude a dataset put & symbol in front of foldername

NumDataSets = length(FolderList);

outputFolder = '/Users/nichols/Dropbox/Sharing_imaging_data/npr-1_2_Lethargus/';


for i = 1:NumDataSets
    clearvars -except i MainDir FolderList NumDataSets outputFolder
    cd(FolderList{i})
    
    wbload
    
    % version 1: traces, IDs, fps, timevector(seconds), state annotation (reverse, forward, quiescence, turn), stateID, trialname, stimulus
    wbdataset.traces = wbstruct.simple.deltaFOverF_bc;
    wbdataset.IDs = wbstruct.simple.ID;
    wbdataset.timeVectorSeconds = wbstruct.simple.tv;
    wbdataset.fps = wbstruct.fps;
    wbdataset.trialname = wbstruct.trialname;
    wbdataset.stimulus =wbstruct.stimulus;
    
    getFourStates
    wbdataset.FourStates = fourStates+1;
    wbdataset.FourStatesNames ={'Reversal', 'Forward', 'Quiescence', 'Turn'};
    
    mkdir(outputFolder, wbdataset.trialname);
    
    save([outputFolder, wbdataset.trialname '/wbdataset.mat'], 'wbdataset');
    
    
    cd(MainDir)
end


