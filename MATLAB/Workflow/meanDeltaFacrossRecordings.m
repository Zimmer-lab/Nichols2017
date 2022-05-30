
MainDir = pwd;
FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

tvi = ((0:5399)/5)'; %time vector extrapolated


for ii = 1:NumDataSets %Folder loop

    cd(FolderList{ii})
    
    wbload
    tvo =wbstruct.tv; %time vector original
    allDeltaFOverF(ii,:) = interp1(tvo,mean(wbstruct.simple.deltaFOverF_bc'),tvi);  %'extrap'
    cd(MainDir)

end

figure; plot(allDeltaFOverF','DisplayName','allDeltaFOverF')
figure; imagesc(allDeltaFOverF,'DisplayName','allDeltaFOverF')