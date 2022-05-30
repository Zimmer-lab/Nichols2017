clear all

MainDir = pwd;
 
FolderList = mywbGetDataFolders; %to exclude a dataset put & symbol in front of foldername
 
NumDataSets = length(FolderList);
 
 
for i = 1:NumDataSets;
    
    cd(FolderList{i});
    
    TotalPharynxTracks;
    
    cd(MainDir);
    
end