function [labels,simpleIndices]=wbGetTopNeurons(sortType,numNeurons,wbstruct,options)

if nargin<1 || isempty(sortType)
    sortType='pcaloading1';
end


if nargin<3 || isempty(wbstruct)
    [wbstruct wbstructFileName]=wbload([],false);
end

if nargin<2  || isempty(numNeurons)
    numNeurons=wbstruct.simple.nn;
end

if nargin<4
    options=[];
end


if ~isfield(options,'useOnlyIDedNeurons')
    options.useOnlyIDedNeurons=true;
end

[traces sortIndex]=wbSortTraces(wbstruct.simple.deltaFOverF,sortType);


j=1;
isLabeled=false(1,numNeurons);
for i=1:numNeurons
    
    %wbstruct.simple.ID1{sortIndex(i)}
    
    if ~isempty(wbstruct.simple.ID1{sortIndex(i)})
        neuronSubsetString{i}=wbstruct.simple.ID1{sortIndex(i)};
        neuronSubsetStringLabeledOnly{j}=wbstruct.simple.ID1{sortIndex(i)};
        isLabeled(i)=true;
        j=j+1;
    else
        neuronSubsetString{i}=num2str(sortIndex(i));
    end
end

if options.useOnlyIDedNeurons
    labels=neuronSubsetStringLabeledOnly;
    simpleIndices=sortIndex(isLabeled);
else
    labels=neuronSubsetString;
    simpleIndices=sortIndex;
end