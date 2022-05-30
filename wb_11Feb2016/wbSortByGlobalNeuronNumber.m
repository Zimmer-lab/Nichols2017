function sortIndex=wbSortByGlobalNeuronNumber(neuronList)

if ischar(neuronList), neuronList={neuronList}; end

globalNeuronIDs=LoadGlobalNeuronIDs;

sortIndex=zeros(1,length(neuronList));

j=1;
for i=1:length(globalNeuronIDs)
    
    
    if ismember(globalNeuronIDs{i},neuronList)

        sortIndex(j) = find(strcmp(neuronList,globalNeuronIDs{i}));
        j=j+1;
    end
    
end



end