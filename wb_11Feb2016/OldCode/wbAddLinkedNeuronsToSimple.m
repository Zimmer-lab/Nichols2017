function wbstruct=wbAddLinkedNeuronsToSimple(wbstruct)

if strcmp(wbstruct.metadata.noseDirection,'North') || strcmp(wbstruct.metadata.noseDirection,'South')
    width=wbstruct.metadata.fileInfo.width;
    height=wbstruct.metadata.fileInfo.height;
else
    height=wbstruct.metadata.fileInfo.width;
    width=wbstruct.metadata.fileInfo.height;
end


for nn=1:wbstruct.added.n
    
    thisDeltaFOverF=wbstruct.added.neighbors(nn).deltaFOverF(:,wbstruct.added.neighbors(nn).picked);
    thisF0=wbstruct.added.neighbors(nn).f0(wbstruct.added.neighbors(nn).picked);
    thisZ=wbstruct.added.neighbors(nn).z(wbstruct.added.neighbors(nn).picked);
    
    thisX=wbstruct.added.x(nn);
    thisY=wbstruct.added.y(nn);
    
    %find insertion index
    bt_spatialindex=zeros(size(wbstruct.blobThreads.parentlist));
    for i=1:length(wbstruct.blobThreads.parentlist)
        %compute spatial index %head to tail
        bt_spatialindex(i)=wbstruct.blobThreads_sorted.x0(wbstruct.blobThreads.parentlist(i))+width*wbstruct.numZ*(wbstruct.blobThreads_sorted.y0(wbstruct.blobThreads.parentlist(i))-1)+width*(wbstruct.blobThreads_sorted.z(wbstruct.blobThreads.parentlist(i))-1); 
    end
    
    [sortvals, neuronlookup]=sort(bt_spatialindex,'ascend');
    
    this_spatialindex=thisX+width*wbstruct.numZ*(thisY-1)+width*(thisZ-1);
    
    index=find(this_spatialindex<sortvals,1,'first');
    %
    
    
    wbstruct.simple.x=insertVal(wbstruct.simple.x, thisX ,index);
    wbstruct.simple.y=insertVal(wbstruct.simple.y, thisY ,index);
    wbstruct.simple.z=insertVal(wbstruct.simple.z, thisZ ,index);

    
    wbstruct.simple.deltaFOverF=insertVal(wbstruct.simple.deltaFOverF, thisDeltaFOverF , index);
    
    
    wbstruct.simple.nn=wbstruct.simple.nn+1;
    
    %negative values indicated linked ROI neuron
    wbstruct.simple.nOrig=insertVal(wbstruct.simple.nOrig, -nn, index);
    
    if isfield(wbstruct,'f0')

        wbstruct.simple.f0=insertVal(wbstruct.simple.f0, thisF0 ,index) ;

    end
    
    
    if isfield(wbstruct.simple,'ID')
        
        wbstruct.simple.ID=insertVal(wbstruct.simple.ID, {[]}, index);
        
    end
    
    
    %add to derivs if they exist
    if isfield(wbstruct.simple,'derivs')     
        
        thisDeriv=wbDeriv(thisDeltaFOverF,'reg',wbstruct.simple.derivs.alpha,wbstruct.simple.derivs.numIter);
        wbstruct.simple.derivs.traces=insertVal(wbstruct.simple.derivs.traces, thisDeriv, index);
        
    end

    
end

end %main



function arrayOut=insertVal(array,val,index)

    arrayOut=[array(1:index-1) val array(index:end)];
    
end