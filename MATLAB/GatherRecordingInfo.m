%% GatherRecordingInfo

MainDir = pwd;

FolderList = mywbGetDataFolders;

NumDataSets = length(FolderList);

if exist('nNeurons')
    count = length(nNeurons)+1;
else
    count =1;
end

for ii = 1:NumDataSets %Folder loop
    cd(FolderList{ii})
    
    wbload;
    
    [~,nNeurons(count,1)] = size(wbstruct.simple.deltaFOverF_bc);
    FPS(count,1) = wbstruct.fps;
    nNeuronsIDd(count,1) = (length(wbstruct.simple.ID) - sum(cellfun(@isempty,wbstruct.simple.ID)))/length(wbstruct.simple.ID);
    Znumbers(count,1) = wbstruct.numZ;
    
    count =count+1;
    cd(MainDir)
end