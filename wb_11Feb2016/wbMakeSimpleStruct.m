function wbstruct=wbMakeSimpleStruct(wbstructOrFile,saveExtraCopyFlag,saveFlag)
% wbstruct=wbMakeSimpleStruct(wbstructOrFile,saveExtraCopyFlag,saveFlag)
%
%

    if nargin<2
        saveFlag=true;
    end

    if nargin<2
        saveExtraCopyFlag=true;
    end

    if nargin<1
        [wbstruct, wbstructFileName]=wbload([],false);
    elseif ischar(wbstructOrFile)
        [wbstruct wbstructFileName]=wbload(wbstructOrFile,false);
    else
        wbstruct=wbstructOrFile;
    end

    x=wbstruct.nx; x(:,wbstruct.exclusionList)=[];
    y=wbstruct.ny; y(:,wbstruct.exclusionList)=[];
    z=wbstruct.nz; z(wbstruct.exclusionList)=[];
    deltaFOverF=wbstruct.deltaFOverF;
    deltaFOverF(:,wbstruct.exclusionList)=[];
    
    wbstruct.simple.x=x;
    wbstruct.simple.y=y;
    wbstruct.simple.z=z;
    wbstruct.simple.deltaFOverF=deltaFOverF;
    
    if isfield(wbstruct,'deltaFOverF_bc');
       deltaFOverF_bc=wbstruct.deltaFOverF_bc;
       deltaFOverF_bc(:,wbstruct.exclusionList)=[];
       wbstruct.simple.deltaFOverF_bc=deltaFOverF_bc;
    end
    
    wbstruct.simple.nOrig=1:wbstruct.nn;
    wbstruct.simple.nOrig(wbstruct.exclusionList)=[];
    

    wbstruct.simple.stimulus=wbstruct.stimulus;
    wbstruct.simple.tv=wbstruct.tv;
    
    wbstruct.simple.dateSimpleRan=datestr(now);
    
    wbstruct.simple.nn=size(wbstruct.simple.deltaFOverF,2);
    

    wbUpdateOldIDs;
    
    if isfield(wbstruct,'f0')
        
        f0=wbstruct.f0; 
        f0(wbstruct.exclusionList)=[];
        wbstruct.simple.f0=f0;
        
    end
    
%     if exist('wbstructFileName','var')      
%         wbSave(wbstruct,wbstructFileName);
%     end
    
%     if ~isfield(wbstruct,'ID1')
%         wbstruct=wbUpdateOldStruct(wbstructFileName);
%     end
%     

    if isfield(wbstruct,'ID')
        
        ID=wbstruct.ID; 
        ID=[ID cell(1,wbstruct.nn-length(ID))];  %pad ID cell array to match number of traces
        ID(wbstruct.exclusionList(wbstruct.exclusionList<=length(ID)))=[];
        wbstruct.simple.ID=ID; 
        
    end

    if isfield(wbstruct,'ID1')
        
        ID1=wbstruct.ID1; 
        ID1(wbstruct.exclusionList(wbstruct.exclusionList<=length(ID1)))=[];
        wbstruct.simple.ID1=ID1;
        
    end
    
    if isfield(wbstruct,'ID2')
        
        ID2=wbstruct.ID2; 
        ID2(wbstruct.exclusionList(wbstruct.exclusionList<=length(ID2)))=[];
        wbstruct.simple.ID2=ID2;
        
    end
        if isfield(wbstruct,'ID3')
        
        ID3=wbstruct.ID1; 
        ID3(wbstruct.exclusionList(wbstruct.exclusionList<=length(ID3)))=[];
        wbstruct.simple.ID3=ID3;
        
        end
       
    
    if saveFlag
        if exist('wbstructFileName','var')      
            disp('wbMakeSimpleStruct> saving simple field to wbstruct.');
            wbSave(wbstruct,wbstructFileName);
        end
    end
    
    if saveExtraCopyFlag
        simpleStruct=wbstruct.simple;
        save(['Quant' filesep 'wbSimpleStruct-' wbMakeShortTrialname(wbstruct.trialname)],'-struct','simpleStruct');
    end
    
    if evalin('base','exist(''wbstruct'',''var'')')
         disp('wbMakeSimpleStruct> updating wbstruct in workspace.');
         assignin('base','wbstruct',wbstruct)
    end
    
    
    
    
    function wbUpdateOldIDs
    
        wbstruct.ID1=cell(1,wbstruct.nn);
        wbstruct.ID2=cell(1,wbstruct.nn);
        wbstruct.ID3=cell(1,wbstruct.nn);

        if isfield(wbstruct,'ID')
            
            for i=1:length(wbstruct.ID)
                try
                    if ~strcmp(wbstruct.ID{i}{1},'---')
                        wbstruct.ID1{i}=wbstruct.ID{i}{1};
                    end
                    if ~strcmp(wbstruct.ID{i}{2},'---')
                        wbstruct.ID2{i}=wbstruct.ID{i}{2};
                    end
                    if ~strcmp(wbstruct.ID{i}{3},'---')
                        wbstruct.ID3{i}=wbstruct.ID{i}{3};
                    end
                catch me
                end
            end
        
        end


    end
    
    
    
end