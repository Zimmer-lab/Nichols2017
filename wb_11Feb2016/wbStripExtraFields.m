function wbStripExtraFields(wbstruct)

if nargin<1
    [wbstruct,wbstructfilename]=wbload([],false); 
end


if isfield(wbstruct.blobThreads_sorted,'instdistance')
    wbstruct.blobThreads_sorted=rmfield(wbstruct.blobThreads_sorted,'instdistance');
end

save(wbstructfilename,'-struct','wbstruct');

    
    