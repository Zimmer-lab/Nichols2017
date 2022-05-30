function [wbPCAstruct,wbPCAstructfilename]=wbLoadPCA(folderOrFile,addToBaseFlag)

if nargin<2
    addToBaseFlag=true;
end

if nargin<1 || isempty(folderOrFile)
    
    if exist(['Quant' filesep 'wbPCAstruct.mat'],'file')==2
        
        wbPCAstructfilename=['Quant' filesep 'wbPCAstruct.mat'];
        wbPCAstruct=load(wbPCAstructfilename);
        
    elseif exist('wbPCAstruct.mat','file')==2
        
        wbPCAstructfilename='wbPCAstruct.mat';
        wbPCAstruct=load('wbPCAstruct.mat'); 
        
    else
        
        disp('wbLoadPCA> no wbPCAstruct found. Please run wbComputePCA.');
        beep;
        wbPCAstructfilename=[];
        wbPCAstruct=[];
        return;
        
    end
        
else 
    
    if exist(folderOrFile,'file')==2
        wbPCAstructfilename=folderOrFile;
        wbPCAstruct=load(wbPCAstructfilename);
    elseif exist([folderOrFile filesep 'Quant' filesep 'wbPCAstruct.mat'],'file')
        wbPCAstructfilename=[folderOrFile filesep 'Quant' filesep 'wbPCAstruct.mat'];
        wbPCAstruct=load(wbPCAstructfilename);
    else
        wbPCAstruct=[];
        wbPCAstructfilename=[];
        disp('wbLoadPCA> did not find wbPCAstruct.mat.');
        return;
    end
end

%handle legacy wbpcastruct.mat file that has parent wbstruct
if isfield(wbPCAstruct,'wPCAstruct')
    wbPCAstruct=wbPCAstruct.wbPCAstruct;
end

if addToBaseFlag
    assignin('base','wbPCAstruct',wbPCAstruct);
end

end