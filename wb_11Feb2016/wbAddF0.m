function wbAddF0(wbstruct)

    if nargin<1
        [wbstruct wbstructFileName] = wbload([],'false'); 
    end
    
    for i=1:wbstruct.nn
        wbstruct.f0(i)=nanmean(wbstruct.f_bonded(:,wbstruct.neuronlookup(i)));
    end

    if exist('wbstructFileName','var')
        disp('saving')
        wbSave(wbstruct,wbstructFileName);  
    end
    
end