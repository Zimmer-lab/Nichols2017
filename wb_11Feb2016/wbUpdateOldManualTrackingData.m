function wbUpdateOldManualTrackingData(wbstructOrDir)


    if nargin<1 || isempty(wbstructOrDir)
        wbstructOrDir=pwd;
    end

    wbUpdateOldStruct;
    
    [wbstruct,wbstructFileName]=wbload(wbstructOrDir,false);


    
    try 
        if ~isfield(wbstruct.added.neighbors,'deltaFOverFNoBackSub')
           for i=1:length(wbstruct.added.neighbors)
                wbstruct.added.neighbors(i).deltaFOverFNoBackSub=wbstruct.added.neighbors(i).deltaFOverF;
           end
        end
        if ~isfield(wbstruct.added.neighbors,'z')
           for i=1:length(wbstruct.added.neighbors)
                wbstruct.added.neighbors(i).z=-3:3;
           end
        end
        if ~isfield(wbstruct.added.neighbors,'picked')  
           for i=1:length(wbstruct.added.neighbors)
                wbstruct.added.neighbors(i).picked=[];
           end 
        end
        
    catch me
        disp('fail');
    end

    if isfield(wbstruct,'replacements')
        if ~isfield(wbstruct.replacements,'OLDdeltaFOverF')   
            wbstruct.replacements.OLDdeltaFOverF= wbstruct.replacements.deltaFOverF;    
        end

        if isfield(wbstruct.replacements,'deltaFOverF')  

            wbstruct.replacements=rmfield(wbstruct.replacements,'deltaFOverF');

            wbstruct.replacements.OLDf0=nan(size(wbstruct.replacements.neuron));

            wbstruct.replacements.OLDnx=nan(size(wbstruct.tblobs,2), length(wbstruct.replacements.neuron));
            wbstruct.replacements.OLDny=nan(size(wbstruct.tblobs,2), length(wbstruct.replacements.neuron));
            wbstruct.replacements.OLDnz=nan(1, length(wbstruct.replacements.neuron));        

        end
    end
    wbSave(wbstruct,wbstructFileName);
    
    
end