function [Q_sorted, sortIndex,sequenceRestarts]=wbMatrixSequenceSort(Q,startingColIndex)


currentColIndex=startingColIndex;

alreadyUsedFlags=false(1,size(Q,1));
sortIndex=zeros(1,size(Q,1));

sequenceRestarts=[];
for i=1:size(Q,1)
    
    sortIndex(i)=currentColIndex;
    alreadyUsedFlags(currentColIndex)=true;
   
    thisCol=Q(:,currentColIndex);
    
    %get smallest positive entry not already found
    thisCol(thisCol<0)=NaN;
    thisCol(alreadyUsedFlags)=NaN;
    [minVal minInd]=min(thisCol); 
    if ~isnan(minVal)
        currentColIndex=minInd;
    else  %no further links found so pick the first unused neuron
        sequenceRestarts=[sequenceRestarts i];
        currentColIndex=find(~alreadyUsedFlags,1,'first');
    end
    
    
end

Q_sorted=Q(sortIndex,sortIndex);
