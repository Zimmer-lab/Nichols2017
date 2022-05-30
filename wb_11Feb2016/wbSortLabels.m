function [labels, values]=wbSortLabels(wbstruct,options)

if nargin<1 || isempty(wbstruct)
    wbstruct=wbload([],false);
end

if nargin<2
    options=[];
end

if ~isfield(options,'sortMethod')
    options.sortMethod='power';
end

if ~isfield(options,'useOnlyIDedNeurons');
    options.useOnlyIDedNeurons=false;
end

if ~isfield(options,'fieldName');
    options.fieldName='deltaFOverF';
end

if ~isfield(options,'sortOptions')
    options.sortOptions=[];
end

if ~isfield(options,'sortParams')
    options.sortParams=[];
end

[tracesSorted,sortIndex,sortValues,~,reducedSortIndex]=wbSortTraces(wbstruct.(options.fieldName),options.sortMethod,wbstruct.exclusionList,options.sortParams,options.sortOptions);
tracesSorted=tracesSorted(:,1:end-length(wbstruct.exclusionList)); %remove excluded neurons

labels={};
for i=1:length(reducedSortIndex);
    
    if ~options.useOnlyIDedNeurons
        thisLabel=num2str(reducedSortIndex(i));
    else
        thisLabel=[];
    end
    
    if ~isempty(wbstruct.simple.ID{reducedSortIndex(i)}) && ~strcmp(wbstruct.simple.ID{reducedSortIndex(i)}{1},'---')
            thisLabel=wbstruct.simple.ID{reducedSortIndex(i)}{1};
            
    end

    labels=[labels thisLabel];
    
end

values=sort(sortValues,1,'descend');

end