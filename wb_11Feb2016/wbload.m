function [wbstruct,wbstructfilename]=wbload(folderOrFile,addToBaseFlag,forceCellWrapper)
%[wbstruct,wbstructfilename]=wbload(folderOrFile,addToBaseFlag)

if nargin<3
    forceCellWrapper=false;
end

if nargin<2
    addToBaseFlag=true;
end

if nargin<1 || isempty(folderOrFile)
    folderOrFile=pwd;
end


    
if exist([folderOrFile filesep 'Quant' filesep 'wbstruct.mat'],'file')==2

    wbstructfilename=[folderOrFile filesep 'Quant' filesep 'wbstruct.mat'];
    wbstruct=load(wbstructfilename);

elseif exist(folderOrFile,'file')==2

    wbstructfilename=folderOrFile;
    wbstruct=load(folderOrFile); 

else

    foldersFullPath=listfolders(folderOrFile,true);
    folders=listfolders(folderOrFile,false);
    
    if ~isempty(folders)  && isempty(find(strcmpi(folders,'Quant'),1))  %is this a root folder

        disp('wbload> running in a root folder.  trying to load multiple wbstructs.');

        for i=1:length(folders)

            [wbstruct{i},wbstructfilename{i}]=wbload(foldersFullPath{i},false);
            
        end

    else

        disp('wbload> no wbstruct found.');
        wbstructfilename=[];
        wbstruct=[];
        return;

    end

end


%handle legacy wbstruct.mat file that has parent wbstruct
if isfield(wbstruct,'wbstruct')
    wbstruct=wbstruct.wbstruct;
end


%add cell wrapper if needed
if forceCellWrapper && isstruct(wbstruct)
    wbstruct={wbstruct};
end


if addToBaseFlag
    assignin('base','wbstruct',wbstruct);
end

end