function wbbatch(folder,options)
%
%run wb on a set of folders
%Saul Kato 20131117

if nargin<1
    folder=pwd;
end

if nargin<2
    options=[];
end

folderNames=ListSubfolders(folder);

for i=1:length(folderNames)
    clear global ZMovie;
    close all;
    f=[folder '/' folderNames{i}];
    wba(f,options);
    disp(['WBBATCH:' folderNames{i} ' analysis completed.']);
end

end

function folderNames=ListSubfolders(folder)
%make a cell array all of the subfolder names within a folder
    d = dir(folder);
    isub = [d(:).isdir];
    folderNames = {d(isub).name}';
    folderNames(ismember(folderNames,{'.','..'})) = [];

end