function wbstruct=wbUpdateOldStruct(wbDir)


    if nargin<1 || isempty(wbDir)
        wbDir=pwd;
    end
    
    [wbstruct,wbstructFileName]=wbload(wbDir,false);
    
    disp('wbUpdateOldStruct> updating old ID field to ID1,2,3 fields');
    wbUpdateOldIDs;
    
    disp('wbUpdateOldStruct> updating old XYs to time seres XYs.');
    wbUpdateXYtoTimeSeries;
    
    wbSave(wbstruct,wbstructFileName);
    
    wbMakeSimpleStruct(wbstructFileName);
    
    
    function wbUpdateOldIDs
    
            
        wbstruct.ID1=cell(1,wbstruct.nn);
        wbstruct.ID2=cell(1,wbstruct.nn);
        wbstruct.ID3=cell(1,wbstruct.nn);

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


    function wbUpdateXYtoTimeSeries


        if size(wbstruct.nx,1)==1

            wbstruct.nx=wbstruct.blobThreads_sorted.x(:,wbstruct.blobThreads.parentlist(wbstruct.neuronlookup));
            wbstruct.ny=wbstruct.blobThreads_sorted.y(:,wbstruct.blobThreads.parentlist(wbstruct.neuronlookup));

        end

        if isfield(wbstruct,'replacements') && isfield(wbstruct.replacements,'OLDnx') && size(wbstruct.replacements.OLDnx,1)==1
            
            wbstruct.replacements.OLDnx=repmat(wbstruct.replacements.OLDnx,size(wbstruct.nx,1),1);
            wbstruct.replacements.OLDny=repmat(wbstruct.replacements.OLDny,size(wbstruct.ny,1),1);
            
        end


    end

end